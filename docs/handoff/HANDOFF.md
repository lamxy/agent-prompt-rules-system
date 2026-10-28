---
branch: main
head: 90c2bfd
status: active
updated: 2026-10-28
---
# 进度交接

本文件记录仓库当前状态与续作指引，供 Claude Code、Codex 或协作者接手，也用于同一客户端清空会话后的续作。新需求完成后，在文末「变更日志」追加一条。

<!-- section: summary -->
## 摘要

- 进度：仓库转型、四场景配置、安装脚本分工与场景包聚合、Codex 适配改造均已完成并提交，已推送并发布 v2.0.1（Latest）；已制定「场景配置评估、优化与验证」待办计划，尚未开始执行
- 停在：2026-10-24 可观测性按起步阶段重写（Uptime Kuma、GlitchTip、Beszel、Dozzle、Telegram 转发，`21a4c0f`）、移除 K8s 改围绕 Docker（`304865c`）、FiberHouse 错误经附加 writer 进入 GlitchTip（`405408c`；FiberHouse 分支 `feature/logger-extra-writers` 已推送，头 `39cba6c`）、sentry / grafana-mcp 插件改为 GlitchTip MCP（`288cda3`）；12 个测试文件全过
- 2026-10-26：FiberHouse 框架取舍 7 条已由用户在 FiberHouse 仓库实施并发布 `v1.2.0`，backend-dev `fiberhouse.md` 改为引用 v1.2.0，疑问文件第一节清空、前端错误送 GlitchTip 转为待办
- 2026-10-26（续）：前端错误送 GlitchTip 分析后暂缓；新增请求 id 传递约定；FiberHouse 规则去版本绑定（不再引用 v1.2.0）
- 2026-10-27：按用户指示推送 `main` 的全部累积提交，发布 v2.1.0（tag `3821dee`）
- 2026-10-27～28：阶段 1 审计简化并写成手动测验指南（`b305f5d`）；settings 插件池梳理（`81e2b10`）；支持包按主／第二场景划分、场景包 README（`cff9bfe`）；2026-10-28 已推送并发布 v2.2.0（Latest，tag `e4af50e`）
- 2026-10-28（续）：工作流框架分层定稿并实施（`5e3b6a3`、`eb7375a`、`5eb6078`，未推送）：gstack 外部检出 + `--prefix`、默认不注册 hook，`skillOverrides` 默认只手动调用、场景按需打开；mattpocock-skills 移出全局改为 prd-design、backend-dev 场景启用
- 下一步：用户按 `docs/evaluation/manual-test-guide.md` 手动执行阶段 1，逐场景说「总结 <场景>」，由 Claude 回填 `docs/evaluation/2026-10-baseline.md` 第 3 节

接手前必读顺序：`AGENTS.md` → 本文件 → `docs/plans/2026-10-20-scenario-config-evaluation-plan.md`（执行计划时）→ 要改动的目录自己的 `README.md` → 根目录 `README.md`（设计原则与转型说明）。

<!-- section: status -->
## 当前状态

基础建设完成，进入「评估 → 调研 → 优化 → 验证」阶段。

| 任务 | 状态 | 说明 |
|---|---|---|
| **数据库设计强化（优先）** | 完成：MySQL（`d56306b`）、反面案例（`f91cd48`）、MongoDB（`3707f4f`） | 见「续作时必须知道的事」→「数据库设计强化」与「建议的下一步」 |
| 教学材料沉淀（gRPC、Go、Redis） | 完成，疑问已定稿 | `5098a4e`、`3c492ef`、`9bddf11`；疑问见 `docs/plans/2026-10-22-learning-distill-questions.md` |
| backend-dev Go 参考实现 | **进行中** | 第一批 `7b7ef74`；存储与中间件规范 `2ac1c49`；gRPC 规范 `5098a4e`（来自教学材料，用户企业 RPC 规范若有再补） |
| 可观测性重写与 FiberHouse 错误追踪 | 完成；框架取舍已决定（FiberHouse `v1.2.0`） | `docs/plans/2026-10-22-learning-distill-questions.md` 第三节「FiberHouse 框架取舍」 |
| 场景配置评估、优化与验证 | **阶段 1 待用户手动执行** | 2026-10-27 审计简化：16 个任务、交互模式手动执行，见 `docs/evaluation/2026-10-baseline.md` 第 1 节与 `docs/evaluation/manual-test-guide.md`；计划文件开头「审计结论」优先于下方原清单 |
| 四个场景的自定义 skill | 待开始 | `backend-dev` 已有 `go-new-module`；其余 `skills/skills-<FLAG>/` 目前只有占位；例如 PRD 模板、API 契约、上线检查清单。建议在阶段 2 调研后再写 |
| `dot_claude/commands/analyze-github-repo.md` 转 Codex skill | 待开始 | Codex custom prompts 已于 2026-01 弃用；装到 `~/.agents/skills` |
| 本机采用新全局设定 | 待用户决定 | `sh scripts/install-settings.sh -l user -m overwrite`；`dot_claude/settings.json` 仍是本机设定镜像，未做插件分层调整 |
| 技能与工具包管理平台 MVP 迁入 `src/` | 待开始 | 根目录 `README.md` Roadmap |

