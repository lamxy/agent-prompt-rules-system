# 场景配置评估、优化与验证：待办计划

创建：2026-10-20　状态：阶段 1、2 完成（阶段 2 范围按方案 B）；阶段 3 行为验证完成（2026-11-04），3.2 静态验证、3.4 真实项目试用、3.5 判定未做　关联：`docs/handoff/HANDOFF.md`「待办」

## 2026-10-27 审计结论（与下文冲突时以此为准）

- 阶段 1 只测四项：常驻上下文、安全边界、场景约定是否生效、不越界；任务缩减为每场景 3 个 ★ 任务 + 1 个反向任务，共 16 个。范围、推迟项与理由见 `docs/evaluation/2026-10-baseline.md` 第 1 节。
- 由用户在本机正常的 Claude Code 中以交互模式手动执行，不设 `CLAUDE_CONFIG_DIR`、不用 `claude -p`；环境与真实使用一致（装支持包、场景插件、启用项目 MCP），对本机的影响由指南逐项提醒。步骤见 `docs/evaluation/manual-test-guide.md`，素材在 `docs/evaluation/fixtures/`。
- 每个任务基线、优化后各最多跑 2 次。
- 阶段 2 只针对阶段 1 发现的问题调研，不做 2.2 的全面调研。
- 阶段 3 以同一指南重跑 16 个任务对比；盲评、Codex 对比、`skill-creator`、`claude plugin eval`、真实项目试用改为选做，视基线结果再决定。
- 全局层评估（重复冲突）推迟到本机采用新全局设定之后；第三方插件名随指南 1.4 的插件安装一并核对。2026-10-30 更新：本机已于 10-28 对齐，skill/agent/MCP 汇总改为阶段 2 处理（基线 1.3）。
- 2026-11-03 决定（方案 B）：阶段 2 范围 = 阶段 1 问题 + 四场景对标成熟实战配置，找出缺失能力列为「新增能力」，并决定是否写自定义 skill；不做 2.2 其余问题。此前只完成官方来源核对，未查大厂、社区。阶段 3 仍重跑全部 16 个任务。
- 2026-11-03 决定（取代第 37 条「每次都同跑基线」）：16 个任务在新专案集 `scenario-eval-final` 用优化后配置跑，与阶段 1 结果比较；只有 B-4 出现过的 B1、D3、F1 在旧专案集同期再跑对照组。FiberHouse 用阶段 1 同一提交；阶段 3 结束前不装 myplugins、不改全局。步骤见 `docs/evaluation/manual-test-guide.md` 第 12 节。
- 2026-10-30 决定：阶段 2 的修改只落在场景层（`claude_mds/`、`settings/settings.project-*`、场景 skill），不改 `dot_claude/` 与本机；阶段 3 证明有效后再考虑升到全局模板，本机是否套用由用户决定。

## 目标

1. **评估现状**：四个场景与全局层的 settings、`CLAUDE.md`、`.mcp.json`、agents、skills、`open_supports` 支持包是否适配场景、是否符合最佳实践。
2. **吸收外部经验**：查找官方、大厂与社区的最佳实践，形成补充与修改建议，经确认后实施。
3. **验证最终版**：用「个人真实项目试用 + AI 交叉验证」证明优化有效，并沉淀为可重复执行的方法。

## 约束（沿用 `docs/handoff/HANDOFF.md`）

- 只改本仓库；本机 `~/.claude/`、`~/.codex/` 只读，除非用户明确指示
- 测试在临时目录或 scratchpad 进行；真实项目试用由用户决定项目与时机
- 外部资料遵守 `dot_claude/CLAUDE.md` 的「范围与完成」「资讯来源」「网路」：关键结论读原文、未验证内容标明，网路慢不缩小范围
- 涉及取舍的建议先列方案，用户确认后再改

---

## 阶段 1：现状评估

### 1.1 评估对象

