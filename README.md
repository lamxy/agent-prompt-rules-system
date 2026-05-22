# Agent Prompt Rules System

<p align="center">
  一套面向 <strong>Claude Code</strong> 的可扩展主代理规则系统：<br />
  <strong>低 token、高质量、按需加载、适合工具调用、派发任务、与子代理/代理团队协作。</strong>
</p>

<p align="center">
  <img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/lamxy/agent-prompt-rules-system?style=flat-square" />
  <img alt="GitHub last commit" src="https://img.shields.io/github/last-commit/lamxy/agent-prompt-rules-system?style=flat-square" />
  <img alt="GitHub License" src="https://img.shields.io/github/license/lamxy/agent-prompt-rules-system?style=flat-square" />
  <img alt="Claude Code" src="https://img.shields.io/badge/Claude%20Code-project%20memory-purple?style=flat-square" />
  <img alt="Prompt Style" src="https://img.shields.io/badge/prompt-minimal%20%26%20layered-orange?style=flat-square" />
</p>

---

## 项目简介

`agent-prompt-rules-system` 是一套用于 **Claude Code** 的可扩展规则与配置系统，目标是低 token 消耗、高质量输出、按需加载规则，安全支持工具调用、子代理协作、代理团队协作与周期性任务。

可作为 GitHub 共享规则仓库，也可直接作为 Claude Code CLI 的用户级或项目级配置体系使用。

---

## 为什么要做这个仓库

随着 Claude Code 在真实项目中的使用增加，规则文件很容易出现这些问题：

- 主提示词越来越长
- 规则重复堆叠
- 多轮对话中上下文膨胀过快
- 子代理与工具调用缺少统一约束
- 团队协作时难以复用和维护

本仓库的核心思路是：

> **主文件尽量短，细节尽量外置；先最小，后加载；够用即停。**

高频稳定原则放 `CLAUDE.md`，场景细节拆到外部极简规约，只在必要时使用模板，避免让规则系统本身成为上下文负担。

---

## 仓库结构概览

本仓库由三类内容组成：

### 一、`.claude/` — 核心规则与配置目录

`.claude/` 是 Claude Code 的配置根目录，包含主规则文件、场景极简规约、可扩展内容和基础 settings，可通过 `scripts/install.sh` 同步到**用户级**（`~/.claude`）或**项目级**（项目的 `.claude/` 目录）。

```
.claude/
├── CLAUDE.md              # 主记忆文件，始终生效的默认运行策略
├── RTK.md                 # 补充参考文档
├── settings.json          # 项目级权限与工具配置基线
├── commands/              # 自定义命令（审计、GitHub 仓库分析等）
├── hooks/                 # 执行门禁与护栏（SubagentStop、PostToolUse 等）
├── rules/                 # 按需自动加载的极简规约
│   ├── task/              # 场景规约（通用任务、设计、子代理、团队等）
│   └── preferences/       # 偏好规约（弱网、信息源验证等）
└── expandable/            # 按需展开的扩展内容（默认不常驻）
    ├── audit/             # 审计检查清单与失败样例
    ├── preferences/       # 可扩展的详细偏好与风格规范
    ├── specs/             # 完整规约层（极简规约的详细版，待逐步完善）
    └── templates/         # 高频结构化输出模板
```

**`expandable/` 目录说明：**
- `preferences/`：存放项目或团队级详细偏好（技术栈、编码风格等），极简偏好规约不够用时按需引用
- `specs/`：存放完整规约层，是 `rules/` 下各极简规约的详细版（规约细节、边界更完整清晰），随项目演进逐步填充
- `templates/`：存放高频结构化输出模板，仅在需要稳定格式时启用

### 二、场景包目录 — 按项目/场景集中管理，按需安装

这些目录用于集中存放各场景的相关文件，通过 `scripts/` 下对应脚本输出到目标项目目录，不会自动影响任何项目。

