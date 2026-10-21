# 缓存场景模板

模板基于 go-redis v9 与 `golang.org/x/sync/singleflight`，已在 Redis 8.10.2 上编译运行；`rdb` 为 `redis.UniversalClient`，key 按 `.claude/rules/redis.md` 的格式由集中函数生成。

## 1. 读：旁路缓存 + 穿透 / 击穿 / 雪崩

| 问题 | 做法 | 说明 |
|---|---|---|
| 穿透（数据不存在） | 缓存空值，TTL 30～60 秒；id 可枚举且量大时加布隆过滤器 | 空值约 95 字节 / key（参考资料在 Redis 8.2 上的实测），被随机 id 攻击时会占满内存，入口先校验 id 格式并限流 |
| 击穿（热点 key 过期） | 进程内 `singleflight` 合并回源；多实例仍压垮数据库时再加分布式互斥或逻辑过期 | 拿不到互斥锁的请求短暂 sleep 后重读缓存，不排队等锁；拿到锁后先再查一次缓存 |
| 雪崩（大批 key 同时过期） | TTL 加 10%～20% 随机偏移；预热分批 | 参考资料实测：1 万个固定 TTL 的 key 在同一秒全部失效，加偏移后分散到 7 秒 |
| 雪崩（Redis 不可用） | 降级读数据库 + 限流 / 熔断；热点数据可加进程内缓存 | 保护数据库优先于保证命中率 |

```go
var sf singleflight.Group

const nullMarker = "\x00null"

func ttlWithJitter(base time.Duration) time.Duration {
	return base + time.Duration(rand.Int64N(int64(base/10)+1)) // math/rand/v2
}

func (r *UserCache) Get(ctx context.Context, id int64) (*User, error) {
	key := UserProfileKey(id)
	s, err := r.rdb.Get(ctx, key).Result()
	switch {
	case err == nil:
		if s == nullMarker {
			return nil, ErrNotFound
		}
		return decodeUser(s)
	case !errors.Is(err, redis.Nil):
		r.log.Warn("redis get failed, fallback to db", "key", key, "err", err) // 故障降级，不当成未命中写回
		return r.repo.FindByID(ctx, id)
	}
	v, err, _ := sf.Do(key, func() (any, error) {
		u, err := r.repo.FindByID(ctx, id)
		if errors.Is(err, ErrNotFound) {
			r.rdb.Set(ctx, key, nullMarker, 30*time.Second)
			return nil, err
		}
		if err != nil {
			return nil, err
		}
		r.rdb.Set(ctx, key, encodeUser(u), ttlWithJitter(30*time.Minute))
		return u, nil
	})
	if err != nil {
		return nil, err
	}
	return v.(*User), nil
}
```

- `singleflight` 共享第一个调用者的 ctx：第一个请求被取消，同批请求都会拿到取消错误。需要隔离时在回调里用 `context.WithoutCancel(ctx)` 加超时。
- 逻辑过期（value 里存过期时间、过期后返回旧值并异步刷新）零等待但有脏读窗口，key 没有真 TTL，实例需 `allkeys-*` 淘汰策略；只用于少量明确的热点 key。

## 2. 写：先更新数据库，再删缓存

| 顺序 | 并发下的结果 |
|---|---|
| 先更新数据库，再**更新**缓存 | 两个写请求交错会把旧值留在缓存，直到 TTL |
| 先删缓存，再更新数据库 | 读请求在两步之间把旧值写回缓存，直到 TTL |
| **先更新数据库，再删缓存** | 只在「读未命中且查到旧值后、写回前，恰好完成一次写」时留下旧值，概率低 |

- 删缓存失败时记录并重试（重试任务或消息），不吞掉错误；TTL 是最终兜底，决定最长不一致时间。
- 读从库时，删缓存后读请求可能从落后的从库读到旧值写回；此时用延迟双删（提交后删一次，延迟大于「从库延迟 + 一次读耗时」再删一次），或由 binlog / CDC 订阅统一删缓存。
- 缓存与数据库之间没有强一致；要求强一致的读直接查主库。

## 3. 分布式锁

适用：防重复提交、缓存重建、定时任务防并发等「偶尔失效只是多做一次」的场景。主从切换时未复制的锁会丢失，GC 停顿或网络延迟可能让两个持有者同时在临界区；扣款、库存等不能出错的场景，正确性由数据库唯一约束、版本号（fencing token）或事务保证，Redis 锁只用来减少冲突。不用 Redlock。

