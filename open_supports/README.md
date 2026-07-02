# open_supports — 说明与 TODO

> 进入 `open_supports/` 目录请先阅读本文件。它是理解整个目录结构、贡献规范和使用方式的唯一入口。

## 目录定位

`open_supports/` 用于收录与 Agent 编程相关的开源库的**本地化支持包**。  
每个支持包提炼开源仓库的核心介绍，并将官方安装 / 更新流程封装为：

- **一键脚本**：适合手动执行的一键安装 / 更新脚本
- **安装 Skill**：适合通过自然语言让 AI 模型完成安装 / 更新

---

## 目录结构

```
open_supports/
├── README.md                       # 本文件：体系说明 + 待办事项
├── workflow-quickstart.md          # workflow Skill 快速使用教程
├── .ost-workflow-state/            # workflow 运行时状态目录（JSON 状态默认不提交）
├── ost_{OwnerName}_{RepoName}/    # 每个开源库一个支持包目录
│   ├── .ost-refs/                  # （可选）手动引用文档，大模型操作前优先阅读
│   ├── repo_readme_summary.md      # 仓库核心介绍（摘自官方 README）
│   ├── usage_examples.md           # （可选）安装后的使用示例与验证排错
│   ├── scripts_for_install/
│   │   └── install.*               # 一键安装 / 更新脚本（扩展名随语言选型）
│   └── skill_for_setup/
│       ├── README.md               # Skill 使用说明
│       └── ost_{OwnerName}_{RepoName}_install/
│           └── SKILL.md            # 安装 Skill 主文件
└── .copilot-skills/                # 收录开源库过程中沉淀的通用 Skill，供跨支持包复用
```

### 命名规范

命名均基于 GitHub 仓库路径 `{OwnerName}/{RepoName}`（即 `github.com/{OwnerName}/{RepoName}`），将路径中的 `/` 替换为对应分隔符后拼接：

| 类型 | 格式 | 映射规则 | 示例（来源：`colbymchenry/codegraph`） |
|------|------|---------|--------------------------------------|
| 支持包目录 | `ost_{OwnerName}_{RepoName}` | `/` → `_` | `ost_colbymchenry_codegraph` |
| Skill 目录 | `ost_{OwnerName}_{RepoName}_install` | `/` → `_`，末尾加 `_install` | `ost_colbymchenry_codegraph_install` |
| 脚本文件 | `install.sh` / `install.js` / `install.py` | 扩展名随语言选型；脚本需幂等（兼容首次安装与更新），无需单独 `update.*` | — |

> 大小写与 GitHub 仓库地址完全一致，原样保留，不做转换。

---

## 各子文件说明

### `.ost-refs/`

手动维护的补充参考文档目录，用于在大模型执行安装 / 更新等操作前，提供上下文信息（如本地路径约定、环境差异、特殊配置说明等）。

- **存在且有内容**：大模型执行任何操作前优先阅读该目录下的所有文件
- **不存在或为空**：忽略，不影响正常流程

> 该目录不纳入模板，按需手动创建即可。

### `repo_readme_summary.md`

提炼自官方 README 的 5 部分结构化摘要（概览 / 安装与更新 / 使用示例 / 注意事项 / 补充与延伸），遵循「快速原则」（前 4 部分只保留核心内容）与「补充增强原则」（第 5 部分精炼延伸，链接原库）。

详细编写规范见 [`.copilot-skills/ost-repo-readme-summary/SKILL.md`](.copilot-skills/ost-repo-readme-summary/SKILL.md)。

### `usage_examples.md`

可选文件，由 `ost-support-workflow` 的 `optional_usage_examples` checklist 命中且用户同意时生成。用户明确要求时，也可单独使用 `ost-usage-examples` 生成。

面向安装后的快速开始、常见场景、Agent 客户端配合、验证与排错；不重复安装流程，不承载卸载流程。

### `scripts_for_install/install.*`

按官方文档封装的安装 / 更新脚本，要求：
- 支持首次安装和已有安装的更新（幂等）
- 模块化设计，可按运行时客户端追加参数（如 `--client claude|codex`）
- 执行前打印操作摘要，执行后验证结果

**脚本语言选型**：随库的运行时走，不强制统一语言；选型优先级如下：

| 优先级 | 适用场景 | 推荐语言 |
|--------|---------|---------|
| 1 | 库本身依赖 Node.js（npm 生态） | Node.js — 零额外依赖，JSON / MCP 注册原生支持 |
| 2 | 库本身依赖 Python | Python — 同理，运行时已是前置依赖 |
| 3 | 库无特定运行时依赖 | POSIX sh — 最小依赖，与仓库 `scripts/` 风格一致 |
| 4 | sh 遇到 JSON 操作 | sh + `jq`（检测可用性；不可用时提示手动，与仓库现有策略一致） |

> Windows 用户：所有 sh 脚本需在 WSL 或 Git Bash 下执行，与现有仓库脚本保持同等前提。  
> 不提前引入额外运行时：若库本身不需要 Node / Python，安装脚本也不应引入。

### `skill_for_setup/`

供 AI 模型通过自然语言完成安装的 Skill 包。

**客户端优先级**：优先支持 Claude Code、Codex；其他客户端按各开源库官方支持范围决定是否收录。

- `README.md`：说明 Skill 触发词、适用客户端、交互式 / 非交互式使用方式
- `ost_{OwnerName}_{RepoName}_install/SKILL.md`：Skill 主体，包含安装步骤、参数说明、验证方法

### `.copilot-skills/`

