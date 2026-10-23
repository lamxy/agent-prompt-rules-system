# gRPC 服务部署

应用侧的代码规范在 backend-dev 场景的 `rules/rpc/` 与 `rpc-design` skill；这里只写 Docker / Docker Compose 下的部署、健康检查与监控。依据：Compose 文件参考（`stop_grace_period`、`healthcheck`）、`docker stop` 文档、grpc-health-probe README、grpc-go 源码（`keepalive` 参数注释）。

## 负载均衡

gRPC 是 HTTP/2 长连接，一条连接承载所有请求；经 L4 转发时，连接建立后固定在一个后端。起步阶段单实例部署，不涉及这个问题。扩到多实例时在部署说明里写明方案：

| 方案 | 做法 | 代价 |
|---|---|---|
| L7 代理 | 支持 HTTP/2 的代理按请求分发（如 nginx `grpc_pass`、Envoy） | 多一跳与一个需要运维的组件 |
| 客户端负载均衡 | 客户端 `dns:///` 目标 + `round_robin` service config | 需要 DNS 返回多个后端地址；地址变化有延迟（依赖服务端 `MaxConnectionAge` 促使重连） |
| 只靠定期断连 | 服务端 `MaxConnectionAge` + `MaxConnectionAgeGrace` | 只能缓解，重连时有抖动 |

上线前用实际的代理或 DNS 实测流量是否分散。

## 健康检查

- 应用注册 `grpc.health.v1.Health`。
- 容器健康检查用 grpc-health-probe：在镜像中加入其发布的静态二进制（`COPY --from=ghcr.io/grpc-ecosystem/grpc-health-probe:<版本> /ko-app/grpc-health-probe /bin/grpc_health_probe`），compose 中 `healthcheck.test: ["CMD", "/bin/grpc_health_probe", "-addr=:<端口>"]`；返回 `SERVING` 时退出码为 0。
- 外部探测（Uptime Kuma）只检查端口或对外的 HTTP 健康端点，见 `observability.md`。

## 优雅关闭

- `docker stop` / `docker compose down` 先发 `SIGTERM`，等待 `stop_grace_period`（Compose 默认 10s）后发 `SIGKILL`。
- 应用收到 `SIGTERM`：健康状态置为 `NOT_SERVING` → `GracefulStop()` → 超时后 `Stop()`；该超时小于 `stop_grace_period`。
- 长连接流不会自己结束，`GracefulStop` 会一直等待；必须有超时兜底。

## keepalive 与中间设备

- 客户端 keepalive `Time` 要短于 NAT、LB、防火墙的空闲超时，否则长连接会被静默切断。
- 服务端 `KeepaliveEnforcementPolicy.MinTime`（默认 5 分钟）必须不大于客户端 `Time`，否则服务端以 `ENHANCE_YOUR_CALM`（`too_many_pings`）断开连接；`PermitWithoutStream` 两端一致。
- 经 L7 代理时，客户端到代理、代理到后端是两段连接，keepalive 与超时分别配置。

## 排障

- gRPC 的 HTTP 状态几乎总是 200，成败在 `grpc-status` trailer：代理、LB 的统计与告警按 gRPC status code 看，不按 HTTP 状态。
- 客户端大量 `Unimplemented` 而服务端无日志时，先查代理路由（代理返回的 404 会被映射为 `Unimplemented`）。
- 消息超过 4MiB 被拒时 handler 不会执行，服务端业务日志里看不到该请求，只能从客户端或传输层发现。
- 需要按方法与 code 统计请求数、错误率、延迟时，按 `monitoring.md` 升级到 Prometheus。

## 安全

- 生产使用 TLS；反射服务只在开发、测试环境开启，生产需要时只对内网开放。
- gRPC 端口不直接暴露到公网；对外提供 HTTP/JSON 时经网关转换。
