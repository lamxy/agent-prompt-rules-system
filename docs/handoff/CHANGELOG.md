# 变更日志

新需求完成后在此追加一行：日期、需求、主要改动、遗留事项。2026-11-27 起从 `docs/handoff/HANDOFF.md` 移来（原「变更日志」一节原样保留）。

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
| 2026-10-28 | task-master 不注册 MCP | 全局清单改为 `eyaltoledano/claude-task-master --global`（只装 CLI）；INDEX 与帮助示例同步；本机 `~/.claude.json` 无 task-master MCP 记录，无需清理 | 推送待用户指示 |
| 2026-10-28 | 全局安装一条命令 | `install-claude-project.sh -g` 改为三步并标出步骤：复制全局清单 → `-K skillOverrides` 同步 gstack 分层（先备份，`-k` 跳过）→ 安装全局支持包并只读检查覆盖；14 个测试文件全过（`41281a1`） | 本机安装由用户执行 `sh scripts/install-claude-project.sh -g -d` 预演后去掉 `-d`；推送待用户指示 |
| 2026-10-28 | 本机同步分层与升级检查 | `install-settings.sh` 新增 `-K <字段>`（只合并指定字段，避免本机异市场同名插件被重复启用）；新增只读 `scripts/check-gstack-overrides.sh`，gstack 安装脚本 setup 后自动运行；隔离 HOME 真实安装端到端验证；14 个测试文件全过（`90c2bfd`） | 已由 `41281a1` 合并为一条命令，见下一行 |
| 2026-10-28 | fullstack-dev 启用 mattpocock-skills | `settings/settings.project-fullstack-dev.json` 与插件池表、索引同步（`690b1b7`） | 未推送：用户要求待办全部完成后再推送 |
| 2026-10-28 | 推送与发布 v2.2.0 | 推送 `b305f5d`～`e4af50e`，发布 v2.2.0（Latest，tag `e4af50e`）；相容性说明：frontend-dev 默认装 gsd-core、不再默认装 codegraph，backend-dev 加装 OpenSpec（会全局安装或升级 openspec CLI） | — |
| 2026-10-28 | 本机全局安装、推送与发布 v2.3.0 | 用户在本机执行 `install-claude-project.sh -g`（`check-gstack-overrides.sh` 一致）；deanpeters/Product-Manager-Skills 决定忽略，`open_supports/INDEX.md` 改为不启用（`beb1ca8`）；推送并发布 v2.3.0（Latest），相容性说明：gstack 默认只手动调用、无 `--prefix` 旧安装需重装、全局不再启用 mattpocock-skills；14 个测试文件全过 | 本机全局设定差异待用户决定；docker 残留待用户手动清理 |
| 2026-10-28 | 本机全局设定对齐 | 比对本机与 `settings.user.json` 后由用户逐项决定；同一插件跨市场被视为不同插件、同时启用只注册一份 hooks（官方 `plugins/loading.md`），directory 来源用 `install --replace` 切换、demo 市场副本需 `uninstall`；本机备份 `~/.claude/settings.json.bak-20261028191703`；`settings/README.md` 记录与保留差异，镜像同步（`6adb239`） | `installed_plugins.json` 有指向已删除 scratchpad 的项目级孤立记录，无影响、未清理 |
| 2026-10-29 | 配置安装技能 `myconfig` | 盘点、设计 v2 经子代理交叉审查后由用户确认第 9 节；实现 `dot_claude/skills/myconfig/`（SKILL.md、`scripts/catalog`、`references/commands.md`）与 `test-myconfig-catalog.sh`（15 个测试文件全过）；`claude -p` 实测发现沙箱同时限制读取（`denyRead ~/`）、会话内写 `.claude/` 配置与注入命令，改为只预演 + 交付命令、注入加 `\|\| printf` 退路；第二轮实现审查 1 blocker（单个支持包 `--dry-run` 放在 `--` 后会真实安装）等全部修正 | 已提交（`0400627`、`d68370c`）并推送，发布 v2.4.0（Latest）；安装后报告未端到端测试 |
| 2026-10-29～30 | 阶段 1 手动测验：T1、backend-dev、dev-ops | postman 移出 backend-dev、fullstack-dev（`29a8e27`）；T1 按配置项求差（场景增量 ≤ 1%）；B1/B4/B8/B2 通过，D2 部分（未询问资源上限）、D7/D3/D4 通过；问题清单 B-1～B-6、D-1～D-3、E-1～E-6（`6ece7e8`、`09936c7`、`f0dbb7c`）；阶段 1 后另测 B0 登记 | frontend-dev、prd-design 待测；指南待修订；测验容器与残留待收尾清理 |
| 2026-10-30 | 阶段 1 手动测验：frontend-dev、prd-design 与收尾 | F1/F2/F4/F7、P1/P2/P4/P7 均通过（F4、P1 附注）；问题清单新增 F-1～F-4、P-1～P-3、E-7～E-9，B-4 确认跨场景；沙箱统一关闭的决定与更正写入 1.2/3.1；收尾 env diff 只有 1.1 范围新增；3.5 阶段 1 小结；计划文件阶段 1 清单同步（`8f8e911`、`d70b231`、`aa9620e`） | B0 放到最后；指南待按 E-1～E-9 修订；`deploy/.env`、`eval-mysql`、`.remember/` 清理待用户决定；未推送 |
| 2026-10-30 | 阶段 1 梳理与指南修订 | 梳理问题与疑问 Q1～Q12 并由用户决定；指南修订 E-1～E-11（`save-run.sh` 检查会话已退出、清 `.remember/`，各项目关沙箱并停用 remember，P1 移出素材，8080 检查，提问框答法，docker 确认按 auto 模式）；基线撤回 B-3、补 B-1 实例、B-4 原因、skill 清单预算推测；计划改为只改场景层、汇总提前到阶段 2（`d2b129a`） | `save-run.sh` 会话拦截与项目层停用 remember 未实测；未推送 |
| 2026-11-02 | 本机 docker 误清恢复 | 用户执行 `docker system prune --volumes`，已停止容器与匿名卷被删、具名卷保留；从 `~/workspace/local-infra/` 重建 `fh-glitchtip-verify`、`fiberhouse-dev`，GlitchTip 数据核对仍在（1 用户、1 组织、1 项目、12 issue），两栈端点可达；之后用户手动 `docker rmi` 清理未用映像（剩 26 个、16.15GB），保留 `/cso` 11 个与 `mysql:8.0` 等 8 个；建置缓存未清。临时操作，不改变后续计划 | `eval-mysql` 阶段 3 前重建；两栈 20:23 起由用户手动停止 |
| 2026-11-02～03 | 阶段 2：预算核对与 S1～S3 补测 | prd-design 超预算证实（39312 > 30000 字符）；S1 无模板冲突，S2、S3 自然触发 pm-skills；基线 P-1、P-2 与指南更新，观察在专案集 `notes.md` | 见下一行 |
| 2026-11-03 | 阶段 2 调研与实施 | 预算实测：backend-dev 也超出（32978），frontend-dev、dev-ops 未超；更正基线把 backend-dev 记成 dev-ops 的错误；D-1、D-2、B-4、F-4、F-1 约定落场景层，frontend-dev 移除 sentry，prd-design、backend-dev 设 `skillListingBudgetFraction: 0.015`；不移除 pm-skills，gsd-core 暂缓；15 个测试文件全过 | 改动效果未验证（阶段 3）；`save-run.sh` 待换新版；调研子代理曾把 `CLAUDE_CODE_MESSAGING_TOKEN` 明文印进其会话记录（值未入库，处理由用户决定）；未推送。当时写「阶段 2 完成」不实，已更正 |
| 2026-11-03 | 全局规则修订 | 经两轮子代理交叉审核：`dot_claude/CLAUDE.md` 新增「范围与完成」，「资讯来源」补来源与验证边界，「弱网环境」改「网路」；轻量探测移到 `docs/plans/2026-11-03-weak-network-rule-backup.md`；同步 Codex 模板、README、`analyze-github-repo` 第 3 步；`AGENTS.md` 补未验证内容约束；计划与交接勾选更正，方案 B 登记 | 本机已套用；规则行为效果未测；未推送 |
| 2026-11-03 | 方案 B 与第二轮决策 | 调研见 `docs/research/2026-10-best-practices.md` 第 4 节、`docs/research/2026-11-plan-b-candidates.md`。实施：四个模板 `docker compose down` 列 ask（dev-ops 补 `docker-compose`）；删除类 docker 命令说明、插件冲突以项目为准、事故先取证、部署核对版本、PRD 假设与交接路径；MySQL ESR 规则修订（B-1）；FiberHouse 缓存落点（B-2，源码核对）；deny 范围说明；`test-install-settings` 改用只含插件的来源文件验证无警告 merge；15 个测试文件全过 | 未提交；行为效果待阶段 3；frontend-dev 现在要用 overwrite 才带 `permissions`；全局模板与本机的 `down` 放行未改 |
| 2026-11-03 | 阶段 2 未做项补做 | Reddit 按用户决定移除；Hacker News、dev-ops 仓库、Go 迁移工具（含 MySQL 实测）完成，报告在 `docs/research/2026-11-plan-b-reports/`；第三轮决策（第 30～39 条）见研究文档第 5 节 | 第三轮待用户确认、未实施；所有改动未提交；`mig-probe-net` 待用户手动删除 |
| 2026-11-03 | 第三轮决策实施 | 用户确认第 30～39 条照建议。`rules/database/mysql.md` 改第 47 行并加 4 条；`db-schema-design` 加 MySQL 迁移验证步骤、更正 `references/mysql.md` 改类型的 `INSTANT` 说法（两份同步）；dev-ops `incident-response-commander`、`security-engineer`、`devops-automator` 去 K8s，事故范本改 Compose 并先取证（两份同步）；`middleware-ops` 新增 `references/backup-restore.md` 与索引、description 加触发词（两份同步）；计划 3.3 加第 37 条指标；疑问清单第 12 条更新、新增第 16 条。实测：Compose 重建容器会丢日志、`--scale` 限制、`pg_dump` 隔离还原与冷备份卷摘要一致、Beszel 卷含私钥（`2026-11-plan-b-reports/compose-probe/`）；迁移实测脚本入库 `go-migrations-lab/` | 备份失败告警、Kuma 卷还原、离机与加密未实测（疑问清单第 16 条）；`bprobe-*` 与 `mig-probe-net` 清理被拒，待用户手动执行 |
| 2026-11-03 | MongoDB 场景案例 | 子代理调研电商、聊天、替代 MySQL（大厂一手资料只有 Coinbase；X 无可用内容），报告 `docs/research/2026-11-mongodb-cases.md`；MongoDB 8.0.34 副本集实测 T1～T8（脚本 `2026-11-plan-b-reports/mongo-lab/`）；独立子代理交叉审核更正 T2（超卖次数不定）、T5（漏读取决于页大小）并修订草案；用户确认后写入 `case-mongodb.md`、`mongodb.md` 三处、`SKILL.md` 索引（两份同步）与 rules 分页一句；疑问清单新增第 17 条（片键） | 不写入：前缀正则、片键、Discord 反例、SKU 拆分、选型信号；`mcase*` 容器清理被拒，待用户执行 |
| 2026-11-03 | 全局插件拆分与 myplugins | 分析全局插件用途与常驻成本（约 3.9k，拆 8 个省约 1.8k），独立子代理交叉审核；实现 `dot_claude/skills/myplugins/`（序号启用／关闭、本地或 `--shared`、清单增删、SessionStart 提示）与 `test-myplugins.sh`，16 个测试文件全过；临时项目实测提示输出、写入本地设定、新会话载入插件；发现沙箱拦写 `.claude/settings*.json`，以 `sandbox.excludedCommands` 解决 | 已提交 `47928a3`，未推送；本机安装延到阶段 3 结束后（用户决定）；会话内 `/reload-plugins`、提示显示、共享模式实机未验证 |
| 2026-11-03 | 阶段 3 准备步骤 | 指南新增第 12 节：新专案集重装、FiberHouse 固定阶段 1 提交、`eval-mysql` 重建、预算核对、旧专案集对照组只跑 B1/D3/F1（取代第 37 条「每次同跑基线」），计划文件同步（`871bf85`） | 12.1 命令试跑被权限拒绝、未实测；前端规划型任务卡待写 |
| 2026-11-04 | 阶段 3 行为验证 | 新专案集 16 个任务 + B1、D3、F1 同期对照（用户手动执行，Claude 按会话记录核对）；新增 F5 规划型任务卡；结论写入 `docs/evaluation/2026-10-final.md`：全部通过（6 个附注），B-4 改善在 B、D 可归因于配置、F1 不算，D-1/D-2/F-1/F-4/P-3/E-8/E-9 已解决，新问题 B-7～E-13，gsd-core 建议移出 | 已提交 `68e14a8`、`44c190a`、`398d2b5`，未推送；B2 r2、myplugins 安装、待确认项未做；local-infra 容器已由用户重建 |
| 2026-11-04 | B-7、B-8、B-10 与 B2 r2 | `db-schema-design` 验证限定一次性容器、改用 `SHOW CREATE TABLE`（一次性 MySQL 容器 4 情境实测，`f67e416`）；B2 r2 通过（无 deny、无残留）；B-10 行构造游标经 MySQL 8.0.46／8.4.10 复验后改写法（`9cb4a30`）；结论回填（`a1a548b`） | 未推送 |
| 2026-11-04 | myplugins 安装与调整、myconfig 提示 | 本机安装并同步镜像与模板（`5b5425d`）；按用户试用改默认写共享、`-t` 预演、提示文案与颜色（`f07a347`）、状态符号与表格（`33ec84d`）、清单 21 个与排序（`38ce0b5`、`d164e41`）、`sync`（`f5d3ad4`）、模板 21 个 `false`（`8c9a93a`）、`~` 路径排除规则（`claude -p` 实测，`ac254c2`）；myconfig 说明 `AGENT_RULES_REPO`（`21e78c6`）；本机设定与两个 skill 已同步；16 个测试文件全过 | 未推送；`/reload-plugins`、skill 表格与询问流程未实机验证 |
| 2026-11-04 | myplugins 减 token | 按会话记录与 API usage 拆解 `/myplugins` 的 token 来源（本身约 2.9k，其余为首轮系统附件与 `/context` 输出）；`SKILL.md` 拆出 `references/details.md`（2,746 → 1,655 字符），列表后只回「已启用」一行与用法，启动提示加 `!` 只看清单命令（`64ef966`）；本机副本已同步（`diff -r` 一致）；本仓库启用 claude-md-management、skill-creator（`2105be7`）；16 个测试文件全过 | 未推送；`-t` 询问流程未实机验证 |
| 2026-11-04～05 | 阶段 3 待确认项与 v2.5.0 | B-9 调研（12 个来源原文核对，标明中国大陆来源）后用户选方案 C：`layering.md` 契约类型分级、`go-new-module` 与 depguard `apivo-not-in-storage`（`078674c`）；D-4 同名 Compose 项目检查（Compose 5.5.0 实测，`250f03d`）；gsd-core 主场景改后端且默认不启用（`8c1da27`，本机 myconfig 已同步）；deny 改前缀 ask（`claude -p` 实测，`6416e56`，本机已改）；OpenSpec Corepack 修复（`node:22-alpine` 实测，`06b7902`）；删除 `docs/recommend_repos/`、`examples/`（`8eb2ef7`）；用户约束细化中国大陆来源与 Reddit 暂时移除；16 个测试文件全过 | 改本机 settings 前未另备份（与镜像一致，可从 git 还原）；`d4probe_data` 待用户删除 |
| 2026-11-05 | 3.2 静态验证与敏感读取 | 新增 `test-scenario-bundles.sh`（四场景真实安装、反向验证 6 处故障全部检出，`01a1b0f`）、`claude-config-smoke.sh`（`7b239a3`）、`permissions-smoke.sh`（36 条，`8f0029c`）；对照实验确认 RTK hook 使 `Read` deny 失效（上游源码只读 `Bash(...)` 规则），本机 RTK 加 `exclude_commands`；`Read` deny 扩充 20 条，`.env.example` 放行（逐条列变体，否定字符类与 allow 例外均实测无效），模板、镜像、本机三处同步（`76c6d27`）；记录子 shell 加外层重定向的缺口；17 个测试文件全过 | 未推送；子 shell 缺口是否回报上游待用户决定 |
| 2026-11-05 | myplugins、myconfig 未验证项实测 | `claude -p` + `--resume` 在 scratchpad 临时项目实测：myplugins `-t` 询问／确认／拒绝三条路径、共享模式同机双克隆载入均通过；myconfig 设计 §8 第 3～9、11 条全部通过（第 4、8、9 条附注，第 7 条为模拟失败），结果与新发现（plan 模式 `!` 注入被拒、技能退路有效）写入设计文件 §12；`mypilot` 改名 `mysession-eval`（`8ec5cbb`） | 用户决定：预演状态行已改、`cp` 矛盾改 SKILL.md、AskUserQuestion 先观察；本机两个 skill 副本已同步；互动模式未验证；未推送 |
| 2026-11-05 | 待决定事项处理 | 用户决定：本地提交、暂不推送；子 shell 缺口不回报上游；`claude plugin eval` 纳入计划 3.3 先小型试跑（方案与官方文档要点已写入，暂不执行）；交叉评审不做（计划「需要用户决定」已划掉） | 试跑待用户指示 |
| 2026-11-05 | 本机清理 | 盘点：疑问清单第六节所列旧残留（`grpclab-gomod`、`obs-net`、`mcp-gt`、`fegt-*`、`besz-net`、`rcase-*`、`mgv*`、`d4probe_data`、redis／bufbuild 映像）已不存在；按用户确认删除 `fiberhouse-example-dev`（`docker compose -p … down -v`：4 容器、网络、3 卷）、`scenario-eval-final/projects/dev-ops/deploy/.env`、`~/.claude/plans/` 3 个测试计划档；保留 `fiberhouse-dev`、`fh-glitchtip-verify`、`eval-mysql`（3.4 可能用到）、`golangci-lint` 映像 | — |
| 2026-11-05 | `mysession-eval` 决定 | 用户决定要做，暂不执行；计划 3.4 候选项改为已决定，作为 3.4 前置、取代手填日志模板；交接摘要、待处理、下一步同步 | 开工前确认初步设计 |
| 2026-11-05 | 取消 B0 | 用户取消「独立 Go 项目 `go get` FiberHouse 建第一个模块」单独测验；基线 1.2 局限说明保留并加注，交接移除待处理项 | 基线在框架仓库内测验的局限不再补测 |
| 2026-11-05 | myconfig 互动模式补测 | 用户在临时 Go 项目手动操作、按会话记录核对：选场景与确认均弹 AskUserQuestion，`!` 执行不受沙箱限制、写入 51 个文件、Claude 自动回报，`sleep 130` 不中断；RTK 对注入无影响；结果写入设计文件 §12 | 回报分类计数两次不准，是否改 SKILL.md 待用户决定；超过 130 秒未测 |
| 2026-11-05 | myconfig 回报只引用摘要数字 | SKILL.md 回报步骤加「数字只引用脚本摘要与标签行数，不自行按类别计数」；以 `claude -p --plugin-dir` 载入临时插件验证，回报只列类别名、数字取自摘要 | 本机副本已按用户指示同步（`diff -r` 一致） |
| 2026-11-05 | 新增 myopensupports 技能 | `list`／`install`（只印方案）／`remove`（`--apply` 才备份删除）／`add`／`sync`，仓库取自 `AGENT_RULES_REPO`；`scripts/tests/test-myopensupports.sh`；README、设计与计划文件 | 本机安装待用户 `cp`；疑问见设计文件「过程记录与疑问」 |
| 2026-11-05 | myopensupports 交叉审核 | 子代理审查 9 项（中 4、低 5）全部修正：`remove-apply` 独立子命令且不在 `allowed-tools`、搬移式备份、命令 `shlex.quote`、无默认参数不产生命令、`-n` 传 ost_ 名等；生成的 `--dry-run` 命令实跑通过 | `allowed-tools` 列表形式与 `remove *` 不匹配 `remove-apply` 未实测（设计文件 Q5） |
| 2026-11-05 | myopensupports 标示与本机安装 | INDEX 建议场景「不启用／暂不启用」标〔不启用〕、「不直接安装」标〔手动挑选〕，install 印注意（`68307d2`）；用户手动 `cp` 安装，会话即时识别技能 | Q3、Q5 待首次使用验证 |
| 2026-11-05 | 沙箱 `allowRead` 修正（test2 会话） | `.` 改 `~/.claude`，加 `~/workspace`、`~/.config/git/ignore`，`denyRead` 加 `~/workspace/documents`；镜像、模板与 README（`cb63add`） | `dot_claude_legacy/` 不改 |
| 2026-11-05 | myopensupports 只给 `!` 命令 | 因 `allowUnsandboxedCommands: false`，去掉「Claude 关闭沙箱执行」，Q3 结案（`fb1d0fd`） | 本机副本已同步；Q5 待首次使用验证 |
| 2026-11-05 | myopensupports 实测与回滚修正 | 临时项目走完 list／install 方案／`--skills-only`／remove／`remove-apply`；Q5 实测不跳权限提示（`autoAllowBashIfSandboxed`），文件改正；`remove-apply` 先搬 `skills/`、失败回滚并加测试（`bd1518e`） | 本机副本已同步；临时项目已删除 |
| 2026-11-05 | 推送 | 用户指示推送，`a569d97..9d43f5f` 共 40 笔推到 `origin/main` | — |
| 2026-11-05 | mysession-eval 设计 | 待验证项实测（会话 id 取 `CLAUDE_CODE_SESSION_ID`、`disable-model-invocation` 不占清单、`/clear` 换 id、`/compact` 不换、rule 加载记为 `nested_memory`）；与用户逐点确认后定稿并经建构者审阅（`1186eb1`、`25a3621`）；实作计划（`ab61619`） | — |
| 2026-11-05 | mysession-eval 实作 | 7 个任务（`bbd5712`～`a4ad205`）；整体审查 5 项重要问题修正（`ddad778`）；延后 4 项 minor 处理（`3844761`，第 4 项只能补文件说明）；本机安装与端到端实测（记录约 2.8k／含询问 4.7k、期中复盘约 8.9k）；`run-all.sh` 19 个全过 | 长会话与多记录未实测 |
| 2026-11-05 | 推送 | 用户指示推送，`fa1c8ef..68a54b9` 共 13 笔推到 `origin/main` | — |
| 2026-11-06 | claude-code-setup 补充调研与执行 | 四场景推荐汇总与决策表（`8bae224`）；MCP 写入防线（`56e94f4`）；agent 精简与三个审查 agent（`38dc553`、`68304c0`）；relay token 泄漏修正（`43eedcc`）；terraform 移出默认（`61c157b`）；计划勾选（`2207643`）；`run-all.sh` 19 个全过 | 3.4 试用；暂缓项见待处理 |
| 2026-11-06 | 推送 | 用户指示推送本批提交到 `origin/main` | — |
| 2026-11-06 | skill 编写约定与 myplugins 清单 | `skills/README.md` 新增「编写约定」（官方 best practices 原文 + 本仓库要求），交接加提醒；myplugins 默认清单 21 → 25（`plugin-dev`、`mcp-server-dev`、`mcp-apps`、`agent-sdk-dev`，全局模板与镜像各加 `false`）；`run-all.sh` 19 个全过 | 本机 myplugins 已 `cp` 并 `sync`（`diff -r` 一致，本机清单 25 个）；2026-11-06 用户指示推送 |
| 2026-11-06 | 发布 v2.6.0 | 按 `skills/skills-github-ops/github-release` 流程：annotated tag 推送、release notes 纯 ASCII 校验通过、`gh release create`；`gh release list` 显示 Latest | — |
| 2026-11-23 | /goal 冲突处理同步到仓库与 Codex | 本机 `~/.claude/CLAUDE.md` 已有、仓库 `dot_claude/CLAUDE.md` 缺的「/goal 冲突处理」补回；Codex 模板加改写版：Codex 无外部检查器，由模型以 `update_goal` 标 `blocked`（同一阻塞连续 3 个 goal 回合），去掉「检查器判定 Impossible」「系统上限结束」（依 openai/codex main 分支 `ext/goal/templates/goals/continuation.md`，已用本机 0.171.0 可执行文件核对一致）；`multi_client_support/README.md` 对照表、`dot_claude/README.md` 同步（`f3ae9ec`）；用户同意后执行 `codex.sh` 写入 `~/.codex/AGENTS.md`（备份 `AGENTS.md.bak.20261123-190639`，diff 只新增该段）；`run-all.sh` 19 个全过 | Codex 的 AGENTS.md 是否展开 `@` 导入未验证（会话记录显示 Codex 自行 `cat` RTK.md）；Codex 启用的 `gopls-lsp` 插件在 Codex 源码找不到 LSP 支持，用户决定保留 |
| 2026-11-23 | /goal Codex 版审计修正 | 子代理审计后修正：续行回合先确认阻塞是否仍在（避免用户解除禁令后仍只重述）；goal 因预算耗尽（`budget_limited`）停止时不调用 `update_goal`（与 Codex 内置规则一致）；对照表与变更日志改为「已用本机 0.171.0 可执行文件核对一致」；`dot_claude/README.md` 行数改约 60 行、合并清单补两个 `@memory` 导入；测试禁用词加「检查器」「Impossible」并断言模板含 /goal 段（`bcff9a7`）；`codex.sh` 重新写入（备份 `AGENTS.md.bak.20261123-221416`，diff 只改该行）；`run-all.sh` 19 个全过 | 无 |
| 2026-11-23 | 发布 v2.7.0 | 按用户指示推送 `main`（`eb97844..5a0c6d6`）；按 `skills/skills-github-ops/github-release` 流程：annotated tag `v2.7.0` 指向 `5a0c6d6` 并推送、release notes 纯 ASCII 校验通过、`gh release create`；`gh release list` 显示 Latest | — |
| 2026-11-27 | myhandoff 3.0.0（交接文件瘦身与分层） | 应 kap_llm_wiki 会话请求、经用户确认，实作其方案（`docs/superpowers/specs/2026-11-27-handoff-slimming-design.md`，b97f9e1）第 2–6 节：HANDOFF 必读在前加 `<!-- on-demand -->` 停止标记、gotchas 分核心约束／触发索引／未提交变更、新增 `GOTCHAS.md` 模板；SKILL 拆 `references/save.md`、`interrupt.md`；`handoff-check` 秘密扫描扩到 `docs/handoff/`、pre-commit 任何 `docs/handoff/` 文件触发、索引与 GOTCHAS 不一致 FAIL、大小格式只 WARN、`status` 三种中断判定；新增 `test-handoff-check.sh`（31 项）；`run-all.sh` 20 个全过（`e38c6c3`） | 安装到 `~/.claude/skills/myhandoff/` 与 `sync-codex` 被权限拒绝，待用户执行；本仓库 HANDOFF 仍是旧结构（check 只出 WARN），未迁移 |
| 2026-11-27 | myhandoff 3.0.1（秘密扫描漏带前缀的环境变量） | kap_llm_wiki 会话回报 `AWS_SECRET_ACCESS_KEY=` 抓不到，用户同意修：assigned secret 样式原以 `\b` 界定开头，`_` 后不成立；改为允许 `_`/`-` 结尾的前缀，新增 AWS secret 样式，排除 camelCase、`$VAR`/`${VAR}`、`process.env`、`YOUR_` 占位符；以仓库 507 个追踪文件比对新旧样式，交接文件无差异，残余误报只在 agents 范例代码；另修锚点与停止标记须单独成行（本文件变更日志里的行内 on-demand 标记曾被误认）；测试 40 项、`run-all.sh` 20 个全过（`ce982b2`）；用户执行安装与 `sync-codex`，两份副本已核对一致 | 残余误报：snake_case 的 token 键后接代码标识符（agents 范例代码，非交接文件） |
| 2026-11-27 | 本仓库 HANDOFF 迁移到 myhandoff 3.0.1 结构 | 摘要覆写为三行；当前状态、下一步只留未完成项；「续作时必须知道的事」分为 9 条核心约束与 `docs/handoff/GOTCHAS.md` G1～G30（触发索引 30 行）；变更日志移到本文件，「如何扩展」移到 `CONTRIBUTING.md`；`AGENTS.md` 改指向本文件；无其他去处的旧段落原样存档于下方 | 3.4 试用待用户指定 |
| 2026-11-27 | myhandoff 3.0.2（触发索引行数误计） | 迁移时发现模板自带的触发索引引导句被计入 30 行上限，写满 30 条即 WARN；改为只计列表项，测试补「30 条加引导句不警告」；`run-all.sh` 20 个全过；用户 rsync 同步本机与 Codex 副本，`diff -r` 一致 | — |
| 2026-11-27 | remember 改为可选插件 | 应 kap_llm_wiki 会话请求、经用户确认：`catalog.default.json` 在「通用」末尾加入 `remember`（序号 11），全局模板与镜像设为 `false`，两份 README 同步，`test-myplugins.sh` 序号更新；`run-all.sh` 20 个全过 | — （用户已同步 myplugins 副本并 `sync`，本机清单 remember 为序号 11「通用」；已全局停用，`~/.claude/settings.json` 核对为 `false`） |
| 2026-11-27 | myplugins 清单按分组上色；add 分组可见化 | `list` 输出到终端时，`@` 前的插件名与 `[分组]` 按分组上色（分组按首次出现顺序取色，10 色不含蓝与灰白，未分组 `-` 不上色；初版按名称 crc32 取色，经用户要求改为按分组），按可见宽度补齐、对齐不变；`NO_COLOR` 关闭，`--color` 或 `FORCE_COLOR` 强制开启。`add --category` 原已支持但未写进用法：补进 SKILL.md、`list` 用法行、`details.md`；有同分组时插到该组末尾。`test-myplugins.sh` 加 8 项；`run-all.sh` 20 个全过 | — （`!` 执行时默认无色码；用户实测 `--color` 在 `!` 下渲染成颜色，故启动提示的 `!` 命令改带 `--color`，`dot_claude/README.md`、`GOTCHAS.md` 同步；本机副本需再 rsync） |
| 2026-11-27 | 发布 v2.8.0 | 按用户指示推送 `main`（`8ba1147..d6d3fa1`）；annotated tag `v2.8.0` 指向 `d6d3fa1` 并推送；`gh release create`，`gh release list` 显示 Latest。偏差：发布前未先读 `skills/skills-github-ops/github-release`，notes 含 2 个非 ASCII 字（「通用」）就发布了；发现后改为英文、ASCII 校验 0、`gh release edit` 更新，线上 notes 复核 0 个非 ASCII | 下次发版先读该 skill |

