# 教学材料沉淀：待用户确认的疑问

2026-10-22 无人值守处理三个本机教学目录（gRPC、Go、Redis），把对 backend-dev 场景有收益的内容沉淀到配置；2026-10-23 与用户逐条讨论定稿。本文件按状态组织：待确认、待办、决定记录、待验证、参考记录、本机残留。

落点：gRPC `rules/rpc/{proto,grpc-go}.md`、`skills/rpc-design/`、dev-ops `middleware-ops/references/grpc.md`；Go `rules/go/{code-style,concurrency,testing}.md`、`skills/go-perf-diagnose/`；Redis `rules/redis.md`、`skills/cache-design/`（含 `references/patterns.md`）、`middleware-ops/references/redis.md`。实测环境：grpc-go v1.84.0、buf 1.74.0；Go 1.25.14、x/sync v0.22.0；Redis 8.10.2 / 7.4.11、go-redis v9.22.0。

## 一、待确认

1. **Redis 单实例内存上限**（原 Redis 9）。现行用户规范「25GB 以内」；参考资料以 fork 耗时为由主张 8～16GB，但只测到 132MB，大内存为外推。现状：保留 25GB，补「开启持久化时偏向更小实例」与 `latest_fork_usec` 监控。选项：A 维持 / B 改为 16GB / C 按是否开启持久化给两个值。

## 二、待办（已决定，需后续实施）

1. **gRPC 追踪与指标统一 OpenTelemetry**：与 HTTP 侧一并决定；写入前核对 otelgrpc 官方文档。未写入配置。
2. **dev-ops 部署模板注入 `GOMEMLIMIT` 并加入巡检**：注入方式（如 K8s 引用容器内存限额）需实测后再写入；backend rule 维持「由部署配置注入」。
3. **Redis 8.4 起的 `DELEX` / `SET IFEQ` 能否替代解锁 Lua**：核对项目最低 Redis 版本与 go-redis v9.22 支持情况后再决定是否写入。

## 三、决定记录（2026-10-23）

| 主题 | 决定 | 落点 |
|---|---|---|
| gRPC 对外 HTTP/JSON | 对外走 FiberHouse HTTP handler 调同一 service，gRPC 只做服务间；不引入 grpc-gateway、Connect（项目已有时沿用） | `rpc-design/SKILL.md` |
| buf breaking 类别 | 新项目 `FILE`（buf 默认）；淘汰字段标 `deprecated` 保留，破坏性变更开新版本 package；已有项目以其 `buf.yaml` 为准 | `rules/rpc/proto.md`、`rpc-design/SKILL.md` |
| gRPC 反射 | 配置开关控制，生产默认关闭 | `rules/rpc/grpc-go.md` |
| gRPC 拦截器 | recovery、日志、request id 自写（模板已实测）；不引入 go-grpc-middleware | `rpc-design/references/grpc-go.md` |
| goroutine 内 panic | 自己开的 goroutine 一律 recover，记录日志或转成 error | `rules/go/concurrency.md` |
| Go 常驻规则体积 | 维持 6.1KB，不再拆分「出站 HTTP 与运行时参数」 | — |
| 生产 pprof | 配置开关控制，生产默认关闭，只监听 localhost / 内网，经 SSH 隧道访问 | `go-perf-diagnose/references/pprof.md` |
| `go-perf-diagnose` skill | 保留 | — |
| 循环中 `time.After` | 不硬性禁止，只要求语义正确（整体超时用循环外 ctx 或 Timer） | `rules/go/concurrency.md` |
| x/sync 版本 | v0.24.0 要求 go ≥ 1.26，写在 reference，不进 rule | `go-perf-diagnose/references/concurrency.md` |
| Redis hash tag | `{}` 只包住标识段，用业务实体 id，仅用于同 slot 的多 key 操作；只为减少往返用 pipeline | `rules/redis.md`、`cache-design` |
| `MULTI` / `EXEC` | 维持不用，原子操作一律 Lua（官方：脚本能做事务能做的一切，通常更简单更快） | `cache-design/references/redis.md` |
| go-redis 重试 | 维持：非幂等写用关闭重试（`MaxRetries: -1`）的客户端或做成幂等 | `rules/redis.md` |
| `ContextTimeoutEnabled` | 强制开启 | `rules/redis.md` |
| 淘汰策略 | 按实例用途：纯缓存 `allkeys-lru`（官方推荐默认，命中率不佳再对比 LFU），混存 `volatile-lru`；新实例显式配置 | `middleware-ops/references/redis.md` |
| Redis Stream | 维持：Redis 不作为消息队列；Pub/Sub 只用于可丢的信号 | `rules/redis.md`、`mq-design` |
| 分布式锁 | 维持 `SET NX PX` + Lua 校验释放 / 续期；正确性由数据库唯一约束或版本号兜底；不用 Redlock、不引入 etcd | `rules/redis.md`、`cache-design/references/patterns.md` |
| 配置中的未验证内容 | 不得出现；无一手依据的移入本文件第四节；`anti-patterns.md`「评审经验」条目不动 | 全部场景包 |
| path rules 覆盖不到 Redis 代码（原 gRPC 5、Redis 8） | `go-redis` 只在 `module/<模块>/cache/` 与通用缓存组件中 import，service 不 import；service 的「先更新数据库再删缓存」写进 layering；项目用 golangci-lint 时以 depguard 机械检查；完整分层示例写入 `cache-design` | `CLAUDE.md`（两份）目录表、`rules/go/layering.md`、`go-new-module`（含 `references/depguard.yml`）、`cache-design/references/layered-examples.md` |

