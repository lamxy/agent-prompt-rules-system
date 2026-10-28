# 全局插件数量与上下文成本、工作流框架共存

日期：2026-10-28。状态：讨论结论，已实测（报告见 `docs/evaluation/2026-10-28-skill-overrides-experiment.md`），用户确认后才改配置。

> **实测后修正（2026-10-28）**：`skillOverrides` 对插件 skill 无效，因此下文 mattpocock-skills「按 skill 分 B/C 层」不成立，只能整包全局启用或改在场景 `enabledPlugins` 启用；gstack 的分层可行（逐键合并、用户层 → 项目层放宽已实测）。本机加上 gstack 后清单仍未超预算。修正后的建议见实测报告「建议」一节；下文保留为讨论原始记录。

## 问题

- 全局插件数量与上下文成本的平衡点在哪里
- superpowers、gstack、mattpocock-skills 三个工作流框架如何共存
- 在「1 个全局 + 4 个场景」结构下，框架该多场景生效还是严格按场景划分

用户倾向：superpowers 保持全局（任意目录都可能用到）；gstack、mattpocock-skills 未定。

## 已验证事实

来源：Claude Code 官方 skills 文档（`https://code.claude.com/docs/en/skills.md`，2026-10-28 读取）、本机插件缓存、上游仓库原文。

- 每回合常驻的是 skill 清单（名称 + 描述）；全文只在调用时加载。
- 清单预算为 context window 的 1%（`skillListingBudgetFraction` 可调），超出时从最少使用的 skill 开始丢描述、只留名称；单条描述上限 1,536 字符。因此 skill 多的代价是**描述被丢、触发变差**，不是 token 无上限增长。
- `skillOverrides` 四态：`on`（名称 + 描述）、`name-only`、`user-invocable-only`（模型看不到，`/` 菜单保留）、`off`（都隐藏）。用户、项目、本地设置中按 skill 名称匹配。
- `/doctor` 估算清单成本；`/skill-doctor` 报告各 skill 的成本与使用次数。
- superpowers 7.0.0：15 个 skill，描述合计约 2.3K 字符；SessionStart hook 每次会话注入 `using-superpowers` 全文（约 3.2KB），要求「有 1% 可能就调用 skill」。
- mattpocock-skills 1.3.1（`.claude-plugin/plugin.json`）：27 个 skill。
- gstack：仓库根目录五十多个目录（未逐一核对哪些是 skill）；描述很短（`review`：`Pre-landing PR review. (gstack)`），但全文大（`review/SKILL.md` 约 58KB），调用时先跑 bash preamble（更新检查、遥测询问）。上游只支持用户级安装（team 模式不 vendor 进项目）。
- 本机 `~/.claude/settings.json` 当前未启用 mattpocock-skills，也未安装 gstack；二者只登记在本仓库 `settings/settings.user.json` 与 `dot_claude_projects/.claude/open_supports_name_list.txt`。

## 主要成本：意图重叠

| 意图 | 竞争的 skill |
|---|---|
| TDD | superpowers `test-driven-development`、mattpocock `tdd` |
| 调试 | superpowers `systematic-debugging`、mattpocock `diagnosing-bugs`、gstack `investigate` |
| 代码审查 | superpowers `requesting-code-review`、mattpocock `code-review`、gstack `review`、内置 `/code-review`、`pr-review-toolkit`、`open-code-review` |
| 交接 | mattpocock `handoff`、`myhandoff`、gstack `context-save`／`context-restore` |
| 复盘 | mattpocock `retro`、gstack `retro` |

superpowers 的「1% 就调用」规则会放大同类 skill 的误触发。

## 结论：按 skill 分三层，而不是按插件数

平衡点不以插件数量衡量，看两个指标：可自动触发的 skill 是否在清单预算内（不丢描述）；同一意图可自动触发的 skill 是否不超过 1 个。

| 层 | 含义 | 成本 |
|---|---|---|
| A 全局自动 | 全局安装，`on` | 每回合占清单预算 |
| B 全局手动 | 全局安装，`user-invocable-only` | 清单成本为 0，任意目录可 `/` 调用 |
| C 场景自动 | 场景项目 settings 改为 `on` | 只在该场景占预算 |

进入 A 层的标准：跨场景常用，且与其他 A 层 skill 不重叠。

### 三个框架的建议

- **superpowers**：A 层。
- **mattpocock-skills**：全局安装，默认 B 层。与 superpowers、myhandoff 重叠的（`tdd`、`diagnosing-bugs`、`code-review`、`handoff`、`implement`、`retro`、`pr`）始终 B 层。C 层候选：`prd-design` 开 `grill-me`、`grill-with-docs`、`to-spec`、`to-tickets`、`to-questionnaire`、`domain-modeling`；`backend-dev` 开 `domain-modeling`、`codebase-design`、`improve-codebase-architecture`。
- **gstack**：全局安装，默认 B 层；iOS 系列、gbrain、openclaw、ubicloud 等设为 `off`。C 层候选：`prd-design` 开 `office-hours`、`plan-ceo-review`；`dev-ops` 开 `ship`、`land-and-deploy`、`canary`、`cso`。frontend 的 `qa`、`browse` 与 playwright、chrome-devtools 重叠，先留 B 层。

不按场景安装框架的理由：gstack 上游只支持用户级安装；B 层保留「任意目录都可能用到」。

## 与既有决定的关系

交接文件「其他已知问题」记录：全局工具重叠「不用 `skillOverrides` 关闭，由用户按需手动调用」。本方案改用 `user-invocable-only` 实现「只手动调用」，属于修改该决定，需用户确认。

## 待实测（写入配置前必须通过）

1. 项目级 `skillOverrides` 能否把用户级设为 `user-invocable-only` 的 skill 改回 `on`（决定 C 层是否成立）。
2. 插件 skill 在 `skillOverrides` 中的键是 `tdd` 还是 `mattpocock-skills:tdd`。
3. gstack 安装后的实际 skill 名称、是否有前缀、数量。
4. 本机当前清单是否已超预算：由用户在交互会话执行 `/doctor`、`/skill-doctor`（并入阶段 1「记录常驻上下文占用」）。