| 层级 | 对象 | 位置 |
|------|------|------|
| 全局 | 15 个全局插件（superpowers、mattpocock-skills、context7、github、remember 等） | `settings/settings.user.json` |
| 全局 | 全局支持包 gstack、task-master | `dot_claude_projects/.claude/` |
| 全局 | 个人差异规则（Claude / Codex 两份） | `dot_claude/CLAUDE.md`、`scripts/multi_client_support/templates/` |
| 场景 ×4 | settings（插件、permissions） | `settings/settings.project-<FLAG>.json`、`settings.local-<FLAG>.json` |
| 场景 ×4 | 场景约定 | `claude_mds/CLAUDE-<FLAG>.md` |
| 场景 ×2 | MCP（后端数据库、GlitchTip） | `dot_mcp_jsons/` |
| 场景 ×4 | agents（5～6 个/场景） | `agents/agents-<FLAG>/` |
| 场景 ×4 | 自定义 skill（尚未编写） | `skills/skills-<FLAG>/` |
| 场景 ×4 | 支持包清单（pm-skills、codegraph、OpenSpec/gsd-core 可选） | `dot_claude_projects/.claude-<FLAG>/` |
| 组合 | fullstack-dev（只有 settings） | `settings/settings.project-fullstack-dev.json` |

### 1.2 评估维度

| 维度 | 检查内容 | 方法 |
|------|---------|------|
| 场景覆盖 | 场景的典型任务（见 3.2 标准任务）是否都有对应能力；有无缺口 | 列出每场景 5～8 个典型任务，逐项映射到插件/skill/agent/MCP |
| 重复与冲突 | 同类能力是否多处提供（如 TDD、需求追问、代码审查、记忆）；指令是否互相矛盾 | 汇总所有 skill 名称与描述，按功能归类；`/doctor prompt-audit` |
| 上下文成本 | 常驻上下文（CLAUDE.md、skill 描述、MCP 工具定义、agent 描述）各占多少 | 临时项目安装场景包后用 `/context` 记录；`session-report` 看实际会话 |
| 安全边界 | permissions 的 deny/ask 是否生效；MCP 是否真的只读；凭据是否只走 `${VAR}` | 临时项目实测被拦截的命令；检查 MCP 配置与只读账号说明 |
| 触发准确性 | skill/agent 的 description 能否在该触发时触发、不该触发时不触发 | `skill-creator` 的触发评估；阶段 3 的行为记录 |
| 可维护性 | 场景包与各维度目录分开维护后的漂移；第三方市场插件名是否有效 | 对比两处差异并记录（不自动同步）；首次安装时 `/plugin` 核对 |
| 跨客户端 | Codex 侧能复用的部分是否可用 | `codex.sh -d`、`.agents/skills` 安装后在 Codex 中列出 |

### 1.3 待办

- [x] 为四个场景写「典型任务清单」，作为评估与验证的共同基准（与 3.2 共用）——审计后 16 个任务，见基线第 2 节
- [x] 在临时项目安装每个场景包（`install-claude-project.sh -f <FLAG> -t <项目>`，含支持包与场景插件，见手动测验指南第 1 节），记录 `/context` 各项占用——T1，基线 3.2；16 个任务结果见 3.3～3.5（2026-10-30 完成）
- [ ] 汇总全局 + 场景启用后的全部 skill / agent / MCP 工具，按功能归类，标出重复与冲突——2026-10-30 改为阶段 2 处理（基线 1.3）；阶段 1 已发现第三方插件 skill 未被调用，可能与 skill 清单预算有关（F-3、P-2）
- [x] 实测 permissions：后端 deny 的数据库破坏性命令、DevOps ask 的 terraform/docker 变更命令——B8（deny 拦截）、D2（`docker compose up` 在 auto 模式下仍弹确认）；terraform 未涉及
- [x] 核对第三方市场插件名（`document-skills@anthropic-agent-skills`、pm-skills）——随指南 1.4 安装成功（基线 3.1）
- [ ] ~~对比场景包与各维度目录的差异，记录是否需要人工同步~~——取消（2026-10-20 已决定两者独立维护，基线 1.3）
- [ ] 评估 fullstack-dev 是否需要场景包——推迟（基线 1.3）

