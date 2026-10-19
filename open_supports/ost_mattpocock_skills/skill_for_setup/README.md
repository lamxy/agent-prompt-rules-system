# Skills For Real Engineers 安装 Skill — 使用说明

> **作用域契约（模式 D）**：插件（Claude Code / Codex / Copilot）与 Gemini CLI 默认用户级，不需要项目目录；`npx skills add` 默认项目级且 CWD 敏感，需传入已确认的项目目录，由脚本在子 Shell 中 `cd` 执行；`--global` 走 `-g`，不传目录。

## 触发词

| 触发方式 | 示例 |
|----------|------|
| 自然语言描述 | "帮我安装 mattpocock/skills" |
| 自然语言描述 | "用 npx 给 Cursor 装 Matt Pocock 的 skills 到 /work/app" |
| 自然语言描述 | "检查 mattpocock-skills 插件装好了没有" |
| 明确指定 Skill | `/ost-mattpocock-skills-install` |

## 适用客户端

| 客户端 | 支持状态 |
|--------|---------|
| Claude Code | ✅ 优先支持（插件，用户级默认，`--local` 项目级） |
| Codex CLI | ✅ 优先支持（插件，仅用户级） |
| GitHub Copilot CLI | ✅ 支持（插件，仅用户级）；VS Code 走兜底 GUI 步骤 |
| Gemini CLI | ✅ 支持（用户级默认，`--local` 为 workspace） |
| 其他 agent（Cursor、OpenCode、Windsurf、Amp 等） | ✅ 通过 `--client=npx`（项目级默认，`--global` 全局） |

## 参数

| 参数 | 默认 | 说明 |
|------|------|------|
| `--client=NAME` | `claude-code` | `claude-code`、`codex`、`copilot`、`gemini`、`npx` |
| `--agent=NAME` | 交互选择 | 仅 `npx`：目标 agent |
| `--global` | 插件 / Gemini 默认 | 显式用户级 / 全局；不得同时给项目目录 |
| `--local` | `npx` 默认 | 显式项目级，仅 `claude-code`、`gemini`、`npx` |
| `项目目录` | 无（本 Skill 总是显式传入） | 项目级目标目录，必须已存在 |
| `--verify-only` | 否 | 只验证不安装 |
| `--dry-run` | 否 | 只打印命令 |

## 范围说明

- ✅ 包含：选择客户端与作用域、确认后运行安装脚本或官方命令、更新入口、安装验证、提示在每个仓库运行 `/setup-matt-pocock-skills`。
- ❌ 不含：卸载（仅链接官方 `claude plugin uninstall` / `npx skills remove` 说明）、自动改写 `~/.copilot/settings.json`（需用户手动合并）、VS Code GUI 操作代执行、各 skill 的详细用法教程（见 `usage_examples.md`，如存在；可由 `ost-usage-examples` 生成）。
