# 教学材料沉淀：待用户确认的疑问

2026-10-22 无人值守处理三个本机教学目录（gRPC、Go、Redis），把对 backend-dev 场景有收益的内容沉淀到配置。处理中无法自行决定、或与现行规范冲突的事项累积在此，等用户统一检查讨论。

每条格式：问题、背景与证据、当前处理（暂按哪种做法写入或未写入）、需要用户决定的选项。

## gRPC

落点：`rules/rpc/{proto,grpc-go}.md`、`skills/rpc-design/`、dev-ops `middleware-ops/references/grpc.md`。实测环境 grpc-go v1.84.0、buf 1.74.0。

1. **对外 HTTP/JSON 方案**。教材只说「对外加网关」，未比较方案；FiberHouse 分层允许多个 transport 复用 service。暂行：不指定，沿用项目已有方案，引入新方案写 ADR。选项：A 不指定 / B grpc-gateway / C Connect / D HTTP 走 FiberHouse handler，gRPC 只做服务间。
2. **buf breaking 默认类别**。实测 FILE 类别连「删字段并写 reserved」也报错，WIRE 不拦改名。暂行：以项目 `buf.yaml` 为准。选项：A 项目配置为准 / B 新项目默认 FILE / C 新项目默认 WIRE_JSON。
3. **生产是否开启 gRPC 反射**。暂行：仅开发、测试或配置开关打开时注册。选项：A 开关控制 / B 生产一律禁止 / C 内网默认开启。
4. **拦截器与可观测性自写还是用库**。context7 无 go-grpc-middleware 文档，API 无法核对，未写入。暂行：只给经测试的自写模板（recovery、日志、request id）。选项：A 自写 / B go-grpc-middleware v2 / C 链路追踪统一 otelgrpc StatsHandler（与 HTTP 侧一并决定）。
5. **gRPC 客户端代码的落点**。path rules 按路径匹配，调用下游 gRPC 的代码常在 `repository/` 等目录，`rules/rpc/grpc-go.md` 不会加载（ClientConn 复用、deadline、重试规则失效）。交叉审查暂行：规则内约定 handler 放 `api/grpc/`、客户端封装放 `grpc/` 目录或以 `_rpc.go` 结尾（项目已有约定优先），paths 由 `*grpc*.go` 放宽为 `*rpc*.go`。选项：A 维持此约定 / B paths 加 `**/repository/**/*.go`（编辑任何 repository 都会加载，约 2KB）/ C 不约定，靠 `rpc-design` skill 覆盖。
6. **本机残留**：docker 卷 `grpclab-gomod`（删除命令被权限拒绝）与镜像 `bufbuild/buf:latest` 未清理，需要时手动 `docker volume rm grpclab-gomod`。

## Go

落点：`rules/go/{code-style,concurrency,testing}.md`（`concurrency.md` 新增，原 code-style 的并发与 context 两节移入）、新增 skill `go-perf-diagnose`（含 `references/{concurrency,pprof}.md`）、两份 backend-dev `CLAUDE.md` 的「验证」段。实测环境 Go 1.25.14（`golang:1.25-alpine`）、`golang.org/x/sync v0.22.0`、`go.uber.org/goleak v1.3.0`。

