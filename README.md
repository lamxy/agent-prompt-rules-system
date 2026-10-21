# Agent Prompt Rules System

<p align="center">
  面向个人开发者的 Agent 配置与技能管理工具<br />
  <strong>以 Claude Code 为主，兼顾 Codex；配置可同步、技能可安装、工具接入可复现。</strong>
</p>

<p align="center">
  <img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/lamxy/agent-prompt-rules-system?style=flat-square" />
  <img alt="GitHub last commit" src="https://img.shields.io/github/last-commit/lamxy/agent-prompt-rules-system?style=flat-square" />
  <img alt="GitHub License" src="https://img.shields.io/github/license/lamxy/agent-prompt-rules-system?style=flat-square" />
  <img alt="Claude Code" src="https://img.shields.io/badge/Claude%20Code-personal%20config-purple?style=flat-square" />
</p>

---

## 项目简介

这是一套帮助个人开发者管理 Agent 配置与能力的工具，按工作场景集中维护：

- **配置**：Claude Code 用户级配置、settings 模板、项目级 `CLAUDE.md`、`.mcp.json` 与场景包
- **能力包**：按场景分组的 agent 定义与 skill
- **工具接入**：Agent 编程相关开源库的本地化支持包（摘要、幂等安装脚本、setup Skill）
- **多客户端**：把个人差异规则同步到 Codex，并说明场景配置与 skill 如何复用

可以直接 fork 后按自己的工作流改造。注意 `dot_claude/settings.json` 等文件带有作者的本机环境假设（代理、`rtk`、`myhandoff` 等），直接使用前请先阅读对应 README。

> 仓库名 `agent-prompt-rules-system` 沿用早期「提示词规则系统」时期的名称，定位已在 2026-10 转型，见下方「转型说明」。

---

## 转型说明

本仓库最初是一套面向 Claude Code 的**分层提示词规则系统**：`CLAUDE.md` 主文件 + `rules/` 极简规约 + `expandable/` 按需规约 + 输出模板 + hooks，常驻上下文约 22KB，路线图规划了完整规约层、触发决策树、披露层与串联协议。

2026-10-19 对照 Claude Code 现状与官方文档重新评估后，这套规则几乎全部删除，`dot_claude/CLAUDE.md` 精简为约 30 行：

1. **多数规则已是默认行为**：先给结论、简洁、不编造、只问一个关键问题、压缩工具输出、不可逆操作先确认，新版系统提示词已涵盖。官方建议单个 CLAUDE.md 少于 200 行，过长会降低遵循度。
2. **按需加载不可靠**：`expandable/` 依赖模型自行记得读取文件；官方机制是 skill 与带 `paths` frontmatter 的 rule。
3. **自建协作协议已被平台取代**：派发模板、输出字段、结果分流阈值、`SendMessage` 纠正流程，已由 Agent 工具、agent 定义的 `model:` frontmatter、`/loop`、Plan mode 取代。
4. **规则互相冲突**：如「同一工具最多重试 1 次」与全局 curl 重试规则矛盾；两条指令矛盾时模型可能任选其一。
5. **hook 存在语义错误**：修复后收益仍低，新版不再采用。

规则系统消失后，仓库真正持续产出价值的部分是**配置同步、技能与 agent 包、开源工具接入**，因此转型为面向个人开发者的 Agent 配置与工具／技能管理工具。原路线图中的规约层、决策层、披露层与串联协议不再推进。

- 原规则系统完整备份于 `dot_claude_legacy/`（已修正其中的 hook 与 settings 错误，不被任何安装脚本使用）
- 逐项迁移对照、settings 调整与提炼的经验见 `dot_claude/README.md`

---

## 仓库内容

