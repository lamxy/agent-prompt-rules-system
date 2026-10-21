---
paths:
  - "**/*.sql"
  - "**/migrations/**"
  - "**/model/**/*.go"
  - "**/repository/**/*.go"
  - "**/entity/**/*.go"
---

# MySQL

适用于 MySQL 8.0（5.7 的差异见 `db-schema-design` skill 的 `references/mysql.md`，条目理由也在那里）。项目不用 MySQL 时删除本文件。下列数字是默认上限，项目另有约定时以项目为准。

## 建表

- 主键为 `id bigint unsigned NOT NULL AUTO_INCREMENT`，插入时不指定主键值，也不更新主键。
- 每张表有 `created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP` 与 `updated_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP`，`updated_at` 建索引；项目已有其他命名时沿用项目的。
- `ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC`；需要区分大小写的字段或表用 `COLLATE utf8mb4_bin`。
- 表与每个字段都写 `COMMENT`。
- 库、表、字段名用小写英文加下划线，不超过 32 个字符，不用 MySQL 保留字。
- 单表字段不超过 40 个；不用外键、存储过程、函数、触发器、视图、事件。

## 字段

- 所有字段 `NOT NULL`，除 `TEXT` / `BLOB` 外都有默认值。「没有」用约定值表示：可选关联 id 为 `0`，尚未发生的时间为 `'1970-01-01 00:00:00'`，字符串为 `''`；约定值写进字段 `COMMENT`。
- 确需 `NULL` 的极少数字段，在 `COMMENT` 与设计文档的 ADR 中写明理由；查询可空列用 `IS NULL` / `<=>`，不用 `NOT IN (子查询)`（子查询含 `NULL` 时结果为空），改用 `NOT EXISTS`。
- 对外暴露的编号（订单号、支付单号等）用独立的 `VARCHAR` 字段加唯一索引，不对外暴露自增 `id`。
- 表间关联字段存对方的 `bigint` 主键（如 `order_id`，类型与对方 `id` 一致），不用文本业务键或多列组合关联；业务键只留在本表并建唯一索引，需要保留「当时的值」时另存快照字段。
- 软删除用 `is_deleted TINYINT NOT NULL DEFAULT 0`；需要删除时间或表上有业务唯一键时，按 `db-schema-design` skill 的 `references/mysql.md`「软删除」处理。
- 金额等精确小数用 `DECIMAL`；枚举、状态与布尔用 `TINYINT`（`TINYINT(1)`），不用 `ENUM` / `BOOLEAN`，`COMMENT` 列出全部取值。
- 手机号、证件号、外部编码等标识用 `VARCHAR`，不用数字类型。
- `VARCHAR` 不超过 2000；主表不放 `TEXT` / `BLOB`，需要时拆到附表并用业务键关联，或存文件只存路径。
- 时间用 `datetime`，不用 `timestamp`（2038 年上限）。
- 密码只存哈希；可逆加密的字段命名为 `<明文字段>_cipher`。

## 索引

- 二级索引 `idx_<字段>`，唯一索引 `uk_<字段>`，名称反映实际字段，改字段时同步改名；单索引不超过 3 个字段，单表不超过 5 个索引。
- 每个索引都对应一条写明的查询；子表按父表 id 查询的字段（`order_id`、`parent_id` 等）都要有索引。
- 组合索引按 ESR 排列：等值条件在前，排序次之，范围条件在后；低选择性字段（如 `status`）不放最左，也不单独建索引。范围列与排序列不同时，一个索引无法同时消除范围扫描和 `filesort`，在设计文档中写明取舍。
- 业务唯一性用唯一索引保证，不用「先查再插」；唯一约束只建在稳定的业务规则上。
- `WHERE`、`ORDER BY`、`GROUP BY` 用到的字段要有索引；不在 `TEXT` / `BLOB` 上建索引，长字符串用前缀索引。

## 变更（migration）

- schema 变更只写 migration 文件并附回滚步骤，不直接在库上执行 DDL；不用 GORM `AutoMigrate` 管理线上表结构。
- 不 `DROP TABLE` 后重建，不删除字段、不修改已上线字段的类型或名称；新增字段不用 `AFTER`；同一张表的多个变更合并为一条 `ALTER`。

## SQL

- 只查需要的字段，不写 `SELECT *`（GORM 用 `Select` 或较小的结果结构体，或开启 `QueryFields`）；`INSERT` 写明字段名。
- 不在 `WHERE` 字段上套函数或表达式，等号两边类型一致（字符串列的比较值必须带引号，否则索引失效）；日期范围写半开区间 `>= 起 AND < 止`，不写 `DATE(col) = ?`；不用前导通配符 `LIKE '%x'`、`!=` / `<>`；`OR` 改写为 `IN`，`IN` 列表不超过 100 个，少用 `NOT IN`；`AND` 与 `OR` 混用时加括号。
- 在线业务（OLTP）的查询必须有 `WHERE`；关联不超过两张表，关联字段的类型、长度、字符集一致；`LEFT JOIN` 中决定匹配的条件写在 `ON`，写在 `WHERE` 会退化为内连接；少用子查询，相关子查询改写为先聚合再关联或窗口函数。
- 请求路径中不对大表执行精确 `COUNT(*)`，改用计数器、估算值或「是否还有下一页」。
- 单条写语句影响不超过 1000 行，批量 `VALUES` 不超过 1000 组；查询结果不超过 5000 行，每秒超过 100 次的高频查询不超过 100 行。
- 深分页改用游标：`WHERE id > ? ORDER BY id LIMIT ?`，不用大 `OFFSET`；排序键不唯一时加主键作决胜列，`WHERE (created_at, id) > (?, ?) ORDER BY created_at, id`。
- 不用 optimizer hint（`FORCE INDEX` 等）、`REPLACE INTO`、跨库事务，单条语句不同时更新多张表；统计类 `SUM` / `COUNT` 走从库或分析库。
- 计算放在业务代码，不在 SQL 中做数学运算；写操作保证幂等（唯一键或状态条件更新），避免重复扣款、重复下单。
- 事务隔离级别为 `READ COMMITTED`；应用账号只有 `SELECT`、`INSERT`、`UPDATE`，`DELETE` 按需授权，不授予 DDL 权限。
