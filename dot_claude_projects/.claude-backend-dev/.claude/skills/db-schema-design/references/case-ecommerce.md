# 案例：电商订单库

一个自营电商一期的 MySQL 设计，用来示范互联网业务中刻意的取舍：对外编号、快照、冗余计算字段、从查询反推索引。设计新库时对照它找漏掉的实体和索引，不要照抄表结构。

数据规模（教学库）：用户 1 万、商品 500、规格 1,502、订单约 100 万、明细 250 万。实测环境为 MySQL 8.0.46。

## 表

| 表 | 用途 | 值得注意的设计 |
|---|---|---|
| `users` | 用户 | `phone VARCHAR(20)` 加唯一索引，不用数字类型 |
| `categories` | 分类，自参照树 | `parent_id = 0` 表示顶层；层级「以后可能加」，所以不建固定层级表 |
| `products` | 商品（SPU） | `sales_count` 是冗余计算字段，服务「按销量排序」；下架看 `status`，删除看软删除标记 |
| `skus` | 规格，实际可售单位 | 价格与库存按规格分开；`price` 是当前价 |
| `orders` | 订单主表 | 内部 `id` 自增，对外 `order_no VARCHAR(32)` 加唯一索引；`total_amount` 冗余自明细；收件人信息是快照 |
| `order_items` | 订单明细，订单与规格的多对多关联 | 关联表本身是实体：`price_snapshot`、`sku_name_snapshot` 是快照，`product_id` 冗余以便按商品统计不必关联 `skus` |
| `payments` | 支付记录 | `trade_no` 唯一；`order_id` 不唯一，因为要允许支付失败后重试 |
| `coupons` | 优惠券 | `threshold = 0` 表示无门槛 |

需求里没有明说、但设计时必须补上的隐含实体：收货地址（用户可存多个，需要单独查询和修改，不塞 JSON）、购物车、发货单或包裹（一张订单可能分多次发货）。另外，跨店下单会拆成多张订单但只付一次款时，`payments.order_id` 只能指向一张订单，需要一张支付单表承接「一次付款对应多张订单」。

明细的快照字段：

```sql
`sku_name_snapshot` VARCHAR(300)  NOT NULL COMMENT '下单时的商品规格名称快照',
`price_snapshot`    DECIMAL(10,2) NOT NULL COMMENT '下单时的单价快照，不可用 skus.price 替代',
`subtotal`          DECIMAL(12,2) NOT NULL COMMENT '小计 = price_snapshot * quantity',
```

教学库中同一个规格的快照价与现价相差 -237 到 +267，用现价重算，历史订单金额会全错。

## 查询与索引

| 场景 | 查询形态 | 索引 |
|---|---|---|
| 用户订单列表 | `WHERE user_id=? AND status=? ORDER BY created_at DESC` | `orders (user_id, status, created_at)` |
| 订单明细、支付记录 | `WHERE order_id=?` | `order_items (order_id)`、`payments (order_id)` |
| 按单号、手机号查询 | 等值 | 唯一索引 |
| 经营日报 | `WHERE created_at >= ? AND created_at < ?` | `orders (created_at)` |
| 子分类、递归 | `WHERE parent_id=?` | `categories (parent_id)` |
| 分类下按销量排序 | `WHERE category_id=? AND status=? ORDER BY sales_count DESC` | `products (category_id, status, sales_count)` |
| 商品销售排行 | 见下节 | `order_items (created_at, product_id, quantity)` |

漏建「按父查子」的索引代价最大：`order_items(order_id)` 建立前实测为 `ALL`、扫描约 242 万行，建立后为 `ref`、约 5 行；`payments(order_id)` 从扫描 76 万行降到 1 行。

## 实测：商品销售排行的索引

需求：看每个商品的销售排行，可按今天、近 7 天、近 30 天筛选。查询：

```sql
SELECT sku_id, SUM(quantity) AS qty
FROM order_items
WHERE created_at >= ? AND created_at < ?
GROUP BY sku_id
ORDER BY qty DESC
LIMIT 20;
```

每次只保留一个候选索引，`EXPLAIN ANALYZE` 实测耗时（近 30 天约 30 万行，近 7 天约 11 万行，1 天约 3 万行）：

| 索引 | 访问方式 | 30 天 | 7 天 | 1 天 |
|---|---|---|---|---|
| 无 | 全表扫描，临时表 | 398 ms | 338 ms | 329 ms |
| `(sku_id, created_at)` | 扫描整个索引，逐行回表 | 8297 ms | 4136 ms | 4018 ms |
| `(created_at, sku_id)` | 范围扫描，回表，临时表 | 563 ms | 207 ms | 58 ms |
| `(created_at, sku_id, quantity)` | 覆盖索引范围扫描，临时表 | 65 ms | 24 ms | 6.5 ms |
| `(sku_id, created_at, quantity)` | 扫描整个覆盖索引，按索引顺序分组 | 256 ms | 238 ms | 234 ms |

结论：

1. 分组列放最左的 `(sku_id, created_at)` 比不建索引慢 20 倍。查询没有 `sku_id` 的等值条件，只能扫描整个索引；它确实按 `sku_id` 的顺序分组、省掉了临时表，但 250 万行逐行回表读 `quantity`，随机 I/O 压过一切。省掉临时表不等于快。
2. 时间范围列放最左，扫描量随时间窗缩小。
3. 覆盖索引让结果再快约 8 倍，聚合用到的 `quantity` 必须在索引里。
4. 分组列也必须在覆盖索引里：用 `(created_at, sku_id, quantity)` 跑 `GROUP BY product_id` 会退回回表，30 天耗时 531 ms。先和需求方确认排行是按商品还是按规格，再定索引；按商品排行用 `(created_at, product_id, quantity)`，实测 66 ms / 24 ms / 6.6 ms。
5. 每种索引都消不掉最后的 `filesort`，因为排序对象是 `SUM()` 的结果。只能靠分组后行数少（500～1500 行）加 `LIMIT` 控制代价。
6. 数据再增长一个数量级，或时间窗可以任意放大时，改为预计算：按「日期 × 商品」维护销量汇总表，排行查汇总表。
