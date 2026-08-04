# Taskmaster 安装 Skill — 使用说明

> **目录契约**：本地 npm 安装依赖 CWD。调用脚本时传 `TARGET_DIR`（位置参数或 `--project-dir`）；脚本在子 Shell 中切换目录。`--global` 不传项目目录。

## 触发词

| 触发方式 | 示例 |
|----------|------|
| 自然语言描述 | "帮我安装 Taskmaster" |
| 自然语言描述 | "给 Claude Code 配置 task-master-ai MCP" |
| 自然语言描述 | "在这个项目里安装 claude-task-master" |
| 自然语言描述 | "更新 task-master-ai CLI" |
| 明确指定 Skill | `/ost-eyaltoledano-claude-task-master-install` |

## 适用客户端

| 客户端 | 支持状态 |
|--------|---------|
| Claude Code | 优先支持 |
| Codex CLI | 优先支持 |

## 参数

| 参数 | 默认 | 说明 |
|------|------|------|
| `--location=local` / `--local` | 默认 | 在目标项目内执行 `npm install task-master-ai@latest` |
| `--location=global` / `--global` | 无 | 执行 `npm install -g task-master-ai@latest` |
| `--project-dir=DIR` | 当前目录 | 项目目录；本地安装和 `--init-project` 会在此目录执行 |
| `--claude-mcp` | 无 | 同时运行 `claude mcp add ...` 注册 Taskmaster MCP server |
| `--mcp-scope=SCOPE` | `user` | Claude MCP scope，支持 `user`、`project`、`local` |
| `--tools=MODE` | 未设置 | MCP 工具加载模式，如 `core`、`standard`、`all`、`lean` 或逗号列表 |
| `--init-project` | 无 | 安装后运行 `task-master init`；会修改目标项目 |
| `--help` / `-h` | 无 | 显示脚本帮助 |

## 范围说明

- 包含：检查 macOS / Linux / WSL 平台，检查 Node.js >= 20.0.0、npm、npx，按参数执行官方 npm 安装 / 更新命令。
- 包含：显式传 `--claude-mcp` 时，使用官方 `claude mcp add ... npx -y task-master-ai` 路径配置 Claude Code MCP。
- 包含：显式传 `--init-project` 时，在目标项目运行 `task-master init` 或 `npx task-master init`。
- 不含：安装 Node.js、npm、npx、Claude Code CLI、Codex CLI 或编辑器本身。
- 不含：写入 API keys、创建 `.env`、修改非 Claude Code 的 MCP JSON；这些按 `repo_readme_summary.md` 第 2 部分手动处理。
- 不含：卸载、删除 `.taskmaster/`、删除 MCP 配置或清理 API keys。
