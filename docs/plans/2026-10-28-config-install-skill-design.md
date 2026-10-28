# 配置安装技能（`myconfig`）需求与设计

状态：v3（2026-10-29）：第 9 节决定已由用户确认（2026-10-29）；已实现于 `dot_claude/skills/myconfig/`，会话实测后按第 11 节调整。以下 v2 正文保留作为设计依据，与第 11 节冲突处以第 11 节为准。
原状态：草案 v2（2026-10-28，无人值守产出）。v1 经独立子代理交叉审查（2 blocker、11 should-fix、7 nit），已全部按推荐修改；第 9 节的决定按推荐默认值暂定，**待用户确认**。尚未实现，未提交。
附件：`docs/plans/2026-10-28-config-install-skill/inventory.md`（脚本盘点）、`review-v1.md`（v1 审查原文）。
依据：本仓库安装脚本盘点（子代理读源码、跑 `-h` 与 `-d`，临时 HOME）；官方 skill 文档 `https://code.claude.com/docs/en/skills.md`（frontmatter、`!` 动态注入及其失败行为、`${CLAUDE_SKILL_DIR}`、`allowed-tools`、调用控制、`description`+`when_to_use` 上限 1,536 字符、`SKILL.md` 建议 500 行内）。

## 1. 目标

让用户用一句话管理本仓库提供的配置：

- **没说清要装什么**：列出配置能力清单与一句话说明，附可直接说的示例；不写入任何东西。
- **说清了装什么、装到哪**：预演 → 一次确认 → 调用对应脚本 → 报告结果与安装后仍需手动做的事。
- **只说了一半**：只追问缺的那一项，给推荐值。

非目标：不改安装脚本行为；不改模板内容；v1 不做卸载、不支持 Codex（只留一行退路）。

## 2. 配置能力清单

技能列出的内容分两部分：4 个场景的一句话说明写死在 `SKILL.md`（很少变）；「FLAG × 维度」可用性矩阵与支持包主条目由 `scripts/catalog` 现场生成（≤30 行）。

| 分组 | 单元 | 脚本（`<R>` = 仓库路径） | 写入位置 | 技能是否执行（v2 设想；v3 起所有写入都只交付命令，见 §11） |
|---|---|---|---|---|
| 场景整包（推荐） | `prd-design`、`frontend-dev`、`backend-dev`、`dev-ops` | `<R>/scripts/install-claude-project.sh -f <FLAG> -t <项目>` | `<项目>/.claude/**`、`.mcp.json`、`CLAUDE.md`；支持包另有项目外副作用（OpenSpec `npm -g`、codegraph `curl \| sh`、pm-skills `git clone` + `claude plugin install`） | 是（目标在 cwd 下时） |
| 单一维度 | settings（project：4 场景 + `fullstack-dev`；local：4 场景） | `install-settings.sh -l project\|local -s <FLAG> -p <项目>/.claude -m overwrite\|merge` | `settings.json` / `settings.local.json` | 是 |
| | CLAUDE.md | `install-claude-md.sh -f <FLAG> -t <项目>` | `<项目>/CLAUDE.md` | 是 |
| | `.mcp.json`（只有 backend-dev、dev-ops 有内容） | `install-dot-mcp.sh -f <FLAG> -t <项目>` | `<项目>/.mcp.json` | 是 |
| | agents | `install-agent-pkg.sh -f <FLAG> -t <项目>/.claude/agents`（目录须先存在） | `.claude/agents/` | 是 |
| | skills（场景及 `open-supports`、`github-ops`、`codex-repair`） | `install-skill-pkg.sh -f <FLAG> -t <项目>/.claude/skills` | `.claude/skills/` | 是 |
| | 单个支持包 | `install-open-supports.sh -t <项目> -n <包>` | 视支持包 | 是 |
| 全局工具 | gstack、task-master + gstack `skillOverrides` 同步 | `install-claude-project.sh -g` | `~/.claude/`、`~/.local/share/gstack`；`npm -g` | **否**，只给命令 |
| 个人用户级 | `dot_claude/` | `install.sh -l user -m overwrite …`（最小范围，见 `commands.md`） | `~/.claude/`，**覆盖不备份** | **否**，只给命令 |
| | 全局 settings | `install-settings.sh -l user` | `~/.claude/settings.json` | **否**，只给命令，并提醒先比对差异 |
| Codex | 个人差异规则区块 | `<R>/scripts/multi_client_support/codex.sh` | `~/.codex/AGENTS.md` | **否**，只给命令 |

