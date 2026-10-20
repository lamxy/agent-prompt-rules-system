---
paths:
  - "**/api/**/*.go"
  - "**/handler/**/*.go"
  - "**/router/**/*.go"
  - "**/middleware/**/*.go"
---

# Fiber

适用于使用 Fiber 内核的项目（原生 Fiber，或 FiberHouse 的 Fiber 内核）。不使用 Fiber 的项目删除本文件。

- `*fiber.Ctx` 及其返回的字符串、`[]byte`（`c.Params`、`c.Query`、`c.Body` 等）只在 handler 返回前有效；需要在 handler 之后使用（存入结构体、交给 goroutine、放进缓存）时先复制。
- 不把 `*fiber.Ctx` 传给 goroutine 或 service；传给 service 的是 `c.UserContext()`。
- 错误直接 `return err`，由统一的错误处理器转换为响应；不在每个 handler 中各自拼错误响应。
- 请求体用 `c.BodyParser` 绑定后再做字段校验，校验失败返回 400。
