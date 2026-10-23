# 分层落点与完整示例

Redis 代码放在哪一层，以及通用 string 键值组件与 hash / set / zset 的写法。示例为一个完整可运行的模块（`example.com/shop`），已在 Redis 8.10.2 与 7.4.11、go-redis v9.22.0、Go 1.25 上通过 `go vet` 与集成测试（并发未命中只回源一次、空值缓存、更新后删缓存、Redis 不可用时降级、残缺 hash 不被创建、限长、去重计数等）。

## 落点

```text
component/cache/            通用 string 键值组件（框架自带时用框架的，例如 FiberHouse 的 component/cache）
module/<模块>/cache/        本模块全部 key 与 Redis 命令，对外提供有类型的方法
module/<模块>/service/      编排顺序：读走旁路缓存，写先更新数据库再删缓存；不 import go-redis
module/<模块>/repository/   只访问数据库
```

为什么这样分：

- `rules/redis.md` 按路径加载（`**/cache/**/*.go` 等）。Redis 命令散在 `service/`、`repository/` 时，编辑这些文件不会加载 Redis 规则；集中到 `cache/` 后，规则覆盖全部直接访问 Redis 的代码。
- 只在 `cache/` 中 import go-redis，可以用 golangci-lint 的 depguard 机械检查（`go-new-module` skill 的 `references/depguard.yml`）。
- 通用组件只解决「一个 key 存一段序列化值」：序列化、空值、合并回源、TTL 偏移、降级。hash / set / zset 的用法因业务而异，放在模块自己的 `cache/` 包，key 拼装也集中在那里。
- service 编排「数据库 + 缓存」的先后顺序（这部分规则写在 `rules/go/layering.md`，编辑 service 时会加载）。

框架自带缓存组件时（例如 FiberHouse 的 `cache.GetOrLoad` + `CacheOption`），旁路读取用框架的，模块 `cache/` 只放结构化用法；需要原生客户端时通过组件取得（FiberHouse 为 `GetRedisClient()`），不在业务代码中另建客户端。

## 示例中值得注意的写法

| 场景 | 写法 | 原因 |
|---|---|---|
| 旁路读取 | `singleflight` 中用 `context.WithoutCancel(ctx)` 加超时回源 | 首个调用方取消时，同 key 的其他等待者不应一起失败 |
| 穿透 | 数据源返回 `NotFound` 时写入短 TTL 空值标记 | 第二次查询不存在的 id 不再回源 |
| 降级 | `Get` 返回非未命中错误时直接回源、不写回 | Redis 故障不当作未命中；实测每次请求仍要付出连接失败的耗时，关键路径需要熔断 |
| hash 计数 | Lua：key 存在才 `HINCRBY` | key 不存在时直接 `HINCRBY` 会建出只有一个字段的 hash，之后被当作命中 |
| hash 改单个字段 | Lua：key 存在才 `HSET` | 同上 |
| hash 批量读 | pipeline 分批 `HMGET`（每批 120），字段缺失视为未命中 | 不同 id 的 key 分布在不同 slot，不能用多 key 命令 |
| set 多 key 运算 | 两个 key 的标识段用相同 hash tag `{id}`，再 `SDIFF` | 集群中多 key 命令要求同 slot |
| zset 最近 N 条 | `ZADD` + `ZREMRANGEBYRANK 0 -(N+1)` + `EXPIRE` | 重复元素只更新 score，长度有上限 |
| zset 计数去重 | 每单一个 `SET NX` 标记，成功才 `ZINCRBY`；用关闭重试的客户端 | `ZINCRBY` 非幂等；去重标记不放进同一个 set，避免变成 bigkey |
| 计数失败 | 不删去重标记，定时按数据库重算校正 | 读超时不等于未执行，删掉标记再重投可能重复计数 |
| 删除 | pipeline 逐个 `UNLINK` | 多 key `UNLINK` 跨 slot 会报 `CROSSSLOT` |

## 通用组件

`component/cache/cache.go`：

