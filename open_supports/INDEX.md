# open_supports 索引

当前收录的开源工具库，以及各自安装脚本的作用域分类（A～D）。体系说明与贡献规范见 [`README.md`](README.md)。

> 分类以各支持包 `repo_readme_summary.md` 开头的「安装作用域」为准，本索引只做汇总。`scripts/tests/test-open-supports-index.sh` 会检查两者一致，以及每个支持包都已登记。

---

## 安装作用域分类（A～D）

分类回答一个问题：**这个工具装到哪里，安装脚本怎么找到目标项目？** 定义与审查用例见 [`.copilot-skills/ost-install-script/SKILL.md`](.copilot-skills/ost-install-script/SKILL.md) 与 [`SCOPE-CONTRACT-CASES.md`](.copilot-skills/ost-install-script/SCOPE-CONTRACT-CASES.md)。

| 分类 | 含义 | 安装脚本的做法 | 你需要做什么 |
|------|------|---------------|-------------|
| **A** 仅全局 | 官方只支持装到用户级目录（如 `~/.claude`、全局 npm），不接受项目路径 | 直接执行官方全局命令；不提供 `--local`、`--target` 之类的伪参数 | 直接运行，无需项目目录；注意它会改动用户级配置 |
| **B** 项目本地／CWD 敏感 | 官方的项目级安装写入「当前目录」，且没有项目路径参数 | 接收项目目录（默认 `.`），验证存在后在子 shell `( cd "$DIR" && 命令 )` 中执行，不改变调用端的当前目录 | 把项目目录作为最后一个参数传入，例如 `/path/to/project` |
| **C** 原生路径参数 | 官方命令本身接受项目路径（如 `--project DIR`） | 接收并验证项目目录，直接传给官方的路径参数，不自行 `cd` | 同 B，传入项目目录 |
| **D** 双模式 | 官方同时支持全局与项目级安装 | 分别实现两个分支；**默认值与官方一致**（官方默认全局就默认全局）。项目分支再按 B 或 C 处理；全局分支不接受项目目录 | 用 `--global` / `--local`（或该库的等效参数）显式选择；项目模式传入项目目录 |

下表「分类」一栏写成 `D（本地 B）` 时，表示双模式，且项目分支属于 B（依赖 CWD，由脚本用子 shell 切换）。

---

## 已收录支持包

<!-- 新增支持包时在表格末尾追加一行；分类首字母必须与该包 repo_readme_summary.md 的「模式 X」一致 -->

