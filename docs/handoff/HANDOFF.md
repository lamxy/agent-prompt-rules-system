---
branch: main
head: 4d611a6
status: active
updated: 2026-10-21
---
# 进度交接

本文件记录仓库当前状态与续作指引，供 Claude Code、Codex 或协作者接手，也用于同一客户端清空会话后的续作。新需求完成后，在文末「变更日志」追加一条。

<!-- section: summary -->
## 摘要

- 进度：仓库转型、四场景配置、安装脚本分工与场景包聚合、Codex 适配改造均已完成并提交，已推送并发布 v2.0.1（Latest）；已制定「场景配置评估、优化与验证」待办计划，尚未开始执行
- 停在：用户交来首批技术规范（本机 `~/workspace/documents/技術規範--檔案夾/`，含企业原规范，**不入库**），已去企业化重组为 backend-dev 的存储与中间件 rules、4 个 skill 和 dev-ops 的 `middleware-ops` skill（`2ac1c49`、`4d611a6`），12 个测试文件全过，已推送到 `origin/main`
- 下一步：RPC 规范等用户下一批规范；或开始评估计划的「典型任务清单」

接手前必读顺序：`AGENTS.md` → 本文件 → `docs/plans/2026-10-20-scenario-config-evaluation-plan.md`（执行计划时）→ 要改动的目录自己的 `README.md` → 根目录 `README.md`（设计原则与转型说明）。

<!-- section: status -->
## 当前状态

基础建设完成，进入「评估 → 调研 → 优化 → 验证」阶段。

| 任务 | 状态 | 说明 |
|---|---|---|
| backend-dev Go 参考实现 | **进行中** | 第一批 `7b7ef74`；存储与中间件规范 `2ac1c49`；RPC 待用户规范 |
| 场景配置评估、优化与验证 | 待开始 | 三个阶段，清单见下方；方法论细节见 `docs/plans/2026-10-20-scenario-config-evaluation-plan.md` |
| 四个场景的自定义 skill | 待开始 | `backend-dev` 已有 `go-new-module`；其余 `skills/skills-<FLAG>/` 目前只有占位；例如 PRD 模板、API 契约、上线检查清单。建议在阶段 2 调研后再写 |
| `dot_claude/commands/analyze-github-repo.md` 转 Codex skill | 待开始 | Codex custom prompts 已于 2026-01 弃用；装到 `~/.agents/skills` |
| 本机采用新全局设定 | 待用户决定 | `sh scripts/install-settings.sh -l user -m overwrite`；`dot_claude/settings.json` 仍是本机设定镜像，未做插件分层调整 |
| 技能与工具包管理平台 MVP 迁入 `src/` | 待开始 | 根目录 `README.md` Roadmap |

### 待办计划：场景配置评估、优化与验证

计划文件：`docs/plans/2026-10-20-scenario-config-evaluation-plan.md`（评估对象表、7 个评估维度、调研来源分级、标准任务示例、判定标准、执行顺序图）。完成一项就在此勾选，并在计划文件同步。

**阶段 1：现状评估**（产出 `docs/evaluation/2026-10-baseline.md`）

- [ ] 为四个场景写「典型任务清单」（每场景 5～8 个），作为评估与验证的共同基准
- [ ] 在临时项目安装每个场景包（`install-claude-project.sh -f <FLAG> -t <tmp> -N`），用 `/context` 记录各项常驻上下文占用
- [ ] 汇总全局 + 场景启用后的全部 skill / agent / MCP 工具，按功能归类，标出重复与冲突（辅以 `/doctor prompt-audit`）
- [ ] 实测 permissions：后端 deny 的数据库破坏性命令、DevOps ask 的 terraform/kubectl/helm 变更命令
- [ ] 核对第三方市场插件名（`document-skills@anthropic-agent-skills`、pm-skills）
- [ ] 对比场景包与各维度目录的差异，记录是否需要人工同步
- [ ] 评估 fullstack-dev 是否需要场景包

**阶段 2：外部最佳实践调研**（产出 `docs/research/2026-10-best-practices.md`）

