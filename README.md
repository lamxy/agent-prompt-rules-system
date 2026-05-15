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

`agent-prompt-rules-system` 是一套用于 **Claude Code** 的仓库级规则系统，目标是低 token 消耗、高质量输出、按需加载规则，安全支持工具调用、子代理协作、代理团队协作与周期性任务。

可作为 GitHub 共享规则仓库，也可直接作为 Claude Code CLI 的项目级配置体系使用。

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

## 核心特性

### 分层规则设计
规则系统分为四层：

- **核心提示**：始终生效的默认运行策略
- **场景规约**：按任务场景加载的极简规则
- **输出模板**：用于高频结构化输出
- **可选偏好**：技术、编码风格、个人或仓库约定

### 适合 Claude Code CLI
该仓库结构遵循 Claude Code 的项目级配置思路：

- `CLAUDE.md`：主记忆文件
- `.claude/settings.json`：项目共享设置
- `.claude/rules/`：外部极简规约（task/preference）
- `.claude/expandable/`：模板与审计文档（默认不常驻）

### 面向真实 Agent 工作流
不仅适合普通问答，也适合工具调用、子代理并行、多代理汇总、周期性任务、GitHub 协作与代码实现分析。

支持"软规则"（`CLAUDE.md` + 极简规约 + 模板）与"硬约束"（`hooks` + `permissions` + `sandbox`）组合使用。建议渐进式落地，先最小门禁，再逐步扩展。

### 对开源协作友好
规则文件可以和代码一起版本化管理，便于团队共享、PR 审阅、历史追踪与多仓库复用。

---

## 规则运行方式

核心口径：

> **先最小，后加载；够用即停。**

默认顺序：识别场景 → 加载极简规约 → 必要时展开完整规约 → 必要时加载模板 → 输出前压缩 → 复杂阶段结束后退回极简。

对应仓库维护：`CLAUDE.md` 只保留高杠杆常驻规则；细节外置到 `.claude/rules/` 和 `.claude/expandable/`；模板仅在需要稳定结构时启用。

---

## 当前状态

当前项目处于 **极简规则阶段**，重点是：

- 优化常驻层与场景极简规约
- 优化基础模板
- 进行真实使用中的体验验证与审计

当前阶段暂不把以下能力作为运行前提：

- 完整规约层的系统化展开
- 规则触发决策树
- 规则展开开关条件
- 规约披露风格层
- 独立的规则加载协议文件驱动

当前已完成的补充：

- 补充主代理 / 子代理 / 代理团队在真实协作中的最小完成性与汇总约束。
- 建立 hook 分阶段执行路径（完成性门禁与非阻塞噪音治理）。
- 保持"提示词主控 + hook 护栏"的结构，不把复杂状态机迁移到 hook 层。

---

## 快速开始

### 方式一：直接作为项目级 Claude Code 配置使用
把以下内容放入你的项目：

- `CLAUDE.md`
- `.claude/settings.json`
- 你实际需要的 `.claude/rules/` 文件

`.claude/settings.json` 定位为"全栈基础工具权限基线"，提供通用权限与安全边界，平衡子代理高频调用的审批效率，作为项目级共享基础配置。

然后在项目目录中运行 Claude Code 即可。

### 方式二：作为"规则源仓库"维护
把本仓库作为规则源，在多个工作仓库中同步或复制：

- 主 `CLAUDE.md`
- 通用 `settings.json`
- 高频使用的规则文件

适合：多项目共用一套默认规则、把提示词与规则纳入 Git 管理、希望逐步演进而不是在单仓库临时堆规则。

### 方式三：使用脚本同步与管理配置

按"两步走"理解：先同步完整 `.claude` 目录，再按需叠加场景化 settings 模板。

#### 3.1 优先：同步整个 `.claude` 目录

使用 `scripts/install.sh` 同步完整 `.claude` 目录（规则、命令、基础 settings 等）：

```sh
sh ./scripts/install.sh -l <user|project|local> [-p <target_path>] -m <overwrite|append|ask>
```

关于 `.claude/settings.json` 的处理：

- 目标目录不存在 `settings.json` 时：脚本直接复制基础配置
- 目标目录已存在 `settings.json` 时：应由用户手动处理（避免 JSON 自动拼接导致结构风险）

#### 3.2 再按需：安装场景化 settings 模板

Claude Code settings 按作用域分层管理：

- `user`：用户级，全局个人默认（`~/.claude/settings.json`）
- `project`：项目级，团队共享（`.claude/settings.json`）
- `local`：本地级，当前仓库个人覆盖（`.claude/settings.local.json`，不提交）

优先级：`local > project > user`。

使用 `scripts/install-settings.sh` 安装模板：

```sh
sh ./scripts/install-settings.sh -l <user|project|local> [-s <scenario>] [--src <source_settings_json>] -m <overwrite|merge|ask> [-p <target_dir>]
```

参数说明：

