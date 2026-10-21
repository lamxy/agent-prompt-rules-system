---
name: middleware-ops
description: 部署、调优、迁移或检查 Redis、Kafka、RabbitMQ、Elasticsearch、MongoDB 等中间件，部署 gRPC 服务（负载均衡、探针、优雅关闭），以及为业务系统和中间件配置监控告警基线。用户说「部署 Redis／Kafka／RabbitMQ／ES／MongoDB」「中间件调优」「Redis 迁移」「新库上线」「加监控告警」「中间件巡检」「gRPC 负载不均」时使用。应用代码如何使用这些中间件属于 backend-dev 场景，不使用本 skill。
---

# 中间件运维

按任务读取对应的参考文件，不需要全部读完：

| 任务 | 参考 |
|---|---|
| 业务系统与中间件的监控告警基线 | `references/monitoring.md` |
| Redis 架构选择、内存与淘汰、持久化、巡检、数据迁移 | `references/redis.md` |
| Kafka 集群参数、topic 管理、安全加固 | `references/kafka.md` |
| RabbitMQ vhost / 队列管理、内存水位 | `references/rabbitmq.md` |
| Elasticsearch 系统参数、分片与索引设置 | `references/elasticsearch.md` |
| MongoDB 新库上线清单、备份与时间点恢复、安全基线、巡检指标 | `references/mongodb.md` |
| gRPC 服务的 K8s 负载均衡、探针、优雅关闭、keepalive、监控 | `references/grpc.md` |

## 通用约定

- 参数修改写进 IaC（Terraform、Helm values、Ansible），不在机器上手改；变更前先展示差异，确认后再执行（见 `CLAUDE.md`）。
- 中间件资源（topic、队列、vhost、数据库账号）由运维统一创建，业务方通过工单或合并请求提交申请，申请中写明用量评估及计算方式。
- 新中间件实例必须先接入监控（exporter + 告警规则）再交付使用。
- 管理端口与数据端口不暴露到公网，只对集群内部和指定业务开放。
- 参考文件中的数值是常见的起点，按实际压测结果与版本文档调整，并在变更说明中写明依据。