跨支持包复用的通用 Skill 收录在这里，例如摘要生成、安装脚本生成、setup Skill 生成、workflow 编排、可选用例生成等。

- 放入 `.copilot-skills/`：适用于多个开源库支持包的通用流程、质量标准、状态管理或可选阶段
- 留在各支持包 `skill_for_setup/`：某个库专属的安装 / 配置 Skill，以及该库特有的触发词、参数和排错说明
- 不放入 `.copilot-skills/`：单库 README 摘要、单库安装脚本、单库使用示例产物

---

## 使用入口（用户）

1. **脚本安装**：进入对应支持包目录，执行 `scripts_for_install/install.*`（`.sh` / `.js` / `.py`，见各支持包说明）
2. **Skill 安装**：在支持的 AI 客户端中，按 `skill_for_setup/README.md` 说明触发对应 Skill

---

## 贡献指南（新增支持包）

1. 复制 `ost_OwnerName_RepoName_TEMPLATE/` 并按命名规范重命名
2. 填写 `repo_readme_summary.md`（摘自官方 README，保留原文链接）
3. 编写 `scripts_for_install/install.*`（语言随库的运行时选型，参考官方安装文档，保持幂等）
4. 编写 `skill_for_setup/ost_{OwnerName}_{RepoName}_install/SKILL.md`（优先覆盖 Claude Code / Codex）
5. 更新 `skill_for_setup/README.md` 说明触发词与使用方式
6. 可选：workflow 的 `optional_usage_examples` checklist 命中且用户同意时，生成 `usage_examples.md`；用户明确要求时，也可单独使用 `ost-usage-examples` 生成
7. 在本文件下方 TODO 列表中登记状态

---

## 已收录库

| 支持包目录 | 库名 | 脚本 | Skill | 状态 |
|-----------|------|------|-------|------|
| `ost_colbymchenry_codegraph` | [codegraph](https://github.com/colbymchenry/codegraph) | ✅ 已填充 | ✅ 已填充 | ✅ 已完成 |
| `ost_deanpeters_Product-Manager-Skills` | [Product-Manager-Skills](https://github.com/deanpeters/Product-Manager-Skills) | ✅ 已填充 | ✅ 已填充 | ✅ 已完成 |
| `ost_eyaltoledano_claude-task-master` | [claude-task-master](https://github.com/eyaltoledano/claude-task-master) | ✅ 已填充 | ✅ 已填充 | ✅ 已完成 |
| `ost_garrytan_gstack` | [gstack](https://github.com/garrytan/gstack) | ✅ 已填充 | ✅ 已填充 | ✅ 已完成 |
| `ost_msitarzewski_agency-agents` | [agency-agents](https://github.com/msitarzewski/agency-agents) | ✅ 已填充 | ✅ 已填充 | ✅ 已完成 |
| `ost_open-gsd_gsd-core` | [gsd-core](https://github.com/open-gsd/gsd-core) | ✅ 已填充 | ✅ 已填充 | ✅ 已完成 |
| `ost_topoteretes_cognee` | [cognee](https://github.com/topoteretes/cognee) | ✅ 已填充 | ✅ 已填充 | ✅ 已完成 |

---

## TODO

### 体系层

- [x] 新增 workflow Skill：串联 `ost-repo-readme-summary` → `ost-install-script` → `ost-skill-for-setup` → `optional_usage_examples` → 可选测试安装验证
- [x] 增加 `.ost-workflow-state/` 状态目录约定，用于 workflow Skill 的问题澄清、断点续传和恢复执行
- [x] 为 3 个核心阶段 Skill 及可选 `ost-usage-examples` 增加统一 `Clarification / Blocking` 协议：信息不足时不猜测，返回 blocked 信息并等待用户澄清
- [x] workflow Skill 增加串行子代理执行策略、上下文节省约束和 `sh + jq` 状态脚本
- [x] `.copilot-skills/` 补充说明：明确哪类通用 Skill 应沉淀至此（如通用 MCP 注册、版本检测等），以及与各库 `skill_for_setup/` 的边界
- [x] 新增可选 `ost-usage-examples` Skill：用于在 workflow 后生成 `usage_examples.md`
- [ ] 确认多客户端 Skill 的组织方式：单文件多客户端 vs 分文件

### 已澄清问题

- [x] `repo_readme_summary.md` 的示例部分保持轻量，只增加有限理解性注释；详细用例不放入摘要
- [x] 增加可选 `ost-usage-examples` Skill，用于在 workflow 后生成 `usage_examples.md`
- [x] 一键脚本默认不包含删除 / 卸载；官方卸载方法只记录为参考，`--uninstall` 仅作为明确要求下的可选扩展

### 具体待办

- [x] `ost_OwnerName_RepoName_TEMPLATE`：统一使用 `repo_readme_summary.md` 文件名
- [x] `ost_colbymchenry_codegraph`：填充 `repo_readme_summary.md`、`scripts_for_install/install.*`、`skill_for_setup/ost_colbymchenry_codegraph_install/SKILL.md`
- [x] `ost_garrytan_gstack`：填充 `repo_readme_summary.md`、`scripts_for_install/install.sh`、`skill_for_setup/ost_garrytan_gstack_install/SKILL.md`，并生成 `usage_examples.md`
- [x] `ost_open-gsd_gsd-core`：补充目录内容
- [x] `.copilot-skills/`：已收录首批通用 Skill（摘要、安装脚本、setup、workflow、可选用例）
- [ ] `.copilot-skills/`：按后续支持包经验继续补充通用 MCP 注册、版本检测等 Skill
