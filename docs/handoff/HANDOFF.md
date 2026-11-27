---
branch: main
head: 9b5b76a
status: active
updated: 2026-11-27
---
# 进度交接

本文件记录仓库当前状态与续作指引，供 Claude Code、Codex 或协作者接手，也用于同一客户端清空会话后的续作。接手时读到「以下按需查阅」为止；陷阱细节在 `docs/handoff/GOTCHAS.md`，按触发索引查阅，不整份读。变更日志在 `docs/handoff/CHANGELOG.md`。

<!-- section: summary -->
## 摘要

- 进度：四场景配置、评估阶段 1～3 与静态验证、myhandoff 3.0.1 均已完成；2026-11-27 本文件迁移到 myhandoff 3.0.1 结构
- 停在：迁移提交之后；`main` 有未推送提交（推送与 release 等用户指示）
- 第一件事：请用户指定 3.4 真实项目试用的场景与项目

<!-- section: status -->
## 当前状态

| 任务 | 状态 | 说明 |
|---|---|---|
| 3.4 真实项目试用 | 待开始 | 等用户指定 1～2 个场景与项目；`mysession-eval` 已就绪；计划文件 3.4 |
| 3.4 后的「通过／调整／移除」判定 | 待开始 | 结论回写 `docs/evaluation/2026-10-final.md`、`scripts/tests/`、对应 README |
| backend-dev Go 参考实现 | 进行中 | 三批已完成（`7b7ef74`、`2ac1c49`、`4d611a6`）；RPC 规范等用户下一批（gRPC 教材版 `5098a4e` 已入库） |
| 四场景自定义 skill | 待开始 | 11 项候选见 `docs/evaluation/2026-11-claude-code-setup-review.md` 3.6；`skills/skills-<FLAG>/` 除 backend-dev 外为占位 |
| `dot_claude/commands/analyze-github-repo.md` 转 Codex skill | 待开始 | Codex custom prompts 已于 2026-01 弃用；装到 `~/.agents/skills` |
| 技能与工具包管理平台 MVP 迁入 `src/` | 待开始 | 根目录 `README.md` Roadmap |
| 阶段 1 遗留：skill/agent/MCP 汇总；fullstack-dev 场景包 | 延后 | `docs/plans/2026-10-20-scenario-config-evaluation-plan.md` 阶段 1 清单 |
| HANDOFF 迁移到 3.0.1 结构 | 完成，待用户核对 | 去处对照见 `docs/handoff/CHANGELOG.md` |

<!-- section: next -->
## 建议的下一步

1. 3.4 真实项目试用：用户指定场景与项目后，在项目中做完一件事就 `/mysession-eval`，期中 `/mysession-eval review`，结束 `review --final`；改动后可用对应审查 agent 复核（相关：G11、G25、G26）
2. 写场景自定义 skill 时，开始前主动提醒用户 `skills/README.md`「编写约定」：找缺口 → 3 个评估情境 → 最少内容 → 新会话实测（相关：G27）
3. 用户提供 RPC 规范后补 backend-dev（相关：G4、G8）
4. 杂项（低优先）：`claude plugin eval` 小型试跑，必须加 `--no-publish`；计划文件 3.3（相关：无）

<!-- section: gotchas -->
## 续作时必须知道的事

<!-- block: core -->
### 核心约束

- 只修改本仓库；`~/.claude/`、`~/.codex/` 等本机文件只读，除非用户明确指示（来源：`AGENTS.md` 第 5 行，用户约束 2026-10-20）
- 涉及取舍先列方案与理由，用户确认后再实现；提交需用户确认，推送与 release 需用户明确指示（来源：用户约束 2026-10-20）
- 测试一律在临时目录或 scratchpad，不对真实配置测试（来源：`AGENTS.md`「Testing Guidelines」）
- `dot_claude_projects/`、`skills/`、`claude_mds/` 每条结论须有实测或一手来源，否则记入 `docs/plans/` 待验证清单（来源：`AGENTS.md`「Unverified Content」，用户 2026-10-23）
- 中国大陆闭源工具与应用严禁（如飞书、钉钉、阿里云、腾讯云）；已开源的纯技术库可参考但倾向不采用，引用须标明来源，需取舍时问用户（来源：用户 2026-11-04）
- 仓库公开：技术规范与教材源文件（`~/workspace/documents/`）不入库、不引用其路径，入库前去除企业元素（来源：用户 2026-10-21；细节 G4）
- 调研来源暂不含 Reddit（未登录访问被拦），找到可行访问方式后再纳入（来源：用户 2026-11-03）
- 场景包 `dot_claude_projects/.claude-<FLAG>/` 与各维度目录分开维护，不加自动同步或一致性测试；要一致时手动复制并在提交说明写明（来源：用户 2026-10-20，2026-10-28 对齐过一次）
- 沟通用繁体中文；`dot_claude/` 与 Codex 模板为繁体中文；其他仓库文档为简体中文（来源：用户约束、`AGENTS.md`）

