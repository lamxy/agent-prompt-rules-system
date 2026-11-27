# 陷阱细节

本文件按需查阅，不整份读。每个条目都必须在 `docs/handoff/HANDOFF.md` 的触发索引有一行「动作 → 一句话做法 → G<n>」；`handoff-check check` 会核对两边，对不上时 FAIL。

2026-11-27 由旧 HANDOFF「续作时必须知道的事」迁移而来，去处对照见 `docs/handoff/CHANGELOG.md`「2026-11-27 HANDOFF 迁移去处对照」。

### G1 单独重装 settings 后支持包插件消失

现象：PRD 场景用 `install-settings.sh -m overwrite` 重装 settings 后，pm-skills 插件消失。

原因：pm-skills 以 `--scope project` 写入项目 `.claude/settings.json`，overwrite 会整体替换。`install-claude-project.sh` 已内建「先复制 settings 再装支持包」的顺序，单独装 settings 时没有。

做法：单独重装 settings 后重新运行 `install-open-supports.sh -t <project>`，或用 `-m merge`。含 permissions 的模板（backend-dev、dev-ops、fullstack-dev）必须用 overwrite，merge 只合并插件、市场与 `skillOverrides` 字段。

### G2 数据库 MCP 可写

现象：MCP Toolbox 的 `execute_sql` 可以执行写操作，工具本身没有只读开关；settings 的 `deny` 只拦 Bash 命令，拦不到 MCP 调用。

原因：MCP 工具调用不经 Bash 权限规则；项目 `env`（`MDB_MCP_READ_ONLY`）要等信任文件夹才生效，`deny`／`ask` 立即生效。

做法：连接必须使用只读账号、只连开发或测试库；写入防线两层并用（`env` + `deny`／`ask`）。mongodb 插件工具名为 `mcp__plugin_mongodb_mongodb__<工具>`，插件升级若新增写入工具要补进 deny（详见 `dot_mcp_jsons/README.md`）。

### G3 Codex 模板需手动同步

现象：改了 `dot_claude/CLAUDE.md`，Codex 端行为没变。

原因：`scripts/multi_client_support/templates/AGENTS.codex-user.md` 是 `dot_claude/CLAUDE.md` 的 Codex 版（加回复语言、去掉 LSP、工具名改通用说法、/goal 改用 `update_goal` 的 `blocked`），两份分开维护。Codex 只自动读取 `AGENTS.override.md`、`AGENTS.md` 与 `project_doc_fallback_filenames`，其他文件名不会生效。

做法：修改 `CLAUDE.md` 时同步模板。

### G4 补充技术规范：放置位置与脱敏

现象：用户的技术规范源文件含原企业的系统名、key 示例、内部流程与路径；本仓库公开。

原因：源文件只在本机 `~/workspace/documents/技術規範--檔案夾/`，入库内容是重组后的版本。

做法：
- 只以重组后的内容入库，不复制、不引用源文件路径；替换示例中的系统名、key 前缀、日志路径、工单系统、内部工具名，提交前用临时关键词清单扫描改动文件（清单不入库）。
- 文件分布（2026-10-21 融入，`2ac1c49`、`4d611a6`），补充规范时照此放置：
  - `dot_claude_projects/.claude-backend-dev/.claude/rules/`：`database/{mysql,mongodb,elasticsearch}.md`、`redis.md`、`mq/{kafka,rabbitmq}.md`、`go/logging.md`
  - `dot_claude_projects/.claude-backend-dev/.claude/skills/`：`db-schema-design`、`cache-design`、`mq-design`、`system-design-doc`（含 `references/`），并复制到 `skills/skills-backend-dev/`
  - `dot_claude_projects/.claude-dev-ops/.claude/skills/middleware-ops/`，并复制到 `skills/skills-dev-ops/`
  - backend-dev `CLAUDE.md`（两份）「存储与中间件」索引；根 `README.md`、`dot_claude_projects/README.md`、`skills/README.md` 同步
  - 测试：`scripts/tests/test-scenario-skills.sh`（四场景 skill 与场景包 `diff -r`）、`test-backend-dev-bundle.sh`