| 目录 | 内容 | 安装脚本 |
|------|------|---------|
| `settings/` | 按作用域和场景分类的 settings 模板 | `install-settings.sh` |
| `agents/` | 按场景分组的 agent 定义包（`agents-<FLAG>/`） | `install-agent-pkg.sh` |
| `skills/` | 按场景分组的 skill 技能包（`skills-<FLAG>/`） | `install-skill-pkg.sh` |
| `claude_mds/` | 按场景分类的 CLAUDE.md 配置文件（`CLAUDE-<FLAG>.md`） | `install-claude-md.sh` |

### 三、`docs/` — 文档与教程目录

`docs/` 用于沉淀设计说明、使用手册与外部资源整理，便于使用者快速理解、上手与后续扩展。

其中 `docs/recommend_repos/` 专门用于收集和整理优秀仓库，按来源分组维护：

- `official/`：官方仓库与官方工具链
- `github/`：开源社区仓库（含已验证的实践向导）
- `custom/`：团队或个人自定义推荐仓库

`recommend_repos` 下的文档维护原则：

- 每个推荐仓库都应配套可复现的详细使用教程文档
- 教程应覆盖：仓库定位、适用场景、安装/接入步骤、最小可运行示例、常见问题与排错
- 优先给出面向 Agent 编码场景的实操流程，而不只做链接汇总

当前 `docs/recommend_repos/github/` 已包含多份详细中文教程（如 `code-review-graph`、`GET SHIT DONE`、`Graphify`、`gstack`、`OpenSpec`）。

---

## 核心特性

### 分层规则设计
规则系统分为四层：

- **核心提示**：始终生效的默认运行策略（`CLAUDE.md`）
- **场景规约**：按任务场景加载的极简规则（`rules/`）
- **输出模板**：用于高频结构化输出（`expandable/templates/`）
- **可选偏好**：技术、编码风格、个人或仓库约定（`expandable/preferences/`）

### 适合 Claude Code CLI
遵循 Claude Code 的配置分层：`CLAUDE.md`（主记忆）→ `rules/`（极简规约）→ `expandable/`（按需展开）→ `settings.json`（权限约束）。

### 面向真实 Agent 工作流
支持工具调用、子代理并行、多代理汇总、周期性任务、GitHub 协作与代码实现分析。  
支持"软规则"（`CLAUDE.md` + 极简规约 + 模板）与"硬约束"（`hooks` + `permissions` + `sandbox`）组合使用。

### 对开源协作友好
规则文件可以和代码一起版本化管理，便于团队共享、PR 审阅、历史追踪与多仓库复用。

---

## 规则运行方式

核心口径：

> **先最小，后加载；够用即停。**

默认顺序：识别场景 → 加载极简规约 → 必要时展开完整规约（`expandable/specs/`）→ 必要时加载模板 → 输出前压缩 → 复杂阶段结束后退回极简。

---

## 快速开始

### 方式一：直接作为项目级 Claude Code 配置使用

把以下内容放入你的项目：

- `.claude/CLAUDE.md`
- `.claude/settings.json`
- 你实际需要的 `.claude/rules/` 文件

然后在项目目录中运行 Claude Code 即可。

### 方式二：作为"规则源仓库"维护

把本仓库作为规则源，在多个工作仓库中同步或复制。适合：多项目共用一套默认规则、把提示词与规则纳入 Git 管理、希望逐步演进而不是在单仓库临时堆规则。

### 方式三：使用脚本同步与安装

#### 3.1 同步 `.claude` 目录（用户级或项目级）

使用 `scripts/install.sh` 将整个 `.claude` 目录（规则、命令、hooks、基础 settings 等）同步到用户级或项目级：

```sh
sh ./scripts/install.sh -l <user|project|local> [-p <target_path>] -m <overwrite|append|ask>
```

- `-l user`：同步到用户级默认路径 `~/.claude`（全局生效）
- `-l project`：同步到指定项目的 .claude 目录（项目级共享）
- `-l local`：同步到本地个人覆盖目录

> `.json` 文件已存在时脚本自动跳过，需手动合并以保证 JSON 结构合法。

#### 3.2 安装场景化 settings 模板

Claude Code settings 按作用域分层，优先级：`local > project > user`。