排除：模板名 `FLAG-NAME*`、`NAME-FLAG`（实测 `-f FLAG-NAME_template` 能通过脚本校验）；`fullstack-dev` 没有整包，只有 settings；`agents-agency-agent-based-dev`（48 个 agent 原始池）只在用户点名时提供。

## 3. 交互设计

### 3.1 意图判定

| 用户输入 | 行为 |
|---|---|
| `/myconfig`、「這個倉庫能配什麼」 | 列表：场景说明 + catalog 矩阵 + 3 条示例说法 |
| 「把 backend-dev 裝到這裡／<目录>」 | 安装（§3.2） |
| 「給這個專案裝配置」（缺单元） | 按 §3.3 推荐，用 `AskUserQuestion` 给推荐项 + 其他选项；不明确时直接列 4 个场景 |
| 「裝 backend-dev」（缺目标） | 默认候选为 cwd（cwd 是本仓库时改为请用户给路径） |
| 「backend-dev 的 settings + agents」 | 多单元：一份预演、一次确认、固定顺序（§3.2 第 6 步） |
| 「更新 backend-dev 配置」 | 整包 `-F`；报告中 `[STALE]` 的支持包再提示 `install-open-supports.sh -t <P> -F`（先 `--dry-run`），因为整包脚本不把 `-F` 转给支持包 |
| 「裝 gstack」「同步全域設定」「裝 Codex 規則」「更新個人 CLAUDE.md」 | 不执行：给出最小范围的完整命令与影响说明，让用户在终端执行 |

### 3.2 安装流程

1. **定位仓库**：读 catalog 注入输出的第一行 `REPO=`；`REPO=NOT_FOUND` 时停止并转述设置方法。
2. **判断能否在会话中执行**：目标须在当前 cwd 之下，且单元不属于全局 / 用户级 / Codex。否则跳到第 7 步只输出命令。原因：本机沙箱只允许写 cwd 与少数缓存目录，且 `allowUnsandboxedCommands: false`。
3. **解析**：单元 → 脚本与参数，查 `references/commands.md`；目标转为绝对路径并检查存在。所有脚本都从 `$0` 推出仓库根，所以保持 cwd 不变，用 `sh "<R>/scripts/x.sh" … -t "<绝对路径>"` 调用。
4. **预检（只读）**：
   - 目标是否 git 仓库，有无未提交改动；
   - `.gitignore` 是否已含 `*.bak.*`、`.claude-project-backup-*`、`settings.local*.json`；
   - 将被跳过的已存在文件。
5. **预演**：
   - 有预演的脚本（`install-claude-project.sh -d`、`install-open-supports.sh --dry-run`）直接运行，压缩为「新增 N / 跳过 M（列文件）/ 将装的支持包及其项目外副作用」。
   - 其余单一维度脚本由技能只读列出「源 → 目标 / 冲突」。
6. **一次确认**（`AskUserQuestion`）：
   - 选项：「安裝（推薦）／加 -F 覆蓋已存在檔案（先備份，列出檔案）／取消」。
   - 目标已有 `settings.json` 时，把选项换成「overwrite（備份，模板 permissions 生效）／merge（只合併外掛與 skillOverrides，模板 permissions 不寫入）」。
   - 写明不会回滚的项目外副作用（`npm -g`、插件下载到 `~/.claude/plugins/`）。
   - 多单元执行顺序：settings → CLAUDE.md / .mcp.json → agents（先 `mkdir -p`）→ skills → 支持包；遇到第一个失败就停。
   - 退路：参数中已带「確認」或 `-y` 时视为已确认；`AskUserQuestion` 不可用（如 `claude -p`）时改为文字提问后停止。