1. **goroutine 内的 panic 是否一律 recover**。实测 `g.Go` / `go` 中 panic 直接终止进程，errgroup 源码注释说明不传播 panic 是有意设计（崩溃更易被发现）；但 HTTP / gRPC 的 recovery 中间件只覆盖请求 goroutine。暂行：规则要求「可能 panic 的代码在 goroutine 内 recover 并记录日志或转成 error」，扇出模板把 panic 转成 error。选项：A 维持 / B 只对请求路径外的后台 goroutine 要求 recover，计算型扇出任其崩溃 / C 不要求，交给进程重启。
2. **`GOMEMLIMIT` 取值与归属**。实测运行时不按容器内存限额自动设置；教材建议限额的 80%，未在负载下实测。暂行（交叉审查后）：rule 只写「由部署配置注入」，取值「80%～90%」放在 skill reference；dev-ops 场景未改。选项：A 维持 / B 固定写 80% 或 90% / C 同时在 dev-ops 的部署模板与 `middleware-ops` 巡检中加入检查。
3. **常驻上下文增量**（交叉审查已处理）。编辑任何 `.go` 时常驻的 `code-style + concurrency + logging` 由约 8.2KB 降到约 6.1KB（code-style 2.2→1.5KB、concurrency 4.0→2.6KB；原改动前约 5.9KB）。删去 AI 默认会写对或与 `logging.md` 重复的条目（类型断言两值、接口由使用方定义、logger 一行），解释、次要条目与 pprof 端口移到 `go-perf-diagnose/references/concurrency.md` 的「规则的补充说明」。仍可选：把「出站 HTTP 与运行时参数」一节移到只匹配 `**/main.go`、`**/cmd/**` 的 rule（约省 0.5KB）。
4. **生产环境是否开放 pprof**。暂行：skill 中写只挂在 localhost 或内网的单独端口、经 SSH 隧道访问，生产采集需用户确认（与 gRPC 第 3 条同类）；交叉审查后该条不再常驻 rule。选项：A 配置开关控制 / B 生产一律不注册 / C 内网端口常开，block 与 mutex 低采样率常开。
5. **新增 skill 是否保留**。`go-perf-diagnose` 触发于泄漏、内存、OOM、CPU、锁竞争、性能优化、benchmark 等排查场景，与「写新代码」场景不重叠；交叉审查认为触发清晰、值得独立，并补充了 GC 指针数量与 `go tool trace` 两行。选项：A 保留 / B 并入 `go-new-module` 的 references，排查流程不做 skill / C 改名（如 `go-troubleshoot`）。
6. **依赖版本**（交叉审查已处理，按 A）。`golang.org/x/sync` v0.24.0 要求 `go` ≥ 1.26（已核对其 `go.mod`），写在 reference，不进 rule。
7. **`time.After` 在循环中是否硬性禁止**（交叉审查新增）。教材实测 1.23+ 未引用的定时器可回收，但仍主张「循环里别用」（每轮约 3 次分配）；官方文档写「There is no reason to prefer NewTimer when After will do」。暂行：rule 只要求语义正确（`time.After` 每轮重新计时，整体超时用循环外的 ctx 或 Timer），分配开销写在 reference。选项：A 维持 / B 恢复「循环里不用 `time.After`」硬约定。
8. **交叉审查修正记录**（无需决定）：reference 把「循环变量每轮独立」误归于 `wg.Go`，实为 `go` ≥ 1.22 语义，已改；`GOMAXPROCS` 补充「取 CPU limit 而非 request、向上取整且不低于 2、手动设置会关闭自动更新」（核对 1.25 `runtime` 源码注释，并以 `--cpus=1.5` 复测为 2）；`testing.md` 中 alpine 装 cgo 的环境说明移到 reference；Timer 1.22 / 1.25 模块差异、errgroup 不传播 panic（v0.22.0 源码注释）、`wg.Go`、`synctest` 在 1.25 正式、`b.Loop` 1.24 均已核对无误。
9. **未写入的教材内容**：GMP 调度、GC 三色标记与写屏障、接口内存布局、反射成本、小整数装箱缓存等属于原理或面试知识，对写业务代码收益低，未写入。`benchstat` 的 `-count=10` 来自其官方说明，未实测；pprof 速查与 block / mutex 默认关闭沿用教材实测与官方文档，本次未复测。
10. **本机残留**：无新建 docker 卷或容器；模块缓存与实测代码在 scratchpad 的 `go/`、`go-review/` 子目录，会话结束随 scratchpad 清理。

## Redis

落点：`rules/redis.md`、`skills/cache-design/`（`references/redis.md` 改写并加实测记录，新增 `references/patterns.md` 场景模板）、dev-ops `middleware-ops/references/redis.md`（内存与淘汰、持久化、巡检）。实测环境 Redis 8.10.2（`redis:8`，单机与 3 主集群）、7.4.11 对照，go-redis v9.22.0（集群另以 v9.17.3 对照），Go 1.25.14。

