# SQL 写法陷阱

评审 repository 层 SQL 或设计报表查询时对照。数据来自 MySQL 8.0 教学库（订单约 100 万行、明细 250 万行）的实测，数字用来说明数量级，不代表其他数据集。

## 结果静默出错

| 陷阱 | 现象 | 正确写法 |
|---|---|---|
| `LEFT JOIN` 的右表条件写在 `WHERE` | 未匹配的行右表列为 `NULL`，被 `WHERE` 过滤掉，退化为内连接；实测 634 行变成 428 行，不报错 | 决定怎么匹配的条件写在 `ON`，过滤最终结果的条件写在 `WHERE` |
| `NOT IN (子查询)` 遇到 `NULL` | 子查询结果里只要有一个 `NULL`，整个条件为 UNKNOWN，实测返回 0 行，正确结果约 100 万行 | 改用 `NOT EXISTS`；与版本无关 |
| `= NULL`、`!= NULL` | 永远不成立，返回 0 行，不报错 | `IS NULL`、`IS NOT NULL` 或 `<=>` |
| `AND` 与 `OR` 混用不加括号 | `AND` 优先级更高，实测加括号 75,171 行，不加 90,191 行 | 一律加括号 |
| 测试数据没有区分度 | 换一组条件后两种写法结果相同，因为条件在当前数据上恒为空集，错误写法被误判为正确 | 验证前先确认测试条件在当前数据上确实能区分出差异 |
| `DISTINCT(a), b` | `DISTINCT` 作用于整个 `SELECT` 列表，括号不起作用，按 `(a, b)` 组合去重 | 只想对 `a` 去重时用 `GROUP BY a` 或子查询 |
| 关闭 `ONLY_FULL_GROUP_BY` | 非聚合列返回任意一行的值，结果不确定 | 保持开启；非聚合列用 `ANY_VALUE()` 或 `MAX()` 表达意图 |
| 分组取 Top-N 不加决胜列 | 排序键相同时每次结果可能不同 | `ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC, id DESC)`；过滤条件放进子查询内部 |

凡是排序依赖稳定性的场景（分页、排名、去重），排序键都必须唯一，不唯一就加主键。

## 性能

| 陷阱 | 现象 | 正确写法 |
|---|---|---|
| 相关子查询内对外层做聚合 | 每一行外层数据都执行一次子查询，实测 3.26 s；MySQL 8.0 通常不会自动去相关化 | 先按该列聚合成派生表再 `JOIN`，或用窗口函数 `AVG() OVER (PARTITION BY ...)`，实测 0.39 s |
| 能在 `WHERE` 过滤的条件放进 `HAVING` | 先对全表分组再过滤 | `WHERE` 过滤行，`HAVING` 只过滤聚合结果 |
| 请求路径里跑精确 `COUNT(*)` | 要扫描整个索引，千万级表上很慢 | 计数器表、估算值或「是否还有下一页」；`information_schema.TABLES.TABLE_ROWS` 是抽样估算，实测误差 0.74%～3.2%，读取几乎没有代价，可用于后台展示 |
| `IN`、`EXISTS`、`JOIN` 混用 | 8.0 会把 `IN` 改写为半连接，差距已缩小 | 子查询结果小用 `IN`，只判断是否存在用 `EXISTS`，需要子表的列用 `JOIN` |

## 树形结构

自参照表（`parent_id`）适合层级不固定的分类、组织架构。`parent_id` 上必须建索引。

递归 CTE 的三个坑：

1. 锚点成员里拼接路径时要先 `CAST(name AS CHAR(500))`，否则列宽按锚点推断，路径变长后报 `ERROR 1406 Data too long`。
2. 用 `UNION ALL`，不用 `UNION`。
3. `cte_max_recursion_depth` 默认 1000，数据里有环时报错而不是死循环，这是一层保护，不要随意调大。

```sql
WITH RECURSIVE tree AS (
  SELECT id, parent_id, CAST(name AS CHAR(500)) AS path, 1 AS depth
  FROM categories WHERE parent_id = 0
  UNION ALL
  SELECT c.id, c.parent_id, CONCAT(t.path, ' > ', c.name), t.depth + 1
  FROM categories c JOIN tree t ON c.parent_id = t.id
)
SELECT * FROM tree;
```

读多写少时可以改用路径枚举：存一个 `path` 字段（如 `/1/11/111/`），用 `LIKE '/1/11/%'` 查子树，读取不用递归，代价是移动节点时要维护整棵子树的 `path`。
