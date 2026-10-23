# 可观测性（起步阶段）

适用于起步初期、预算极低、访问量小、要求开源免费的平台：一台最便宜的业务主机（2 核 4G 或 4 核 8G）跑业务，出问题时第一时间在 Telegram 收到通知，并能看到报错的堆栈与行号。资源上限与组件取舍先询问用户，本文的组合是建议方案。

下文「实测」指 2026-10-23 在 Docker 中的闲置内存（`docker stats`）与端到端验证；版本以 `assets/observability/` 的 compose 为准。

## 拓扑

| 位置 | 组件 | 实测内存 |
|---|---|---|
| 业务主机 | 业务服务、Beszel agent、Dozzle | agent 约 6MiB，Dozzle 约 10MiB |
| 外部探测机（业务主机以外的另一台小主机） | Uptime Kuma、GlitchTip + Postgres、Telegram 转发、Beszel hub | 合计约 300MiB（compose 启动后） |

外部探测与告警不放在业务主机上：主机宕机时，装在同一台机器上的监控也一起失效，没人收到告警。

部署文件：`assets/observability/compose.monitor.yml`（外部探测机）、`compose.app-host.yml`（业务主机）、`glitchtip-telegram-relay/`（转发服务源码）。

## 组件

| 需求 | 组件 | 通知 | 依据 |
|---|---|---|---|
| 服务存活、HTTP 与证书探测、状态页 | Uptime Kuma | Telegram 原生 | 官方 README |
| 错误聚合、堆栈与行号 | GlitchTip（all-in-one，不用 Valkey） | Slack 兼容 webhook → `glitchtip-telegram-relay` → Telegram | 官方安装文档、源码 `apps/alerts/` |
| 主机与容器的 CPU、内存、磁盘、网络 | Beszel（hub + agent） | Telegram（Shoutrrr URL：`telegram://<token>@telegram?chats=<chat-id>`） | beszel.dev 通知文档 |
| 实时查看容器日志 | Dozzle | — | 官方 README：不支持离线搜索 |

## 不在起步阶段引入

| 组件 | 原因 | 何时再考虑 |
|---|---|---|
| 分布式追踪（Jaeger、Tempo、OpenTelemetry） | 单体或两三个服务时收益很低，占 CPU、网络与存储 | 服务数量增多、跨服务排障成为主要成本 |
| ELK、自建 Sentry | 自建 Sentry 的安装脚本要求至少 14GB 内存（`errors-only` 也要 7GB） | 不考虑；错误追踪用 GlitchTip |
| Prometheus + Grafana | 实测 Grafana 闲置约 309MiB；要写采集、告警规则与看板 | 需要应用层指标（QPS、5xx 比例、延迟分布）时，见 `monitoring.md` |
| Loki | Dozzle 只看实时 | 需要检索历史日志时：采集用 Grafana Alloy（Promtail 已于 2026-03-02 停止维护），并开启 compactor 的 `retention_enabled`（不开则永久保留） |

## 日志

- 服务输出 JSON 到 stdout，由 Docker 日志驱动落盘；不在容器内另写日志文件。
- 日志驱动用 `local`（默认每个容器保留 100MB 并压缩），或 `json-file` 配 `max-size`、`max-file`。`json-file` 默认 `max-size=-1`，不轮转，小硬盘会被写满。
- 在 compose 中按服务设置 `logging`，或在 `/etc/docker/daemon.json` 设默认值；改 daemon 默认值后需重启 Docker，且只对新建的容器生效，已有容器要重建。

```json
{ "log-driver": "local" }
```

## 错误追踪（GlitchTip）

- 应用接入 sentry-go（官方提供 `fiber`、`gin`、`grpc`、`zerolog`、`slog` 等集成），DSN 由环境变量注入，为空时不上报；换成 Sentry SaaS 只需改 DSN。
- 使用 zerolog 的应用把 `sentryzerolog` 接成日志输出之一，ERROR 日志即上报，日志字段成为 tags（`error` 字段转为 exception）。FiberHouse 经 `WithLogWriters` 接入，实测 Web 示例（Fiber 内核）的 handler 错误、panic、`exception.Panic` 与字符串 panic 均进入 GlitchTip。
- all-in-one 模式：`SERVER_ROLE=all_in_one`，`VALKEY_URL` 置空后任务队列、缓存与会话走 Postgres。官方推荐 512MB 内存，最低 256MB；实测闲置约 130～170MiB。
- 数据保留：`GLITCHTIP_RETENTION_DAYS`，默认 90 天。
- MCP：`GLITCHTIP_ENABLE_MCP=True` 后端点为 `<GLITCHTIP_DOMAIN>/mcp`，支持 OAuth（客户端动态注册）与 API token；项目 `.mcp.json` 模板中的 `glitchtip` 条目读取 `GLITCHTIP_URL`。实测 6.2.6：开启后 `GLITCHTIP_DOMAIN` 不是 https（`localhost`、`127.0.0.1` 除外，见 MCP SDK `validate_issuer_url`）时启动即退出（`Issuer URL must be HTTPS`）；端点未认证返回 401 并给出 OAuth 元数据。Claude Code 中用 `/mcp` 完成 OAuth 认证（Claude Code 文档）；与 GlitchTip 的实际登录未实测，失败时改用 API token。
- 告警：项目设置中新建 Alert，收件者选「General Slack-compatible webhook」，URL 为 `http://relay:8080/glitchtip/<RELAY_SECRET>`。GlitchTip 发送 webhook 时会拒绝解析到内网地址的 URL，relay 在同一 Docker 网络时必须设 `GLITCHTIP_ALLOW_PRIVATE_IPS=True`。
- 实测：同一时间窗内的多个新 issue 合并成一条 Telegram 消息，含标题、链接、项目与主机名。
- 定位能力（sentry-go v0.50.0 实测）：panic 的堆栈含 panic 所在行；`errors.New`、`fmt.Errorf` 产生的 error 不带堆栈，只能定位到上报处，靠 `%w` 逐层附加的上下文判断出处。

## 外部探测（Uptime Kuma）

- 探测业务的健康检查端点与关键接口，通知渠道选 Telegram。
- 管理界面（3001）只绑定 127.0.0.1，经 SSH 隧道或带认证的反向代理访问。

## 主机与容器（Beszel）

- hub 在外部探测机，agent 在业务主机：agent 只读挂载 `docker.sock`，`KEY` 填在 hub 中添加主机时给出的公钥；agent 监听端口只对 hub 所在主机开放。连接步骤以 beszel.dev 的 Getting Started 为准。
- 告警至少覆盖：磁盘使用率、内存使用率、主机离线；阈值写明依据。

## Go 服务的容器参数

- `GOMEMLIMIT` 与 `mem_limit` 一起显式设置，取限额的 90%～95%（Go GC 指南建议给运行时之外的内存留 5%～10%）。实测：`--memory=512m` 而不设 `GOMEMLIMIT` 时，运行时的内存上限仍是无限；`GOMEMLIMIT=460MiB` 与写成字节数都生效。
- `go.mod` 的 `go` ≥ 1.25 时，`GOMAXPROCS` 按容器 CPU 限额自动设置（实测 `--cpus=1.5` 得到 2），不要再设 `GOMAXPROCS` 环境变量（会关闭自动更新）。
- `docker stop` / `docker compose down` 先发 `SIGTERM`，等 `stop_grace_period`（默认 10s）后发 `SIGKILL`；该值要大于应用优雅关闭的超时。
