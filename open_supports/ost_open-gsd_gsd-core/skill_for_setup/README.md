# GSD Core 安装 Skill — 使用说明

> **目录契约**：`--local` 是 CWD-sensitive。调用脚本时始终传 `TARGET_DIR`（位置参数）；脚本在子 Shell 中切换目录。`--global` 不传项目目录。

## 触发词

| 触发方式 | 示例 |
|----------|------|
| 自然语言描述 | "帮我安装 GSD Core 到 Claude Code" |
| 自然语言描述 | "给 Codex CLI 配置 open-gsd/gsd-core" |
| 自然语言描述 | "更新本机的 GSD Core 配置" |
| 明确指定 Skill | `/ost-open-gsd-gsd-core-install` |

## 适用客户端

| 客户端 | 支持状态 |
|--------|---------|
| Claude Code | 优先支持 |
| Codex CLI | 优先支持 |

## 参数

| 参数 | 默认 | 说明 |
|------|------|------|
| `--claude` | 无 | 安装 / 更新 Claude Code runtime 配置 |
| `--codex` | 无 | 安装 / 更新 Codex runtime 配置；需 Codex CLI >= 0.130.0 |
| `--gemini` | 无 | 安装 / 更新 Gemini CLI runtime 配置 |
| `--opencode` | 无 | 安装 / 更新 OpenCode runtime 配置 |
| `--kilo` | 无 | 安装 / 更新 Kilo runtime 配置 |
| `--kimi` | 无 | 安装 / 更新 Kimi CLI / Kimi Code runtime 配置 |
| `--copilot` | 无 | 安装 / 更新 GitHub Copilot runtime 配置 |
| `--cursor` | 无 | 安装 / 更新 Cursor runtime 配置 |
| `--windsurf` | 无 | 安装 / 更新 Windsurf / Devin Desktop runtime 配置 |
| `--devin-desktop` | 无 | `--windsurf` 的等价 runtime flag |
| `--cline` | 无 | 安装 / 更新 Cline runtime 配置 |
| `--codebuddy` | 无 | 安装 / 更新 CodeBuddy runtime 配置 |
| `--qwen` | 无 | 安装 / 更新 Qwen Code runtime 配置 |
| `--augment` | 无 | 安装 / 更新 Augment Code runtime 配置 |
| `--antigravity` | 无 | 安装 / 更新 Antigravity runtime 配置 |
| `--trae` | 无 | 安装 / 更新 Trae runtime 配置 |
| `--all` | 无 | 安装全部官方支持 runtime；只能配合 `--global` |
| `--local` / `--location=local` | 默认 | 项目级安装 |
| `--global` / `--location=global` | 无 | 全局安装 |
| `--help` / `-h` | 无 | 显示脚本帮助 |

至少需要指定一个 runtime flag，例如 `--claude` 或 `--codex`。未指定 scope 时脚本默认使用 `--local`。

## 范围说明

- 包含：检查 macOS / Linux / WSL 平台，检查 Node.js >= 22.0.0、npm >= 10.0.0、npx，可按脚本参数运行官方 `@opengsd/gsd-core` 安装器完成首次安装或更新。
- 包含：Codex runtime 安装前检查 Codex CLI >= 0.130.0，并在安装后提示目标 runtime 的验证命令。
- 不含：安装 Node.js、npm、npx、Codex CLI 或目标 AI runtime。
- 不含：运行 `/gsd-new-project`、`$gsd-new-project` 等 GSD 项目工作流命令。
- 不含：Claude native plugin、Gemini native extension、Windows native shell、无 Node.js 机器复制输出目录、手动转换源文件等路径；这些场景按 `repo_readme_summary.md` 第 2 部分处理。
