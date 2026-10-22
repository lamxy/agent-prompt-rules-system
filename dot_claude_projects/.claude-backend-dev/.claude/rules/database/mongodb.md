---
paths:
  - "**/migrations/**"
  - "**/model/**/*.go"
  - "**/repository/**/*.go"
  - "**/entity/**/*.go"
---

# MongoDB

适用于使用 MongoDB Go Driver 的项目；不用 MongoDB 时删除本文件。建模方法、连接参数与各条的实测依据见 `db-schema-design` skill 的 `references/mongodb.md`。

## 命名

- 库名小写，只用字母、数字和下划线，不以数字开头，不超过 64 个字符，不与 `admin`、`local`、`config` 重名；按业务用途命名，例如 `inventory`。
- 集合名小写加下划线，不超过 64 个字符，不以 `system.` 开头；同一模块的集合用相同前缀：`<模块>_<用途>`，例如 `order_sync_log`。
- 按业务边界分库，同一业务、需要 `$lookup` 关联的集合放在同一个库；大集合需要独立权限、独立备份，或在分片集群中分散主分片时才单独分库。
- 字段名只用字母、数字和下划线，不以数字开头；同一集合中同名字段的类型保持一致。
- `_id` 默认用驱动生成的 ObjectID；存在不可变、唯一且主要按它查询的键（上游消息 id、雪花 id、分桶键 `<设备>:<日期>`）时可作为 `_id`。可能变化的业务值（手机号、邮箱、展示编号）不作 `_id`，另设字段建唯一索引；不用随机 UUID 作 `_id`。

## 建模

- 无上限增长的子数据（评论、日志、流水）不内嵌，改为单独集合并存父文档 `_id`；内嵌数组要有可预期的上限，嵌套不超过两层。
- 引用没有外键约束，也不会级联删除；删除或修改父文档时，由应用负责处理引用它的文档。

## 索引

- 每个查询都要有对应索引；组合索引按 ESR 排列：等值字段 → 排序字段 → 范围字段。低选择性字段（状态、性别）不单独建索引。
- 数组字段的索引是多键索引：一个组合索引最多含一个数组字段，否则写入两个字段都是数组的文档时报错；对同一数组元素的多个条件用 `$elemMatch`，否则会跨元素匹配。
- 不用 `hint` 强制部分索引（`partialFilterExpression`）：查询条件不在过滤范围内时，结果会缺数据且不报错。
- 索引与集合变更写成迁移脚本，不在应用启动时隐式创建。
- 设计集合时说明数据增长量和清理归档方式（TTL 索引、按时间分集合等）。

## 读写

- 线上代码的 `Update*`、`Delete*` 必须带过滤条件，不传空的 `bson.D{}` / `bson.M{}`（驱动不拦截）；`Find` 不带过滤条件时必须有 `Limit`。
- 不用 `$where`、`$function` 等服务端 JavaScript 查询（无法使用索引）。
- 批量写入用 `InsertMany` / `BulkWrite`，不逐条循环写入；互不依赖的批量操作设 `SetOrdered(false)`，单条失败不中断其余。
- 更新用 `$set`、`$inc` 等更新操作符，不用整文档替换，除非确实要替换（`ReplaceOne`）。
- 聚合管道的第一个阶段是 `$match`；用 projection 只取需要的字段。
- 分页用范围条件（`_id` 或排序键大于上一页最后一条），不用大偏移的 `Skip`；不为算总页数对大集合 `CountDocuments`，需要总数时：整个集合用 `EstimatedDocumentCount`（不支持过滤条件），带条件用 `CountDocuments` 并 `SetLimit` 设上限。
- 游标用完 `defer cursor.Close(ctx)`。
- 不在代码中把写关注降到 `w: 1` 或 `w: 0`；含仲裁节点的部署（PSA）默认写关注是 `w: 1`，连接串要显式设置 `w=majority`；`w: "majority"` 超时返回错误时，写入可能已经生效，按「结果未知」处理（幂等重试或查询确认），不直接当失败。
- 刚写入的数据要立即读回时读 primary；读 secondary 只用于可接受延迟的场景（报表、统计）。在因果一致性会话中读 secondary，节点落后时读会等待，必须带超时。

## 事务

- 能用单文档原子更新（内嵌、`$inc`、`FindOneAndUpdate`）解决的，不用多文档事务。
- 用 `session.WithTransaction`，回调内只做数据库操作并使用回调传入的 `ctx`；回调可能被重复执行，不在其中发消息或调外部接口，用到的外部变量在回调开头重置。
- 事务执行时间远小于 60 秒（服务端默认上限，超时会被中止）；批处理拆成小批次（官方文档：事务过大会因 WiredTiger 缓存压力中止）。

## 驱动版本

- 使用 `go.mongodb.org/mongo-driver/v2`，不新引入 v1（`go.mongodb.org/mongo-driver`）。
- v2 写法：`bson.ObjectID`、`bson.NewObjectID()`（原 `primitive` 包已并入 `bson`）；`mongo.Connect(opts)` 不传 `ctx`；会话与事务回调参数是 `context.Context`（不再有 `mongo.SessionContext`）；超时用 `context` 或 `SetTimeout`（`SetMaxTime`、`SetSocketTimeout` 已移除）。

## 连接

- 一个进程共享一个 `*mongo.Client`，不按请求创建。
- 连接串列出副本集全部成员并带 `replicaSet`，优先用域名而非 IP；应用账号只授予本业务库的 `readWrite`，报表用只读账号。
- 每个操作都有超时：请求的 `context` deadline 或客户端 `SetTimeout`（`timeoutMS`）；不把超时设为 0。
- 连接超时 `SetConnectTimeout` 约 3s；`SetMaxPoolSize` 按并发量设置（驱动默认 100）。
