# 实测报告：skill 清单成本、skillOverrides 与工作流框架分层

日期：2026-10-28。环境：Claude Code 2.1.312，macOS。讨论背景与原始结论见 `docs/plans/2026-10-28-workflow-frameworks-tiering.md`。

## 结论摘要

1. **`skillOverrides` 对插件 skill 无效**（官方文档原文 + 实测）。superpowers、mattpocock-skills 是插件，只能整包启用或停用；原结论中「mattpocock 按 skill 分 B/C 层」不成立。
2. **`skillOverrides` 跨层逐键合并，高层可放宽也可收紧**，用户层 → 项目层已直接实测。gstack 属于个人 skill，可以按「全局手动 + 场景打开」分层。
3. **插件可按场景开关**：项目层 `enabledPlugins: false` 能关掉用户层已启用的插件，`true` 能启用用户层未启用的插件。
4. **在本机环境中，清单预算还不是瓶颈**：本机全局 + mattpocock + 3 个测试 skill 共 73 项、16,955 字符；再加 gstack 62 项后共 131 项、22,718 字符。haiku、opus 下都没有丢描述。真正的成本是同类意图重叠和误触发，不是 token。
5. **mattpocock-skills 上游已自行收敛**：27 个 skill 中 16 个带 `disable-model-invocation: true`，模型可自动触发的只有 11 个。其中 `tdd`、`diagnosing-bugs`、`code-review` 与 superpowers 重叠。
6. **gstack 安装有副作用**：默认短名称（非交互时也是），会新增 `/review`、`/retro`、`/learn` 等 9 个通用名称的 `/` 命令；setup 默认在 `~/.claude/settings.json` 注册 timeline Stop hook。

## 方法

- 测试项目：scratchpad 下的 `sk/proj`（3 个标记 skill：`alpha`、`beta`、`gamma`）与 `sk/proj2`（gstack 62 个 skill 的 frontmatter 存根，只含 `name`、`description`，不执行上游代码）。
- 插件：`--plugin-dir` 加载 mattpocock/skills 的克隆（`59db609`，plugin 1.3.1）。gstack 克隆为 `cd4fc4b`（VERSION 1.91.288.0）。
- 每个案例跑一次 `claude -p "Reply with just: done"`，默认 `--model haiku`。观察两处：
  - 会话记录 `~/.claude/projects/<项目>/<session>.jsonl` 中 `attachment.type == "skill_listing"` 的内容，即模型实际收到的清单。
  - `--output-format stream-json` 的 init 事件 `slash_commands`，即 `/` 菜单。
- 设置来源用 `--setting-sources` 控制：
  - 默认 `project,local`，排除本机用户设置。
  - 需要用户层时用 `user,project,local`，只读加载本机 `~/.claude/settings.json`，未修改它。
- 隔离的 `CLAUDE_CONFIG_DIR` 无法登录（`Not logged in`）。为不复制凭据，没有采用这个方式。

## 结果

| 案例 | 设置 | 结果 |
|---|---|---|
| T0 基线 | 无 overrides | 3 个测试 skill 都有描述，都在 `/` 菜单 |
| T1 四态 | 项目层 `alpha: user-invocable-only`、`beta: name-only`、`gamma: off` | alpha：清单无、菜单有；beta：清单只有名称、菜单有；gamma：清单与菜单都没有。与文档一致 |
| T2 插件键（短名） | `tdd: user-invocable-only` | `mattpocock-skills:tdd` 不受影响 |
| T2b 插件键（命名空间） | `mattpocock-skills:tdd: user-invocable-only`、`mattpocock-skills:research: off`、`grilling: name-only` | 三者都不受影响。官方文档：「Plugin skills are not affected by `skillOverrides`. Manage those through `/plugin` instead.」 |
| T3 项目 → 本地 | 项目层 `alpha`、`beta` 为 `user-invocable-only`；本地层 `alpha: on`、`gamma: off` | alpha 恢复，beta 维持隐藏，gamma 关闭，即逐键合并 |
| T4 项目 → `--settings` | 项目层 `alpha`、`beta` 隐藏；flag 层 `alpha: on` | alpha 恢复，beta 维持隐藏 |
| T5 高层收紧 | 项目层 `alpha: on`；本地层 `alpha: user-invocable-only` | alpha 隐藏 |
| T6a 用户层基线 | 本机用户层 `claude-api: user-invocable-only` | `claude-api` 不在清单，菜单有 |
| T6b 用户层 → 项目层 | 项目层 `claude-api: on` | `claude-api` 回到清单（有描述） |
| T7a/T7b 加入 gstack | 本机用户设置 + 62 个 gstack 存根；haiku 与 opus 各一次 | 131 项、22,718 字符，name-only 0 项；`/` 菜单从 126 增至 184 项 |
| T8 预算压缩 | `skillListingBudgetFraction: 0.001` | 7,697 字符，121 项只剩名称，确认超预算时丢描述 |
| T9 场景关插件 | 用户层启用 `playground`；项目层 `enabledPlugins` 设为 `false` | `playground:playground` 不在清单，也不在菜单 |

