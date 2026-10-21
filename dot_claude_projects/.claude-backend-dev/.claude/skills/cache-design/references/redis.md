# Redis 参考

`.claude/rules/redis.md` 的条目理由与实测依据。场景模板（锁、限流、击穿、一致性）见 `patterns.md`。

## 为什么

| 规则 | 理由 |
|---|---|
| 分层 key 命名 | 便于按前缀统计内存、定位所属服务，以及用 `SCAN MATCH` 排查；数据类型段让巡检脚本不必逐个 `TYPE` |
| hash tag `{...}` | 只有 `{}` 内的内容参与 slot 计算，同 tag 的 key 落在同一 slot，但无法再分散到多个节点。key 规则目前禁止 `}`，需要 hash tag 时先与项目约定确认 key 格式 |
| 禁止 bigkey | Redis 命令在单线程中执行，操作大 key 耗时长，会阻塞其他请求；还会造成集群节点内存不均衡、网络流量过大（1MB 的 key 每秒读 1000 次就是约 1GB/s）；一个 key 只能在一个 slot，扩容拆不开 |
| 必须设 TTL | 没有 TTL 的 key 只增不减；`volatile-*` 淘汰策略只淘汰设了 TTL 的 key，没有候选时写入直接报 OOM（实测见下） |
| TTL 加随机偏移 | 大批 key 同时过期会让请求同时回源，压垮数据库；偏移量取基础时长的 10%～20% |
| 删大 key 用 `UNLINK` | `DEL` 在主线程同步释放内存，大集合同样阻塞；`UNLINK` 交给后台线程 |
| `MGET` / pipeline 分批 | 批量命令能减少往返，但单次数量过多会变成慢查询，并在集群模式下涉及多个节点 |
| 不用 `KEYS`、`MONITOR` | 阻塞命令，数据量大时会让实例停止响应、CPU 飙升；`SCAN` 的安全来自每次只扫一小批，`COUNT` 调到上万同样会进慢查询 |
| `SCAN` 结果去重 | 遍历期间发生 rehash 时同一个 key 可能返回多次；遍历开始后新增的 key 不保证返回 |
| 不用 `FLUSHALL`、`FLUSHDB` | 原子执行且无法撤销 |
| 只用 db0 | Redis Cluster 只支持 db0；部分迁移与同步工具也不会迁移其他 db |
| 长连接与连接池 | 频繁建立连接浪费资源，在云网络中短连接还容易超时；单实例连接数有上限 |
| 不当消息队列用 | 缺少持久化保证、消费确认和积压处理能力，堆积全部占内存；需要队列时用 Kafka（高吞吐）或 RabbitMQ（可靠投递、灵活路由），取舍见 `patterns.md` |
| `SET NX PX` 加锁 | `SETNX` 后再 `EXPIRE` 不是原子操作，进程在两步之间崩溃会留下永不过期的锁 |
| 不用事务 | `MULTI` / `EXEC` 中某条命令运行期出错，其他命令照常提交、不回滚；只有入队时的语法错误才让整个事务被丢弃；集群下还要求 key 在同一 slot。需要「判断 + 写入」用 Lua |
| Lua 的 key 通过 `KEYS` 传入 | 集群按 `KEYS` 参数路由，脚本访问未声明且不在本节点的 key 会报错；脚本执行期间整个实例被占用，脚本必须很快，不在脚本里遍历大集合 |
| 避免 value 大小频繁变化 | 从小变大会产生内存碎片 |

## 数据类型的内存编码

小集合用紧凑编码（listpack / intset），超过阈值转为 hashtable / skiplist / quicklist，**转换单向**：删回很少的元素也不会变回 listpack。阈值按实例配置，用 `CONFIG GET *-max-*` 查看，不要背默认值。

| 配置 | 不带配置文件启动的值（7.4、8.x 实测） | 说明 |
|---|---|---|
| `hash-max-listpack-entries` / `-value` | 512 / 64 字节 | 字段数或任一值长度超过即转换；`redis.conf` 示例文件写的是 128，部署时可能被改小 |
| `zset-max-listpack-entries` / `-value` | 128 / 64 字节 | |
| `set-max-intset-entries` | 512 | 成员全为整数时用 intset |
| `set-max-listpack-entries` | 128 | |
| `list-max-listpack-size` | -2（每个节点 8KB） | |

String 存 JSON 还是 Hash：

- 整体读写用 String（一次往返；支持嵌套结构）。只改个别字段、计数、只读几个字段用 Hash（`HINCRBY`、`HMGET`）；String 存 JSON 的「读 → 改 → 写」在并发下会丢更新。
- Hash 只在 listpack 编码下省内存。实测（Redis 8.10.2，`MEMORY USAGE`）：20 个字段 Hash 372 字节、JSON String 471 字节；600 个字段（已转 hashtable）Hash 30856 字节，是 String 14360 字节的 2.1 倍。
- 7.4 起 Hash 支持字段级 TTL（`HEXPIRE` / `HTTL`），旧版本只能拆 key；先确认线上版本。

## 时间复杂度为 O(N) 的常用命令

N 较大时谨慎使用，优先用分页或 `SCAN` 系列命令。