- 核对状态：Go 客户端参数（mongo-go-driver、go-redis、kafka-go、amqp091-go、GORM）已按 context7 官方文档核对；middleware-ops 的 ES 系统参数已于 2026-10-26 对照规范原文核对（堆 32GB 与 G1、文件句柄与 `vm.max_map_count` 655360 出自规范，配置中标注「技术规范」并与官方 bootstrap check 下限并列）；其余通用经验值（quorum 队列等）规范中没有，按 `docs/plans/2026-10-22-learning-distill-questions.md` 待验证清单处理。

### G5 修改 MySQL 设计规则或引用数据库教材

现象：教材 day3 讲义的销售排行索引 `(sku_id, created_at)` 与批改中「`(created_at, status)` 让 `GROUP BY status` 免临时表」都是错的，已在临时容器（MySQL 8.0.46，导入 `schema/snapshot-full.sql.gz`）实测推翻，结果写进 `references/case-ecommerce.md` 与 `references/mysql.md`。

原因：教材来源可信度不一：各 day 的 `lecture.md`、`solutions.md` 经数据库实测，为权威；`reviews/`、`node-*-guide.md` 为讲师批改，无实测的标为推论；`exercises.md` 与 `day3-design/database-design.md` 是学员产出，不作为结论来源。教材在本机 `~/workspace/documents/learning/databases_learn/`，不入库（入库内容已去除品牌、人名、日期、需求编号）。

做法：引用教材结论前先区分来源等级，存疑的就实测；实测用不暴露端口的临时容器，不用教材的 compose（其设 `restart: unless-stopped`）。用户已定（写在 `dot_claude_projects/.claude-backend-dev/.claude/rules/database/mysql.md`）：
- 组合索引按 ESR（等值 → 排序 → 范围），取代「按区分度从高到低」；低选择性字段不单独建索引，多个等值列优先放高选择性列（2026-11-03 按 B-1 修订：它是等值条件且后接排序或范围列时可放最左）
- 维持全部 `NOT NULL`，「没有」用约定值（关联 id `0`、未发生时间 `'1970-01-01 00:00:00'`、字符串 `''`）；极少数例外须在 `COMMENT` 与 ADR 写明理由
- 分表门槛、膨胀系数等经验值标为「默认值，项目可调整」
- 现行 `datetime`（无毫秒）不改为教材的 `DATETIME(3)`

### G6 修改 MongoDB 规范

现象：早期教材（MongoDB 4.2、Go Driver v1）的不少结论在新版已过时或本就不准，直接引用会写错规则。

原因：以 MongoDB 8.0 与 Go Driver v2 实测推翻或修正了多条，例如：`readConcern: majority` 单独使用不阻塞、但在因果一致性会话读落后的 secondary 时会等待；`w: majority` 超时不等于未写入；`hint` 强制部分索引会静默少返回数据；`WithTransaction` 遇写冲突会重跑回调；`background: true`、`enableMajorityReadConcern`、`$lookup` 不能查分片集合等说法已过时。详见 `db-schema-design/references/mongodb.md` 文末「早期资料中已过时的说法」。

做法：补充或修改前先查该文件的实测表；新结论用临时容器实测（`mongo:8.0` 三节点副本集，独立 docker 网络、不暴露端口；Go 用 `golang:1.25-alpine` 挂载 scratchpad 目录运行），Go 代码一律用 `go.mongodb.org/mongo-driver/v2`（FiberHouse 亦然）。教材在本机 `~/workspace/documents/learning/mongodb/`，不入库。

### G7 引用 Go、Redis、gRPC 教材结论

