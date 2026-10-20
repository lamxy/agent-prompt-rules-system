# Kafka 运维

应用侧的使用规范见 backend-dev 场景的 `.claude/rules/mq/kafka.md`。

## broker 参数起点

| 参数 | 建议 | 说明 |
|---|---|---|
| `auto.create.topics.enable` | `false` | topic 统一由运维创建 |
| `num.network.threads` | CPU 核数 + 1 | 处理网络请求；多个应用共用、并发高时调大 |
| `num.io.threads` | CPU 核数 × 2（不超过 × 3） | 处理磁盘 I/O；高峰期出现 I/O 等待时调整 |
| `default.replication.factor` / `min.insync.replicas` | 3 / 2（3 个 broker） | 重要数据提高副本数；与生产者 `acks=all` 配合才能保证不丢 |
| `message.max.bytes` | 1MB | 与客户端的单条消息上限一致 |

使用 ZooKeeper 的旧集群，`zookeeper.connection.timeout.ms` 可适当调大（如 10s）；新集群使用 KRaft。

## topic 管理

- 名称全小写，单词之间用 `-` 连接。
- 分区数按生产者与消费者的并发确定；集群分区总数要设上限（经验值：每个 broker 的分区副本数不超过数千）。分区越多，文件句柄、内存占用、不可用窗口和端到端延迟都会增加。
- 副本数按业务重要性调整。

## 安全与治理

交付集群前检查：

- [ ] 认证：SASL（SCRAM 或 OAuth），禁止匿名访问
- [ ] 授权：ACL 按 topic 与 consumer group 授权
- [ ] 传输加密：TLS
- [ ] 配额：按客户端限制连接数与生产、消费速率（quotas）
- [ ] 监控：broker 指标、consumer lag、按用户与 topic 统计的流量
