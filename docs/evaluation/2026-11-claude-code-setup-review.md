# claude-code-setup 推荐汇总（阶段 3 补充调研）

创建：2026-11-05　状态：汇总完成，决策表待用户确认　关联：`docs/plans/2026-10-20-scenario-config-evaluation-plan.md` 3.3「补充调研」

用官方插件 `claude-code-setup`（skill `claude-automation-recommender`）在阶段 3 专案集的四个场景项目各跑一次，收集它对场景包的推荐，对照**仓库当前**场景包 `dot_claude_projects/.claude-<FLAG>/` 判读。原始提示与报告在专案集 `~/workspace/aitools_test/scenario-eval-final/test_result_history/claude-code-setup/`（不入库）。

## 1. 条件

| 项目 | 内容 |
|---|---|
| 执行 | Claude Code 2.1.318，`claude -p --plugin-dir <本机插件缓存>/claude-code-setup/1.0.0`，`--permission-mode dontAsk`，只放行 Read、Glob、Grep、WebFetch、WebSearch 与单条只读 Bash；不写项目 settings |
| 项目 | `scenario-eval-final/projects/<FLAG>`，均在 `baseline`，执行后 `git status` 均干净 |
| 提示 | 背景只写事实与约束（项目定位、技术栈、部署约束、不推荐中国大陆闭源工具、附官方来源），不列现有配置；每类 2～4 条（skill 默认 1～2 条） |
| 偏离 | backend-dev 提示未写明可用 WebFetch，它误以为不能上网，外部来源全部未核对；其余三个补了这句，各用 WebFetch 7～9 次 |
| 成本 | backend-dev 1.09 美元／2.5 分钟；dev-ops 0.97／3.1；prd-design 0.92／3.5；frontend-dev 1.15／4.0；合计约 4.1 美元 |

## 2. 报告中不成立或已处理的说法

对照每次运行会话开头的 `init` 记录（实际加载的插件、skill、MCP）与本仓库已有结论：

| 报告说法 | 判读 | 依据 |
|---|---|---|
| frontend-dev：`typescript-native-lsp@anthropic-plugin-directory` 可能加载不了 | 不成立 | `init` 的 plugins 含 `typescript-native-lsp`；市场选择见 `settings/README.md` |
| prd-design：`/grill-me` 不在 skill 清单 | 不成立 | `init` 的 skills 含 `mattpocock-skills:grill-me` |
| prd-design：`pm-execution:create-prd` 与 `CLAUDE.md` 8 项冲突 | 已处理 | 基线 P-1：2026-11-03 补测 S1 强制走 `create-prd` 时以 `CLAUDE.md` 8 项为准，未冲突 |
| frontend-dev：GSD hooks 都在 `settings.local.json` | 已过时 | gsd-core 已移出前端默认清单（`8c1da27`），阶段 3 专案仍装着 |
| dev-ops：`Read(.env)` 应 deny | 已有 | 全局 `Read` deny 已于 2026-11-05 扩充 `.env` 系列 |
| backend-dev：ES、Kafka、RabbitMQ、gRPC rules 在 `go.mod` 无对应客户端，建议清理 | 不采纳 | rules 是用户技术规范，面向真实项目而非 FiberHouse 本身 |
| Gitee 镜像、`example_config` 明文密码、`signup.html` 缺 label 等 | 范围外 | FiberHouse 上游或测验素材本身，不属场景包 |

## 3. 有效发现（按主题）

证据均已在仓库当前场景包中核对（2026-11-05）。

### 3.1 agent 未按场景改写（冲突）

agents 挑选自通用模板，内容与场景约定冲突：

- backend-dev `database-optimizer.md`：Supabase、PlanetScale、PgBouncer 共 10 处，主力应为 MySQL、MongoDB
- dev-ops `incident-response-commander.md`（8 处）、`devops-automator.md`（2 处）：Slack、PagerDuty、DataDog、Prometheus，与「起步阶段、告警只发 Telegram」冲突
- prd-design `ux-architect.md:22,29,64`：「Provide CSS design systems」「Own repository topology, contract definitions」，与「不写生产代码」冲突

### 3.2 agent 没有 `tools:` 限制