**产出**：`docs/evaluation/2026-10-baseline.md`——每个评估对象按维度打分（适配 / 部分适配 / 不适配），附问题清单与证据。

---

## 阶段 2：外部最佳实践调研

### 2.1 来源与可信度

| 级别 | 来源 | 用途 |
|------|------|------|
| A 官方 | Anthropic Claude Code 文档与最佳实践、`claude-plugins-official` 市场、Agent Skills 规范、OpenAI Codex 文档 | 机制与推荐做法的准据 |
| B 大厂 | 大厂公开的工程博客、内部 Agent 配置开源仓库 | 规模化实践、治理与安全做法 |
| C 社区 | 高星配置仓库、awesome 列表、外部作者的实战分享（`docs/recommend_repos/` 是本仓库的推荐清单，不作调研来源） | 场景化技巧、可直接复用的 skill/agent |

每条建议都要回到原文核对；只有二手转述的标「未验证」，不进入采纳决策。

### 2.2 调研问题

| 范围 | 问题 |
|------|------|
| 全局 | 全局插件数量与上下文成本的平衡点；工作流框架（superpowers、gstack、mattpocock-skills）共存的推荐做法；记忆类工具选型（配合用户另行测试的记忆工具） |
| PRD 与原型 | PRD 模板、需求追问、原型产出（线框、可交互原型）的成熟 skill；与设计工具的接入方式 |
| 前端 | UI 实现与视觉验证（浏览器自动化、截图对比）、可访问性、性能；组件库与设计系统约定写法 |
| 后端 | API 契约优先、数据库迁移与只读查询的安全做法；Go / Node.js 项目约定；MongoDB/Redis/MySQL/PostgreSQL MCP 的成熟方案 |
| DevOps | CI/CD 与基础设施变更的人工确认机制；Docker Compose / Terraform / 可观测性 MCP；事故响应流程 |
| 横向 | permissions 与 sandbox 配置范式；hooks 的典型用途与反模式；CLAUDE.md 的长度与写法；agent 定义的粒度 |
| Codex | Codex 侧的 AGENTS.md 分层、skills、配置的推荐做法，哪些可与 Claude 共用 |

### 2.3 待办

- [x] 补测 2～3 个应触发 skill 的任务（例如附录 A 的 P3、F5），其中一个用 P2 素材强制 `/create-prd`，与 `CLAUDE.md` 8 项盲比（P-1）；先用 `claude --debug` 确认 skill 清单是否超出预算（P-2）
- [ ] （部分：官方来源已核对问题 D-1、B-4、P-2、F-1、F-4、D-2；大厂、社区与场景对标已做，三轮决策见 `docs/research/2026-10-best-practices.md` 第 3～5 节，未做项见 5.3；2.2 其余问题已由方案 B 取消）按 2.2 的问题逐一调研，每条记录：来源、日期、原文核对结论、适用场景、建议、预估收益与成本
- [ ] （部分：问题映射已做；「新增能力」未做）对照阶段 1 的问题清单，形成「建议 → 对应问题」映射；没有对应问题的建议单独列为「新增能力」
- [ ] （部分：第一轮已确认，第二轮待方案 B 调研后）输出采纳决策表（采纳 / 暂缓 / 不采纳 + 理由），**提交用户确认**
- [ ] （部分：第一轮已实施）按确认结果实施，按主题拆分提交，每次提交前跑 `run-all.sh`

**产出**：`docs/research/2026-10-best-practices.md`（调研记录与采纳决策表）；实施提交。

---

## 阶段 3：最终版验证方法论

### 3.1 原则

