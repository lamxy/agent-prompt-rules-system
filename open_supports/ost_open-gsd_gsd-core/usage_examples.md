# GSD Core — 使用示例

## 安装作用域示例

```sh
# 项目级：脚本在 /path/to/project 内运行 CWD-sensitive 官方 --local 命令
sh scripts_for_install/install.sh --claude --local /path/to/project

# 全局：不传项目目录
sh scripts_for_install/install.sh --claude --global
```

> 来源：官方 README / 文档；本文件只保留 open_supports 使用者最常见的入口。

## 快速开始

安装完成并重启目标 Agent runtime 后，在要管理的项目仓库中运行初始化命令。

### 初始化当前项目的 GSD 工作区

适用场景：第一次在某个项目中使用 GSD Core，需要创建 `.planning/` 项目状态并让 Agent 了解项目目标。

```sh
/gsd-new-project
```

预期结果：命令被目标 runtime 识别，并开始询问项目问题；完成后会在项目内建立 GSD 使用的 `.planning/` 状态文件。

注意事项：该命令会修改当前项目目录，初始化或更新 `.planning/` 下的项目规划状态。Gemini CLI 与 Codex 的命令写法见下文「与 Agent 客户端配合」。

来源：`repo_readme_summary.md` 第 2、3 部分；官方快速开始：https://docs.opengsd.net/core/quickstart

## 常见场景

### 从第一个 phase 开始推进工作

适用场景：项目已经完成 `/gsd-new-project` 初始化，现在要把第 1 个 phase 从讨论推进到交付。

```sh
/gsd-discuss-phase 1
/gsd-plan-phase 1
/gsd-execute-phase 1
/gsd-verify-work 1
/gsd-ship 1
```

预期结果：GSD 会按 discuss -> plan -> execute -> verify -> ship 的顺序推动第 1 个 phase，并在 `.planning/` 中保留对应 artifacts 与状态。

注意事项：这些命令会让 Agent 读取并更新项目规划文件，也可能按 phase 内容修改源码或文档。执行前建议确认当前 git 工作区状态。

来源：`repo_readme_summary.md` 第 1、3 部分；工作流命令参考：https://docs.opengsd.net/core/commands/workflow-commands

### 清空上下文后继续 phase 工作

适用场景：长对话后上下文变重，需要清空聊天上下文，再让 GSD 通过 `.planning/` 继续工作。

```sh
/clear
/gsd-discuss-phase 1
```

预期结果：runtime 清空当前对话上下文后，GSD 命令会从项目中的 `.planning/` 状态恢复所需背景，并继续对应 phase 的讨论。

注意事项：`/clear` 是 runtime 命令，是否可用取决于当前 Agent 客户端；GSD 的持久化状态来自 `.planning/` 文件。

来源：`repo_readme_summary.md` 第 1、3 部分；官方快速开始：https://docs.opengsd.net/core/quickstart

### 在已安装 runtime 内更新 GSD Core

适用场景：已经安装 GSD Core，想在 Agent runtime 内检查并应用更新。

```sh
/gsd-update
/gsd-update --sync
/gsd-update --reapply
```

预期结果：GSD 更新流程启动；稳定更新会按官方逻辑处理已有文件，本地修改文件会被安装器备份。

注意事项：`--sync`、`--reapply` 的具体效果以官方更新页为准；需要 RC / prerelease 通道时使用 `/gsd-update --next` 或 `/gsd-update --rc`。

来源：`repo_readme_summary.md` 第 2 部分；官方更新页：https://github.com/open-gsd/gsd-core/blob/next/docs/how-to/update-gsd.md

### 使用安装脚本验证本地 runtime 配置

适用场景：安装已完成，但想用支持包脚本重新执行同一 runtime 的安装 / 更新路径，并查看脚本给出的验证提示。

```sh
sh scripts_for_install/install.sh --claude --local /path/to/project
```

预期结果：脚本完成平台、Node.js、npm、npx 检查，调用官方 `@opengsd/gsd-core` 安装器，然后输出对应 runtime 的验证命令。

注意事项：该脚本会调用官方安装器并写入目标 runtime 配置；`--codex` 会额外检查 Codex CLI >= 0.130.0。不要在未确认 runtime 与 scope 时执行。

来源：`skill_for_setup/README.md`；`skill_for_setup/ost_open-gsd_gsd-core_install/SKILL.md`；`scripts_for_install/install.sh`

## 与 Agent 客户端配合

### Claude Code / Copilot / OpenCode / Kilo / Cline 等 slash command runtime

适用场景：目标 runtime 使用 GSD 的 hyphen slash command 形式。