1. **key 禁止 `}` 与集群 hash tag 冲突**（2026-10-23 已决定：A 按建议放开）。`{ }` 只包住标识段、用业务实体 id、仅用于同 slot 的多 key 操作，写入 `rules/redis.md`，`cache-design` 同步。
2. **是否继续禁止 `MULTI` / `EXEC`**（2026-10-23 已决定：A 维持）。原子操作一律用 Lua；理由与官方文档出处写入 `cache-design/references/redis.md`。待验证、未入配置：Redis 8.4 起的 `DELEX` / `SET IFEQ` 能否替代解锁 Lua（项目最低版本与 go-redis v9.22 支持情况未核对）。
3. **go-redis 默认重试与非幂等写**（复测确认）。服务端被慢脚本占住 0.4s、`ReadTimeout` 300ms 时，默认重试下 `INCR` 返回成功但计数器为 2；`MaxRetries: -1` 返回超时、计数器为 1。`MaxRetries: 0` 即默认 3 次。暂行：rule 要求非幂等写用关闭重试的客户端或做成幂等。选项：A 维持 / B 全局 `MaxRetries: -1`，由调用方按幂等性自行重试 / C 只写在 reference。
4. **`ContextTimeoutEnabled` 是否强制开启**（复测确认）。关闭时 200ms 的 ctx 超时无效（服务端阻塞 1.5s 就等 1.5s），开启后 200ms 返回。暂行：rule 要求开启。选项：A 强制 / B 只在有请求级 deadline 的服务开启。
5. **淘汰策略默认值**。现行 ops 规范默认 `volatile-lru`；实测无 TTL key 时写入直接 OOM、不淘汰。参考资料主张纯缓存用 `allkeys-lru` / `allkeys-lfu`。暂行：维持 `volatile-lru`，补 OOM 现象、应急切换，注明服务端内置默认是 `noeviction`。选项：A 维持 / B 纯缓存实例 `allkeys-lfu`、混存实例 `volatile-lru` / C 一律 `allkeys-lru`。
6. **Redis Stream 是否允许**。Stream 有消费者组、确认与重投，但积压占内存。暂行（交叉审查收紧）：与 rule、`mq-design`「Redis 不作为消息队列」一致，`patterns.md` 只列对比，不给适用场景；Pub/Sub 只用于可丢的信号（实测无订阅者时直接丢失）。选项：A 维持 / B 允许已有 Redis 的内部轻量任务用 Stream，需在设计文档说明理由。
7. **分布式锁的边界**。暂行：`SET NX PX` + Lua 校验释放 / 续期；rule 新增「扣款、库存等由数据库唯一约束或版本号兜底」；不用 Redlock。选项：A 维持 / B 正确性关键的互斥改用 etcd 等 CP 存储并写入 rule / C 允许 Redlock。
8. **rule 的 paths 覆盖不到 repository 层**（与 gRPC 第 5 条同类）。Redis 调用常写在 `repository/` 下，文件名不含 cache / redis 时 `rules/redis.md` 不加载。暂行未改。选项：A 约定 Redis 访问代码放 `cache/` 目录或以 `_cache.go` 结尾 / B paths 加 `**/repository/**/*.go`（约 3.1KB）/ C 不改，靠 `cache-design` skill。
9. **单实例内存上限**。现行经验值「25GB 以内」；参考资料以 fork 耗时为由主张 8～16GB，但只测到 132MB，大内存为外推（未验证）。暂行：保留 25GB，补「开启持久化时偏向更小实例」与 `latest_fork_usec` 监控。选项：A 维持 / B 改为 16GB / C 按是否开启持久化给两个值。
10. **交叉审查修正记录**（无需决定）：rule 由 3.6KB 压到 3.1KB（原 2.2KB），改回第 1、2 条原条款，删去与 reference 重复的理由括注，`ClusterClient.Scan` 说明移回 reference。锁模板原续期循环在网络持续失败时不会中止业务（注释与代码不符），改为按本地记录的有效期在剩余不足 `ttl/2` 时取消 ctx，复测：续期正常、锁被改写、续期全部失败（200ms 取消，锁剩余约 100ms）三种情况均符合预期。独立复测确认：第 3、4 条；`PoolTimeout` 200ms 在默认重试下约 970ms 才返回、`-1` 时 200ms；pipeline 有未命中时 `Exec` 返回 `redis.Nil`、其他命令正常；`ClusterClient.Scan` 结果不完整且每次不同（原记录 199，复测 150 / 300），`ForEachMaster` 完整；7.4.11 与 8.10.2 的 `hash-max-listpack-entries` 均为 512、`zset` / `set` listpack 为 128；`MaxRetries`、`ErrPoolTimeout` 重试已核对 v9.22.0 源码。
11. **go-redis 版本**（无需决定）：v9.23.0 要求 `go` ≥ 1.26，`go` 1.25 的模块最高 v9.22.0；v9.17 → v9.22 默认 `ReadTimeout` 由 3s 改为 5s、重试退避由 8ms～512ms 改为 10ms～1s；实测 v9.22.0 的 `MGet` 与 `Do("MGET")` 跨 slot 仍报错，v9.23 未测。
12. **参考资料中推翻或修正的说法**（无需决定）：「`hash-max-listpack-entries` 默认 128」——不带配置文件启动时为 512，128 来自 `redis.conf` 示例；「八种淘汰策略」——8.10 多了 `allkeys-lrm`、`volatile-lrm`；「`MULTI` 不减少往返」——`TxPipelined` 一次发送；「逐条 `INCR` 比 pipeline 慢 462 倍」——主要是每次新建 `redis-cli` 进程与连接的开销；「淘汰一次触发 16035 个 key」——由一次性压低 `maxmemory` 造成，不代表常态。
13. **未写入的内容**：单线程与 I/O 多路复用、slot 数由来、跳表、RESP、MOVED / ASK、过期抽样算法等属原理或面试知识；RedisBloom 只在穿透一行提及；`KEYS` 在千万级 key 上的耗时、大实例 fork 秒级为外推，未写入；「主库无持久化自动重启会清空从库」「关闭 THP」来自官方文档，未实测。
14. **本机残留**：原代理的 docker 网络 `redislab-net`、交叉审查的 `redisrev-net` 删除命令均被权限拒绝；镜像 `redis:8`、`redis:7.4` 保留。需要时手动 `docker network rm redislab-net redisrev-net && docker rmi redis:8 redis:7.4`。容器均以 `--rm` 运行并已停止；实测代码与模块缓存在 scratchpad 的 `redis/`、`redis-review/` 子目录，随 scratchpad 清理。
