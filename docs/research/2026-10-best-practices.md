# 阶段 2 调研：现状汇总与最佳实践

## 1. 四场景现状汇总（2026-11-03，Claude Code 2.1.316）

来源：各场景 `claude --debug` 会话的 `skill_listing` 与 debug log；自定义 agent 数取基线 T1 表；`.mcp.json` 与 `settings.json` 取测验项目实际文件。插件自带的 MCP 不在下表。

| 场景 | Skill 数 | 清单字符（去 description 前 → 后，预算 30000） | 只列名称 | 自定义 agent | `.mcp.json` |
|---|---|---|---|---|---|
| prd-design | 154 | 39312 → 29.6k，**超预算** | 37 | 7 | 无 |
| frontend-dev | 147 | 27.5k | 0 | 47 | 无 |
| backend-dev | 114 | 32978 → 28.8k，**超预算** | 13 | 13 | mysql、postgres、glitchtip、codegraph |
| dev-ops | 72 | 18.2k | 0 | 12 | glitchtip |

四个场景共有 62 个相同 skill（全局插件、个人 skill 与内置）。

### 各场景占用最大的来源（去 description 后的字符数）

| 场景 | 主要来源 |
|---|---|
| prd-design | pm-skills 5 个插件共 73 项、7.8k（其中 36 项只列名称）；document-skills 3.0k；mattpocock-skills 2.5k |
| frontend-dev | gsd-core 77 项（与内置等合计 13.7k）；sentry 2.9k；modern-web-guidance 1.9k |
| backend-dev | mongodb 4.4k；redis-development 4.0k；mattpocock-skills 11 项（9 项只列名称） |
| dev-ops | semgrep 1.3k；sonatype-guide 0.7k；gstack 4 项 |
| 全局（四场景都有） | superpowers 2.8k；chrome-devtools-mcp 2.1k |

### 功能可能重叠（按名称与 description 归类，未读正文，未验证）

| 功能 | 同时存在的项 | 场景 |
|---|---|---|
| 代码审查 | 内置 `code-review`、`open-code-review`、`pr-review-toolkit`、`mattpocock-skills:code-review`、`gsd-code-review` | 按各场景启用情况 |
| 调试 | `superpowers:systematic-debugging`、`mattpocock-skills:diagnosing-bugs`、`gsd-debug` | backend-dev、prd-design、frontend-dev |
| TDD | `superpowers:test-driven-development`、`mattpocock-skills:tdd` | backend-dev、prd-design |
| 规格流程 | `opsx:*` 6 项与 `openspec-*` 6 项 | backend-dev |
| 浏览器 | `playwright`、`chrome-devtools-mcp` | frontend-dev |

### 从数字可得的判断

- frontend-dev 距预算约 2.5k 字符，按已定方向移除 sentry 后约有 5.4k 余量；新增插件前要先算预算。
- backend-dev 超出约 3k 字符，且被去掉 description 的主要是 mattpocock-skills；自写 skill 均保留。
- prd-design 超出约 9.3k 字符，被去掉的主要是 pm-skills 的 skill 版本；S3 显示有 command 指向时不妨碍使用。

## 2. 官方来源核对（2026-11-03 取得；大型文档按关键字定位阅读，未通读）

| 问题 | 结论 | 来源 |
|---|---|---|
| 预算控制 | `skillOverrides` 含 `name-only` 都不影响插件 skill（"Plugin skills are not affected by `skillOverrides`."）；`skillListingBudgetFraction` 默认 0.01，可放项目设置；插件只有整包开关 | `code.claude.com/docs/en/skills.md`、`settings-reference.md` |
| skill 规则被跳过 | 每次都必须成立的放 hook；需判断的指引写成适用整个任务；重点放最前，有顺序的流程写步骤与 checklist；没有「先询问用户」的专门写法 | `skills.md`、平台 skill 编写最佳实践 |
| Bash 改文件 | 必须每次成立的放 hook 或 deny，`CLAUDE.md` 是指引；PreToolUse 可查命令文字但不是安全边界，脚本自行写文件拦不到 | `best-practices.md`、`hooks-guide.md`、`permissions.md` |
| 范围外改动 | 官方范例："Don't add features, tests, files, docs or refactors that weren't asked for."，有用的想法留到最后提出；属非确定性指令 | 平台 Sonnet 5.5 提示工程页 |
| Playwright 输出目录 | `--output-dir`、`PLAYWRIGHT_MCP_OUTPUT_DIR`、`outputDir`，只影响自动命名的文件；默认 `.playwright-mcp` 来自源码，与发布版是否对应未验证 | `microsoft/playwright-mcp` README、`microsoft/playwright` 源码 |
| Compose 与秘密 | 官方未把选项描述为秘密保护。实测 v5.5.0（假值）：验证用 `--quiet`；`--no-interpolate --no-env-resolution` 不展开变数与 env file，但写死的值仍会打印；`--environment` 打印整个 shell 环境 | `docs.docker.com/reference/cli/docker/compose/config.md`、本机实测 |

