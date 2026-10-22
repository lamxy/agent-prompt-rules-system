# MongoDB 设计参考

`.claude/rules/database/mongodb.md` 的补充说明。标「实测」的结论在 MongoDB 8.0 三节点副本集与 Go Driver v2 上验证过；其余以官方文档为准。早期版本（4.x）的资料中有几条已过时，见文末。

## 何时选 MongoDB

适合：文档结构随业务变化、以单文档读写为主、需要内嵌子对象的场景。不适合：多表关联多、强事务一致性、复杂报表。选用前与架构负责人或 DBA 一起评审需求。

## 分库与 `_id`

分库：WiredTiger 是文档级并发，库和集合层只有意向锁，分库不能减少写入互相影响（那是 MMAPv1 库级锁时代的理由）。分库现在的作用是按库授权、按库备份与删除，以及在分片集群中让各库的未分片集合落在不同的主分片（8.0 起也可用 `moveCollection` 单独迁移集合）。代价是 `$lookup` 只能关联同一个库的集合。

`_id` 实测（各插入 100 万条）：

| `_id` 类型 | 写入耗时 | `_id` 索引 | 数据存储 |
|---|---|---|---|
| ObjectID | 3.9s | 17.8 MB | 11 MB |
| UUID（二进制 16 字节） | 7.6s | 55.9 MB | 25 MB |
| UUID 字符串 | 8.7s | 52.4 MB | 46 MB |
| 聚簇集合（按 `_id` 存放）+ ObjectID | 3.8s | — | 13 MB |
| 聚簇集合 + UUID | 8.6s | — | 37 MB |

- ObjectID 以时间戳开头、近似递增，新值写在索引尾部；随机 UUID 散落在索引各处，写入慢一倍、索引大三倍。
- `_id` 不可修改（实测报 `would modify the immutable field '_id'`），业务值一旦要改只能删除重建，引用它的文档也要跟着改。
- 用不可变的自然键作 `_id` 能省一个唯一索引，并可直接按 `_id` 幂等 upsert。

## 建模三步

1. 按业务画出实体与关系（概念、逻辑模型）。文档模型的逻辑模型基本就是 JSON 结构，不必再单独做物理模型。
2. 按工况细化：最频繁的查询与写入、读写比例、数据量与增长速度，决定内嵌、引用或冗余。
3. 套用设计模式（下文），再用 `explain` 核对主要查询。

## 内嵌还是引用

| 关系 | 默认做法 | 改为引用的条件 |
|---|---|---|
| 1:1 | 内嵌 | 子数据很大或很少读取（基础信息与详情动静分离） |
| 1:N，N 有上限 | 内嵌数组 | 元素频繁单独修改 |
| 1:N，N 无上限 | 子集合存父 `_id` | — |
| N:N | 在读得多的一侧存对方 `_id` 数组 | 对方信息常改时不冗余对方字段，只存 `_id` |

冗余对方字段能省一次查询，代价是对方修改时要批量更新所有冗余副本。例如用户内嵌所属组的名称，改组名就要更新组内所有用户；组信息常改时只存 `group_ids`，读取时 `$lookup` 或二次查询。

文档持续变大会占用更多缓存、更新开销随之增加，超过 16MB 会写入失败；数组上的多键索引也随元素数量膨胀。

引用的限制：没有外键约束；`$lookup` 只能左外连接**同一个库**的集合，且只能在聚合管道中使用。MongoDB 5.1 起 `from` 可以是分片集合。

## 设计模式

| 模式 | 场景 | 做法 |
|---|---|---|
| 属性模式 | 字段很多且都要查，例如每个国家一个上映日期字段 | 列转行为数组 `releases: [{country, date}]`，建一个组合索引 `{"releases.country": 1, "releases.date": 1}`，替代每个字段一个索引；查询用 `$elemMatch` |
| 分桶 | 时序或日志类小记录 | 按时间段把多条记录合并进一个文档的数组，减少文档数与索引项 |
| 预聚合 | 需要精确计数 | 在文档中放统计子文档，写入时 `$inc` 对应维度 |
| 近似计数 | 访问量等允许误差的高频计数 | 在 Redis 中累计，定期批量 `$inc` 回写 |
| 模式版本 | 文档结构演进 | 加 `schema_version` 字段，读取时按版本兼容，后台逐步迁移 |

