# MongoDB 设计参考

`.claude/rules/database/mongodb.md` 的补充说明。

## 何时选 MongoDB

适合：文档结构随业务变化、以单文档读写为主、需要内嵌子对象的场景。不适合：多表关联多、强事务一致性、复杂报表。选用前与架构负责人或 DBA 一起评审需求。

## 内嵌还是引用

| 选择 | 适用条件 |
|---|---|
| 内嵌 | 子数据总是随父文档一起读写，数量有上限（单文档上限 16MB） |
| 引用 | 子数据会无限增长、被多个父文档共享、或需要单独查询 |

无上限增长的数组（评论、日志）不要内嵌，否则文档持续变大并导致频繁移动。

## 分库与数据增长

- 增长快的集合单独放一个库，避免变更（重建索引、压缩）互相影响。
- 删除文档后磁盘空间不会立即归还操作系统；设计时就规划清理方式：TTL 索引、按时间分集合后整个 `drop`、或定期归档到冷存储。

## 索引

- 选择性高（取值分散）的字段放在组合索引前面；遵循 ESR 原则：等值（Equality）→ 排序（Sort）→ 范围（Range）。
- 数组字段的索引是 multikey 索引，每个元素一个索引项，元素多时索引膨胀；组合索引中最多只能有一个数组字段。
- MongoDB 4.2 起建索引不再长时间锁集合，旧版本需要 `background: true`；大集合仍应在低峰期建索引。

## 读写

- `UpdateOne` 不带更新操作符时，驱动会拒绝或整体替换文档，丢失其他字段；局部更新一律用 `$set`、`$inc` 等。
- 聚合管道以 `$match` 开头才能使用索引并尽早减少数据量。
- 用 `explain` 检查执行计划，确认是 `IXSCAN` 而不是 `COLLSCAN`。

## Go 驱动连接参数

| 参数（连接串 / `options.Client()`） | 驱动默认 | 建议 |
|---|---|---|
| `maxPoolSize` / `SetMaxPoolSize` | 100 | 按并发量设置，所有实例的连接总数不超过服务端上限 |
| `serverSelectionTimeoutMS` / `SetServerSelectionTimeout` | 30s | 保持默认或按可用性要求缩短 |
| `connectTimeoutMS` / `SetConnectTimeout` | 30s | 约 3s |
| `timeoutMS` / `SetTimeout` | 未设置 | 必须设置，或在每个请求的 `context` 上设 deadline；`0` 表示永不超时，不能使用 |

设置了 `timeoutMS` 后，`socketTimeoutMS`、`waitQueueTimeoutMS` 等旧参数会被忽略。参数名与默认值以项目所用驱动版本的文档为准。
