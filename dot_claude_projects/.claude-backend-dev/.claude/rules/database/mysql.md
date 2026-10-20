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

- 所有字段 `NOT NULL`，除 `TEXT` / `BLOB` 外都有默认值。
- 金额等精确小数用 `DECIMAL`；枚举与布尔用 `TINYINT`（`TINYINT(1)`），不用 `ENUM` / `BOOLEAN`。
- `VARCHAR` 不超过 2000；主表不放 `TEXT` / `BLOB`，需要时拆到附表并用业务键关联，或存文件只存路径。
- 时间用 `datetime`，不用 `timestamp`（2038 年上限）。
- 密码只存哈希；可逆加密的字段命名为 `<明文字段>_cipher`。

## 索引

- 二级索引 `idx_<字段>`，唯一索引 `uk_<字段>`；组合索引按区分度从高到低排列，单索引不超过 3 个字段，单表不超过 5 个索引。
- `WHERE`、`ORDER BY`、`GROUP BY` 用到的字段要有索引；不在 `TEXT` / `BLOB` 上建索引，长字符串用前缀索引。

## 变更（migration）

- schema 变更只写 migration 文件并附回滚步骤，不直接在库上执行 DDL；不用 GORM `AutoMigrate` 管理线上表结构。
- 不 `DROP TABLE` 后重建，不删除字段、不修改已上线字段的类型或名称；新增字段不用 `AFTER`；同一张表的多个变更合并为一条 `ALTER`。

## SQL

- 只查需要的字段，不写 `SELECT *`（GORM 用 `Select` 或较小的结果结构体，或开启 `QueryFields`）；`INSERT` 写明字段名。
- 不在 `WHERE` 字段上套函数或表达式，等号两边类型一致；不用前导通配符 `LIKE '%x'`、`!=` / `<>`；`OR` 改写为 `IN`，`IN` 列表不超过 100 个，少用 `NOT IN`。
- 在线业务（OLTP）的查询必须有 `WHERE`；关联不超过两张表，关联字段的类型、长度、字符集一致；少用子查询。
- 单条写语句影响不超过 1000 行，批量 `VALUES` 不超过 1000 组；查询结果不超过 5000 行，每秒超过 100 次的高频查询不超过 100 行。
- 深分页改用游标：`WHERE id > ? ORDER BY id LIMIT ?`，不用大 `OFFSET`。
- 不用 optimizer hint（`FORCE INDEX` 等）、`REPLACE INTO`、跨库事务，单条语句不同时更新多张表；统计类 `SUM` / `COUNT` 走从库或分析库。
- 计算放在业务代码，不在 SQL 中做数学运算；写操作保证幂等（唯一键或状态条件更新），避免重复扣款、重复下单。
- 事务隔离级别为 `READ COMMITTED`；应用账号只有 `SELECT`、`INSERT`、`UPDATE`，`DELETE` 按需授权，不授予 DDL 权限。
