---
paths:
  - "**/main.go"
  - "**/application_impl.go"
  - "**/module/*_impl.go"
  - "**/providers/**/*.go"
  - "**/module/*/api/**/*.go"
---

# FiberHouse 框架

适用于基于 [FiberHouse](https://github.com/lamxy/fiberhouse) 的项目。不使用 FiberHouse 的项目删除本文件。使用最新已发布版本，具体配置项与 API 以框架源码和文档为准。

- 能力只通过显式注册进入启动链：`ApplicationRegister`、`ModuleRegister`、`TaskRegister` 与 Provider / Manager。框架不扫描目录，新增模块、路由、中间件后要在对应注册器或 Provider 中接入。
- `Default()` 不会自动加入 `DefaultProviders()` / `DefaultPManagers(ctx)`，需要时由应用显式加入。
- 不 import FiberHouse 的 `example_*` 包作为依赖；需要时复制到自己的应用目录再修改。
- 内核由 `BootConfig.CoreType` 选择。Fiber handler 为 `func(*fiber.Ctx) error`，普通错误直接 `return err`；Gin handler 为 `func(*gin.Context)`，错误用 `c.Error(err)` 上报。路由、绑定与 handler 使用各内核的原生 API。
- 切换或新增内核时，只改传输边缘（请求绑定、响应写出、错误翻译），service 及以下保持不变。接入其他内核（如 Hertz）参照 FiberHouse 的 `example_application/hertzcore/`。
- 响应统一使用框架的 `{code,msg,data}` 结构，不在 handler 中自定义响应外壳。
- 跨组件共享的实例（数据库、缓存、codec 等）通过 `GlobalManager` / `Locator` 获取，不另建包级全局变量。
- 需要关闭的资源实现 `ClosableProvider`，由框架按注册的逆序关闭；不在业务代码中自行管理关闭顺序。
- 装配期的错误使用返回 error 的入口（如 `RunServerWithError`），不依赖 panic。

## 日志与错误

- 日志用框架的全局 logger（底层 zerolog），不另引入 slog、zap。容器部署只写 stdout（控制台 JSON，关闭文件输出）。
- 错误与 panic 由框架统一捕获并记录一次，handler 不重复记录。生产环境开启堆栈（写入 `stack` 字段）、关闭 debug 模式（否则响应会带内部错误详情）。
- 定级按 HTTP 状态：4xx（含 `Exception`、`ValidateException`）记 WARN，5xx 与未知错误记 ERROR；只有 ERROR 进入错误追踪。因此服务端故障（数据库、下游不可用）不包成 `Exception`，直接返回 error（Gin 用 `c.Error`）；自行写出 500 不经框架捕获，不会上报。
- 错误追踪：经 `WithLogWriters` 接入 sentry-go 的 `sentryzerolog`，DSN 由 `SENTRY_DSN` 注入；writer 由框架关闭。
- `return err` 的堆栈只有框架调用链，出处靠 `%w` 附加的上下文判断；panic 的堆栈含出错行。
- 请求 id：日志字段名由 `application.trace.requestID` 决定（默认 `requestId`），Fiber `requestid` 的 `ContextKey` 从该配置读取、不写死；中间件没给值时框架退回请求头 `X-Request-ID`。没有反向代理时，在 requestid 中间件之前丢弃客户端传入的 `X-Request-ID`（中间件与框架兜底都会原样采信）。传递约定见 `rules/go/logging.md`「请求 id 传递」。
