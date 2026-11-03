# MongoDB 场景案例调研（电商、聊天、替代 MySQL）

日期：2026-11-03。子代理只读调研，主会话抽查；未做 MongoDB 实测。原始抓取在会话 scratchpad（`mongodb-cases/raw/`），随会话清理，下文给出 URL 或仓库路径。

可信度：**原文**＝读过原始页面或源码；**存档**＝经 archive.org 读到原文；**摘要**＝只有 WebFetch 或搜索摘要。

主会话抽查（原文核对一致）：Rocket.Chat `Messages.ts` 索引 `{ rid: 1, ts: 1, _updatedAt: 1 }`；官方 Bucket Pattern 分页用 `skip`（`find({_id: /^123_/}).sort({_id:1}).skip(9).limit(1)`）；官方 Attribute Pattern `createIndex({ releases: 1 })`；Coinbase「connection storms」「MongoDB death loop」、K-V 数据移到 DynamoDB；Reaction `startup.js` 多处 `$inc`。更正：Sarah Mei 原文为「four pair-weeks」（结对），子代理误作 4 人周。

## 1. 结论

### 电商

1. 商品与 SKU 分开存，另存一份给前台读的发布版。官方 2015 参考架构〔E1〕：变体 `_id` 为 SKU、`itemId` 指回商品，理由是文件大小可预期；Reaction Commerce〔E5〕用 `ancestors` 表示层级，另有 `Catalog` 存反正规化发布文档。
2. 扣库存用带条件的单文档原子更新，不无条件 `$inc`。Kvalheim（前 MongoDB Node 驱动负责人）〔E3〕：`update({_id, quantity:{$gte:q}}, {$inc:{quantity:-q}, $push:{reserved:…}})`，更新 0 笔即回滚。反例 Reaction〔E5〕：建单事件后无条件 `$inc inventoryReserved`，失败只记日志，靠重算修正。需实测 T2。
3. 订单内嵌下单时的商品子集快照；评论用子集模式（商品只内嵌最近 N 条，全部放 `reviews`）〔E2〕。
4. 按店定价用组合 `_id`（`<id>_<store>`），批量取价用 `$in`〔E1〕；官方前缀正则 `/^30671/` 没带分隔符，会误中 `306710_…`，应写 `/^30671_/`（T3）。
5. 属性差异大的商品用属性模式 `[{k,v}]`；官方索引写法与仓库不同（见第 3 节冲突 1，T1）。

### 聊天

1. 消息一条一文档，主索引为会话 id + 时间：Rocket.Chat〔C4〕`{rid, ts, _updatedAt}`；Discord 2015〔C1〕`channel_id + created_at`。
2. 未读数放「用户 × 会话」订阅文档〔C4〕：`{rid, u._id}` 唯一，字段含 `unread`、`alert`、`ls`；发消息时 `updateMany({rid, 'u._id':{$nin:…}}, {$set:{alert:true}, $inc:{unread:n}})`，写入次数与群人数成正比（T6）。
3. 分桶读得快、写入复杂：官方社区博客〔C2〕比较读时扇出、写时扇出、写时扇出加分桶（每桶 50 条，片键 `{owner, sequence}`）；官方文档〔C3〕指出时间序列集合会自动分桶。
4. 反例 Discord〔C1〕：2015-11 约 1 亿条消息时数据与索引放不进 RAM、延迟不可预测；当时只用单一副本集、不分片；2017 年改 Cassandra，主键 `((channel_id, bucket), message_id)`。MongoDB 3.x 以前，不能推论到 8.0。
5. 片键：官方〔C6〕看基数、频率、是否单调；单调键用哈希分片；可用 `analyzeShardKey` 评估。聊天场景的具体片键没有大厂依据。

### 替代 MySQL

1. 数据价值在文档之间的关联时不选 MongoDB〔M1，Sarah Mei，2013〕：社交网络里同一用户多处出现，复制会不一致，引用就要在应用层手写 join。8 个月数据转为约 120 万行 MySQL，转换花 four pair-weeks。当时没有 `$lookup`（3.2）与多文档事务（4.0）。
2. 需要事务、级联删除、团队熟 SQL、要给客户自托管时，关系库更划算〔M2，Infisical，2024〕：迁移 3～4 个月、6 小时只读窗口切换，数据库账单降 50%（自述）。
3. 高频 K-V 查找加流量尖峰时连接数是弱点〔M3，Coinbase〕：尖峰绕过缓存直打 MongoDB 引发「connection storms」，失败时加连接、重试导致「death loop」；最常用的 K-V 数据移到 DynamoDB。
4. 从 MySQL 换到 MongoDB、具名且有数字的大厂正面案例：未找到。