### 清单构成（T6a，本机用户设置）

可自动触发项最多的来源：superpowers 15、mattpocock-skills 11（`--plugin-dir` 加入；本机实际未启用）、chrome-devtools-mcp 7、hookify 5，其余插件 1～3 项，另有内置 skill 约 12 项。

### gstack 源码核对（未运行 setup）

- 62 个 skill；`setup` 的 `--prefix` / `--no-prefix` 控制是否加 `gstack-` 前缀。未传参时先读已保存的配置，再交互询问；非交互时用短名称。本仓库 `open_supports/ost_garrytan_gstack/scripts_for_install/install.sh` 调用 `./setup` 时不传前缀参数。
- `gstack-config set disabled_skills a,b`：setup 不为这些 skill 建链接，相当于安装层面的 `off`。
- timeline Stop hook：未设置时默认 `yes`，写入 `~/.claude/settings.json`（会先备份为 `.bak.<ts>`）。可用 `--no-timeline-stop-hook` 关闭。plan-tune 相关 hook 需要用户同意才会写入。
- 描述普遍很短（如 `Pre-landing PR review. (gstack)`），62 项合计约 5.1K 字符。但正文很大（`review/SKILL.md` 约 58KB），且调用时先执行 bash preamble。

## 对原结论的修正

| 原结论 | 修正 |
|---|---|
| 平衡点看清单预算是否溢出 | 本机加上 gstack 也没有溢出；短期内平衡点只看「同一意图可自动触发的 skill 不超过 1 个」与常驻 hook 注入 |
| mattpocock 全局安装，按 skill 分 B/C 层 | 不可行。只能二选一：全局启用（11 个可自动触发，其中 3 个与 superpowers 重叠），或从全局移除、在场景 `enabledPlugins` 启用 |
| gstack 全局安装，默认 B 层，场景打开 C 层 | 可行，机制已实测。补充：建议以 `--prefix` 安装，避免占用 `/review` 等通用名称；`skillOverrides` 的键随之为 `gstack-<名称>` |

## 建议（待用户确认）

- **superpowers**：维持全局。
- **mattpocock-skills**：倾向从全局移除，改在 `prd-design`、`backend-dev` 场景的 `enabledPlugins` 启用。
  - 理由：它最有价值的 `grill-me`、`to-spec`、`to-tickets`、`domain-modeling` 集中在需求与设计阶段，其中多数本来就只能手动调用；全局启用的代价是 3 个与 superpowers 重叠的自动触发 skill。
  - 代价：在任意目录无法 `/grill-me`。若你常在非场景目录用它，就维持全局，接受重叠。
- **gstack**：
  - 全局安装，`--prefix`。
  - `settings/settings.user.json` 的 `skillOverrides` 把全部 `gstack-*` 设为 `user-invocable-only`；iOS、gbrain、openclaw、ubicloud 一类用 `gstack-config set disabled_skills` 或 `off`。
  - 场景模板只把需要的几个设为 `on`。
  - 安装包装脚本是否默认 `--no-timeline-stop-hook`，需要你决定。
- **与既有决定**：交接文件记录过「不用 `skillOverrides` 关闭、由用户手动调用」。本建议只对 gstack 使用 `user-invocable-only`，效果仍是「手动调用」，但属于修改该决定。

## 未验证与局限

