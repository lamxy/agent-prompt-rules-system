# grpc-go 模板与实测依据

模板已在 Go 1.25、`google.golang.org/grpc` v1.84.0 下通过 `go vet` 与 bufconn 测试。服务名、包名为示例，按项目替换。

## 服务端装配

```go
func NewServer(logger *slog.Logger) (*grpc.Server, *health.Server) {
	srv := grpc.NewServer(
		grpc.ChainUnaryInterceptor(
			recoveryUnary(logger), // 第一个 = 最外层，兜住后续拦截器与 handler 的 panic
			requestIDUnary,
			accessLogUnary(logger),
		),
		grpc.ChainStreamInterceptor(recoveryStream(logger)),
		grpc.KeepaliveEnforcementPolicy(keepalive.EnforcementPolicy{
			MinTime:             10 * time.Second, // 不大于客户端 keepalive.Time
			PermitWithoutStream: true,
		}),
		grpc.KeepaliveParams(keepalive.ServerParameters{
			MaxConnectionAge:      5 * time.Minute, // 定期让客户端重连，扩容后的实例才能分到连接
			MaxConnectionAgeGrace: 30 * time.Second,
		}),
	)
	hs := health.NewServer()
	healthgrpc.RegisterHealthServer(srv, hs)
	return srv, hs
}

// 收到 SIGTERM 后
hs.Shutdown() // 所有服务置为 NOT_SERVING
stopped := make(chan struct{})
go func() { srv.GracefulStop(); close(stopped) }()
select {
case <-stopped:
case <-time.After(20 * time.Second): // 小于容器的停止宽限期（compose stop_grace_period，默认 10s）
	srv.Stop()
}
```

拦截器：

```go
func recoveryUnary(logger *slog.Logger) grpc.UnaryServerInterceptor {
	return func(ctx context.Context, req any, info *grpc.UnaryServerInfo, h grpc.UnaryHandler) (resp any, err error) {
		defer func() {
			if r := recover(); r != nil {
				logger.ErrorContext(ctx, "grpc panic", "method", info.FullMethod, "panic", r)
				err = status.Error(codes.Internal, "internal error")
			}
		}()
		return h(ctx, req)
	}
}

func requestIDUnary(ctx context.Context, req any, info *grpc.UnaryServerInfo, h grpc.UnaryHandler) (any, error) {
	id := ""
	if md, ok := metadata.FromIncomingContext(ctx); ok {
		if v := md.Get("x-request-id"); len(v) > 0 {
			id = v[0]
		}
	}
	if id == "" {
		id = newID()
	}
	_ = grpc.SetHeader(ctx, metadata.Pairs("x-request-id", id)) // 成功与失败时客户端都能从 Header 取到
	return h(context.WithValue(ctx, ctxKeyRequestID{}, id), req)
}

// 调下游时显式转发
func outgoing(ctx context.Context) context.Context {
	if id, ok := ctx.Value(ctxKeyRequestID{}).(string); ok {
		return metadata.AppendToOutgoingContext(ctx, "x-request-id", id)
	}
	return ctx
}
```

stream 版 recovery 同理，包裹 `h(srv, ss)`。访问日志按 `status.Code(err)` 分级：`Internal`、`Unknown`、`DataLoss` 记 ERROR，其余业务码记 INFO 或 WARN（与 `rules/go/logging.md` 一致）。

## 错误映射（传输层）

```go
func toStatus(err error) error {
	switch {
	case err == nil:
		return nil
	case errors.Is(err, context.DeadlineExceeded), errors.Is(err, context.Canceled):
		return status.FromContextError(err).Err()
	case errors.Is(err, domain.ErrInvalid):
		return status.Error(codes.InvalidArgument, err.Error())
	case errors.Is(err, domain.ErrNotFound):
		return status.Error(codes.NotFound, "resource not found")
	case errors.Is(err, domain.ErrConflict):
		return status.Error(codes.AlreadyExists, "resource already exists")
	case errors.Is(err, domain.ErrPrecondition):
		return status.Error(codes.FailedPrecondition, err.Error())
	case errors.Is(err, domain.ErrConcurrent):
		return status.Error(codes.Aborted, "concurrent modification, retry")
	default:
		return status.Error(codes.Internal, "internal error") // 原始错误只进日志
	}
}
```