未验证：插件 command 是否占清单预算、同一插件内 command 与 skill 同名的行为；30000 字符如何由 1% 换算；`skillListingBudgetFraction` 调高后的实际效果。

过程异常：调研子代理实测 `--environment` 时，把一个环境变量的明文值印进了子代理会话记录（值未写入任何报告；用途与有效期未验证）。

## 3. 采纳决策表

用户 2026-11-03 确认：全部按「决定」一栏的建议执行；「建议采纳」「已定」项已实施，阶段 3 验证。

| # | 问题 | 建议 | 决定 | 理由与成本 |
|---|---|---|---|---|
| 1 | D-1 | dev-ops `CLAUDE.md` 常驻一行「规划规格、节点数、内存上限前先询问可用资源上限」，`middleware-ops` 把该条移到开头 | 建议采纳 | 官方：贯穿任务的指引写成常驻；不用 hook，询问不是可机械判断的规则 |
| 2 | B-4 | 四场景 `CLAUDE.md` 各加一行「改代码与配置一律用 Edit/Write」 | 已定，维持 | hook 拦不全，先观察阶段 3 |
| 3 | P-2 | prd-design、backend-dev 项目模板设 `skillListingBudgetFraction: 0.015`，阶段 3 核对警告消失 | 建议采纳 | 约 45000 字符（按 1M 窗口推算），常驻多约 2.3k、0.8k tokens；`name-only` 对插件无效 |
| 4 | F-3 / P-2 | 不移除 pm-skills、mattpocock-skills | 建议不移除 | S2、S3 已自然触发 |
| 5 | F-3 | gsd-core 去留：阶段 3 补测一个规划型任务后再定 | 建议暂缓 | F 系列偏实现型，证据不足；占 77 项 skill、40 个 agent |
| 6 | F-3 | playwright、chrome-devtools 两者都留 | 建议不改 | F 系列用 playwright、P4 用 chrome-devtools；后者为用户刻意全局保留 |
| 7 | F-3 | frontend-dev 移除 sentry | 已定，维持 | 省约 2.9k 字符 |
| 8 | F-4 | frontend-dev `CLAUDE.md` 加「不做未要求的改动；删除元素、改变业务行为前先确认；有用的想法放到最后提出」 | 建议采纳 | 改写自官方范例，非确定性 |
| 9 | F-1、F-2 | 说明把 `.playwright-mcp/` 加进 `.gitignore`，不设 `--output-dir` | 已定，维持 | 改目录只影响自动命名文件，且默认值与发布版的对应未验证 |
| 10 | D-2 | `middleware-ops` 写明：验证用 `docker compose config --quiet`；看结构用 `--no-interpolate --no-env-resolution`；不用 `--environment` | 建议采纳 | 有实测依据，本次调研也发生同类外泄 |
| 11 | P-1 | 不加「章节以本文件为准」 | 建议不采纳 | S1 未冲突；阶段 3 再观察 |

不在本轮：B-1、B-2、B-6、D-3、P-3 未调研。

范围更正（2026-11-03）：本轮只查了官方与上游原文，大厂、社区与场景对标未做，不代表阶段 2 完成；用户已选方案 B 补做，结果追加第二轮决策表。

## 4. 第二轮调研（方案 B，2026-11-03）

候选、K8s 梳理与社区来源见 `docs/research/2026-11-plan-b-candidates.md`。本节只记结论与决策。

### 4.1 关键核对结果