## 2026-11-27 HANDOFF 迁移去处对照

旧文件为 `0cd368a` 的 `docs/handoff/HANDOFF.md`。

| 旧条目 | 去处 |
|---|---|
| 摘要（31 行历史进度） | 新摘要三行覆写；原文存档于下方「旧摘要」 |
| 当前状态表中已完成的行（数据库强化、教学材料、可观测性、场景配置评估、审查 agent、本机全局设定、myplugins、myopensupports、mysession-eval、myconfig） | 删出 HANDOFF；原文存档于下方「旧当前状态」 |
| 当前状态表中未完成的行（Go 参考实现、自定义 skill、analyze-github-repo 转 Codex、MVP 迁入 `src/`） | HANDOFF「当前状态」 |
| 待办计划阶段 1～3 勾选清单 | 权威版本在 `docs/plans/2026-10-20-scenario-config-evaluation-plan.md`；未完成项进 HANDOFF「当前状态」；副本存档于下方。注意：副本中阶段 2 四项为 `[x]`，计划文件中三项标「部分」，以计划文件为准 |
| 已完成内容：仓库定位、版本列表、技术栈决策 | 存档于下方；仓库定位与技术栈另见根目录 `README.md` |
| 已完成内容：四场景表、目录结构 | HANDOFF「已完成内容」精简为文件地图；四场景见根目录 `README.md`「四个场景」 |
| 本机执行 | HANDOFF「本机执行」（去掉指向变更日志的一句，补 smoke 重跑提示） |
| 用户约束表 9 行 | HANDOFF 核心约束；「场景包与各维度目录分开维护」也并入核心约束 |
| 安装顺序与 settings 覆盖 | G1 |
| 数据库 MCP 可写；场景 agent 节的「MCP 写入防线」 | G2 |
| Codex 模板需手动同步 | G3 |
| 2026-10-21 技术规范融入的改动范围；技术规范来源不入库 | G4（脱敏禁令另入核心约束） |
| 数据库设计强化 | G5 |
| MongoDB 规范的实测依据 | G6 |
| 教学材料沉淀 | G7 |
| path rules 的加载时机；mysession-eval 节的「rule 加载与 Bash 读档」 | G8 |
| FiberHouse 版本引用 | G9；旧「正确做法」写按 `v1.2.0` 引用，与 2026-10-26 去版本绑定矛盾，2026-11-27 grep 确认规则中已无 `v1.2.0`，按现状改写 |
| GlitchTip 与 Telegram 的坑 | G10 |
| 阶段 1 执行方式：核对方式；阶段 3 开头段；场景 agent 节「final 专案 tag 比较」 | G11 |
| 阶段 1：存档前确认退出、「保存」含义；阶段 3：回滚不清被忽略的文件 | G12 |
| 阶段 1：终端变量串场、沙箱关闭、remember、P1 素材、交互脚本外回答 | G13 |
| 阶段 1：权限前提 | G14 |
| 阶段 3：全局 deny 按字面拦整条命令 | G15（`Bash(env)` 推测另列 HANDOFF 待处理） |
| 阶段 3：depguard、Corepack | G16、G17 |
| 阶段 3：敏感读取两层防护、子 shell 重定向、`.env` 逐条 | G18 |
| 阶段 3：未信任的临时目录 | G19 |
| 阶段 3：compose 项目名撞名；阶段 1 环境中 `docker system prune`、`--no-build` 说明 | G20 |
| 阶段 3：本仓库会话的权限 | G21 |
| 沙箱 `allowRead` 的 `.`、`allowUnsandboxedCommands` | G22 |
| myplugins 全节 | G23；token 占用 → G24；「维护本仓库时」→ G27；未验证项与备份 → HANDOFF 待处理 |
| mysession-eval 全节 | G25（rule 加载一条 → G8） |
| 场景 agent：只放自写 agent、同步三处、子代理命令逐条 | G26 |
| 其他已知问题：第三方插件名离线校验、工作流框架重叠 | G28 |
| 其他已知问题：zsh glob、TypeScript LSP | G29、G30 |
| 其他已知问题：Codex `@` 引用（未验证） | HANDOFF 待处理 |
| 阶段 1、阶段 3「测验环境现状」 | 阶段 3 版本（较新）进 HANDOFF 待处理并标「未复查」；阶段 1 版本存档于下方 |
| 待处理事项表 | HANDOFF 待处理，指针改为 G<n> 或「文件＋节号」；myconfig 上线行（各项已实测通过）只存档 |
| 建议的下一步 | 未完成项（3.4、写 skill 提醒、RPC、plugin eval）进 HANDOFF；迁移计划本身已执行；全文存档于下方 |
| 如何扩展 | `CONTRIBUTING.md`「如何扩展」 |
| 变更日志 | 本文件开头的表格，原样 |