- [ ] 按来源分级（A 官方 / B 大厂 / C 社区）调研全局、四个场景、横向主题与 Codex 的问题；每条记录来源、日期、原文核对结论、适用场景、收益与成本；二手转述标「未验证」
- [ ] 形成「建议 → 阶段 1 问题」映射，无对应问题的列为「新增能力」
- [ ] 输出采纳决策表（采纳 / 暂缓 / 不采纳 + 理由），**提交用户确认**
- [ ] 按确认结果实施，按主题拆分提交，每次提交前跑 `run-all.sh`

**阶段 3：最终版验证**（产出 `docs/evaluation/2026-10-final.md`）

- [ ] 安装与静态验证：扩展 `scripts/tests/`；临时项目中 `claude mcp list` 等只读 smoke；permissions 实测脚本
- [ ] 行为验证（AI 交叉）：每场景 3～5 个标准任务，在 worktree 或临时副本用 `claude -p` 跑「基线 vs 优化后」各至少 2 次；采集触发情况、拦截、token/耗时（`session-report`）；不同模型盲评、`/code-review`、`open-code-review`、`/security-review`、Codex 同任务对比、`skill-creator` 评估自定义 skill
- [ ] 真实项目试用：每场景一个用户指定的项目，约 2 周；试用日志模板 `docs/evaluation/pilot-log-template.md`；每周复盘并回写
- [ ] 按「通过 / 调整 / 移除」判定，稳定结论回写本文件、`scripts/tests/`、对应 README

<!-- section: done -->
## 已完成内容

**仓库定位**：个人 Agent 配置与工具／技能管理仓库（Claude Code 为主，兼顾 Codex），公开供参考。2026-10-19 从「分层提示词规则系统」转型而来，设计原则与原因见根目录 `README.md`。

**版本**：本地 `main` 与 `origin/main` 同步（2026-10-21 推送至交接提交）；GitHub release v2.0.0（tag 指向 `a0783b3`）、v2.0.1（tag 指向 `6a31aee`，标为 Latest）。GitHub 仓库描述与 topics 已改为个人开发者工具定位。

**四个场景**（FLAG 在所有维度目录中一致；另有 `fullstack-dev` 只存在于 `settings/`）：

| FLAG | 场景 | 范围 |
|---|---|---|
| `prd-design` | PRD 与原型设计 | 需求说明书、PRD、线框图或基础原型 |
| `frontend-dev` | 前端开发 | UI 设计与实现、前端交互、对接后端 API |
| `backend-dev` | 后端开发 | 系统规格、系统／数据库／架构设计、选型；后端功能、API 与数据库开发 |
| `dev-ops` | DevOps | CI/CD、上线、可观测性 |

**已确认的技术栈决策**：后端 Go、Node.js / TypeScript；数据库以 MongoDB、Redis、MySQL 为主，兼容 PostgreSQL；开源自建 Kubernetes、Prometheus / Grafana、Sentry；PRD 以 pm-skills、mattpocock-skills、gstack 等技能为主；**不设主工作流框架**（全局只有 superpowers，OpenSpec、gsd-core 在前后端清单中以注释提供）；全局工具 task-master、mattpocock-skills、gstack；记忆类只保留 `remember`，cognee 暂不启用。

**目录结构**：

```
dot_claude/                 个人用户级配置（约 30 行 CLAUDE.md、commands/、settings.json），繁体中文
dot_claude_legacy/          2026-10-19 前的分层规则系统存档，不被任何安装脚本使用
settings/                   全局 settings.user.json（15 个全局插件）+ 项目级 5 个场景模板 + 本地级 4 个
claude_mds/                 CLAUDE-<FLAG>.md，各约 30 行，只写场景约定
dot_mcp_jsons/              后端 MySQL/PostgreSQL（MCP Toolbox）、DevOps Kubernetes（只读配置）；PRD、前端为空
agents/                     agents-<FLAG>/，各 5～6 个，挑选自 agents-agency-agent-based-dev/
skills/                     skills-<FLAG>/ 尚为占位；skills-open-supports/ 为支持包安装 Skill
dot_claude_projects/
  .claude/                  全局支持包清单（gstack、task-master），install-claude-project.sh -g 安装
  .claude-<FLAG>/           场景包：settings、CLAUDE.md、.mcp.json、agents、支持包清单的完整聚合
open_supports/              10 个支持包；INDEX.md 登记用途、作用域分类、建议场景、全局工具
scripts/
  install-claude-project.sh 复制场景包或全局清单，然后调用 install-open-supports.sh
  install-open-supports.sh  安装支持包：-t 项目级 / -g 全局，-n 单一 / -l 清单
  install-*.sh              单一维度安装（settings、CLAUDE.md、.mcp.json、agents、skills、dot_claude）
  multi_client_support/     codex.sh：把个人差异规则写入 ~/.codex/AGENTS.md 标记区块
  tests/                    10 个测试文件，run-all.sh 一次执行
docs/
  handoff/HANDOFF.md        本文件
  plans/                    待办计划
  recommend_repos/          推荐仓库与中文教程
```

