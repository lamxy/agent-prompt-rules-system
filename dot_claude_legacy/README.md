# dot_claude_legacy

2026-10-19 之前的 `dot_claude/` 分层规约系统备份（`CLAUDE.md` + `rules/` + `expandable/` + `hooks/` + 审计命令）。

已不再由任何安装脚本使用，仅供查阅、回溯，或手动复制给仍想使用旧版的人。被替换的原因、逐项迁移对照与提炼的经验，见 `dot_claude/README.md`。

`audit-reports/` 中的 hook 事故记录（尤其 `2026-04-28-posttooluse-hook-pitfall.md`）仍有参考价值。

## 2026-10-19 归档时的修正

归档前已对照 Claude Code 官方文档修正以下错误，使旧版单独使用时不会出问题；分层设计本身未改动。

| 文件 | 问题 | 修正 |
|---|---|---|
| `hooks/subagent_stop_gate.py` | 放行时返回不合法的 `"decision": "approve"`；误以为 block 后子代理已无法写文件，提示「不要写文件」 | 放行时不输出；block 时指示子代理把完整内容写入 `.claude/artifacts/` 并只回传摘要与路径；`stop_hook_active` 为 true 时不再 block，防止循环 |
| `hooks/artifact_read_gate.py` | 未注册；拦截 `/tmp/` 而非规约要求的 `.claude/artifacts/`；对所有非 artifact 的 Read 返回 `allow`（会跳过权限确认）；对 artifact 每次都拒绝，声明「加工」后也无法读取 | 拦截项目与用户级 `.claude/artifacts/`；非 artifact 不输出；同一会话同一文件只拦截一次；已在 `settings.json` 注册为 `PreToolUse` `Read` hook |
| `settings.json` | `deny` 中 `Bash(*\|*sh*)` 等子字符串规则会误伤（实测 `echo push \| grep push` 被拒）；`ask` 中 `*\|*node*` 等同理 | 改为匹配管道后的命令名，如 `Bash(*\| sh)`、`Bash(*\| sh *)`（实测 `\| grep push` 放行、`\| sh` 被拒） |
| `settings.json` | `PreCompact` prompt hook 的 `systemMessage` 会被官方丢弃，没有作用 | 删除 |
| `settings.json` | SubagentStop hook 的兜底命令输出不合法的 `approve` | 改为 `\|\| true`（失败时不输出，正常放行） |
| `settings.json` | 写死 `model: claude-sonnet-4-6`；`DISABLE_AUTOUPDATER: "0"` 等于未设置 | 删除两者 |
| `RTK.md` | rtk 1.0 起 `rtk proxy` 已改名为 `rtk bypass` | 更新 |
| `rules/task/tool-call-rule-min.md` | 「同一工具最多重试 1 次」与全局 curl TLS EOF 重试规则（最多 3 次）、`env-tools-min.md`（首选工具最多重试 2 次）冲突 | 注明有专门约定时以该约定为准 |
| `rules/preferences/skill-trigger-constraint-min.md` | 「消息中出现触发词」即可加载，引用或讨论该名称也会误触发 | 改为「明确要求执行」；注明可用 `skillOverrides` 强制 |
| `audi_reports/` | 目录名拼写错误，且与 `/auditrules` 的输出路径 `.claude/audit-reports/` 不一致 | 更名为 `audit-reports/` |

未修改：`ask` 中的 `Bash(*>*)` 也会匹配 `2>&1`，但「任何重定向都需确认」可能是有意设计，保留原状。