## 2026-11-27 迁移存档：旧 HANDOFF 原文

以下为迁移到 myhandoff 3.0.1 结构前 `docs/handoff/HANDOFF.md`（`0cd368a`）中没有其他去处的段落，原样保留，只作历史查阅；现状以 `docs/handoff/HANDOFF.md` 为准。

### 旧「摘要」

- 进度：仓库转型、四场景配置、安装脚本分工与场景包聚合、Codex 适配改造均已完成并提交，已推送并发布 v2.0.1（Latest）；「场景配置评估、优化与验证」进度见下方各行
- 停在：2026-10-24 可观测性按起步阶段重写（Uptime Kuma、GlitchTip、Beszel、Dozzle、Telegram 转发，`21a4c0f`）、移除 K8s 改围绕 Docker（`304865c`）、FiberHouse 错误经附加 writer 进入 GlitchTip（`405408c`；FiberHouse 分支 `feature/logger-extra-writers` 已推送，头 `39cba6c`）、sentry / grafana-mcp 插件改为 GlitchTip MCP（`288cda3`）；12 个测试文件全过
- 2026-10-26：FiberHouse 框架取舍 7 条已由用户在 FiberHouse 仓库实施并发布 `v1.2.0`，backend-dev `fiberhouse.md` 改为引用 v1.2.0，疑问文件第一节清空、前端错误送 GlitchTip 转为待办
- 2026-10-26（续）：前端错误送 GlitchTip 分析后暂缓；新增请求 id 传递约定；FiberHouse 规则去版本绑定（不再引用 v1.2.0）
- 2026-10-27：按用户指示推送 `main` 的全部累积提交，发布 v2.1.0（tag `3821dee`）
- 2026-10-27～28：阶段 1 审计简化并写成手动测验指南（`b305f5d`）；settings 插件池梳理（`81e2b10`）；支持包按主／第二场景划分、场景包 README（`cff9bfe`）；2026-10-28 已推送并发布 v2.2.0（Latest，tag `e4af50e`）
- 2026-10-28（续）：工作流框架分层定稿并实施（`5e3b6a3`、`eb7375a`、`5eb6078`，未推送）：gstack 外部检出 + `--prefix`、默认不注册 hook，`skillOverrides` 默认只手动调用、场景按需打开；mattpocock-skills 移出全局改为 prd-design、backend-dev 场景启用
- 2026-10-28：用户已在本机执行 `install-claude-project.sh -g`（gstack 64 个 skill 与 `skillOverrides` 64 项一致，task-master 0.43.1）；推送全部提交并发布 v2.3.0（Latest，tag `beb1ca8`）
- 之后升级 gstack（含 task-master）仍用 `sh scripts/install-claude-project.sh -g`，可先加 `-d` 预演
- 2026-10-29～30：**阶段 1 手动测验完成**。16 个任务通过 15、部分 1（D2），反向任务 B8/D7/F7/P7 全部符合；结果、问题清单（B-1～B-6、D-1～D-3、F-1～F-4、P-1～P-3、E-1～E-9）与 3.5 小结在 `docs/evaluation/2026-10-baseline.md`（`6ece7e8`、`09936c7`、`f0dbb7c`、`8f8e911`、`d70b231`、`aa9620e`）；收尾环境 diff 只有 1.1 范围内的新增
- 2026-10-30（续）：指南已按 E-1～E-11 修订，基线撤回 B-3、补 B-4 直接原因（auto 模式系统提示允许 Bash 改文件）与 skill 清单预算推测，阶段 2 决定登记进计划文件（`d2b129a`）
- 2026-11-02～03：阶段 2 第一步完成。prd-design skill 清单超预算已证实（39312 > 30000 字符，37 项只有名称）；补测 S1～S3 通过，第三方 skill 可被自然触发，预算不是未调用的主因（基线 P-1、P-2）
- 2026-11-03：阶段 2 **部分完成**：四场景预算实测、官方来源核对、第一轮决策已确认并实施（`69e10a6`～`4ecf882`，`docs/research/2026-10-best-practices.md`）；大厂、社区与场景对标未做。全局规则来源已修订（`dot_claude/CLAUDE.md`、Codex 模板）
- 2026-11-03（续）：方案 B 调研与第二轮决策（第 12～29 条）完成并经用户确认，改动已实施；结论见 `docs/research/2026-10-best-practices.md` 第 4 节
- 2026-11-03（续）：阶段 2 未做项补做（Reddit 已移除），第三轮决策第 30～39 条经用户确认并实施：MySQL 迁移规则与验证步骤、dev-ops 3 个 agent 去 K8s、`middleware-ops/references/backup-restore.md`（均有实测，见 `docs/research/2026-11-plan-b-reports/`）；未做项见研究文档 5.3
- 2026-11-03（续）：MongoDB 场景案例调研、8.0 副本集实测 T1～T8 与独立交叉审核后写入：新增 `db-schema-design/references/case-mongodb.md`，`mongodb.md` 补属性模式、分桶、分页索引三处，`rules/database/mongodb.md` 分页游标改为 `(排序键, _id)`；结论与不写入项见 `docs/research/2026-11-mongodb-cases.md`
- 2026-11-03（续）：全局插件分析与独立交叉审核后，新增全局技能 `myplugins`（`dot_claude/skills/myplugins/`，按序号把可选插件启用到当前项目，分本地／共享两层，清单可增删，SessionStart 提示）；测试通过、临时项目实测通过，已提交 `47928a3`（已随 v2.5.0 推送）；本机安装用户决定**延到阶段 3 结束后**（避免改变阶段 1 的全局插件条件）
- 2026-11-03～04：**阶段 3 行为验证完成**。16 个任务全部通过（6 个附注），B1、D3、F1 同期对照完成；结论 `docs/evaluation/2026-10-final.md`（`44c190a`、`398d2b5`），指南与计划更新 `68e14a8`；均未推送。新问题 B-7～E-13，gsd-core 建议移出 frontend-dev 默认清单
- 2026-11-04（续）：B-7、B-8 已修（`f67e416`），B2 r2 通过；B2 r2 发现并复验 B-10（行构造游标用不上索引，`9cb4a30`）；结论回填 `a1a548b`。myplugins 已在本机安装并按用户试用调整（默认写共享设定、`-t` 预演、21 个插件清单、`sync`、`~` 路径的沙箱排除规则，`5b5425d`～`ac254c2`）；myconfig 补 `AGENT_RULES_REPO` 提示（`21e78c6`）。已随 v2.5.0 推送
- 2026-11-04（续）：myplugins 减 token：`SKILL.md` 拆出 `references/details.md`，列表后只回「已启用」一行与用法，启动提示加第三行只看清单的 `!` 命令（`64ef966`）；本仓库 `.claude/settings.json` 启用 claude-md-management、skill-creator（`2105be7`）；实测 `/myplugins` 每次约 2.9k token，之前看到的一万多来自首轮系统附件与 `/context` 自身输出。已随 v2.5.0 推送
- 2026-11-04～05：阶段 3 待确认项全部处理：B-9 调研后用户选方案 C（`docs/research/2026-11-layering-strictness.md`，规则与 depguard `078674c`）；D-4（`250f03d`）；gsd-core 移出前端默认、主场景改后端且默认不启用（`8c1da27`）；全局 deny 改前缀 ask（`6416e56`，本机已同步）；OpenSpec 安装脚本 Corepack 卡住修复（`06b7902`）；删除 `docs/recommend_repos/`、`examples/`（`8eb2ef7`）；推送并发布 v2.5.0
- 2026-11-05：**3.2 静态验证完成**：`scripts/tests/test-scenario-bundles.sh`（四场景真实安装）、`scripts/smoke/claude-config-smoke.sh`（`claude mcp list`）、`scripts/smoke/permissions-smoke.sh`（36 条抽样）；实测发现 RTK hook 使 `Read` deny 在沙箱关闭时失效，已在本机 RTK 加 `exclude_commands`，`Read` deny 扩充 20 条（`.env` 系列、凭据、历史记录，`.env.example` 放行；`76c6d27`、`8f0029c`、`f2561b9`，未推送）
- 2026-11-05（续）：myplugins、myconfig 未验证项用 `claude -p` 与互动模式实测通过，myplugins 预演状态行、myconfig 补档 `cp` 例外与回报计数已修（本机副本已同步）；`claude plugin eval` 纳入计划 3.3 先小型试跑（暂不执行）；交叉评审不做、子 shell 缺口不回报、B0 取消；本机测验残留已清理。2026-11-05 用户指示推送，`origin/main` 已更新至 `9d43f5f`（含 myopensupports 与沙箱修正共 40 笔）
- 2026-11-05（续）：**`mysession-eval` 完成**：待验证项实测（`1186eb1`）→ 设计定稿 `docs/plans/2026-11-05-mysession-eval-design.md`（`25a3621`）→ 实作计划 `docs/plans/2026-11-05-mysession-eval-plan.md`（`ab61619`）→ 7 个任务实作、整体审查 5 项修正、4 项 minor 修正（`bbd5712`～`3844761`，已合并本地 `main`）；本机已安装（`~/.claude/skills/mysession-eval/`，`settings.json` 加 `excludedCommands`，备份 `.bak-20261105-mse`）；端到端实测 2 笔记录，用户决定保留作第一次小型试用（backend-dev 列入 1 笔）
- 2026-11-05～06：**claude-code-setup 补充调研完成**（四场景各跑一次推荐，汇总与执行结果 `docs/evaluation/2026-11-claude-code-setup-review.md`）。按用户逐项确认：数据库 MCP 写入加第二道防线（`56e94f4`）；移除 21 个通用人设 agent，改为自写只读审查 agent `go-reviewer`、`deploy-reviewer`、`prd-reviewer`（`38dc553`、`68304c0`，均用阶段 3 产出实测）；relay 示例 token 写进日志已修（`43eedcc`）；terraform 移出 dev-ops 默认（`61c157b`）；决策表 5～7 不做；`mysession-eval` 本机副本已同步（`diff -r` 一致）
- 2026-11-06（续）：`skills/README.md` 新增「编写约定」（官方 best practices），写 skill 前主动提醒；myplugins 默认清单 25 个，本机已 `sync`。观察到本机 `~/.claude/settings.json` 中 `gopls-lsp` 为全局 `true`（2026-11-06 00:02 修改，非本会话所改，来源未查，用户知悉）
- 2026-11-06：按用户指示发布 **v2.6.0**（Latest，tag 指向 `0277471`；自 v2.5.0 起 67 笔：审查 agent、MCP 写入防线、mysession-eval、myopensupports、relay 修正、3.2 静态验证）；release notes 注明移除 21 个 agent 属不兼容变更
- 2026-11-23：全局规则补回「/goal 冲突处理」并同步 Codex 模板（`f3ae9ec`），审计后修正续行与预算耗尽两处措辞（`bcff9a7`），已写入 `~/.codex/AGENTS.md`；按用户指示推送并发布 **v2.7.0**（Latest，tag 指向 `5a0c6d6`）
- 下一步：3.4 真实项目试用（用户指定场景与项目，在项目中做完一件事就 `/mysession-eval`；改动后可用对应审查 agent 复核）；2026-11-06 用户指示推送本批提交