属性模式的陷阱（实测）：`find({"releases.country": "US", "releases.date": {$gt: D}})` 会命中「某个元素是 US、**另一个**元素日期大于 D」的文档，索引的日期边界也变成 `[MinKey, MaxKey]`；改为 `{releases: {$elemMatch: {country: "US", date: {$gt: D}}}}` 后结果正确，两个字段都用上索引边界。

## 索引

实测数据：10 万文档，查询 `a` 等值、`b` 范围、按 `c` 排序取 20 条。

| 结论 | 实测结果 |
|---|---|
| ESR：等值 → 排序 → 范围 | `{a, c, b}` 扫描 199 个索引项、无排序阶段；`{a, b, c}` 扫描 1000 个并出现内存 `SORT` |
| 只能用索引前缀 | 索引 `{a, b, c}` 能支持只查 `a`；只查 `b` 时走 `COLLSCAN` |
| 覆盖查询要排除 `_id` | projection `{_id: 0, a: 1, b: 1}` 为 `PROJECTION_COVERED`；不排除 `_id` 仍需 `FETCH` |
| 多键索引不能覆盖数组字段 | 只投影数组子字段时仍需 `FETCH` |
| 组合索引最多一个数组字段 | 建索引或写入两字段都是数组的文档时报 `CannotIndexParallelArrays` |
| 部分索引只在查询条件蕴含过滤表达式时才用 | 条件不蕴含时优化器走 `COLLSCAN`；用 `hint` 强制时返回 100 条，正确结果是 1000 条，不报错 |
| `background: true` 已无作用 | 4.2 起建索引统一为优化后的过程，选项被接受但忽略；大集合仍在低峰期建 |

TTL 索引由后台任务每 60 秒清理一次，过期文档不会准时删除。

## 分页与计数

| 做法 | 实测（10 万文档） |
|---|---|
| `Skip(90000).Limit(20)` | 扫描 90020 个索引项 |
| `_id > 上一页最后一条` + `Limit(20)` | 扫描 20 个索引项 |
| 无索引条件 `Limit(50)` | 找到 50 条即停，检查 332 个文档 |
| 同条件 `CountDocuments` | 检查全部 100000 个文档 |

按非唯一字段排序分页时，用 `(排序键, _id)` 作为游标，避免同值记录跳过或重复。

## 读写关注

| 项目 | 默认值（5.0+，实测） | 说明 |
|---|---|---|
| 写关注 | `w: "majority"` | 含仲裁节点且数据节点数不超过投票多数时（典型 PSA）默认为 `w: 1` |
| 读关注 | `local` | 可能读到之后被回滚的数据 |
| 读偏好 | `primary` | 读 secondary 会读到复制延迟前的旧数据 |

实测（两个 secondary 都被 `fsyncLock` 暂停复制）：

- `w: "majority", wtimeout: 2000`：约 2 秒后返回 `WriteConcernFailed`，但 primary 上已有这条数据，服务端不会撤销它，复制恢复后会继续同步；若 primary 在复制完成前故障，这条写入仍可能被回滚。超时既不等于没写入，也不等于已持久。
- 不使用显式会话时，`readConcern: "majority"` 读立即返回，只是看不到尚未被多数派确认的写入，相当于读已提交。
- 在显式会话（`client.StartSession()`，默认开启因果一致性）中先写再读 secondary：节点没追上本会话写入的时间点前，`majority` 与 `local` 读都会**等待**，实测一直等到 3 秒的 `context` 超时（`MaxTimeMSExpired`）。

需要「读到自己刚写的数据」又要读 secondary 时：用显式会话，读写关注都用 `majority`，读操作必须带超时；一个会话不能被多个 goroutine 并发使用。更简单的做法是这类读直接读 primary。

## 事务

实测：

