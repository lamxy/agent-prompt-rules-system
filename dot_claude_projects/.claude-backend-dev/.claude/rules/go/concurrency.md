---
paths:
  - "**/*.go"
---

# 并发与 context

定时器与 `GOMAXPROCS` 的行为由主模块 `go.mod` 的 `go` 行决定，不只看工具链版本。模板与实测依据见 `go-perf-diagnose` skill 的 `references/concurrency.md`。

## context

- 需要 I/O、超时或取消的函数，第一个参数为 `ctx context.Context`；不存进结构体；请求的 ctx 一路传到 repository，业务代码不用 `context.Background()` 切断链路。`With*` 之后紧跟 `defer cancel()`。
- 长循环、批处理、阻塞的 channel 操作检查 `ctx.Done()`；取消是协作式的。
- 请求返回后仍要执行的异步工作，用 `context.WithoutCancel(ctx)` 再加 `WithTimeout`，不把请求 ctx 直接交给后台 goroutine；不能丢的任务走消息队列或任务表。

## goroutine

- 每个 goroutine 都要有停止方式（ctx 或关闭信号），并有人等待其退出。
- 一组子任务任一失败即整体失败：`errgroup.WithContext` + `g.SetLimit(n)`。派生的 ctx 在 `Wait` 返回后即被取消，`Wait` 之后的代码用原 ctx。
- 只需等待、不汇总错误：`go.mod` ≥ 1.25 用 `wg.Go(f)`；否则 `wg.Add` 写在 `go` 语句之前。
- goroutine 内（含 `g.Go`、`wg.Go`）的 panic 会终止进程，HTTP / gRPC 的 recovery 中间件捕获不到，errgroup 也不转成 error；可能 panic 的代码在 goroutine 内 `recover` 并记录日志或转成 error。

## channel、定时器与共享状态

- channel 容量为 0 或 1，更大要说明理由（如扇出结果 channel 设为任务数，接收方提前返回时发送方不阻塞）。只由发送方或等待全部发送方结束的协调者 `close`。
- `time.After` 每次调用重新计时：循环里的整体超时用循环外的 ctx 或 Timer。`go` ≥ 1.23 的模块 `Reset` 前不需要 `Stop` + 排空 channel；< 1.23 仍需要。
- 共享状态用 `sync.Mutex`，单个计数或标志用 `atomic.Int64` / `atomic.Bool`；换 `RWMutex` 要有 benchmark，且持读锁时不再次 `RLock`（有写者排队时死锁）。
- 在边界处复制 slice 与 map，避免调用方与内部共享底层数据。

## 出站 HTTP 与运行时参数

- 出站请求用 `http.NewRequestWithContext` 和进程内复用、设了 `Timeout` 的 `http.Client`；判断 `err` 后 `defer resp.Body.Close()`，不关 body 会泄漏 goroutine。
- `go` ≥ 1.25 的模块由运行时按容器 CPU limit 设置 `GOMAXPROCS`，不引入 `automaxprocs`（已有的移除：手动设置会关闭运行时的自动更新）；`GOMEMLIMIT` 不会自动设置，由部署配置注入。