- gstack 的 setup 没有实际运行，以上安装行为来自源码阅读。安装后的名称、hook 写入需在真实安装时确认。
- 装 gstack（短名称）后 `/review` 执行的是 gstack 还是内置 `/code-review` 的别名，未实测。
- 清单预算的实际上限（字符或 token）没有测出，只确认本机 131 项未溢出、压缩时会丢描述。
- 自动触发的误触发率（重叠 skill 互抢）没有行为实测，属于推论；可并入阶段 3 的行为验证。
- 每个案例只跑一次。清单与菜单由设置决定，结果确定性高，但未重复。

## 补充：gstack 实际安装与 hook（2026-10-28 第二轮）

隔离 `HOME`（scratchpad 下 `sk/home`）中把克隆放在 `~/.local/share/gstack`，执行 `./setup --prefix --no-timeline-stop-hook --no-plan-tune-hooks --no-browser`，退出码 0：

- setup 自动创建 `~/.claude/skills/gstack → ~/.local/share/gstack`，不需要手动 `ln`；安装摘要显示 `source: ~/.local/share/gstack`。
- `~/.claude/skills/` 下共 64 项：61 个 `gstack-*` skill、别名 `gstack-connect-chrome`、路由 `gstack` 与 `_gstack-command`。frontmatter `name` 与目录名一致。
- `~/.claude/settings.json` 保持 `{}`，没有写入 hook；`~/.gstack/config.yaml` 记录了选择。
- 克隆目录建置后约 1.1GB（`node_modules` 565MB，`.git` 23MB）。
- T10：把真实安装的 `SKILL.md` 放进测试项目，`gstack-review: user-invocable-only`、`gstack-ios-qa: off`、`gstack`、`_gstack-command` 均按预期生效，`gstack-ship` 未设置时保持可见。
- 串接：各 skill 多以 Read `~/.claude/skills/gstack/<skill>/SKILL.md` 串接，不经 Skill 工具；只有路由 skill 用 Skill 工具派发。

hook（源码阅读，`setup`、`bin/gstack-config`、`hosts/claude/hooks/`）：

| hook | 事件 | 作用 | 默认 | 设为 no 时 |
|---|---|---|---|---|
| timeline Stop hook | Stop，全局每回合 | 给中断的 skill 补「completed（unknown）」，只有 `retro` 读取 timeline | `yes` | 下次 setup 会移除已注册的 hook |
| plan-tune `question-log-hook` | PostToolUse，matcher `AskUserQuestion` | 记录每个问题与用户的选择，供 `/gstack-plan-tune` 学习偏好 | `prompt`（终端询问，非交互时跳过） | 不再安装，但**不移除已注册的 hook**，要用 `./setup --no-team` 或 `gstack-settings-hook remove-source --source plan-tune-cathedral` |
| plan-tune `question-preference-hook` | PreToolUse，matcher `AskUserQuestion` | 按偏好对带 `<gstack-qid:…>` 标记的问题直接拒绝提问并自动决定；无标记的问题放行，但可附加 memory nugget 上下文 | 同上 | 同上 |
| `auq-error-fallback-hook` | PostToolUse，matcher `AskUserQuestion` | AskUserQuestion 出错时提示改用文字提问 | 与 plan-tune 一起安装 | 同上 |

`gstack-config set timeline_stop_hook yes|no`、`gstack-config set plan_tune_hooks prompt|yes|no` 只保存设置，下次 `./setup`（或 `/gstack-upgrade`）时才生效；只有 `skill_prefix`、`disabled_skills` 在 set 时会立即 relink。

## 实测副作用与清理

- 共执行 15 次 `claude -p`（haiku 14 次、opus 1 次；另 1 次隔离目录登录失败）；gstack setup 只在隔离 `HOME` 中运行 1 次。
- Claude Code 自动生成会话记录：`~/.claude/projects/-private-tmp-claude-501--Users-zz-workspace-github-repos-agent-prompt-rules-system-9d8ed949-783b-4043-9280-e586a3db95df-scratchpad-sk-proj/` 与 `...-scratchpad-sk-proj2/`。可手动删除。
- 用户层案例（T6～T9）加载了本机插件与 hook，hook 的输出落在 scratchpad 测试项目内。
- 测试项目、上游克隆、脚本都在 scratchpad 的 `sk/` 下，会话结束后随 scratchpad 清理。