## 四、待验证（已移出配置）

2026-10-23 按「配置中不得出现未验证内容」核对后移出。原位置均为 `dot_claude_projects/` 下的场景包，`skills/skills-*/` 中的同名副本同步修改。

1. **MongoDB 单事务修改文档数不超过 1000**。原位置：backend-dev `rules/database/mongodb.md`「事务」节、`db-schema-design/references/mongodb.md`「事务」节。缺少依据：官方 Production Considerations 只给 60 秒时限与 WiredTiger 缓存压力中止，没有文档数上限；该数来自课程。现改为「批处理拆成小批次」并引用缓存压力说明。建议验证：在 8.0 副本集上对不同文档数与文档大小的事务测提交耗时、缓存占用与 `TransactionTooLargeForCache` 出现条件。
2. **分片集群中让同一事务的文档落在同一分片**。原位置：`db-schema-design/references/mongodb.md`「事务」节。缺少依据：课程经验值，未查官方 Sharded Clusters Transactions 原文。建议验证：查 `core/transactions-sharded-clusters` 原文；或在分片集群对单分片与跨分片事务测耗时。
3. **block / mutex profile 常开采样率 block 10000、mutex 100**。原位置：`go-perf-diagnose/references/pprof.md`。缺少依据：`runtime` 文档只说明参数含义，未给推荐值。现只保留「值越大开销越低，按实测调整」。建议验证：在有锁竞争的 benchmark 上对比不同取值的 CPU 开销与采样数。
4. **`GOMEMLIMIT` 取容器限额的 80%～90%**。原位置：`go-perf-diagnose/references/concurrency.md`。缺少依据：教材值；官方 GC 指南建议留 5%～10% 余量（即 90%～95%），已改为引用官方。建议验证：在 `--memory` 限额容器内用有 cgo 或大量非堆内存的负载对比 80% 与 90%～95% 的 OOM 与 GC CPU。
5. **gRPC Trailers-Only 响应中 `SetHeader` 的值在非 Go 客户端能否从 Header 取到**。原位置：`rpc-design/references/grpc-go.md`「早期资料中不准确的说法」。缺少依据：只在 grpc-go 实测，跨语言未测。现删去跨语言说法，保留「同时检查 Header 与 Trailer」。建议验证：用 grpc-java、grpc-python 等客户端调用返回错误且设置了 header 的 grpc-go 服务。
6. **缓存空值约 95 字节 / key**。原位置：`cache-design/references/patterns.md` 穿透一行。缺少依据：参考资料在 Redis 8.2 上的测量，本仓库未复测。建议验证：Redis 8 容器中 `MEMORY USAGE` 测不同 key 长度的空值。
7. **固定 TTL 的 1 万个 key 同秒失效、加偏移后分散到 7 秒**。原位置：`cache-design/references/patterns.md` 雪崩一行。缺少依据：参考资料测量，未复测。现改为定性描述。建议验证：容器内批量写入后按秒统计 `expired_keys`。
8. **`appendfsync always` 比 `everysec` 慢约 33 倍、`no` 与 `everysec` 吞吐几乎相同**。原位置：dev-ops `middleware-ops/references/redis.md`。缺少依据：参考资料单连接压测（Redis 8.2），未复测。现改为引用官方持久化文档的定性说法。建议验证：同一磁盘上 `redis-benchmark` 分别测三种策略，注意单连接与多连接（group commit）差异。
9. **Elasticsearch 堆「约 31GB」与「大堆使用 G1 GC」**。原位置：`middleware-ops/references/elasticsearch.md`。缺少依据：官方 8.19 文档给的是「26GB 多数系统安全，部分可到 30GB」，以日志确认压缩指针；未找到 G1 建议原文。前者已改为官方说法，后者删除。建议验证：查所用版本 `jvm.options` 默认 GC 与官方说明。
10. **文件句柄与 `vm.max_map_count`「常设为 655360」**。原位置：同上。缺少依据：官方只给下限 65535、262144（推荐 1048576）。建议验证：确认是否为团队运维规范；若是，标为「默认值，项目可调整」后再放回。
11. **晚到的 rule 能否让复杂约束自我修正**。现象：Write 新建文件时 rule 在写完后才注入；只测过「首行固定注释」这类可机械检查的约束。缺少依据：连接复用、deadline、重试等需要理解代码的约束是否同样会被重写修正，未测。建议验证：在临时项目让模型新建 `module/x/cache/x_cache.go`，rule 要求 `ContextTimeoutEnabled` 与关闭重试，多次运行统计合规率。
12. **gRPC 客户端用 depguard 限制在 `grpc/` 目录**。缺少依据：只对 go-redis 实测了 depguard；`google.golang.org/grpc` 在 handler（`api/grpc/`）与客户端封装两处都要 import，规则写法未测。建议验证：同样以违规文件实测后，再决定是否写入 `rpc-design`。

