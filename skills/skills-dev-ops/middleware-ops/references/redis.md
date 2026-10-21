# Redis 运维

应用侧的使用规范见 backend-dev 场景的 `.claude/rules/redis.md`。下文「实测」指 Redis 8.10.2（`redis:8` 镜像）与 7.4.11 的临时容器实测；版本敏感的参数以 `CONFIG GET` 为准。

## 架构选择

| 架构 | 适用 |
|---|---|
| 主从（含哨兵或云厂商托管的主从） | 单实例能承载的 QPS 与内存范围内（常见经验值：数万 QPS、内存在 25GB 以内；开启持久化时 fork 耗时随内存增长，偏向更小的实例） |
| Redis Cluster | 超出单实例能力，且业务代码不使用集群不支持的命令（跨 slot 多 key 操作、非 db0）；至少 3 主，常见 3 主 3 从 |

申请实例时要求业务方提供用量评估：key 数量、平均 value 大小、峰值 QPS 及计算方式。

主从复制是异步的：主库已确认的写入可能在故障切换时丢失（含分布式锁）。`WAIT` 只确认副本已收到、不保证持久化；`min-replicas-to-write` / `min-replicas-max-lag` 以拒绝写入换取更小的丢失窗口。要求强一致的业务不依赖 Redis。

## 内存与淘汰

- 淘汰策略默认 `volatile-lru`：只淘汰设了 TTL 的 key，因此业务必须给 key 设 TTL；纯缓存实例也可用 `allkeys-lru` / `allkeys-lfu`（批量扫描会污染 LRU，LFU 不受影响）。服务端内置默认值是 `noeviction`，新实例要显式配置。
- 实测：`volatile-*` 下没有带 TTL 的 key 时，内存超限后写入报 `OOM command not allowed`，一个 key 也不淘汰；读、`DEL`、`EXPIRE` 仍可执行。应急：`CONFIG SET maxmemory-policy allkeys-lru` 立即生效，随后 `CONFIG REWRITE` 或改配置文件，否则重启失效。
- 8.x 新增 `allkeys-lrm`、`volatile-lrm`（7.4 没有），语义按目标版本文档确认后再用。
- 设置 `maxmemory`，为复制缓冲、fork 写时复制与碎片预留内存；开启持久化的写入密集实例更保守。关闭透明大页（THP）。
- lazyfree 选项（`lazyfree-lazy-eviction`、`-expire`、`-server-del`、`-user-del`）在 7.4 与 8.10 默认均为 `no`：淘汰、过期与 `DEL` 大 key 都在主线程同步释放。实测 20 万成员 set 的 `DEL` 3443μs、`UNLINK` 8μs。大 key 较多的实例评估开启。
- 小集合编码阈值（`hash-max-listpack-entries` 等）不带配置文件时为 512 / 128，`redis.conf` 示例为 128；改动会影响内存，变更前后对比 `INFO memory`。

## 持久化

| 用途 | 配置 |
|---|---|
| 纯缓存（可从数据库重建） | 可关闭 RDB 与 AOF；确认数据库能承受冷启动回源 |
| 需要恢复数据 | AOF + `aof-use-rdb-preamble yes`（混合：重写后 base 为 RDB、增量为 AOF），`appendfsync everysec`（最多丢约 1 秒） |

- `appendfsync always` 每条写都 fsync，参考资料的单连接压测（Redis 8.2）比 `everysec` 慢约 33 倍；`no` 与 `everysec` 吞吐几乎相同，却有更长的丢失窗口，不用。
- RDB 快照、AOF 重写、主从全量同步都会 fork；fork 期间主线程阻塞，耗时随内存（页表）增长，用 `INFO stats` 的 `latest_fork_usec` 监控。线上不执行 `SAVE`（全程阻塞），用 `BGSAVE`。
- 可由从库承担持久化以避开主库 fork，但主库重启时若无持久化文件会以空数据启动并同步给从库，需禁止自动重启或先切换。

## 配置

- 用 ACL 或 `rename-command` 禁用 `KEYS`、`FLUSHALL`、`FLUSHDB`；`MONITOR` 只在运维排障时临时使用。
- 只使用 db0；业务需要其他 db 或要把 Redis 当持久存储时，走评审，并加强内存监控。
- `maxclients` 按客户端连接池总数设置；连接数接近上限时性能会明显下降。go-redis 默认每个进程 `10 * GOMAXPROCS` 个连接，用实例数 × 连接池大小估算。
- 慢查询：`slowlog-log-slower-than` 默认 10000μs，排障时可临时调低；`INFO commandstats` 查看 `KEYS` 等命令的调用次数。

## 巡检

- 找 bigkey：`redis-cli --bigkeys` 基于 `SCAN`、不阻塞，但每种类型只报最大的一个；全量排查用 `--memkeys` 或离线分析 RDB。不用 `KEYS` 排查。
- 检查没有 TTL 的 key 的比例（`INFO keyspace` 的 `keys` 与 `expires`）、`evicted_keys`、慢查询日志、`mem_fragmentation_ratio`。
- 过期 key 由访问时惰性删除与每秒 `hz` 次的抽样删除共同回收，大批 key 同时过期时会短暂占用内存；`DBSIZE` 可能包含尚未回收的过期 key。

## 数据迁移

迁移期间不重启实例、不做其他变更。

| 方式 | 步骤 | 注意 |
|---|---|---|
| 挂载为从库 | 新实例执行 `REPLICAOF <源地址> <端口>`；用 `INFO replication` 确认同步完成；业务停写后在新实例执行 `REPLICAOF NO ONE`，再为新主库挂从库 | 适合可以短暂停写的场景 |
| redis-shake 实时同步 | 源主库 → redis-shake → 目标主库；对比两边 key 数量与抽样数据；确认同步后切换业务配置，最后停止同步 | 已过期的 key 不同步；**非 db0 的数据不会同步** |
| RDB / 导出导入 | 在源实例导出 RDB（或 JSON），传到目标实例加载 | 简单，但只是时间点快照，切换前的增量会丢失 |
