# OpenSpec — 仓库核心介绍

> 官方仓库：[Fission-AI/OpenSpec](https://github.com/Fission-AI/OpenSpec)
> 官方文档：[Documentation Home](https://github.com/Fission-AI/OpenSpec/blob/main/docs/README.md)

## 1. 概览

OpenSpec 是一个面向 AI 编码助手的轻量级规格驱动工作流工具，用 `openspec` CLI 和 `/opsx:*` slash commands 帮助人和 AI 先对齐需求、再实现代码。

- 在项目内生成 `openspec/specs/` 与 `openspec/changes/`，把当前行为和待实现变更分开管理。
- 每个变更通常包含 proposal、delta specs、design、tasks 等工件。
- 默认核心流程包含 `/opsx:explore`、`/opsx:propose`、`/opsx:apply`、`/opsx:sync`、`/opsx:archive`。
- 支持 25+ AI coding tools，并按工具生成 skills / commands。
- 适合 brownfield 与 greenfield 项目；官方强调 fluid、iterative、easy。

官方入口：

- 仓库：https://github.com/Fission-AI/OpenSpec
- Getting Started：https://github.com/Fission-AI/OpenSpec/blob/main/docs/getting-started.md
- CLI Reference：https://github.com/Fission-AI/OpenSpec/blob/main/docs/cli.md
- Supported Tools：https://github.com/Fission-AI/OpenSpec/blob/main/docs/supported-tools.md

## 2. 安装与更新

### 前置依赖

官方要求：

```bash
node --version
```

- **Node.js 20.19.0 or higher**
- Bun 可用于全局安装 OpenSpec，但 OpenSpec 当前仍运行在 Node.js 上，`PATH` 中仍需要 Node.js 20.19.0 or higher。

### npm

```bash
npm install -g @fission-ai/openspec@latest
```

### pnpm

```bash
pnpm add -g @fission-ai/openspec@latest
```

### yarn

```bash
yarn global add @fission-ai/openspec@latest
```

### bun

```bash
bun add -g @fission-ai/openspec@latest
```

### Nix：直接运行

```bash
nix run github:Fission-AI/OpenSpec -- init
```

### Nix：安装到 profile

```bash
nix profile install github:Fission-AI/OpenSpec
```

### Nix：加入 flake.nix 开发环境

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    openspec.url = "github:Fission-AI/OpenSpec";
  };

  outputs = { nixpkgs, openspec, ... }: {
    devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
      buildInputs = [ openspec.packages.x86_64-linux.default ];
    };
  }
}
```

### 初始化项目

安装后进入目标项目并初始化：

```bash
cd your-project
openspec init
```

`openspec init` 也支持非交互工具选择：

```bash
# Configure specific tools
openspec init --tools claude,cursor

# Configure all supported tools
openspec init --tools all

# Skip tool configuration
openspec init --tools none

# Override profile for this init run
openspec init --profile core
```

### 平台差异

官方安装文档未给出 macOS、Linux、WSL、Windows 的不同安装命令；package manager 安装方式按 npm/pnpm/yarn/bun/Nix 分列。Nix flake 示例使用 `x86_64-linux`。Codex 的 command files 安装到全局 Codex home：`$CODEX_HOME/prompts/`，未设置时为 `~/.codex/prompts/`。

### 验证安装

```bash
openspec --version
```

### 更新

README 的更新流程：

```bash
npm install -g @fission-ai/openspec@latest
```

```bash
openspec update
```

Installation guide 的组合命令：

```bash
npm install -g @fission-ai/openspec@latest   # or pnpm/yarn/bun equivalent
openspec update                              # run inside each project
```

CLI reference 的 update 示例：

```bash
# Update instruction files after npm upgrade
npm update @fission-ai/openspec
openspec update
```

`openspec update` 会按当前 global profile、selected workflows 与 delivery mode 重新生成项目里的 AI tool configuration files。

## 3. 使用示例

最小主路径：

```text
TERMINAL   $ npm install -g @fission-ai/openspec@latest
TERMINAL   $ cd your-project && openspec init
AI CHAT      /opsx:explore                    (optional: think it through first)
AI CHAT      /opsx:propose add-dark-mode      (AI drafts the plan; you review it)
AI CHAT      /opsx:apply                      (AI builds it)
AI CHAT      /opsx:archive                    (specs updated, change filed away)
```

理解要点：

- `openspec ...` 在终端运行；`/opsx:...` 在 AI assistant chat 中输入。
- `/opsx:explore` 用于先澄清想法；已有明确目标时可直接 `/opsx:propose <what-you-want-to-build>`。
- `/opsx:archive` 会把完成的变更归档，并更新 specs。

可用 CLI 做基本检查：

```bash
# List active changes
openspec list

# View change details
openspec show add-dark-mode

# Validate spec formatting
openspec validate add-dark-mode

# Interactive dashboard
openspec view
```

## 4. 注意事项

- 早期最常见混淆点是命令输入位置：`openspec` CLI 在 terminal；`/opsx:*` slash commands 在 AI chat。
- `openspec init` 默认是交互式；脚本或 CI 场景应使用 `--tools` 等非交互选项。
- 默认 global profile 是 `core`，包含 `propose`、`explore`、`apply`、`sync`、`archive`；expanded workflows 需要通过 `openspec config profile` 启用，再运行 `openspec update` 应用。
- Skills / commands 的生成数量取决于 profile、workflow selection 与 delivery mode，不是固定数量。
- Stores、worksets 等功能标记为 Beta，命令名、flags、文件格式和 JSON output 可能在版本间变化。
- OpenSpec 收集匿名 usage stats；可用 `OPENSPEC_TELEMETRY=0` 或 `DO_NOT_TRACK=1` 关闭，CI 中会自动禁用。
- 官方 Usage Notes 建议使用 high-reasoning models，并在开始实现前保持干净上下文。

---

## 5. 补充与延伸

- 卸载不是单个 `openspec uninstall` 命令；需移除全局 package、可选删除项目 `openspec/`，并清理各工具生成的 `openspec-*` skills 与 `opsx-*` commands。原文：https://github.com/Fission-AI/OpenSpec/blob/main/docs/installation.md#uninstalling
- 每个 AI tool 的 skill / command 输出路径不同；安装脚本若处理具体工具，必须参考 Supported Tools 表。原文：https://github.com/Fission-AI/OpenSpec/blob/main/docs/supported-tools.md#tool-directory-reference
- CI/CD 或脚本化初始化使用 `openspec init --tools ...`，并可配合 `--profile`。原文：https://github.com/Fission-AI/OpenSpec/blob/main/docs/supported-tools.md#non-interactive-setup
- `openspec completion` 支持 `bash`、`zsh`、`fish`、`powershell`，可生成、安装或卸载 shell completions。原文：https://github.com/Fission-AI/OpenSpec/blob/main/docs/cli.md#utility-commands
- 完整 CLI 命令、JSON 输出和 agent/script 适用命令请参考 CLI Reference。原文：https://github.com/Fission-AI/OpenSpec/blob/main/docs/cli.md
