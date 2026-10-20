# Redis 运维

应用侧的使用规范见 backend-dev 场景的 `.claude/rules/redis.md`。

## 架构选择

| 架构 | 适用 |
|---|---|
| 主从（含哨兵或云厂商托管的主从） | 单实例能承载的 QPS 与内存范围内（常见经验值：数万 QPS、内存在 25GB 以内） |
| Redis Cluster | 超出单实例能力，且业务代码不使用集群不支持的命令（跨 slot 多 key 操作、非 db0） |

申请实例时要求业务方提供用量评估：key 数量、平均 value 大小、峰值 QPS 及计算方式。

## 配置

- 淘汰策略默认 `volatile-lru`：只淘汰设了 TTL 的 key，因此业务必须给 key 设 TTL；纯缓存实例也可用 `allkeys-lru`。
- 设置 `maxmemory`，为复制缓冲与 fork 预留内存。
- 用 `rename-command` 或 ACL 禁用 `KEYS`、`FLUSHALL`、`FLUSHDB`；`MONITOR` 只在运维排障时临时使用。
- 只使用 db0；业务需要其他 db 或要把 Redis 当持久存储时，走评审，并加强内存监控。
- `maxclients` 按客户端连接池总数设置；连接数接近上限时性能会明显下降。

## 巡检

- 定期用 `redis-cli --bigkeys`、`--memkeys` 或离线分析 RDB 找出 bigkey，通知业务方整改。
- 检查没有 TTL 的 key 的比例与慢查询日志。

## 数据迁移

迁移期间不重启实例、不做其他变更。

| 方式 | 步骤 | 注意 |
|---|---|---|
| 挂载为从库 | 新实例执行 `REPLICAOF <源地址> <端口>`；用 `INFO replication` 确认同步完成；业务停写后在新实例执行 `REPLICAOF NO ONE`，再为新主库挂从库 | 适合可以短暂停写的场景 |
| redis-shake 实时同步 | 源主库 → redis-shake → 目标主库；对比两边 key 数量与抽样数据；确认同步后切换业务配置，最后停止同步 | 已过期的 key 不同步；**非 db0 的数据不会同步** |
| RDB / 导出导入 | 在源实例导出 RDB（或 JSON），传到目标实例加载 | 简单，但只是时间点快照，切换前的增量会丢失 |