| 类型 | 命令 |
|---|---|
| string | `MSET`、`MSETNX`、`MGET` |
| list | `LRANGE`、`LINDEX`、`LSET`、`LINSERT`（后三个按位置访问，长列表尤其慢） |
| hash | `HGETALL`、`HKEYS`、`HVALS`、多字段 `HDEL` |
| set | `SMEMBERS`、`SUNION` / `SUNIONSTORE`、`SINTER` / `SINTERSTORE`、`SDIFF` / `SDIFFSTORE`；`SPOP` / `SRANDMEMBER` 取多个时 |
| zset | `ZRANGE` / `ZREVRANGE`、`ZRANGEBYSCORE` / `ZREVRANGEBYSCORE`、`ZREMRANGEBYRANK` / `ZREMRANGEBYSCORE`（O(log N + M)，M 为返回或删除的数量） |
| 通用 | 多 key `DEL`、`KEYS`；删除大集合的 `DEL` |

## value 大小与 QPS

超过 10KB 的 value 应优化；确实无法避免时，按大小限制访问频率（单实例参考值）：

| value 大小 | QPS 上限 |
|---|---|
| 10KB～20KB | 1000 |
| 20KB～50KB | 500 |
| 50KB～100KB | 100 |
| 超过 100KB | 不允许，改存其他存储 |

## go-redis 客户端

当前 v9 最新为 v9.23.0，要求 `go` ≥ 1.26；`go` 1.25 的模块最高用 v9.22.0（已核对两版的 `go.mod`）。

- 默认值随版本变化：v9.17 的 `ReadTimeout` / `WriteTimeout` 为 3 秒、重试退避 8ms～512ms，v9.22 起为 5 秒、10ms～1s。显式设置 `DialTimeout`、`ReadTimeout`、`WriteTimeout`、`PoolSize`（默认 `10 * GOMAXPROCS`）、`PoolTimeout`（默认 `ReadTimeout + 1s`）、`MinIdleConns`。
- `ContextTimeoutEnabled` 默认关闭：关闭时请求 ctx 的 deadline 不影响命令，只受 socket 超时约束。
- `MaxRetries`：0 表示默认 3 次，`-1` 才关闭。连接池取连接超时也会被重试，实际等待约为 `PoolTimeout` 的数倍。
- `SetNX(ctx, k, v, ttl)` 在 `ttl > 0` 时发送 `SET k v PX/EX ttl NX`；`ttl` 为 0 时不设过期。需要更多参数用 `SetArgs`，key 已存在时返回 `redis.Nil`。
- `redis.NewScript(...).Run` 先发 `EVALSHA`，服务端无缓存时自动改用 `EVAL`，`SCRIPT FLUSH` 后照常工作。
- 集群用 `redis.NewClusterClient`；按 slot 拆分请求的只有 pipeline，`MGet`、`MSet`、多 key `Del`、`Do("MGET", ...)` 都不会自动拆分。

## 实测记录

Redis 8.10.2（`redis:8` 镜像）单机与 3 主集群、7.4.11 对照；go-redis v9.22.0（集群行为另以 v9.17.3 对照，结果相同）；Go 1.25.14。

| 现象 | 结果 |
|---|---|
| Hash 加到 600 个字段后删到 4 个 | 仍是 `hashtable`；单个值 65 字节立即转 `hashtable` |
| 20 万成员 set：`SMEMBERS` / `DEL` / `UNLINK` | 5111μs / 3443μs / 8μs；`lazyfree-lazy-user-del` 等 lazyfree 选项默认均为 `no` |
| `MULTI` 中 `INCRBY` 参数个数错误 | `EXECABORT`，整个事务丢弃 |
| `MULTI` / `TxPipelined` 中对字符串 `INCR` | 返回错误，同事务其他 `SET` 已生效 |
| `volatile-lru`、无 key 设 TTL、内存超限 | 写入报 `OOM command not allowed`，一个 key 也未淘汰；`GET`、`EXPIRE`、`DEL` 仍可执行；改 `allkeys-lru` 后立即淘汰并写入成功 |
| 服务端被慢脚本占住约 0.4s，客户端 `ReadTimeout` 300ms 执行 `INCR` | 默认重试：返回成功，计数器为 **2**；`MaxRetries: -1`：返回超时错误，计数器仍为 **1** |
| `ContextTimeoutEnabled` false / true，ctx 超时 200ms，服务端暂停 1.5s | false：等待 1.57s 后成功；true：200ms 超时返回 |
| `PoolSize: 2` 全被阻塞命令占用，`PoolTimeout` 200ms | 默认重试：约 970ms 后返回 `redis: connection pool timeout`；`MaxRetries: -1`：200ms |
| pipeline 含一个未命中的 `Get` | `Exec` 返回 `redis.Nil`，其他命令结果正常 |
| 20 个 goroutine 用 `Watch` 各加 50 次 | 结果 1000，期间 `TxFailedErr` 5649 次（高竞争下乐观锁重试成本高） |
| 集群跨 slot `MGet` / `MSet` / `Del` / Lua / `TxPipelined` | 均 `CROSSSLOT`；pipeline 正常；hash tag 同 slot 后 Lua 与 `TxPipelined` 正常 |
| 集群 Lua 访问未经 `KEYS` 声明的其他节点 key | `Script attempted to access a non local key` |
| 集群 300 个 key，`ClusterClient.Scan` 迭代器 | 结果不完整且每次不同（两次分别 199、150 个，每次调用可能落到不同节点）；`ForEachMaster` 逐节点 `Scan` 返回 300 个 |
| 淘汰策略 | 8.10.2 可选值多了 `allkeys-lrm`、`volatile-lrm`（7.4.11 没有），语义未验证 |