<!-- block: triggers -->
### 触发索引

开始任何子任务前，比对这次要做的动作；命中就先读 `docs/handoff/GOTCHAS.md` 对应条目。

- 单独重装 settings → 之后重跑 `install-open-supports.sh -t`，或用 `-m merge` → G1
- 配数据库或 Mongo MCP → 只读账号、只连测试库，`env` 与 deny／ask 两层 → G2
- 改 `dot_claude/CLAUDE.md` → 同步 Codex 模板 `AGENTS.codex-user.md` → G3
- 补充技术规范 → 照既定文件分布放置，脱敏后用关键词清单扫描 → G4
- 改 MySQL 规则或引用数据库教材 → 先分来源等级，存疑就用临时容器实测 → G5
- 改 MongoDB 规范 → 先查 `references/mongodb.md` 实测表，用 mongo-driver v2 → G6
- 引用 Go／Redis／gRPC 教材结论 → 先查各 skill references 实测表，注意版本上限 → G7
- 写 path rule → 动手前必须知道的写进 `CLAUDE.md` 或 skill，lint 兜底 → G8
- 改 FiberHouse 相关规则 → 先核对 FiberHouse 提交，不绑版本 → G9
- 部署 GlitchTip 与 Telegram 告警 → 同网络设 `GLITCHTIP_ALLOW_PRIVATE_IPS`，MCP 需 https 域名 → G10
- 核对测验或试用结果 → 以会话记录 jsonl 为准，不以回复自述为准 → G11
- 测验存档 → 先确认会话已退出，再 `save-run.sh` 并写 `notes.md` → G12
- 准备测验会话 → 换终端防变量串场、关沙箱、停用 remember → G13
- 判定是否弹权限确认 → 按会话记录实际情况，不按指南预设 → G14
- 命令或说明含被 deny 的字样 → 避开这些词 → G15
- 写 depguard 规则 → `pkg` 写 `<module>/apivo` 前缀 → G16
- 用 Corepack 查 pnpm／yarn 路径 → 加 `COREPACK_ENABLE_NETWORK=0` → G17
- 新增 Read deny 或验证读取规则 → 同步 RTK `exclude_commands`，看内容是否外泄 → G18
- 用 `claude -p` 测项目层 allow → 改用 `--allowedTools` → G19
- 起新 compose 项目 → 先按项目名查已有卷与停止的容器 → G20
- 在本仓库会话做 DROP、`rm -rf`、`docker rm` → 给用户 `!` 命令 → G21
- 改沙箱路径或技能要写受保护路径 → `.` 解析为 `~/.claude`；只能给 `!` 或 `excludedCommands` → G22
- 改 myplugins → 命令三处一致写 `~` 路径，照用户定的行为约定 → G23
- 测量某操作的 token 成本 → 看 API usage 或 `/context` 差值扣约 5.5k → G24
- 改 mysession-eval → 请用户 `cp -R` 同步本机副本并 `diff -r` → G25
- 新增或修改场景 agent → 只放自写只读审查 agent，同步三处 → G26
- 维护本仓库要用 skill-creator 等 → 先 `/myplugins` 启用 → G27
- 调整工作流框架或 `skillOverrides` → 对插件 skill 无效，整包移到场景 → G28
- zsh 下 `for x in dir/*` 批量处理 → 先 `setopt nullglob` 或写成 `sh` → G29
- 前端项目 TypeScript 6 以下 → 另装 `typescript-language-server` → G30

<!-- on-demand -->
**以下按需查阅**：待处理事项、本机执行（中断恢复时要用）、已完成内容。