### 待办计划：场景配置评估、优化与验证

计划文件：`docs/plans/2026-10-20-scenario-config-evaluation-plan.md`（评估对象表、7 个评估维度、调研来源分级、标准任务示例、判定标准、执行顺序图）。完成一项就在此勾选，并在计划文件同步。

**阶段 1：现状评估**（产出 `docs/evaluation/2026-10-baseline.md`）

- [x] 为四个场景写「典型任务清单」：审计后为每场景 3 个 ★ 任务 + 1 个反向任务（`docs/evaluation/2026-10-baseline.md` 第 2 节）
- [ ] 用户按手动测验指南执行 T1～T4，Claude 汇总回填第 3 节（以下各项按审计结论并入或推迟）
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

**版本**：`main` 已于 2026-10-28 推送至 `origin/main`（之后的新提交推送仍需用户指示）；GitHub release v2.0.0（tag `a0783b3`）、v2.0.1（tag `6a31aee`）、v2.1.0（tag `3821dee`）、v2.2.0（tag `e4af50e`，标为 Latest）。GitHub 仓库描述与 topics 已改为个人开发者工具定位。

**四个场景**（FLAG 在所有维度目录中一致；另有 `fullstack-dev` 只存在于 `settings/`）：

| FLAG | 场景 | 范围 |
|---|---|---|
| `prd-design` | PRD 与原型设计 | 需求说明书、PRD、线框图或基础原型 |
| `frontend-dev` | 前端开发 | UI 设计与实现、前端交互、对接后端 API |
| `backend-dev` | 后端开发 | 系统规格、系统／数据库／架构设计、选型；后端功能、API 与数据库开发 |
| `dev-ops` | DevOps | CI/CD、上线、可观测性 |

**已确认的技术栈决策**：后端 Go、Node.js / TypeScript；数据库以 MongoDB、Redis、MySQL 为主，兼容 PostgreSQL；部署围绕 Docker / Docker Compose（2026-10-23 去掉 K8s）；可观测性起步阶段用 Uptime Kuma、GlitchTip、Beszel、Dozzle，告警只发 Telegram，升级路径为 Prometheus + Alertmanager；PRD 以 pm-skills、mattpocock-skills、gstack 等技能为主；**规格框架按场景启用**（2026-10-28 改：全局 superpowers；后端清单默认启用 OpenSpec、前端清单默认启用 gsd-core，同一项目只启用一套；支持包按主场景启用、第二场景注释录入，见 `open_supports/INDEX.md`「建议场景」）；全局工具 task-master、gstack（2026-10-28：gstack 以 `--prefix` 安装，`skillOverrides` 默认只能手动调用、场景按需打开；mattpocock-skills 移出全局，改在 prd-design、backend-dev 场景启用，见 `settings/README.md`「工作流框架分层」）；记忆类只保留 `remember`，cognee 暂不启用。

**目录结构**：

