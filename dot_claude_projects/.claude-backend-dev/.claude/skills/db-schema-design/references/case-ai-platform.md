# 案例：放弃代理键的连锁代价

一个插件分发平台（PostgreSQL，18 张表、18 个 migration）的设计演进。它遵守了不用外键，但没有坚持「每张表自增 `bigint` 主键、关联一律用父表 `id`」，后续每次重构都在为此付代价。表名已改写为通用名称。

在 PG 中，`text` 与 `varchar` 性能相同、表也不按主键聚簇，所以下文的问题在 PG 里多属设计层面；照搬到 MySQL 则大多建不起来或代价放大，见 `mysql.md`「从 PostgreSQL 设计迁移到 MySQL」。

## 起点

初版各表都有 `bigint` 自增主键，但版本表已经用文本业务键关联主表：

```sql
CREATE TABLE plugins (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  plugin_code text NOT NULL,          -- 业务键，唯一
  category text NOT NULL,             -- 自由文本
  ...
);
CREATE TABLE plugin_versions (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  plugin_code text NOT NULL,          -- 关联 plugins.plugin_code，而不是 plugins.id
  version text NOT NULL,
  supported_os jsonb NOT NULL DEFAULT '[]',
  ...
);
```

## 连锁演进

| 步骤 | 发生了什么 | 违反的规范 |
|---|---|---|
| 1. 放弃 id 关联 | 之后三次 migration 把子表原有的 `plugin_version_id bigint` 改成 `(plugin_code text, version text)` 两列；最终 7 张子表都靠两个字符串关联版本 | 关联用父表 `bigint id` |
| 2. 主键三套并存 | 新表改用随机 `uuid` 或 `text` 主键，配置表直接用业务值 `version` 作主键；18 张表里 `bigint` 主键只剩 5 张 | 每张表自增 `bigint` 主键 |
| 3. 改已上线的主键 | 审核表的 `bigint` 主键被换成 `uuid`，旧列改名为 `legacy_record_id` 永久保留 | 不改已上线字段，主键尤甚 |
| 4. 伪造回填 | 新加的 `NOT NULL` 列补不出真值：引用列填 `gen_random_uuid()`，其他列填 `'legacy'`、`'legacy-import'` | 「没有」用约定值并写进 `COMMENT` |
| 5. 触发器兼容 | 高频写入的安装记录表挂上 `BEFORE INSERT` 触发器，按旧的 `bigint` 列查版本补新列，查不到就填占位串；列定义为 `NOT NULL` 却设 `DEFAULT NULL` | 不用触发器，兼容放应用层 |

第 4 步的核心片段：

```sql
UPDATE release_reviews
SET check_run_id = COALESCE(check_run_id, gen_random_uuid()),   -- 指向不存在的记录
    version      = COALESCE(version, 'legacy'),
    owner_team   = COALESCE(owner_team, 'legacy-import');
```

## 同一套设计里的其他问题

- **维度值自由文本**：分类在数据里同时有中英文两种写法，且已复制到审核表、审核人分派表；migration 注释承认直接加约束「要连带改写三张表，风险远大于收益」，最后只在主表加了一个新列。
- **JSON 存可查询子数据**：版本支持的操作系统和客户端存成两个 `jsonb` 数组，列表接口还要按它们筛选。后来拆成关联表时，迁移只处理两个数组长度都为 1 的版本。
- **拆表后旧字段不下线**：安装命令等字段拆到修订表后，版本表上的同名字段仍保留；审核表的同一份信息同时存在于源表、冗余列和 JSON 快照三处。
- **引用命名不一致**：用户引用有 `*_uid`、`user_ref` + `user_ref_type` 两种；版本在多数表叫 `version`，在一张表叫 `plugin_version`。

## 按 MySQL 规范的设计

```sql
CREATE TABLE plugins (
  id          bigint unsigned NOT NULL AUTO_INCREMENT,
  plugin_code varchar(64)     NOT NULL COMMENT '对外编号',
  category_id bigint unsigned NOT NULL COMMENT '分类字典 id',
  ...
  PRIMARY KEY (id),
  UNIQUE KEY uk_plugin_code (plugin_code)
);
CREATE TABLE plugin_versions (
  id        bigint unsigned NOT NULL AUTO_INCREMENT,
  plugin_id bigint unsigned NOT NULL COMMENT 'plugins.id',
  version   varchar(32)     NOT NULL,
  ...
  PRIMARY KEY (id),
  UNIQUE KEY uk_plugin_id_version (plugin_id, version)
);
CREATE TABLE plugin_version_targets (      -- 取代 jsonb 数组
  id                bigint unsigned NOT NULL AUTO_INCREMENT,
  plugin_version_id bigint unsigned NOT NULL,
  os_type           tinyint unsigned NOT NULL COMMENT '1 linux 2 macos 3 windows',
  client_type       tinyint unsigned NOT NULL COMMENT '1 client_a 2 client_b',
  ...
  PRIMARY KEY (id),
  UNIQUE KEY uk_version_os_client (plugin_version_id, os_type, client_type)
);
```

子表一律存 `plugin_version_id`；需要展示「当时的版本号」时另存快照字段并在 `COMMENT` 注明。历史数据缺失时，关联填 `0`，并加 `is_legacy` 标记。

## 这套设计里做对的

审计表禁止改写、安装上报用幂等键加唯一索引、游标分页的排序加主键决胜列、用部分唯一索引保证「同一版本同时只有一个待审核」。前三项可以直接搬到 MySQL；部分索引在 MySQL 中改用生成列或应用层加锁。
