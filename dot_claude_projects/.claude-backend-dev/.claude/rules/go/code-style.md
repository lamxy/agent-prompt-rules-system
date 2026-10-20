---
paths:
  - "**/*.go"
---

# Go 代码规范

格式与 import 顺序由 hook（goimports / gofmt）和项目的 golangci-lint 负责，这里只写工具检查不到的约定。

## 错误

- 调用方需要判断的错误，定义为包级 `var ErrXxx = errors.New(...)` 或自定义错误类型，用 `errors.Is` / `errors.As` 匹配，不比较错误字符串。
- 向上传递时用 `fmt.Errorf("<动作>: %w", err)` 补充上下文；不写 "failed to" 之类的前缀，避免层层堆叠成 `failed to x: failed to y`。
- 每个错误只处理一次：要么记录日志后降级处理，要么包装后返回，不要既记录又返回。
- 类型断言用两值形式 `v, ok := x.(T)`。

## panic 与退出

- 业务代码不用 panic 表达可处理的错误，返回 error。
- 只在 `main` 中调用 `os.Exit` 或 `log.Fatal`，且只调用一次；其余函数返回 error。
- 避免 `init()` 与可变的包级变量；依赖通过构造函数或框架的装配机制注入。

## 并发

- 不启动无人管理的 goroutine：每个 goroutine 都要有停止方式（`context` 取消或关闭信号），并能等待其退出（`sync.WaitGroup`、`errgroup`）。
- channel 容量为 0 或 1；更大的容量需要说明理由。
- 在边界处复制 slice 与 map，避免调用方与内部共享底层数据。

## context

- 需要 I/O、超时或取消的函数，第一个参数为 `ctx context.Context`；不把 context 存进结构体。
- 从请求进入的 context 一路传到 repository；不在业务代码里用 `context.Background()` 切断请求链路。

## 其他

- 时间间隔用 `time.Duration`，时间点用 `time.Time`，不用裸整数表示秒或毫秒。
- 需要序列化的结构体字段都写 `json` / `bson` 等 tag。
- 日志用项目统一的结构化 logger，不用 `fmt.Println`；日志里不输出密码、token、完整的个人信息。
