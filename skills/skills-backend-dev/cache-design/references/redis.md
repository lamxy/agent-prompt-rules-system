# Redis 参考

`.claude/rules/redis.md` 的条目理由。

## 为什么

| 规则 | 理由 |
|---|---|
| 分层 key 命名 | 便于按前缀统计内存、定位所属服务，以及用 `SCAN MATCH` 排查；数据类型段让巡检脚本不必逐个 `TYPE` |
| 禁止 bigkey | Redis 命令在单线程中执行，操作大 key 耗时长，会阻塞其他请求；还会造成集群节点内存不均衡、网络流量过大（1MB 的 key 每秒读 1000 次就是约 1GB/s） |
| 必须设 TTL | 没有 TTL 的 key 只增不减；常见的淘汰策略 `volatile-lru` 只淘汰设了过期时间的 key，内存满后写入会失败 |
| TTL 加随机偏移 | 大批 key 同时过期会让请求同时回源，压垮数据库 |
| `MGET` / pipeline 分批 | 批量命令能减少往返，但单次数量过多会变成慢查询，并在集群模式下涉及多个节点 |
| 不用 `KEYS`、`MONITOR` | 阻塞命令，数据量大时会让实例停止响应、CPU 飙升 |
| 不用 `FLUSHALL`、`FLUSHDB` | 原子执行且无法撤销 |
| 只用 db0 | Redis Cluster 只支持 db0；部分迁移与同步工具也不会迁移其他 db |
| 长连接与连接池 | 频繁建立连接浪费资源，在云网络中短连接还容易超时；单实例连接数有上限 |
| 不当消息队列用 | 缺少持久化保证、消费确认和积压处理能力；需要队列时用 Kafka（高吞吐）或 RabbitMQ（可靠投递、灵活路由） |
| `SET NX EX` 加锁 | `SETNX` 后再 `EXPIRE` 不是原子操作，进程在两步之间崩溃会留下永不过期的锁 |
| 少用事务 | `MULTI` / `EXEC` 不支持回滚，集群下还要求 key 在同一 slot；出错时由应用补偿 |
| Lua 的 key 通过 `KEYS` 传入 | 集群按 `KEYS` 参数路由；脚本执行期间整个实例被占用，脚本必须很快 |
| 避免 value 大小频繁变化 | 从小变大会产生内存碎片 |

## 时间复杂度为 O(N) 的常用命令

N 较大时谨慎使用，优先用分页或 `SCAN` 系列命令。

| 类型 | 命令 |
|---|---|
| string | `MSET`、`MSETNX`、`MGET` |
| list | `LRANGE`、`LINDEX`、`LSET`、`LINSERT`（后三个按位置访问，长列表尤其慢） |
| hash | `HGETALL`、`HKEYS`、`HVALS`、多字段 `HDEL` |
| set | `SMEMBERS`、`SUNION` / `SUNIONSTORE`、`SINTER` / `SINTERSTORE`、`SDIFF` / `SDIFFSTORE`；`SPOP` / `SRANDMEMBER` 取多个时 |
| zset | `ZRANGE` / `ZREVRANGE`、`ZRANGEBYSCORE` / `ZREVRANGEBYSCORE`、`ZREMRANGEBYRANK` / `ZREMRANGEBYSCORE`（O(log N + M)，M 为返回或删除的数量） |
| 通用 | 多 key `DEL`、`KEYS` |

## value 大小与 QPS

超过 10KB 的 value 应优化；确实无法避免时，按大小限制访问频率（单实例参考值）：

| value 大小 | QPS 上限 |
|---|---|
| 10KB～20KB | 1000 |
| 20KB～50KB | 500 |
| 50KB～100KB | 100 |
| 超过 100KB | 不允许，改存其他存储 |

## go-redis 客户端

- `Options` 中设置 `DialTimeout`、`ReadTimeout`、`WriteTimeout`、`PoolSize`、`MinIdleConns`；默认值随版本变化，显式设置比依赖默认值可靠。
- 需要让命令遵守请求 `context` 的 deadline 时，开启 `ContextTimeoutEnabled`。
- 集群用 `redis.NewClusterClient`，代码中避免跨 slot 的多 key 命令。