## 2. 来源

### 电商

| 编号 | 来源 | 类别、日期 | 可信度 | 重点 |
|---|---|---|---|---|
| E1 | MongoDB 博客 Retail Reference Architecture Part 1 | 官方，2015-05-04 | 原文 | 商品与变体分开；`prices._id=<id>_<store>` |
| E1b | 同系列 Part 2（库存） | 官方，2015-05-12 | 原文 | 按商品内嵌 `vars:[{sku,quantity}]`；数量存成字符串、用已移除的 `geoNear`，已过时 |
| E2 | 官方文档设计模式各页、Handle Duplicate Data、Enforce Consistency | 官方，现行 | 原文 | 子集、离群（阈值 50、`has_extras`）、归档、订单快照、事务同步价格；交易示例 `updateOne({}, …)` 空过滤照抄有害 |
| E3 | Kvalheim 购物车章节（mongodb.github.io） | 前 MongoDB 员工，未标日期，旧 `update()` API | 摘要 | 购物车 `_id=userId`；`reserved` 数组；条件 `$inc`；定时归还过期预留 |
| E4 | OneUptime、Reintech 等教程 | 社区，2026 | 摘要 | 预留、确认、释放；TTL 购物车；未深读 |
| E5 | `reactioncommerce/reaction`（12.4k 星，最后 push 2026-03-01） | 社区 GitHub | 原文（源码） | `Catalog` 的 `product._id` 唯一；`Cart` 的 `accountId`、`referenceId` 部分唯一；`SimpleInventory` `{productVariantId, shopId}` 唯一；多集合 `{updatedAt, _id}` |
| — | 大厂电商 | — | 未找到 | — |

### 聊天

| 编号 | 来源 | 类别、日期 | 可信度 | 重点 |
|---|---|---|---|---|
| C1 | Discord「How Discord Stores Billions of Messages」 | 公司博客（非大厂），2017-01-13 | 摘要（含逐句引述） | 单一副本集；读写约 50/50；改 Cassandra |
| C2 | MongoDB 社区博客「Schema Design for Social Inboxes」 | 官方，年份未标 | 摘要 | 三种扇出设计 |
| C3 | 官方 Bucket Pattern | 官方，现行 | 原文 | `_id="<cust>_<秒>"`；`count<10` 才 `$push`，否则 upsert 新桶；分页 `skip` |
| C4 | `RocketChat/Rocket.Chat`（46.4k 星，最后 push 2026-11-02） | 社区 GitHub | 原文（源码） | 消息 `{rid,ts,_updatedAt}`、`expireAt` TTL、`{rid, tlm:-1}` 部分索引；订阅 `{rid,u._id}` 唯一；会话内嵌 `lastMessage`、`msgs` |
| C5 | OneUptime、Mastering Backend、MongoDB 论坛 | 社区 | 摘要 | `channels.lastMessage`、`(channelId, sentAt)` |
| C6 | 官方 Choose a Shard Key | 官方，现行 | 原文 | 基数、频率、单调；`analyzeShardKey` |
| — | 大厂聊天、X | — | 未找到 | — |

### 替代 MySQL

| 编号 | 来源 | 类别、日期 | 可信度 | 重点 |
|---|---|---|---|---|
| M1 | Sarah Mei「Why You Should Never Use MongoDB」 | 个人博客，2013-11-11 | 存档（原站两次失败） | 见结论；提到 Etsy 也离开 MongoDB（Etsy 原文未核对） |
| M2 | Infisical「The Great Migration from MongoDB to PostgreSQL」 | 初创公司博客，2024-03-25 | 摘要 | Mongoose 换 Knex |
| M3 | Coinbase「Scaling Identity」 | 大厂博客，日期未知 | 存档（直连两次 403） | 连接风暴、death loop、DynamoDB；版本字段乐观锁、客户端指数退避 |
| M4 | Coinbase「Scaling connections with Ruby and MongoDB」 | 大厂博客 | 摘要（403） | 自建 `mongobetween` 代理，路由连接从 1 万降到数百 |
| M5 | Teknasyon「MySQL → MongoDB」 | 公司博客 | 取不到（两次 403） | 搜索摘要称删除猜测性索引后效能提升约 30%，未验证 |
| M6 | Medium「Horror Stories」 | 匿名 | 摘要 | 无法核对，不采用 |