- `-l`：级别（`user|project|local`）
- `-s`：场景名（未使用 `--src` 时从 `settings/` 下自动解析）
- `--src`：自定义源文件，提供后忽略 `-s`
- `-m`：操作方式（`overwrite|merge|ask`）
- `-p/--dst`：目标目录；`user` 默认 `~/.claude`，`project/local` 必填

当前可用场景名：

- `user`：`productivity`（不传 `-s` 时默认回退到 `settings.user.json`）
- `project`：`frontend-dev`、`backend-dev`、`fullstack-dev`、`product-collab`、`release-ops`
- `local`：`frontend-dev`、`backend-dev`、`experimental`、`low-connectivity`

场景含义速览：

- `user/productivity`：个人跨项目默认基线
- `project/*`：团队共享场景基线，按研发类型区分
- `local/*`：当前仓库个人覆盖层，用于实验、弱网或岗位偏好

补充文件：

- `.claude/commands/auditrules.md`：对当前轮执行路径和输出做最小审计。
- `.claude/commands/analyze-github-repo.md`：对复杂 GitHub 仓库执行轻量探测与预算判断。
- `.claude/expandable/audit/audit-failure-examples-min.md`：高频审计失败样例，便于快速对照问题。
- `.claude/expandable/templates/audit-report-template.md`：审计结果落盘的最小 Markdown 结构。

扩展建议：

- 先以 `project` 场景作为团队稳定基线，再用 `local` 做个人覆盖。
- 新增插件时，优先确认其 marketplace 来源，并在模板中同步维护 `extraKnownMarketplaces`。
- 语言类 LSP 插件按仓库技术栈最小化启用；新增场景时，优先复制最接近的现有模板再按需增减。
- 若代理链路较差，优先使用低连通性模板，减少 hook 与插件噪音对主流程的干扰。

示例：

```sh
# 用户级默认模板
sh ./scripts/install-settings.sh -l user -m overwrite

# 项目级前端开发场景
sh ./scripts/install-settings.sh -l project -s frontend-dev -m overwrite -p /path/to/project/.claude

# 本地级实验场景，融合到现有 settings.local.json
sh ./scripts/install-settings.sh -l local -s experimental -m merge -p /path/to/project/.claude

# 本地级弱网场景
sh ./scripts/install-settings.sh -l local -s low-connectivity -m merge -p /path/to/project/.claude

# 使用自定义源文件
sh ./scripts/install-settings.sh -l project --src /path/to/settings.project-team.json -m ask -p /path/to/project/.claude
```

---

## 当前推荐目录结构

```text
.
├── README.md
├── LICENSE
├── CONTRIBUTING.md
├── scripts/
│   ├── install.sh
│   └── install-settings.sh
├── settings/
│   ├── settings.user-productivity.json
│   ├── settings.user.json
│   ├── settings.project-frontend-dev.json
│   ├── settings.project-backend-dev.json
│   ├── settings.project-fullstack-dev.json
│   ├── settings.project-product-collab.json
│   ├── settings.project-release-ops.json
│   ├── settings.project-xxx.json
│   ├── settings.local-frontend-dev.json
│   ├── settings.local-backend-dev.json
│   ├── settings.local-experimental.json
│   ├── settings.local-low-connectivity.json
│   ├── settings.local.json
│   └── ...
└── .claude/
    ├── CLAUDE.md
    ├── RTK.md
    ├── settings.json
    ├── audit-reports/
    │   ├── <xxxx-xx-xx>-<xxx>.md
    ├── commands/
    │   ├── auditrules.md
    │   └── analyze-github-repo.md
    ├── rules/
    │   ├── task/
    │   │   ├── general-task-rule-min.md
    │   │   ├── design-first-rule-min.md
    │   │   ├── loop-cron-rule-min.md
    │   │   ├── sub-agent-rule-min.md
    │   │   ├── agent-team-rule-min.md
    │   │   ├── subagent-cost-rule-min.md
    │   │   └── tool-call-rule-min.md
    │   ├── preferences/
    │   │   ├── network-degraded-preference-min.md
    │   │   └── source-verification-min.md
    └── expandable/
      ├── audit/
      │   ├── rule-audit-checklist-short.md
      │   └── audit-failure-examples-min.md
      ├── preferences/
      │   └── ...
      ├── specs/
      │   └── ...
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
- `CLAUDE.md`

### 场景极简层
```text
task/
  general-task-rule-min.md
  design-first-rule-min.md
  loop-cron-rule-min.md
  sub-agent-rule-min.md
  agent-team-rule-min.md
  tool-call-rule-min.md
  ...
```

### 场景完整层
```text
task/
  general-task-rule.md
  design-first-rule.md
  loop-cron-rule.md
  sub-agent-rule.md
  agent-team-rule.md
  tool-call-rule.md
  ...
```

### 模板层
```text
expandable/templates/
  loop-report-template.md
  tool-result-summary-template.md
  team-leader-output-template.md
  team-agent-output-template.md
  multi-agent-summary-template.md
  sub-agent-output-template.md
  ...