```sh
sh install-settings.sh -l <user|project|local> [-s <scenario>] [--src <source_settings_json>] -m <overwrite|merge|ask> [-p <target_dir>]
```

当前可用场景：

| 作用域 | 场景名 |
|--------|--------|
| `user` | `productivity`（默认） |
| `project` | `frontend-dev`、`backend-dev`、`fullstack-dev`、`product-collab`、`release-ops` |
| `local` | `frontend-dev`、`backend-dev`、`experimental`、`low-connectivity` |

```sh
# 用户级默认
sh ./scripts/install-settings.sh -l user -m overwrite

# 项目级前端场景
sh ./scripts/install-settings.sh -l project -s frontend-dev -m overwrite -p /path/to/project/.claude

# 本地弱网场景（融合到已有配置）
sh ./scripts/install-settings.sh -l local -s low-connectivity -m merge -p /path/to/project/.claude
```

#### 3.3 安装 Agent 包

```sh
sh ./scripts/install-agent-pkg.sh -f <FLAG> -t /path/to/project/.claude/agents [-F]
```

将 `agents/agents-<FLAG>/` 下的 `*.md` 文件安装到目标项目的 agents 目录。`-F` 表示强制覆盖同名文件。

#### 3.4 安装 Skill 包

```sh
sh ./scripts/install-skill-pkg.sh -f <FLAG> -t /path/to/project/.claude/skills [-F]
```

将 `skills/skills-<FLAG>/` 下的技能目录安装到目标项目的 skills 目录。

#### 3.5 安装 CLAUDE.md 配置

```sh
sh ./scripts/install-claude-md.sh -f <FLAG> -t /path/to/project [-n CLAUDE.md] [-F]
```

将 `claude_mds/CLAUDE-<FLAG>.md` 复制为目标项目的 CLAUDE.md（或 `AGENTS.md`、`GEMINI.md` 等）。

---

## 完整目录结构

```text
.
├── README.md
├── LICENSE
├── CONTRIBUTING.md
├── scripts/
│   ├── install.sh               # 同步 .claude 目录（用户级/项目级）
│   ├── install-settings.sh      # 安装场景化 settings 模板
│   ├── install-agent-pkg.sh     # 安装 agent 包
│   ├── install-skill-pkg.sh     # 安装 skill 包
│   └── install-claude-md.sh     # 安装 CLAUDE.md 配置
├── settings/                    # Settings 模板集合
│   ├── settings.user.json
│   ├── settings.user-productivity.json
│   ├── settings.project-frontend-dev.json
│   ├── settings.project-backend-dev.json
│   ├── settings.project-fullstack-dev.json
│   ├── settings.project-product-collab.json
│   ├── settings.project-release-ops.json
│   ├── settings.local-frontend-dev.json
│   ├── settings.local-backend-dev.json
│   ├── settings.local-experimental.json
│   ├── settings.local-low-connectivity.json
│   └── ...
├── agents/                      # Agent 包集合（按场景分组）
│   ├── agents-<FLAG>/           # 每个包含该场景所需的 *.md agent 定义
│   └── ...
├── skills/                      # Skill 包集合（按场景分组）
│   ├── skills-<FLAG>/           # 每个包含该场景所需的 skill 子目录
│   └── ...
├── claude_mds/                  # CLAUDE.md 配置文件集合（按场景分类）
│   ├── CLAUDE-<FLAG>.md
│   └── ...
├── docs/                        # 文档与教程目录
│   ├── claude-memory-and-slimming-rationale.md
│   └── recommend_repos/         # 推荐仓库集合与详细教程
│       ├── README.md
│       ├── official/            # 官方仓库推荐
│       ├── custom/              # 自定义仓库推荐
│       └── github/              # 开源仓库推荐与详细使用教程
│           ├── code-review-graph 详细使用教程
│           ├── GET SHIT DONE-详细使用教程
│           ├── Graphify-详细使用教程
│           ├── gstack-详细使用教程
│           └── OpenSpec-详细使用教程
└── .claude/                     # 核心规则与配置（可直接同步到项目）
    ├── CLAUDE.md
    ├── RTK.md
    ├── settings.json
    ├── commands/
    │   ├── auditrules.md
    │   └── analyze-github-repo.md
    ├── hooks/
    ├── rules/
    │   ├── task/
    │   │   ├── general-task-rule-min.md
    │   │   ├── design-first-rule-min.md
    │   │   ├── loop-cron-rule-min.md
    │   │   ├── sub-agent-rule-min.md
    │   │   ├── agent-team-rule-min.md
    │   │   ├── subagent-cost-rule-min.md
    │   │   └── tool-call-rule-min.md
    │   └── preferences/
    │       ├── network-degraded-preference-min.md
    │       └── source-verification-min.md
    └── expandable/
        ├── audit/
        │   ├── rule-audit-checklist-short.md
        │   └── audit-failure-examples-min.md
        ├── preferences/         # 详细偏好规范（按需引用）
        ├── specs/               # 完整规约层（极简规约的详细版，待逐步完善）
        └── templates/
            ├── audit-report-template.md
            ├── dispatch-template.md
            ├── loop-report-template.md
            ├── tool-result-summary-template.md
            ├── team-leader-output-template.md
            ├── team-agent-output-template.md
            ├── multi-agent-summary-template.md
            └── sub-agent-output-template.md
```

