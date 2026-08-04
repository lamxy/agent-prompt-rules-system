# GSD Core — 仓库核心介绍

> **安装作用域（模式 D / 本地为 B）**：官方 `--global` 写入用户级配置；`--local` 以当前工作目录识别目标项目。支持包的本地命令必须带 `TARGET_DIR`，脚本会检查目录并在子 Shell 中 `cd` 后运行官方命令：`sh scripts_for_install/install.sh --claude --local /path/to/project`。全局命令不需要项目路径：`sh scripts_for_install/install.sh --claude --global`。依据：[官方安装文档](https://docs.opengsd.net/core/installation)。

> 官方仓库：[open-gsd/gsd-core](https://github.com/open-gsd/gsd-core)
> 官方文档：[Open GSD Docs](https://docs.opengsd.net/) / [GSD Core Installation](https://docs.opengsd.net/core/installation)

## 1. 概览

GSD Core 是面向 AI 编程运行时的轻量级 meta-prompting、上下文工程和 spec-driven development 工作流系统，把开发拆成 discuss -> plan -> execute -> verify -> ship 的阶段循环。

- 支持 Claude Code、OpenCode、Gemini CLI、Kimi CLI、Kilo、Codex、Copilot、Cursor、Windsurf / Devin Desktop、Cline、Qwen Code 等运行时。
- 用 fresh-context subagents 承担重型调研、规划和执行，降低长上下文质量衰减。
- 通过 `.planning/` 中的 `PROJECT.md`、`REQUIREMENTS.md`、`ROADMAP.md`、`STATE.md`、phase artifacts 持久化项目状态。
- 安装器会按目标运行时转换 schema、目录布局、命令命名和 hook 配置；官方明确不建议直接复制 `agents/` 或 `commands/`。
- 官方仓库：https://github.com/open-gsd/gsd-core；官方文档：https://docs.opengsd.net/。

## 2. 安装与更新

### 前置依赖

- Node.js >= 22.0.0
- npm >= 10.0.0

检查命令：

```bash
node --version
npm --version
```

Codex 运行时另需 Codex CLI >= 0.130.0；官方检查命令：

```bash
codex --version
```

### 标准交互式安装

macOS / Linux / WSL / Windows（已安装 Node.js 与 npm/npx）均使用同一官方命令：

```bash
npx @opengsd/gsd-core@latest
```

安装器会交互式选择 runtime 与 global/local scope。官方文档还给出一次性安装全部支持运行时的命令：

```bash
npx @opengsd/gsd-core@latest --all --global
```

### 按运行时非交互安装

Claude Code：

```bash
npx @opengsd/gsd-core@latest --claude --global
CLAUDE_CONFIG_DIR=~/.claude-alt npx @opengsd/gsd-core@latest --claude --global
```

Claude Code native plugin：

```bash
claude plugin install gsd-core
claude plugin enable gsd-core
claude plugin disable gsd-core
claude plugin update gsd-core
```

Gemini CLI：

```bash
npx @opengsd/gsd-core@latest --gemini --global
GEMINI_CONFIG_DIR=~/.gemini-alt npx @opengsd/gsd-core@latest --gemini --global
```

Gemini native extension：

```bash
gemini extensions install https://github.com/open-gsd/gsd-core   # install
gemini extensions update gsd-core                                # update
gemini extensions uninstall gsd-core                             # remove
gemini extensions link /path/to/gsd-core                         # dev: symlink a checkout
```

OpenCode：

```bash
npx @opengsd/gsd-core@latest --opencode --global
OPENCODE_CONFIG_DIR=~/.config/opencode-alt npx @opengsd/gsd-core@latest --opencode --global
```

Kilo：

```bash
npx @opengsd/gsd-core@latest --kilo --global
KILO_CONFIG_DIR=~/.config/kilo-alt npx @opengsd/gsd-core@latest --kilo --global
```

Codex：

```bash
npx @opengsd/gsd-core@latest --codex --global
```

Kimi CLI：

```bash
npx @opengsd/gsd-core@latest --kimi --global
/skill:gsd-new-project
kimi --agent-file ~/.config/agents/agents/gsd.yaml
kimi --agent-file ~/.agents/agents/gsd.yaml
npx @opengsd/gsd-core@latest --kimi --global --config-dir ~/.kimi-code
kimi --agent-file ~/.kimi-code/agents/gsd.yaml
KIMI_CONFIG_DIR=~/.kimi-code npx @opengsd/gsd-core@latest --kimi --global
```

GitHub Copilot：

```bash
npx @opengsd/gsd-core@latest --copilot --global
COPILOT_CONFIG_DIR=~/.copilot-alt npx @opengsd/gsd-core@latest --copilot --global
```

Cursor：

```bash
npx @opengsd/gsd-core@latest --cursor --global
CURSOR_CONFIG_DIR=~/.cursor-alt npx @opengsd/gsd-core@latest --cursor --global
```

Windsurf / Devin Desktop：

```bash
npx @opengsd/gsd-core@latest --windsurf --global
# or equivalently:
npx @opengsd/gsd-core@latest --devin-desktop --global
WINDSURF_CONFIG_DIR=~/.codeium/windsurf-alt npx @opengsd/gsd-core@latest --windsurf --global
```

Cline：

```bash
# Global install (all projects — skills + rules directory)
npx @opengsd/gsd-core@latest --cline --global

# Local install (this project only — rules directory only)
npx @opengsd/gsd-core@latest --cline --local
```

CodeBuddy：

```bash
npx @opengsd/gsd-core@latest --codebuddy --global
```

Qwen Code：

```bash
npx @opengsd/gsd-core@latest --qwen --global
QWEN_CONFIG_DIR=~/.qwen-alt npx @opengsd/gsd-core@latest --qwen --global
```

Augment Code：

```bash
npx @opengsd/gsd-core@latest --augment --global
```

Antigravity：

```bash
npx @opengsd/gsd-core@latest --antigravity --global
ANTIGRAVITY_CONFIG_DIR=~/.gemini/antigravity-alt npx @opengsd/gsd-core@latest --antigravity --global
```

Trae：

```bash
npx @opengsd/gsd-core@latest --trae --global
```

### Local / prerelease / no-Node 安装

Local scope 示例：

```bash
npx @opengsd/gsd-core@latest --claude --local
```

Prerelease runtime config-dir 示例：

```bash
WINDSURF_CONFIG_DIR=~/.codeium/windsurf-next npx @opengsd/gsd-core@latest --windsurf --global
```

Windows 或其他无 Node.js 机器的官方替代路径之一，是在有 Node.js 的 WSL、Linux VM、CI runner 或 Docker container 上运行安装器，再复制输出目录。官方 OpenCode 示例：

```bash
npx @opengsd/gsd-core@latest --opencode --global
# Then copy ~/.config/opencode/agents/ to the Windows machine
```

另一条无 Node.js 路径是手动转换源文件；不要猜测转换规则，按官方 [Manual install / no-Node.js setup](https://github.com/open-gsd/gsd-core/blob/main/docs/USER-GUIDE.md) 与安装器转换函数执行。

### 更新命令

稳定版更新（官方安装页）：重新运行安装命令，安装器是幂等的，会备份本地修改文件。

```bash
npx @opengsd/gsd-core@latest
```

运行时内更新（官方仓库更新页）：

```bash
/gsd-update
/gsd-update --sync
/gsd-update --reapply
/gsd-update --next
```

RC 通道等价命令：

```bash
/gsd-update --next
# or equivalently:
/gsd-update --rc
```

Claude plugin 与 Gemini extension 的更新命令分别是：

```bash
claude plugin update gsd-core
gemini extensions update gsd-core                                # update
```

### 验证命令

安装后重启目标运行时并运行对应命令：

```bash
/gsd-new-project
```

Gemini CLI 使用：

```bash
/gsd:new-project
```

Codex 使用：

```bash
$gsd-new-project
```

命令被识别并开始询问项目问题，即代表安装成功。

## 3. 使用示例

最小新项目流程（Claude Code / Copilot / OpenCode / Kilo 的 hyphen form）：

```bash
/gsd-new-project
/clear
/gsd-discuss-phase 1
/gsd-plan-phase 1
/gsd-execute-phase 1
/gsd-verify-work 1
/gsd-ship 1
```

Gemini CLI 将 `/gsd-` 替换为 `/gsd:`；Codex 将 slash command 替换为 dollar-prefix skill form，例如 `$gsd-plan-phase 1`。

## 4. 注意事项

- 官方安装器是跨运行时兼容的必要步骤；直接复制 `agents/` 或 `commands/` 会绕过转换，可能导致 schema 校验错误或命令缺失。
- docs.opengsd.net 安装页和仓库 `package.json` 均要求 Node.js >= 22.0.0、npm >= 10.0.0；仓库内旧版 `docs/how-to/install-on-your-runtime.md` 仍出现 Node.js 18+，下游脚本应按当前官方站点与 package engines 处理。
- 安装或更新后通常需要重启目标运行时；Codex 可重启或运行 `codex --reload`。
- Gemini 若 `settings.json` 中有 `hooksConfig.enabled: false`，GSD hooks 会被 Gemini CLI 静默禁用。
- Cline 项目级 hooks 只在 macOS 和 Linux 运行；官方说明全局 hook 目录尚未由安装器填充。
- Kimi 集成区分 legacy `kimi-cli` 与 Kimi Code：`--agent-file` 属于 legacy `kimi-cli`，Kimi Code 使用 skills root / `--skills-dir`。

---

## 5. 补充与延伸

- 官方 README：https://github.com/open-gsd/gsd-core
- 官方安装页：https://docs.opengsd.net/core/installation
- 仓库安装深度页：https://github.com/open-gsd/gsd-core/blob/main/docs/how-to/install-on-your-runtime.md
- 官方更新页：https://github.com/open-gsd/gsd-core/blob/next/docs/how-to/update-gsd.md
- 首个项目教程：https://docs.opengsd.net/core/quickstart
- 工作流命令参考：https://docs.opengsd.net/core/commands/workflow-commands
- 配置参考：https://github.com/open-gsd/gsd-core/blob/next/docs/CONFIGURATION.md
- CLI tools 参考：https://github.com/open-gsd/gsd-core/blob/next/docs/CLI-TOOLS.md
- 无 Node.js / 手动转换路径入口：https://github.com/open-gsd/gsd-core/blob/main/docs/USER-GUIDE.md
