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

`agent-prompt-rules-system` 是一套用于 **Claude Code** 的仓库级规则系统，目标是：

- 低 token 消耗
- 高质量输出
- 少重复
- 可控的上下文增长
- 按需加载规则
- 安全支持工具调用、子代理协作、代理团队协作与周期性任务

它既可以作为：

1. **GitHub 仓库中的共享规则入口**
2. **Claude Code CLI 的项目级记忆与配置体系**

Claude Code 官方文档说明，`CLAUDE.md` 用于在启动时向 Claude Code 提供指令和上下文，`.claude/settings.json` 用于项目级共享设置，例如权限、工具行为等。([docs.claude.com](https://docs.claude.com/en/docs/claude-code/settings?utm_source=openai))

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

也就是说：

- 把高频、稳定、高杠杆的原则放在 `CLAUDE.md`
- 把场景细节拆到外部极简规约
- 只在必要时使用模板
- 避免让规则系统本身成为新的上下文负担

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
- `.claude/rules/`：外部极简规约与模板

Claude Code 官方文档说明，项目共享设置适合提交到源码管理；而 `.claude/settings.local.json` 适合个人偏好与本地实验，不应作为团队共享配置。([docs.claude.com](https://docs.claude.com/en/docs/claude-code/settings?utm_source=openai))  
Claude Code 也提供了清晰的配置作用域与优先级模型，包括用户级、项目级和本地项目级设置。([code.claude.com](https://code.claude.com/docs/en/configuration?utm_source=openai))

### 面向真实 Agent 工作流
不仅适合普通问答，也适合：

- 工具调用
- 子代理并行
- 多代理汇总
- 周期性任务
- GitHub 协作
- 代码实现与仓库分析

并且支持将“软规则”与“硬约束”组合使用：

- 软规则：`CLAUDE.md` + 极简场景规约 + 输出模板
- 硬约束：`hooks` + `permissions` + `sandbox`

建议采用渐进式落地：先最小门禁，再逐步扩展，避免一次性引入过多拦截造成协作阻塞。

### 对开源协作友好
规则文件可以和代码一起版本化管理，便于：

- 团队共享
- PR 审阅
- 历史追踪
- 多仓库复用

---

## 规则运行闭环

这套规则系统的目标不是一次性加载全部规则，而是采用**渐进式、可回退**的加载方式。

默认运行顺序如下：

1. 主系统最小规则常驻
2. 先识别任务场景
3. 先加载场景极简规约
4. 必要时才展开完整规约
5. 必要时才加载模板
6. 输出前先压缩结果
7. 必要时才向用户披露规约命中
8. 复杂阶段结束后退回极简状态

这意味着本仓库的重点不是“规则越多越好”，而是：

- 默认最小
- 按需展开
- 结果压缩
- 复杂完成后回收上下文复杂度

---

## 当前状态

当前项目仍处于 **极简规则阶段**，重点在：

- 优化常驻层
- 优化场景极简规约
- 优化基础模板
- 进行真实使用中的体验验证
- 进行审计与稳定性验证

当前阶段暂不依赖以下能力作为运行前提：

- 完整规约层的系统化展开
- 规则触发决策树
- 规则展开开关条件
- 规约披露风格层
- 独立的规则加载协议文件驱动

这些内容是未来演进方向，而不是当前阶段的硬依赖。

补充（真实协作场景迭代）：

- 已补充主代理 / 子代理 / 代理团队在真实协作中的最小完成性与汇总约束。
- 已建立 hook 分阶段执行路径（优先完成性门禁与非阻塞噪音治理）。
- 保持“提示词主控 + hook 护栏”的结构，不把复杂状态机迁移到 hook 层。

---

## 快速开始

### 方式一：直接作为项目级 Claude Code 配置使用
把以下内容放入你的项目：

- `CLAUDE.md`
- `.claude/settings.json`
- 你实际需要的 `.claude/rules/` 文件

其中 `.claude/settings.json` 在本仓库中主要定位为一份“全栈基础工具权限基线”：

- 提供通用的工具权限与安全边界
- 在子代理高频工具调用场景下，平衡审批效率与安全要求
- 作为项目级共享的基础配置，便于团队统一行为

然后在项目目录中运行 Claude Code 即可。

Claude Code Quickstart 说明了 CLI 的安装、登录和项目目录内启动方式。([code.claude.com](https://code.claude.com/docs/en/quickstart?utm_source=openai))

### 方式二：作为“规则源仓库”维护
把本仓库作为规则源，在多个工作仓库中同步或复制：

- 主 `CLAUDE.md`
- 通用 `settings.json`
- 高频使用的规则文件

适合以下场景：

- 多项目共用一套默认规则
- 希望把提示词与规则纳入 Git 管理
- 希望逐步演进，而不是在单仓库中临时堆规则

### 方式三：使用脚本同步与管理配置

本仓库重点是提示词规约体系；settings 模板用于辅助常见开发场景下的插件分类与组合。

#### 3.1 优先：同步整个 `.claude` 目录（规约与基础配置）

使用 `scripts/install.sh` 同步完整 `.claude` 目录（规则、命令、基础 settings 等）：

```sh
sh ./scripts/install.sh -l <user|project|local> [-p <target_path>] -m <overwrite|append|ask>
```

关于 `.claude/settings.json` 的处理建议：

- 目标目录不存在 `settings.json` 时：脚本会直接复制基础配置
- 目标目录已存在 `settings.json` 时：应由用户决策并手动处理（避免 JSON 自动拼接导致结构或语义风险）

#### 3.2 再按需：安装场景化 settings 模板（插件分类方案）

Claude Code settings 推荐按作用域分层管理：

- `user`：用户级，全局个人默认（`~/.claude/settings.json`）
- `project`：项目级，团队共享（`.claude/settings.json`）
- `local`：本地级，当前仓库个人覆盖（`.claude/settings.local.json`，不提交）

优先级：`local > project > user`。

使用 `scripts/install-settings.sh` 按级别和场景安装模板：

```sh
sh ./scripts/install-settings.sh -l <user|project|local> [-s <scenario>] [--src <source_settings_json>] -m <overwrite|merge|ask> [-p <target_dir>]
```

参数说明（简版）：

- `-l`：级别（`user|project|local`）
- `-s`：场景名（未使用 `--src` 时从 `settings/` 下自动解析模板）
- `--src`：自定义源 settings 文件，提供后会忽略 `-s`
- `-m`：操作方式（`overwrite|merge|ask`）
- `-p/--dst`：目标目录；`user` 默认 `~/.claude`，`project/local` 必填

当前可用场景名：

- `user`：`productivity`（不传 `-s` 时默认回退到 `settings.user.json`）
- `project`：`frontend-dev`、`backend-dev`、`fullstack-dev`、`product-collab`、`release-ops`
- `local`：`frontend-dev`、`backend-dev`、`experimental`、`low-connectivity`

场景基线定位（用于二次扩展）：

- `user/productivity`：个人跨项目通用协作基线，强调代码托管、任务协同与基础提交流程。
- `project/frontend-dev`：前端研发链路基线，覆盖设计协作、TypeScript 代码智能、评审与部署联动。
- `project/backend-dev`：后端研发链路基线，覆盖服务侧语言智能、可观测性与后端平台集成。
- `project/fullstack-dev`：前后端混合项目基线，适用于需要跨端协同和统一评审流的仓库。
- `project/product-collab`：产品/设计/研发协同基线，强调需求、文档、设计稿和代码协作闭环。
- `project/release-ops`：发布与运维基线，强调变更交付、监控告警、发布平台与沟通通道。
- `local/frontend-dev`、`local/backend-dev`：个人在当前仓库内的技术偏好覆盖层，用于按岗位快速收敛插件组合。
- `local/experimental`：个人实验层，用于临时验证新插件或新组合，不影响团队共享基线。
- `local/low-connectivity`：个人弱网或代理不稳定覆盖层，用于减少 hook 与插件噪音，优先保障主流程完成。

命令补充：

- `.claude/commands/auditrules.md`：对当前轮执行路径和输出做最小审计。
- `.claude/commands/analyze-github-repo.md`：对复杂 GitHub 仓库执行轻量探测、预算判断和超预算升级。

审计辅助：

- `.claude/rules/audit/audit-failure-examples-min.md`：收录高频审计失败样例，便于快速对照 `L3 / S3 / S4 / 超预算未升级` 等问题。
- `.claude/rules/templates/audit-report-template.md`：提供审计结果落盘的最小 Markdown 结构。

扩展建议（推荐）：

- 先以 `project` 场景作为团队稳定基线，再用 `local` 做个人覆盖，避免团队配置频繁抖动。
- 新增外部集成插件时，优先确认其 marketplace 来源，并在模板中同步维护 `extraKnownMarketplaces`。
- 语言类 LSP 插件按仓库技术栈最小化启用，避免无关插件增加资源开销与噪音。
- 新增场景时，建议复制最接近的现有模板并重命名为 `settings.<level>-<scenario>.json`，再按需增减插件。
- 若代理链路较差、Fast mode 经常不可用，优先使用低连通性模板，减少 hook 与插件噪音对主流程的干扰。

示例：

```sh
# 用户级默认模板（自动回退到 settings/settings.user.json）
sh ./scripts/install-settings.sh -l user -m overwrite

# 项目级前端开发场景
sh ./scripts/install-settings.sh -l project -s frontend-dev -m overwrite -p /path/to/project/.claude

# 本地级实验场景，融合到现有 settings.local.json
sh ./scripts/install-settings.sh -l local -s experimental -m merge -p /path/to/project/.claude

# 本地级弱网 / 代理不稳定场景
sh ./scripts/install-settings.sh -l local -s low-connectivity -m merge -p /path/to/project/.claude

# 使用自定义源文件
sh ./scripts/install-settings.sh -l project --src /path/to/settings.project-team.json -m ask -p /path/to/project/.claude
```

---

## 当前推荐目录结构

当前仓库建议使用的结构，以**极简规则阶段**为主：

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
    │   ├── 2026-04-28-hook-baseline-matrix-draft.md
    │   ├── 2026-04-28-hook-phase1-execution.md
    │   ├── 2026-04-28-hook-phase2-3-execution.md
    │   └── 2026-04-28-hook-phase4-execution.md
    ├── commands/
    │   ├── auditrules.md
    │   └── analyze-github-repo.md
    └── rules/
    ├── audit/
    │   ├── rule-audit-checklist-short.md
    │   └── audit-failure-examples-min.md
    ├── task/
    │   ├── general-task-rule-min.md
    │   ├── design-first-rule-min.md
    │   ├── loop-cron-rule-min.md
    │   ├── sub-agent-rule-min.md
    │   ├── agent-team-rule-min.md
    │   ├── subagent-cost-rule-min.md
    │   ├── subagent-input-rule-min.md
    │   └── tool-call-rule-min.md
    ├── templates/
    │   ├── audit-report-template.md
    │   ├── dispatch-template.md
    │   ├── loop-report-template.md
    │   ├── tool-result-summary-template.md
    │   ├── team-leader-output-template.md
    │   ├── team-agent-output-template.md
    │   ├── multi-agent-summary-template.md
    │   └── sub-agent-output-template.md
    └── preferences/
      ├── network-degraded-preference-min.md
      ├── source-verification-min.md
      └── README.md
```

> 注意：不是所有文件都需要一开始就存在。  
> 对于可选偏好文件，如果文件不存在、不可读，或当前环境不支持加载，可以直接忽略，不应阻断任务执行。

---

## 目标架构（演进方向）

本项目的目标闭环结构如下。

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
templates/
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

需要说明的是：以上结构描述的是**目标演进方向**，并不代表当前仓库已完整实现所有层级。

---

## 设计原则

### 1. 默认最小
主文件只保留：

- 高频
- 稳定
- 高杠杆
- 跨场景通用

的规则。

### 2. 细节外置
如果某条规则只对某一类任务有效，应优先放到外部规约，而不是持续膨胀 `CLAUDE.md`。

### 3. 够用即停
如果当前层已经足够完成任务，就不要继续叠加更多规则或模板。

### 4. 模板不常驻
模板只在这些场景下使用：

- 输出结构需要稳定
- 多工具或多代理结果需要归并
- 高频重复任务需要统一格式

### 5. 复杂完成后回退
复杂阶段结束后，应尽量退回极简状态，避免把临时展开的复杂规则长期常驻。

### 6. 不让规则系统本身成为成本源
不要因为“规则很多”而导致：

- token 变大
- 输出变慢
- 阅读负担变重
- 协作门槛变高

---

## `CLAUDE.md` 与 `.claude/settings.json` 的区别

### `CLAUDE.md`
用于定义：

- 主运行策略
- 记忆文件
- 任务处理原则
- 规则分层与加载顺序
- 可选偏好与引用口

### `.claude/settings.json`
用于定义：

- 权限控制
- 文件访问限制
- 工具行为
- 环境相关配置
- 共享项目级设置

在协作强化场景下，建议将 `.claude/settings.json` 作为“执行约束层”承载：

- `Stop` / `SubagentStop`：最小完成性门禁
- `PostToolUse`：非阻塞噪音分级
- `PreCompact`：最小关键事实保全
- `PreToolUse`：窄范围高风险 `ask`

默认策略：先保障主流程完成，再逐步提高约束强度。

Claude Code 官方文档明确区分了这两类文件的职责，并说明了设置优先级：命令行参数、本地项目设置、共享项目设置、用户设置等会按优先级叠加。([docs.claude.com](https://docs.claude.com/en/docs/claude-code/settings?utm_source=openai); [code.claude.com](https://code.claude.com/docs/en/configuration?utm_source=openai))

---

## 适用场景

这套规则系统特别适合以下场景：

- 使用 Claude Code CLI 的个人开发者
- 想把 `CLAUDE.md` 纳入 Git 管理的团队
- 需要工具调用与外部检索的工程工作流
- 需要子代理拆分与并行处理的任务
- 需要稳定汇总多代理结果的场景
- 希望在多个仓库之间复用规则的用户

---

## 安全说明

请不要把以下内容写进共享规则文件：

- API Key
- Access Token
- 私有凭据
- `.env` 中的敏感信息
- 云资源密钥
- 生产环境账号信息

Claude Code 官方建议使用 `.claude/settings.json` 中的 `permissions.deny` 来屏蔽敏感文件或目录，避免被 Claude Code 读取。([docs.claude.com](https://docs.claude.com/en/docs/claude-code/settings?utm_source=openai))

例如：

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

### 建议先做的事
- 保持 `CLAUDE.md` 稳定
- 先补最常用的 1~3 个外部规约
- 对高频场景再补模板
- 先在极简阶段完成体验与审计
- 不要一开始就把所有想法写满

### 不建议做的事
- 把 `CLAUDE.md` 写成一个巨大的万能系统提示词
- 一次性创建所有规约文件
- 在极简阶段提前引入过多完整层和决策层
- 用大量低频细节污染主文件
- 让模板长期常驻
- 让规则系统比业务任务更复杂

---

## 常见问题

### 1. 所有引用的规则文件都必须存在吗？
不必须。  
可选文件不存在时，应忽略该引用，继续按已有规则执行。

### 2. 这套系统是否依赖 Claude Code 自动加载所有外部规则？
不强依赖。  
如果当前环境支持按需加载，就按需加载；如果不支持，这些外部文件仍然可以作为仓库内可维护的分层规范参考。

### 3. 为什么 README 中提到完整规约层、决策层、披露层和串联协议，但当前仓库并未全部落地？
因为当前项目仍处于**极简规则阶段**。  
现阶段重点是先验证极简层是否足够稳定、是否便于审计、是否能在真实使用中形成高杠杆收益；更复杂的层级属于未来演进方向，而不是当前运行前提。

### 4. 是否适合多个仓库复用？
适合。  
这也是本仓库的重要目标之一：让规则可以被版本化、迁移和复用。

### 5. 是否适合团队协作？
适合，但建议保持主文件克制，把团队细节下沉到更小的规约文件中。

---

## 演进依据

本项目不会为了“体系完整”而提前引入全部层级。  
后续是否扩展完整规约、决策层、披露层和串联协议，将主要依据以下信号逐步推进：

- 真实使用中的高频痛点
- 审计验证结果
- 失败与重试模式
- 输出稳定性是否提升
- 上下文成本是否可控
- 是否确实带来高杠杆收益

换句话说，本项目更重视：

- 实用性
- 稳定性
- 可回退性
- 长期可维护性

而不是规则数量本身。

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
- [ ] 验证复杂阶段结束后的“退回极简”机制
- [ ] 形成更稳定的多仓库复用方式

---

## 贡献

欢迎贡献，但请优先遵循以下原则：

- 最小优先
- 增量扩展
- 避免 prompt 膨胀
- 先拆文件，再扩主文件
- 优先稳定性，而不是规则数量

更详细说明见：

- [`CONTRIBUTING.md`](./CONTRIBUTING.md)

---

## 许可证

本项目采用 MIT License，详见：

- [`LICENSE`](./LICENSE)

---

## 致谢

本仓库的结构设计参考了 Claude Code 官方文档中关于：

- `CLAUDE.md`
- 项目级共享设置
- `.claude/settings.json`
- 配置优先级
- 安全权限控制

等机制的说明。([docs.claude.com](https://docs.claude.com/en/docs/claude-code/settings?utm_source=openai); [code.claude.com](https://code.claude.com/docs/en/configuration?utm_source=openai))