1. **先定标准再验证**：每个场景先写标准任务与通过条件，避免事后挑结果
2. **对照实验**：同一任务分别在「基线配置」与「优化后配置」下执行，比较差异
3. **真实为主、AI 为辅**：真实项目的体感与数据决定去留；AI 交叉验证用来扩大覆盖面、发现盲点
4. **评审与执行分离**：执行任务的模型或会话不评自己的结果
5. **可重复**：任务、提示词、评分标准、结果都存档，下次优化后可再跑一遍

### 3.2 第一层：安装与静态验证（自动化）

- [x] （2026-11-05，`scripts/tests/test-scenario-bundles.sh`）扩展 `scripts/tests/`：四个场景包安装到临时项目后，检查文件齐全、JSON 合法、清单项目级条目带 `{PROJECT_DIR}`（部分已有）
- [x] （2026-11-05，`scripts/smoke/claude-config-smoke.sh`；`claude plugin` 只列本机插件、与场景无关，未做）新增 smoke：在临时项目执行 `claude mcp list`、`claude plugin` 相关只读命令，确认配置被识别（需本机 Claude Code，不改用户配置）
- [x] （2026-11-05，`scripts/smoke/permissions-smoke.sh`，按用户选择抽样 36 条而非逐条）permissions 实测脚本：对 deny/ask 规则逐条构造命令，确认被拦截或要求确认

### 3.3 第二层：行为验证（AI 交叉验证）

**第二轮决策追加的观察项（2026-11-03）**：每次运行统计 Bash 写入次数与会话记录的 `bashFirstSteer`（B-4，仍绕过再加窄范围 hook）；用 `/skill-doctor` 查未使用 skill（可用性届时确认）；对改动过的 skill 做有无 skill 对比；观察项目规则与 `redis-development`、`mongodb` 插件是否冲突。

**第三轮决策追加（2026-11-03，第 37 条）**：B-4 以每次运行的 Bash 写入次数为主要指标；同时记录工具调用失败次数与 LSP 使用次数；做优化前后对比时，每次都同跑一次基线配置，不拿过去的基线结果比（2026-11-03 缩为只对 B1、D3、F1 同跑，见开头审计结论）。

**阶段 3 执行中发现，阶段 3 跑完后再处理（用户 2026-11-03 确认时机）**：`db-schema-design` 第 4 节的 MySQL 迁移验证步骤（阶段 2 第三轮加入）在两个任务中出问题。细节见专案集 `notes.md` 的 B1、B2 记录。

- B1：没有限定验证用一次性容器，Claude 用 `docker exec eval-mysql` 和容器内 root 在共享测验库建了临时库，绕过只读账号，结束后临时库还留在库里（用户已手动删除）。
- B2：步骤要求比对 `mysqldump --no-data`，与全局 deny `Bash(*mysqldump*)` 冲突。Claude 探测工具的复合命令 `which mysql mysqldump docker; docker ps` 整条被拒，之后放弃验证。阶段 1 的 skill 没有这一步，`docker run --rm mysql:8.0` 验证可以正常执行。
- 用户原则：创建与只读命令放行，清理与删除需要确认或禁止；不应阻止 Claude 发起验证。
- [x] （2026-11-04，`f67e416`）修改 `db-schema-design`（`skills/skills-backend-dev/` 与 `dot_claude_projects/.claude-backend-dev/` 两处）：验证改用 `docker run --rm mysql:8.0` 一次性容器，不用共享库；schema 比对改用 `SHOW CREATE TABLE` 或 `information_schema`，不依赖 `mysqldump`
- [x] （2026-11-04，B2 r2 通过，另修 B-10 `9cb4a30`；B1 未重跑）改完后重跑 B2（r2），确认验证能完成且不留残留；B1 是否重跑视改动范围决定
- [x] （2026-11-04 D-4 已修）D2：compose 项目名与本机 `~/workspace/local-infra/fiberhouse-dev`（`name: fiberhouse-dev`）同名，挂上并改动了该环境的三个卷。评估 `middleware-ops` 是否加「启动前按项目名查已有卷与停止的容器」；测验后在 local-infra 目录 `docker compose up -d` 重建容器，并检查其 Redis 是否混入测验写入（2026-11-04：重建与 Redis 检查已完成，无需清理；`middleware-ops` 修改即 D-4，2026-11-04 已做）
- [x] （2026-11-04 用户选前缀 ask：删除 deny，改为 `ask` `Bash(mysqldump *)`，模板、镜像、本机三处同步；已知 `$(…)`、反引号可绕过，见 `settings/README.md`）全局 deny `Bash(*mysqldump*)` 是否改为 ask，由用户决定（改 `~/.claude/` 需用户明确指示；skill 改完后不再依赖它，非必需）