## 3. 与现有 `db-schema-design/references/mongodb.md` 比较

已有且一致：何时选 MongoDB 的限制；内嵌与引用判断；冗余字段批量更新；分桶、预聚合、版本字段、属性模式的 `$elemMatch` 陷阱；`(排序键, _id)` 游标；事务行为。

缺少：完整场景案例；子集、离群、归档、单一集合模式与时间序列集合；条件扣库存、购物车过期归还、订单快照；聊天的消息索引、订阅未读数、内嵌 `lastMessage`、扇出取舍；片键三要素与 `analyzeShardKey`、Discord 工作集超出 RAM；连接风暴；换回关系库的信号。

冲突：

1. 属性模式索引：官方建 `{releases:1}`，仓库用 `{"releases.country":1,"releases.date":1}` 加 `$elemMatch`（已实测）。整个子文档的索引只支持整份子文档相等比较，属既有知识，未验证（T1）。
2. 分页：官方 `skip` 跳桶，仓库主张游标。
3. 组合字符串 `_id` 的前缀查询必须带分隔符（T3）。
4. TTL 只删除文档，不执行归还库存等副作用（T8）。

## 4. 写入草案（待实测）

建议新增 `references/case-ecommerce-mongodb.md`、`references/case-chat-mongodb.md`（或合为 `mongodb-cases.md`），`mongodb.md` 只补模式表与选型信号。

电商：

1. 商品与 SKU 分开存：SKU 文档 `_id` 用 SKU，`itemId` 指回商品并建索引；前台读取量大时另存发布后的反正规化文档。〔E1、E5；索引需实测〕
2. 扣库存用带条件的单文档原子更新：`updateOne({_id: sku, available: {$gte: q}}, {$inc: {available: -q, reserved: q}})`，`matchedCount == 0` 即库存不足；不先查再扣，不无条件 `$inc` 后靠对账修正。〔E3；T2〕
3. 购物车预留要有过期归还流程；TTL 只删除文档，不归还库存。〔T8〕
4. 订单内嵌下单时的商品快照，只取展示与对账需要的字段。〔E2，一手来源〕
5. 商品只内嵌最近 N 条评论，全部评论放 `reviews` 集合。〔E2；`$push $each $slice` 写法 T7〕
6. 按店定价用组合 `_id`（`<sku>_<店>`），批量取价用 `$in`；前缀正则必须带分隔符。〔E1；T3〕
7. 极少数文档的数组远大于其余时用离群模式：主文档存前 N 个并标 `has_extras`，其余放附表。〔E2，一手来源〕
8. 金额统一用 `Decimal128` 或最小单位整数。〔先核对 `rules/database/mongodb.md` 现行规定〕

聊天：

1. 消息一条一文档，索引 `{会话id: 1, ts: 1}`，拉历史用 `(ts, _id)` 游标。〔C4；T5〕
2. 未读数放「用户 × 会话」订阅文档（`{rid, uid}` 唯一），发消息时 `updateMany` + `$inc`；成员很多的群改为读取时按 `ls` 计算或显示上限「99+」。〔C4；T6〕
3. 会话文档内嵌最后一条消息与消息计数，会话列表不查消息集合。〔C4、C5〕
4. 分桶减少文档数与索引项，但写入要处理桶满换桶；时序型数据先考虑时间序列集合。〔C2、C3；T4〕
5. 片键不用单调递增字段；单个会话 id 作片键时大群会成热点，选定前用 `analyzeShardKey` 评估。〔C6，一手来源；不写具体片键结论〕
6. 反例：单一副本集只靠一个组合索引，工作集超过内存后延迟不可预测（Discord，2015 年约 1 亿条消息）。〔C1，标明年份〕

选型：

1. 数据价值在文档之间的关联时用关系库；出现应用层手写 join 是信号。〔M1，2013〕
2. 需要级联删除、跨集合事务、团队以 SQL 为主或要交客户自托管时，优先关系库。〔M2，公司经验〕
3. 高频 K-V 查找加流量尖峰：限制连接池、尖峰时不绕过缓存、重试退避并限次。〔M3，存档原文〕

