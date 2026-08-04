# Cognee 安装 Skill — 使用说明

> **目录契约**：本地模式传 `TARGET_DIR`；脚本明确使用 `TARGET_DIR/.venv`，不依赖 CWD。`--global` 安装到用户 Python 环境，不传项目目录。

## 触发词

| 触发方式 | 示例 |
|----------|------|
| 自然语言描述 | "安装 Cognee" |
| 自然语言描述 | "Update Cognee in this project" |
| 带参数描述 | "安装 cognee[postgres,neo4j,aws] 到本地 .venv" |
| 验证描述 | "检查 cognee-cli 是否可用" |
| 明确指定 Skill | `/ost-topoteretes-cognee-install` |

## 适用客户端

| 客户端 | 支持状态 |
|--------|----------|
| Claude Code | 优先支持；可读取本地支持包并运行脚本 |
| Codex CLI | 优先支持；可读取本地支持包并运行脚本 |
| Copilot CLI | 可用；前提是当前环境能发现本地 Skill |

## 参数

| 参数 | 默认 | 说明 |
|------|------|------|
| `--location=local` | 是 | 在当前项目虚拟环境中安装或更新 Cognee |
| `--location=global` | 否 | 使用当前 Python 的 `pip --user` 安装或更新 |
| `--venv-dir=PATH` | `.venv` | 指定本地虚拟环境目录 |
| `--extras=LIST` | 空 | 安装 Cognee extras，逗号分隔，如 `ollama`、`postgres,neo4j,aws` |
| `--manager=auto` | 是 | 优先使用 `uv`，否则使用 `python -m pip` |
| `--manager=uv` | 否 | 要求使用 `uv` |
| `--manager=pip` | 否 | 强制使用 `python -m pip` |
| `--dry-run` | 否 | 只打印计划，不安装、不修改环境 |
| `--help` / `-h` | 否 | 显示脚本帮助 |

## 执行方式

主路径从支持包根目录运行：

```sh
sh scripts_for_install/install.sh [flags] [TARGET_DIR]
```

常用示例：

```sh
sh scripts_for_install/install.sh --dry-run /path/to/project
sh scripts_for_install/install.sh --extras=ollama /path/to/project
sh scripts_for_install/install.sh --extras=postgres,neo4j,aws /path/to/project
sh scripts_for_install/install.sh --location=global --manager=pip
```

脚本支持 macOS、Linux 和 WSL。Windows、Docker Compose、预构建 Docker 镜像、MCP server 源码运行、本地 UI 和 provider 详细配置，按 `repo_readme_summary.md` 第 2 部分走兜底路径。

## 验证方式

脚本会自动执行基础验证：

```sh
python -c 'import cognee; print("Cognee import OK:", cognee.__file__)'
```

可选端到端检查：

```sh
cognee-cli remember "Cognee turns documents into AI memory."
cognee-cli recall "What does Cognee do?"
```

## 范围说明

- 包含：Cognee Python 包安装 / 更新、extras 选择、本地虚拟环境或用户级安装、`import cognee` 与 `cognee-cli` 轻量验证、脚本失败时指向手动兜底路径。
- 不含：自动创建或修改用户真实 `.env`、Docker、Claude、Agent、MCP 或全局 shell 配置。
- 不含：详细使用教程、业务数据导入设计、生产部署规划、数据库迁移和卸载流程。
- 边界：需要写入真实配置时，应先展示建议内容并取得用户确认。