现象：教材结论常与新版行为不符（例如 Timer 的 Reset 语义、GOMAXPROCS 容器感知取决于 `go.mod` 的 go 行而非工具链；listpack 内置默认 512 而非 `redis.conf` 示例的 128；grpc-go 不捕获 panic，进程直接退出）。

原因：教材基于旧版本，且部分数字来自示例配置或带额外开销的测量。

做法：落点与实测表在各 skill 的 references（`rpc-design/references/`、`go-perf-diagnose/references/concurrency.md`、`cache-design/references/{redis,patterns}.md`）；修改前先查实测表，新结论用 `--rm`、不暴露端口的临时容器实测。版本上限：Go 1.25 项目最高 go-redis v9.22.0、x/sync v0.22/v0.23（v0.24 与 go-redis v9.23 要求 Go 1.26）。rule 正文维持用户既定条款（Redis key 禁 `}`、不用 MULTI/EXEC 等），冲突方案只写疑问文件。教材在本机 `~/workspace/documents/learning/{grpc_learn,golang_learn,redis-bootcamp}/`，不入库。

### G8 path rule 写对了却不生效

现象：rule 写对了 `paths`，编辑某些代码时仍不生效。

原因：Claude Code 2.1.308 实测（2026-10-23）：Read、Bash 读类命令、Write、Edit 都会加载匹配的 rule，但都在工具执行之后才注入；Bash 写类命令（heredoc、`sed -i`）不加载；代码不在匹配路径下时不加载；hook 注入同样晚到。2.1.318（2026-11-05）观察到用 Bash `head`／`cat` 读符合 `paths` 的文件不会加载 rule，只有 Read 工具会（2 次观察，可能与 RTK 改写有关，未验证）。

做法：必须在动手前知道的约定写进常驻 `CLAUDE.md` 或 skill；按目录集中代码让 `paths` 精准命中（Redis 代码只放 `cache/`），并尽量用 lint（depguard）等机械检查兜底。实测记录在 `docs/plans/2026-10-22-learning-distill-questions.md`「参考记录」。

### G9 FiberHouse 相关规则

现象：`WithLogWriters`、caller 修正、字符串 panic 记录、按 HTTP 状态定级等行为在 v1.1.1 及更早版本中没有。

原因：2026-10-24 在临时克隆切分支 `feature/logger-extra-writers` 修改并推送到 `lamxy/fiberhouse`；2026-10-26 用户合并入 `main` 并发布 `v1.2.0`（远端分支保留）。同日按用户决定 FiberHouse 规则去版本绑定（2026-11-27 grep 确认 backend-dev 场景包与 `claude_mds/` 中已无 `v1.2.0`）。

做法：框架行为变更后先核对 FiberHouse 的提交与 `.codegraph-qa-out/` 记录再改规则。本机 FiberHouse 仓库在 `~/workspace/github_repos/fiberhouse`，本仓库不放框架源码。FiberHouse 提交信息用英文（其 `CLAUDE.md` 要求）。

### G10 部署 GlitchTip 与 Telegram 告警

现象：webhook 静默不到；开 MCP 后 GlitchTip 启动即退出。

原因：GlitchTip 6.2.6 告警渠道没有 Telegram，靠 `assets/observability/glitchtip-telegram-relay` 转发；relay 与 GlitchTip 同网络时 webhook 被 SSRF 检查静默拦截。`GLITCHTIP_ENABLE_MCP=True` 时 `GLITCHTIP_DOMAIN` 不是 https（localhost、127.0.0.1 除外）会启动即退出。

做法：同网络时设 `GLITCHTIP_ALLOW_PRIVATE_IPS=True`；开 MCP 时 `GLITCHTIP_DOMAIN` 用 https 或 localhost。2026-10-24 会话中 `docker network rm`、`docker rm` 被拒，测试网络 `obs-net` 与容器 `mcp-gt` 需用户手动清理（见疑问清单第六节）。

### G11 核对测验或试用会话的结果