```go
// Package cache 是通用的 string 键值缓存组件：调用方只拿到「按 key 读写一段字节」与
// 「旁路读取」两种能力，序列化、防穿透、合并回源、TTL 偏移都在这里统一处理。
// hash / set / zset 等结构化用法放在各模块自己的 cache/ 包中。
package cache

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"math/rand/v2"
	"time"

	"github.com/redis/go-redis/v9"
	"golang.org/x/sync/singleflight"
)

// ErrMiss 表示缓存未命中；其他非 nil 错误都是 Redis 故障。
var ErrMiss = errors.New("cache: miss")

// KV 是 string 键值缓存的最小接口，便于在测试中替换。
type KV interface {
	Get(ctx context.Context, key string) ([]byte, error)
	Set(ctx context.Context, key string, val []byte, ttl time.Duration) error
	Del(ctx context.Context, keys ...string) error
}

// RedisKV 用 go-redis 实现 KV，单机、哨兵、集群客户端都可传入。
type RedisKV struct {
	rdb redis.UniversalClient
}

func NewRedisKV(rdb redis.UniversalClient) *RedisKV {
	return &RedisKV{rdb: rdb}
}

func (c *RedisKV) Get(ctx context.Context, key string) ([]byte, error) {
	b, err := c.rdb.Get(ctx, key).Bytes()
	if errors.Is(err, redis.Nil) {
		return nil, ErrMiss
	}
	return b, err
}

func (c *RedisKV) Set(ctx context.Context, key string, val []byte, ttl time.Duration) error {
	return c.rdb.Set(ctx, key, val, ttl).Err()
}

// Del 逐个 key 用 UNLINK 删除：多 key 一次删除在集群中跨 slot 会报 CROSSSLOT，
// 因此走 pipeline，而不是 Unlink(ctx, keys...)。
func (c *RedisKV) Del(ctx context.Context, keys ...string) error {
	_, err := c.rdb.Pipelined(ctx, func(p redis.Pipeliner) error {
		for _, k := range keys {
			p.Unlink(ctx, k)
		}
		return nil
	})
	return err
}

// NewRedisClient 在进程启动时调用一次，结果经依赖注入共享。
// noRetry 为 true 时关闭自动重试，供 INCR、ZINCRBY 等非幂等写使用。
func NewRedisClient(addr string, noRetry bool) *redis.Client {
	opt := &redis.Options{
		Addr:                  addr,
		DialTimeout:           2 * time.Second,
		ReadTimeout:           500 * time.Millisecond,
		WriteTimeout:          500 * time.Millisecond,
		PoolSize:              50,
		PoolTimeout:           time.Second,
		ContextTimeoutEnabled: true,
	}
	if noRetry {
		opt.MaxRetries = -1
	}
	return redis.NewClient(opt)
}

// nullMarker 标记「数据源中不存在」，JSON 编码结果不会是单个 0 字节。
var nullMarker = []byte{0}

// LoadOptions 描述一类缓存条目的读取策略，通常按业务用途定义成包级常量值。
type LoadOptions struct {
	TTL         time.Duration // 正常值的基础 TTL
	NullTTL     time.Duration // 空值的基础 TTL，应明显短于 TTL
	Jitter      float64       // TTL 随机偏移比例，0.1 表示增加 0～10%
	LoadTimeout time.Duration // 回源超时，与调用方 ctx 的取消解耦
	NotFound    error         // 数据源的「不存在」哨兵错误，命中时写入空值
}

// ReadThrough 持有 singleflight 分组，进程内共享一个实例。
type ReadThrough struct {
	kv KV
	sf singleflight.Group
}

func NewReadThrough(kv KV) *ReadThrough {
	return &ReadThrough{kv: kv}
}

// Invalidate 在数据库更新成功后调用（先更新数据库，再删缓存）。
func (r *ReadThrough) Invalidate(ctx context.Context, keys ...string) error {
	return r.kv.Del(ctx, keys...)
}

// GetOrLoad 实现旁路缓存读取：命中直接返回；未命中时同 key 只回源一次并写回；
// 数据源不存在时写入短 TTL 空值；Redis 故障时降级直接回源、不写回。
func GetOrLoad[T any](ctx context.Context, r *ReadThrough, key string, o LoadOptions,
	load func(context.Context) (T, error)) (T, error) {
	var zero T
	b, err := r.kv.Get(ctx, key)
	switch {
	case err == nil:
		if bytes.Equal(b, nullMarker) {
			return zero, o.NotFound
		}
		var v T
		if err := json.Unmarshal(b, &v); err != nil {
			return zero, err
		}
		return v, nil
	case !errors.Is(err, ErrMiss):
		// Redis 故障不当作未命中写回，直接读数据源；限流与熔断由调用链路负责。
		return load(ctx)
	}

	v, err, _ := r.sf.Do(key, func() (any, error) {
		// 首个调用方的 ctx 被取消时，不能让同 key 的其他等待者一起失败。
		lctx, cancel := context.WithTimeout(context.WithoutCancel(ctx), o.LoadTimeout)
		defer cancel()
		val, err := load(lctx)
		if o.NotFound != nil && errors.Is(err, o.NotFound) {
			_ = r.kv.Set(lctx, key, nullMarker, jitter(o.NullTTL, o.Jitter))
			return nil, err
		}
		if err != nil {
			return nil, err
		}
		if b, err := json.Marshal(val); err == nil {
			_ = r.kv.Set(lctx, key, b, jitter(o.TTL, o.Jitter)) // 写回失败只影响命中率
		}
		return val, nil
	})
	if err != nil {
		return zero, err
	}
	t, _ := v.(T) // loader 返回 nil 指针时 v 为 nil，取零值
	return t, nil
}

func jitter(ttl time.Duration, ratio float64) time.Duration {
	span := time.Duration(float64(ttl) * ratio)
	if span <= 0 {
		return ttl
	}
	return ttl + rand.N(span)
}
```

