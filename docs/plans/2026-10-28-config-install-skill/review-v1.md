# `myconfig` 设计草案独立审查

对象：`docs/plans/2026-10-28-config-install-skill-design.md`（下称「草案」）
依据：脚本源码（行号为 2026-10-28 工作区）、`https://code.claude.com/docs/en/skills.md`（官方 skill 文档，下称「文档」）、`dot_claude/settings.json`（本机设定镜像）、`docs/handoff/HANDOFF.md`。
本次只读：未修改仓库，只在 scratchpad 临时 HOME 下跑了 `install.sh -h`；另做了一次只读的沙箱探测（`ls` 读取 cwd 以外的目录，成功）。

---

## Blocker

### B1. `catalog` 只要以非 0 退出，整个技能就无法调用

- 证据：文档「When an injected command fails」：「A failed command aborts the entire skill invocation … Claude never sees the skill content」；默认 bash 下任何非 0 退出码都算失败。草案 §5.1「都不命中：报告并提示设置」和验收 6「找不到仓库：明确报错」都默认 catalog 会报错退出。按草案实现，找不到仓库时用户只能看到 `Shell command failed for pattern …`，技能正文里的引导根本不会显示。
- 建议：
  - `catalog` 规定**永远 exit 0**：找不到仓库时，输出 `REPO=NOT_FOUND` 加一行设置方法；内部错误同样输出 `ERROR=…` 后以 0 退出（不靠 `set -e` 直接中断，或者在注入行末尾加 `|| true`）。
  - SKILL.md 开头写一条分支：`REPO=NOT_FOUND` 时只做引导，不往下执行。
  - 测试里加断言：在找不到仓库、仓库缺目录这两种情况下，退出码都是 0，且输出含 `REPO=`。

### B2. 用户自己的沙箱设定很可能挡住「装到其他目录」和所有全局安装（未实测写入）

- 证据：`dot_claude/settings.json` 中 `sandbox.enabled: true`、`allowUnsandboxedCommands: false`（不能用 `dangerouslyDisableSandbox` 绕过），`filesystem.allowWrite` 只有 `/tmp`、`~/.cache`、`~/.npm` 等缓存目录，**没有**其他项目目录、`~/.claude`、`~/.local/share`、`~/.codex`，也没有全局 npm 前缀。另有 `defaultMode: auto`、`autoAllowBashIfSandboxed: true`。
- 影响：
  - 会话 cwd 不是目标项目时（例如在本仓库里说「装到 ~/work/api」），复制大概率因 EPERM 失败。
  - `-g`（写 `~/.claude/settings.json`、`~/.local/share/gstack`，跑 `npm -g`）、`install.sh -l user`、`codex.sh`、支持包里的 `npm install -g` / `curl | sh`，在 Claude Code 里多半都跑不完。
  - 验收 2「装到 <临时目录>」只有临时目录恰好在 cwd 内才可能通过。
  - 另外，沙箱是否额外保护 cwd 内的 `.claude/settings.json` 写入，属**未验证**。
- 已验证的只有读取：本会话能读 cwd 以外的 `~/workspace/...`，所以 catalog 读仓库没问题。写入行为**未实测**（按约束不在真实目录试写）。
- 建议：
  1. 主路径改为「目标 = 当前会话 cwd（或其子目录）」，脚本用绝对路径调用（见 S3），cwd 不切换。
  2. 目标不在 cwd 下，或者是全局 / 用户级 / Codex 单元时：技能完成预演后，**输出一条完整命令让用户在终端执行**（或提示用 `claude` 在目标目录重开会话），不在会话里直接执行。
  3. 验收里加一条「真实 Claude Code 会话 + 临时项目为 cwd」的实测，确认 `.claude/settings.json`、`.claude/skills/`、`.mcp.json` 都能写入；没实测前，草案不能声称自动安装可用。

---

## Should-fix

### S1. 「个人用户级」「Codex」单元的副作用写错了，而且不该由技能直接执行