接手前必读顺序：`AGENTS.md` → 本文件 → `docs/plans/2026-10-20-scenario-config-evaluation-plan.md`（执行计划时）→ 要改动的目录自己的 `README.md` → 根目录 `README.md`（设计原则与转型说明）。

### 旧「当前状态」（含阶段清单副本，权威版本在计划文件）

基础建设完成，进入「评估 → 调研 → 优化 → 验证」阶段。

| 任务 | 状态 | 说明 |
|---|---|---|
| **数据库设计强化（优先）** | 完成：MySQL（`d56306b`）、反面案例（`f91cd48`）、MongoDB（`3707f4f`） | 见「续作时必须知道的事」→「数据库设计强化」与「建议的下一步」 |
| 教学材料沉淀（gRPC、Go、Redis） | 完成，疑问已定稿 | `5098a4e`、`3c492ef`、`9bddf11`；疑问见 `docs/plans/2026-10-22-learning-distill-questions.md` |
| backend-dev Go 参考实现 | **进行中** | 第一批 `7b7ef74`；存储与中间件规范 `2ac1c49`；gRPC 规范 `5098a4e`（来自教学材料，用户企业 RPC 规范若有再补） |
| 可观测性重写与 FiberHouse 错误追踪 | 完成；框架取舍已决定（FiberHouse `v1.2.0`） | `docs/plans/2026-10-22-learning-distill-questions.md` 第三节「FiberHouse 框架取舍」 |
| 场景配置评估、优化与验证 | **阶段 1 完成、指南已修订（2026-10-30）**，阶段 2 完成（2026-11-03，范围按方案 B；未做项见研究文档 4.3），**阶段 3 行为验证完成（2026-11-04）**，B2 r2 通过（2026-11-04）；静态验证完成（2026-11-05）；真实项目试用未做；B0 用户 2026-11-05 取消 | 2026-10-27 审计简化：16 个任务、交互模式手动执行，见 `docs/evaluation/2026-10-baseline.md` 第 1 节与 `docs/evaluation/manual-test-guide.md`；计划文件开头「审计结论」优先于下方原清单 |
| 场景审查 agent | 完成（2026-11-06）：`go-reviewer`、`deploy-reviewer`、`prd-reviewer`，frontend-dev 暂不设 | `agents/README.md`；见「续作时必须知道的事」→「场景 agent」 |
| 四个场景的自定义 skill | 待开始（claude-code-setup 的新能力候选已并入，见汇总文件 3.6） | `backend-dev` 已有 `go-new-module`；其余 `skills/skills-<FLAG>/` 目前只有占位；例如 PRD 模板、API 契约、上线检查清单。建议在阶段 2 调研后再写 |
| `dot_claude/commands/analyze-github-repo.md` 转 Codex skill | 待开始 | Codex custom prompts 已于 2026-01 弃用；装到 `~/.agents/skills` |
| 本机采用新全局设定 | 完成（2026-10-28） | 本机已对齐：插件统一 `@claude-plugins-official`（`--replace` 切换、删除 `claude-code-plugins` 市场）、删除 `kubectl get/describe` 放行、停用 `playground`；刻意保留全局启用 `frontend-design`、`chrome-devtools-mcp`（临时项目用），记录于 `settings/README.md`；`dot_claude/settings.json` 镜像已同步 |
| 可选插件技能 `myplugins` | 已实现、本机已安装并按用户试用调整（2026-11-04，`5b5425d`～`ac254c2`、`64ef966`，已随 v2.5.0 推送）；2026-11-05 `-t` 与共享模式实测、预演状态行修改（`9bbddda`，2026-11-05 已推送） | 见「续作时必须知道的事」→「myplugins」；安装步骤在 `dot_claude/README.md`「myplugins 安装」 |
| 支持包技能 `myopensupports` | 已实现、测试通过、交叉审核已处理（2026-11-05）；用户手动 `cp` 安装后又改了 SKILL.md、details.md（`fb1d0fd`：去掉「Claude 关闭沙箱执行」，安装与 `remove-apply` 只给 `!` 命令），临时项目实测通过（2026-11-05）；Q5 实测：`autoAllowBashIfSandboxed` 下 `remove-apply` 不跳权限提示，文件已改、`remove-apply` 改为先搬 `skills/` 且失败回滚（`bd1518e`），本机副本已同步（`diff -r` 一致）；临时项目 `~/workspace/tmp-mos-test` 已由用户删除 | `dot_claude/skills/myopensupports/`；设计与疑问 `docs/plans/2026-11-05-myopensupports-design.md`，计划 `docs/plans/2026-11-05-myopensupports-plan.md` |
| 试用评估技能 `mysession-eval` | 完成（2026-11-05）：已实作、测试 65 例、整体审查、本机安装、端到端实测；已合并并推送 | `dot_claude/skills/mysession-eval/`；设计 `docs/plans/2026-11-05-mysession-eval-design.md`，计划 `docs/plans/2026-11-05-mysession-eval-plan.md`；见「续作时必须知道的事」→「mysession-eval」 |
| 技能与工具包管理平台 MVP 迁入 `src/` | 待开始 | 根目录 `README.md` Roadmap |
| 配置安装技能 `myconfig`（列出／安装本仓库配置） | 已实现并发布 v2.4.0（2026-10-29）；用户已在本机安装，`/myconfig` 列表模式正常 | `dot_claude/skills/myconfig/`；设计 `docs/plans/2026-10-28-config-install-skill-design.md` §11。`claude -p` 实测：沙箱禁止会话内写 `.claude/settings.json`、`skills/`、`hooks/`，改为技能只预演、写入交付命令由用户执行；跨项目使用需把仓库路径与 `~/.claude/skills/myconfig` 加进 `sandbox.filesystem.allowRead`；两轮子代理交叉审查意见已全部处理 |

