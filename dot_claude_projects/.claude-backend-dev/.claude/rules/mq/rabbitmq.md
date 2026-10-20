---
paths:
  - "**/rabbitmq/**/*.go"
  - "**/*rabbit*.go"
  - "**/*amqp*.go"
  - "**/mq/**/*.go"
  - "**/producer/**/*.go"
  - "**/consumer/**/*.go"
---

# RabbitMQ

客户端以 rabbitmq/amqp091-go 为例。不用 RabbitMQ 的项目删除本文件。设计交换机与队列时用 `mq-design` skill。

## 拓扑与命名

- 交换机、队列、绑定由运维或 IaC 预先创建；代码只用 passive 声明（`ExchangeDeclarePassive`、`QueueDeclarePassive`）检查其存在，不在启动时自动创建。
- 不用默认 vhost `/`，每个业务使用自己的 vhost；不用默认交换机（`""`），队列绑定到自定义交换机。
- 名称只用小写字母、数字、`.`、`-`、`_`，不含 `! @ " ' $ % # ^ & * ? < >`。
- 交换机名：`<业务>.<生产方服务>`；队列名：`<业务>.<消费方服务>`；同一集群内队列名不重复，即使在不同 vhost。

## 消息与确认

- 单条消息不超过 500KB；消息越大，单次批量确认的条数越少：1KB 约 5000 条，10KB 约 500 条，100KB 约 50 条，100～500KB 逐条确认。
- 消费者用手动确认（`Consume` 的 `autoAck=false`），处理成功后 `Ack`，失败时 `Nack` 并决定是否重新入队；用 `Channel.Qos` 限制预取数量。
- 不能丢的消息：持久化队列、`DeliveryMode: amqp.Persistent`，并开启 publisher confirm（`Channel.Confirm` + `NotifyPublish`，监听通道的缓冲至少等于未确认的消息数）。
- 消费处理必须幂等，重复投递不产生副作用。

## 连接

- 一个进程复用少量长连接，channel 不跨 goroutine 共享。
- 必须处理断线重连：较新版本的 amqp091-go 可用 `Config.Recovery`，否则监听 `NotifyClose` 自行重建连接、channel 与消费者；以项目使用的版本为准。
- RPC 式调用（等待回复）要设超时（约 3s），拉取式 `Get` 不无限阻塞。