### MongoDB 8.0 实测清单

| # | 集合与数据 | 索引 | 操作 | 预期 |
|---|---|---|---|---|
| T1 | `movies` 10 万条，`releases:[{location,date}]` | 甲 `{releases:1}`；乙 `{"releases.location":1,"releases.date":1}` | `$elemMatch` location 等值 + date 范围 | 乙两字段都有边界；甲用不上或全范围（待证） |
| T2 | 一个 SKU，`available:10` | `_id` | 100 个并发条件扣减；对照无条件 `$inc` | 条件组恰好 10 次成功、最终 0；对照组变负 |
| T3 | `prices` 含 `30671_store23`、`306710_store1` | `_id` | `/^30671/` 与 `/^30671_/` | 前者 2 条、后者 1 条，都是 IXSCAN |
| T4 | 官方分桶示例 `trades` | `_id` | 20 个并发 upsert | 观察是否出现多个未满桶或 `_id` 重复错误 |
| T5 | 消息 100 万条、1000 个会话 | `{rid,ts}`；对照 `{rid,ts,_id}` | 倒序取 50 条；同 `ts` 用 `(ts,_id)` 游标 | `keysExamined` 约 50、无 SORT；无 `_id` 决胜时同值跳漏 |
| T6 | 5000 人群 | `{rid,u._id}` 唯一 | 连发 1000 条 `updateMany $inc`；对照读取时 `countDocuments({rid, ts>ls})` | 每条耗时与 oplog 条数 |
| T7 | `recentReviews` | — | `$push $each $sort $slice:5` | 数组维持 5 条、最新在前 |
| T8 | 购物车 TTL，库存有 `reserved` | TTL | 等购物车过期 | 购物车被删、`reserved` 不变 |
| T9（选做） | 分片集群 | — | `analyzeShardKey` 比较 `{rid}`、`{rid,ts}`、`{rid:"hashed"}` | 需三分片集群 |

## 5. 已验证／未验证边界／未做／下一步

**已验证**：官方文档现行页（`.md` 原文）；2015 零售参考架构 2 篇；Rocket.Chat、Reaction 的索引与更新语句（源码）；Sarah Mei 全文、Coinbase「Scaling Identity」数据库段落（存档）；主会话抽查见文首。

**未验证边界**：Discord、Infisical、Kvalheim、社区收件箱只有摘要；C2 年份、M3 日期不明；所有「需实测」条目与冲突 1 的判断；案例中的效果数字均为当事者自述；Coinbase 是否算「千亿级」视币种而定，Discord、Infisical、Teknasyon 不算大厂。

**未做**：大厂电商、大厂聊天一手文章（搜索 2 轮未找到）；X 只经搜索引擎 1 次（x.com 需登录）；取不到：DZone（403×2，以官方原版 E1 替代）、Coinbase「Scaling connections」（403×2，未试存档）、Teknasyon（403×2）；未读：官方客户案例页、MongoDB University、Etsy 原文、Discord 2023 ScyllaDB 文章；未读全：Reaction 下单前可售检查、Rocket.Chat 大群未读数特殊处理；未做任何 MongoDB 实测。

**下一步（待用户决定）**：在三节点副本集实测 T1～T8（T9 选做）；通过的写入案例文件，其余进疑问清单；核对 `rules/database/mongodb.md` 的金额类型规定。

## 6. MongoDB 8.0 实测结果与收益评估（2026-11-03）

环境：`mongo:8.0.34-noble` 三节点副本集（`mcase1`～`mcase3`，网络 `mcase-net`），脚本在 `2026-11-plan-b-reports/mongo-lab/`。单机、无其他负载，耗时只有相对意义。T9（分片）未做。 T2、T4 的并发启动方式：`for i in $(seq 1 20); do docker exec mcase1 mongosh --quiet --file /<脚本> > out-$i.txt & done; wait`。