#### 待办计划：场景配置评估、优化与验证

计划文件：`docs/plans/2026-10-20-scenario-config-evaluation-plan.md`（评估对象表、7 个评估维度、调研来源分级、标准任务示例、判定标准、执行顺序图）。完成一项就在此勾选，并在计划文件同步。

**阶段 1：现状评估**（产出 `docs/evaluation/2026-10-baseline.md`）

- [x] 为四个场景写「典型任务清单」：审计后为每场景 3 个 ★ 任务 + 1 个反向任务（`docs/evaluation/2026-10-baseline.md` 第 2 节）
- [x] 用户按手动测验指南执行 T1～T4，Claude 汇总回填第 3 节（2026-10-30 全部完成，含 3.5 小结；以下各项按审计结论并入或推迟，计划文件 1.3 已同步）
- [x] 在临时项目安装每个场景包（`install-claude-project.sh -f <FLAG> -t <tmp> -N`），用 `/context` 记录各项常驻上下文占用
- [ ] 汇总全局 + 场景启用后的全部 skill / agent / MCP 工具，按功能归类，标出重复与冲突（辅以 `/doctor prompt-audit`）——2026-10-30 改为阶段 2 处理
- [x] 实测 permissions：B8（deny 拦截）、D2（`docker compose up` 在 auto 模式下仍弹确认）；terraform 未涉及
- [x] 核对第三方市场插件名（`document-skills@anthropic-agent-skills`、pm-skills）
- [ ] ~~对比场景包与各维度目录的差异~~（取消）
- [ ] 评估 fullstack-dev 是否需要场景包（推迟）