## 五、参考记录（无需决定）

**推翻或修正的教材结论**（实测或一手来源）：

- gRPC：服务端 `ctx.Err()` 并非统一 Canceled（服务端有自己的 deadline）；grpc-go 不捕获 panic，进程直接退出；handler `SetHeader` 后返回错误，客户端仍可从 Header 取到；字段改名只对 wire 安全，会破坏 JSON 与生成代码；buf `FILE` 下删字段并写 reserved 仍报错。
- Go：Timer 的 Reset 语义与容器感知 `GOMAXPROCS` 由 `go.mod` 的 go 行决定（1.23 / 1.25 起），不只看工具链；泛型并非零开销（实测与接口调用同速）；`nilness` 不在 `go vet` 默认分析器；errgroup 派生 ctx 在 `Wait` 后取消且不传播 panic；`go` ≥ 1.25 不再需要 automaxprocs；「循环变量每轮独立」是 `go` ≥ 1.22 语义，与 `wg.Go` 无关。
- Redis：`hash-max-listpack-entries` 内置默认 512（128 来自 `redis.conf` 示例）；8.6 起多了 `allkeys-lrm`、`volatile-lrm`；`TxPipelined` 一次往返；「逐条比 pipeline 慢 462 倍」主要是每次新建 `redis-cli` 进程的开销；「一次淘汰 16035 个 key」由一次性压低 `maxmemory` 造成。
- 交叉审查修正：Redis 锁模板续期循环在网络持续失败时不会中止业务，已改为剩余有效期不足 `ttl/2` 时取消 ctx（三种情况复测通过）；`ClusterClient.Scan` 结果不完整且每次不同，集群遍历用 `ForEachMaster`。

**path rules 加载实测**（2026-10-23，Claude Code 2.1.308，`claude -p` 全新会话，以对话记录中的探针标记判断）：Read、Bash 读类命令（`cat`、`grep`、`head`、`sed -n`）、Write 新建文件、Edit 均会加载匹配的 rule，但都在工具执行**之后**注入；Bash 写类命令（heredoc、`sed -i`）不加载；编辑 `service/` 文件不会加载 `rules/redis.md`（FiberHouse 示例把缓存编排放在 `service/`）。PreToolUse / PostToolUse hook 注入的上下文同样随工具结果送达，不比内置机制早。可机械检查的 rule（首行固定注释）在 haiku、sonnet 各 2 次中都是「写完 → 看到 rule → 重写」后合规。社区 issue #23478、#63142 所述「Write 与 Bash 不加载」在该版本已部分过时。depguard 规则用 golangci-lint v2.5.0 实测：`repository/` 中 import go-redis 报错，`cache/` 与测试文件不报错。

**版本约束**：Go 1.25 模块最高 go-redis v9.22.0（v9.23.0 要求 go ≥ 1.26）、x/sync v0.23.x（v0.24.0 要求 go ≥ 1.26）。

**未写入的教材内容**：GMP 调度、GC 三色标记、接口内存布局、Redis 单线程模型、跳表、RESP、MOVED / ASK 等原理或面试知识，对写业务代码收益低；教材 `skills/` 中的面试复习页生成 skill 与后端开发无关。

## 六、本机残留（需要时手动清理）

子代理删除时被权限拒绝或保留的资源：

```sh
docker volume rm grpclab-gomod
docker network rm redislab-net redisrev-net
docker rmi redis:8 redis:7.4 bufbuild/buf:latest
```

2026-10-23 path rules 与分层示例实测：容器 `rcase-redis`（`--rm`，停止即删除）、网络 `rcase-net`，镜像 `golangci/golangci-lint:v2.5.0`：

```sh
docker stop rcase-redis; docker network rm rcase-net
docker rmi golangci/golangci-lint:v2.5.0
```

更早的实测资源（MongoDB / MySQL）：容器 `mgv1`～`mgv3`、`dbverify-tmp`，网络 `mgv-net`。实测代码在会话 scratchpad，随会话清理。
