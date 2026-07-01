# Agency Agents — 仓库核心介绍

> 官方仓库：[msitarzewski/agency-agents](https://github.com/msitarzewski/agency-agents)
> 官方文档：[Agency Agents App](https://agencyagents.app/)

## 1. 概览

Agency Agents 是一套面向 AI 编程工具的多代理提示词与安装脚本集合，用来把专业化 agent、slash commands 和相关配置安装到 Claude Code、Codex、OpenCode、Rovo Dev 等工具中。

核心能力：

- 提供 CTO、CEO、Product Manager、Frontend Developer、Backend Developer、QA Engineer 等预置专业 agent。
- 支持按 division/team 安装，也支持只安装单个 agent。
- 为 Claude Code 提供原生 `.claude/agents` 安装路径。
- 为 Codex、OpenCode、GitHub Copilot、Rovo Dev、Crush、Cursor、Gemini CLI、Amp、Qodo CLI、Kilo Code 等工具提供转换与安装脚本。
- 提供 macOS/Windows/Linux 桌面应用，用图形界面配置并安装 Agency Agents。

官方入口：

- 主仓库 README：https://github.com/msitarzewski/agency-agents
- 桌面应用文档：https://agencyagents.app/
- 桌面应用 release：https://github.com/msitarzewski/agency-agents-app/releases/latest

## 2. 安装与更新

### 前置依赖

- 官方 README 的脚本命令使用 POSIX shell 风格命令，适用于 macOS、Linux 或 WSL 这类 shell 环境；README 未给出单独的 WSL 差异命令。
- 桌面应用支持 macOS、Windows 和 Linux。
- 官方 README 未声明 Node.js、Python、Go 等运行时版本要求。
- 官方 README 示例假定已经取得 `msitarzewski/agency-agents` 仓库内容，并从仓库根目录运行脚本；README 未给出单独的 `git clone` 安装命令。

### 桌面应用安装

macOS：

- 直接下载安装包：在 https://github.com/msitarzewski/agency-agents-app/releases/latest 选择对应 macOS asset。
- README 给出的 Homebrew 命令：

```sh
brew install --cask msitarzewski/agency-agents/agency-agents
```

- 官方网站给出的 Homebrew 命令：

```sh
brew tap msitarzewski/agency-agents
brew install --cask agency-agents
```

Linux：

- 直接下载安装包：在 https://github.com/msitarzewski/agency-agents-app/releases/latest 选择对应 Linux asset。

Windows：

- 直接下载安装包：在 https://github.com/msitarzewski/agency-agents-app/releases/latest 选择对应 Windows asset。

从源码构建桌面应用：

```sh
git clone https://github.com/msitarzewski/agency-agents-app.git
cd agency-agents-app
npm install
npm run dev
```

桌面应用更新：

- 官方网站说明应用内置自动更新，会在新版本发布时提示。
- Homebrew 更新命令：

```sh
brew upgrade --cask agency-agents
```

桌面应用验证：

- 官方未给出命令行验证命令；可通过启动 Agency Agents App 并选择 AI tool、agent source 和 target directory 验证。

### Claude Code 安装

完整交互式安装：

```sh
./scripts/install.sh
```

安装全部 agents：

```sh
./scripts/install.sh --all
```

安装指定 division/team：

```sh
./scripts/install.sh --division engineering
./scripts/install.sh --team frontend
```

安装单个 agent：

```sh
./scripts/install.sh --agent frontend-developer
```

指定目标目录：

```sh
./scripts/install.sh --target /path/to/project/.claude/agents
```

列出可用 division 和 team：

```sh
./scripts/install.sh --list divisions
./scripts/install.sh --list teams
```

预览安装：

```sh
./scripts/install.sh --division engineering --dry-run
```

强制覆盖：

```sh
./scripts/install.sh --all --force
```

手动安装：

```sh
cp agents/engineering/frontend-developer.md ~/.claude/agents/
cp agents/engineering/backend-developer.md ~/.claude/agents/
cp agents/product/product-manager.md ~/.claude/agents/
```

### 其他 AI 工具安装

快速转换并安装到所有支持的工具：

```sh
./scripts/quick-install-all-tools.sh
```

按工具转换并安装：

```sh
./scripts/install.sh --tool codex --division engineering
./scripts/install.sh --tool opencode --division engineering
./scripts/install.sh --tool gemini-cli --all
```

转换到所有工具，不安装：

```sh
./scripts/convert-all-tools.sh
```

并行安装到常用工具：

```sh
./scripts/install-multi-tool.sh --tools codex,opencode,github-copilot --division engineering
```

非交互安装全部 agents：

```sh
./scripts/install-multi-tool.sh --tools all --all --non-interactive
```

只转换到指定工具：

```sh
./scripts/convert-to-tool.sh codex
```

只安装到指定工具：

```sh
./scripts/install.sh --tool codex
```

Codex：

```sh
./scripts/install.sh --tool codex --division engineering
```

OpenCode：

```sh
./scripts/install.sh --tool opencode --division engineering
```

GitHub Copilot：

```sh
./scripts/install.sh --tool github-copilot --division engineering
```

Rovo Dev：

```sh
./scripts/install.sh --tool rovo-dev --division engineering
```

Crush：

```sh
./scripts/install.sh --tool crush --division engineering
```

Cursor：

```sh
./scripts/install.sh --tool cursor --division engineering
```

Gemini CLI：

```sh
./scripts/install.sh --tool gemini-cli --division engineering
```

Amp：

```sh
./scripts/install.sh --tool amp --division engineering
```

Qodo CLI：

```sh
./scripts/install.sh --tool qodo-cli --division engineering
```

Kilo Code：

```sh
./scripts/install.sh --tool kilo-code --division engineering
```

更新已转换的工具文件：

```sh
./scripts/convert-all-tools.sh
```

CLI/脚本验证：

```sh
./scripts/install.sh --list teams
./scripts/install.sh --tool opencode --division engineering --dry-run
codex --help
opencode agent list
copilot --help
```

## 3. 使用示例

Claude Code 最小路径：

```sh
./scripts/install.sh --division engineering
```

这会把 Engineering division 的 agents 安装到 Claude Code 默认 agents 目录。安装后在 Claude Code 中用自然语言提到相应角色，例如 “Use Frontend Developer to review this component”，即可触发对应 agent。

其他工具最小路径：

```sh
./scripts/install.sh --tool codex --division engineering
```

这会为 Codex 转换并安装 Engineering division 的 agents；安装完成后可用 `codex --help` 验证 Codex CLI 可用。

## 4. 注意事项

- 官方 README 未声明运行时版本要求；安装脚本下游不要擅自添加 Node.js/Python 版本门槛。
- Claude Code 支持 full agent specification；其他工具通过转换脚本适配，功能等价性取决于目标工具支持的 agent/command 格式。
- 部分工具可能需要手动配置或认证；README 在 troubleshooting 中建议先确认对应 CLI 可用。
- 多工具安装涉及多个目标目录，使用 `--dry-run` 可先检查将写入哪些文件。
- 若修改或新增源 agent 文件，需要重新运行转换脚本同步到其他工具格式。

---

## 5. 补充与延伸

- 桌面应用的安装、配置、自动更新与源码构建说明见：https://agencyagents.app/
- 桌面应用最新二进制下载见：https://github.com/msitarzewski/agency-agents-app/releases/latest
- Claude Code 安装脚本、手动安装、覆盖、dry-run 和选择性安装见主 README 的 “Installation” 与 “Selection Options”：https://github.com/msitarzewski/agency-agents
- 多工具转换和安装命令见主 README 的 “Multi-Tool Integrations” 与 “Quick Start”：https://github.com/msitarzewski/agency-agents
- 各工具的目标目录和命令格式见主 README 的 “Supported Tools” 与 “Generated Structure”：https://github.com/msitarzewski/agency-agents
- 转换后同步流程见主 README 的 “Regenerating After Changes”：https://github.com/msitarzewski/agency-agents
- 故障排查命令见主 README 的 “Troubleshooting”：https://github.com/msitarzewski/agency-agents
