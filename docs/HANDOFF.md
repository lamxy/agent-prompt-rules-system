# 交接文档

本文件记录仓库转型与四场景配置的规划、决策和当前状态，供后续会话或协作者接手并继续追加需求。最后更新：2026-10-19。

**接手时先读**：本文件 → 根目录 `README.md` → `AGENTS.md` → 要改动的目录自己的 `README.md`。新需求完成后，在文末「变更日志」追加一条。

---

## 1. 仓库定位

个人 Agent 配置与工具／技能管理仓库（Claude Code 为主，兼顾 Codex），公开供参考。2026-10-19 从「分层提示词规则系统」转型而来，原因见根目录 `README.md`「转型说明」。

设计原则（根目录 `README.md`）：

1. **只写差异**：`CLAUDE.md` 只写与 Claude Code 默认行为不同、确有需要的约定
2. **硬约束优先**：权限与沙箱 → hook → Plan mode → 提示词
3. **按需加载用官方机制**：skill、带 `paths` 的 rule、slash command
4. **冲突比缺漏更糟**：同一项目不同时启用多套工作流框架
5. **工具接入可复现**：支持包安装脚本幂等、可重复执行、带验证
6. **安装不覆盖人工内容**：已存在的文件默认不覆盖；`-F` 先备份再覆盖

---

## 2. 用户约束与偏好（必须遵守）

| 约束 | 说明 |
|------|------|
| **不改动本机配置** | 只修改本仓库。`~/.claude/` 等本机文件只读，除非用户明确下指令 |
| 改动前先确认 | 涉及取舍的事项先列方案与理由，用户确认后再实现 |
| 不使用中国大陆的工具 | 例如飞书、钉钉、阿里云、腾讯云 |
| 语言 | 与用户沟通用繁体中文；`dot_claude/` 内容为繁体中文；其他仓库文档为简体中文 |
| 测试 | 一律在临时目录中执行，不对真实配置测试 |
| 提交 | 用户确认后才提交；`scripts/install-settings.sh` 中第 299、307 行的 `${LEVEL}`、`${MODE}` 是用户自己的修改，提交时需与其他改动一起向用户说明 |

---

## 3. 四个场景

FLAG 在所有场景目录中一致：

| FLAG | 场景 | 范围 |
|------|------|------|
| `prd-design` | PRD 与原型设计 | 需求功能说明书、PRD、线框图或基础原型 |
| `frontend-dev` | 前端开发 | UI 设计与实现、前端交互、对接后端 API |
| `backend-dev` | 后端开发 | 系统规格说明、系统／数据库／架构设计、技术与框架选型；后端功能、API 与数据库开发 |
| `dev-ops` | DevOps | CI/CD、上线、可观测性 |

另有 `fullstack-dev`（前端 + 后端），只存在于 `settings/`。

### 已确认的技术栈决策

| 项目 | 决定 |
|------|------|
| 后端语言 | Go、Node.js / TypeScript（LSP：`gopls-lsp`、`typescript-native-lsp`） |
| 数据库 | MongoDB、Redis、MySQL 为主，兼容 PostgreSQL |
| 云与可观测性 | 开源自建：Kubernetes、Prometheus / Grafana、Sentry |
| PRD 工具 | 以技能为主：pm-skills、mattpocock-skills、gstack；Figma、Notion 等只作为可选 |
| 主工作流框架 | **不设**。全局只有 superpowers；OpenSpec、gsd-core 在前后端清单中以注释提供，按需启用其一 |
| gstack | 保持全局生效 |
| 全局工具 | task-master、mattpocock-skills、cognee、gstack |

---

## 4. 各目录现状

### `settings/`（`install-settings.sh`）

- **`settings.user.json`**：推荐的全局基础设定。以本机设定为基础，只调整插件与市场：
  - 全局插件：superpowers、mattpocock-skills、andrej-karpathy-skills、ralph-loop、context7、github、commit-commands、security-guidance、open-code-review、claude-code-setup、claude-md-management、skill-creator、hookify、remember、session-report
  - 移出到场景：LSP（gopls、pyright、typescript-native-lsp）、frontend-design、chrome-devtools-mcp、playground
  - 统一用 `@claude-plugins-official`；删除 `claude-code-plugins` 市场（其插件官方市场都有）
- **`dot_claude/settings.json`** 仍是本机设定的镜像，**未做上述调整**。要在本机采用新全局设定，由用户自行执行 `install-settings.sh -l user`
- **项目级**：

  | 模板 | 插件 | permissions |
  |------|------|-------------|
  | `project-prd-design` | playground、document-skills（`anthropic-agent-skills` 市场） | — |
  | `project-frontend-dev` | typescript-native-lsp、frontend-design、playwright、chrome-devtools-mcp、modern-web-guidance、playground、pr-review-toolkit、sentry | — |
  | `project-backend-dev` | gopls-lsp、typescript-native-lsp、postman、mongodb、redis-development、semgrep、sentry、pr-review-toolkit | `deny`：四种数据库的破坏性命令（含 `mongosh`） |
  | `project-dev-ops` | terraform、grafana-mcp、sentry、semgrep、sonatype-guide、pr-review-toolkit | `ask`：terraform apply/destroy/import/state、kubectl 变更类、helm 变更类 |
  | `project-fullstack-dev` | 前端 + 后端去重 | 同后端 |

