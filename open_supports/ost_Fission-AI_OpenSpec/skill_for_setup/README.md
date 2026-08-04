# OpenSpec 安装 Skill — 使用说明

> **目录契约**：CLI 安装是全局模式，不传项目目录。只有 `--init-project` / `--update-project` 需要 `TARGET_DIR`，脚本会在子 Shell 中切换目录。

## 触发词

| 触发方式 | 示例 |
|----------|------|
| 自然语言描述 | "帮我安装 OpenSpec"、"在这个项目初始化 OpenSpec"、"更新 OpenSpec 的项目配置" |
| 明确指定 Skill | `/ost-fission-ai-openspec-install` |

## 适用客户端

| 客户端 | 支持状态 |
|--------|----------|
| Claude Code | 支持 |
| Codex CLI | 支持 |

## 参数

| 参数 | 默认 | 说明 |
|------|------|------|
| `--package-manager=PM` | `npm` | 全局安装 OpenSpec CLI 的 package manager，可选 `npm`、`pnpm`、`yarn`、`bun` |
| `--project-dir=DIR` | `.` | `--init-project` 或 `--update-project` 的目标项目目录 |
| `--init-project` | 不启用 | 安装 CLI 后执行 `openspec init`，会写入目标项目 |
| `--tools=TOOLS` | `none` | 非交互初始化工具选择，例如 `claude,codex`、`all`、`none` |
| `--profile=PROFILE` | 官方默认 | 传给 `openspec init --profile` 的 profile |
| `--update-project` | 不启用 | 安装 CLI 后在目标项目执行 `openspec update` |

## 范围说明

- 包含：检查 Node.js 前置条件、安装或更新全局 OpenSpec CLI、验证 `openspec --version`、可选初始化或更新一个目标项目。
- 不含：卸载 OpenSpec、删除项目中的 `openspec/` 或 AI tool 文件、生成完整使用教程、代替用户执行 `/opsx:*` chat commands。
- 项目初始化和项目更新都会写入目标项目；执行前应先向用户确认目标目录和工具选择。