| 类别 | 目录 | 内容 | 安装方式 |
|------|------|------|---------|
| 配置 | `dot_claude/` | 个人 Claude Code 用户级配置：约 30 行 `CLAUDE.md`、`commands/`、`skills/`（myhandoff）、`settings.json`（繁体中文） | `install.sh` |
| 配置 | `settings/` | 全局基础插件 + 项目级四个场景（PRD、前端、后端、DevOps）与全栈组合 + 本地级可选插件 | `install-settings.sh` |
| 配置 | `claude_mds/` | 按场景分类的 `CLAUDE-<FLAG>.md` | `install-claude-md.sh` |
| 配置 | `dot_mcp_jsons/` | 按场景分类的 `.mcp.json` 模板 | `install-dot-mcp.sh` |
| 配置 | `dot_claude_projects/` | 场景包：各维度配置的完整聚合（settings、`CLAUDE.md`、`.mcp.json`、agents、skills、支持包清单）；`.claude/` 为全局支持包清单 | `install-claude-project.sh` |
| 能力包 | `agents/` | 按场景分组的 agent 定义（`agents-<FLAG>/`） | `install-agent-pkg.sh` |
| 能力包 | `skills/` | 按场景分组的 skill（`skills-<FLAG>/`） | `install-skill-pkg.sh` |
| 工具接入 | `open_supports/` | 开源库本地化支持包（`ost_{Owner}_{Repo}/`）；可单独或按清单安装 | `install-open-supports.sh` |
| 多客户端 | `scripts/multi_client_support/` | 把 `dot_claude/CLAUDE.md` 的差异规则写入 Codex 的 `~/.codex/AGENTS.md`（标记区块，保留原有内容） | `codex.sh` |
| 文档 | `docs/recommend_repos/` | 推荐仓库与详细中文教程 | — |
| 平台 | `src/` | 预留给「Agent 技能与工具包标准体系」管理平台（MVP 已在其他仓库实现，后续迁入） | — |
| 归档 | `dot_claude_legacy/` | 2026-10-19 前的分层规则系统备份 | 不安装 |

### 四个场景

| FLAG | 场景 | 重点 |
|------|------|------|
| `prd-design` | PRD 与原型设计 | 需求说明书、PRD、线框图与基础原型；以 pm-skills、mattpocock-skills、gstack 等技能为主 |
| `frontend-dev` | 前端开发 | UI 设计与实现、前端交互、对接后端 API |
| `backend-dev` | 后端开发 | 系统规格与架构设计、技术与框架选型、数据库设计；以 Go 技术栈为参考实现：Gin、Fiber、自定义框架、gRPC，MySQL、PostgreSQL、MongoDB、Elasticsearch、Redis、Kafka、RabbitMQ |
| `dev-ops` | DevOps | CI/CD、上线、可观测性；Kubernetes、Prometheus/Grafana、Sentry |

仓库只维护以上四个场景，每个场景是一份**参考实现**，不追求覆盖该领域的所有技术栈（例如 `backend-dev` 只以 Go 为主）。其他场景、其他技术栈或特定项目由使用者自行实现，常见做法有两种：

- **复制场景包**：复制最接近的场景（例如 `dot_claude_projects/.claude-backend-dev/`），以项目名或技术栈作为新 FLAG（例如 `.claude-order-service/`），再改写其中内容
- **切分支修改**：在自己的 fork 中切出分支，直接修改现有场景包

详见 [`dot_claude_projects/README.md`](dot_claude_projects/README.md) 的「范围与自定义场景」。

每个场景在 `settings/`、`claude_mds/`、`dot_mcp_jsons/`、`agents/`、`skills/`、`dot_claude_projects/` 中使用相同的 FLAG。插件分层与选择理由见 `settings/README.md`，一次初始化一个场景项目的命令见 `dot_claude_projects/README.md`。

当前收录 10 个 `open_supports` 支持包（OpenSpec、codegraph、Taskmaster、gstack、cognee 等），清单、用途、安装作用域分类（A～D）与安装命令见 `open_supports/INDEX.md`。

贡献规范见 `open_supports/README.md`。

---

## 快速开始

所有脚本均为 POSIX `sh`，从仓库根目录执行。完整参数见 `scripts/README.md`。

```sh
# 1. 同步个人用户级配置到 ~/.claude（已有 CLAUDE.md 时会询问；检测到旧版残留会警告）
sh ./scripts/install.sh -l user -m ask

# 2. 安装全局支持包（gstack、task-master）：清单复制到 ~/.claude/ 后全局安装
sh ./scripts/install-claude-project.sh -g -d   # 预演，确认后去掉 -d

# 3. 一次安装一个场景的完整项目配置，并安装其清单中的支持包
sh ./scripts/install-claude-project.sh -f frontend-dev -t /path/to/project -d

# 4. 或者只安装某一个维度，例如 settings、skills
sh ./scripts/install-settings.sh -l project -s frontend-dev -m overwrite -p /path/to/project/.claude
sh ./scripts/install-skill-pkg.sh -f frontend-dev -t /path/to/project/.claude/skills

# 5. 把个人差异规则同步到 Codex 的 ~/.codex/AGENTS.md（先预演）
sh scripts/multi_client_support/codex.sh -d
```

