---
paths:
  - "**/cache/**/*.go"
  - "**/redis/**/*.go"
  - "**/*cache*.go"
  - "**/*redis*.go"
---

# Redis

适用于 go-redis；不用 Redis 的项目删除本文件。设计缓存时用 `cache-design` skill，条目理由见其 `references/redis.md`。

## key

- 格式：`<系统>:<模块>:<用途>:<数据类型>:<标识>`，全部小写，段内用下划线，不用驼峰。例：`blog:user:profile:hash:1001`、`shop:cart:items:zset:2001`。
- 不含 `! @ " ' $ % # ^ & * ? < > }` 等特殊字符；整个 key 不超过 256 字节。
- key 的拼装集中在一个函数或常量里，不在业务代码各处手拼字符串。

## value

- 不写 bigkey：`string` 不超过 10KB；`hash`、`list`、`set`、`zset` 不超过 10000 个元素。超出时拆分 key 或改用其他存储；超过 25KB 的文本先压缩。
- 读取频繁的 key 更要控制大小（hot bigkey 会打满带宽与单线程）。
- 每个 key 都设 TTL，并加随机偏移，避免同时过期。

## 命令

- 线上代码不用 `KEYS`、`FLUSHALL`、`FLUSHDB`、`MONITOR`；遍历用 `SCAN` / `HSCAN` / `SSCAN` / `ZSCAN` 并限制 `COUNT`。
- 不对大集合用 O(N) 命令（`HGETALL`、`SMEMBERS`、`LRANGE 0 -1`、`ZRANGE 0 -1` 等），单次处理的元素不超过 1000 个；`MGET` / pipeline 每批不超过 120 个 key。
- 分布式锁用 `SetNX(ctx, key, token, ttl)`（单条 `SET NX EX`），释放时校验 token；不用 `SETNX` 后再 `EXPIRE` 的两步写法。
- 不用 `MULTI` / `EXEC` 事务；`EVAL` / Lua 只在必须原子执行时使用，脚本里用到的 key 全部通过 `KEYS` 参数传入（集群路由需要）。

## 用途与连接

- Redis 只当缓存，数据源仍在数据库；不当消息队列用（用 Kafka 或 RabbitMQ），不把全部数据或冷数据放进 Redis。
- 只用 db0（集群不支持其他 db）。
- 一个进程共享一个 `*redis.Client` / `*redis.ClusterClient` 并复用连接池，不按请求新建连接；设置 `DialTimeout`、`ReadTimeout`、`WriteTimeout`、`PoolSize`。
- Redis 出错时降级读数据库，不让缓存故障变成整体故障；重试用指数退避并设上限，关键路径加限流或熔断。