backend-dev 6 个、dev-ops 5 个、frontend-dev 5 个全部没有 `tools:`；prd-design 的 `ux-architect`、`ux-researcher` 没有（另 4 个有）。报告引官方文档：不写 `tools` 即继承全部工具。审查类（`security-engineer`、`accessibility-auditor`、`api-tester` 等）有写入与 Bash 能力；项目沙箱又关闭时没有其他防线。

### 3.3 MCP 写入没有第二道防线

- backend-dev 启用的 `mongodb` 插件 MCP 有 `drop-database`、`delete-many`、`update-many` 等写入工具；两个场景的 `permissions` 都没有任何 `mcp__` 规则（现有 deny 只拦 Bash）
- MCP Toolbox 的 `execute_sql`（已知，见交接文件「数据库 MCP 可写」）
- GlitchTip MCP 有写入工具 `update_issue`（frontend-dev 报告，WebFetch 摘要）
- 未验证：MongoDB MCP 的只读启动参数（报告称有 `--readOnly`／`MDB_MCP_READ_ONLY`）

### 3.4 `CLAUDE.md` 软规则可改为机械检查

| 场景 | 规则 | 建议的机制 |
|---|---|---|
| 全部 | 「改文件一律用 Edit/Write」（B-4） | PreToolUse 拦 Bash 写文件；B-4 阶段 3 已解决，不需要 |
| dev-ops | 执行 docker 前显示 context 与项目名；`compose config` 不带 `--environment`、要 `--no-interpolate` | PreToolUse：注入 `docker context show`，违规 `deny` |
| dev-ops | 固定 tag、不用 `latest` | PostToolUse：编辑 compose 后 `config --quiet --no-interpolate` 并查 `:latest` |
| frontend-dev | 不硬编码颜色、间距 | PostToolUse：编辑 html/css 后查十六进制颜色与 `px`（排除 token 文件） |
| backend-dev | 改完 Go 至少 build、vet | Stop：有 `.go` 变更时跑 `go build ./...`、`go vet ./...` |
| prd-design | PRD 必含 8 项 | PostToolUse：写 `docs/prd/*.md` 后查章节标题 |

### 3.5 冗余或不适用

- dev-ops 启用 `terraform` 插件，`settings.json` 5 处、`CLAUDE.md` 4 处提 terraform；场景只用 Docker／Compose
- frontend-dev `permissions.ask` 只有 `docker compose down` 系列，与前端无关
- frontend-dev 同时启用 playwright 与 chrome-devtools-mcp，`CLAUDE.md` 未指定以哪套为主
- backend-dev `.mcp.json` 的 glitchtip url 为 `${GLITCHTIP_URL}/mcp`，未设变量时报 INVALID_CONFIG；dev-ops 已用 `${GLITCHTIP_URL:-http://localhost:18000}/mcp`

### 3.6 新能力候选

对应交接文件「四个场景的自定义 skill（待开始）」：

| 场景 | 候选 | 类型 | 备注 |
|---|---|---|---|
| backend-dev | `api-contract`：改契约、重生 swagger、查破坏性变更 | skill | 依赖项目用 swag |
| backend-dev | `go-layering-reviewer`：只读审查分层与依赖方向 | agent | 与 depguard（B-9 方案 C）部分重叠 |
| dev-ops | `compose-release`：差异 → 固定 tag 与回滚点 → 确认 → 核对 build id | skill | 可能与 gstack `land-and-deploy`、`canary` 重叠，未核对 |
| dev-ops | `incident-triage`：只读取证清单（docker、GlitchTip、Uptime Kuma 等） | skill | 补强 `incident-response-commander` |
| dev-ops | `gha-change` 或 actionlint hook：最小 `permissions`、actions 钉 SHA | skill／hook | GitHub 安全指引已核对 |
| dev-ops | `deploy-config-reviewer`：只读审查 compose 与 workflow | agent | — |
| prd-design | `handoff`：前后端交接文档模板 | skill | — |
| prd-design | `prd-reviewer`、`dev-handoff-reviewer`：完整性、可追溯性、开发视角 | agent | 与 `pm-execution:red-team-prd` 部分重叠 |
| prd-design | 保护 `inputs/` 原始需求（`deny Edit/Write`） | permissions | — |
| frontend-dev | `api-client`：请求五种状态、`X-Request-ID` | skill | — |
| frontend-dev | `verify-ui`：三宽度、控制台、键盘、label／alt | skill | 与 chrome-devtools `a11y-debugging` 部分重叠 |
| frontend-dev | `api-contract-reviewer`：只读审查前端对契约的使用 | agent | 与 `api-tester` 部分重叠 |
| frontend-dev | 契约文件 `api/openapi.yaml` 改动走 `ask` | permissions | — |
| frontend-dev | GlitchTip 浏览器 SDK 约定（`@sentry/browser`、`autoSessionTracking: false`） | skill 或 `CLAUDE.md` | WebFetch 摘要 |
| dev-ops | `gopls-lsp` | plugin | `init` 证实 dev-ops 未加载；DevOps 改 Go 代码少，收益低 |
| 全局 | GitHub MCP 开 `actions` toolset 并 `--read-only` | 全局插件设定 | 属本机配置 |