## user 模块

`module/user/repository/user_repository.go`：

```go
package repository

import (
	"context"
	"errors"

	"example.com/shop/module/user/entity"
)

// ErrNotFound 是 repository 向上暴露的领域错误，驱动的「无记录」错误在实现中转换为它。
var ErrNotFound = errors.New("user not found")

// UserStore 是数据库存取接口；实现（MySQL / MongoDB）不在本示例范围内。
type UserStore interface {
	Get(ctx context.Context, id int64) (*entity.User, error)
	UpdateName(ctx context.Context, id int64, name string) error
	IncrFollowers(ctx context.Context, id int64, delta int64) error
}
```

`module/user/cache/user_cache.go`：

```go
// Package cache 是 user 模块对 Redis 的全部直接访问：key 拼装集中在这里，
// service 只调用这里的方法，不 import go-redis。
package cache

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"time"

	"github.com/redis/go-redis/v9"
)

// key 格式：<系统>:<模块>:<用途>:<数据类型>:<标识>
func ProfileKey(id int64) string { return fmt.Sprintf("shop:user:profile:string:%d", id) }
func statsKey(id int64) string   { return fmt.Sprintf("shop:user:stats:hash:%d", id) }

// 两个 set 要一起做 SDIFF，用 hash tag 包住整个标识段，保证集群中落在同一 slot。
func tagsKey(id int64) string  { return fmt.Sprintf("shop:user:tags:set:{%d}", id) }
func mutedKey(id int64) string { return fmt.Sprintf("shop:user:muted_tags:set:{%d}", id) }

func recentKey(id int64) string { return fmt.Sprintf("shop:user:recent_viewed:zset:%d", id) }

const (
	statsTTL     = 30 * time.Minute
	tagsTTL      = 24 * time.Hour
	recentTTL    = 7 * 24 * time.Hour
	RecentMaxLen = 50
)

// ---------- hash：计数器缓存 ----------

// Stats 缓存用户的计数字段，数据源是数据库。
type Stats struct {
	rdb redis.Cmdable // 传入关闭重试的客户端：HINCRBY 非幂等
}

func NewStats(rdb redis.Cmdable) *Stats { return &Stats{rdb: rdb} }

// Fill 回源后整体写入并设 TTL。HSET 与 EXPIRE 放进一个 pipeline 减少往返（不是事务）。
func (s *Stats) Fill(ctx context.Context, id int64, followers, posts int64) error {
	_, err := s.rdb.Pipelined(ctx, func(p redis.Pipeliner) error {
		p.HSet(ctx, statsKey(id), "followers", followers, "posts", posts)
		p.Expire(ctx, statsKey(id), statsTTL)
		return nil
	})
	return err
}

// Get 返回 (followers, posts, 是否命中)。HMGET 对不存在的 key 返回全 nil，而不是 redis.Nil。
func (s *Stats) Get(ctx context.Context, id int64) (followers, posts int64, hit bool, err error) {
	vals, err := s.rdb.HMGet(ctx, statsKey(id), "followers", "posts").Result()
	if err != nil {
		return 0, 0, false, err
	}
	if vals[0] == nil || vals[1] == nil {
		return 0, 0, false, nil
	}
	if followers, err = strconv.ParseInt(vals[0].(string), 10, 64); err != nil {
		return 0, 0, false, err
	}
	if posts, err = strconv.ParseInt(vals[1].(string), 10, 64); err != nil {
		return 0, 0, false, err
	}
	return followers, posts, true, nil
}

// incrIfExists：key 不存在时直接 HINCRBY 会建出只有一个字段的残缺 hash，
// 之后 Get 会把它当命中。只在 key 已存在时递增，否则等下次回源整体写入。
var incrIfExists = redis.NewScript(`
if redis.call('EXISTS', KEYS[1]) == 1 then
  return redis.call('HINCRBY', KEYS[1], ARGV[1], ARGV[2])
