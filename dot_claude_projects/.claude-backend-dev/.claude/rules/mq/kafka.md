---
paths:
  - "**/kafka/**/*.go"
  - "**/*kafka*.go"
  - "**/mq/**/*.go"
  - "**/producer/**/*.go"
  - "**/consumer/**/*.go"
---

# Kafka

客户端以 segmentio/kafka-go 为例，其他客户端按同名的 Kafka 配置项对应。不用 Kafka 的项目删除本文件。设计主题与消费方式时用 `mq-design` skill。

## topic

- 名称全小写，单词之间用 `-` 连接，不混用 `.` 与 `_`；例如 `order-created`。
- topic 由运维或 IaC 创建，代码不依赖自动创建（kafka-go `Writer.AllowAutoTopicCreation` 保持 `false`）。
- 分区数按消费并发确定，同一 consumer group 的消费者数量不超过分区数。

## 生产者

- 显式设置 `RequiredAcks`：一般业务用 `kafka.RequireOne`，不能丢的消息用 `kafka.RequireAll`。kafka-go 的默认值是 `RequireNone`（不等确认），不能沿用。
- kafka-go 的 `BatchTimeout` 默认 1s，同步写入会因此最多等待 1s；对延迟敏感时调低（Java 客户端常用 `linger.ms=5`）。
- 开启压缩（`Compression`，如 `kafka.Snappy` 或 `kafka.Zstd`）；单条消息不超过 1MB。
- `Async: true` 会忽略写入错误，只用于可丢失的消息，并设置 `Completion` 回调记录失败。
- 需要按业务键保持顺序时设置消息 `Key`。
- 客户端协议版本不高于 broker 版本。

## 消费者

- 消息处理成功后再提交 offset：用 `FetchMessage` + `CommitMessages`，不用处理前就提交的 `ReadMessage`。
- 消费处理必须幂等（业务唯一键、去重表或状态机），Kafka 可能重复投递。
- `GroupID` 使用固定名称，不包含任务 ID、主机名等变量。
- 消费循环有退出机制（`context` 取消），退出时调用 `Reader.Close()` 离开 group，避免其他成员等待 session 超时；不频繁加入、退出 group。
- 处理单条消息时不长时间阻塞，避免超过 session 超时引发 rebalance；`SessionTimeout` 约 30s。
- 本地缓冲（`QueueCapacity`、`MaxBytes`）设上限，避免内存溢出。