```
dot_claude/                 个人用户级配置（约 30 行 CLAUDE.md、commands/、settings.json），繁体中文
dot_claude_legacy/          2026-10-19 前的分层规则系统存档，不被任何安装脚本使用
settings/                   全局 settings.user.json（15 个全局插件）+ 项目级 5 个场景模板 + 本地级 4 个
claude_mds/                 CLAUDE-<FLAG>.md，各约 30 行，只写场景约定
dot_mcp_jsons/              后端 MySQL/PostgreSQL（MCP Toolbox）+ GlitchTip；DevOps GlitchTip；PRD、前端为空
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
  tests/                    14 个测试文件，run-all.sh 一次执行
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

最后一次完整验证结果：2026-10-28（`90c2bfd`），14 个测试文件全部通过（含 `sh -n` 语法检查）。

<!-- section: gotchas -->
## 续作时必须知道的事

### 用户约束（必须遵守）

| 约束 | 说明 |
|---|---|
| 不改动本机配置 | 只修改本仓库。`~/.claude/`、`~/.codex/` 等本机文件只读，除非用户明确下指令 |
| 改动前先确认 | 涉及取舍的事项先列方案与理由，用户确认后再实现 |
| 提交 | 用户确认后才提交；推送与发布 release 需用户明确指示（2026-10-20 已按指示推送并发布 v2.0.0、v2.0.1；2026-10-27 按指示推送累积提交） |
| 测试 | 一律在临时目录或 scratchpad 执行，不对真实配置测试 |
| 配置不含未验证内容 | 2026-10-23 用户要求：`dot_claude_projects/`、`skills/`、`claude_mds/` 中每条结论须有容器实测或一手来源（官方文档、规范、源码）；做不到的记入 `docs/plans/` 待验证清单，不写入配置。用户规范的既定默认值保留 |
| 不使用中国大陆的工具 | 例如飞书、钉钉、阿里云、腾讯云 |
| 语言 | 与用户沟通用繁体中文；`dot_claude/` 与 Codex 模板为繁体中文；其他仓库文档为简体中文 |

### 场景包与各维度目录分开维护

现象：改了 `settings/`、`claude_mds/` 等维度目录，场景包 `dot_claude_projects/.claude-<FLAG>/` 里的同名配置没变，反之亦然。

原因：2026-10-20 用户决定场景包是「初次从各维度复制、之后独立维护」的完整聚合，不做同步脚本或一致性测试。

正确做法：需要两边一致时手动复制，并在提交说明里写明；不要新增自动同步或一致性测试。2026-10-28 插件集中梳理时，用户要求两边对齐一次（四个场景的 settings 已确认完全一致），之后仍分开维护，除非用户明确要求再次对齐。

### 安装顺序与 settings 覆盖

现象：PRD 场景用 `install-settings.sh -m overwrite` 重装 settings 后，pm-skills 插件消失。

原因：pm-skills 以 `--scope project` 写入项目 `.claude/settings.json`，overwrite 会整体替换。`install-claude-project.sh` 已内建「先复制 settings 再装支持包」的顺序，单独装 settings 时没有。

正确做法：单独重装 settings 后重新运行 `install-open-supports.sh -t <project>`，或用 `-m merge`。含 permissions 的模板（backend-dev、dev-ops、fullstack-dev）必须用 overwrite，merge 只合并插件、市场与 `skillOverrides` 字段。

### 数据库 MCP 可写

MCP Toolbox 的 `execute_sql` 可以执行写操作，工具本身没有只读开关；settings 的 `deny` 只拦 Bash 命令，拦不到 MCP 调用。连接必须使用只读账号、只连开发或测试库。

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

正确做法：只以重组后的内容入库，不复制、不引用源文件路径；之后补充规范时，同样替换示例中的系统名、key 前缀、日志路径、工单系统、内部工具名，提交前用临时关键词清单扫描改动文件（清单不入库）。Go 客户端参数（mongo-go-driver、go-redis、kafka-go、amqp091-go、GORM）已按 context7 官方文档核对；middleware-ops 的 ES 系统参数已于 2026-10-26 对照技术规范原文核对：堆 32GB 与 G1、文件句柄与 `vm.max_map_count` 655360 出自规范，配置中标注「技术规范」并与官方 bootstrap check 下限并列；其余补充的通用经验值（quorum 队列等）规范中没有，仍按疑问文件的待验证清单处理。

### 数据库设计强化（2026-10-21）

用户决定（已写入 `dot_claude_projects/.claude-backend-dev/.claude/rules/database/mysql.md`）：

- 组合索引按 ESR（等值 → 排序 → 范围），取代「按区分度从高到低」；低选择性字段不放最左
- 维持全部 `NOT NULL`，「没有」用约定值（关联 id `0`、未发生时间 `'1970-01-01 00:00:00'`、字符串 `''`）；极少数例外须在 `COMMENT` 与 ADR 写明理由
- 分表门槛、膨胀系数等经验值标为「默认值，项目可调整」
- 现行 `datetime`（无毫秒）不改为教材的 `DATETIME(3)`

教材来源：本机 `~/workspace/documents/learning/databases_learn/`（**不入库**，入库内容已去除品牌、人名、日期、需求编号）。来源可信度：各 day 的 `lecture.md`、`solutions.md` 经数据库实测，为权威；`reviews/`、`node-*-guide.md` 为讲师批改，无实测的标为推论；`exercises.md` 与 `day3-design/database-design.md` 是学员产出，**不作为结论来源**。

已踩过的坑：教材 day3 讲义的销售排行索引 `(sku_id, created_at)` 与批改中「`(created_at, status)` 让 `GROUP BY status` 免临时表」都是错的，已在临时容器（MySQL 8.0.46，导入 `schema/snapshot-full.sql.gz`）实测推翻，结果写进 `references/case-ecommerce.md` 与 `references/mysql.md`。之后引用教材结论前，先区分来源等级，存疑的就实测。实测时用不暴露端口的临时容器，不用教材的 compose（其设 `restart: unless-stopped`）。

### MongoDB 规范的实测依据（2026-10-22）

现象：早期教材（MongoDB 4.2、Go Driver v1）的不少结论在新版已过时或本就不准，直接引用会写错规则。

原因：本次以 MongoDB 8.0 与 Go Driver v2 实测推翻或修正了多条，例如：`readConcern: majority` 单独使用不阻塞、但在因果一致性会话读落后的 secondary 时会等待；`w: majority` 超时不等于未写入；`hint` 强制部分索引会静默少返回数据；`WithTransaction` 遇写冲突会重跑回调；`background: true`、`enableMajorityReadConcern`、`$lookup` 不能查分片集合等说法已过时。详见 `db-schema-design/references/mongodb.md` 文末「早期资料中已过时的说法」。

正确做法：补充或修改 MongoDB 规范前先查该文件的实测表；新结论用临时容器实测（`mongo:8.0` 三节点副本集，独立 docker 网络、不暴露端口；Go 用 `golang:1.25-alpine` 挂载 scratchpad 目录运行），Go 代码一律用 `go.mongodb.org/mongo-driver/v2`（FiberHouse 亦然）。教材来源在本机 `~/workspace/documents/learning/mongodb/`，**不入库**。

### 教学材料沉淀（2026-10-22）

现象：教材结论常与新版行为不符（例如 Timer 的 Reset 语义、GOMAXPROCS 容器感知取决于 `go.mod` 的 go 行而非工具链；listpack 内置默认 512 而非 `redis.conf` 示例的 128；grpc-go 不捕获 panic，进程直接退出）。

原因：教材基于旧版本，且部分数字来自示例配置或带额外开销的测量。

正确做法：落点与实测表在各 skill 的 references（`rpc-design/references/`、`go-perf-diagnose/references/concurrency.md`、`cache-design/references/{redis,patterns}.md`）；修改前先查实测表，新结论用 `--rm`、不暴露端口的临时容器实测。版本上限：Go 1.25 项目最高 go-redis v9.22.0、x/sync v0.22/v0.23（v0.24 与 go-redis v9.23 要求 Go 1.26）。rule 正文维持用户既定条款（Redis key 禁 `}`、不用 MULTI/EXEC 等），冲突方案只写疑问文件。教材在本机 `~/workspace/documents/learning/{grpc_learn,golang_learn,redis-bootcamp}/`，**不入库**。

### path rules 的加载时机（2026-10-23 实测）

现象：rule 写对了 `paths`，编辑某些代码时仍不生效。

原因：Claude Code 2.1.308 中，Read、Bash 读类命令、Write、Edit 都会加载匹配的 rule，但都在工具执行之后才注入；Bash 写类命令（heredoc、`sed -i`）不加载；代码不在匹配路径下（例如缓存编排在 `service/`）时当然不加载。hook 注入同样晚到，不能补救。

正确做法：必须在动手前知道的约定写进常驻 `CLAUDE.md` 或 skill；按目录集中代码让 `paths` 精准命中（Redis 代码只放 `cache/`），并尽量用 lint（depguard）等机械检查兜底。实测记录在 `docs/plans/2026-10-22-learning-distill-questions.md`「参考记录」。

### FiberHouse 版本引用（2026-10-24，2026-10-26 更新）

现象：backend-dev 规则引用的 `WithLogWriters`、caller 修正、字符串 panic 记录、按 HTTP 状态定级等行为在 v1.1.1 及更早版本中没有。

原因：按用户要求在临时克隆（scratchpad 下 `fh-work/fiberhouse`，会话结束即清理）切分支 `feature/logger-extra-writers` 修改并推送到 `lamxy/fiberhouse`；2026-10-26 用户合并入 `main` 并发布 `v1.2.0`（远端分支保留）。

正确做法：规则按版本引用 `go get github.com/lamxy/fiberhouse@v1.2.0`（经 proxy.golang.org 实测解析）；框架行为变更后先核对 FiberHouse 的提交与 `.codegraph-qa-out/` 记录再改规则。本机 FiberHouse 仓库在 `~/workspace/github_repos/fiberhouse`，不在本仓库内放框架源码。FiberHouse 提交信息用英文（其 `CLAUDE.md` 要求）。

### GlitchTip 与 Telegram 的坑（2026-10-24 实测）

- GlitchTip 6.2.6 告警渠道没有 Telegram，靠 `assets/observability/glitchtip-telegram-relay` 转发；relay 与 GlitchTip 同网络时必须 `GLITCHTIP_ALLOW_PRIVATE_IPS=True`，否则 webhook 被 SSRF 检查静默拦截。
- `GLITCHTIP_ENABLE_MCP=True` 时 `GLITCHTIP_DOMAIN` 不是 https（localhost、127.0.0.1 除外）会启动即退出。
- 权限：本会话中 `docker network rm`、`docker rm` 被拒，测试网络 `obs-net` 与容器 `mcp-gt` 需用户手动清理（见疑问清单第六节）。

### 其他已知问题

- 第三方市场插件名无法离线校验：`pm-skills`、`anthropic-agent-skills` 未缓存在本机，`test-settings-templates.sh` 跳过其名称检查
- 工作流框架重叠（2026-10-28 改）：原决定「不用 `skillOverrides` 关闭，由用户按需手动调用」已被取代。`skillOverrides` 对插件 skill 无效（实测 + 官方文档），所以 mattpocock-skills 只能整包移到场景；gstack 是个人 skill，用 `user-invocable-only` 实现「只手动调用」。依据见 `docs/evaluation/2026-10-28-skill-overrides-experiment.md`
- `typescript-native-lsp` 来自内置插件目录（`@anthropic-plugin-directory`）；TypeScript 6 以下需另装 `typescript-language-server`
- 本机 `~/.codex/AGENTS.md` 首行 `@/Users/zz/.codex/RTK.md`：`@` 引用是 Claude Code 语法，Codex 文档未提及支持，可能不生效（未验证，未改动）
- zsh 下 `for x in dir/*` 无匹配会报错中断；在本仓库用 Bash 工具批量处理文件时先 `setopt nullglob`，或写成 `sh` 脚本

<!-- section: pending -->
## 待处理事项

| 项目 | 位置 |
|---|---|
| 各场景用于试用的真实项目（用户指定） | 计划文件「需要用户决定」 |
| 试用期长度（建议 2 周） | 同上 |
| 教学材料沉淀的已完成项、1 项暂缓（前端 GlitchTip）、11 条待验证与本机 docker 残留清理 | `docs/plans/2026-10-22-learning-distill-questions.md` |
| 交叉评审的模型组合与预算上限（`claude -p` 重复执行会消耗额度） | 同上 |
| 阶段 2 的采纳决策 | 阶段 2 完成后产出 |
| 本机是否采用新的全局设定 | 本文件「当前状态」 |
| `claude plugin eval` 是否适合本仓库场景包 | 计划文件 3.3（待确认后纳入） |
| deanpeters/Product-Manager-Skills 是否进入 PRD 场景（2026-10-28 用户决定暂不处理，下次再看）：需先为 `open_supports/ost_deanpeters_Product-Manager-Skills` 补 Claude Code 项目级安装路径（目前项目级只有 `--client=codex-zip`）；还要考虑与 phuryn/pm-skills 功能重叠、两者 `marketplace.json` 的 `name` 都是 `pm-skills`、授权为 CC BY-NC-SA 4.0（非商业） | `open_supports/INDEX.md`「建议场景」下方说明 |

<!-- section: next -->
## 建议的下一步

**数据库设计强化（优先，按用户节奏逐步推进）**：用户 2026-10-21 要求加入，分批提供材料。

1. 互联网商城的 MySQL 设计、反经典范式思想、索引：**已完成**（`d56306b`）。落点：`db-schema-design` 的 `SKILL.md`（节点流程与自查清单）、`references/{mysql,sql-pitfalls,case-ecommerce,anti-patterns,design-doc-template}.md`，以及 `rules/database/mysql.md`
2. MongoDB 设计：**已完成**（`3707f4f`）。课程笔记（MongoDB 4.2）经 MongoDB 8.0 三节点副本集与 Go Driver v2.9 实测、context7 官方文档核对，并由子代理独立复测审计；落点：`rules/database/mongodb.md`、`db-schema-design/references/mongodb.md`、dev-ops `middleware-ops/references/mongodb.md`（备份与时间点恢复、安全、巡检）、`rules/go/layering.md`（`bson.ObjectID`）
3. AI 开发技能平台的失败数据库设计（反面案例）：**已完成**（`f91cd48`）。落点：新增 `references/case-ai-platform.md`（领域改写为插件分发平台、不注明来源仓库），`anti-patterns.md` 新增 7 条，`mysql.md` 补 PostgreSQL 迁移对照，rule 新增「表间关联用对方 `bigint` 主键」；子代理报告中 7 项未验证内容按用户决定未写入

做法：材料较大时派子代理只读提炼，报告写到 scratchpad，主会话抽查后先向用户列改动方案、确认后再写入；每一步都等用户决定。skill 在 `skills/skills-backend-dev/` 与场景包保持一致（`test-scenario-skills.sh` 校验）。材料若含企业或真实项目元素，先去除再入库，源文件不入库。

前置条件：三项均已完成，本条无后续。

**backend-dev Go 参考实现（进行中）**：用户已确认分三批实现，目录分层以 [FiberHouse](https://github.com/lamxy/fiberhouse) 的 `example_application/` 为准（`transport → service → repository → model`）。

1. 第一批（已完成，`7b7ef74`）：CLAUDE.md、`rules/go/{code-style,layering,testing}.md`、`rules/framework/{fiberhouse,fiber,gin}.md`、`go-new-module` skill、`hooks/go-fmt.sh`；移除 TS LSP 与 prisma
2. 第二批：`rules/database/{sql,mongodb}.md`（paths：`migrations/**`、`**/*.sql`、`model`/`repository`）+ `db-schema-design` skill；完成后删除 CLAUDE.md「数据库」段落
3. 第三批：`rules/redis.md`、`rules/mq.md`（RocketMQ）、`rules/rpc.md` + `cache-design`、`mq-design` skill

第二、三批已按用户首批技术规范合并完成（`2ac1c49`、`4d611a6`），范围调整：MQ 改为 Kafka + RabbitMQ（不做 RocketMQ）；Redis key 采用五段式 `<系统>:<模块>:<用途>:<数据类型>:<标识>`；运维面内容放 dev-ops 的 `middleware-ops`；RPC 延后到用户下一批规范。

约定：rules 一律带 `paths`（`test-backend-dev-bundle.sh` 检查）；skill 在 `skills/skills-backend-dev/` 与场景包各放一份并保持一致；规范内容先读原始来源（Uber Go Style Guide、FiberHouse 文档）再写。path rules 与 skill 的实际触发效果尚未在真实项目中验证。

**评估计划（阶段 1）**：由用户按 `docs/evaluation/manual-test-guide.md` 手动执行（专案集 `~/workspace/aitools_test/scenario-eval/`，FiberHouse 在专案集内从 GitHub 重新克隆）。用户说「总结 <场景>」时：读专案集的 `notes.md`、项目内 run tag（`git diff baseline <任务>-r<次数>`）与 `~/.claude/projects/` 下该项目的会话记录，按任务卡观察点判定，回填 `docs/evaluation/2026-10-baseline.md` 第 3 节，列出问题清单，经用户确认后提交。收尾时比对 `env-before.txt` 与 `env-after.txt`。

前置条件：指南与素材已提交；执行由用户安排。阶段 2 只针对阶段 1 发现的问题调研。

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
| 2026-10-21 | 新增数据库设计强化待办 | 交接文件登记优先待办：等用户提供商城设计、反范式思想、AI 技能平台反面案例的教学材料 | 等材料 |
| 2026-10-21 | 数据库设计强化：MySQL 商城教学案例 | 组合索引改 ESR、NOT NULL 约定值与例外等写入 MySQL rule；`db-schema-design` 新增 4 个 references 与节点流程、自查清单；销售排行索引经临时容器实测（`d56306b`） | MongoDB、反面案例等用户材料；未推送 |
| 2026-10-22 | 数据库设计强化：AI 技能平台反面案例 | 子代理只读分析原仓库 migration，去识别化后写入 `case-ai-platform.md`、`anti-patterns.md` 7 条、`mysql.md` 迁移对照与 rule 一条（`f91cd48`） | MongoDB 等用户材料；未推送；临时容器 `dbverify-tmp` 待用户清理（未验证是否仍存在） |
| 2026-10-22 | 数据库设计强化：MongoDB | 课程笔记经 8.0 副本集与 Go Driver v2 实测、官方文档核对、子代理独立复测审计后重写 backend-dev MongoDB rule 与 reference；分库与 `_id` 规则按实测放宽；dev-ops 补备份与时间点恢复、安全基线、巡检指标（`3707f4f`） | 未推送；临时容器 `mgv1`～`mgv3`、网络 `mgv-net` 待清理 |
| 2026-10-22 | 教学材料沉淀：gRPC、Go、Redis | 逐个子代理提炼 + 容器实测 + 子代理交叉复测：`rules/rpc/`、`rpc-design`（`5098a4e`）；`rules/go/concurrency.md`、`go-perf-diagnose`，常驻 Go 规则 8.2KB→6.1KB（`3c492ef`）；Redis rule、`cache-design/references/patterns.md`、middleware-ops（`9bddf11`） | 疑问待用户讨论；未推送；docker 卷 `grpclab-gomod`、网络 `redislab-net`/`redisrev-net`、容器 `mgv1`～`mgv3`/`dbverify-tmp` 待清理 |
| 2026-10-23 | 疑问「path rules 覆盖不到 Redis 代码」定稿 | `claude -p` 实测 rule 加载时机；go-redis 只在 `cache/` 层 import（常驻 `CLAUDE.md`、`layering.md`、`go-new-module`）；depguard 范本（golangci-lint v2.5.0 实测）；`cache-design/references/layered-examples.md`（Redis 8.10.2 / 7.4.11 集成测试）（`3c278bc`） | 复杂约束的自我修正、gRPC depguard 待验证；未推送；容器 `rcase-redis`、网络 `rcase-net` 待清理 |
| 2026-10-24 | 可观测性重写、去 K8s、FiberHouse 错误追踪 | 资源配置先问上限（`d229d3d`）；去 K8s 改 Docker（`304865c`）；可观测性起步方案与 compose / relay 实测（`21a4c0f`）；DELEX 说明（`511086d`）；FiberHouse 分支 `feature/logger-extra-writers`（caller、附加 writer、字符串 panic、typed-nil，`39cba6c`）+ 规则接入（`405408c`）；插件改 GlitchTip MCP（`288cda3`）；子代理交叉审查 4 项 should-fix 已修正；场景安装到临时项目后复验通过（compose、MCP、告警链路）；第二轮交叉复验无 blocker / should-fix，2 个 nit 已修正 | 8 条框架取舍待用户确认；FiberHouse 分支未合并；本仓库未推送；`obs-net`、`mcp-gt` 待清理 |
| 2026-10-26 | FiberHouse 框架取舍定稿 | 7 条取舍在 FiberHouse 实施并发布 `v1.2.0`（经 GOPROXY 实测编译）；`rules/framework/fiberhouse.md` 改为引用 v1.2.0，按新行为改写定级、堆栈字段、重复上报、traceId 说明；疑问文件第一节清空、新增决定表与待办 4（前端错误送 GlitchTip）；12 个测试文件全过；子代理交叉审查无 blocker，4 项 should-fix（Fiber requestid `ContextKey` 前提、Gin 写法、业务码 5xxxxx 仍为 400、顶帧结论限 Fiber 实测）与 2 项 nit 已修正 | 未推送 |
| 2026-10-26 | 前端错误追踪分析与请求 id 传递规则 | 待办 4 深入分析并实测（`@sentry/browser` 11.9.0 → GlitchTip 6.2.6，报告 `docs/plans/2026-10-26-frontend-glitchtip-analysis.md`），用户决定暂不接入；新增请求 id 传递约定：backend `rules/go/logging.md`「请求 id 传递」（Fiber v2.52.16、Gin v1.12.0 实测入口覆盖与放入 ctx）、frontend `CLAUDE.md` 显示错误编号、dev-ops `observability.md`「请求 id」与 `CLAUDE.md`（Nginx 1.29.8 实测）；12 个测试文件全过 | 未提交；GlitchTip 停用 key 无效、key 限流不生效是否报上游待定；docker `fegt-gt`、`fegt-pg`、网络 `fegt-net` 待手动清理 |
| 2026-10-26 | 待办 1～3 收尾 | Beszel 0.21.1 hub↔agent 连接补测（公钥正确在线、错误离线）；`settings.user.json` 移除 `kubectl get/describe` 放行（不用 K8s，且可读出 Secret）；DELEX 条目精简并核对主流锁库（Redisson、redis-py 仍用 Lua）；独立子代理交叉评估无 blocker，3 项 should-fix 已修正（FiberHouse 请求 id 兜底顺序、直接对外时丢弃客户端值、实测证据补入疑问文件第五节）；12 个测试文件全过 | 网络 `besz-net`、`fegt-net` 与容器 `fegt-*` 待手动清理；未推送 |
| 2026-10-26 | 恢复来自技术规范的 ES 配置 | 对照技术规范原文，ES 堆 32GB 与 G1、文件句柄与 `vm.max_map_count` 655360 放回 dev-ops `middleware-ops/references/elasticsearch.md`（场景包与 `skills/skills-dev-ops/` 两份）并标注来源；疑问文件删除空的待确认节，待办拆为已完成与暂缓（`b01cf82`、`968ddd2`） | — |
| 2026-10-27 | 交接补记与推送 | 补记上一条、重跑测试（12 个测试文件全过）、重写 frontmatter 锚点；按用户指示推送累积提交；发布 v2.1.0（Latest） | — |
| 2026-10-27～28 | 阶段 1 审计与手动测验指南 | 用户决定不用 `CLAUDE_CONFIG_DIR` 隔离、改为手动实战，环境与真实使用一致（装支持包、场景插件、启用项目 MCP），影响逐项提醒；交互模式、每任务最多 2 次；任务缩减为 16 个；新增 `docs/evaluation/`（基线、指南、fixtures）（`b305f5d`） | 等用户执行 |
| 2026-10-28 | settings 插件池梳理 | 参考插件配置 + 全局 + 各场景汇总为插件池表；同源插件统一 `@claude-plugins-official`；`code-review`、`mongodb-self-managed-mcp` 不采用；local 模板加 `pyright-lsp`、`typescript-lsp`（false）；`settings.user.json` 本机依赖说明；全局 deny 覆盖 dev-ops ask 保持现状并说明（`81e2b10`） | project 模板与场景包本次对齐，之后仍分开维护 |
| 2026-10-28 | 支持包场景划分与场景包 README | 核对 5 个上游原文（报告中 pm-skills 数量、`/canary` 灰度、gsd-core 后端命令等为误）；主场景启用、第二场景注释录入：OpenSpec 主后端、gsd-core 主前端（取代「不设默认框架」）、codegraph 主后端、`pm-ai-shipping` 次 DevOps；四个场景包新增 README（自动加载／需手动安装的插件与恢复命令）（`cff9bfe`） | deanpeters 入 PRD 暂缓（见待处理事项） |
| 2026-10-28 | 工作流框架分层 | 讨论与实测（`5e3b6a3`）：`skillOverrides` 对插件 skill 无效、跨作用域逐键合并；`install-settings.sh -m merge` 逐键合并 `skillOverrides`（`eb7375a`）；gstack 安装脚本默认 `~/.local/share/gstack`、`--prefix`、不注册 timeline / plan-tune hook，只对 `gstack-config` 未保存的设置传默认值（隔离 HOME 端到端验证）；`settings.user.json` 隐藏 gstack 64 项，prd-design、dev-ops 按需打开；mattpocock-skills 改为 prd-design、backend-dev 场景启用（`5eb6078`）；13 个测试文件全过 | 未推送；本机尚未按新方式安装 gstack；gstack 升级新增 skill 时需补进 `skillOverrides`；`/gstack-review` 与内置 `/code-review` 别名的关系未实测；本机 `~/.claude/settings.json` 尚无 gstack 的 `skillOverrides`（直接 merge 会重复启用 4 个异市场同名插件，方案待定）；gstack 升级新增 skill 的检查方式待定 |
| 2026-10-28 | 本机同步分层与升级检查 | `install-settings.sh` 新增 `-K <字段>`（只合并指定字段，避免本机异市场同名插件被重复启用）；新增只读 `scripts/check-gstack-overrides.sh`，gstack 安装脚本 setup 后自动运行；隔离 HOME 真实安装端到端验证；14 个测试文件全过（`90c2bfd`） | 本机安装 gstack 由用户执行：`sh scripts/install-settings.sh -l user -m merge -K skillOverrides`，再 `sh scripts/install-open-supports.sh -g -n garrytan/gstack`，最后 `sh scripts/check-gstack-overrides.sh`；推送待用户指示 |
| 2026-10-28 | fullstack-dev 启用 mattpocock-skills | `settings/settings.project-fullstack-dev.json` 与插件池表、索引同步（`690b1b7`） | 未推送：用户要求待办全部完成后再推送 |
| 2026-10-28 | 推送与发布 v2.2.0 | 推送 `b305f5d`～`e4af50e`，发布 v2.2.0（Latest，tag `e4af50e`）；相容性说明：frontend-dev 默认装 gsd-core、不再默认装 codegraph，backend-dev 加装 OpenSpec（会全局安装或升级 openspec CLI） | — |