### 3.7 报告列为不建议的（与本仓库方向一致，记录备查）

Docker MCP（绕过 `Bash(docker …)` 的 ask）、Sentry MCP（已有 GlitchTip）、Slack／PagerDuty／Telegram MCP、K8s 相关、Prometheus 系 MCP（起步阶段不引入）、再加通用 PM／UX／前端 agent（已饱和，加重 skill 清单预算）、每次编辑跑 `golangci-lint` 或 `go test -race`（太慢）、Prism mock server（暂不需要）、第三方 GlitchTip MCP。

## 4. 决策表（待用户确认）

优先级按「安全 > 冲突修正 > 机械检查 > 新能力」。写入前按「配置不含未验证内容」实测或核对一手来源。

| # | 项目 | 建议 | 写入前需要的验证 |
|---|---|---|---|
| 1 | MCP 写入加第二道防线（3.3）：backend-dev `deny` mongodb 写入工具，`execute_sql` 改 `ask` | 采纳 | 临时项目实测 `mcp__plugin_mongodb_mongodb__<工具>` 的 deny 生效；核对工具名清单；MongoDB MCP 只读参数读原文 |
| 2 | 改写冲突 agent（3.1）：`database-optimizer`、`incident-response-commander`、`devops-automator`、`ux-architect` | 采纳 | 无需实测；改写后对照场景 `CLAUDE.md` |
| 3 | 审查类 agent 加 `tools:`（3.2） | 采纳，只限审查类；实现类保留全部工具 | 读官方 sub-agents 文档确认 `tools`／`disallowedTools` 语义 |
| 4 | dev-ops 移除 terraform（插件、ask、`CLAUDE.md`） | 采纳；若计划用 Terraform 开主机则保留并写明用途 | 无 |
| 5 | backend-dev glitchtip url 加默认值，与 dev-ops 一致 | 采纳 | 无 |
| 6 | frontend-dev：删去 docker ask；`CLAUDE.md` 指定 Playwright 为主、Chrome DevTools 做性能 | 采纳 | 无 |
| 7 | 机械检查 hook（3.4） | 只做 1 个试点：dev-ops compose `:latest`／`--no-interpolate`；Bash 写文件拦截不做（B-4 阶段 3 已解决，0/7，`docs/evaluation/2026-10-final.md` 第 79 行已决定不加 hook） | 临时项目实测误拦率；其余视试点结果 |
| 8 | 新 skill／agent／permissions 候选（3.6） | 暂缓，并入「四个场景的自定义 skill」，3.4 真实项目试用中出现需求再做 | — |
| 9 | 全局 GitHub MCP `actions` toolset | 暂缓（本机配置，需用户指示） | 读插件设定方式 |
| 10 | dev-ops 加 `gopls-lsp` | 不采纳（收益低、增加常驻） | — |

## 5. 对 claude-code-setup 本身的评价

- 有价值的部分主要来自**读现有配置找冲突**（3.1～3.3、3.5），不是新推荐；代码信号少的 PRD、前端项目同样有产出
- 有 3 条事实错误（第 2 节），都是没看实际加载状态、凭文件推断；结论需对照会话 `init` 或实测
- 每次约 1 美元、3 分钟；适合改动场景包后做一次「一致性体检」，不适合常驻启用
