# 监控告警基线（Prometheus）

起步阶段用 `observability.md` 的组合（Uptime Kuma、GlitchTip、Beszel），不部署 Prometheus。需要应用层指标（QPS、错误率、延迟分布）或中间件的细粒度指标时，再升级到 Prometheus + Alertmanager（Grafana 可选），以本文为基线；exporter 名称为社区常用实现，按实际部署选择。

- 告警通知用 Alertmanager 的 `telegram_configs`（官方 receiver），与起步阶段一样发到 Telegram。
- 数据保留：`--storage.tsdb.retention.time` 默认 15d；小硬盘再加 `--storage.tsdb.retention.size` 限制容量。

## 主机

每台服务器默认采集：CPU、内存、磁盘（使用率与 I/O）、网络流量、TCP 连接状态（node_exporter）。

## 应用

每个生产环境业务系统必须有：

- 健康检查端点（如 `/healthz`），并配置容器 `healthcheck`
- 核心业务端口的存活探测（blackbox_exporter）
- QPS 突增、突降告警
- 响应时间（P95 / P99）与错误率告警
- 日志中 `ERROR` 级别的告警（由日志平台按级别或告警字段触发）

## 中间件

| 中间件 | Exporter | 必备告警 |
|---|---|---|
| Redis | redis_exporter | 内存使用率、网络 I/O、连接数、慢查询、主从复制状态 |
| Kafka | kafka_exporter（+ JMX exporter） | broker 内存与 CPU、网络 I/O、consumer group 积压（lag）、端口存活、未同步副本 |
| RabbitMQ | 内置 `rabbitmq_prometheus` 插件 | 内存、可用磁盘、文件句柄、socket 数、连接与 channel 数、生产与消费速率、未确认消息数、就绪消息数、消费者数量为 0 |
| Elasticsearch | elasticsearch_exporter | 集群状态（yellow / red）、JVM 堆与 GC、CPU、网络 I/O、磁盘水位、HTTP 端口存活 |
| MongoDB | mongodb_exporter | 连接数、复制延迟、oplog 窗口、慢操作、磁盘 |

## 告警规则

- 新增告警通过合并请求提交，写明阈值依据，并附 runbook 链接。
- 告警的接收人与升级路径集中在告警平台配置，不写在各个规则里。