- **本地级**：只列可选、需要个人账号或托管服务的插件，默认 `false`
- `-m merge` 只合并 `enabledPlugins`、`extraKnownMarketplaces`；含 `permissions` 的模板要用 `overwrite`

### `open_supports/`（`install-open-supports.sh`）

- `INDEX.md`：10 个支持包的用途、A～D 安装作用域分类、**建议场景**、安装命令速查、**全局工具**安装方式
- 场景分配：codegraph → 前后端；pm-skills → PRD（项目级插件）；OpenSpec、gsd-core → 前后端可选框架；deanpeters PM skills → PRD 备选（未启用）；agency-agents → 已挑选到 `agents/`
- `ost_phuryn_pm-skills` 已扩充：`--client=claude-code --location=local` 以 `--scope project` 安装到项目；默认仍为用户级
- 工作流说明改名为 `README-workflow-quickstart.md`

### `dot_claude_projects/`（`install-claude-project.sh`）

启动包**只放** `.claude/open_supports_name_list.txt`，只为 Claude Code 配置；settings、`CLAUDE.md`、`.mcp.json` 由各自目录维护，避免重复。PRD 清单安装 pm-skills；前后端清单安装 codegraph，并注释提供 OpenSpec、gsd-core；DevOps 无专属支持包。

**安装顺序**：settings 模板必须在 `install-open-supports.sh` 之前安装，否则 pm-skills 写入的项目 settings 条目会被覆盖。完整命令见 `dot_claude_projects/README.md`。

### `claude_mds/`、`dot_mcp_jsons/`、`agents/`、`skills/`

| 目录 | 现状 |
|------|------|
| `claude_mds/` | 四个 `CLAUDE-<FLAG>.md`，各约 30 行，只写场景约定 |
| `dot_mcp_jsons/` | 后端：MCP Toolbox 的 `mysql`、`postgres`（`execute_sql` 可写，必须用只读账号）；DevOps：`kubernetes-mcp-server`，配合 `kubernetes-mcp-server.readonly.toml`；PRD、前端为空 |
| `agents/` | 四个场景各 5～6 个，挑选自 `agents-agency-agent-based-dev/`；文件名去前缀，`name` 改为小写连字符 |
| `skills/` | 四个场景的自定义 skill **尚未编写**；前端外部 skills（vercel-labs/agent-skills）安装方式见 `skills-frontend-dev/README.md` |

### `scripts/`

本轮修复与新增：

| 脚本 | 改动 |
|------|------|
| `install-settings.sh` | 备份不再同秒覆盖；merge 列出未写入的字段；ask 从 `/dev/tty` 读取；找不到场景时列出可用场景 |
| `install-skill-pkg.sh` / `install-agent-pkg.sh` | `-F` 先备份到 `<target>.backup-<时间戳>/`；skill 只装含 `SKILL.md` 的目录；目标不存在时自动创建 |
| `install-claude-md.sh` / `install-dot-mcp.sh` / `install-claude-project.sh` | 去掉 `eval`（曾可注入命令、路径含空格会失败）；`-F` 先备份；跳过空模板；`.mcp.json` 校验 JSON；项目包 `-F` 不再删除整个 `.claude/` |
| `install-open-supports.sh` | 新增 `{PROJECT_DIR}` 占位符（以前项目级安装会装进支持包目录）；清单改用 fd 3 读取（以前安装脚本读 stdin 会吞掉后续条目且结束码为 0）；wrapper Skill 记录全部安装命令并随清单重新生成；`[STALE]` 提示；`-F` 先备份 |
| `scripts/tests/` | 所有测试集中于此，`run-all.sh` 一次执行（含 `sh -n`）；当前 10 个测试文件全部通过 |

---

## 5. 如何扩展

| 需求 | 步骤 |
|------|------|
| 新增场景 | 在 `settings/`、`claude_mds/`、`dot_mcp_jsons/`、`agents/`、`skills/`、`dot_claude_projects/` 使用相同 FLAG 新建；更新根目录 `README.md`「四个场景」与本文件 |
| 场景增减插件 | 改 `settings/settings.project-<FLAG>.json`，第三方市场要在 `extraKnownMarketplaces` 声明；同步 `settings/README.md`；跑 `test-settings-templates.sh` |
| 新增全局插件 | 改 `settings/settings.user.json` 与 `settings/README.md`；确认与已有全局插件无功能重叠或指令冲突 |
| 新增支持包 | 按 `open_supports/README.md` 贡献指南或 `ost-support-workflow`；在 `INDEX.md` 两张表登记（含建议场景）；项目级安装写进对应场景清单并带 `{PROJECT_DIR}`；跑 `test-open-supports-index.sh` |
| 新增 MCP | 先确认场景插件没有提供；凭据用 `${VAR}`；更新 `dot_mcp_jsons/README.md` |
| 新增 agent | 从 `agents-agency-agent-based-dev/` 复制到场景包，去掉文件名前缀，`name` 改为与文件名一致 |
| 修改脚本 | 前后都执行 `sh scripts/tests/run-all.sh`；新测试命名为 `scripts/tests/test-<对象>.sh` |