**阶段 2：外部最佳实践调研**（产出 `docs/research/2026-10-best-practices.md`）

- [x] （2026-11-03，范围按方案 B；Reddit、Hacker News 与个别来源未做，见研究文档 4.3）按来源分级（A 官方 / B 大厂 / C 社区）调研全局、四个场景、横向主题与 Codex 的问题；每条记录来源、日期、原文核对结论、适用场景、收益与成本；二手转述标「未验证」
- [x] 形成「建议 → 阶段 1 问题」映射，无对应问题的列为「新增能力」
- [x] （两轮均已确认）输出采纳决策表（采纳 / 暂缓 / 不采纳 + 理由），**提交用户确认**
- [x] （第二轮改动未提交）按确认结果实施，按主题拆分提交，每次提交前跑 `run-all.sh`

**阶段 3：最终版验证**（产出 `docs/evaluation/2026-10-final.md`）

- [x] （2026-11-05，见 `docs/evaluation/2026-10-final.md` 第 5 节）安装与静态验证：扩展 `scripts/tests/`；临时项目中 `claude mcp list` 等只读 smoke；permissions 实测脚本
- [x] 行为验证：按审计结论改为交互模式手动执行，16 个任务 + B1、D3、F1 同期对照（2026-11-04 完成，`docs/evaluation/2026-10-final.md`）；交叉评审（盲评、`/code-review`、Codex 对比等）未做，属选做
- [ ] 真实项目试用：每场景一个用户指定的项目；试用记录由 `mysession-eval` 产生（2026-11-05 已完成并安装；已有 1 笔 backend-dev 列入判定的小型试用）；复盘时机由用户决定（多次期中 + 一次最终），最终复盘结论写回 `docs/evaluation/2026-10-final.md`
- [ ] 按「通过 / 调整 / 移除」判定，稳定结论回写本文件、`scripts/tests/`、对应 README