end
return false`)

// ErrNotCached 表示缓存中没有该条目，调用方无需处理。
var ErrNotCached = errors.New("user stats not cached")

func (s *Stats) Incr(ctx context.Context, id int64, field string, delta int64) (int64, error) {
	n, err := incrIfExists.Run(ctx, s.rdb, []string{statsKey(id)}, field, delta).Int64()
	if errors.Is(err, redis.Nil) { // Lua 的 false 在 go-redis 中是 redis.Nil
		return 0, ErrNotCached
	}
	return n, err
}

// ---------- set：兴趣标签与屏蔽标签 ----------

type Tags struct {
	rdb redis.Cmdable
}

func NewTags(rdb redis.Cmdable) *Tags { return &Tags{rdb: rdb} }

func (t *Tags) Add(ctx context.Context, id int64, tags ...string) error {
	return t.add(ctx, tagsKey(id), tags)
}

func (t *Tags) Mute(ctx context.Context, id int64, tags ...string) error {
	return t.add(ctx, mutedKey(id), tags)
}

func (t *Tags) add(ctx context.Context, key string, tags []string) error {
	members := make([]any, len(tags))
	for i, tag := range tags {
		members[i] = tag
	}
	_, err := t.rdb.Pipelined(ctx, func(p redis.Pipeliner) error {
		p.SAdd(ctx, key, members...)
		p.Expire(ctx, key, tagsTTL)
		return nil
	})
	return err
}

// Has 是 O(1) 的成员判断，不要先 SMEMBERS 再在代码里查找。
func (t *Tags) Has(ctx context.Context, id int64, tag string) (bool, error) {
	return t.rdb.SIsMember(ctx, tagsKey(id), tag).Result()
}

// Visible 返回未被屏蔽的标签。SDIFF 是多 key 命令，两个 key 带相同 hash tag 才能在集群执行；
// 标签集合有上限（业务限制 200 个以内），因此可以整体返回。
func (t *Tags) Visible(ctx context.Context, id int64) ([]string, error) {
	return t.rdb.SDiff(ctx, tagsKey(id), mutedKey(id)).Result()
}

// ---------- zset：最近浏览（去重 + 按时间排序 + 限长） ----------

type Recent struct {
	rdb redis.Cmdable
}

func NewRecent(rdb redis.Cmdable) *Recent { return &Recent{rdb: rdb} }

// Touch 以浏览时间为 score，重复浏览只更新时间；超过上限时删掉最旧的。
func (r *Recent) Touch(ctx context.Context, id int64, productID string, at time.Time) error {
	key := recentKey(id)
	_, err := r.rdb.Pipelined(ctx, func(p redis.Pipeliner) error {
		p.ZAdd(ctx, key, redis.Z{Score: float64(at.UnixMilli()), Member: productID})
		p.ZRemRangeByRank(ctx, key, 0, -RecentMaxLen-1)
		p.Expire(ctx, key, recentTTL)
		return nil
	})
	return err
}

// List 返回最近浏览的前 n 个，最新的在前。
func (r *Recent) List(ctx context.Context, id int64, n int64) ([]string, error) {
	return r.rdb.ZRevRange(ctx, recentKey(id), 0, n-1).Result()
}
```

`module/user/service/user_service.go`：