> 可选文件不存在时，忽略该引用继续执行即可，不应阻断任务执行。

---

## 目标架构（演进方向）

后续可能扩展到的完整分层（不代表当前已实现）：

### 常驻层
- CLAUDE.md

### 场景极简层（当前已实现）
```text
rules/task/
  general-task-rule-min.md
  design-first-rule-min.md
  loop-cron-rule-min.md
  sub-agent-rule-min.md
  agent-team-rule-min.md
  tool-call-rule-min.md
  ...
```

### 场景完整层（存放于 `expandable/specs/`，待逐步完善）
```text
expandable/specs/task/
  general-task-rule.md
  design-first-rule.md
  loop-cron-rule.md
  sub-agent-rule.md
  agent-team-rule.md
  tool-call-rule.md
  ...
```

### 模板层（存放于 `expandable/templates/`）
```text
expandable/templates/
  loop-report-template.md
  tool-result-summary-template.md
  team-leader-output-template.md
  ...
```

### 决策层
- `rule-trigger-decision-tree.md`
- `rule-expansion-switch-conditions.md`

### 披露层 & 串联协议
- `rule-disclosure-style-guide.md`
- `rule-loading-protocol.md`

---

## 设计原则

1. **默认最小**：主文件只保留高频、稳定、高杠杆、跨场景通用的规则。
2. **细节外置**：只对某类任务有效的规则，放到外部规约，不膨胀 CLAUDE.md。
3. **够用即停**：当前层已足够完成任务时，不继续叠加更多规则或模板。
4. **模板不常驻**：模板仅用于输出结构需要稳定、多工具/多代理结果需要归并的场景。
5. **复杂完成后回退**：复杂阶段结束后尽量退回极简状态，避免临时展开的规则长期常驻。
6. **规则系统不是成本源**：规则不应导致 token 膨胀、输出变慢或协作门槛提高。

---

## CLAUDE.md 与 settings.json 的区别

**CLAUDE.md**：定义主运行策略、记忆文件、任务处理原则、规则分层与加载顺序、可选偏好与引用口。

**settings.json**：定义权限控制、文件访问限制、工具行为、环境配置、共享项目级设置。

在协作强化场景下，建议将 `settings.json` 作为"执行约束层"承载：

- `Stop` / `SubagentStop`：最小完成性门禁
- `PostToolUse`：非阻塞噪音分级
- `PreCompact`：最小关键事实保全
- `PreToolUse`：窄范围高风险 `ask`

默认策略：先保障主流程完成，再逐步提高约束强度。

---

## 当前状态

当前项目处于**极简规则阶段**，重点是：

- 优化常驻层与场景极简规约
- 优化基础模板
- 进行真实使用中的体验验证与审计

当前已完成：