| 支持包 | 上游 | 用途 | 分类 | 建议场景 | usage_examples |
|--------|------|------|------|----------|:-:|
| `ost_Fission-AI_OpenSpec` | [Fission-AI/OpenSpec](https://github.com/Fission-AI/OpenSpec) | 规格驱动开发工作流：`openspec` CLI 与 `/opsx:*` 命令，先对齐需求再实现 | A（项目初始化 B） | 主：后端；次：前端 | ✅ |
| `ost_colbymchenry_codegraph` | [colbymchenry/codegraph](https://github.com/colbymchenry/codegraph) | 本地代码知识图谱 MCP，一次调用取得精准上下文 | D（本地 B） | 主：后端；次：前端 | — |
| `ost_deanpeters_Product-Manager-Skills` | [deanpeters/Product-Manager-Skills](https://github.com/deanpeters/Product-Manager-Skills) | 产品管理框架 skills / commands（discovery、strategy、delivery 等） | D（项目分支为显式路径） | 主：PRD（备选，未默认启用；与 phuryn 二选一，见下方说明） | ✅ |
| `ost_eyaltoledano_claude-task-master` | [eyaltoledano/claude-task-master](https://github.com/eyaltoledano/claude-task-master) | Taskmaster：把 PRD 拆成任务，经 CLI 或 MCP 推进 | D（本地 B） | **全局** | ✅ |
| `ost_garrytan_gstack` | [garrytan/gstack](https://github.com/garrytan/gstack) | Think → Plan → Build → Review → Test → Ship 的编码工作流技能包 | D（本地 B） | **全局**（产品、前后端常用） | ✅ |
| `ost_mattpocock_skills` | [mattpocock/skills](https://github.com/mattpocock/skills) | 小而可组合的工程类 agent skills（如 `/grill-me`） | D（项目分支 B） | prd-design、backend-dev（插件，场景 settings 启用） | ✅ |
| `ost_msitarzewski_agency-agents` | [msitarzewski/agency-agents](https://github.com/msitarzewski/agency-agents) | 多角色专业 agent 与安装脚本（本仓库 `agents/agents-agency-agent-based-dev/` 的来源） | D（项目分支 B） | 不直接安装，已挑选到 `agents/` | ✅ |
| `ost_open-gsd_gsd-core` | [open-gsd/gsd-core](https://github.com/open-gsd/gsd-core) | discuss → plan → execute → verify → ship 的 spec-driven 工作流 | D（本地 B） | 主：前端；次：后端 | ✅ |
| `ost_phuryn_pm-skills` | [phuryn/pm-skills](https://github.com/phuryn/pm-skills) | PM Skills 插件市场：68 个 PM skills、42 个工作流 | D（本地 B） | 主：PRD（项目级插件）；次：DevOps（仅 `pm-ai-shipping`） | ✅ |
| `ost_topoteretes_cognee` | [topoteretes/cognee](https://github.com/topoteretes/cognee) | Agent 长期记忆平台：知识图谱 + 向量记忆 | D（本地 C） | 暂不启用（记忆类由全局 `remember` 插件承担） | ✅ |


「建议场景」中，**主**为该支持包在场景清单中默认启用的场景；**次**为第二场景，在该场景清单中一律以注释录入并写明适用条件，需要时取消注释再安装。依据（2026-10-28 核对上游原文）：

- OpenSpec 规格放在代码仓库的 `openspec/`、`/opsx:apply` 直接实现，属于开发工作流而非 PRD 工具；以「需求 + 场景（WHEN/THEN）」描述行为，与后端「先改契约」一致，故主场景为后端。
- gsd-core 唯一的场景专属能力是前端的 `/gsd-ui-phase`、`/gsd-ui-review`，故主场景为前端；OpenSpec 与 gsd-core 都是规格／工作流框架，同一项目只启用一套，改用另一套时注释主场景那一行。
- phuryn/pm-skills 的 `pm-ai-shipping`（`/ship-check`、`/security-audit-static`、`/performance-audit-static`）是上线前的静态代码审查与签核材料，列为 DevOps 的次场景；与已有审查工具重叠，默认不启用。
- deanpeters/Product-Manager-Skills 与 phuryn 功能高度重叠，两者 `marketplace.json` 的 `name` 都是 `pm-skills`，且授权为 CC BY-NC-SA 4.0（非商业）；本仓库支持包目前没有 Claude Code 项目级安装路径，暂不写入 PRD 清单。

---

## 全局工具

以下工具在所有项目中都生效，按用户级方式安装一次即可，不写进任何项目的 `open_supports_name_list.txt`。gstack、task-master 已登记在全局清单 `dot_claude_projects/.claude/open_supports_name_list.txt`，统一用 `sh scripts/install-claude-project.sh -g` 安装（先加 `-d` 预演）；下表的单独命令供参考。场景分配见 [`settings/README.md`](../settings/README.md)。

| 工具 | 安装方式 | 前置条件与注意 |
|------|---------|---------------|
| mattpocock-skills | 2026-10-28 移出全局，改在 prd-design、backend-dev 场景 settings 启用（`mattpocock-skills@claude-plugins-official`），无需运行脚本 | 插件 skill 不受 `skillOverrides` 控制，只能整包启用；上游已把 27 个 skill 中 16 个设为只能手动调用，见 `settings/README.md`「工作流框架分层」 |
| gstack | `sh open_supports/ost_garrytan_gstack/scripts_for_install/install.sh` | 检出到 `~/.local/share/gstack`（构建后约 1.1GB），setup 建立 `~/.claude/skills/gstack` 链接，所有项目可见；默认 `--prefix`、不注册 timeline Stop hook 与 plan-tune hook，已用 `gstack-config` 保存的选择不覆盖；62 个 skill 在 `settings/settings.user.json` 的 `skillOverrides` 默认设为只能手动调用，场景按需打开，见 `settings/README.md`「工作流框架分层」 |
| task-master | `sh open_supports/ost_eyaltoledano_claude-task-master/scripts_for_install/install.sh --global --claude-mcp --tools=core` | 需要模型 API key，或使用已认证的 Claude Code provider；`--tools=core` 只加载核心工具，减少上下文 |

---

## 安装命令速查

在仓库根目录执行时，路径前加 `open_supports/<支持包>/`。完整参数以各脚本 `--help` 为准。

| 支持包 | 全局／用户级 | 项目级 | 说明 |
|--------|-------------|--------|------|
| `ost_Fission-AI_OpenSpec` | `sh scripts_for_install/install.sh` | `sh scripts_for_install/install.sh --init-project /path/to/project` | CLI 只能全局安装；`openspec init` 依赖 CWD，由脚本在子 shell 中执行 |
| `ost_colbymchenry_codegraph` | `sh scripts_for_install/install.sh --global` | `sh scripts_for_install/install.sh --location=local /path/to/project` | 本地配置由 CWD 决定；`codegraph init [path]` 另有原生路径参数 |
| `ost_deanpeters_Product-Manager-Skills` | `sh scripts_for_install/install.sh --client=codex-cli --skill=prd-development --global` | `sh scripts_for_install/install.sh --client=codex-zip /path/to/project` | Codex ZIP 解压到显式目录，不依赖 CWD；Skills CLI 路径只有全局 |
| `ost_eyaltoledano_claude-task-master` | `sh scripts_for_install/install.sh --global` | `sh scripts_for_install/install.sh --local /path/to/project` | 项目安装即该目录下的本地 npm 安装 |
| `ost_garrytan_gstack` | `sh scripts_for_install/install.sh` | `sh scripts_for_install/install.sh --team=required /path/to/project` | 常规 setup 为用户级；只有 team 模式需要项目目录 |
| `ost_mattpocock_skills` | `sh scripts_for_install/install.sh` | `sh scripts_for_install/install.sh --client=claude-code --local /path/to/project` | 默认值随客户端：Claude Code / Gemini 插件默认用户级；`--client=npx` 默认项目级 |
| `ost_msitarzewski_agency-agents` | `sh scripts_for_install/install.sh --tool=claude-code` | `sh scripts_for_install/install.sh --tool=opencode /path/to/project` | 是否项目级取决于 `--tool`；项目级工具按 CWD 计算目标 |
| `ost_open-gsd_gsd-core` | `sh scripts_for_install/install.sh --claude --global` | `sh scripts_for_install/install.sh --claude --local /path/to/project` | `--all` 必须配合 `--global` |
| `ost_phuryn_pm-skills` | `sh scripts_for_install/install.sh --client=claude-code` | `sh scripts_for_install/install.sh --client=claude-code --location=local --plugins=pm-execution /path/to/project` | Claude Code 默认用户级，`--location=local` 以 `--scope project` 写入项目 settings；Codex 只有用户级；`--client=opencode` 等为 skills-only 复制 |
| `ost_topoteretes_cognee` | `sh scripts_for_install/install.sh --global` | `sh scripts_for_install/install.sh --local /path/to/project` | 本地模式安装到 `/path/to/project/.venv` |

统一入口 `scripts/install-open-supports.sh`：

- 按项目批量安装：在项目的 `.claude/open_supports_name_list.txt` 中列出支持包，执行 `sh scripts/install-open-supports.sh -t /path/to/project`
- 单一安装：`sh scripts/install-open-supports.sh -t /path/to/project -n <Owner/Repo> -- <参数...>`，全局则把 `-t <dir>` 换成 `-g`
- 全局批量安装：`sh scripts/install-open-supports.sh -g`（读取 `~/.claude/open_supports_name_list.txt`，不复制支持包）

详见 [`README.md`](README.md) 与 `scripts/README.md`。

---

## 新增支持包时更新本索引

1. 按 [`README.md`](README.md)「贡献指南」或 `ost-support-workflow` 完成支持包；`repo_readme_summary.md` 第 3 行必须写明 `**安装作用域（模式 X…）**`
2. 在「已收录支持包」表格末尾追加一行，分类首字母与摘要中的「模式 X」一致；项目分支属于 B 或 C 时在括号中注明；「建议场景」填 PRD／前端／后端／DevOps／全局，并同步对应场景的 `dot_claude_projects/.claude-<FLAG>/.claude/open_supports_name_list.txt`
3. 在「安装命令速查」追加对应命令，命令取自该包脚本的 `--help` 或 `usage_examples.md`
4. 运行 `sh scripts/tests/test-open-supports-index.sh`（或 `sh scripts/tests/run-all.sh`）确认登记完整、分类一致

行模板：

```markdown
| `ost_{OwnerName}_{RepoName}` | [{OwnerName}/{RepoName}](https://github.com/{OwnerName}/{RepoName}) | 一句话用途 | D（本地 B） | 前端、后端 | ✅ |
```
