# RabbitMQ 运维

应用侧的使用规范见 backend-dev 场景的 `.claude/rules/mq/rabbitmq.md`。

## 资源创建

- 关闭业务账号的 configure 权限，交换机与队列由运维创建；业务方申请时提供：vhost、交换机名与类型、队列名、绑定键、是否持久化、死信配置、消息大小与速率、生产方与消费方服务、负责人。
- 不使用默认 vhost `/`；每个业务一个 vhost，账号只授权到自己的 vhost。
- 同一集群内队列名不重复（即使位于不同 vhost），便于监控与排障。

## 配置

- `vm_memory_high_watermark` 设在 0.4～0.6 之间（官方建议范围约 0.4～0.66），超过会更早触发流控阻塞生产者。
- 设置磁盘可用空间下限 `disk_free_limit`。
- 同一机房的服务直接连接同一集群；跨机房复制（shovel、federation）只用于确实需要跨机房的场景。
- 新集群优先使用 quorum 队列保证可靠性。
