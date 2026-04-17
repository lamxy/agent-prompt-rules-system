# Agent Prompt Rules System

<p align="center">
  一套面向 <strong>Claude Code</strong> 的可扩展主代理规则系统：<br />
  <strong>低 token、高质量、按需加载、适合工具调用与子代理协作。</strong>
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

Claude Code 官方文档也说明了项目级 `.claude/settings.json` 与 `CLAUDE.md` 的职责划分，以及设置优先级模型。([docs.claude.com](https://docs.claude.com/en/docs/claude-code/settings?utm_source=openai))

### 面向真实 Agent 工作流
不仅适合普通问答，也适合：

- 工具调用
- 子代理并行
- 多代理汇总
- 周期性任务
- GitHub 协作
- 代码实现与仓库分析

### 对开源协作友好
规则文件可以和代码一起版本化管理，便于：

- 团队共享
- PR 审阅
- 历史追踪
- 多仓库复用

---

## 快速开始

### 方式一：直接作为项目级 Claude Code 配置使用
把以下内容放入你的项目：

- `CLAUDE.md`
- `.claude/settings.json`
- 你实际需要的 `.claude/rules/` 文件

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

---

## 推荐目录结构

```text
.
├── README.md
├── LICENSE
├── CONTRIBUTING.md
├── CLAUDE.md
└── .claude/
    ├── settings.json
    └── rules/
        ├── task/
        │   ├── general-task-rule-min.md
        │   ├── design-first-rule-min.md
        │   ├── loop-cron-rule-min.md
        │   ├── sub-agent-rule-min.md
        │   ├── agent-team-rule-min.md
        │   └── tool-call-rule-min.md
        ├── templates/
        │   ├── loop-report-template.md
        │   ├── tool-result-summary-template.md
        │   ├── team-leader-output-template.md
        │   ├── team-agent-output-template.md
        │   ├── multi-agent-summary-template.md
        │   └── sub-agent-output-template.md
        └── preferences/
            ├── tech-stack-preference-min.md
            ├── code-style-preference-min.md
            ├── personal-preference-min.md
            ├── sub-agent-preference-min.md
            ├── repo-convention-min.md
            └── github-workflow-min.md
```

> 注意：不是所有文件都需要一开始就存在。  
> 对于可选偏好文件，如果文件不存在、不可读，或当前环境不支持加载，可以直接忽略，不应阻断任务执行。

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

### 5. 不让规则系统本身成为成本源
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

Claude Code 官方文档明确区分了这两类文件的职责，并说明了设置优先级：命令行参数、本地项目设置、共享项目设置、用户设置等会按优先级叠加。([docs.claude.com](https://docs.claude.com/en/docs/claude-code/settings?utm_source=openai))

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
- 不要一开始就把所有想法写满

### 不建议做的事
- 把 `CLAUDE.md` 写成一个巨大的万能系统提示词
- 一次性创建所有规约文件
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

### 3. 是否适合多个仓库复用？
适合。  
这也是本仓库的重要目标之一：让规则可以被版本化、迁移和复用。

### 4. 是否适合团队协作？
适合，但建议保持主文件克制，把团队细节下沉到更小的规约文件中。

---

## Roadmap

当前建议的演进顺序：

- [x] 建立主 `CLAUDE.md`
- [x] 建立项目级 `settings.json`
- [x] 定义基础分层结构
- [x] 补充子代理偏好与多代理汇总模板
- [ ] 补充常用 task 规约
- [ ] 补充工具调用摘要模板
- [ ] 补充更细的个人 / 仓库偏好文件
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
- 项目级共享��置
- `.claude/settings.json`
- 配置优先级
- 安全权限控制

等机制的说明。([docs.claude.com](https://docs.claude.com/en/docs/claude-code/settings?utm_source=openai))