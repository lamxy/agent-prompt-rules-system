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

（待处理）
