---
paths:
  - "**/main.go"
  - "**/application_impl.go"
  - "**/module/*_impl.go"
  - "**/providers/**/*.go"
  - "**/module/*/api/**/*.go"
---

# FiberHouse 框架

适用于基于 [FiberHouse](https://github.com/lamxy/fiberhouse) 的项目。不使用 FiberHouse 的项目删除本文件。

- 能力只通过显式注册进入启动链：`ApplicationRegister`、`ModuleRegister`、`TaskRegister` 与 Provider / Manager。框架不扫描目录，新增模块、路由、中间件后要在对应注册器或 Provider 中接入。
- `Default()` 不会自动加入 `DefaultProviders()` / `DefaultPManagers(ctx)`，需要时由应用显式加入。
- 不 import FiberHouse 的 `example_*` 包作为依赖；需要时复制到自己的应用目录再修改。
- 内核由 `BootConfig.CoreType` 选择。Fiber handler 为 `func(*fiber.Ctx) error`，普通错误直接 `return err`；Gin handler 为 `func(*gin.Context)`，错误用 `c.Error(err)` 上报。路由、绑定与 handler 使用各内核的原生 API。
- 切换或新增内核时，只改传输边缘（请求绑定、响应写出、错误翻译），service 及以下保持不变。接入其他内核（如 Hertz）参照 FiberHouse 的 `example_application/hertzcore/`。
- 响应统一使用框架的 `{code,msg,data}` 结构，不在 handler 中自定义响应外壳。
- 跨组件共享的实例（数据库、缓存、codec 等）通过 `GlobalManager` / `Locator` 获取，不另建包级全局变量。
- 需要关闭的资源实现 `ClosableProvider`，由框架按注册的逆序关闭；不在业务代码中自行管理关闭顺序。
- 装配期的错误使用返回 error 的入口，不依赖 panic。
