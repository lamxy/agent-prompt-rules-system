# 并发模板与实测依据

模板已在 Go 1.25.14（`go.mod` 为 `go 1.25`）、`golang.org/x/sync v0.22.0` 下通过 `go vet`、`go test -race` 与 `goleak` 检查。

## 规则的补充说明

`rules/go/` 只保留硬约定，以下解释与次要条目放在这里，写相关代码时按需查阅。

- context：子 context 只能缩短父的 deadline，下游需要更长时间时由上游放宽预算；要记录取消原因用 `WithCancelCause` / `WithTimeoutCause` 与 `context.Cause`，判断类型仍用 `errors.Is(err, context.DeadlineExceeded)`；`context.Background()` 的 `Done()` 为 nil，在 `select` 里永远不会就绪。`go vet` 能发现 `ctx, _ := WithCancel(...)`，发现不了 `_ = cancel`。
- 「收 N 次」收集结果时，每个 goroutine 无论成败都必须恰好发送一次；可能少于 N 时改为 `close` 后 `range`。
- `time.After`：`go` ≥ 1.23 的模块中未被引用的定时器可被 GC 回收（官方文档），旧资料说的「循环中一直泄漏到到期」只适用于 < 1.23；热循环每轮仍有约 3 次分配，复用一个 Timer 可省掉。
- `GOMAXPROCS`（`go` ≥ 1.25，Linux）：取逻辑 CPU 数、CPU 亲和性与 cgroup CPU quota（K8s 的 CPU limit，不是 request）三者的最小值，非整数向上取整，且不低于 2；运行时每秒最多更新一次。设置 `GOMAXPROCS` 环境变量或调用 `runtime.GOMAXPROCS(n)`（`automaxprocs` 就是这样做的）会关闭自动更新。
- `GOMEMLIMIT` 是软上限，cgo 分配不计入；Go GC 指南（go.dev/doc/gc-guide）建议在容器内存限额基础上留 5%～10% 余量给运行时之外的内存；可能与其他进程共享内存时，`GOGC` 不设为 `off`。
- `sync.Pool`：GC 会清空、`Get` 从不阻塞，只能做临时对象缓存，不能限制数量；限流用 `SetLimit`、`semaphore` 或带缓冲 channel，连接数用客户端自带的池参数。
- 泛型不是性能手段：指针等同形状的类型参数共用一份代码，方法调用经字典派发，实测与接口调用同速。
- `-gcflags=-m` 只用来找分配原因：变长 `make` 报告 does not escape 仍可能堆分配，以 benchmark 的 `allocs/op` 为准。已知长度的 slice 与 map 预分配；热路径的数字转字符串用 `strconv`，不用 `fmt.Sprintf`。
- `go test -race` 需要 cgo：`golang:*-alpine` 镜像先装 `gcc musl-dev` 并设 `CGO_ENABLED=1`。
- `golang.org/x/sync` v0.24.0 起要求 `go` ≥ 1.26；`go 1.25` 的模块用 v0.22.0 或更早。

## 模板

### 扇出：并发加载，任一失败即取消

结果按下标写入，不需要锁；`SetLimit` 控制对下游的并发；每个任务自行 `recover`（errgroup 不会把 panic 转成 error）。

```go
// FetchAll 并发加载，任一失败即取消其余；结果按输入顺序返回。
func FetchAll(ctx context.Context, l Loader, ids []int64) ([]Item, error) {
	out := make([]Item, len(ids)) // 每个任务写自己的下标，不需要锁
	g, gctx := errgroup.WithContext(ctx)
	g.SetLimit(8) // 下游能承受的并发上限
	for i, id := range ids {
		g.Go(func() (err error) {
			defer func() {
				if r := recover(); r != nil {
					err = fmt.Errorf("load %d: panic: %v", id, r)
				}
			}()
			it, err := l.Load(gctx, id)
			if err != nil {
				return fmt.Errorf("load %d: %w", id, err)
			}
			out[i] = it
			return nil
		})
	}
	if err := g.Wait(); err != nil {
		return nil, err
	}
	return out, nil // 之后的调用使用 ctx，不用 gctx（已被取消）
}
```

### 空闲超时（`go` ≥ 1.23）

```go
// Consume 空闲超时：idle 内没有新消息就返回。go.mod 的 go >= 1.23。
func Consume(ctx context.Context, in <-chan string, idle time.Duration, handle func(string)) error {
	t := time.NewTimer(idle)
	defer t.Stop()
	for {
		select {
		case msg, ok := <-in:
			if !ok {
				return nil
			}
			handle(msg)
			t.Reset(idle) // 1.23+ 不需要 Stop + 排空
		case <-t.C:
			return nil
		case <-ctx.Done():
			return ctx.Err()
		}
	}
}
```

`go` < 1.23 的模块，`Reset` 前须 `if !t.Stop() { select { case <-t.C: default: } }`，否则会读到旧的到期信号。

### 请求结束后的异步工作

```go
// AfterResponse 请求结束后仍要完成的工作。
func AfterResponse(ctx context.Context, logger *slog.Logger, send func(context.Context) error) {
	bg := context.WithoutCancel(ctx) // 保留 trace 等值，不随请求取消
	go func() {
		defer func() {
			if r := recover(); r != nil {
				logger.ErrorContext(bg, "async task panic", "panic", r)
			}
		}()
		ctx, cancel := context.WithTimeout(bg, 5*time.Second)
		defer cancel()
		if err := send(ctx); err != nil {
			logger.WarnContext(ctx, "async task failed", "err", err)
		}
	}()
}
```