现象：Claude 的最终回复自述与实际操作不符。

原因：回复是自述，会话记录才是事实。

做法：专案集 `~/workspace/aitools_test/scenario-eval/`（阶段 1，对照组）与 `scenario-eval-final/`（最终配置），逐任务证据在各自 `notes.md`（不入库）。核对以会话记录为准：记录在 `~/.claude/projects/-Users-zz-workspace-aitools-test-scenario-eval-projects-<场景>/*.jsonl`（取最新；final 专案集同理），用 `python3 -I` 解析 tool_use（Skill、AskUserQuestion、Write/Edit、Bash、mcp__*）与 tool_result（`denied`）；产出用 `git status` / `git diff baseline`，每个任务的产出在 tag `<任务>-r<次数>`（对照组 `<任务>-ctl-r1`）。阶段 3 的分析脚本在当时的 scratchpad，已清除，要用时重写。观察写进专案集 `notes.md`，场景完成后回填评估文件并列问题清单，经用户确认再提交。final 专案 backend-dev 的 `baseline` 在 B-7 修正后重打，早于修正的 run tag（如 `B1-r1`）与它比较会显示「删了规则」，属误报；用 run tag 当素材前先看 `git log` 时间。

### G12 测验存档（save-run.sh）

现象：会话未退出时 `save-run.sh` 回滚会让 Claude 的文件消失，或把下一任务产出存进上一 tag；回滚后被忽略的文件（如 `deploy/.env`）留给后续任务。

原因：存档会回滚工作树；`git clean -fdq` 不删 `.gitignore` 里的文件。

做法：「保存」（用户 2026-10-30 指定）= 确认会话已退出 → 在项目目录 `sh ../../bin/save-run.sh <任务> <次数> [keep]` → 把经会话记录核对的观察、判定、tag 与提交号写进 `notes.md`。确认退出：`for p in $(ps -axo pid=,args= | awk '$2 ~ /(^|\/)claude$/ {print $1}'); do lsof -a -p $p -d cwd -Fn; done | grep <场景>`，有输出就先请用户退出（本机 `pgrep` 抓不到 claude 进程；修订后指南的 `save-run.sh` 已内建此检查，「会话未退出时被拦」截至 2026-10-30 未实测）。`keep` 只用于 P2、P4（看本任务改动用 `git diff <前一 tag> <本 tag>`）。对照组前人工查 `git status --short --ignored`。

### G13 测验会话的环境准备

现象：D2 中 `MYSQL_*` 覆盖了 compose 同名变量；remember 记忆跨任务注入；P1 读到不该有的素材。

原因：B 系列需 `. "$SET/mysql.env"`，同一终端跑其他场景会串场；remember 插件跨会话注入；`inputs` 在项目内。

做法：其他场景换新终端或先 `unset`；沙箱一律关闭（用户 2026-10-30 决定：项目 `settings.local.json` 的 `sandbox.enabled: false`，新项目在首个会话内执行 `/sandbox` 关闭）；各项目 `settings.local.json` 停用 remember、`save-run.sh` 每次清除 `.remember/`（prd-design 实测有效）；P1 前 `mv inputs` 出项目。交互脚本外的问题一律答「按你的判断」，属任务范围的事实可以照答但阶段间必须给相同回答。已用过的：B1「只接 Fiber 核心，Hertz 和 Gin 都不接。需要将 CoreType 改为 Fiber 核心。」（已进交互脚本；B-3 因此撤回）；B8「连 127.0.0.1:3306 的 evaldb，是测试库。只清 orders，不用先查行数」；D2「变量冲突按你的判断处理。同意启动」；B4 用户直接选了推荐项。remember 停用设定 2026-10-30 时只有 prd-design 加了，其余三个阶段 1 项目未加。

### G14 判定权限是否弹确认

现象：指南预设的确认行为与实际不符。