各目录的细节以其 `README.md` 为准：`settings/README.md`（插件分层与理由）、`dot_claude_projects/README.md`（场景包与来源对照）、`open_supports/INDEX.md`、`scripts/README.md`、`scripts/multi_client_support/README.md`、`dot_mcp_jsons/README.md`。

<!-- section: run -->
## 本机执行

前置条件：POSIX `sh`；`python3`（JSON 校验与合并，3.9 即可）；真实安装支持包时视支持包需要 `node`/`npm`、`git`、`claude`、`codex` CLI。

无构建步骤。所有脚本从仓库根目录执行，参数以各脚本 `-h` 为准。

验证指令：

```bash
sh scripts/tests/run-all.sh
```

预演安装（不写入）：

```bash
sh scripts/install-claude-project.sh -f backend-dev -t /path/to/project -d
sh scripts/install-claude-project.sh -g -d
sh scripts/multi_client_support/codex.sh -d
```

最后一次完整验证结果：2026-10-21，12 个测试文件全部通过（含 `sh -n` 语法检查）。

<!-- section: gotchas -->
## 续作时必须知道的事

### 用户约束（必须遵守）

| 约束 | 说明 |
|---|---|
| 不改动本机配置 | 只修改本仓库。`~/.claude/`、`~/.codex/` 等本机文件只读，除非用户明确下指令 |
| 改动前先确认 | 涉及取舍的事项先列方案与理由，用户确认后再实现 |
| 提交 | 用户确认后才提交；推送与发布 release 需用户明确指示（2026-10-20 已按指示推送并发布 v2.0.0、v2.0.1） |
| 测试 | 一律在临时目录或 scratchpad 执行，不对真实配置测试 |
| 不使用中国大陆的工具 | 例如飞书、钉钉、阿里云、腾讯云 |
| 语言 | 与用户沟通用繁体中文；`dot_claude/` 与 Codex 模板为繁体中文；其他仓库文档为简体中文 |

### 场景包与各维度目录分开维护

现象：改了 `settings/`、`claude_mds/` 等维度目录，场景包 `dot_claude_projects/.claude-<FLAG>/` 里的同名配置没变，反之亦然。

原因：2026-10-20 用户决定场景包是「初次从各维度复制、之后独立维护」的完整聚合，不做同步脚本或一致性测试。

正确做法：需要两边一致时手动复制，并在提交说明里写明；不要新增自动同步。

### 安装顺序与 settings 覆盖

现象：PRD 场景用 `install-settings.sh -m overwrite` 重装 settings 后，pm-skills 插件消失。

原因：pm-skills 以 `--scope project` 写入项目 `.claude/settings.json`，overwrite 会整体替换。`install-claude-project.sh` 已内建「先复制 settings 再装支持包」的顺序，单独装 settings 时没有。

正确做法：单独重装 settings 后重新运行 `install-open-supports.sh -t <project>`，或用 `-m merge`。含 permissions 的模板（backend-dev、dev-ops、fullstack-dev）必须用 overwrite，merge 只合并插件字段。

### 数据库 MCP 可写

MCP Toolbox 的 `execute_sql` 可以执行写操作，工具本身没有只读开关；settings 的 `deny` 只拦 Bash 命令，拦不到 MCP 调用。连接必须使用只读账号、只连开发或测试库。K8s MCP 由只读配置文件保证。

### Codex 模板需手动同步

