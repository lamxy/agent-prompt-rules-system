---
paths:
  - "**/migrations/**"
  - "**/model/**/*.go"
  - "**/repository/**/*.go"
  - "**/entity/**/*.go"
---

# MongoDB

适用于使用 MongoDB Go Driver 的项目；不用 MongoDB 时删除本文件。连接参数与理由见 `db-schema-design` skill 的 `references/mongodb.md`。

## 命名

- 库名小写，只用字母、数字和下划线，不以数字开头，不超过 64 个字符，不与 `admin`、`local`、`config` 重名；按业务用途命名，例如 `inventory`。
- 集合名小写加下划线，不超过 64 个字符，不以 `system.` 开头；同一模块的集合用相同前缀：`<模块>_<用途>`，例如 `order_sync_log`。
- 数据量大的集合各自分库，不和其他大集合放在同一个库。
- 字段名只用字母、数字和下划线，不以数字开头；同一集合中同名字段的类型保持一致。
- 使用驱动生成的 `_id`（ObjectID），不自定义 `_id`；业务唯一键另设字段并建唯一索引。

## 索引

- 每个查询都要有对应索引；组合索引把选择性高的字段放在前面。
- 不在数组字段上建索引（会成为 multikey 索引，体积与写入成本随元素数量增长）。
- 索引名不超过 128 字节；索引与集合变更写成迁移脚本，不在应用启动时隐式创建。
- 设计集合时说明数据增长量和清理归档方式（TTL 索引、按时间分集合等）。

## 读写

- 线上代码的 `Find`、`Update*`、`Delete*` 必须带过滤条件，不传空的 `bson.D{}` / `bson.M{}`。
- 更新用 `$set` 等更新操作符，不用整文档替换，除非确实要替换（`ReplaceOne`）。
- 聚合管道的第一个阶段是 `$match`。
- 用 projection 只取需要的字段。

## 连接

- 一个进程共享一个 `*mongo.Client`，不按请求创建。
- 每个操作都有超时：请求的 `context` deadline 或客户端 `SetTimeout`（`timeoutMS`）；不把超时设为 0。
- 连接超时 `SetConnectTimeout` 约 3s；`SetMaxPoolSize` 按并发量设置（驱动默认 100）。