7. **执行**：
   - 去掉 `-d` 照原参数运行；可能耗时的（含支持包、`npm`、`git clone`）设 `timeout: 600000`。
   - 不用 `-m ask`（Bash 工具无 tty）。
   - 失败时不自动重跑有副作用的整段命令。
8. **报告**：
   - 按标签计数 `[MANUAL]`、`[STALE]`、`[CONFLICT]`、`[BACKUP]`、`[INVALID]`，结合退出码判断结果；各脚本的汇总行格式不同，见 `commands.md`。
   - 分段写「配置复制」与「支持包」。整包脚本的退出码来自支持包阶段，exit 1 时配置可能已复制完成。
   - 列出备份路径，提醒确认后删除或加进 `.gitignore`。
   - 读场景包 README 的「手动安装与恢复」「MCP 服务器」节，列出安装后仍需手动做的事。

### 3.3 场景推断（只做推荐）

| 线索 | 推荐 |
|---|---|
| `go.mod`、`migrations/`、`*.sql`；`package.json` 含 express / fastify / @nestjs / prisma / mongoose | backend-dev |
| `package.json` 含 react / vue / svelte / vite | frontend-dev |
| 前后端都有，或 next / nuxt | 提示没有 fullstack 整包；推荐 backend-dev 或 frontend-dev 整包 + `fullstack-dev` settings |
| 只有 `Dockerfile`、`docker-compose*.yml`、`.github/workflows/` | dev-ops |
| 以 `docs/`、`*.md` 为主，无代码 | prd-design |

## 4. 安装后提示的来源

- 不另建 `post-install.md`。安装后 Read 场景包 README 的「手动安装与恢复」「MCP 服务器」节，避免两份内容不一致。
- README 没写的跨场景陷阱放进 `commands.md`：
  - 单装 backend-dev settings 时，hook 指向的 `.claude/hooks/go-fmt.sh` 只在场景包里有；
  - 单独 `install-settings.sh -m overwrite` 会冲掉 pm-skills 写入的条目，之后要重跑 `install-open-supports.sh -t`；
  - 含 permissions 的模板（backend-dev、dev-ops、fullstack-dev）merge 时不会写入 permissions；
  - `settings.local*` 应加进 `.gitignore`；
  - 数据库 MCP 只用只读账号。

## 5. 实现方案

### 5.1 定位仓库（catalog 内，第一行输出 `REPO=<path>`）

按顺序查找：

1. 环境变量 `AGENT_RULES_REPO`；
2. catalog 自身的物理路径（`pwd -P` 往上 3 层）是仓库检出；符号链接安装或在仓库内运行时零配置；
3. cwd 的 git 根就是本仓库；
4. 都不命中：输出 `REPO=NOT_FOUND` 与设置方法，**exit 0**。

不写作者本机的默认路径，因为仓库公开。判断「是本仓库」的标准：`scripts/install-claude-project.sh` 与 `dot_claude_projects/` 同时存在。

### 5.2 catalog 必须永远 exit 0

官方文档「When an injected command fails」：注入命令非 0 退出会中断整个技能调用，Claude 看不到技能内容。所以 catalog 内部捕获所有错误，以文字形式报告。

### 5.3 文件结构

```
dot_claude/skills/myconfig/
  SKILL.md                  # ≤150 行，繁体中文：硬性规则、意图判定、流程、4 场景说明
  scripts/catalog           # POSIX sh，只读，exit 0；REPO= + 可用性矩阵 + 支持包主条目，≤30 行
  references/commands.md    # 单元 → 脚本参数、目标路径语义表、预演方式、退出码与标签解析、跨场景陷阱
```

### 5.4 frontmatter