`scripts/multi_client_support/templates/AGENTS.codex-user.md` 是 `dot_claude/CLAUDE.md` 的 Codex 版（加回复语言、去掉 LSP、工具名改通用说法），两份分开维护。修改 `CLAUDE.md` 时同步模板。Codex 只自动读取 `AGENTS.override.md`、`AGENTS.md` 与 `project_doc_fallback_filenames`，其他文件名不会生效。

### 2026-10-21 技术规范融入的改动范围

已提交（`2ac1c49`、`4d611a6`）并推送；文件分布如下，补充规范时照此放置：

- `dot_claude_projects/.claude-backend-dev/.claude/rules/`：`database/{mysql,mongodb,elasticsearch}.md`、`redis.md`、`mq/{kafka,rabbitmq}.md`、`go/logging.md`
- `dot_claude_projects/.claude-backend-dev/.claude/skills/`：`db-schema-design`、`cache-design`、`mq-design`、`system-design-doc`（含 `references/`），并复制到 `skills/skills-backend-dev/`
- `dot_claude_projects/.claude-dev-ops/.claude/skills/middleware-ops/`，并复制到 `skills/skills-dev-ops/`（删除其 `.gitkeep`）
- backend-dev `CLAUDE.md`（两份）技术栈改为 Kafka、RabbitMQ，「数据库」段改为「存储与中间件」索引；根 `README.md`、`dot_claude_projects/README.md`、`skills/README.md` 同步
- 测试：新增 `scripts/tests/test-scenario-skills.sh`（四场景 skill 与场景包 `diff -r`）；`test-backend-dev-bundle.sh` 改查新 rules/skills；`test-install-pkg.sh` 的占位包去掉 `dev-ops`

### 技术规范来源不入库

现象：用户的技术规范源文件含原企业的系统名、key 示例、内部流程与路径。

原因：本仓库公开，源文件只在本机 `~/workspace/documents/技術規範--檔案夾/`。

正确做法：只以重组后的内容入库，不复制、不引用源文件路径；之后补充规范时，同样替换示例中的系统名、key 前缀、日志路径、工单系统、内部工具名，提交前用临时关键词清单扫描改动文件（清单不入库）。Go 客户端参数（mongo-go-driver、go-redis、kafka-go、amqp091-go、GORM）已按 context7 官方文档核对；middleware-ops 中少量补充的通用经验值（ES 堆约 31GB、`vm.max_map_count`、quorum 队列等）未在本次逐条核对原文。

### 其他已知问题

- 第三方市场插件名无法离线校验：`pm-skills`、`anthropic-agent-skills` 未缓存在本机，`test-settings-templates.sh` 跳过其名称检查
- 全局工具重叠：mattpocock-skills 与 superpowers 都有 TDD、需求追问类 skill；用户决定不用 `skillOverrides` 关闭，由用户按需手动调用
- `typescript-native-lsp` 来自内置插件目录（`@anthropic-plugin-directory`）；TypeScript 6 以下需另装 `typescript-language-server`
- 本机 `~/.codex/AGENTS.md` 首行 `@/Users/zz/.codex/RTK.md`：`@` 引用是 Claude Code 语法，Codex 文档未提及支持，可能不生效（未验证，未改动）
- zsh 下 `for x in dir/*` 无匹配会报错中断；在本仓库用 Bash 工具批量处理文件时先 `setopt nullglob`，或写成 `sh` 脚本

<!-- section: pending -->
## 待处理事项

| 项目 | 位置 |
|---|---|
| 各场景用于试用的真实项目（用户指定） | 计划文件「需要用户决定」 |
| 试用期长度（建议 2 周） | 同上 |
| 交叉评审的模型组合与预算上限（`claude -p` 重复执行会消耗额度） | 同上 |
| 阶段 2 的采纳决策 | 阶段 2 完成后产出 |
| 本机是否采用新的全局设定 | 本文件「当前状态」 |
| `claude plugin eval` 是否适合本仓库场景包 | 计划文件 3.3（待确认后纳入） |

<!-- section: next -->
## 建议的下一步