| 问题 | 结论 | 证据 |
|---|---|---|
| B-4 成因 | **已验证**：本机四个测验项目的会话记录共有 19 个 `auto_mode` 附件，全部 `bashFirst: true`、`bashFirstSteer: relaxed`（2.1.312、2.1.314）。说明 auto 模式确实引导用 Bash | 本机会话记录统计；[anthropics/claude-code#87971](https://github.com/anthropics/claude-code/issues/87971) |
| `CLAUDE.md` 明写的效果 | 单人小样本（Opus、auto、每组 15 次）：Bash 写入 12/15 → 2/15，规则载入 5/15 → 15/15。其环境是否同为 relaxed 未知，未在本仓库复现 | #87971 留言（2026-10-13） |
| deny 规则范围 | 涵盖内建工具、可识别的 Bash 文件命令与重定向目标；不涵盖 `grep -r` 与 Python、Node 脚本自行开档。B4 的「只挡内建工具」比官方窄，以官方为准 | `code.claude.com/docs/en/permissions` |
| Compose 数据风险 | `down -v` 删除具名卷；只重启用 `restart` 或不带 `-v` 的 `down`。配置模板放行 `docker compose down *`、`docker-compose *` 且无对应 deny | Docker 官方 `docker-compose-patterns`；#63644；`settings/settings.user.json` |
| 插件与项目规则 | Redis 官方 skill 用 `{entity}:{id}:{attribute}`、`{user:1001}:profile`，并在 clustering 提到事务；项目规则是五段式、tag 只包标识段、不用 `MULTI/EXEC`。**写法不同**，实际是否干扰未测 | `redis/agent-skills`；`rules/redis.md` |
| B-1 索引顺序 | PlanetScale：等值在前，再范围或排序；多个等值列之间才优先高基数，且查询模式通常比选择性重要。支持基线的修改建议 | `planetscale/database-skills` `references/composite-indexes.md` |
| K8s | 本轮新增的 B11、B12 无命中；其余候选只有个别文件提及，未采纳任何依赖 K8s 的 skill | 克隆后关键字扫描 |

### 4.2 第二轮决策表

用户 2026-11-03 确认：全部按「决定」一栏的建议执行；全局模板与本机不改，阶段 3 证实后再考虑。「建议采纳」项已实施（未提交），效果待阶段 3 验证。第 23、24 条因 `AGENTS.md`「未验证内容不进配置」，只记入 `docs/plans/2026-10-22-learning-distill-questions.md`，不写进场景包 README。

| # | 对应 | 建议 | 决定 | 理由与成本 |
|---|---|---|---|---|
| 12 | 新发现 | backend-dev、frontend-dev、fullstack-dev、dev-ops 模板把 `docker compose down`、`docker-compose down`（含 `-f` 等写法）列为 `ask`；写入前先实测匹配 | 建议采纳 | 防数据丢失。多一次确认。不覆盖全局放行；全局模板与本机是否改由用户另定 |
| 13 | 新发现 | dev-ops、backend-dev `CLAUDE.md` 加一条：删除类 docker 命令先说明会失去什么并确认；重启用 `restart` 或不带 `-v` 的 `down` | 建议采纳 | Docker 官方 skill 原文；ask 只管是否弹窗，这条管说明内容 |
| 14 | B-4 | 维持 `CLAUDE.md` 一行，不加 hook，不用 `CLAUDE_CODE_THRIFTY_SONIC`；阶段 3 统计 Bash 写入次数与 `bashFirstSteer` | 建议维持 | 该变量未见官方文档且有失效回报；仍绕过时再按 C4 思路加窄范围 hook |
| 15 | (b) | `settings/README.md` 记录 deny 不涵盖脚本自行写档 | 建议采纳 | 官方原文，避免误判安全边界 |
| 16 | B-1 | MySQL 规则改为：有等值条件时按 ESR，低选择性限制只针对单独建索引或作为多个等值列之首 | 建议采纳 | 有 B2 实例与 PlanetScale 依据；免去每次写 ADR |
| 17 | B-2 | `fiberhouse.md` 说明框架缓存组件的落点，`cache/` 限制只针对直接 Redis 客户端；写前核对 FiberHouse 源码 | 建议采纳 | 消除规则与框架惯例的歧义 |
| 18 | 新发现 | backend-dev `CLAUDE.md` 加一条：项目规则与 `redis-development`、`mongodb` 插件冲突时以项目为准 | 建议采纳 | 成本一行；效果阶段 3 观察 |
| 19 | 新发现 | dev-ops `CLAUDE.md` 加：事故排查先取证并说明假设，不先重启或清理；部署后用实际请求核对版本 | 建议采纳 | Matthews Wong 原文与 #41357、#63644 事故；属个人经验，非确定性 |
| 20 | P-3 | prd-design 产出物补交接文档路径 `docs/prd/<功能名>-handoff.md` | 建议采纳 | 成本一行 |
| 21 | 场景对标 | prd-design「写 PRD 之前」加：做原型前写明要验证的假设 | 建议采纳 | C11 README 的验证流程；不安装 C11 |
| 22 | 新增能力 | 数据库迁移的影子库试跑、up/down schema 比对、行数比对 | 建议暂缓 | 单一作者且基于 PostgreSQL，MySQL 未实测；记入 `docs/plans/`，真实项目需要时实测后再做 |
| 23 | 新增能力 | Node.js：`mcollina/skills` 不进默认配置，在 README 列为可选来源 | 建议暂缓 | backend-dev 是 Go 参考实现且清单仍吃紧；个人仓库，内容未实测；Claude 插件安装方式未验证 |
| 24 | 新增能力 | `getsentry/skills` 的 `gha-security-review` | 建议暂缓 | 有价值，但现行配置未确定用 GitHub Actions；项目需要时再启用 |
| 25 | 场景对标 | 不安装 C7、C12、C13、B7、B8、B15、C10、C1、C8 | 建议不采纳 | 预算吃紧且功能已覆盖或不适配：Go 错误规则已有；前端问题是 skill 未被调用，加 skill 无益；`web-design-guidelines` 每次抓取远端规则；`web-perf` 与 chrome-devtools-mcp 重叠；起步阶段不用 Prometheus 栈；`mock-engine` 依赖未随 skill 提供的模板；Writ 过重 |
| 26 | 自写 skill | 本轮不写新 skill，阶段 3 证明有缺口再写 | 建议不写 | PRD、API 约定已在 `CLAUDE.md`；未发现现有规则无法承载的缺口 |
| 27 | (a)、(d) | 不加「先询问」或范围外改动的 hook，也不加跨模型审查 hook | 建议不采纳 | 属判断题；可靠性都是作者自述。D-1、F-4 第一轮已处理，阶段 3 观察 |
| 28 | 方法 | 阶段 3 用 `/skill-doctor` 看未使用 skill；借鉴 `mcollina/skills` 的有无 skill 对比 | 建议采纳 | 只增加验证步骤。`/skill-doctor` 可用性实施时确认 |
| 29 | B-6 | 暂不改 | 建议暂缓 | 阶段 3 仍出现再加说明 |

不处理：D-3 是测验条件，不是配置问题。

### 4.3 未验证与未做

- 第 12 条已实测匹配（2.1.316，`claude -p`，规则经 `--settings` 传入，每条命令 1 次，结果见 `settings/README.md`）；项目层 settings 来源、互动模式是否弹确认、与真实全局设置合并后的效果未测，阶段 3 验证。
- 第 17 条依据 FiberHouse 源码（`2133a88`，v1.2.0 之后未改缓存组件），未实际运行；第 18 条的实际效果未测。
- 社区未读原文：`builtbyzac` 返回 404，Chaayush Malik 的 Medium 被 Cloudflare 拦截，B3 未取得正文；这些内容未作为决策依据。
- Reddit、Hacker News、dev-ops 社区仓库、Go 迁移工具：已于第 5 节补做或移除范围。
- 只读 README 或部分正文：B6、B7、B8、C7、C10、C11、C13 只读到决策所需段落，未通读。

### 4.4 过程异常

1. 首次统计 `bashFirst` 全为 0 是错的：目录名以 `-` 开头被 grep 当成选项。改用 `./` 前缀后重跑，以 4.1 为准。
2. 仓库内容改用浅克隆读取，未全程用 GitHub MCP：原因是要跨文件扫描，且 code search 的 OR 查询不可靠。
3. 文章用 curl 取得 HTML 后抽取正文，以避开 WebFetch 的摘要。

## 5. 第三轮补做（2026-11-03）

逐条来源与实测记录：`docs/research/2026-11-plan-b-reports/`（`reddit-hn.md`、`devops-repos.md`、`go-migrations.md`，由子代理产出，主会话抽查了关键项）。

**范围**：用户决定移除 Reddit（未登录全部被拦，0 篇原文）。

### 5.1 关键结果

| 主题 | 结论 | 依据 |
|---|---|---|
| MySQL migration 半途失败 | goose 版本仍记为上一版、已执行的 DDL 留下；此时 `down` 回滚上一个成功版本（实测删掉 `orders`，退出码 0）。golang-migrate 标 dirty，拒绝 up、down，要手动 `force` | MySQL 8.0.46、goose v3.29.0、golang-migrate v4.20.1 实测（小规模、无并发） |
| 比对方法 | schema、行数都相同时数据仍可能丢失（删列后由 down 加回），要加 `CHECKSUM TABLE`；`table_rows` 是估算值，不可用 | 同上 |
| 现有规则的问题 | 「合并为一条 `ALTER`」把加列与加索引合并时会重建整张表；`references/mysql.md` 暗示改类型可用 `INSTANT`，实测不支持 | 同上 |
| dev-ops agent | `incident-response-commander` 等 3 个 agent 含 K8s 内容，范本用 `kubectl rollout undo`，与「不用 K8s」「先取证」不一致 | 仓库文件 |
| 备份还原 | 现有配置只有 MongoDB 备份与 Redis 持久化，监控栈的具名卷没有备份说明，也没有还原演练 | 仓库文件；做法来自 `John6810/Ratatoskr`（0 星，未实测） |
| Hacker News | 第二个来源证实 auto 模式的 Bash 引导；有人称 `CLAUDE.md` 遵守度低（与 #87971 的 12/15 → 2/15 相左，无数字）；实践者常用访谈式「先问」，无量测 | HN 49373083 等，个人经验 |
| 框架对比 | 模型一个月的漂移大于任何 skill 包相对基线的优势（用 Codex、单种子，作者有立场）；不能解读为框架无效 | orcabot 基准 |

### 5.2 第三轮决策表（2026-11-03 用户确认按建议，已实施）

| # | 对应 | 建议 | 决定 | 理由与成本 |
|---|---|---|---|---|
| 30 | 修订第 22 条 | `rules/database/mysql.md` 加 4 条：DDL 与 DML 分文件、一个文件一条 DDL；可 `INSTANT` 的加列单独一条（改第 47 行）；线上 `ALTER` 写明 `ALGORITHM`；半途失败先查实际状态，不直接 down | 采纳 | 有实测；防止误删表 |
| 31 | 修订第 22 条 | `db-schema-design` 加验证步骤：种子数据试跑，比对 schema、`COUNT(*)`、`CHECKSUM TABLE`。不新建 skill | 采纳 | MySQL 实测可行；只适用 MySQL，要写明 |
| 32 | 新发现 | 更正 `references/mysql.md`：改类型不能用 `INSTANT` | 采纳 | 实测 |
| 33 | 第 22 条余项 | 接近线上规模的脱敏影子库维持暂缓 | 暂缓 | 本次无依据 |
| 34 | 工具选型 | 不指定迁移工具 | 不指定 | FiberHouse 没有内置；Atlas 未实测，授权说法未验证 |
| 35 | 新发现 | dev-ops 3 个 agent 去掉 K8s 内容，事故范本改为 Compose 并先取证（agents/ 与场景包两份） | 采纳 | 现有内容与已定方向冲突 |
| 36 | 新增能力 | `middleware-ops` 加 `references/backup-restore.md`：逐卷分类、备份离机、隔离环境还原、记录耗时、备份失败告警。先实测再写。第 26 条的「不写新 skill」不受影响，这是现有 skill 的参考文件 | 采纳（备份失败告警未实测，移入疑问清单第 16 条） | 真实缺口；需一次还原实测 |
| 37 | 方法 | 阶段 3 以 Bash 写入次数为 B-4 主要指标，并记录工具调用失败与 LSP 使用；对比时每次同跑基线 | 采纳 | 只增加验证步骤 |
| 38 | (a)、(d) | Stop hook 不当硬边界；访谈式「先问」、测试目录只读挂载、不给 agent 生产凭据、找反证、审查与实现隔离，均暂不写入 | 暂缓 | 没有本仓库的失败证据或量测；生产凭据若要做应放 settings 或 hook，另案评估 |
| 39 | 候选 | 3 个指定仓库与 3 个新搜到的仓库都不安装 | 不采纳 | 能力不对应或质量不足（如 `ops-engineering-skills` 296 个 skill 只有 2 个提交且有错字） |

### 5.3 未做

- `builtbyzac` 原文无法取得（原网址、作者页、API、archive.org 都没有内容）。
- `ericrisco/rsc-harness` 的 monitoring（443 星）因数量上限未读。
- MongoDB、MySQL、Node.js、可观测性在 Hacker News 没查到实践者内容；Redis 未单独查。
- Atlas、PostgreSQL 的实测，MongoDB 迁移，FiberHouse 接入迁移工具的写法。部分官方页面只经摘要，详见各报告。
- 备份还原：Postgres 逻辑备份、冷备份卷、隔离还原已实测（`2026-11-plan-b-reports/compose-probe/`）；Uptime Kuma 卷的还原、备份失败告警（Kuma Push）、离机传输与加密未实测。
- `ops-engineering-skills` 另外 277 个 skill 未读全文，分类靠规则。

### 5.4 过程异常

- 子代理因账号额度上限中断两个任务，恢复后续做。
- Hacker News 子代理请求 51 次（目标约 40 次），并在 scratchpad 多写了原始数据与脚本，删除被权限拒绝。
- docker 网络 `mig-probe-net` 的删除被权限拒绝，残留，由用户手动清理；0 个容器连接。