- 证据：
  - `scripts/install.sh:362-368`：`overwrite` 模式直接 `cp` 覆盖已有文件，**没有备份**（只有 `-C` 时才会移动旧版残留）。`-l user -m overwrite` 会覆盖 `~/.claude/CLAUDE.md`，而本机这个文件里有 Homebrew、curl、`@RTK.md` 等专属规则（盘点 §1.6）。
  - 草案 §2 表中这两行「项目外副作用」都写「无」。
  - HANDOFF「用户约束」：未经要求不得修改本机配置。
- 建议：
  - 这几类单元只**列出并给出命令**，不执行：`install.sh -l user`、`install-settings.sh -l user`、`codex.sh`、`install-claude-project.sh -g`。命令统一用最小范围，例如 `-m overwrite -E commands -e CLAUDE.md -e settings.json`（`install.sh -h` 中的「只更新 skills/」示例）。
  - 表中改写副作用为「覆盖 `~/.claude/...`，无备份」。
  - 这样也绕开了 B2 的沙箱问题。

### S2. 「解析汇总行」与实际输出格式不符

- 证据：各脚本收尾的输出不一样：
  - `install-claude-project.sh`：`复制完成。copied= forced= manual= empty= invalid=`
  - `install-agent-pkg.sh:134`：`Done. copied= forced= manual=`
  - `install-skill-pkg.sh:150`：在上面基础上多一个 `invalid=`
  - `install-claude-md.sh`、`install-dot-mcp.sh`：没有汇总行，只打印 `[MANUAL]` / `[COPIED]`，已存在时 exit 0（`install-claude-md.sh:124-126`）
  - `install-settings.sh:536`：只有一句 `配置安装完成。`
  - `install-open-supports.sh:712-720`：有 `stale=`、`no_script=`，但 `stale>0` 时仍是 exit 0。
- 还有一种「部分成功」：`install-claude-project.sh` 的最终退出码来自支持包阶段（`:349`），所以 exit 1 时配置文件**已经复制完成**。
- 建议：
  - `references/commands.md` 改为按标签计数：`[MANUAL]`、`[STALE]`、`[CONFLICT]`、`[BACKUP]`、`[INVALID]`，再结合退出码判断。
  - 报告分两段写：「配置复制：成功」「支持包：X 失败」。
  - 失败时只建议重跑出错的那个支持包：`install-open-supports.sh -t <P> -n <ost> --dry-run` 之后再正式执行。不要重跑整包，这也和用户「只重试失败请求」的规则一致。

### S3. 目标路径语义与调用方式

| 脚本 | `-t`/`-p` 含义 | 不存在时 | 证据 |
|---|---|---|---|
| `install-settings.sh` | `-p` 是 **`.claude` 目录**；`-s` 必填 | 自动创建 | `install-settings.sh:37,455-482` |
| `install-agent-pkg.sh` | agents 目录 | **报错 exit 1**，要先 `mkdir -p <P>/.claude/agents` | `install-agent-pkg.sh:81-82` |
| `install-skill-pkg.sh` | skills 目录 | 自动创建 | `install-skill-pkg.sh:89-91` |
| `install-claude-md.sh` / `install-dot-mcp.sh` | 项目根 | exit 1 | `:106` / `:100` |
| `install-claude-project.sh` | 项目根；**不会转成绝对路径**，只去掉末尾的 `/` | exit 1 | `:150-155` |

- 草案中 `multi_client_support/codex.sh` 路径错误，实际是 `scripts/multi_client_support/codex.sh`（草案 §2 表、§3.2 第 4 步）。
- 所有脚本都通过 `$0` 推出 `REPO_ROOT`（如 `install-agent-pkg.sh:14-15`、`install.sh:296-297`），所以盘点里「须从仓库根执行」不准确。技能应**留在目标 cwd**，用 `sh "<REPO>/scripts/x.sh" … -t "<绝对路径>"` 调用，不要 `cd` 到仓库（这对 B2 也有利）。
- 建议把上表原样放进 `references/commands.md`。