<!-- section: pending -->
## 待处理事项

| 项目 | 位置 |
|---|---|
| 3.4 试用场景、项目与试用期长度待用户决定；`mysession-eval` 长会话的 `extract`／`summarize` 输出量未实测 | 计划文件「需要用户决定」、3.4；`docs/plans/2026-11-05-mysession-eval-design.md`「token 预算」 |
| 教材沉淀 17 条待验证、前端 GlitchTip 暂缓、本机 docker 残留 | `docs/plans/2026-10-22-learning-distill-questions.md` |
| 阶段 2 未做项与疑问清单第 12、16 条 | `docs/research/2026-10-best-practices.md` 5.3 |
| claude-code-setup 暂缓项（新 skill／agent／permissions 候选、frontend-dev 审查 agent、全局 GitHub MCP `actions` toolset 需用户指示） | `docs/evaluation/2026-11-claude-code-setup-review.md` 3.6、4、6 |
| FiberHouse 示例 `repository.CreateExample` 接收 `requestvo` 会被 depguard 拦，用户 2026-11-05 决定暂不处理 | `docs/research/2026-11-layering-strictness.md` 第 6 节 |
| 未验证：myplugins 互动模式信任对话框与另一台机器；`/plugin` User 分组含义；`Bash(env)` 拦 `env \| grep`；`/context` 分类重叠；2.1.318 rule 加载与 RTK 的关系 | G23、G15、G24、G8 |
| 未验证：本机 `~/.codex/AGENTS.md` 首行 `@/Users/zz/.codex/RTK.md` 是 Claude Code 语法，Codex 可能不生效（未改动） | — |
| 测验环境（2026-11-05 记录，未复查）：`eval-mysql`（只读账号 `eval_ro`，变量在专案集 `mysql.env`）与 GlitchTip（`~/workspace/local-infra/glitchtip`）在跑；local-infra `fiberhouse-dev` 四容器 2026-11-04 重建；旧专案集阶段 1 残留在 `scenario-eval/leftover-dev-ops-deploy-bak-20261104/`；映像 `golangci/golangci-lint:v2.5.0`、`node:22-alpine` 可保留 | G20、G21 |
| 本机设定备份：`~/.claude/settings.json` 的 `.bak-20261104131115`、`.bak-20261104200612`、`.bak-20261105012410`；myplugins 清单 `~/.claude/myplugins/catalog.json.bak-20261104`；RTK `config.toml` 为 2026-11-05 新建 | G18、G23 |

<!-- section: run -->
## 本机执行

前置条件：POSIX `sh`；`python3`（3.9 即可）；真实安装支持包时视需要 `node`/`npm`、`git`、`claude`、`codex` CLI。无构建步骤，脚本从仓库根目录执行，参数以各脚本 `-h` 为准。

```bash
sh scripts/tests/run-all.sh
sh scripts/install-claude-project.sh -f backend-dev -t /path/to/project -d   # 预演
sh scripts/install-claude-project.sh -g -d
sh scripts/multi_client_support/codex.sh -d
```

改了 `permissions`、沙箱、RTK 或升级 Claude Code 后按 `scripts/smoke/README.md` 重跑 smoke。

<!-- section: done -->
## 已完成内容

接手阅读顺序：`AGENTS.md` → 本文件 → 计划文件（执行计划时）→ 要改动目录的 `README.md` → 根目录 `README.md`（设计原则与转型说明）。

```
dot_claude/                 个人用户级配置与自写技能（myconfig、myplugins、myopensupports、mysession-eval、myhandoff）
dot_claude_legacy/          转型前分层规则系统存档，只读
settings/ claude_mds/ dot_mcp_jsons/ agents/ skills/   按维度的配置，FLAG：prd-design、frontend-dev、backend-dev、dev-ops
dot_claude_projects/        .claude/ 全局支持包清单；.claude-<FLAG>/ 场景包完整聚合
open_supports/              支持包；INDEX.md 登记用途与建议场景
scripts/                    安装脚本、tests/、smoke/、multi_client_support/codex.sh
docs/                       handoff/、plans/、research/、evaluation/
```

各目录细节以其 `README.md` 为准；版本与发布记录见 `docs/handoff/CHANGELOG.md` 与 GitHub releases。
