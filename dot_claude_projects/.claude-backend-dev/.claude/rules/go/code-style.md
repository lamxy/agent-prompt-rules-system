---
paths:
  - "**/*.go"
---

# Go 代码规范

格式与 import 顺序由 hook（goimports / gofmt）和项目的 golangci-lint 负责，这里只写工具检查不到的约定。并发与 context 见 `concurrency.md`，日志见 `logging.md`。

## 错误

- 调用方需要判断的错误，定义为包级 `var ErrXxx = errors.New(...)` 或自定义错误类型，用 `errors.Is` / `errors.As` 匹配，不比较错误字符串。
- 向上传递时用 `fmt.Errorf("<动作>: %w", err)` 补充上下文；不写 "failed to" 之类的前缀，避免层层堆叠成 `failed to x: failed to y`。
- 每个错误只处理一次：要么记录日志后降级处理，要么包装后返回，不要既记录又返回。
- 函数签名返回 `error`，不返回 `*MyErr` 等具体类型：nil 指针装进 `error` 后 `err != nil` 为 true，`go vet` 不报告。

## panic 与退出

- 业务代码不用 panic 表达可处理的错误，返回 error。
- 只在 `main` 中调用 `os.Exit` 或 `log.Fatal`，且只调用一次；其余函数返回 error。
- 避免 `init()` 与可变的包级变量；依赖通过构造函数或框架的装配机制注入。

## 其他

- 时间间隔用 `time.Duration`，时间点用 `time.Time`，不用裸整数表示秒或毫秒。
- 需要序列化的结构体字段都写 `json` / `bson` 等 tag。
- 性能改动要有 `go test -bench -benchmem` 的前后对比，以 `allocs/op` 为准，不凭 `-gcflags=-m` 下结论（见 `go-perf-diagnose`）。
