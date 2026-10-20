---
paths:
  - "**/*_test.go"
---

# Go 测试

- 多组输入用表驱动测试，每组用 `t.Run` 命名为子测试。
- 资源清理用 `t.Cleanup`；不用 `time.Sleep` 等待异步结果，改用 channel、`context` 超时或轮询加上限。
- service 测试通过接口替换 repository；不为了测试而导出内部函数。
- 依赖真实 MySQL、MongoDB、Redis、MQ 的集成测试必须可跳过：用环境变量（如 `<PROJECT>_INTEGRATION=1`）或 build tag 开启，默认的 `go test ./...` 不需要外部服务。
- 集成测试的数据与 key 带唯一后缀（时间戳、进程 ID），清理时只删除本测试创建的数据。
- 涉及并发的测试用 `go test -race` 运行。