**标准任务**：每个场景 3～5 个，覆盖该场景核心能力，例如：

| 场景 | 标准任务示例 |
|------|------------|
| PRD 与原型 | 根据一段口述需求产出 PRD；把 PRD 拆成用户故事与验收标准；产出一页线框原型 |
| 前端 | 按设计说明实现一个组件并做视觉验证；修复一个可访问性问题；对接一个后端 API |
| 后端 | 设计并实现一个带数据库的 CRUD API；写一个数据库迁移；排查一个慢查询 |
| DevOps | 为项目写 CI 流水线；为服务写 Docker Compose 部署；根据告警做一次事故分析 |

**执行**：按 `docs/evaluation/manual-test-guide.md` 在专案集中以交互模式手动执行，基线与优化后各最多 2 次（第 1 次结果明确时不跑第 2 次）。

**采集**：

| 指标 | 来源 |
|------|------|
| 是否触发预期的 skill / agent / MCP，有无误触发 | 会话记录、`session-report` |
| 权限拦截是否符合预期 | 会话记录 |
| token、耗时、工具调用次数 | `session-report` |
| 产出质量 | 下方交叉评审 |
| 人工干预次数 | 真实项目试用日志 |

**交叉评审手段**：

- 盲评：另开会话或子代理，用不同模型按评分表（正确性、完整性、符合场景约定、安全）评审，不告诉评审者是哪套配置的结果
- 代码类产出：`/code-review`、`open-code-review`、`/security-review` 各跑一遍，比较发现的问题数量与严重度
- 跨客户端：同一任务在 Codex 下用对应配置执行，对比结果，检验 `codex.sh` 与 `.agents/skills` 的复用效果
- 自定义 skill：用 `skill-creator` 的评估功能检查触发准确性与产出质量
- [ ] 插件级评估 `claude plugin eval`（用户 2026-11-05 同意纳入，先小型试跑，暂不执行）：
  - 试跑对象：myconfig，把 2026-11-05 会话实测第 11 条的 5 句触发评估写成案例（2 句应触发、3 句不应触发），确认 skill 能否作为目标、无插件对照组（Δ）有没有用；有用再决定是否推广到其他 skill 与场景包
  - 前提（官方 `code.claude.com/docs/en/plugin-evals.md`、`plugins/create.md`，2026-11-05 读原文）：目标须是含 `.claude-plugin/plugin.json` 的插件目录或 skills-directory plugin，普通 skill 不行，需在 scratchpad 建临时插件外壳（`plugin.json` + `skills/myconfig/` 复制），不改仓库；每次运行是隔离的 `claude -p`（临时 HOME，不载入个人设定、其他 skill 与插件），环境变量只传 `EVAL_*`，所以 catalog 可能找不到仓库（不影响触发判定）；Bash 等非只读工具要 `--allow-tools` 授权，skill 的 `allowed-tools` 不能放宽
  - 案例写法：每案例 `prompt.md`（frontmatter `max_turns`、`allowed_tools`、`tags`）+ `graders/*.md`；应触发用 `type: tool_used`、`tool: Skill`、`input_match: '"skill"\s*:\s*"(?:[\w-]+:)?myconfig"'`；不应触发加 `min: 0`、`max: 0`、`arm: both`
  - 执行：`claude plugin eval . --runs 1 --no-publish --trust-plugin --max-cost-usd 5`；**默认会把 HTML 报告发布到 claude.ai，必须加 `--no-publish`**；默认每案例 3 次再加对照组，试跑用 `--runs 1`（5 案例 × 2 组 = 10 次运行）
  - 未验证：场景包（`.claude/` 目录，非插件）能否作为目标