字段级校验错误：

```go
st, _ := status.New(codes.InvalidArgument, "invalid request").WithDetails(&errdetails.BadRequest{
	FieldViolations: []*errdetails.BadRequest_FieldViolation{{Field: "items[0].quantity", Description: "must be > 0"}},
})
return nil, st.Err()
// 客户端：for _, d := range status.Convert(err).Details() { if br, ok := d.(*errdetails.BadRequest); ok { ... } }
```

details 走 `grpc-status-details-bin` trailer，受 header 大小限制，只放少量结构化信息。

### code 选择边界

| 易混淆 | 区别 | 客户端行为 |
|---|---|---|
| `InvalidArgument` / `FailedPrecondition` | 参数本身错 / 系统状态不允许 | 都不重试；后者要先改变状态 |
| `Aborted` / `FailedPrecondition` | 并发冲突 / 状态不对 | 前者可重试整个读-改-写 |
| `Unavailable` / `Internal` | 暂时不可达 / 服务端缺陷 | 前者可退避重试，后者重试无意义；把 `Internal` 报成 `Unavailable` 会引发重试风暴 |
| `Unimplemented` / `NotFound` | 方法不存在（版本不符、路由错、代理返回 404）/ 资源不存在 | 前者查部署与路由 |

经过不理解 gRPC 的代理时，代理自身返回的 HTTP 状态会被客户端映射（依据 grpc/grpc 仓库 `doc/http-grpc-status-mapping.md`，只用于响应中没有 `grpc-status` 的情况）：404 → `Unimplemented`，429 / 502 / 503 / 504 → `Unavailable`，401 → `Unauthenticated`，403 → `PermissionDenied`。这类响应没有 `grpc-status`，可借此与服务端真实返回区分。

## 客户端装配

```go
const serviceConfig = `{
  "loadBalancingConfig": [{"round_robin": {}}],
  "methodConfig": [{
    "name": [{"service": "demo.order.v1.OrderService", "method": "GetOrder"}],
    "timeout": "2s",
    "retryPolicy": {
      "maxAttempts": 3,
      "initialBackoff": "0.1s",
      "maxBackoff": "1s",
      "backoffMultiplier": 2,
      "retryableStatusCodes": ["UNAVAILABLE"]
    }
  }]
}`

conn, err := grpc.NewClient("dns:///order-svc-headless.<ns>.svc.cluster.local:9090",
	grpc.WithTransportCredentials(creds),
	grpc.WithDefaultServiceConfig(serviceConfig),
	grpc.WithKeepaliveParams(keepalive.ClientParameters{
		Time:                30 * time.Second, // 低于 10s 会被提升为 10s
		Timeout:             10 * time.Second,
		PermitWithoutStream: true,
	}),
)
```

`ClientConn` 在启动时创建，注入到 repository 或下游客户端封装，退出时关闭。

## bufconn 测试

```go
lis := bufconn.Listen(1 << 20)
srv, _ := NewServer(logger)
orderv1.RegisterOrderServiceServer(srv, handler)
go func() { _ = srv.Serve(lis) }()
t.Cleanup(srv.Stop)

cc, err := grpc.NewClient("passthrough:///bufnet",
	grpc.WithContextDialer(func(ctx context.Context, _ string) (net.Conn, error) { return lis.DialContext(ctx) }),
	grpc.WithTransportCredentials(insecure.NewCredentials()),
)
```

## 实测结论

grpc-go v1.84.0，单机临时容器，健康检查服务作为实验载体：

