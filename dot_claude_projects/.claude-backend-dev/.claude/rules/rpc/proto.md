---
paths:
  - "**/*.proto"
  - "**/buf.yaml"
  - "**/buf.gen.yaml"
---

# Protobuf 契约

适用于 gRPC 的 `.proto`；不用 gRPC 的项目删除 `rules/rpc/`。新增服务或方法用 `rpc-design` skill，兼容性实测见其 `references/proto.md`。

## 命名（与 buf lint `STANDARD` 一致）

- package 带版本后缀：`<领域>.<资源>.v1`，目录与 package 对应（`proto/<领域>/<资源>/v1/`）。
- 服务名以 `Service` 结尾；每个 RPC 用专属的 `<方法>Request` / `<方法>Response`，不复用业务 message，不用 `google.protobuf.Empty` 作请求或响应（之后无法加字段）。
- 字段 `lower_snake_case`；枚举值带枚举名前缀，零值为 `<枚举名>_UNSPECIFIED`，业务代码对未知枚举值、`oneof` 未设置或未知成员（type switch 的 `default`）要有兜底分支。

## 兼容性

- 字段号是契约：已发布的字段号不修改、不复用。删字段时同时 `reserved` 号与名：`reserved 6; reserved "remark";`。
- 不改已有字段的类型（含 `int32` ↔ `int64`、`int32` ↔ `sint32`、`string` ↔ `bytes`）、不改名、不在单个与 `repeated` 之间切换、不把字段移入或移出 `oneof`；需要时加新字段并废弃旧字段（`[deprecated = true]`）。
- 改名在 wire 上兼容，但会破坏 JSON 映射（网关、protojson）和生成代码，按破坏性变更处理。
- 破坏性变更走新版本 package（`v2`）与 `v1` 并存，不在原 package 内修改。

## 字段语义

- 需要区分「未设置」与零值的标量（如 `bool auto_renew` 传 `false`）用 `optional`；部分更新接口用 `google.protobuf.FieldMask update_mask`，不靠零值判断「没传」。
- 时间用 `google.protobuf.Timestamp`、时长用 `google.protobuf.Duration`；用整数时字段名写明单位（`created_at_unix_ms`）。金额不用 `float` / `double`。
- 列表接口带分页（`page_size`、`page_token` / `next_page_token`）；写接口需要防重时带 `idempotency_key`（或 `request_id`）。
- 单条消息默认上限 4MiB（接收端），大对象走对象存储，消息里传引用。
- 需要稳定字节（签名、哈希、缓存 key）时不直接用 `proto.Marshal` 的结果：`map` 字段顺序不确定，至少用 `proto.MarshalOptions{Deterministic: true}`。

## 改动后

- 新项目 `buf.yaml` 的 breaking 类别用 `FILE`；已有项目以其配置为准。
- 项目有 `buf.yaml` 时运行 `buf lint` 与 `buf breaking --against '<主分支或已发布的 proto>'`；有报错先修改设计，不为通过而关闭检查。
- 用项目的生成命令（`buf generate` / `make proto`）重新生成；`*.pb.go`、`*_grpc.pb.go` 不手改。