### S4. 定位仓库：去掉作者本机的默认路径，改为自定位

- 证据：
  - HANDOFF:76 写明仓库「公开供参考」。
  - 草案 §5.1 第 3 步的 `~/workspace/github_repos/agent-prompt-rules-system` 是作者私有路径，会写进公开的 `dot_claude/`，而且与 §3.2 第 1 步「不猜路径」自相矛盾。
- 建议的顺序（全部写在 catalog 里，第一行输出 `REPO=<path>`；同时去掉单独的 `--repo` 模式，避免再调用一次）：
  1. `$AGENT_RULES_REPO`
  2. catalog 自身的物理路径（`cd "$(dirname "$0")" && pwd -P` 往上 3 层）若是仓库检出：符号链接安装和在仓库内运行时都能零配置命中
  3. cwd 的 git 根就是本仓库
  4. 都不中时输出 `REPO=NOT_FOUND` 和设置方法（遵守 B1）
- 「安装时由 install.sh 记录路径」需要改安装脚本，违反草案「不改脚本行为」的非目标，不推荐。
- 符号链接安装的坑：之后再跑 `install.sh -l user -m overwrite` 时，`cp` 的源和目标是同一文件，会报错并在 `set -eu` 下中断，需要加 `-E skills/myconfig`。所以把它放进用户决定项，不作为默认。

### S5. 长时间命令会撞上 Bash 2 分钟超时

- 证据：文档「How injected commands run」说明默认超时为 2 分钟。以下操作在用户的高延迟代理环境（全局 CLAUDE.md「弱网环境」）下很容易超过 2 分钟：gstack 构建（约 1.1GB，盘点 §1.2）、`npm install -g`、`git clone`、`curl | sh`。
- 建议：正式执行（非预演）时显式设 `timeout: 600000`，或改为后台运行并等待结束通知；`-N`（只复制配置）的情况不受影响。

### S6. 重装 / 更新流程没有定义，`-F` 语义有坑

- 证据：
  - `install-claude-project.sh:341-349` 调用支持包安装器时**不会转发 `-F`**。所以「整包加 `-F`」不会更新已 vendor 的支持包，只会报 `[STALE]`，且 exit 0。
  - 备份放在项目内：`<P>/.claude-project-backup-<ts>/`、`.mcp.json.bak.*`、`CLAUDE.md.bak.*`、`settings.json.bak.*`，很容易被误提交。
- 建议：
  - 草案增加「更新」意图：整包 `-F` 之后，如果报告有 `stale>0`，再提示 `install-open-supports.sh -t <P> -F`（先 `--dry-run`）。
  - 报告末尾列出备份路径，并提醒「确认无误后删除，或加进 `.gitignore`」。
  - `-F` 的确认文本直接列出预演里 `[MANUAL]` 的文件：这些就是会被覆盖的文件，不需要再预演一次。

### S7. 「带说明的清单」没有说明来源；`post-install.md` 与 README 重复

- 证据：
  - catalog 只是「扫描各维度目录」（§5.2），目录名本身不含说明，而用户需求 (a) 要的是「带解释」。
  - 各场景包 README 已有「## 手动安装与恢复」「## MCP 服务器」节（例如 `dot_claude_projects/.claude-backend-dev/README.md:24,45`），草案 §4 再复制一份到 `references/post-install.md`，以后会两边不一致。
- 建议：
  - 4 个场景的一句话说明直接写死在 SKILL.md（4 行，很少变化）；catalog 只输出「FLAG × 维度」的可用性矩阵和支持包主条目，输出控制在 30 行以内。
  - 删掉 `post-install.md`：安装后用 Read 读源仓库对应 README 的「手动安装与恢复」节。只把 README 里没有的跨场景陷阱写进 `commands.md`：单装 backend-dev settings 会缺 `go-fmt.sh`；`overwrite` 会冲掉 pm-skills 写入的条目；`settings.local*` 要加进 `.gitignore`。