### 3.4 第三层：真实项目试用

- [ ] 每个场景选一个用户的真实项目（由用户指定），试用期约 2 周
- [ ] 试用日志字段（2026-11-05 起由 `mysession-eval` 记录，手填模板 `pilot-log-template.md` 不另建，除非设计确认时改变）：日期、任务、用到的 skill/agent/MCP、冲突或误触发、人工干预、满意度（1～5）、备注
- [ ] 每周复盘一次：汇总日志，决定保留、调整或移除的项目，调整后回写仓库
- [ ] 试用结束后与阶段 1 的基线对比，结论写入 `docs/evaluation/2026-10-final.md`
- [x] （2026-11-05 已实作并端到端实测，计划 `docs/plans/2026-11-05-mysession-eval-plan.md`，本机已安装；用户 2026-11-05 决定**要做**；设计已于 2026-11-05 经用户确认，见 `docs/plans/2026-11-05-mysession-eval-design.md`，**以设计文件为准**，下方「初步设计」仅保留作历史；它取代手填日志，所以 3.4 不另建 `pilot-log-template.md`，除非设计确认时改变）全局技能 `mysession-eval`（2026-11-05 由 `mypilot` 改名；`my:session-eval` 不符合 Agent Skills 规范 name 只允许小写字母、数字与连字号，且冒号在 Claude Code 表示插件命名空间）：在真实项目中由用户主动调用，记录与整理试用数据，取代手填日志。初步设计（已由设计文件取代）：
  - 位置与安装：`dot_claude/skills/mysession-eval/`（`SKILL.md` + Python 脚本），本仓库测试后同步到 `~/.claude/skills/`；脚本命令加进 `sandbox.excludedCommands`（同 myplugins，用 `~` 路径）
  - `/mysession-eval`：脚本解析本次会话记录（`~/.claude/projects/<项目>/<会话>.jsonl`）得到客观指标（skill／agent／MCP 调用、权限拒绝、工具错误、token），只输出汇总、不把原文带进上下文；主观数据（满意度 1～5、干预次数、备注）由参数或一次提问取得；每条一行 JSON 写入 `~/.claude/mysession-eval/`（不进项目与本仓库）；排除 `mysession-eval` 自身的调用
  - `/mysession-eval review [场景]`：汇总日志，对照 3.5 判定表给出初判；结论去识别化后写回本仓库
  - 成本估计（除常驻外未实测，参照 myplugins 每次约 2.9k）：常驻 0（设 `disable-model-invocation: true`，已验证见下）；每次记录约 3～4k；每次复盘约 6～12k；一次性开发约 80～150k；2 场景 × 10 会话、复盘 2 次合计约 90k，与事后手工分析（约 40～100k）相近，收益主要是用户时间与数据一致性
  - 已验证（2026-11-05，Claude Code 2.1.318，scratchpad 临时项目，`-p` 与互动模式各一次）：
    - 当前会话 id：Bash 环境变量 `CLAUDE_CODE_SESSION_ID` 与 skill 内 `${CLAUDE_SESSION_ID}` 替换都等于 `~/.claude/projects/<项目>/<id>.jsonl` 的文件名；`--resume` 沿用原 id 与文件，`--fork-session` 换新 id 与新文件（以上为 `-p`；互动模式只核对了环境变量与文件名一致，替换未测）。脚本据此定位会话记录，不用「取最新 jsonl」
    - `disable-model-invocation: true`：该 skill 不出现在会话记录的 `skill_listing` 附件中（对照组未设的 skill 出现），仍可用 `/<名称>` 手动调用
  - 不采用：SessionEnd hook 自动记录（会在非试用项目留痕，用户要求主动调用）