### 旧「已完成内容」中的仓库定位、版本与技术栈决策

**仓库定位**：个人 Agent 配置与工具／技能管理仓库（Claude Code 为主，兼顾 Codex），公开供参考。2026-10-19 从「分层提示词规则系统」转型而来，设计原则与原因见根目录 `README.md`。

**版本**：`main` 已于 2026-10-28 推送至 `origin/main`（之后的新提交推送仍需用户指示）；GitHub release v2.0.0（tag `a0783b3`）、v2.0.1（tag `6a31aee`）、v2.1.0（tag `3821dee`）、v2.2.0（tag `e4af50e`）、v2.3.0（tag `beb1ca8`）、v2.4.0（tag `d68370c`）、v2.5.0、v2.6.0（2026-11-06，tag 指向 `0277471`）、v2.7.0（2026-11-23，tag 指向 `5a0c6d6`）、v2.8.0（Latest，2026-11-27，tag 指向 `d6d3fa1`）。GitHub 仓库描述与 topics 已改为个人开发者工具定位。
**已确认的技术栈决策**：后端 Go、Node.js / TypeScript；数据库以 MongoDB、Redis、MySQL 为主，兼容 PostgreSQL；部署围绕 Docker / Docker Compose（2026-10-23 去掉 K8s）；可观测性起步阶段用 Uptime Kuma、GlitchTip、Beszel、Dozzle，告警只发 Telegram，升级路径为 Prometheus + Alertmanager；PRD 以 pm-skills、mattpocock-skills、gstack 等技能为主；**规格框架按场景启用**（2026-10-28 改：全局 superpowers；后端清单默认启用 OpenSpec、前端清单默认启用 gsd-core，同一项目只启用一套；支持包按主场景启用、第二场景注释录入，见 `open_supports/INDEX.md`「建议场景」）；全局工具 task-master（只装 CLI，不注册 MCP）、gstack（2026-10-28：gstack 以 `--prefix` 安装，`skillOverrides` 默认只能手动调用、场景按需打开；mattpocock-skills 移出全局，改在 prd-design、backend-dev 场景启用，见 `settings/README.md`「工作流框架分层」）；记忆类只保留 `remember`，cognee 暂不启用。

### 旧「测验环境现状」（阶段 1 版本，已被阶段 3 版本取代）

- **测验环境现状**：
  - 容器 `eval-mysql`（只读账号，连接变量在专案集 `mysql.env`，600）；收尾时用户手动删除
  - backend-dev 已 `codegraph init`（`.codegraph/` 被 git 忽略，`save-run.sh` 不清除）；B1 时尚无索引
  - dev-ops：baseline 重打为 `2559f78`（`.mcp.json` 的 glitchtip 加默认地址 `localhost:18000`）；`settings.local.json` 关闭沙箱（用户决定 dev-ops 全程维持关闭）；`deploy/` 下残留被忽略的 `.env`，收尾清理
  - D2 部署 `fiberhouse-dev`（app、mysql、redis、mongodb）保留后用，设定文件已导出到 `~/workspace/local-infra/fiberhouse-dev/deploy/`，app 占 `127.0.0.1:8080`；2026-11-02 误清后用 `docker compose up -d --no-build` 重建（建置上下文没有源码，不能 `--build`），当日 20:23 起已停止，需要时 `docker compose start`；停止状态下 `docker system prune` 会再次删除容器（数据卷保留）；本机 GlitchTip 在 `~/workspace/local-infra/glitchtip/`，已开 MCP
  - 收尾待用户处理：`eval-mysql` 已于 2026-11-02 被 `docker system prune --volumes` 删除（没有 compose、没有具名卷，原为空库），阶段 3 前按 `mysql:8.0`、`127.0.0.1:3306`、空库 `evaldb`、只读账号 `eval_ro` 重建；dev-ops `deploy/.env`（D2 随机密码）建议删除；`fh-glitchtip-verify-*` 3 个容器 2026-11-02 已从 `~/workspace/local-infra/glitchtip/` 重建，当日 20:23 起已停止，数据卷保留；全局 deny 拦 `docker rm`，删除由用户执行
  - Node.js 已升级到 22.23.4（此前每个会话首次 Bash 会被 CVE hook 挡一次）

### 旧「建议的下一步」

**本仓库 HANDOFF 迁移到 myhandoff 3.0.1 结构（下一个会话的第一件事；用户 2026-11-27 已同意）**：在新会话执行，不在做 3.0 实作的会话里做（上下文太重）。