```go
package service

import (
	"context"
	"errors"
	"log/slog"
	"time"

	kv "example.com/shop/component/cache"
	"example.com/shop/module/user/cache"
	"example.com/shop/module/user/entity"
	"example.com/shop/module/user/repository"
)

// profileLoad 是用户详情缓存的读取策略，与 key 一起决定这一类缓存的行为。
var profileLoad = kv.LoadOptions{
	TTL:         10 * time.Minute,
	NullTTL:     time.Minute,
	Jitter:      0.1,
	LoadTimeout: 2 * time.Second,
	NotFound:    repository.ErrNotFound,
}

// UserService 编排「数据库 + 缓存」的顺序；Redis 命令细节都在 module/user/cache。
type UserService struct {
	store repository.UserStore
	rt    *kv.ReadThrough
	stats *cache.Stats
}

func NewUserService(store repository.UserStore, rt *kv.ReadThrough, stats *cache.Stats) *UserService {
	return &UserService{store: store, rt: rt, stats: stats}
}

// Get：string 键值 + 旁路缓存，由通用组件处理穿透、击穿与降级。
func (s *UserService) Get(ctx context.Context, id int64) (*entity.User, error) {
	return kv.GetOrLoad(ctx, s.rt, cache.ProfileKey(id), profileLoad,
		func(ctx context.Context) (*entity.User, error) { return s.store.Get(ctx, id) })
}

// UpdateName：先更新数据库，再删缓存；删除失败只记日志，由 TTL 兜底。
func (s *UserService) UpdateName(ctx context.Context, id int64, name string) error {
	if err := s.store.UpdateName(ctx, id, name); err != nil {
		return err
	}
	if err := s.rt.Invalidate(ctx, cache.ProfileKey(id)); err != nil {
		slog.WarnContext(ctx, "invalidate user profile cache failed", "user_id", id, "err", err)
	}
	return nil
}

// Follow：数据库计数是数据源，缓存中的计数器只在已缓存时同步递增；
// 详情缓存里也带了 followers，直接删掉让下次回源。
func (s *UserService) Follow(ctx context.Context, id int64) error {
	if err := s.store.IncrFollowers(ctx, id, 1); err != nil {
		return err
	}
	if _, err := s.stats.Incr(ctx, id, "followers", 1); err != nil && !errors.Is(err, cache.ErrNotCached) {
		slog.WarnContext(ctx, "incr user stats cache failed", "user_id", id, "err", err)
	}
	if err := s.rt.Invalidate(ctx, cache.ProfileKey(id)); err != nil {
		slog.WarnContext(ctx, "invalidate user profile cache failed", "user_id", id, "err", err)
	}
	return nil
}
```

## product 模块：hash 摘要

`module/product/cache/product_cache.go`：

```go
// Package cache 缓存商品摘要（hash），供列表页按字段批量读取。
package cache

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

func summaryKey(id int64) string { return fmt.Sprintf("shop:product:summary:hash:%d", id) }

const (
	summaryTTL = 30 * time.Minute
	batchSize  = 120 // pipeline 每批 key 数上限
)

// Summary 是列表页需要的字段；详情页的完整对象另用 string 键值缓存。
type Summary struct {
	ID    int64
	Title string
	Price int64 // 分
}

type Summaries struct {
	rdb redis.Cmdable
}

func NewSummaries(rdb redis.Cmdable) *Summaries { return &Summaries{rdb: rdb} }

// Fill 回源后写入整组字段。
func (s *Summaries) Fill(ctx context.Context, items []Summary) error {
	for start := 0; start < len(items); start += batchSize {
		batch := items[start:min(start+batchSize, len(items))]
		_, err := s.rdb.Pipelined(ctx, func(p redis.Pipeliner) error {
			for _, it := range batch {
				p.HSet(ctx, summaryKey(it.ID), "title", it.Title, "price", it.Price)
				p.Expire(ctx, summaryKey(it.ID), summaryTTL)
			}
			return nil
		})
		if err != nil {
			return err
		}
	}
	return nil
}

// SetPrice 只改一个字段：数据库改价成功后调用。key 不存在时 HSET 会建出缺字段的 hash，
// 因此在 Lua 中先判断存在（与 user 模块的 incrIfExists 同理）。
var setIfExists = redis.NewScript(`
if redis.call('EXISTS', KEYS[1]) == 1 then
  return redis.call('HSET', KEYS[1], ARGV[1], ARGV[2])
end
return false`)

func (s *Summaries) SetPrice(ctx context.Context, id int64, price int64) error {
	err := setIfExists.Run(ctx, s.rdb, []string{summaryKey(id)}, "price", price).Err()
	if errors.Is(err, redis.Nil) {
		return nil // 未缓存，下次回源时写入
	}
	return err
}

// MGet 按 id 批量读取摘要，返回命中的条目与未命中的 id（由调用方回源后 Fill）。
// 不同 id 的 key 分布在不同 slot，用 pipeline 而不是多 key 命令；HMGET 未命中时字段全为 nil。
func (s *Summaries) MGet(ctx context.Context, ids []int64) (hits map[int64]Summary, misses []int64, err error) {
	hits = make(map[int64]Summary, len(ids))
	for start := 0; start < len(ids); start += batchSize {
		batch := ids[start:min(start+batchSize, len(ids))]
		cmds := make([]*redis.SliceCmd, len(batch))
		_, err := s.rdb.Pipelined(ctx, func(p redis.Pipeliner) error {
			for i, id := range batch {
				cmds[i] = p.HMGet(ctx, summaryKey(id), "title", "price")
			}
			return nil
		})
		if err != nil {
			return nil, nil, err
		}
		for i, id := range batch {
			var v struct {
				Title string `redis:"title"`
				Price *int64 `redis:"price"`
			}
			if err := cmds[i].Scan(&v); err != nil {
				return nil, nil, err
			}
			if v.Price == nil { // 字段缺失视为未命中
				misses = append(misses, id)
				continue
			}
			hits[id] = Summary{ID: id, Title: v.Title, Price: *v.Price}
		}
	}
	return hits, misses, nil
}
```