```sh
/gsd-new-project
/gsd-plan-phase 1
```

预期结果：runtime 识别 `/gsd-*` 命令，并进入对应 GSD workflow。

来源：`repo_readme_summary.md` 第 2、3 部分；`scripts_for_install/install.sh`

### Gemini CLI

适用场景：目标 runtime 是 Gemini CLI，需要使用 colon 命令命名。

```sh
/gsd:new-project
/gsd:plan-phase 1
```

预期结果：Gemini CLI 识别 `/gsd:*` 命令，并进入对应 GSD workflow。

注意事项：如果 Gemini `settings.json` 中存在 `hooksConfig.enabled: false`，GSD hooks 会被 Gemini CLI 静默禁用。

来源：`repo_readme_summary.md` 第 2、3、4 部分

### Codex CLI

适用场景：目标 runtime 是 Codex CLI，需要使用 dollar-prefix skill form。

```sh
$gsd-new-project
$gsd-plan-phase 1
```

预期结果：Codex 识别 `$gsd-*` skill，并进入对应 GSD workflow。

注意事项：安装后如命令不识别，可重启 Codex，或按支持包说明运行 `codex --reload` 重新加载配置。

来源：`repo_readme_summary.md` 第 2、3、4 部分；`skill_for_setup/ost_open-gsd_gsd-core_install/SKILL.md`

## 验证与排错

### 最小安装验证

适用场景：确认安装后的 runtime 是否已经加载 GSD Core。

```sh
/gsd-new-project
```

预期结果：命令被识别并开始询问项目问题，即代表安装成功。

注意事项：Gemini CLI 使用 `/gsd:new-project`；Codex 使用 `$gsd-new-project`。验证前通常需要重启目标 runtime。

来源：`repo_readme_summary.md` 第 2 部分；`skill_for_setup/ost_open-gsd_gsd-core_install/SKILL.md`

### 命令不识别

适用场景：安装器执行成功，但 Agent runtime 中输入 GSD 命令没有反应或报未知命令。

```sh
codex --reload
```

预期结果：Codex 重新加载配置后，可以识别 `$gsd-new-project` 等命令。

注意事项：非 Codex runtime 通常重启目标客户端。若仍失败，重新运行安装脚本或官方 npx 安装命令，并确认安装目标 runtime 与 scope 正确。

来源：`repo_readme_summary.md` 第 4 部分；`skill_for_setup/ost_open-gsd_gsd-core_install/SKILL.md`

### 安装脚本缺少 runtime flag

适用场景：运行支持包脚本时看到「请至少指定一个 runtime flag」。

```sh
sh scripts_for_install/install.sh --codex --local /path/to/project
```

预期结果：脚本使用明确 runtime 与 scope 执行安装 / 更新路径。

注意事项：`--all` 不能与其他 runtime flag 混用，并且官方摘要只给出 `--all --global` 路径。

来源：`scripts_for_install/install.sh`；`skill_for_setup/ost_open-gsd_gsd-core_install/SKILL.md`

### Node.js / npm / Codex 版本不满足要求

适用场景：安装脚本或官方安装器提示版本不满足要求。

```sh
node --version
npm --version
codex --version
```

预期结果：Node.js >= 22.0.0，npm >= 10.0.0；选择 Codex runtime 时，Codex CLI >= 0.130.0。

注意事项：支持包不负责安装 Node.js、npm、npx、Codex CLI 或目标 Agent runtime；版本不满足时先升级对应工具，再重新运行安装 / 更新。

来源：`repo_readme_summary.md` 第 2、4 部分；`scripts_for_install/install.sh`

## 延伸阅读

- 官方 README：https://github.com/open-gsd/gsd-core
- 官方文档：https://docs.opengsd.net/
- 官方安装页：https://docs.opengsd.net/core/installation
- 首个项目教程：https://docs.opengsd.net/core/quickstart
- 工作流命令参考：https://docs.opengsd.net/core/commands/workflow-commands
- 仓库安装深度页：https://github.com/open-gsd/gsd-core/blob/main/docs/how-to/install-on-your-runtime.md
- 官方更新页：https://github.com/open-gsd/gsd-core/blob/next/docs/how-to/update-gsd.md
- 配置参考：https://github.com/open-gsd/gsd-core/blob/next/docs/CONFIGURATION.md
- CLI tools 参考：https://github.com/open-gsd/gsd-core/blob/next/docs/CLI-TOOLS.md
- 无 Node.js / 手动转换路径入口：https://github.com/open-gsd/gsd-core/blob/main/docs/USER-GUIDE.md