### S8. 把任务交给 `open-supports-install` 可能找不到这个技能；触发锚点需要补

- 证据：`open-supports-install` 位于 `skills/skills-open-supports/`，属于项目级包，只有装进项目后才存在，用户级不一定有。
- 建议：
  - 单个支持包直接由 myconfig 处理：`install-open-supports.sh -t <P> -n <pkg> --dry-run`，然后确认、执行。`when_to_use` 中「改用 open-supports-install」改为「已装 open-supports-install 时可优先使用」，或者直接删掉这句。
  - 补一个反向锚点：「推薦專案該用哪些 Claude Code 功能 → claude-automation-recommender」。
  - `description` 删掉「settings、.mcp.json、agents、skills」这类泛词，避免在其他项目里说「改 settings」时误触发；只保留「本倉庫」「場景包」和 4 个 FLAG 名。目前 description+when_to_use 共 353 字符，远低于 1,536 上限（文档 Frontmatter reference），长度不是问题，问题在锚点。

### S9. 一句话里要装多个单元（「backend-dev 的 settings + agents」）

- 草案没有规则。建议写成：
  1. 多个单元合并成**一份**预演、**一次**确认。
  2. 执行顺序：settings → CLAUDE.md / .mcp.json → agents（先 `mkdir -p`）→ skills → 支持包。「先 settings 后支持包」见盘点 §1.2，否则 pm-skills 的写入会被覆盖。
  3. 遇到第一个失败就停，报告逐个单元写。
- 目标已有 `settings.json` 时，确认项里给出两个选择：「overwrite（备份，失去原有 permissions）」和「merge（只合并插件和 skillOverrides，模板的 permissions 不会写入）」。依据：`install-settings.sh -h`、盘点 §3 #4。

### S10. 调用方式：建议保持可由模型调用

- 对比：
  - 设 `disable-model-invocation: true`：description 不进上下文，省约 350 字符；但「把 backend-dev 装到 X」这类自然语言就不会触发，用户必须记住输入 `/myconfig`，与需求「说清楚就执行」相冲突。依据：文档「Control who invokes a skill」中的表格。
  - 安全性主要来自技能内的「预演 → 一次确认」。另外 `allowed-tools` **不要**预授权安装脚本，只授权 catalog，安装命令仍然走权限和自动模式分类器。
- 建议：保持默认（模型可调用），在 SKILL.md 开头写硬性规则「未經確認不執行任何非預演命令」。
- `AskUserQuestion` 在 `claude -p` 中无法交互，而 HANDOFF 阶段 3 要用 `claude -p` 做行为验证。所以写一条退路：参数中已带「確認 / -y」时视为已确认；`AskUserQuestion` 不可用时，改用纯文字提问后停止。

### S11. 验收与测试缺口

在草案 §8 的基础上增加：

- catalog 在找不到仓库、仓库缺目录时都 exit 0（B1）。
- 输出不超过 30 行。
- `dot_claude/skills/myconfig/` 内不含 `/Users/` 或 `~/workspace` 绝对路径（grep 测试，S4）。
- 部分成功：支持包失败但配置已复制时，报告分段写清楚（S2）。
- 第二次执行同一安装（幂等）：报告「全部已存在，无改动」，并提供 `-F`。
- 多单元请求只确认一次，执行顺序正确（S9）。
- 目标不在 cwd，或是全局 / 用户级单元时：只输出命令，不执行（B2、S1）。
- 触发评估：
  - 应触发：「這個倉庫能配什麼」「把 frontend-dev 裝到這裡」。
  - 不应触发：「允許 npm 指令」→ update-config；「這專案該用哪些 Claude 功能」→ claude-automation-recommender；「裝 lodash」。
- 场景包与维度目录内容一致性守护：目前 4 个 FLAG 的 settings 和 CLAUDE.md 用 `cmp` 比对都一致（本次实测）。若技能会提示「整包与单维度可以混用」，应有测试保证两边持续一致。

---

## Nit

