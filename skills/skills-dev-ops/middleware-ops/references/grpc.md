# gRPC 服务部署

应用侧的代码规范在 backend-dev 场景的 `rules/rpc/` 与 `rpc-design` skill；这里只写部署、网关与监控。K8s 部分依据 kubernetes.io（Service、Pod 终止流程、gRPC 探针）与 grpc-go 源码（DNS 解析器不定期轮询，只在连接断开后重新解析；`keepalive` 参数注释）。

## K8s 负载均衡

gRPC 是 HTTP/2 长连接，一条连接承载所有请求。经普通 ClusterIP Service（L4）时，连接建立后固定在一个 Pod，扩容后的新 Pod 拿不到流量。三选一，并在部署说明里写明：

| 方案 | 做法 | 代价 |
|---|---|---|
| 客户端负载均衡 | headless Service（`clusterIP: None`）+ 客户端 `dns:///` 目标与 `round_robin` service config | 客户端要配置；DNS 变化有延迟（依赖服务端 `MaxConnectionAge` 促使重连） |
| L7 代理 / 服务网格 | Envoy、Linkerd、Istio，或支持 HTTP/2 的 ingress（如 nginx `grpc_pass`）按请求分发 | 多一跳与一个需要运维的组件 |
| 只靠定期断连 | 服务端 `MaxConnectionAge` + `MaxConnectionAgeGrace` | 只能缓解，重连时有抖动 |

普通 Service 加 `round_robin` 无效：DNS 只返回一个 VIP。

## 健康检查与探针

- 应用注册 `grpc.health.v1.Health`，探针用 K8s 原生 gRPC 探针（v1.27 起稳定）：`livenessProbe.grpc.port`，需要区分时设 `service`（如 `<服务名>-readiness`）。
- 就绪探针在应用开始关闭时立即失败（应用调用 `health.Server.Shutdown()`）。

## 优雅关闭

- 应用收到 SIGTERM：健康状态置为 `NOT_SERVING` → `GracefulStop()` → 超时后 `Stop()`；超时时间小于 `terminationGracePeriodSeconds`。
- 长连接流不会自己结束，`GracefulStop` 会一直等待；必须有超时兜底。
- Endpoints 摘除有延迟，可加短暂的 `preStop` 等待，让流量先停再关闭。

## keepalive 与中间设备

- 客户端 keepalive `Time` 要短于 NAT、LB、防火墙的空闲超时，否则长连接会被静默切断。
- 服务端 `KeepaliveEnforcementPolicy.MinTime`（默认 5 分钟）必须不大于客户端 `Time`，否则服务端以 `ENHANCE_YOUR_CALM`（`too_many_pings`）断开连接；`PermitWithoutStream` 两端一致。
- 经 L7 代理时，客户端到代理、代理到后端是两段连接，keepalive 与超时分别配置。

## 监控

- gRPC 的 HTTP 状态几乎总是 200，成败在 `grpc-status` trailer：网关、LB、APM 的告警按 gRPC status code 统计，不按 HTTP 状态。
- 必备指标：按方法与 code 的请求数、错误率（`Internal`、`Unknown`、`Unavailable`、`DeadlineExceeded` 分开看）、延迟 P95 / P99、活跃流数量、连接数。
- 客户端大量 `Unimplemented` 而服务端无日志时，先查代理路由（代理返回的 404 会被映射为 `Unimplemented`）。
- 消息超过 4MiB 被拒时 handler 不会执行，服务端业务日志里看不到该请求，只能从客户端或传输层指标发现。

## 安全

- 生产使用 TLS（或网格 mTLS）；反射服务只在开发、测试环境开启，生产需要时只对内网开放。
- gRPC 端口不直接暴露到公网；对外提供 HTTP/JSON 时经网关转换。
