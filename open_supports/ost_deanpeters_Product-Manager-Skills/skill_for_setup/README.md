# Product Manager Skills 安装 Skill - 使用说明

## 触发词

| 触发方式 | 示例 |
|----------|------|
| 自然语言描述 | "帮我把 Product Manager Skills 安装到 Codex 项目里" |
| 明确指定 Skill | `/ost-deanpeters-product-manager-skills-install` |

## 适用客户端

| 客户端 | 支持状态 |
|--------|----------|
| Codex CLI / Codex repo | 支持：优先使用 `codex-zip` 或 `codex-cli` |
| Claude Code | 支持：输出官方 plugin marketplace 命令 |
| Claude Desktop / Claude Web | 支持：输出官方 ZIP 上传步骤 |
| Windows shell | 需走兜底路径：脚本只支持 macOS、Linux、WSL |

## 参数

| 参数 | 默认 | 说明 |
|------|------|------|
| `--client=codex-zip` | `codex-zip` | 下载 latest `pm-skills-codex.zip` 并安装到目标 repo |
| `--client=codex-cli` | - | 通过 `npx skills` 全局安装指定 skill |
| `--client=claude-code` | - | 打印 Claude Code plugin marketplace 安装命令 |
| `--client=claude-desktop` | - | 打印 Claude Desktop / Web ZIP 上传步骤 |
| `--project-dir=PATH` | `.` | `codex-zip` 的目标项目根目录 |
| `--skill=NAME` | - | `codex-cli` 必填的 skill 名称 |
| `--location=local` | `local` | `codex-zip` 仅支持 local |
| `--location=global` | - | `codex-cli` 按官方命令需要 global |
| `--verify-only` | 关闭 | 只执行脚本内可行的验证，不安装 |
| `--help` | - | 显示脚本帮助 |

## 范围说明

- 包含：安装路径选择、运行支持包安装脚本、脚本失败或平台不支持时回退到官方摘要、安装后验证和下一步提示。
- 不含：详细 PM skill 使用教程、卸载、修改上游 skill 内容、管理 Claude / Codex 账号权限或 API key。
- setup Skill 只负责安装、配置、验证和升级入口；具体使用示例应参考官方文档或后续 usage examples 支持包。