| # | 结果 | 与现有配置 | 收益评估 | 建议 |
|---|---|---|---|---|
| T1 | 10 万文档，`$elemMatch`（location 等值 + date 范围）：官方 `{releases:1}` 边界 `[MinKey, MaxKey]`，扫 500000 个索引项、100000 文档、161ms；`{"releases.location":1,"releases.date":1}` 扫 8386、8ms；规划器默认选后者。`{releases:1}` 只服务整份子文档相等，且字段顺序不同时结果为 0 | 现有写法正确 | 低～中：官方示例可能被照抄（插件或官方文档），一句提醒即可 | 在现有属性模式陷阱一行补半句 |
| T2 | 20 个客户端各扣 5 次、库存 10：条件更新成功 10 次、最终 0；先查再扣成功 11 次、库存 -1（超卖）。复核：只跑先查再扣、3 轮各 20 并发，最终库存 -1、-2、0，超卖次数不定、可能不发生 | 规则只有「能用单文档原子更新就不用事务」，没有扣库存写法 | 高：电商核心正确性 | 写入案例 |
| T3 | `/^30671/` 命中 3 条（含 `306710_store1`），`/^30671_/` 命中 2 条，都是 IXSCAN | 无 | 低：只在组合字符串 `_id` 前缀查询时相关 | 不写入 |
| T4 | 官方分桶示例（`_id = <客户>_<秒>`）：20 个客户端 × 10 次只成功 20 次、180 次 E11000；**串行**连写 20 次也是后 10 次全部失败——同一秒内桶满后新桶 `_id` 与旧桶重复，写入丢失。改为 `_id: ObjectId()` + 业务字段 `customerId` 与索引 `{customerId, count}`：200 次全部成功、20 个满桶，未观察到多余的未满桶 | 现有「分桶」一行没写桶 id 怎么取 | 中～高：照抄官方示例会静默丢写入（调用方若吞错） | 在分桶一行补「桶满换桶时新桶 `_id` 不用时间拼接」 |
| T5 | 30 万条消息、1000 个会话：`sort({ts:-1,_id:-1})` 用 `{rid,ts}` 时有内存 SORT，第一页扫该会话全部 300 个索引项（后续页扫 98 个，复核）；用 `{rid,ts,_id}` 扫 50 条、无 SORT。只按 `ts` 的游标：每页 49 条取到 294/300、51 条取到 295，50 条与 20 条时 300（数据每 2 条同一 `ts`，页边界落在同值组中间才漏读；`t5.js` 存的是 50 条版本，49 条版本以 `--eval` 运行），`(ts,_id)` 游标 300 条且顺序一致，`$or` 写法扫 49 个索引项 | 已有「用 `(排序键, _id)` 作为游标」，没说索引要带 `_id` | 中：不带 `_id` 时每页都把整个分区排序 | 在分页一行补「索引末尾加 `_id`」 |
| T6 | 5000 人群：每条消息 `updateMany $inc unread` 平均 65.8ms、写 4999 条 oplog；只插入消息 2.1ms；读取时 `countDocuments({rid, ts>ls}, {limit:100})` 0.32ms/次 | 无聊天内容 | 高：大群写放大的量化依据 | 写入案例 |
| T7 | `$push {$each, $sort:{at:-1}, $slice:5}` 连写 8 次后数组为最新 5 条 | 无 | 低：语法确认，单独无价值 | 只作为案例中的写法示例 |
| T8 | TTL 删除购物车后，库存 `reserved` 保持 2 不变 | 已有 TTL 清理不准时 | 低：属预期行为 | 只在案例中一句带过 |

未实测但有一手来源的做法（商品与 SKU 分开、订单快照、离群模式）可在案例中引用；选型信号（M1～M3）与连接池已被现有「何时选 MongoDB」「连接参数」覆盖，不写入。

本机残留（`docker rm` 被拒）：容器 `mcase1`～`mcase3`、网络 `mcase-net`。


### 交叉审核（2026-11-03，独立子代理）

结论：A1 通过；A2 改为不与 rules 第 19 行「分桶键 `<设备>:<日期>` 作 `_id`」冲突，并把「丢写入」改为「报 E11000」；A3 数字加条件；`case-mongodb.md` 值得新增但精简，删去 Discord（只有摘要）与片键（未实测）两条，SKU 一条与 `case-ecommerce.md` 重复删去，不点名 Reaction 项目；未读数补读端代价。另指出 `rules/database/mongodb.md`「分页用范围条件（`_id` 或排序键大于上一页最后一条）」允许只用排序键作游标，与 T5 的漏读结论不一致（未改，交用户决定）。