以 `dot_claude/skills/myconfig/SKILL.md` 为准。与 v2 草案的差异：description 改为「會話中只做預演；寫入改給一條命令由使用者執行」；注入与 `allowed-tools` 均为 `sh "${CLAUDE_SKILL_DIR}/scripts/catalog" || printf 'REPO=UNREADABLE
'`，因为沙箱 `denyRead` 时 `sh` 读不到脚本会非 0 退出，整个技能随之中断（§11 实测）。

`allowed-tools` 只预授权 catalog，且须与正文注入命令逐字一致；安装命令仍走正常权限流程。正文加一行退路：「若上方未展開清單，執行本技能目錄下的 `scripts/catalog`」（Codex 等不支持 `!` 注入的环境）。

## 6. 硬性规则

以 `SKILL.md`「硬性規則」节为准（v3：技能只执行只读命令与预演，所有写入交付命令由用户执行）。

## 7. 放置与安装

放 `dot_claude/skills/myconfig/`（繁体中文）。安装用 `install.sh -l user` 复制到 `~/.claude/skills/`（默认），并在 shell rc 设 `AGENT_RULES_REPO`。目标是**其他项目**，所以技能必须在任意项目可用；仓库根 `.claude/skills/` 与 `skills/skills-<FLAG>/` 都不满足。实现时同步更新 `dot_claude/README.md`、HANDOFF。

## 8. 验收标准与测试

`scripts/tests/test-myconfig-catalog.sh`（自动）：

1. catalog 在找到仓库、`AGENT_RULES_REPO` 指定、找不到仓库、仓库缺目录时都 exit 0；第一行为 `REPO=…`；输出 ≤30 行；不含模板名。
2. `dot_claude/skills/myconfig/` 内不含 `/Users/` 或 `~/workspace` 绝对路径。

手动 / 会话实测（真实 Claude Code 会话，临时项目为 cwd）：

3. `/myconfig` 无参数：分组清单 + 示例，无写入。
4. 「把 backend-dev 裝到這裡」：预演摘要 → 一次确认 → 交付命令；用户执行后，报告含 README 中的手动步骤。（v3：沙箱禁止会话内写 `.claude/settings.json` 等，已实测，见 §11；交付命令部分已通过，报告部分未测）
5. 再执行一次（幂等）：报告「全部已存在，无改动」，并提供 `-F`。
6. 目标已有 `CLAUDE.md`：报告跳过 1 个文件，确认项含 `-F`。
7. 支持包失败但配置已复制：报告分段写清楚。
8. 「backend-dev 的 settings + agents」：只确认一次，顺序正确，agents 目录自动建立。
9. 「給 <含 go.mod 的目录> 裝配置」：推荐 backend-dev。
10. 「裝 gstack」：不预演，直接给出命令与影响说明。
11. 触发评估：应触发「這個倉庫能配什麼」「把 frontend-dev 裝到這裡」；不应触发「允許 npm 指令」（update-config）、「這專案該用哪些 Claude 功能」（claude-automation-recommender）、「裝 lodash」。

## 9. 决定与待确认（按审查推荐暂定）

| # | 问题 | 暂定 | 备选 |
|---|---|---|---|
| 1 | 调用方式 | 模型可自动触发；写入前强制预演并确认一次 | `disable-model-invocation: true`，只能 `/myconfig` |
| 2 | 目标不在 cwd | 只输出命令让用户在终端执行，或在目标目录重开会话 | 在沙箱 `allowWrite` 加项目根（扩大所有命令写入范围，不推荐） |
| 3 | 全局 / 用户级 / Codex 单元 | 只列出并给最小范围命令，不执行 | 由技能执行（受沙箱限制，多半失败） |
| 4 | 技能安装与仓库定位 | `install.sh -l user` 复制 + shell rc `export AGENT_RULES_REPO=…`；catalog 同时支持自定位 | 符号链接安装：零配置、随仓库更新，但之后同步 `dot_claude/` 要加 `-E skills/myconfig`，否则 `cp` 同一文件报错中断 |
| 5 | 确认次数 | 每次安装一次；冲突时 `-F` 作为同一问题的选项 | 预演、覆盖分开确认 |
| 6 | Codex | v1 不支持，只留一行退路 | 另出 Codex 版 |
| 7 | 卸载 / 回滚 | v1 不做；报告给备份路径与 git 回退指引 | 做 `uninstall` 意图 |