| 场景 | 结果 |
|---|---|
| 客户端 deadline 500ms，handler 耗时 1.5s 并监听 `ctx.Done()` | 客户端得到 `DeadlineExceeded`；服务端 `ctx.Err()` 10 次中 6 次 `Canceled`、4 次 `DeadlineExceeded`（服务端按 `grpc-timeout` 也设了自己的 deadline，与客户端 RST_STREAM 竞争） |
| 同上但 handler 不检查 ctx | handler 跑满 1.5s，结果被丢弃 |
| A→B→C 链路，B 用收到的 ctx 调 C | C 收到的剩余时间约 800ms（deadline 传播）；A 设置的 `x-request-id` 在 C 端为空（metadata 不传播） |
| handler 返回 `errors.New` | `Unknown` |
| handler 返回 `fmt.Errorf("repo: %w", status.Error(NotFound, ...))` | `NotFound`，message 为 `repo: rpc error: code = NotFound desc = ...` |
| handler 返回 `context.DeadlineExceeded` | `DeadlineExceeded` |
| handler panic，无 recovery | 整个服务进程退出（exit 2）；另一进程的客户端得到 `Unavailable: error reading from server: EOF` |
| handler panic，有 recovery 拦截器 | `Internal` |
| `ChainUnaryInterceptor(a, b)` | a 进 → b 进 → b 出 → a 出 |
| 服务端流发送 3 条消息 | stream 拦截器调用 1 次，包装的 `SendMsg` 调用 3 次 |
| handler `SetHeader` 后返回错误 | 客户端 `grpc.Header` 仍取到该值 |
| handler 只 `SetTrailer` 后返回错误 | 值只在 `grpc.Trailer` 中，Header 为空 |
| 5MiB 请求，默认配置 | `ResourceExhausted`（`received message larger than max (… vs. 4194304)`），handler 未被调用 |
| `status.FromError(io.EOF)` | `Unknown`，`ok=false` |
| 3 个实例，默认配置 9 次调用 | 全部落在同一实例（`pick_first`） |
| 同上，service config `round_robin` | 轮流分布到 3 个实例 |
| `grpc.NewClient("bufnet")` + bufconn dialer | `Unavailable: name resolver error: produced zero addresses`；`passthrough:///bufnet` 正常 |
| 前两次返回 `UNAVAILABLE`，配置 `retryPolicy` | 第 3 次成功，无需额外开关；`WithDisableRetry()` 或无配置时 1 次即失败；未列入的 `DEADLINE_EXCEEDED` 不重试 |
| 客户端 keepalive `Time` 10s，服务端默认 enforcement | 空闲 30s 后服务端发 GOAWAY `ENHANCE_YOUR_CALM` / `too_many_pings`；服务端 `MinTime` 5s 时无断连 |
| 打开一条长服务端流后调用 `GracefulStop` | 3s 仍未返回，`Stop()` 后客户端流以 `Unavailable` 结束；只有进行中的 unary 时，`GracefulStop` 等其完成后返回 |
| `health.Server` 默认 / 未登记服务 / `Shutdown()` 后 | `SERVING` / `NotFound` / 全部 `NOT_SERVING` |

服务端 keepalive 默认值（源码 `keepalive/keepalive.go`）：`EnforcementPolicy.MinTime` 5 分钟、`PermitWithoutStream` false；客户端 `Time` 最小 10s。

## 早期资料中不准确的说法

- 「deadline 到期时服务端 `ctx.Err()` 一定是 `Canceled`」：两种都会出现，不应依赖。
- 「`Unknown` 通常来自没包装的 panic」：grpc-go 不恢复 panic，未加 recovery 时进程直接退出，客户端看到的是连接断开（`Unavailable`），不是 `Unknown`。
- 「失败响应（Trailers-Only）时 Header 一定为空」：handler 用 `SetHeader` 设置的值在 grpc-go 中仍可从 Header 取到；只有未设置 header 时才为空。关键追踪信息在客户端同时检查 Header 与 Trailer。