---

## 6. 待办与已知问题

### 待办

- [ ] 为四个场景编写自定义 skill，例如 PRD 模板、API 契约、上线检查清单（`skills/skills-<FLAG>/`）
- [ ] 在真实项目中验证四个场景的配置
- [ ] 由用户决定是否在本机采用新的全局设定（`install-settings.sh -l user`）
- [ ] 按主题拆分提交（见下文）
- [ ] 可选：一条命令初始化场景项目的脚本，串起 `dot_claude_projects/README.md` 中的 7 条命令
- [ ] 将其他仓库中的技能与工具包管理平台 MVP 迁入 `src/`（根目录 Roadmap）

### 已知问题与注意事项

- **第三方市场的插件名无法离线校验**：`pm-skills`、`anthropic-agent-skills` 未缓存在本机，`test-settings-templates.sh` 跳过其名称检查；名称取自上游 `marketplace.json`
- **cognee 前置条件**：需要 Python 3.10～3.14 与 `LLM_API_KEY`；本机系统 `python3` 为 3.9.6
- **数据库 MCP 可写**：MCP Toolbox 没有只读开关，只能靠只读账号
- **全局工具重叠**：mattpocock-skills 与 superpowers 都有 TDD、需求追问类 skill；cognee 与 remember 都是记忆类。出现重复时用 `skillOverrides` 关闭其一
- **Codex 不在场景清单范围内**：由用户自行运行 `open_supports/` 下各支持包的安装脚本（如 `--target=codex`、`--client=codex`、`--codex`）
- **`typescript-native-lsp`** 来自内置插件目录（`@anthropic-plugin-directory`）；TypeScript 6 以下需另装 `typescript-language-server`
- `docs/superpowers/plans/` 中两份 2026-08 计划仍引用已删除的 Docker 测试，属于历史记录，未修改

---

## 7. 未提交的改动与建议的提交拆分

截至本文件更新时，所有改动都**未提交**。建议按主题拆成以下提交，每个提交前跑一次 `run-all.sh`：

1. `refactor:` 转型：`dot_claude/` 精简、原目录归档为 `dot_claude_legacy/`（含 hook 与 settings 修正）、根目录 README / AGENTS / CONTRIBUTING
2. `refactor:` `settings/` 收敛为四场景、清理过时设定
3. `fix:` 安装脚本修复（settings、skill/agent/claude-md/dot-mcp/claude-project 的备份与 `eval`、open-supports 的 `{PROJECT_DIR}`），`install-settings.sh` 中包含用户自己的修改
4. `test:` 测试迁入 `scripts/tests/`、新增测试与 `run-all.sh`
5. `docs:` `open_supports/INDEX.md`、快速教程改名
6. `feat:` 四场景基础配置：settings 插件分层、`claude_mds/`、`dot_mcp_jsons/`、`agents/` 场景包、`dot_claude_projects/` 清单、`ost_phuryn_pm-skills` 项目级安装
7. `docs:` 本交接文档

---

## 8. 变更日志

新需求完成后在此追加：日期、需求、主要改动、遗留事项。

| 日期 | 需求 | 主要改动 | 遗留 |
|------|------|---------|------|
| 2026-10-19 | 仓库转型 | `dot_claude/` 精简、`dot_claude_legacy/` 归档、根目录 README 重写 | — |
| 2026-10-19 | 安装脚本审查 | 备份、`eval`、空模板、`-F` 删除整个目录等问题修复；测试集中到 `scripts/tests/` | 3 个 open_supports 测试的英文断言已修；Docker 测试已删除 |
| 2026-10-19 | open_supports 索引 | `INDEX.md`：A～D 分类、建议场景、全局工具；`{PROJECT_DIR}` 占位符 | — |
| 2026-10-19 | 四场景基础配置 | 全局与场景插件分层、四个 `CLAUDE.md`、数据库与 K8s MCP、场景 agent 包、启动包清单 | 场景自定义 skill；真实项目验证 |
| 2026-10-19 | pm-skills 走支持包 | `ost_phuryn_pm-skills` 支持 `--scope project`；PRD settings 移除 pm-skills | — |
| 2026-10-19 | 场景清单支持 Codex（已撤销） | 曾为清单加入 Codex 参数，随后按用户决定回退；Codex 改由用户手动运行支持包脚本 | — |
| 2026-10-19 | install-open-supports.sh 审查 | 修复安装脚本吞掉清单后续行；wrapper Skill 记录带参数的完整命令（以前缺参数，重装会装错位置）并随清单更新；`-F` 改为备份；新增 `[STALE]`；同一支持包多行只复制一次；新增 5 项测试 | 旧测试的临时目录未清理（既有问题） |