未验证、实现时须实测：

- 沙箱下在 cwd 内写 `.claude/settings.json` 是否被额外保护；
- RTK 的 PreToolUse hook 是否作用于注入命令；
- `typescript-native-lsp` 是否自动加载。

另记一处仓库文档过期：`dot_claude_projects/README.md` 写 backend-dev 有「5 个 skill」，实际 7 个（盘点发现，未改）。

## 10. 实现顺序（确认后）

1. `scripts/catalog` + `test-myconfig-catalog.sh`（先写测试）。
2. `references/commands.md`。
3. `SKILL.md`。
4. 会话实测第 3～11 条；用 `skill-creator` 做触发评估。
5. 更新 `dot_claude/README.md`、HANDOFF；分主题提交。

## 11. 实测结果与设计调整（2026-10-29，v3）

用 `claude -p`（Claude Code 2.1.312）在临时 Go 项目实测，技能放在项目 `.claude/skills/` 下（不改本机 `~/.claude`），`AGENT_RULES_REPO` 指向仓库。

| 实测 | 结果 |
|---|---|
| `!` 注入 + `REPO=NOT_FOUND` 路径 | 正常；技能转述设置方法，未执行命令 |
| `AGENT_RULES_REPO` 是否传入注入命令 | 是 |
| 其他项目中读取仓库 | **被沙箱拒绝**：本机 `denyRead` 含 `~/`，`allowRead` 只有 `.` 等。用 `--settings` 临时加 `sandbox.filesystem.allowRead: [<仓库>]` 后清单与预演正常 |
| cwd 内写 `.claude/settings.json`、`.claude/skills/`、`.claude/hooks/` | **被沙箱拒绝**（原第 9 节「未验证」项，现已验证）；技能遵守硬性规则停下，未半装 |
| 调整后：预演 → 给出命令 | 正确列出 50 个新增文件、无冲突、缺 `.gitignore`、MCP 可写提醒；给出的命令实际执行 `copied=50 manual=0` exit 0 |

| 注入命令是否受沙箱限制（探测技能读 `denyRead` 下的文件） | **受限**，被拒即整个技能中断。注入改为 `sh … catalog \|\| printf 'REPO=UNREADABLE\n'` 后技能正常加载，并带出 `Operation not permitted`（已实测） |

调整（取代 §3.2 第 2、6 步与 §9 第 2 项）：

- 技能只执行只读命令与预演；所有写入都给出一条完整命令由用户执行，建议在提示列用 `! <命令>`，让输出回到会话后再回报。
- 使用前提：仓库路径与 `~/.claude/skills/myconfig` 加入 `sandbox.filesystem.allowRead`（改本机配置，由用户自行设置）；技能装在 `~/.claude/skills/` 下时，注入命令本身也要能读到该目录。SKILL.md 对 `REPO=UNREADABLE` 给出这条说明。
- 测试新增：`allowed-tools` 与注入命令逐字一致且带 `||` 退路。

仍未验证：

- `!` bash 模式执行的命令是否受沙箱限制、是否有 2 分钟超时（SKILL.md 已写退路：出现 `Operation not permitted` 改到终端；含支持包直接建议终端）；
- RTK hook 是否作用于注入命令；
- 安装后回报步骤（解析执行输出、读 README）未做端到端测试。

第二轮交叉审查（实现审查，原文 `2026-10-28-config-install-skill/review-impl.md`）：1 blocker（单个支持包预演模板把 `--dry-run` 放在 `--` 之后会变成真实安装）、11 should-fix、10 nit，已全部按建议修改；catalog 的 NOTE 子 shell 丢失已修复并加测试。