1. 依 `~/.claude/skills/myhandoff/references/save.md` 的覆写与删除规则迁移本文件：摘要覆写成三行；当前状态与下一步只留未完成项；「续作时必须知道的事」21 条分类为核心约束（≤ 10 行附来源）与 `docs/handoff/GOTCHAS.md`（`### G<n>` 加触发索引行）；先搬再删，commit 用 `git cat-file -e`、节号用 grep 核对，「未验证」片段先搬到待处理，无其他来源的只搬不删。结构照 `templates/HANDOFF.md`（`<!-- on-demand -->` 停止标记、`<!-- block: core|triggers|uncommitted -->`）
2. **用户已决定**：「变更日志」整节原样移到 `docs/handoff/CHANGELOG.md`；`AGENTS.md` 第 5 行改为 change log 追加到 `docs/handoff/CHANGELOG.md`（不再写在 HANDOFF 里）。「如何扩展」一节移到合适的文件（如 `README.md`），记录去处
3. 写一张去处对照表（旧文件每个条目与任务行各自移到哪里：核心／GOTCHAS／CHANGELOG／其他文件／删除及理由），放在 `docs/handoff/CHANGELOG.md` 本次条目或提交信息中
4. `handoff-check check` 通过且无大小 WARN（目标 HANDOFF ≤ 8,000 字元），交接相关文件单独提交；`AGENTS.md` 的改动属入口文件，可同一提交。参考先例：kap_llm_wiki 的迁移（`a23cb01`、`5269bba`）与方案第 7 节

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

2026-10-30 进度：**阶段 1 全部完成**（16 个任务、收尾 diff、基线 3.5 小结、计划文件同步）。续作顺序：

1. ~~按 E-1～E-11 修订指南~~：已完成（`d2b129a`）
2. 阶段 2（计划文件 2.3）：先在 prd-design 用 `claude --debug` 看 skill 清单是否超出预算（P-2）；补测 2～3 个应触发 skill 的任务，其一用 P2 素材强制 `/create-prd` 与 `CLAUDE.md` 8 项盲比（P-1）；汇总各场景 skill/agent/MCP；再按 3.4 调研，优先 D-1、B-4、F-3/P-2、F-4、P-1，产出采纳决策表交用户确认。已定方向：只改场景层；B-4 先在四个场景 `CLAUDE.md` 各加一行「改代码与配置一律用 Edit/Write」，阶段 3 仍绕过再加 hook；F-2 由 F-1（`.playwright-mcp/` 进 `.gitignore`）消除；B-5 不处理；frontend-dev 移除 sentry
3. ~~最后：单独测 B0（独立 Go 项目 `go get` FiberHouse 建第一个模块）~~：用户 2026-11-05 取消

前置条件：阶段 1 已完成；收尾的容器与 `.env` 清理由用户决定，不阻塞阶段 2。

下次开工第一步：

1. 本机规则已于 2026-11-03 套用（`~/.claude/CLAUDE.md` 手动合并，备份 `.bak-20261103023211`；`~/.codex/AGENTS.md` 首次写入区块，备份 `.bak.20261103-023237`；已记入测验 `notes.md`）。新会话小测验两个都通过（`/tmp/rule-test`，各 1 次，无旧规则对照；缩范围测验把「仅读摘要」的社区来源标成已做，应标部分）。子代理：旧会话派出的子代理实测仍拿到旧规则；Explore、Plan 不载入 `CLAUDE.md`，派它们要在指令里重申；新会话一般子代理是否载入新规则待按会话记录确认
2. 方案 B 已完成（2026-11-03），决策与未做项见 `docs/research/2026-10-best-practices.md` 第 4 节
3. ~~阶段 3 行为验证~~：已完成（2026-11-04），结论 `docs/evaluation/2026-10-final.md`
4. ~~修 B-7、B-8~~、~~重跑 B2 r2~~、~~安装 myplugins~~：2026-11-04 完成（另修 B-10）
5～9. ~~B-9、D-4、gsd-core、deny 改 ask、推送与 release、OpenSpec Corepack~~：2026-11-04～05 全部完成（见摘要与变更日志）
10. **排期**：~~3.2 静态验证~~（2026-11-05 完成；改了 `permissions`、沙箱、RTK 或升级 Claude Code 后按 `scripts/smoke/README.md` 重跑）、~~`mysession-eval`~~（2026-11-05 完成）、**3.4 真实项目试用**（下一个：用户指定 1～2 个场景与项目，在项目中做完一件事就 `/mysession-eval`，`/mysession-eval review` 期中复盘，结束时 `review --final`）；~~B0~~（用户 2026-11-05 取消）

前置条件：3.4 需用户指定场景与项目；`mysession-eval` 已就绪。

写场景自定义 skill（11 项候选，汇总文件 3.6）时：先读 `skills/README.md`「编写约定」，按「找缺口 → 3 个评估情境 → 最少内容 → 新会话实测」进行；Claude 在开始前主动提醒用户这条约定。

等用户指示再做：推送与 release。

杂项（低优先，用户 2026-11-05 从「等用户指示」移到最后，排在其他长期任务之后）：`claude plugin eval` 小型试跑（计划 3.3「插件级评估」，必须加 `--no-publish`）。

仍未验证（需互动会话或另一台机器）：myplugins 共享模式的信任对话框与未安装插件的机器（官方说项目层插件须过信任检查、`-p` 不够，与同机 `-p` 结果不符）；myconfig 超过 130 秒的 `!` 命令。

---

### 旧「待处理事项」表（原样）

| 项目 | 位置 |
|---|---|
| 各场景用于试用的真实项目、试用期长度：阶段 3 后由用户试用后决定（建议先 1～2 个场景、按会话次数计） | 计划文件「需要用户决定」 |
| 教学材料沉淀的已完成项、1 项暂缓（前端 GlitchTip）、17 条待验证与本机 docker 残留清理 | `docs/plans/2026-10-22-learning-distill-questions.md` |
| 阶段 2 未做项（取不到原文、未读、未实测）与第三轮留下的待验证（疑问清单第 12、16 条） | `docs/research/2026-10-best-practices.md` 5.3、`docs/plans/2026-10-22-learning-distill-questions.md` |
| myconfig 上线前：本机安装（`install.sh` 复制或符号链接）、`AGENT_RULES_REPO`、沙箱 `allowRead`（2026-10-29 已加 `~/workspace/github_repos`、`~/.claude/skills/myconfig`，保留 `denyRead ~/`；新会话实测可读仓库）；§8 第 3～9、11 条已于 2026-11-05 用 `claude -p` 实测通过（附注与新发现见设计文件 §12）；第 8 条矛盾已按用户决定改 SKILL.md（陷阱条目指明的补档 `cp` 可并入交付命令，技能自己不执行）；互动模式补测（2026-11-05）通过：第 9 条在互动模式会先问场景（`-p` 所致）、确认框正常、`!` 不受沙箱限制且 130 秒不中断、RTK 对注入无影响；回报分类计数不准已按用户决定改 SKILL.md（只引用脚本摘要数字，`--plugin-dir` 验证有效）；本机副本已同步 | 设计文件 §8、§11、§12 |
| 杂项（低优先，用户 2026-11-05 移到最后）：`claude plugin eval` 小型试跑（myconfig 5 句触发评估；必须加 `--no-publish`） | 计划文件 3.3「插件级评估」 |
| myplugins：互动模式信任对话框、另一台机器未验证（本机两个 skill 副本已于 2026-11-05 按用户指示同步，`diff -r` 一致） | 本文件「myplugins」 |
| FiberHouse 示例 `repository.CreateExample` 接收 `requestvo`（框架自注临时兼容），会被新 depguard 规则拦；用户 2026-11-05 决定暂不处理 | `docs/research/2026-11-layering-strictness.md` 第 6 节 |
| 本机：映像 `golangci/golangci-lint:v2.5.0`、`node:22-alpine` 为实测拉取，可保留（D-4 实测卷已由用户删除）；2026-11-05 改了 `~/.claude/settings.json`（备份 `.bak-20261105012410`）并新建 RTK `config.toml` | — |
| **写场景自定义 skill 前（提醒）**：先按 `skills/README.md`「编写约定」（官方 best practices：先找缺口与写 3 个评估情境再写、写与测分开、description 第三人称、正文 ≤ 500 行、参考文件只往下一层），起草可用 `skill-creator`；开始任何 skill 编写时由 Claude 主动提醒 | `skills/README.md`；官方 platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices |
| claude-code-setup 汇总的暂缓项：新 skill／agent／permissions 候选（3.6）、frontend-dev 审查 agent（3.4 出现需求再写）、全局 GitHub MCP `actions` toolset（本机配置，需用户指示） | `docs/evaluation/2026-11-claude-code-setup-review.md` 第 3.6、4、6 节 |
| 3.4 真实项目试用：用户指定场景与项目；`mysession-eval` 长会话、多记录时的 `extract`／`summarize` 输出量未实测（只测过小会话 2 笔） | 计划文件 3.4；设计文件「token 预算」 |
