---
paths:
  - "**/grpc/**/*.go"
  - "**/rpc/**/*.go"
  - "**/*rpc*.go"
  - "**/interceptor*/**/*.go"
---

# gRPC（Go）

适用于 `google.golang.org/grpc`。代码模板与实测依据见 `rpc-design` skill 的 `references/grpc-go.md`。

## 分层与错误

- gRPC handler 属于传输层，与 HTTP handler 同级，放在模块的 `api/grpc/`；下游 gRPC 客户端封装放在 `grpc/` 目录或以 `_rpc.go` 结尾（项目已有约定优先；这样本规范才会自动加载）。handler 只做 pb 消息与 dto 的转换、调用 service、错误映射；service 不 import `grpc`、`status`、`codes` 或 pb 包。
- 领域错误在传输层按一张表转为 status：参数非法 → `InvalidArgument`，不存在 → `NotFound`，唯一冲突 → `AlreadyExists`，状态不允许 → `FailedPrecondition`，乐观锁冲突 → `Aborted`，限流 → `ResourceExhausted`，未认证 → `Unauthenticated`，无权限 → `PermissionDenied`，下游暂不可用 → `Unavailable`，其余 → `Internal`。
- handler 只返回 `status.Error` / `status.Errorf`：`errors.New` 会变成 `Unknown`；`fmt.Errorf("%w", st.Err())` 保留 code，但 message 会带上内部前缀。`Internal` 的 message 用固定文案，原始错误只写日志。
- 不在正常响应里放错误码字段；需要字段级错误或重试间隔时用 `status.WithDetails`（`errdetails.BadRequest`、`RetryInfo`）。
- 客户端按 `status.Code(err)` 判断，不匹配错误文本；读 pb 字段用 `GetXxx()`（nil 安全）。

## context 与超时

- 每次出站调用都带 deadline（`context.WithTimeout` 或 service config 的 `timeout`）；handler 调下游时传入收到的 `ctx`，剩余时间会自动随调用传递。
- metadata 不会自动转发：需要传递的 request id、鉴权信息用 `metadata.AppendToOutgoingContext` 显式写入。
- 耗时的循环、批量处理、流的发送循环要检查 `ctx.Done()`；取消是协作式的，不检查就会一直执行到底。不根据服务端的 `ctx.Err()` 区分「超时」与「取消」（两种都会出现）。

## 服务端

- 必须挂 recovery 拦截器并放在 `ChainUnaryInterceptor` / `ChainStreamInterceptor` 的第一个：grpc-go 不捕获 handler 的 panic，会导致整个进程退出。
- stream 拦截器每个流只调用一次；要处理每条消息需包装 `grpc.ServerStream` 的 `RecvMsg` / `SendMsg`。
- 注册 `grpc_health_v1` 健康服务；退出时依次：`health.Server.Shutdown()` → 带超时的 `GracefulStop()` → 超时后 `Stop()`（有长连接流时 `GracefulStop` 不会自己返回）。
- 服务端设置 `KeepaliveEnforcementPolicy`，`MinTime` 不大于客户端 keepalive 的 `Time`，否则客户端会被 `too_many_pings` 断开。
- 反射（`reflection.Register`）由配置开关控制，生产默认关闭；开发、测试环境开启。

## 客户端

- `*grpc.ClientConn` 按目标服务在进程内创建一次并复用，由依赖装配注入；不在请求路径上新建与关闭。
- 用 `grpc.NewClient`（不用已弃用的 `grpc.Dial`）；目标写全 scheme（`dns:///host:port`）。默认负载均衡是 `pick_first`，K8s 内直连多实例需 headless Service + service config `round_robin`，或经 L7 代理。
- 自动重试（service config `retryPolicy`）只配给幂等方法，`retryableStatusCodes` 默认只放 `UNAVAILABLE`；`ResourceExhausted` 也用于「消息超过大小上限」，不要无条件重试。非幂等写操作靠 `idempotency_key` 由服务端去重。
- 流式 `Recv()` 先判断 `err == io.EOF`（正常结束），再按错误处理；`status.FromError(io.EOF)` 会得到 `Unknown`。

## 测试

handler 测试用 `google.golang.org/grpc/test/bufconn`，目标写 `passthrough:///bufnet`（`NewClient` 默认 dns 解析，不加 scheme 会失败）。
