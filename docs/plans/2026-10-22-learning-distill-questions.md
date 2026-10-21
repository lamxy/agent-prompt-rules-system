# 教学材料沉淀：待用户确认的疑问

2026-10-22 无人值守处理三个本机教学目录（gRPC、Go、Redis），把对 backend-dev 场景有收益的内容沉淀到配置。处理中无法自行决定、或与现行规范冲突的事项累积在此，等用户统一检查讨论。

每条格式：问题、背景与证据、当前处理（暂按哪种做法写入或未写入）、需要用户决定的选项。

## gRPC

落点：`rules/rpc/{proto,grpc-go}.md`、`skills/rpc-design/`、dev-ops `middleware-ops/references/grpc.md`。实测环境 grpc-go v1.84.0、buf 1.74.0。

1. **对外 HTTP/JSON 方案**。教材只说「对外加网关」，未比较方案；FiberHouse 分层允许多个 transport 复用 service。暂行：不指定，沿用项目已有方案，引入新方案写 ADR。选项：A 不指定 / B grpc-gateway / C Connect / D HTTP 走 FiberHouse handler，gRPC 只做服务间。
2. **buf breaking 默认类别**。实测 FILE 类别连「删字段并写 reserved」也报错，WIRE 不拦改名。暂行：以项目 `buf.yaml` 为准。选项：A 项目配置为准 / B 新项目默认 FILE / C 新项目默认 WIRE_JSON。
3. **生产是否开启 gRPC 反射**。暂行：仅开发、测试或配置开关打开时注册。选项：A 开关控制 / B 生产一律禁止 / C 内网默认开启。
4. **拦截器与可观测性自写还是用库**。context7 无 go-grpc-middleware 文档，API 无法核对，未写入。暂行：只给经测试的自写模板（recovery、日志、request id）。选项：A 自写 / B go-grpc-middleware v2 / C 链路追踪统一 otelgrpc StatsHandler（与 HTTP 侧一并决定）。
5. **gRPC 客户端代码的落点**。path rules 按路径匹配，调用下游 gRPC 的代码常在 `repository/` 等目录，`rules/rpc/grpc-go.md` 不会加载（ClientConn 复用、deadline、重试规则失效）。交叉审查暂行：规则内约定 handler 放 `api/grpc/`、客户端封装放 `grpc/` 目录或以 `_rpc.go` 结尾（项目已有约定优先），paths 由 `*grpc*.go` 放宽为 `*rpc*.go`。选项：A 维持此约定 / B paths 加 `**/repository/**/*.go`（编辑任何 repository 都会加载，约 2KB）/ C 不约定，靠 `rpc-design` skill 覆盖。
6. **本机残留**：docker 卷 `grpclab-gomod`（删除命令被权限拒绝）与镜像 `bufbuild/buf:latest` 未清理，需要时手动 `docker volume rm grpclab-gomod`。

## Go

（待处理）

## Redis

（待处理）