- N1 `allowed-tools`：
  - `Bash(sh ${CLAUDE_SKILL_DIR}/scripts/catalog*)` 可以匹配注入命令。文档示例是 `Bash(${CLAUDE_SKILL_DIR}/scripts/render.sh *)`，变量会在 `allowed-tools` 和正文里一起替换（文档「Available string substitutions」）。
  - 注入命令与规则的写法必须**逐字一致**；非自动模式下，未被允许的注入命令会中断调用（文档「Permission checks on injected commands」）。
  - 建议两处都写成 `sh "${CLAUDE_SKILL_DIR}/scripts/catalog"`，防止路径里有空格。
  - `Read` 本来就不用预授权，可以删掉。
- N2 `!` 注入的输出在**每次**调用时都会进入上下文，包括明确要安装的那次；输出相同时不会重复附加（文档「Skill content lifecycle」）。所以 S7 的「≤30 行」很重要。
- N3 场景推断：后端规则只有 Go 线索，但 HANDOFF 的技术栈还包括 Node.js / TypeScript 后端。建议加上 `express`、`fastify`、`@nestjs`、`prisma`、`mongoose` → backend-dev；`next` / `nuxt` 视为前后端都有。整张表只作为推荐，命中不明确时直接列出 4 个选项，不要硬推断。
- N4 Codex：`!` 注入、`${CLAUDE_SKILL_DIR}`、`AskUserQuestion` 都只在 Claude 里有效（文档「How Claude Code handles the body of a synced skill」说明注入行会以字面形式到达）。v1 不必支持 Codex，但可以在正文加一行退路：「若上方未展開清單，執行本技能目錄下的 `scripts/catalog`」。成本一行，Codex 装到 `~/.agents/skills` 后就基本可用。
- N5 RTK 的 PreToolUse hook 是否也作用于注入命令，**未验证**。catalog 输出应保持纯文本、表格简单，以免被压缩改写。
- N6 回滚：v1 不做卸载命令。报告中给出「备份路径 + 目标是 git 仓库时用 `git status` 列出新增文件后手动删除」即可；注意 `git clean -fd*`、`rm -rf` 已在 deny 列表里。全局副作用（npm -g、插件下载到 `~/.claude/plugins/`）不会回滚，应在确认文本中写明。
- N7 §3.2 第 3 步「检查未提交改动」很好，建议同时检查 `.gitignore` 是否已有 `*.bak.*`、`.claude-project-backup-*`、`settings.local*.json`，没有就在报告里提醒。

---

## 需要用户决定的问题

1. **调用方式**：自然语言自动触发，还是只能 `/myconfig`？
   推荐：**可自动触发**，写入前强制预演并确认一次（S10）。
2. **沙箱下装到其他目录**：
   - 推荐：只有目标在当前会话 cwd 下时才直接执行；其他目录和全局安装都输出命令，让你在终端执行（B2）。
   - 另一个选择是在 `sandbox.filesystem.allowWrite` 加入项目根目录，但会扩大所有命令的写入范围，不推荐。
3. **用户级 / Codex / 全局工具单元**（`install.sh -l user`、`install-settings.sh -l user`、`codex.sh`、`-g`）：
   推荐：**只列出并给出最小范围的命令**，技能不执行（S1）。
4. **myconfig 自己的安装与仓库定位**：
   推荐：用 `install.sh -l user` 复制安装，在 shell rc 中 `export AGENT_RULES_REPO=…`，catalog 同时支持自定位（S4）。
   另一个选择：符号链接安装，零配置、自动跟随仓库更新，但以后同步时要加 `-E skills/myconfig`。
5. **确认次数**：
   推荐：每次安装**只确认一次**。若有冲突，把「覆盖（`-F`）」作为同一问题里的一个选项，不额外再问。
6. **Codex 支持**：
   推荐：v1 不支持，只加一行退路（N4）。
7. **卸载 / 回滚**：
   推荐：v1 不做，报告中给出备份路径和 git 回退指引（N6）。