## rank 模块：zset 排行榜

`module/rank/cache/rank_cache.go`：

```go
// Package cache 是每日销量排行榜（zset）。排行榜可由订单表重建，数据源仍是数据库。
package cache

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

func salesKey(day string) string { return fmt.Sprintf("shop:rank:sales:zset:%s", day) }

// 订单去重标记，一单一个 key（避免把当天全部订单号塞进一个 set 成为 bigkey）。
func countedKey(orderID int64) string { return fmt.Sprintf("shop:rank:counted:string:%d", orderID) }

const (
	salesTTL   = 3 * 24 * time.Hour
	countedTTL = 3 * 24 * time.Hour
	MaxTopN    = 100
)

// Rank 必须使用关闭重试的客户端：ZINCRBY 读超时后自动重试会重复计数。
type Rank struct {
	rdb redis.Cmdable
}

func NewRank(rdb redis.Cmdable) *Rank { return &Rank{rdb: rdb} }

// AddSale 在订单支付成功（数据库已提交）后调用，同一订单只计一次。
// 去重 key 与排行榜 key 不在同一 slot，分两步：SET NX 成功才 ZINCRBY。
// ZINCRBY 报错时不删去重标记：读超时不等于未执行，删掉再重投可能重复计数；
// 宁可少计，由定时任务按订单表重算当天排行榜校正。
func (r *Rank) AddSale(ctx context.Context, day string, orderID int64, skuID string, qty int64) error {
	ok, err := r.rdb.SetNX(ctx, countedKey(orderID), 1, countedTTL).Result()
	if err != nil || !ok {
		return err // 已计过返回 nil
	}
	key := salesKey(day)
	_, err = r.rdb.Pipelined(ctx, func(p redis.Pipeliner) error {
		p.ZIncrBy(ctx, key, float64(qty), skuID)
		p.Expire(ctx, key, salesTTL)
		return nil
	})
	return err
}

// Top 返回前 n 名（n 不超过 MaxTopN），销量从高到低。
func (r *Rank) Top(ctx context.Context, day string, n int64) ([]redis.Z, error) {
	n = min(n, MaxTopN)
	return r.rdb.ZRevRangeWithScores(ctx, salesKey(day), 0, n-1).Result()
}

// ErrNotRanked 表示该商品当天没有销量。
var ErrNotRanked = errors.New("sku not ranked")

// RankOf 返回名次（从 1 开始）与销量。ZREVRANK 对不存在的成员返回 redis.Nil。
func (r *Rank) RankOf(ctx context.Context, day, skuID string) (rank int64, sales float64, err error) {
	var rk *redis.IntCmd
	var sc *redis.FloatCmd
	_, err = r.rdb.Pipelined(ctx, func(p redis.Pipeliner) error {
		rk = p.ZRevRank(ctx, salesKey(day), skuID)
		sc = p.ZScore(ctx, salesKey(day), skuID)
		return nil
	})
	if errors.Is(err, redis.Nil) {
		return 0, 0, ErrNotRanked
	}
	if err != nil {
		return 0, 0, err
	}
	return rk.Val() + 1, sc.Val(), nil
}
```

## 验证

本文件的代码对应一组集成测试（未收录），覆盖：50 个并发未命中只回源 1 次；TTL 落在基础值到基础值加 10% 之间；更新后缓存被删除并读到新值；不存在的 id 第二次查询不回源；Redis 不可达时降级读数据源；未缓存时 `Incr`、`SetPrice` 不建出残缺 hash；`SDIFF` 结果；最近浏览限长与最新在前；300 个摘要分批写入与读取、未命中 id 正确返回；同一订单重投只计一次、名次与销量、无销量返回 `ErrNotRanked`。修改示例时照这些行为补测。