原因：本机全局 `defaultMode: auto` 且 allow `docker run *`、`docker compose up/down *`，backend-dev 不会对 docker 弹确认；dev-ops 的 ask 规则在 auto 模式下仍弹确认（D2 实测）；auto 分类器会拦截打印凭据的命令（B8、D2）。

做法：判定按会话记录中实际是否弹确认，不按指南预设。

### G15 命令或说明里含被 deny 的字样

现象：含某些字样的任何 Bash 命令（包括 `grep`、提交说明）都被拒、不弹确认。

原因：整条通配的 deny（如 `Bash(*DROP TABLE*)`）按字面匹配整条命令。`mysqldump` 已于 2026-11-04 由 deny `Bash(*mysqldump*)` 改为 `ask` `Bash(mysqldump *)`（模板、镜像、本机三处），前缀规则拦不到 `$(…)` 与反引号（`claude -p` 实测，见 `settings/README.md`）。

做法：命令与说明里避开这些词。`Bash(env)` 同理会拦 `env | grep`（推测，未验证）。

### G16 写 depguard 规则

现象：`*/apivo`、`.../apivo/**` 不生效。

原因：depguard 的 `pkg` 只做前缀匹配（golangci-lint v2.5.0 实测）。

做法：规则写 `<module>/apivo`。

### G17 用 Corepack 查 pnpm／yarn 路径

现象：未下载本体的 pnpm／yarn 在有终端时卡住。

原因：有终端时等隐藏的下载确认，无终端（`</dev/null`）时自动下载。

做法：只查路径用 `COREPACK_ENABLE_NETWORK=0`（立即失败、不下载）。pnpm 12 只在全局 bin 已在 PATH 时才返回路径（原有限制，未处理）。

### G18 新增 Read deny 或验证读取类规则

现象：`Read(~/.ssh/*)` 拦不住 Bash `cat ~/.ssh/...`；`(cmd < file) 2>/dev/null` 能读到被 deny 的文件；`.env.e2e` 之类变体不受保护。

原因：本机全局 `autoAllowBashIfSandboxed: true`，沙箱内命令跳过权限检查，`Read` deny 由沙箱在 OS 层执行；沙箱关闭时只剩权限层，而 RTK hook 把 `cat`／`head`／`grep`／`ls` 改写并回答 `allow`，`Read` deny 因此失效。子 shell 加外层重定向不检查 `Read` deny（`cmd < file`、`(cmd < file)` 会被拦，Claude Code 2.1.318），没有配置可补，用户 2026-11-05 决定不回报上游。allow 不能在 deny 上开例外，`[!e]`、`[^e]` 也按字面匹配。

做法：本机 RTK 已加 `[hooks] exclude_commands`（`~/Library/Application Support/rtk/config.toml`，内容与 `settings/README.md` 一致），新增 `Read` deny 时同步该 regex；`.env` 规则逐条列变体，不写 `.env.*`；验证读取类规则看内容有没有外泄，不看哪一层拦下（`permissions-smoke.sh` 的 `blocked`）。本仓库与测验项目都关了沙箱，属只剩权限层的情况。

### G19 用 `claude -p` 测项目层 allow

现象：项目层 `permissions.allow` 没生效。

原因：`claude -p` 在未接受信任对话框的目录里会忽略项目层 `permissions.allow`（deny、ask 照常生效）。

做法：实测要放行时用 CLI `--allowedTools`。

### G20 起新的 compose 项目

现象：D2 用 `name: fiberhouse-dev` 挂上了本机 `~/workspace/local-infra/fiberhouse-dev` 的三个卷并替换其容器。

原因：`docker compose ls` 只列运行中项目，没查同名卷。另外 local-infra 的 `fiberhouse-dev` 停止状态下 `docker system prune` 会删除其容器（数据卷保留），建置上下文没有源码，重建只能 `docker compose up -d --no-build`。