**backend-dev Go 参考实现（进行中）**：用户已确认分三批实现，目录分层以 [FiberHouse](https://github.com/lamxy/fiberhouse) 的 `example_application/` 为准（`transport → service → repository → model`）。

1. 第一批（已完成，`7b7ef74`）：CLAUDE.md、`rules/go/{code-style,layering,testing}.md`、`rules/framework/{fiberhouse,fiber,gin}.md`、`go-new-module` skill、`hooks/go-fmt.sh`；移除 TS LSP 与 prisma
2. 第二批：`rules/database/{sql,mongodb}.md`（paths：`migrations/**`、`**/*.sql`、`model`/`repository`）+ `db-schema-design` skill；完成后删除 CLAUDE.md「数据库」段落
3. 第三批：`rules/redis.md`、`rules/mq.md`（RocketMQ）、`rules/rpc.md` + `cache-design`、`mq-design` skill

第二、三批已按用户首批技术规范合并完成（`2ac1c49`、`4d611a6`），范围调整：MQ 改为 Kafka + RabbitMQ（不做 RocketMQ）；Redis key 采用五段式 `<系统>:<模块>:<用途>:<数据类型>:<标识>`；运维面内容放 dev-ops 的 `middleware-ops`；RPC 延后到用户下一批规范。

约定：rules 一律带 `paths`（`test-backend-dev-bundle.sh` 检查）；skill 在 `skills/skills-backend-dev/` 与场景包各放一份并保持一致；规范内容先读原始来源（Uber Go Style Guide、FiberHouse 文档）再写。path rules 与 skill 的实际触发效果尚未在真实项目中验证。

**评估计划**：为四个场景写「典型任务清单」，每场景 5～8 个，写入 `docs/evaluation/2026-10-baseline.md` 的开头一节。它同时用于阶段 1 的覆盖度评估、阶段 2 的调研问题聚焦和阶段 3 的标准任务。可参考计划文件 3.3 的示例，写完请用户确认后再进入其余评估项。

前置条件：已满足（无需外部资源）。试用项目、模型组合与预算只在阶段 3 才需要。

---

## 如何扩展

| 需求 | 步骤 |
|---|---|
| 新增场景 | 在 `settings/`、`claude_mds/`、`dot_mcp_jsons/`、`agents/`、`skills/` 用相同 FLAG 新建，再复制进 `dot_claude_projects/.claude-<FLAG>/`（对应关系见该目录 README）；更新根目录 `README.md`「四个场景」与本文件 |
| 场景增减插件 | 改 `settings/settings.project-<FLAG>.json`，第三方市场要在 `extraKnownMarketplaces` 声明；同步 `settings/README.md`；跑 `test-settings-templates.sh` |
| 新增全局插件 | 改 `settings/settings.user.json` 与 `settings/README.md`；确认与已有全局插件无功能重叠或指令冲突 |
| 新增支持包 | 按 `open_supports/README.md` 或 `ost-support-workflow`；在 `INDEX.md` 两张表登记；项目级写进场景清单并带 `{PROJECT_DIR}`，用户级写进 `dot_claude_projects/.claude/`；跑 `test-open-supports-index.sh` |
| 新增 MCP | 先确认场景插件没有提供；凭据用 `${VAR}`；更新 `dot_mcp_jsons/README.md` |
| 新增 agent | 从 `agents-agency-agent-based-dev/` 复制到场景包，去掉文件名前缀，`name` 与文件名一致 |
| 修改脚本 | 前后都执行 `sh scripts/tests/run-all.sh`；新测试命名为 `scripts/tests/test-<对象>.sh`；脚本顶部写功能说明，`-h` 按必选／条件必选／可选分组并附示例 |

## 变更日志

新需求完成后在此追加：日期、需求、主要改动、遗留事项。

| 日期 | 需求 | 主要改动 | 遗留 |
|---|---|---|---|
| 2026-10-19 | 仓库转型 | `dot_claude/` 精简、`dot_claude_legacy/` 归档、根目录 README 重写 | — |
| 2026-10-19 | 安装脚本审查 | 备份、`eval`、空模板、`-F` 删除整个目录等问题修复；测试集中到 `scripts/tests/` | — |
| 2026-10-19 | open_supports 索引 | `INDEX.md`：A～D 分类、建议场景、全局工具；`{PROJECT_DIR}` 占位符 | — |
| 2026-10-19 | 四场景基础配置 | 全局与场景插件分层、四个 `CLAUDE.md`、数据库与 K8s MCP、场景 agent 包、启动包清单 | 场景自定义 skill；真实项目验证 |
| 2026-10-19 | pm-skills 走支持包 | `ost_phuryn_pm-skills` 支持 `--scope project`；PRD settings 移除 pm-skills | — |
| 2026-10-19 | 场景清单支持 Codex（已撤销） | 曾为清单加入 Codex 参数，随后按用户决定回退 | — |
| 2026-10-19 | install-open-supports.sh 审查 | 修复安装脚本吞掉清单后续行；wrapper Skill 记录完整命令并随清单更新；`-F` 改为备份；`[STALE]`；同一支持包多行只复制一次 | 旧测试的临时目录未清理（既有问题） |
| 2026-10-19 | 已知问题处理 | cognee 移出全局工具；重叠 skill 改为手动调用；删除 `docs/superpowers/` 历史计划 | — |
| 2026-10-20 | 安装脚本分工与场景包聚合 | `install-claude-project.sh` 管复制、`install-open-supports.sh` 管安装；两者新增 `-g`；后者新增 `-n`；场景包聚合各维度配置；新增全局清单 `dot_claude_projects/.claude/` | 场景包与各维度目录分开维护 |
| 2026-10-20 | 脚本注释与示例 | 8 个安装脚本与 `codex.sh` 顶部功能说明、`-h` 分组与示例；修复 `install.sh -e '*.md'` 被当前目录展开 | — |
| 2026-10-20 | Codex 适配按新架构改造 | `codex.sh` 只写 `~/.codex/AGENTS.md` 标记区块；模板改为 `CLAUDE.md` 的 Codex 版；移除项目级、`-v`、`.agent-rules/` | `analyze-github-repo` 转 Codex skill |
| 2026-10-20 | 评估与验证待办计划 | 新增 `docs/plans/2026-10-20-scenario-config-evaluation-plan.md`，清单同步写入本文件「当前状态」 | 待用户确认试用项目、模型组合与预算 |
| 2026-10-20 | 交接文件迁移 | `docs/HANDOFF.md` 迁至 `docs/handoff/HANDOFF.md`，按 myhandoff 模板重组（frontmatter、章节锚点），使 handoff 技能与 hook 能识别 | — |
| 2026-10-20 | 推送与发布 v2.0.0 | 推送 `main` 至 `a0783b3`，发布 v2.0.0；GitHub 仓库描述与 topics 改为个人开发者工具定位 | — |
| 2026-10-20 | README 定位文案与 v2.0.1 | 根目录 `README.md` 改为「个人开发者的 agent 配置与技能管理工具」语气（`6a31aee`），推送并发布 v2.0.1（Latest） | — |
| 2026-10-20 | myhandoff 技能纳入 `dot_claude/` | 本机 `~/.claude/skills/myhandoff/` 复制到 `dot_claude/skills/myhandoff/`（`c68cf9c`），`install.sh -l user` 随之安装；append 模式跳过已存在的技能文件（`[SKIP-APPEND]`）；新增 2 项测试 | 副本需手动与本机同步 |
| 2026-10-20 | 仓库根 `.claude/` 设定入库 | `claudeMdExcludes` 移到可提交的 `.claude/settings.json`，sandbox 开关留在 `settings.local.json`；`.gitignore` 排除 `.claude/settings.local.json`、`.claude/.cc-writes/`（`8b3ff01`）；`.codex` 本机不存在，维持忽略 | — |
| 2026-10-20 | 仓库范围说明 | 根目录与 `dot_claude_projects/` README 说明只维护四个场景的参考实现，其他场景由使用者复制场景包或切分支自行实现（`791dabf`） | — |
| 2026-10-20 | backend-dev Go 参考实现（第一批） | 按 FiberHouse 分层重写 CLAUDE.md；新增 6 个 path rules、`go-new-module` skill、`go-fmt.sh` PostToolUse hook；移除 `typescript-native-lsp`、`prisma`；新增 `test-backend-dev-bundle.sh`，11 个测试文件全过（`7b7ef74`） | 第二、三批待做；未推送 |
| 2026-10-21 | 技术规范融入（存储与中间件） | 用户首批规范去企业化后重组：backend-dev 7 个 rules、4 个 skill，dev-ops `middleware-ops` skill；新增 `test-scenario-skills.sh`，12 个测试文件全过 | RPC 待规范 |
