---
paths:
  - "**/*.go"
---

# 日志

使用项目统一的结构化 logger，输出 JSON，一行一条。用框架时用框架的 logger（FiberHouse 见 `rules/framework/fiberhouse.md`），不另引入第二套；没有框架 logger 的项目用 `log/slog` 的 JSON handler 并开启 `AddSource`（zerolog 用 `Caller()`），日志带文件与行号。

## 级别

| 级别 | 用途 |
|---|---|
| `DEBUG` | 开发排查；生产环境不输出 |
| `INFO` | 启动参数与启动完成、配置加载、业务状态变化、核心流程的关键节点、服务之间的调用 |
| `WARN` | 结果与预期不符但可继续：用户输入参数错误、外部返回码异常、可恢复的降级 |
| `ERROR` | 程序逻辑错误与未处理的异常；需要告警的同时上报错误追踪（见「错误」），可预期的业务失败不用 `ERROR` |

上线初期用 `WARN` 观察业务行为时，注意输出量，事后调回。

## 字段

每条日志包含：时间、级别、`service`、`message`，以及请求 id。框架已定的字段名沿用框架（FiberHouse 的请求 id 字段由 trace 配置决定，默认 `traceId`）。当前不做分布式追踪，不要求 `span_id`。按需补充：

- `type`：`ACCESS`（接口访问）或 `EVENT`（业务事件）
- `biz_tag`：业务标签，如 `order.place`，同一业务流程使用同一个标签
- `biz_id`：业务主键，如订单号
- `url`、`cost_ms`：接口路径与耗时

自定义字段名在项目内统一，用 `snake_case`。

## 内容

- 接口访问日志由中间件统一输出，不在每个 handler 里重复写；未捕获的 panic 由中间件或框架恢复并记录 `ERROR`。
- 与外部系统交互（回调、对账、文件交换）时记录原始请求与响应的摘要；需要重发的失败数据存入数据库，而不是只写在日志里。
- 日志信息要完整，能单独看懂：写明对象、动作和关键参数，不写「处理失败」这类无上下文的信息。
- 不输出密码、token、完整的身份证号或银行卡号等敏感信息，必要时脱敏。
- 容器部署时日志只写 stdout，由 Docker 日志驱动轮转，不在容器内另写日志文件。非容器部署必须写文件时，轮转按所用框架或库的配置。

## 错误

- 返回 error 时用 `fmt.Errorf("查询用户 %d: %w", id, err)` 逐层附加上下文；`errors.New` / `fmt.Errorf` 不带堆栈，出处靠上下文链判断。同一个 error 只在最终处理处记录一次。
- 自己开的 goroutine、启动初始化、后台任务等框架统一错误处理之外的地方，自行 recover 并记录 `ERROR`（带行号）。
- 错误追踪用 sentry-go：DSN 由环境变量 `SENTRY_DSN` 注入，为空时不上报；panic 经 recover 上报（堆栈含 panic 所在行），error 用 `CaptureException` 上报。没有日志告警平台时，需要告警的 `INFO` / `WARN` 事件用 `CaptureMessage` 上报。
