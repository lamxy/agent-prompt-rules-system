# gstack — 仓库核心介绍

> 官方仓库：[garrytan/gstack](https://github.com/garrytan/gstack)

## 1. 概览

gstack 是 Garry Tan 开源的 AI 编码工作流与技能包，把 Claude Code 和多个 AI 编码 Agent 组织成“Think → Plan → Build → Review → Test → Ship → Reflect”的软件交付流程。

- 核心能力：产品 office hours、CEO/工程/设计/DX 计划评审、代码审查、浏览器 QA、安全审计、发布与部署、复盘、文档生成、跨模型 Codex 复核。
- 安装形态：wrapper 直接安装 Claude Code、Codex CLI、OpenCode、Factory Droid、Kiro，或使用 `auto` 检测；Cursor、Slate、OpenClaw、Hermes、GBrain 需要各自的 upstream 流程。
- 浏览器能力：`/browse`、`/qa`、`/open-gstack-browser` 可驱动 Chromium、截图、测试登录态页面，并提供 prompt injection 防护。
- 记忆能力：`/learn`、GBrain 集成、项目级 learnings 与可选私有同步，用于跨会话保留偏好和工程经验。
- 官方入口：[README](https://github.com/garrytan/gstack)；深度文档见仓库内 `docs/`、`ARCHITECTURE.md`、`BROWSER.md`、`USING_GBRAIN_WITH_GSTACK.md`。

## 2. 安装与更新

### 前置依赖

- Claude Code
- Git
- Bun v1.0+
- Node.js：仅 Windows 需要；README 说明 Windows 上 Bun 的 Playwright pipe transport 有已知问题，browse server 会回退到 Node.js。
- Windows 支持方式：Windows 11 通过 Git Bash 或 WSL 使用；`bun` 和 `node` 都需要在 `PATH` 上。
- Git：wrapper 使用 `GIT_TERMINAL_PROMPT=0`，并在可用时以 `timeout`/`gtimeout` 限制 Git；`GSTACK_GIT_TIMEOUT_SECONDS` 默认 `120`，只能设为正十进制整数。已导出的代理变量会传给 Git 与 upstream `setup`；Docker 测试需显式注入。

### Claude Code：个人安装

在 Claude Code 中粘贴官方安装请求，让 Claude 执行安装并更新 `CLAUDE.md`：

```text
Install gstack: run **`git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup`** then add a "gstack" section to CLAUDE.md that says to use the /browse skill from gstack for all web browsing, never use mcp__claude-in-chrome__* tools, and lists the available skills: /office-hours, /plan-ceo-review, /plan-eng-review, /plan-design-review, /design-consultation, /design-shotgun, /design-html, /review, /ship, /land-and-deploy, /canary, /benchmark, /browse, /connect-chrome, /qa, /qa-only, /design-review, /setup-browser-cookies, /setup-deploy, /setup-gbrain, /retro, /investigate, /document-release, /document-generate, /codex, /cso, /autoplan, /plan-devex-review, /devex-review, /careful, /freeze, /guard, /unfreeze, /gstack-upgrade, /learn. Then ask the user if they also want to add gstack to the current project so teammates get it.
```

其中实际 shell 命令是：

```bash
git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup
```

### Claude Code：团队模式 / 共享仓库自动更新

从目标项目仓库内运行：

```bash
(cd ~/.claude/skills/gstack && ./setup --team) && ~/.claude/skills/gstack/bin/gstack-team-init required && git add .claude/ CLAUDE.md && git commit -m "require gstack for AI-assisted work"
```

如果只想提示队友而不是强制要求，官方说明是把 `required` 换成 `optional`。团队模式不把 gstack 文件 vendor 到项目内；Claude Code 会在会话启动时做节流的静默自动更新检查。

### OpenClaw：Claude Code 会话内使用 gstack

给 OpenClaw agent 粘贴官方安装请求：

```text
Install gstack: run `git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup` to install gstack for Claude Code. Then add a "Coding Tasks" section to AGENTS.md that says: when spawning Claude Code sessions for coding work, tell the session to use gstack skills. Include these examples — security audit: "Load gstack. Run /cso", code review: "Load gstack. Run /review", QA test a URL: "Load gstack. Run /qa https://...", build a feature end-to-end: "Load gstack. Run /autoplan, implement the plan, then run /ship", plan before building: "Load gstack. Run /office-hours then /autoplan. Save the plan, don't implement."
```

OpenClaw 官方文档补充：OpenClaw 集成是 prompt/template 与 native skills，不需要额外 daemon 或 JSON-RPC 协议。

### OpenClaw：ClawHub 原生方法论技能

```bash
clawhub install gstack-openclaw-office-hours gstack-openclaw-ceo-review gstack-openclaw-investigate gstack-openclaw-retro
```

这些是 OpenClaw agent 直接在聊天中运行的对话技能，不需要 Claude Code 会话。

### 其他 AI Agent：自动检测安装

```bash
git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/gstack
cd ~/gstack && ./setup
```

### 其他 AI Agent：指定 host 安装

官方格式：

```bash
./setup --host <name>
```

官方 README 列出的 host 与目标路径：

| Agent | Flag | Skills install to |
|---|---|---|
| OpenAI Codex CLI | `--host codex` | `~/.codex/skills/gstack-*/` |
| OpenCode | `--host opencode` | `~/.config/opencode/skills/gstack-*/` |
| Factory Droid | `--host factory` | `~/.factory/skills/gstack-*/` |
| Kiro | `--host kiro` | `~/.kiro/skills/gstack-*/` |
| Auto-detected installed host | `--host auto` | Determined by upstream setup |

Cursor and Slate are not installed by current upstream `setup`, so this wrapper
rejects them before Git runs. OpenClaw, Hermes, and GBrain use a separate
artifact-generation or session workflow rather than this wrapper.

### Windows / WSL 差异

- Windows 11：通过 Git Bash 或 WSL 使用；除 Bun 外还需要 Node.js。
- Windows 无 Developer Mode（MSYS2 / Git Bash）：`setup` 会回退为文件复制而不是符号链接；每次 `git pull` 后都要重新运行：

```bash
cd ~/.claude/skills/gstack && ./setup
```

- Unix 和 WSL：官方说明会保留 symlink，不需要在每次 `git pull` 后重跑 `setup`。

### 更新命令

官方主路径：

```text
/gstack-upgrade
```

可选自动更新配置：

```bash
gstack-config set auto_upgrade true
```

README 中针对 Codex 技能描述过期的修复命令：

```bash
cd ~/.codex/skills/gstack && git pull && ./setup --host codex
```

仓库本地安装时：

```bash
cd "$(readlink -f .agents/skills/gstack)" && git pull && ./setup --host codex
```

Windows 无 Developer Mode 时，每次手动 `git pull` 后重跑：

```bash
cd ~/.claude/skills/gstack && ./setup
```

### 验证命令

官方 README 没有发布独立的 `--version` 或 `doctor` 验证命令。官方故障排查给出的最小恢复/确认动作是：

```bash
cd ~/.claude/skills/gstack && ./setup
```

浏览器能力失败时，官方给出的构建确认命令是：

```bash
cd ~/.claude/skills/gstack && bun install && bun run build
```

实际可用性验证应在对应 Agent 内运行 README quick start 中的 slash command，例如 `/office-hours`；若 Claude 看不到技能，按 README 把 `## gstack` 与可用技能列表加入项目 `CLAUDE.md`。

## 3. 使用示例

官方 README 的最小体验路径：

```text
/office-hours
/plan-ceo-review
/review
/qa https://staging.myapp.com
```

- `/office-hours`：先描述要构建的产品，gstack 会提出约束性问题并产出可被后续技能读取的设计文档。
- `/plan-ceo-review`：读取设计文档并做战略与范围评审。
- `/review`：在已有分支改动上做代码审查，自动修复明显问题并标出需要用户确认的问题。
- `/qa https://staging.myapp.com`：打开真实浏览器测试 staging URL，发现问题后可修复并生成回归测试。

## 4. 注意事项

- gstack 是工作流与技能系统，不是传统库 SDK；主要入口是 Agent slash command 和安装脚本。
- 团队模式会在 Claude Code 会话启动时做静默自动更新检查；网络失败安全，且节流到每小时一次。
- Windows 上 Bun 与 Playwright pipe transport 有已知问题，browse server 会回退到 Node.js，因此 Windows 必须安装 Node.js。
- Windows 无 Developer Mode 时 symlink 不可用，`setup` 会复制文件；每次 `git pull` 后必须重跑 `setup`。
- OpenClaw 集成不提供独立 daemon；它依赖 ACP 启动 Claude Code 会话或 ClawHub 原生对话技能。
- 远程 telemetry 默认关闭；首次运行会询问是否发送匿名使用数据，且官方说明不会发送代码、路径、仓库名、分支、prompt 或用户生成内容。
- GitHub Releases API 当前未返回 latest release；版本与变更以仓库 README/CHANGELOG 为准。

---

## 5. 补充与延伸

- 卸载：优先运行 `~/.claude/skills/gstack/bin/gstack-uninstall`；手动删除步骤见 README 的 [Uninstall](https://github.com/garrytan/gstack#uninstall)。
- OpenClaw 高级 dispatch routing、gstack-lite/full/plan 模板与 `OPENCLAW_SESSION` 行为见 [docs/OPENCLAW.md](https://github.com/garrytan/gstack/blob/main/docs/OPENCLAW.md)。
- 新增 Agent host 的配置、生成、验证与测试流程见 [docs/ADDING_A_HOST.md](https://github.com/garrytan/gstack/blob/main/docs/ADDING_A_HOST.md)。
- GBrain 初始化、Supabase/PGLite/remote MCP 路径、同步和 Conductor 环境变量说明见 [USING_GBRAIN_WITH_GSTACK.md](https://github.com/garrytan/gstack/blob/main/USING_GBRAIN_WITH_GSTACK.md)。
- `/browse` 命令、浏览器会话与 CDP 相关细节见 [BROWSER.md](https://github.com/garrytan/gstack/blob/main/BROWSER.md)。
- 架构、prompt injection defense 与 sidebar agent 设计见 [ARCHITECTURE.md](https://github.com/garrytan/gstack/blob/main/ARCHITECTURE.md)。
- 版本变化见 [CHANGELOG.md](https://github.com/garrytan/gstack/blob/main/CHANGELOG.md)。
