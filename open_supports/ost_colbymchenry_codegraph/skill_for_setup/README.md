# CodeGraph 安装 Skill — 使用说明

> **目录契约**：`--location=local` 依赖 CWD。调用脚本时传 `TARGET_DIR`，脚本在子 Shell 中切换目录；`--global` 不传项目目录。

## 触发词

| 触发方式 | 示例 |
|----------|------|
| 自然语言描述 | "帮我安装 CodeGraph"、"把 CodeGraph 接入我的 Claude Code" |
| 明确指定 Skill | `/ost-colbymchenry-codegraph-install` |

## 适用客户端

| 客户端 | 支持状态 |
|--------|----------|
| Claude Code | ✅ 优先支持 |
| Codex CLI | ✅ 优先支持 |
| Cursor | 待评估 |

## 参数

| 参数 | 默认 | 说明 |
|------|------|------|
| `--target=` | `auto` | 目标 Agent：`auto`、`claude`、`codex`、`cursor` 等，逗号分隔多个 |
| `--location=` | `local` | 配置范围：`local`（当前项目）或 `global`（所有项目） |

## 范围说明

- ✅ 包含：CLI 安装、Agent 接入配置
- ❌ 不含：`codegraph init`（项目索引初始化，请在各项目目录手动执行）