注意：

- `install.sh` 在 project/local 层级默认不安装 `dot_claude/settings.json`（个人用户级设定），项目设定请用 `install-settings.sh`。
- 已存在的 `.json` 文件不会被自动覆盖，需手动合并。
- 新增或更新 `open_supports` 支持包时，按 `open_supports/.copilot-skills/ost-support-workflow/SKILL.md` 的流程进行：仓库摘要 → 安装脚本 → setup Skill → 可选 usage examples → 可选安装验证。

---

## 设计原则

1. **只写差异**：`CLAUDE.md` 只写 Claude Code 默认行为之外、确实需要的约束；删掉一条后行为不变，就不该写。
2. **硬约束优先**：权限与沙箱 → hook → Plan mode → 提示词。
3. **按需加载用官方机制**：skill、带 `paths` 的 rule、slash command；不用「需要时读取某文件」。
4. **冲突比缺漏更糟**：修改配置后执行 `/doctor prompt-audit` 检查过时或冲突的指令。
5. **工具接入可复现**：支持包的安装脚本必须幂等、可重复执行、带验证步骤，不依赖一次性的手工操作。
6. **安装不覆盖人工内容**：安装脚本不自动覆盖需要人工合并的 JSON，不删除用户文件；旧版残留只警告或移至备份。

---

## 安全说明

不要把以下内容提交到仓库：API Key、Access Token、私有凭据、`.env` 内容、云资源密钥、生产环境账号信息。

用 `permissions.deny` 屏蔽敏感路径：

```json
{
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)"
    ]
  }
}
```

---

## Roadmap

### 已完成

- [x] 场景化 settings 模板体系（user / project / local）
- [x] Agent 包、Skill 包、CLAUDE.md、`.mcp.json`、项目启动包的脚本化安装
- [x] `open_supports/` 支持包体系与 `ost-support-workflow` 编排流程，已收录 10 个支持包
- [x] `install-open-supports.sh`：单一或按清单安装支持包，项目级 vendor 并生成 wrapper Skill，全局（`-g`）直接运行安装脚本
- [x] `dot_claude_projects/` 场景包聚合各维度配置，`.claude/` 全局清单由 `install-claude-project.sh -g` 安装（2026-10-20）
- [x] Codex 多客户端适配（`codex.sh`）；2026-10-20 改为写入 `~/.codex/AGENTS.md` 标记区块，移除项目级与内嵌
- [x] 转型：分层提示词规则系统归档至 `dot_claude_legacy/`，`dot_claude/` 精简为个人配置（2026-10-19）
- [x] 四个场景的基础配置：全局与场景插件分层、各场景的 `CLAUDE.md`、`.mcp.json`、agent 包与 `open_supports` 清单，见 `settings/README.md`（2026-10-19）
- [x] 清理 `settings/` 模板中过时或无效的设置：写死的模型、无作用的 PreCompact hook 与 `DISABLE_AUTOUPDATER: "0"`、会关闭 thinking 的 `alwaysThinkingEnabled: false`、过宽的管道权限规则（2026-10-19）

### 下一步

- [ ] 将已在其他仓库实现的技能与工具包管理平台 MVP 迁入 `src/`
- [ ] 持续补充和验证 `open_supports/ost_*` 支持包
- [ ] 扩展 `.copilot-skills/`：通用 MCP 注册、版本检测、多客户端配置写入
- [ ] 把仍有价值的场景化指引整理为 skill，而非常驻规则
- [ ] 在真实项目中验证精简后的 `dot_claude/`，以 `/doctor prompt-audit` 定期检查
- [ ] 在真实项目中验证四个场景的配置，并为 `skills/` 四个场景补充自定义 skill

---

## 贡献

本仓库按作者的工作流演进，暂不主动征集贡献。发现问题欢迎开 issue；提交 PR 前请阅读 `CONTRIBUTING.md`。

---

## 许可证

MIT License，详见 LICENSE。