- 主代理 / 子代理 / 代理团队在真实协作中的最小完成性与汇总约束
- 子代理纠正流程：必须用 `SendMessage`（to 现有 agentId），不得重新派发新实例
- Hook 分阶段执行路径（完成性门禁、噪音治理、压缩保全、高风险 ask）
- 完整的场景化 settings 模板体系（user / project / local 三层）
- agent 包、skill 包、CLAUDE.md 配置包的脚本化安装支持

暂不作为当前运行前提：完整规约层系统化展开、规则触发决策树、规约披露风格层、串联协议文件驱动。

---

## 适用场景

- 使用 Claude Code CLI 的个人开发者
- 想把 CLAUDE.md 纳入 Git 管理的团队
- 需要工具调用与外部检索的工程工作流
- 需要子代理拆分与并行处理的任务
- 需要稳定汇总多代理结果的场景
- 希望在多个仓库之间复用规则的用户

---

## 安全说明

不要把以下内容写进共享规则文件：API Key、Access Token、私有凭据、`.env` 中的敏感信息、云资源密钥、生产环境账号信息。

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

## 使用建议

**建议**：保持 CLAUDE.md 稳定；先补 1~3 个最常用外部规约；只对高频场景补模板；先在极简阶段完成体验与审计。

**避免**：把 CLAUDE.md 写成万能系统提示词；一次性创建所有规约；提前引入完整层和决策层；让规则系统比业务任务更复杂。

---

## 常见问题

**1. 所有引用的规则文件都必须存在吗？**  
不必须。可选文件不存在时，忽略该引用继续执行即可。

**2. 这套系统是否依赖 Claude Code 自动加载所有外部规则？**  
不强依赖。支持按需加载时就按需加载；不支持时，这些外部文件仍可作为仓库内可维护的分层规范参考。

**3. `expandable/specs/` 和 `rules/` 有什么区别？**  
`rules/` 下是极简规约，够用且轻量，默认加载；`expandable/specs/` 是对应极简规约的完整版，规约细节和边界更清晰，仅在需要更精确约束时按需引用，不常驻上下文。

**4. 是否适合多个仓库复用？**  
适合，这也是本仓库的重要目标之一。

**5. 是否适合团队协作？**  
适合，但建议保持主文件克制，把团队细节下沉到更小的规约文件中。

---

## Roadmap

### 当前阶段（已完成）
- [x] 建立主 CLAUDE.md 与项目级 `settings.json`
- [x] 定义基础分层结构（`rules/` 极简规约 + `expandable/` 扩展内容）
- [x] 补充子代理偏好与多代理汇总模板
- [x] 以极简规则阶段为主进行体验与审计验证
- [x] 补充真实协作场景下主代理 / 子代理 / 代理团队约束
- [x] 建立分阶段 hook 执行约束（完成性门禁、噪音治理、压缩保全、高风险 ask）
- [x] 场景化 settings 模板体系（user / project / local）
- [x] Agent 包、Skill 包、CLAUDE.md 配置包的脚本化安装（`v1.2.1`）
- [x] 子代理纠正流程规范化（SendMessage 优先，禁止重新派发）

### 下一阶段
- [ ] 补充完整规约层（`expandable/specs/`）并验证按需展开策略
- [ ] 补充更细的个人 / 仓库偏好文件（`expandable/preferences/`）
- [ ] 引入决策层与展开条件
- [ ] 引入披露层与串联协议
- [ ] 验证复杂阶段结束后的"退回极简"机制
- [ ] 形成更稳定的多仓库复用方式

---

## 演进依据

后续扩展依据：真实痛点、审计结果、输出稳定性、上下文成本、是否带来高杠杆收益。优先实用性、稳定性和可维护性，而不是规则数量。

---

## 贡献

欢迎贡献，但请优先遵循以下原则：

- 最小优先
- 增量扩展
- 避免 prompt 膨胀
- 先拆文件，再扩主文件
- 优先稳定性，而不是规则数量

详见 CONTRIBUTING.md。

---

## 许可证

MIT License，详见 LICENSE。

---

## 致谢

结构设计参考了 Claude Code 官方文档关于 CLAUDE.md、`settings.json`、配置优先级与权限控制的说明。([docs.claude.com](https://docs.claude.com/en/docs/claude-code/settings))