### 3.5 判定与回归

| 判定 | 条件 |
|------|------|
| 通过 | 标准任务的预期能力触发率高且无误触发；评审得分不低于基线；真实项目满意度 ≥ 4 且干预次数下降 |
| 调整 | 能力有效但触发不稳、上下文成本过高或与其他能力冲突 |
| 移除 | 两轮调整后仍无收益，或带来安全风险 |

稳定的结论回写：`docs/handoff/HANDOFF.md`（决策）、`scripts/tests/`（能自动化的检查）、对应 README（用法）。

### 3.6 探索项

- 用 hook 记录 skill / agent 的实际触发情况，作为长期统计（先评估上下文与性能影响）
- 长任务：ralph-loop、`/loop` 在真实项目中的适用边界
- 记忆工具：配合用户另行测试的全局记忆工具，比较与 `remember` 的效果
- MCP 安全：数据库 MCP 只读账号的实测流程，能否脚本化
- 评估自动化：把 3.3 的标准任务与评分表做成可重复执行的脚本或 skill

---

## 执行顺序与依赖

```text
1.3 典型任务清单 ──┬──> 1.3 其余评估 ──> 阶段 1 产出 ──┐
                   │                                    ├──> 2.3 采纳决策（用户确认）──> 实施
                   │        阶段 2 调研（可并行）───────┘                                  │
                   └──────────────> 3.3 标准任务 ─────────────────────────────────────────> 3.2～3.4 验证
```

建议从「典型任务清单」开始：它同时服务评估、调研问题聚焦与最终验证。

## 需要用户决定

- [ ] 各场景用于试用的真实项目——阶段 3 后、真实试用前由用户决定；建议先 1～2 个常用场景
- [ ] 试用期长度——同上；建议以会话次数计（例如每场景 10 个真实会话）
- [x] ~~交叉评审使用的模型组合与预算上限——选做，只用于 P-1 模板盲比与阶段 2 决策表复核（Codex 一轮）~~（用户 2026-11-05 决定不做）
- [ ] 阶段 2 的采纳决策——实施前用决策表逐条确认
- [x] （2026-11-04 已决定方案 C，见 `docs/research/2026-11-layering-strictness.md`）**分层规则是否必须严格**（用户 2026-11-03 提出，待讨论；阶段 3 结束后、处理 3.3「阶段 3 执行中发现」那批修改时提醒用户）。起因：B4 中 Claude 指出 FiberHouse 的 `example-module` 中 `service` 直接 import `apivo`，违反 `rules/go/layering.md` 的「service 不可 import apivo」。要讨论的问题：
  - 严格分层（service 只用 dto/entity，api 层做全部 VO 转换）与宽松分层（允许 service 直接复用请求/响应结构，减少样板转换）各自的收益和代价
  - 技术大厂与社区的实践：Go 社区（如 Go 项目布局讨论、Clean Architecture / 六边形架构在 Go 中的落地、Uber/Google 等公开风格指南）、Java 系（阿里巴巴 Java 开发手册的分层领域模型规约等）对「DTO/VO 是否跨层」的规定与反思；需读原文，结论标明哪些是规范、哪些是个人经验
  - 规则应写成硬约束（depguard 强制）、默认建议（允许写 ADR 例外），还是按项目规模分级
  - 框架代码本身（FiberHouse 示例模块）不符合规则时，规则跟框架走还是框架跟规则走；新模块与存量模块是否区别对待
  - 结论影响 `rules/go/layering.md`、`go-new-module` 的 `references/depguard.yml`，以及 B1/B4 观察点的判定口径