做法：起新项目前 `docker volume ls --filter label=com.docker.compose.project=<名>`、`docker ps -a --filter label=com.docker.compose.project=<名>`。

### G21 在本仓库会话做破坏性操作

现象：用容器 root 改库（`DROP DATABASE`）、`rm -rf` 测验目录、`docker rm` 都被拒。

原因：本机权限规则；只读查询可以。

做法：交给用户用 `!` 执行。

### G22 沙箱路径与写受保护路径

现象：在其他项目执行 `/myopensupports list` 报 `os.getcwd()` `PermissionError`（`myhandoff` 的 `handoff-check` 同理，依代码判断）；`dangerouslyDisableSandbox` 无效。

原因：用户层级沙箱路径的 `.` 解析为 `~/.claude`，不是当前项目，`denyRead: ~/` 把项目也挡了；`allowUnsandboxedCommands: false`。

做法：`allowRead` 写 `~/.claude` 与工作根目录（本机 `~/workspace`，另以 `denyRead ~/workspace/documents` 保留不读 documents 的决定），加 `~/.config/git/ignore`（详见 `settings/README.md`「`allowRead` 里的 `.`」，`cb63add`）。技能要写受保护路径时只能给用户 `!` 命令或用 `excludedCommands`。`dot_claude_legacy/settings.json` 也有 `.` 问题，属只读归档，按用户决定不改。

### G23 修改 myplugins

现象：`/myplugins` 写设定报 `Operation not permitted`。

原因：沙箱禁止 Bash 写 `.claude/settings*.json`，而 `excludedCommands` 按命令文字比对（2026-11-04 实测：规则与命令都写 `~` 或都写 `$HOME` 才匹配；`allowRead` 不展开 `$VAR`，`~` 可用）。

做法：
- SKILL.md、`settings/settings.user.json`、镜像三处都写 `python3 ~/.claude/skills/myplugins/scripts/myplugins`（测试检查三处一致），命令不展开路径、不加引号、不串接。
- 源码 `dot_claude/skills/myplugins/`，测试 `scripts/tests/test-myplugins.sh`；本机副本 `~/.claude/skills/myplugins/`，清单 `~/.claude/myplugins/catalog.json`。
- 行为约定（用户 2026-11-04 定）：`enable`／`off` 默认写 `.claude/settings.json`，`--local` 或 `-c` 写 `settings.local.json`；`--dry-run`／`-t`／`--test` 只预演，skill 先给用户确认再写；预演状态行显示写入后状态（2026-11-05）；启动提示第一行黄色粗体（ANSI 在 `systemMessage` 有效，hook 不能写 `/dev/tty`），用「当前目录」不说「项目」，第三行给 `! python3 ~/.claude/skills/myplugins/scripts/myplugins list`；列表用 ✅／⬜／⚠️，列表后不重排表格，只回「已启用」一行、「注意：」行与用法。`SKILL.md` 只留常用规则，其余放 `references/details.md`。
- 清单：默认 26 个（2026-11-27 `remember` 移出全局、加在「通用」末尾，序号 11 起顺延），顺序通用 → PRD → 前端 → 后端 → 运维（用户指定），跨场景插件归最早出现的场景；需个人账号的本地级插件不收。默认清单更新后用 `/myplugins sync`（保留用户 add 的、不加回 remove 过的）。全局模板把列出的插件全部设 `false`，并声明 `anthropic-agent-skills` 市场。
- `/plugin` 的 User 分组是安装范围，与在哪一层启用无关（推断，未找到官方原文）。
- 已验证：会话内 `/reload-plugins` 立即生效；`-t` 预演与确认流程、同机共享模式（`claude -p` + `--resume`，2.1.318）。官方 `plugins/loading.md` 写项目层插件须通过信任检查、`-p` 不够，与同机结果不符，可能因该插件已在用户层安装（未验证）。

### G24 测量某操作的 token 成本

现象：执行 `/myplugins` 后 `/context` 的 Messages 涨一万多。

