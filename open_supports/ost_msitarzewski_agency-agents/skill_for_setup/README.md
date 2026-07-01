# Agency Agents 安装 Skill — 使用说明

## 触发词

| 触发方式 | 示例 |
|----------|------|
| 自然语言描述 | "帮我给这个项目安装 Agency Agents 的 Codex agents" |
| 自然语言描述 | "更新 Claude Code 里的 Agency Agents，并先 dry-run" |
| 明确指定 Skill | `/ost-msitarzewski-agency-agents-install` |

## 适用客户端

| 客户端 | 支持状态 |
|--------|----------|
| Claude Code | 优先支持；使用 `--tool=claude-code` 或脚本默认检测 |
| Codex CLI | 优先支持；使用 `--tool=codex` |
| 其他脚本支持工具 | 支持 `copilot`、`antigravity`、`gemini-cli`、`opencode`、`openclaw`、`cursor`、`aider`、`windsurf`、`qwen`、`kimi`、`osaurus`、`hermes`、`all` |

## 参数

| 参数 | 默认 | 说明 |
|------|------|------|
| `--tool=NAME` | all detected | 目标工具：`claude-code`、`codex`、`opencode` 等，或 `all` |
| `--division=LIST` | upstream default | 逗号分隔的 division/team 列表，可重复传入并合并 |
| `--agent=LIST` | upstream default | 逗号分隔的 agent slug/name 列表，可重复传入并合并 |
| `--agents-file=PATH` | unset | 每行一个 agent slug/name 的文件 |
| `--project-dir=PATH` | `.` | 项目级工具的目标项目目录；脚本会转为绝对路径 |
| `--repo-dir=PATH` | `~/.cache/agency-agents/agency-agents` | 官方仓库 checkout 缓存；已有 checkout 会 `git pull --ff-only` |
| `--path=PATH` | unset | 覆盖单个工具的上游安装目录 |
| `--link` | off | 请求上游用 symlink 而不是 copy |
| `--no-convert` | off | 不让上游自动运行 conversion |
| `--parallel` | off | 请求上游并行安装所选工具 |
| `--jobs=N` | unset | 上游并行任务数，必须为正整数 |
| `--dry-run` | off | 打印上游安装计划，不写入 |
| `--verify-only` | off | 只验证 checkout 和上游 installer 可用性 |
| `--list=WHAT` | unset | 列出上游 `tools`、`teams/divisions`、`agents` 或 `all` |

## 范围说明

- 包含：克隆或快进官方 `msitarzewski/agency-agents` checkout、调用官方 Bash installer、选择工具/division/agent、dry-run、list、verify-only、更新既有安装。
- 包含：根据平台和脚本结果决定是否改走 `repo_readme_summary.md` 第 2 部分的手动安装/更新路径。
- 不含：卸载 agents、删除用户配置、安装 Agency Agents 桌面应用、保证不同 AI 工具的 agent 功能完全等价。
- 不含：生成详细使用教程；安装后只提示用户重启目标 AI 工具并按工具验证。
