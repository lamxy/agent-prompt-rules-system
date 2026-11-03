# MongoDB 案例：电商库存与聊天未读数

MongoDB 8.0 三节点副本集实测（单机，耗时只有相对意义）。建模通则、分页与分桶见 `mongodb.md`；SPU / SKU 拆分见 `case-ecommerce.md`。

## 电商

- 扣库存用带条件的单文档原子更新，`matchedCount == 0` 即库存不足：`updateOne({_id: sku, available: {$gte: q}}, {$inc: {available: -q, reserved: q}})`。实测库存 10、20 个客户端并发：条件更新恰好成功 10 次、最终 0；先 `findOne` 判断再 `$inc` 会超卖（3 轮最终库存 -1、-2、0，次数不定）。不要无条件 `$inc` 后靠对账修正。
- TTL 只删除购物车文档，不归还 `reserved`，预留要有单独的过期归还流程（实测）。
- 订单内嵌下单时的商品快照，只取展示与对账需要的字段；商品只内嵌最近 N 条评论，全部评论放 `reviews` 集合（官方子集模式），写法 `$push: {recentReviews: {$each: [r], $sort: {at: -1}, $slice: N}}`（实测）。

## 聊天

- 消息一条一文档，索引 `{rid: 1, ts: 1, _id: 1}`，游标见 `mongodb.md`「分页与计数」（Rocket.Chat 源码用 `{rid, ts, _updatedAt}`）。
- 会话文档内嵌最后一条消息与消息计数，会话列表不查消息集合（Rocket.Chat 源码）。
- 未读数放「用户 × 会话」订阅文档（`{rid, uid}` 唯一）。发消息时 `updateMany` + `$inc` 的代价与群人数成正比：实测 5000 人群每条消息 65.8ms、写 4999 条 oplog，只插消息 2.1ms。成员多的群改为读取时计算：订阅文档存最后已读时间 `ls`，`countDocuments({rid, ts: {$gt: ls}}, {limit: 100})`，界面显示「99+」。代价转到读端：会话列表每个会话各计数一次（实测单会话 0.32ms）。阈值按自己的写入量与复制延迟实测决定。
