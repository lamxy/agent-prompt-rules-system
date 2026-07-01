# OpenSpec — 使用示例

> 来源：官方 README / 文档；本文件只保留 open_supports 使用者最常见的入口。

## 快速开始

安装完成后，进入目标项目并初始化 OpenSpec，然后在 AI chat 中使用 `/opsx:*` 工作流。

### 初始化项目并创建第一个变更

适用场景：第一次在某个项目中使用 OpenSpec，并希望同时生成 Claude Code 与 Codex 的 Agent command files。

```sh
cd your-project
openspec init --tools claude,codex
```

```text
AI CHAT  /opsx:explore
AI CHAT  /opsx:propose add-dark-mode
AI CHAT  /opsx:apply
AI CHAT  /opsx:archive
```

预期结果：项目内生成 `openspec/specs/`、`openspec/changes/` 与所选 AI tool 的 command files；AI chat 能识别 `/opsx:*` 命令，并按 explore -> propose -> apply -> archive 推进变更。

注意事项：`openspec init` 会写入当前项目；`/opsx:apply` 会让 Agent 修改项目代码或文档，执行前建议确认 git 工作区状态。

来源：`repo_readme_summary.md` 第 1、2、3、4 部分；`skill_for_setup/ost_Fission-AI_OpenSpec_install/SKILL.md`

## 常见场景

### 非交互初始化 CI 或脚本项目

适用场景：不想进入交互式工具选择，希望脚本明确控制生成哪些 Agent 配置。

```sh
openspec init --tools claude,codex --profile core
```

预期结果：OpenSpec 使用 `core` profile 初始化当前项目，并为 `claude,codex` 生成对应 command files。

注意事项：该命令会写入当前项目。若不想生成任何 Agent tool 配置，使用 `openspec init --tools none`。

来源：`repo_readme_summary.md` 第 2、4 部分；`scripts_for_install/install.sh`

### 先澄清需求再生成 proposal

适用场景：需求还不完整，需要先让 AI 和你一起整理问题、边界和方案，再创建正式变更。

```text
AI CHAT  /opsx:explore
AI CHAT  /opsx:propose improve-onboarding-flow
```

预期结果：`/opsx:explore` 先帮助澄清想法；`/opsx:propose` 再为指定 change id 生成 proposal、delta specs、design 或 tasks 等变更工件。

注意事项：已有明确目标时，可以直接使用 `/opsx:propose <what-you-want-to-build>`。

来源：`repo_readme_summary.md` 第 1、3 部分

### 查看和验证当前变更

适用场景：已经有一个 active change，想在实现前检查内容或验证格式。

```sh
openspec list
openspec show add-dark-mode
openspec validate add-dark-mode
```

预期结果：终端列出 active changes、显示 `add-dark-mode` 的详情，并验证对应 spec / change 文件格式。

来源：`repo_readme_summary.md` 第 3、5 部分

### 打开交互式 dashboard

适用场景：想通过本地交互界面浏览 OpenSpec 项目状态，而不是只用命令行查看。

```sh
openspec view
```

预期结果：OpenSpec 启动 interactive dashboard，用于查看当前 specs 与 changes。

来源：`repo_readme_summary.md` 第 3、5 部分

### 更新已初始化项目的 Agent 配置

适用场景：全局 OpenSpec CLI 已升级，或调整了 profile / workflow selection / delivery mode 后，需要重新生成项目中的 AI tool configuration files。

```sh
openspec update
```

预期结果：OpenSpec 按当前 global profile、selected workflows 与 delivery mode 重新生成项目里的 AI tool configuration files。

注意事项：该命令会写入当前项目；官方建议在每个已初始化项目内分别运行。

来源：`repo_readme_summary.md` 第 2、4 部分；`scripts_for_install/install.sh`

## 与 Agent 客户端配合

### Claude Code 与 Codex

适用场景：目标项目希望同时支持 Claude Code 和 Codex 的 OpenSpec workflow。

```sh
openspec init --tools claude,codex
```

```text
AI CHAT  /opsx:propose add-user-settings
AI CHAT  /opsx:apply
```

预期结果：OpenSpec 为 Claude Code 与 Codex 生成对应 tool command files；初始化后，在 AI assistant chat 中使用 `/opsx:*` commands 推进规格驱动工作流。

注意事项：`openspec ...` 是终端命令；`/opsx:*` 是 AI chat 命令。Codex command files 位于 Codex home 的 prompts 目录，`$CODEX_HOME` 未设置时默认使用 `~/.codex/prompts/`。

来源：`repo_readme_summary.md` 第 2、3、4 部分；`skill_for_setup/README.md`

### 配置所有支持的 Agent tools

适用场景：项目团队使用多个 AI coding tools，希望一次生成所有官方支持 tool 的 OpenSpec 配置。

```sh
openspec init --tools all
```

预期结果：OpenSpec 按官方 supported tools 列表生成可用的 skills / commands。

注意事项：生成数量取决于 profile、workflow selection 与 delivery mode；不是固定数量。该命令会写入当前项目和对应 tool 配置位置。

来源：`repo_readme_summary.md` 第 1、2、4、5 部分

## 验证与排错

### 最小 CLI 验证

适用场景：确认 OpenSpec CLI 已经在当前 shell 可用。

```sh
openspec --version
```

预期结果：终端输出 OpenSpec 版本号。

注意事项：如果命令不存在，打开新终端或检查 npm / pnpm / yarn / bun 的 global bin 路径。

来源：`repo_readme_summary.md` 第 2、4 部分；`scripts_for_install/install.sh`

### Node.js 版本不满足要求

适用场景：安装脚本或官方 CLI 提示 Node.js 版本不符合要求。

```sh
node --version
```

预期结果：Node.js 版本为 `20.19.0` 或更高。

注意事项：Bun 可用于全局安装 OpenSpec，但 OpenSpec 当前仍运行在 Node.js 上，`PATH` 中仍需要 Node.js `20.19.0` 或更高。

来源：`repo_readme_summary.md` 第 2、4 部分；`scripts_for_install/install.sh`

### 初始化后命令或文件不符合预期

适用场景：初始化时选错 tools、profile，或升级后需要刷新项目配置。

```sh
openspec update
openspec list
```

预期结果：项目中的 OpenSpec / Agent 配置被刷新，`openspec list` 能列出当前 active changes。

注意事项：`openspec update` 会写入当前项目；若初始化时完全不需要 Agent command files，可重新使用 `openspec init --tools none` 的路径。

来源：`repo_readme_summary.md` 第 2、3、4 部分；`skill_for_setup/ost_Fission-AI_OpenSpec_install/SKILL.md`

## 延伸阅读

- 官方仓库：https://github.com/Fission-AI/OpenSpec
- Documentation Home：https://github.com/Fission-AI/OpenSpec/blob/main/docs/README.md
- Getting Started：https://github.com/Fission-AI/OpenSpec/blob/main/docs/getting-started.md
- Installation：https://github.com/Fission-AI/OpenSpec/blob/main/docs/installation.md
- CLI Reference：https://github.com/Fission-AI/OpenSpec/blob/main/docs/cli.md
- Supported Tools：https://github.com/Fission-AI/OpenSpec/blob/main/docs/supported-tools.md