```

### 决策层
- `rule-trigger-decision-tree.md`
- `rule-expansion-decision-tree.md`
- `rule-expansion-switch-conditions.md`

### 披露层
- `rule-disclosure-style-guide.md`

### 串联协议
- `rule-loading-protocol.md`

---

## 设计原则

### 1. 默认最小
主文件只保留高频、稳定、高杠杆、跨场景通用的规则。

### 2. 细节外置
只对某类任务有效的规则，放到外部规约，不膨胀 `CLAUDE.md`。

### 3. 够用即停
当前层已足够完成任务时，不继续叠加更多规则或模板。

### 4. 模板不常驻
模板仅用于：输出结构需要稳定、多工具/多代理结果需要归并、高频重复任务需要统一格式。

### 5. 复杂完成后回退
复杂阶段结束后，尽量退回极简状态，避免临时展开的规则长期常驻。

### 6. 不让规则系统本身成为成本源
规则不应导致 token 膨胀、输出变慢、阅读负担加重或协作门槛提高。

---

## `CLAUDE.md` 与 `.claude/settings.json` 的区别

### `CLAUDE.md`
用于定义主运行策略、记忆文件、任务处理原则、规则分层与加载顺序、可选偏好与引用口。

### `.claude/settings.json`
用于定义权限控制、文件访问限制、工具行为、环境配置、共享项目级设置。

在协作强化场景下，建议将 `.claude/settings.json` 作为"执行约束层"承载：

- `Stop` / `SubagentStop`：最小完成性门禁
- `PostToolUse`：非阻塞噪音分级
- `PreCompact`：最小关键事实保全
- `PreToolUse`：窄范围高风险 `ask`

默认策略：先保障主流程完成，再逐步提高约束强度。

---

## 适用场景

- 使用 Claude Code CLI 的个人开发者
- 想把 `CLAUDE.md` 纳入 Git 管理的团队
- 需要工具调用与外部检索的工程工作流
- 需要子代理拆分与并行处理的任务
- 需要稳定汇总多代理结果的场景
- 希望在多个仓库之间复用规则的用户

---

## 安全说明

不要把以下内容写进共享规则文件：API Key、Access Token、私有凭据、`.env` 中的敏感信息、云资源密钥、生产环境账号信息。

用 `permissions.deny` 屏蔽敏感路径，例如：

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

**建议**：保持 `CLAUDE.md` 稳定；先补 1~3 个最常用外部规约；只对高频场景补模板；先在极简阶段完成体验与审计。

**避免**：把 `CLAUDE.md` 写成万能系统提示词；一次性创建所有规约；提前引入完整层和决策层；让规则系统比业务任务更复杂。

---

## 常见问题

### 1. 所有引用的规则文件都必须存在吗？
不必须。可选文件不存在时，忽略该引用继续执行即可。

### 2. 这套系统是否依赖 Claude Code 自动加载所有外部规则？
不强依赖。支持按需加载时就按需加载；不支持时，这些外部文件仍可作为仓库内可维护的分层规范参考。

### 3. 为什么提到完整规约层、决策层等，但当前并未全部落地？
当前处于**极简规则阶段**，先验证极简层的稳定性和真实使用收益；更复杂的层级属于未来演进方向，不是当前运行前提。

### 4. 是否适合多个仓库复用？
适合，这也是本仓库的重要目标之一。

### 5. 是否适合团队协作？
适合，但建议保持主文件克制，把团队细节下沉到更小的规约文件中。

---

## 演进依据

后续扩展依据：真实痛点、审计结果、输出稳定性、上下文成本、是否带来高杠杆收益。优先实用性、稳定性和可维护性，而不是规则数量。

---

## Roadmap

### 当前阶段
- [x] 建立主 `CLAUDE.md`
- [x] 建立项目级 `settings.json`
- [x] 定义基础分层结构
- [x] 补充子代理偏好与多代理汇总模板
- [x] 以极简规则阶段为主进行体验与审计验证
- [x] 补充真实协作场景下主代理 / 子代理 / 代理团队约束
- [x] 建立分阶段 hook 执行约束（完成性门禁、噪音治理、压缩保全、高风险 ask）

### 下一阶段
- [ ] 补充更完整的 task 规约
- [ ] 验证完整规约层的按需展开策略
- [ ] 补充工具调用摘要模板
- [ ] 补充更细的个人 / 仓库偏好文件
- [ ] 引入决策层与展开条件
- [ ] 引入披露层与串联协议
- [ ] 验证复杂阶段结束后的"退回极简"机制
- [ ] 形成更稳定的多仓库复用方式

---

## 贡献

欢迎贡献，但请优先遵循以下原则：

- 最小优先
- 增量扩展
- 避免 prompt 膨胀
- 先拆文件，再扩主文件
- 优先稳定性，而不是规则数量

详见 [`CONTRIBUTING.md`](./CONTRIBUTING.md)。

---

## 许可证

MIT License，详见 [`LICENSE`](./LICENSE)。

---

## 致谢

结构设计参考了 Claude Code 官方文档关于 `CLAUDE.md`、`settings.json`、配置优先级与权限控制的说明。([docs.claude.com](https://docs.claude.com/en/docs/claude-code/settings?utm_source=openai))
