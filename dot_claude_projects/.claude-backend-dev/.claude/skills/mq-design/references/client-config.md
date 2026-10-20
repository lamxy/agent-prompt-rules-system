# 消息队列客户端参数

参数名与默认值以项目所用客户端版本的文档为准；下表的默认值来自 segmentio/kafka-go 与 rabbitmq/amqp091-go 的文档。

## Kafka 生产者

| Kafka 配置项 | kafka-go `Writer` 字段 | Java 客户端默认 | kafka-go 默认 | 建议 |
|---|---|---|---|---|
| `acks` | `RequiredAcks` | `all`（3.0 起） | `RequireNone` | 一般业务 `RequireOne`，不可丢失 `RequireAll` |
| `linger.ms` | `BatchTimeout` | 5ms（4.0 起，此前 0） | 1s | 同步发送且对延迟敏感时调到 5～50ms |
| `batch.size` | `BatchSize`（条数）/ `BatchBytes`（字节） | 16KB | 100 条 / 1MB | 按消息大小与吞吐调整 |
| `compression.type` | `Compression` | `none` | 无 | `snappy`、`lz4` 或 `zstd` |
| `max.request.size` | `BatchBytes` | 1MB | 1MB | 单条消息不超过 1MB |
| `max.block.ms` | 用 `WriteMessages` 的 `context` 超时 | 60s | — | 设短超时，例如 100ms～1s，避免请求线程长时间阻塞 |

## Kafka 消费者

| Kafka 配置项 | kafka-go `ReaderConfig` 字段 | 建议 |
|---|---|---|
| `enable.auto.commit` | 用 `FetchMessage` + `CommitMessages` 手动提交；`CommitInterval` 控制提交频率 | 处理成功后再提交 |
| `auto.offset.reset` | `StartOffset`（`kafka.FirstOffset` / `kafka.LastOffset`） | 按业务决定从最早还是最新开始 |
| `session.timeout.ms` | `SessionTimeout` | 约 30s |
| — | `QueueCapacity`、`MaxBytes` | 设上限，避免本地缓冲过大 |

## RabbitMQ

| 主题 | amqp091-go | 建议 |
|---|---|---|
| 预取 | `Channel.Qos(prefetchCount, 0, false)` | 按单条处理耗时设置，限制未确认的消息数 |
| 确认 | `Consume(..., autoAck=false, ...)` + `Delivery.Ack(multiple)` | 批量确认的条数随消息大小减少（见 rules） |
| 发布确认 | `Channel.Confirm(false)` + `NotifyPublish` | 不可丢失的消息开启 |
| 持久化 | `QueueDeclare(durable=true)`、`Publishing.DeliveryMode = amqp.Persistent` | 不可丢失的消息开启 |
| 重连 | 较新版本 `amqp.Config{Recovery: ...}`；否则 `NotifyClose` 后自行重建 | 必须处理 |
| 请求-回复超时 | 等待回复时用 `context` 超时 | 约 3s |