可靠性要求高的任务（失败需重试、进程重启不能丢）改走消息队列或任务表，不用进程内 goroutine。

### 出站 HTTP

```go
var client = &http.Client{Timeout: 10 * time.Second} // 进程内复用

func GetJSON(ctx context.Context, url string) ([]byte, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		_, _ = io.CopyN(io.Discard, resp.Body, 64<<10) // 读掉少量剩余以便复用连接
		return nil, fmt.Errorf("get %s: status %d", url, resp.StatusCode)
	}
	return io.ReadAll(io.LimitReader(resp.Body, 10<<20))
}
```

### 测试

```go
func TestMain(m *testing.M) { goleak.VerifyTestMain(m) }

func TestConsume(t *testing.T) {
	synctest.Test(t, func(t *testing.T) { // 虚拟时间：下面的 Sleep 立即完成
		in := make(chan string)
		done := make(chan error)
		go func() { done <- Consume(context.Background(), in, time.Minute, func(string) {}) }()
		time.Sleep(50 * time.Second)
		in <- "m"
		<-done // 再过 1 分钟空闲后返回
	})
}
```

## 实测结论（Go 1.25.14，linux/arm64）

| 项目 | 结果 |
|---|---|
| `time.Timer`，`go 1.25` 模块 | `cap(t.C)` 为 0；到期未读后直接 `Reset(200ms)`，200ms 后才收到，无旧信号；此时 `Stop()` / `Reset()` 返回 true。`Ticker.Reset` 相同 |
| 同一工具链，`go 1.22` 模块 | `cap(t.C)` 为 1；不排空直接 `Reset`，立即读到旧信号（0s）；行为由 `go.mod` 决定（交叉复测一致） |
| `go vet` 与 cancel | `ctx, _ := WithCancel(...)` 报告；`_ = cancel` 不报告 |
| `go vet` 与 nil 错误 | 返回 `*MyErr` 的 nil 再转为 `error`，`err == nil` 为 false；vet 默认分析器不含 nilness，不报告 |
| `context.WithoutCancel` | 父取消后其 `Err()` 为 nil、`Done()` 为 nil、无 deadline，值保留 |
| 子 context 要 5s、父剩 30ms | 子的 deadline 不晚于父 |
| `WithTimeoutCause` | `Err()` 仍是 `DeadlineExceeded`，`context.Cause` 返回自定义原因 |
| `errgroup.WithContext` | 全部成功、`Wait` 返回后派生 ctx 已是 `context canceled` |
| errgroup 中 panic | 进程直接退出，`Wait` 不返回 error（源码注释说明是有意设计）|
| `SetLimit(2)` 提交 10 个任务 | 最大并发 2，`Go` 在满额时阻塞 |
| `wg.Go`（Go 1.25）| 等价于 `Add(1)` + `go` + `defer Done()`；循环变量每轮独立来自 `go` ≥ 1.22 的语义，与 `wg.Go` 无关 |
| 读锁未释放、写者排队时再次 `RLock` | 死锁 |
| 512KB 响应，20 次请求 | 读完再关：连接复用 19/20；只关不读：复用 0、goroutine 不泄漏；不关：goroutine +60（每请求 3 个） |
| `--cpus=2` 容器 | `go 1.25` 模块 `GOMAXPROCS=2`；`go 1.24` 模块为宿主核数 10。交叉复测 `--cpus=1.5`：`go 1.25` 模块为 2（向上取整），`go 1.22` 模块为 10 |
| `--memory=256m` 容器 | `GOMEMLIMIT` 未设置时仍为无限 |
| `go test -race`，alpine 镜像 | 默认报 `-race requires cgo`；装 `gcc musl-dev` 并 `CGO_ENABLED=1` 后检出 map 并发写 |
| `synctest.Test` | 3×20s 的 `Sleep` 与 30s 定时器即时完成，虚拟耗时精确为 90s；测试结束仍阻塞的 goroutine 报 deadlock |
| 方法调用（noinline 包装） | 直接 1.60ns，接口 1.70ns，泛型（指针类型参数）1.70ns |
| `for i < b.N` 调用未使用结果的纯函数 | 0.23ns（被消除）；`for b.Loop()` 为 1.66ns |
| `make([]int, n)`，n 为变量 | `-m` 都报 does not escape；n=100 时 1 次堆分配（896B），n=4 时 0 次 |
| append 1000 个 int | 不预分配 12 allocs、3.8µs；预分配 0 allocs、0.37µs |

## 早期资料中不准确或已过时的说法

- 「`Reset` 前必须 `Stop` 并排空 channel」：只适用于 `go` < 1.23 的模块。
- 「`time.After` 在循环中会一直泄漏到到期」：`go` ≥ 1.23 的模块不成立（见上文）。循环里真正容易写错的是语义：每轮重新计时，当作整体超时用会永不触发。
- 「泛型编译期展开、零运行时开销」：Go 按类型形状实例化，指针类型共用一份代码，方法调用经字典派发，实测与接口同速。
- 「`go vet` 的 nilness 能发现 nil 接口问题」：nilness 不在 `go vet` 默认分析器中（gopls、golangci-lint 中可启用），且该场景实测不报告。
- 「容器里要用 automaxprocs」：`go` ≥ 1.25 的模块由运行时处理。
- 「`-gcflags=-m` 说不逃逸就没有堆分配」：变长 `make` 仍可能在运行时走堆；实测 Go 1.25 下 32 字节（4 个 int）的变长 `make` 为 0 次分配。以 `allocs/op` 为准。