- 两个事务改同一文档：后写的一方立即收到 `WriteConflict`，带 `TransientTransactionError` 标签，不会等锁。
- 事务未结束时，事务外的写入同一文档会阻塞，直到事务结束或自身超时（设 `maxTimeMS` 1.5 秒时以 `MaxTimeMSExpired` 结束）。长事务会拖住普通写入。
- 事务超过 `transactionLifetimeLimitSeconds`（默认 60 秒）后被中止，提交时报 `NoSuchTransaction`。
- Go Driver `WithTransaction` 遇到 `TransientTransactionError` 会**重新执行整个回调**（实测回调执行 2 次，最终数据正确）。回调内的非数据库副作用会重复发生。

官方文档（Transactions Production Considerations）：未提交的事务对 WiredTiger 缓存压力过大时以写冲突中止，大到缓存放不下时报 `TransactionTooLargeForCache`；批处理拆成小批次。

## Go 驱动

使用 v2（`go.mongodb.org/mongo-driver/v2`，FiberHouse 亦然）。网上与早期资料多为 v1 写法，常见差异：

| v1 | v2 |
|---|---|
| `primitive.ObjectID`、`primitive.NewObjectID()`、`primitive.DateTime` | `bson.ObjectID`、`bson.NewObjectID()`、`bson.DateTime`（`primitive` 包并入 `bson`） |
| `mongo.Connect(ctx, opts)`；`mongo.NewClient` + `client.Connect` | `mongo.Connect(opts)`，`NewClient` 已移除 |
| 回调参数 `mongo.SessionContext` | `context.Context` |
| `options.Find().SetMaxTime(d)` 等 | 已移除，用 `context` deadline 或 `SetTimeout` |
| `SetSocketTimeout` | 已移除 |
| 选项切片 `[]*options.FindOptions` | `[]options.Lister[options.FindOptions]` |

| 行为 | 结果（Go Driver v2.9，实测） |
|---|---|
| `UpdateOne` 的更新文档不含 `$` 操作符 | 驱动直接返回错误 `update document must contain key beginning with '$'`，不会整体替换；整体替换只能用 `ReplaceOne` |
| `UpdateMany` 传空过滤条件 | 不拦截，更新全部文档 |
| `context` 超时 | 正常中断慢查询，`mongo.IsTimeout(err)` 为 true |

服务端未关闭的游标 10 分钟后才超时释放（`cursorTimeoutMillis` 默认 600000）。

### 连接参数

| 参数（连接串 / `options.Client()`） | 驱动默认 | 建议 |
|---|---|---|
| `maxPoolSize` / `SetMaxPoolSize` | 100 | 按并发量设置，所有实例的连接总数不超过服务端上限 |
| `serverSelectionTimeoutMS` / `SetServerSelectionTimeout` | 30s | 保持默认或按可用性要求缩短 |
| `connectTimeoutMS` / `SetConnectTimeout` | 30s | 约 3s |
| `timeoutMS` / `SetTimeout` | 未设置 | 必须设置，或在每个请求的 `context` 上设 deadline；`0` 表示永不超时，不能使用 |

v2 已移除 `SetSocketTimeout` 与各操作的 `SetMaxTime`，超时统一由 `timeoutMS` 或 `context` 控制。参数名与默认值以项目所用驱动版本的文档为准。

## 早期资料中已过时的说法

| 旧说法 | 现状 |
|---|---|
| 大集合建索引要加 `background: true` | 4.2 起忽略该选项 |
| `$lookup` 的 `from` 不能是分片集合 | 5.1 起可以；8.0 起可在事务中对分片集合使用 `$lookup` |
| 要在配置中开启 `enableMajorityReadConcern` | 5.0 起固定为开启，不能修改 |
| 写关注默认 `w: 1` | 5.0 起默认 `w: "majority"`（PSA 等例外见上） |
| `readConcern: "majority"` 总会阻塞到数据被多数派确认 | 单独使用时不阻塞，返回多数派已确认的版本；只有在因果一致性会话中、节点落后于会话的写入时才等待 |
| 文档变大会导致频繁「移动」 | 那是已移除的 MMAPv1 引擎行为；WiredTiger 下的代价是整文档重写与 16MB 上限 |