```go
var (
	unlockScript = redis.NewScript(`if redis.call("GET", KEYS[1]) == ARGV[1] then return redis.call("DEL", KEYS[1]) end return 0`)
	renewScript  = redis.NewScript(`if redis.call("GET", KEYS[1]) == ARGV[1] then return redis.call("PEXPIRE", KEYS[1], ARGV[2]) end return 0`)
)

// WithLock 拿不到锁返回 ErrLockBusy；续期失败时取消 fn 的 ctx。
func WithLock(ctx context.Context, rdb redis.UniversalClient, key string, ttl time.Duration, fn func(context.Context) error) error {
	token := uuid.NewString()
	ok, err := rdb.SetNX(ctx, key, token, ttl).Result()
	if err != nil {
		return err
	}
	if !ok {
		return ErrLockBusy
	}
	lctx, cancel := context.WithCancel(ctx)
	defer cancel()
	done := make(chan struct{})
	go func() { // 续期：每 ttl/3 一次；锁已易主，或续期失败且剩余有效期不足 ttl/2 时中止业务
		defer close(done)
		t := time.NewTicker(ttl / 3)
		defer t.Stop()
		expiry := time.Now().Add(ttl)
		for {
			select {
			case <-lctx.Done():
				return
			case <-t.C:
				start := time.Now()
				n, err := renewScript.Run(lctx, rdb, []string{key}, token, ttl.Milliseconds()).Int()
				switch {
				case err == nil && n == 1:
					expiry = start.Add(ttl)
				case err == nil || time.Until(expiry) < ttl/2:
					cancel()
					return
				}
			}
		}
	}()
	err = fn(lctx)
	cancel()
	<-done
	uctx, ucancel := context.WithTimeout(context.WithoutCancel(ctx), time.Second)
	defer ucancel()
	_ = unlockScript.Run(uctx, rdb, []string{key}, token).Err()
	return err
}
```

- 不需要续期的短任务可去掉续期 goroutine，`ttl` 取业务耗时上限的数倍。
- 续期偶发网络错误时继续尝试，按本地记录的有效期在锁过期前取消业务 ctx；锁被他人持有时 `renewScript` 返回 0，立即取消。业务代码必须检查 ctx。复测（`ttl` 300ms）：持续续期的 700ms 任务正常完成；锁被改写后业务 ctx 立即取消；续期全部失败时 200ms 取消，此时锁剩余约 100ms。

## 4. 计数器、限流、排行榜、延时任务

| 场景 | 做法 | 要点 |
|---|---|---|
| 计数器 | `INCR` / `HINCRBY` | 原子；超时后结果未知，重试可能重复计数（见 `redis.md` 实测），精确计数以数据库为准 |
| 固定窗口限流 | Lua：`INCR` 后若返回 1 再 `PEXPIRE` | 窗口边界处最多放行 2 倍；分开发两条命令时进程崩溃会留下无 TTL 的 key |
| 滑动窗口限流 | ZSet + Lua：`ZREMRANGEBYSCORE` 清窗口外 → `ZCARD` → 未超限才 `ZADD` + `PEXPIRE` | member 必须唯一；被拒绝的请求不写入，否则用户永远恢复不了；每个请求一条记录，高频场景改令牌桶 |
| 排行榜 | ZSet，`ZINCRBY` 更新，`ZREVRANGE ... LIMIT` 分页取 | 成员数持续增长时只保留前 N 名（`ZREMRANGEBYRANK`），全量排名放数据库 |
| 延时任务 | ZSet，score 为执行时间；Lua 原子地「取到期的一条并 `ZREM`」 | 取走后崩溃即丢失，没有确认与重试；要可靠用消息队列的延时能力 |

```go
var fixedWindow = redis.NewScript(`
local n = redis.call("INCR", KEYS[1])
if n == 1 then redis.call("PEXPIRE", KEYS[1], ARGV[1]) end
return n`)

var slidingWindow = redis.NewScript(`
local now, window, limit = tonumber(ARGV[1]), tonumber(ARGV[2]), tonumber(ARGV[3])
redis.call("ZREMRANGEBYSCORE", KEYS[1], 0, now - window)
if redis.call("ZCARD", KEYS[1]) >= limit then return 0 end
redis.call("ZADD", KEYS[1], now, ARGV[4])
redis.call("PEXPIRE", KEYS[1], window)
return 1`)

// allowed, err := slidingWindow.Run(ctx, rdb, []string{key}, time.Now().UnixMilli(), 60000, 100, uuid.NewString()).Bool()
```

## 5. List、Pub/Sub、Stream 与消息队列

| 方式 | 消费者离线时 | 确认与重投 | 广播 | 适用 |
|---|---|---|---|---|
| List（`LPUSH` + `BRPOP`） | 消息保留 | 无，取出即删除；`LMOVE` 到处理中队列也要自己写重投 | 不支持 | 不推荐 |
| Pub/Sub | **丢失**（无订阅者时 `PUBLISH` 返回 0） | 无 | 支持 | 进程内缓存失效通知等可丢的信号 |
| Stream + 消费者组 | 保留 | `XACK`、`XAUTOCLAIM` | 多个消费者组 | 有确认与重投，但积压占内存；现行规则不用于消息传递 |
| Kafka / RabbitMQ | 保留在磁盘 | 完整 | 支持 | 业务消息的默认选择（见 `mq-design`） |

所有 Redis 方案的积压都占内存，`maxmemory` 满后触发淘汰或写入失败；规则要求消息走 Kafka 或 RabbitMQ。
