---
paths:
  - "**/api/**/*.go"
  - "**/handler/**/*.go"
  - "**/router/**/*.go"
  - "**/middleware/**/*.go"
---

# Gin

适用于使用 Gin 内核的项目（原生 Gin，或 FiberHouse 的 Gin 内核）。不使用 Gin 的项目删除本文件。

- 传给 service 的是 `c.Request.Context()`，不是 `*gin.Context`。
- 需要在 goroutine 中使用请求数据时，先取出所需的值或使用 `c.Copy()`，不直接把 `c` 交给 goroutine。
- 绑定用 `ShouldBind*`，自行决定错误响应；`Bind*` 会自动写入 400 并可能与统一错误处理冲突。
- 错误用 `c.Error(err)` 上报并中止，由统一的错误处理中间件转换为响应。