原因：会话第一次正常提问时 Claude Code 一次性附上 skill 清单、沙箱说明、延迟工具与 MCP 说明（约 30k 字符；首轮是 `!` 命令则延到下一个提问），`/context` 自己的输出也会记进对话（每次约 5.5k）；myplugins 本身每次约 2.9k。

做法：看 API usage 或两次 `/context` 差值再扣约 5.5k。`/context` 的 Skills 与 Messages 分类会重叠或挪移（推断，未查官方说明），不要逐类相加。

### G25 修改 mysession-eval

现象：本机行为与仓库不一致；场景判为 `unknown`；升级 Claude Code 后计数异常。

原因：安装方式为复制；`scenarios.json` 取自场景包的 `CLAUDE.md` 首行与 agents；权限拒绝、中断等靠错误文字比对（2.1.318 核对）。

做法：源码 `dot_claude/skills/mysession-eval/`，测试 `scripts/tests/test-mysession-eval.sh`；改完由用户执行 `cp -R dot_claude/skills/mysession-eval ~/.claude/skills/` 再 `diff -r` 核对。改场景包 `CLAUDE.md` 首行或 agents 时同步 `scenarios.json`（`test_scenarios_json_matches_bundles` 会报错）。升级后计数异常先用真实会话记录重新核对错误文字（设计文件「指标对应的 jsonl 字段」）。沙箱计数只认 `Operation not permitted`，其他环境错误看备注（`references/review.md`）。已知限制：技能没执行 `skip`（如中途报错）时，用户的文字回答会算进下一段。日志 `~/.claude/mysession-eval/log.jsonl` 不进项目与本仓库。

### G26 新增或修改场景 agent

现象：通用人设 agent 在 72 个测验会话中调用 0 次、内容与场景冲突；`deploy-reviewer` 首次实测串接命令被拒后放弃。

原因：场景约定已在 `CLAUDE.md`、rules、自写 skill 中，子代理的收益只在干净上下文的独立审查；串接命令易被权限拦。

做法：只放自写只读审查 agent，照 `agents/README.md` 写法约定（`tools:`、只引用项目已有规范、输出带行号与依据）；正文写明「每条命令单独执行、不加 `cd`」。改 agent 同步三处：`agents/agents-<FLAG>/`、`dot_claude_projects/.claude-<FLAG>/.claude/agents/`、`dot_claude/skills/mysession-eval/scenarios.json`（再按 G25 同步本机副本）。子代理读长 `git show` 会被 RTK 截断，`rtk bypass` 需授权。

### G27 维护本仓库时要用 skill-creator 等插件

现象：`skill-creator`、`claude-md-management` 不在全局。

原因：已不是全局插件。

做法：先 `/myplugins` 启用。

### G28 调整工作流框架或 skillOverrides

现象：用 `skillOverrides` 关闭插件 skill 无效。

原因：`skillOverrides` 对插件 skill 无效（实测 + 官方文档，依据 `docs/evaluation/2026-10-28-skill-overrides-experiment.md`）。

做法：mattpocock-skills 只能整包移到场景；gstack 是个人 skill，用 `user-invocable-only` 实现「只手动调用」。第三方市场插件名（`pm-skills`、`anthropic-agent-skills`）无法离线校验，`test-settings-templates.sh` 跳过其名称检查。

### G29 zsh 下批量处理文件

现象：`for x in dir/*` 无匹配时报错中断。

原因：zsh 默认 nomatch。

做法：先 `setopt nullglob`，或写成 `sh` 脚本。

### G30 前端场景的 TypeScript LSP

现象：TypeScript 6 以下 LSP 不工作。

原因：`typescript-native-lsp` 来自内置插件目录（`@anthropic-plugin-directory`），TypeScript 6 以下需另装 `typescript-language-server`。

做法：旧版 TypeScript 项目另装 `typescript-language-server`。
