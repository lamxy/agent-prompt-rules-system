# MongoDB 运维

应用侧的使用规范见 backend-dev 场景的 `.claude/rules/database/mongodb.md`。

## 新库上线清单

业务方使用 MongoDB 前，需与架构负责人、DBA 一起评审需求，通过后再申请测试环境。上线申请需提供：

1. 业务系统名称与数据库名
2. 用户类型：C 端、B 端或内部用户
3. 数据库版本（默认使用当前维护中的稳定版本）
4. 是否需要备份，以及备份保留天数（默认 7 天）
5. 是否需要调整 oplog 大小（按写入量保证足够的复制窗口）
6. 是否需要数据库代理
7. 应用是否已支持切换地址（使用副本集连接串而非单个节点地址）
8. 数据库宕机会影响哪些业务
9. 哪些字段是敏感数据
10. 预估一年内的 QPS 峰值与最大集合数据量

## 运维约定

- 按业务边界分库；大集合需要独立权限、独立备份或在分片集群中分散主分片时才单独分库（WiredTiger 下分库不能减少写入互相影响）。
- 大集合在低峰期建索引。
- 删除数据后磁盘不会自动归还，提前规划归档与清理（TTL 索引、按时间分集合）。
- 应用账号只授予所需库的读写权限，不授予 `dbAdmin` 等管理角色。

## 备份与恢复

标「实测」的在 MongoDB 8.0 副本集上验证过，其余以官方文档为准。

| 方式 | 要点 |
|---|---|
| `mongodump --oplog` | 只支持整个实例导出，加 `--db` 时直接报错（实测）；恢复用 `mongorestore --oplogReplay` |
| 文件系统快照 | 不停机；journal 必须与数据文件在同一逻辑卷，否则要先 `db.fsyncLock()`；快照完成后尽快转存并删除快照 |
| 停止 secondary 后复制数据文件 | 期间副本集少一个成员，冗余下降 |
| 分片集群 | `mongodump` 需先停 balancer、停写入；快照需每个分片与 config server 大致同时拍；不停业务的一致备份需要 Ops Manager、Cloud Manager 或 Atlas |

时间点恢复（实测）：

1. 定期全量 `mongodump --oplog -o <全量目录>`。
2. 事故后导出 oplog：`mongodump -d local -c oplog.rs -o <oplog目录>`，把 `oplog.rs.bson` 复制为空目录下的 `oplog.bson`。
3. 在新实例上 `mongorestore --oplogReplay <全量目录>`，再 `mongorestore --oplogReplay --oplogLimit=<误操作时间的秒级时间戳> <上一步的目录>`。

实测中，全量后写入、误删前的 50 条被补回，误删没有被重放。注意：

- `--oplogReplay` 不能和 `--nsInclude` 一起用（报 `cannot use --oplogReplay with includes specified`，一条都不恢复），只能恢复整个实例后再取需要的库。
- 能恢复到的最早时间受 oplog 窗口限制，oplog 大小按写入量规划（见上线清单第 5 项）。
- 回放耗时与 oplog 条数成正比，大批量写入后的回放会很慢；定期演练恢复并记录耗时。

## 安全基线

- 开启认证：`security.authorization: enabled`（默认关闭）；副本集、分片成员之间用 `keyFile` 或 x.509 认证。
- 账号最小权限：应用账号只授予本业务库 `readWrite`，报表账号 `read`，运维账号按需授予 `clusterMonitor`、`backup`、`restore`；`root` 只留给少数管理员。
- 网络：只在内网或 VPC 暴露，`bind_ip` 绑定具体网卡，防火墙或安全组只放行应用网段；启用 TLS。
- 不用 root 运行 `mongod`。
- 应用不用 `mapReduce`、`$where`、`$accumulator`、`$function` 时，以 `--noscripting`（`security.javascriptEnabled: false`）关闭服务端 JavaScript。

## 巡检指标

| 指标 | 来源 | 说明 |
|---|---|---|
| 缓存脏数据比例 | `mongostat` 的 `dirty` | 脏数据上限为缓存的 20%，接近时写入变慢；持续偏高说明磁盘写入跟不上 |
| 缓存使用比例 | `mongostat` 的 `used` | 接近上限时应用线程会被拉去驱逐缓存 |
| 应用线程驱逐页数 | `db.serverStatus().wiredTiger.cache['pages evicted by application threads']` | 非零且持续增长表示缓存压力，查询延迟与复制延迟随之上升 |
| 排队请求 | `mongostat` 的 `qrw` | 持续排队时先查慢查询与索引，再考虑扩容 |
| 集合读写耗时 | `mongotop` | 定位压力集中在哪个集合 |
| 慢查询 | `mongod` 日志（默认记录超过 100ms 的操作）| 关注 `planSummary: COLLSCAN` 与 `docsExamined` 远大于返回数的记录 |
