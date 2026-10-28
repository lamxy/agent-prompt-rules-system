# 配置安装能力清单（供「安装配置」skill 设计）

调研日期：2026-10-28；仓库 `agent-prompt-rules-system`，HEAD `6adb239`（HANDOFF frontmatter）。
来源：各脚本 `-h`、脚本源码、`AGENTS.md`、`docs/handoff/HANDOFF.md`、`scripts/README.md`、`settings/README.md`、`dot_claude_projects/README.md` 及场景包 README、`dot_mcp_jsons/README.md`、`open_supports/INDEX.md`。
实测仅限：全部脚本 `-h`；`install-claude-project.sh -d`（项目级与 `-g`）、`codex.sh -d`、若干错误路径，均在 scratchpad 临时目录 + 临时 `HOME`/`CODEX_HOME` 下执行。
所有脚本须从**仓库根目录**执行；POSIX `sh` + `set -eu`；JSON 校验与合并依赖 `python3`。

---

## 1. 安装脚本

### 1.1 总览

| 脚本 | 用途 | 作用域 | 预演 | 冲突默认 | 强制 |
|---|---|---|---|---|---|
| `install-claude-project.sh` | **场景包整包安装**（settings + CLAUDE.md + .mcp.json + agents + skills + rules/hooks + 支持包清单），之后自动调 `install-open-supports.sh`；`-g` 为全局工具（gstack、task-master） | 项目根目录 / `~/.claude` | `-d` | `[MANUAL]` 跳过 | `-F` 先备份再覆盖 |
| `install-open-supports.sh` | 安装 `open_supports/` 支持包（清单或单个） | 项目 / 全局 | `--dry-run` | 已复制则复用，不一致报 `[STALE]` | `-F`（仅项目级）备份后替换 |
| `install-settings.sh` | 单一维度：settings 模板 | user / project / local | 无 | 由 `-m` 决定 | `-m overwrite`（先备份） |
| `install-claude-md.sh` | 单一维度：`CLAUDE-<FLAG>.md` → `CLAUDE.md`（或 `AGENTS.md` 等） | 项目根 | 无 | `[MANUAL]` 跳过 | `-F` → `<文件>.bak.<时间戳>` |
| `install-dot-mcp.sh` | 单一维度：`.mcp.json` | 项目根 | 无 | `[MANUAL]` 跳过 | `-F` → `.mcp.json.bak.<时间戳>` |
| `install-agent-pkg.sh` | 单一维度：agents | 任意 agents 目录 | 无 | `[MANUAL]` 跳过 | `-F` → `<target>.backup-<时间戳>/` |
| `install-skill-pkg.sh` | 单一维度：skills | 任意 skills 目录 | 无 | `[MANUAL]` 跳过 | `-F` → `<target>.backup-<时间戳>/` |
| `install.sh` | 同步 `dot_claude/`（个人用户级 CLAUDE.md、commands、skills、settings.json） | user / project / local | 无 | 由 `-m` 决定 | `-m overwrite` |
| `check-gstack-overrides.sh` | **只读**检查 gstack skill 是否都写进 `skillOverrides` | 本机 | 本身只读 | — | — |
| `multi_client_support/codex.sh` | 写 `${CODEX_HOME:-~/.codex}/AGENTS.md` 标记区块 | Codex 用户级 | `-d` | 只替换区块；损坏时报错 | `-F` 重建区块（先备份） |

只有 `install-claude-project.sh`、`install-open-supports.sh`、`codex.sh` 支持预演（`grep -il dry scripts/*.sh` 只命中前两者 + codex.sh）。其余脚本要「预览」只能由 skill 自己列出将写入的路径与冲突。

### 1.2 `install-claude-project.sh`

```
项目级：sh scripts/install-claude-project.sh -f <FLAG> -t <project_dir> [选项]
全局：  sh scripts/install-claude-project.sh -g [选项]
作用域（必选，二选一）：
  -f <FLAG>  场景标识，对应 dot_claude_projects/.claude-<FLAG>/；须与 -t 一起使用
  -t <dir>   目标项目根目录（必须已存在）
  -g         全局；不能与 -f、-t 同用。依次：1 复制全局清单到 ~/.claude/；
             2 把 settings.user.json 的 skillOverrides 合并进 ~/.claude/settings.json（先备份）；
             3 安装清单中的全局支持包（gstack、task-master）
其他（可选）：
  -F  已存在先备份再覆盖（项目：<project>/.claude-project-backup-<时间戳>/；
      全局：~/.claude/open_supports_name_list.txt.backup-<时间戳>）
  -N  只复制配置，不调用 install-open-supports.sh
  -k  仅全局：跳过第 2 步，不改 ~/.claude/settings.json
  -d  预演，不写入
  -s <root> 源 dot_claude_projects 根；-o <root> 源 open_supports 根（传给 -s）
复制规则：目标中包里没有的文件一律保留；空文件、.gitkeep、非法 JSON 跳过；
          已存在且未加 -F → [MANUAL] 跳过，支持包仍按「目标上的」清单安装
```

| 项 | 内容 |
|---|---|
| 写入（项目级） | `<project>/.claude/**`、`<project>/.mcp.json`、`<project>/CLAUDE.md`（只复制包内这三项；包根 `README.md` 不复制）；随后支持包写 `<project>/.claude/open_supports/<ost>/`、`<project>/.claude/skills/<ost>_install/`，以及各支持包自己的副作用（见 1.3） |
| 写入（全局） | `~/.claude/open_supports_name_list.txt`；`~/.claude/settings.json`（只合并 `skillOverrides`，先备份 `.bak.<时间戳>`）；gstack 检出 `~/.local/share/gstack`（构建后约 1.1GB）+ `~/.claude/skills/gstack` 链接；task-master `npm install -g` |
| 顺序 | 先复制 settings，再装支持包（pm-skills 会以 `--scope project` 往项目 settings 写入，所以顺序不能反） |
| FLAG 校验 | 只允许 `[A-Za-z0-9._-]` 且不含 `..`；FLAG 只需在 `dot_claude_projects/` 存在 |
| 退出 | 参数错误 / 源包不存在 / 目标不存在 → `exit 1`（实测：`-f nope`、`-f fullstack-dev`、目标不存在均 exit 1）；`[MANUAL]` **不算失败**，复制阶段 exit 0；最终退出码取自 `install-open-supports.sh`（有 missing/no_script/failed/conflict 时为 1） |
| 预演说明 | `-d` 时目标尚无清单，用包内清单预览支持包；第 2 步只打印 `[DRY-RUN] run …install-settings.sh -l user -m merge -K skillOverrides` |

### 1.3 `install-open-supports.sh`

```
项目级：sh scripts/install-open-supports.sh -t <project_dir> [安装来源] [选项]
全局：  sh scripts/install-open-supports.sh -g [安装来源] [选项]
作用域（必选，二选一）：-t/--target <dir>（须已存在）| -g/--global（不复制、不生成 wrapper Skill）
安装来源（可选，二选一；都不给读默认清单）：
  -n/--name <支持包> [-- 安装参数…]   单个；例 -n acme/widget -- --location=local {PROJECT_DIR}
  -l/--list <清单>                    默认：-t → <project>/.claude/open_supports_name_list.txt
                                            -g → ~/.claude/open_supports_name_list.txt
其他：-s/--source <root>；-F/--force（仅项目级，备份到 .claude/open_supports.backup-<时间戳>/）；
      --no-skills（仅项目级）；--skills-only（仅项目级，不运行安装脚本）；--dry-run
清单：每行 <支持包> [参数…]；名称 OwnerName/RepoName 或 ost_Owner_Repo；参数值不能含空格；
      只支持整行 # 注释；{PROJECT_DIR} → 项目绝对路径（项目级必须带）；
      全局清单含 {PROJECT_DIR}、--local、--location=local → 整份拒绝
```

- 结束汇总行：`完成。mode=… total= vendored= reused= stale= skill_generated= skill_reused= script_ok= missing= no_script= failed= conflict=`；任一 missing/no_script/failed/conflict > 0 → `exit 1`。
- 项目级目标没有清单时：`错误：列表文件不存在：…` exit 1（实测）。
- wrapper Skill `.claude/skills/<ost>_install/SKILL.md`：带生成标记的按清单重新生成；删除标记即视为手动维护；`-n` 只在不存在时创建。
- 已有 skill `skills/skills-open-supports/open-supports-install` 专门包装本脚本（见 §4）。

**支持包自身的外部副作用**（来自源码 / INDEX.md；均需网络）：

| 支持包 | 默认出现在 | 副作用 |
|---|---|---|
| `colbymchenry/codegraph` | backend-dev 清单（主）；frontend-dev（注释） | 未安装时 `curl -fsSL <官方脚本> \| sh` 装 CLI（用户级位置，具体路径未验证）；已装则 `codegraph upgrade`；在项目内 `codegraph install --target=claude --location=local --yes`；不执行 `codegraph init`（需用户手动） |
| `Fission-AI/OpenSpec` | backend-dev（主）；frontend-dev（注释） | `npm install -g <openspec>@latest`（全局！），再在项目执行 `openspec init` |
| `open-gsd/gsd-core` | frontend-dev（主）；backend-dev（注释） | 需 Node ≥ 22、npm ≥ 10；在项目内 `npx <installer> --claude --local` |
| `phuryn/pm-skills` | prd-design（主）；dev-ops（注释，仅 `pm-ai-shipping`） | `git clone --depth 1` 到临时目录；`claude plugin marketplace add … --scope project` + `claude plugin install <p>@pm-skills --scope project`（写项目 `.claude/settings.json`，插件文件下载到 `~/.claude/plugins/`） |
| `garrytan/gstack` | 全局清单 | `git clone/pull` 到 `~/.local/share/gstack`，setup 建 `~/.claude/skills/gstack` 链接；`--prefix`；setup 后自动跑只读 `check-gstack-overrides.sh` |
| `eyaltoledano/claude-task-master --global` | 全局清单 | 需 Node ≥ 20；`npm install -g task-master-ai@latest`；不注册 MCP（需要时手动 `--claude-mcp`） |

### 1.4 `install-settings.sh`

```
sh ./scripts/install-settings.sh -l <user|project|local> -m <overwrite|merge|ask> [-s <场景>] [--src <文件>] [-p <dir>] [-K <字段>]
必选：-l  user → <dir>/settings.json（默认 ~/.claude）；project → <dir>/settings.json；local → <dir>/settings.local.json
      -m  overwrite：备份为 <文件>.bak.<时间戳> 后整体替换
          merge：只逐键合并 enabledPlugins、extraKnownMarketplaces、skillOverrides（先备份），其他字段 [WARN] 列出不写
          ask：从 /dev/tty 询问；非交互环境报错退出
条件必选：-s  project/local 未给 --src 时必填（project -s foo → settings.project-foo.json；local → settings.local-foo.json；user 不带 -s）
         -p/--dst  project/local 必填（不存在时自动创建）；user 默认 ~/.claude
可选：--src <文件>（文件名须匹配作用域）；-K <字段[,字段]>（只与 merge 同用）
当前可用场景：project：prd-design、frontend-dev、backend-dev、dev-ops、fullstack-dev
             local：  prd-design、frontend-dev、backend-dev、dev-ops
```

- 注意 `-p` 指的是 **`.claude` 目录**（如 `~/proj/.claude`），不是项目根。
- 错误场景名：打印可用场景并 exit 1（实测，且未创建目标目录）。
- 同一秒多次执行备份加序号，不覆盖旧备份。
- **自动化陷阱**：`-m ask` 在 Claude Code 的 Bash 工具中无 tty → 报错；skill 必须用 overwrite 或 merge。

### 1.5 单一维度脚本

| 脚本 | 用法（`-h` 节选） | 要点 |
|---|---|---|
| `install-claude-md.sh` | `-f <FLAG> -t <target_dir> [-n <filename>] [-s <root>] [-F]` | `-t` 须已存在（项目根）；`-n` 只能是文件名，如 `AGENTS.md`、`GEMINI.md`；空模板跳过（exit 0） |
| `install-dot-mcp.sh` | `-f <FLAG> -t <target_dir> [-s <root>] [-F]` | 输出固定 `.mcp.json`；prd-design、frontend-dev 为空模板 → 跳过；非法 JSON → exit 1；不展开 `${VAR}` |
| `install-agent-pkg.sh` | `-f <FLAG> -t <target_agents_dir> [-s <root>] [-F]` | `-t` **必须已存在**（如 `<project>/.claude/agents`）；目标中多余文件保留 |
| `install-skill-pkg.sh` | `-f <FLAG> -t <target_skills_dir> [-s <root>] [-F]` | `-t` 不存在时自动创建；只复制含 `SKILL.md` 的子目录；占位包提示「此包尚无 skill」并正常结束；Codex 用 `<project>/.agents/skills` |

共同点：源不存在 / 目标不存在 → exit 1；`-h` exit 0；未知选项 exit 1。

### 1.6 `install.sh`（dot_claude/ 同步）

```
sh ./scripts/install.sh -l <user|project|local> -m <overwrite|append|ask> [-p <target_path>] [选项]
必选：-l user（→ ~/.claude，忽略 -p，自动创建）| project | local（-p 指定的 .claude 目录，须已存在）
      -m overwrite | append | ask（/dev/tty 逐个询问 [o]/[a]/[s]）
      已存在的 .json 在 overwrite/append 时一律跳过 [MANUAL-JSON]；skills/ 下已存在文件 append 时跳过 [SKIP-APPEND]
条件必选：-p（project/local）
可选：-e <名称|glob>（可重复）；-E <相对 dot_claude/ 的目录>（可重复）；
      -S project/local 也装 settings.json；-C 旧版残留移到 <target>/legacy-backup-<时间戳>/
默认：根 README.md 不装；旧版 CLAUDE.md、SubagentStop hook 只警告
```

- `-l user -m overwrite` 会覆盖 `~/.claude/CLAUDE.md`（本机有 Homebrew、curl、`@RTK.md` 等专属规则，须先手动合并）。
- 属于「个人用户级」配置，不是项目场景配置；项目设定应用 `install-settings.sh`。

### 1.7 `check-gstack-overrides.sh`

`[-s <skills 目录>（默认 ~/.claude/skills）] [-f <settings 文件>（默认 ~/.claude/settings.json）]`；只读；退出码 0 一致或未装 gstack / 1 有未覆盖或失效项 / 2 参数或文件错误；需 python3。

### 1.8 `multi_client_support/codex.sh`

`[-d] [-F]`；目标 `${CODEX_HOME:-$HOME/.codex}/AGENTS.md`（目录不存在自动创建）。不存在 → 创建；无区块 → 备份后末尾追加；区块相同 → `[UNCHANGED]`；不同 → 备份后替换；区块外内容保留；区块损坏未加 `-F` → exit 1。已移除 `-l -p -n -v`（传入会报错）。`-d` 实测：打印 `[DRY-RUN] CREATED …/AGENTS.md，区块内容：` + 模板全文，未创建目录。

---

## 2. 配置单元

### 2.1 场景 FLAG × 维度

| 维度（目录 / 脚本） | prd-design | frontend-dev | backend-dev | dev-ops | fullstack-dev |
|---|---|---|---|---|---|
| 场景包 `dot_claude_projects/.claude-<FLAG>/`（`install-claude-project.sh`） | ✅ 9 个文件 | ✅ 8 | ✅ 50 | ✅ 23 | ❌ |
| `settings/settings.project-<FLAG>.json` | ✅ | ✅ | ✅（含 permissions.deny、go-fmt hook） | ✅（含 permissions.ask） | ✅（前端+后端去重，含 deny） |
| `settings/settings.local-<FLAG>.json` | ✅ | ✅ | ✅ | ✅ | ❌ |
| `claude_mds/CLAUDE-<FLAG>.md` | ✅ | ✅ | ✅ | ✅ | ❌ |
| `dot_mcp_jsons/dot-mcp-json-<FLAG>.json` | 空（跳过） | 空（跳过） | mysql、postgres、glitchtip | glitchtip | ❌ |
| `agents/agents-<FLAG>/` | 6 | 5 | 6 | 5 | ❌ |
| `skills/skills-<FLAG>/` | 占位（`.gitkeep`） | 占位（只 README） | 7 个 skill | `middleware-ops` | ❌ |
| 支持包清单（仅场景包内） | pm-skills（5 个插件） | gsd-core；注释：OpenSpec、codegraph | codegraph、OpenSpec；注释：gsd-core | 无主场景；注释：pm-ai-shipping | — |
| rules/、hooks/（仅场景包内） | — | — | rules（go、framework、database、redis、mq、rpc 共 16 文件）、`hooks/go-fmt.sh` | — | — |

文件数来自 `-d` 实测的 `[DRY-RUN] copy` 行数。

各场景包内容概述（据 `dot_claude_projects/README.md` 与清单）：

| FLAG | 场景 | 场景插件（`enabledPlugins`） | 需手动 `claude plugin install … --scope project` |
|---|---|---|---|
| prd-design | PRD 与原型 | playground、document-skills@anthropic-agent-skills、mattpocock-skills | mattpocock-skills；pm-skills 由支持包装 |
| frontend-dev | 前端 | typescript-native-lsp、frontend-design、playwright、chrome-devtools-mcp、modern-web-guidance、playground、pr-review-toolkit、sentry | chrome-devtools-mcp、modern-web-guidance、sentry、typescript-native-lsp（是否自动加载未验证） |
| backend-dev | 后端（Go 参考实现） | gopls-lsp、postman、mongodb、redis-development、semgrep、pr-review-toolkit、mattpocock-skills | postman、mongodb、redis-development、semgrep、mattpocock-skills；另需 `go install …gopls@latest` |
| dev-ops | DevOps | terraform、semgrep、sonatype-guide、pr-review-toolkit | semgrep、sonatype-guide |

backend-dev skills：`go-new-module`、`db-schema-design`、`cache-design`、`mq-design`、`rpc-design`、`system-design-doc`、`go-perf-diagnose`。

### 2.2 其他 FLAG / 包

| 位置 | 内容 | 安装方式 |
|---|---|---|
| `skills/skills-open-supports/` | `open-supports-install` skill | `install-skill-pkg.sh -f open-supports -t …/skills` |
| `skills/skills-github-ops/` | `github-release` | `install-skill-pkg.sh -f github-ops` |
| `skills/skills-codex-repair/` | `npm-codex-enotempty-repair` | `install-skill-pkg.sh -f codex-repair` |
| `agents/agents-agency-agent-based-dev/` | 48 个 agent 原始池（场景 agent 挑选自此，文件名带 `engineering-` 等前缀） | `install-agent-pkg.sh -f agency-agent-based-dev`（可行，但仓库未推荐整包装） |
| 模板（不应安装） | `agents-FLAG-NAME`、`skills-NAME-FLAG`、`CLAUDE-FLAG-NAME.md`（空）、`dot-mcp-json-FLAG-NAME.json`（空）、`.claude-FLAG-NAME_template/` | 实测 `-f FLAG-NAME_template -d` 能通过校验并计划复制清单（其余为空文件跳过）——skill 应把 `FLAG-NAME*`/`NAME-FLAG` 从候选里排除 |

### 2.3 全局单元

| 单元 | 内容 | 安装 |
|---|---|---|
| `dot_claude_projects/.claude/open_supports_name_list.txt` | gstack、task-master `--global` | `install-claude-project.sh -g`（先 `-d`） |
| `settings/settings.user.json` | 15 个全局插件、permissions、sandbox、hooks（rtk、myhandoff、zshrc）、`skillOverrides`（gstack 64 项） | 只同步 gstack 分层：`install-settings.sh -l user -m merge -K skillOverrides`（`-g` 第 2 步即此）；完整：`-l user -m overwrite`（README 要求先与本机比对） |
| `dot_claude/` | 繁中个人 `CLAUDE.md`、`commands/analyze-github-repo.md`、`skills/myhandoff/`、`settings.json`（本机镜像） | `install.sh -l user …` |
| Codex 用户级 | `multi_client_support/templates/AGENTS.codex-user.md` | `codex.sh`（先 `-d`） |

---

## 3. 与自动化相关的注意事项

| # | 注意事项 | 来源 |
|---|---|---|
| 1 | **用户约束**：不改本机配置（`~/.claude`、`~/.codex`），除非用户明确指令；改动前先确认；测试一律在临时目录 | HANDOFF「用户约束」 |
| 2 | 整包安装首选 `install-claude-project.sh`，它内建「先 settings、后支持包」顺序 | dot_claude_projects/README |
| 3 | 单独 `install-settings.sh -m overwrite` 重装 settings 会冲掉 pm-skills 写入的条目 → 之后重跑 `install-open-supports.sh -t <project>`，或用 `-m merge` | HANDOFF、settings/README |
| 4 | 含 permissions 的模板（backend-dev、dev-ops、fullstack-dev）**必须 overwrite**；merge 只合并 `enabledPlugins`/`extraKnownMarketplaces`/`skillOverrides` | 同上、`-h` |
| 5 | `-m ask`（install-settings、install.sh）需要 `/dev/tty`，Claude 的 Bash 工具中会失败 | scripts/README |
| 6 | 场景包与各维度目录**分开维护**，内容可能不同；混用整包与单维度脚本时以哪个为准需告知用户 | HANDOFF |
| 7 | 插件在项目 settings 中启用 ≠ 已安装：外部来源插件需手动 `claude plugin install <id> --scope project`（清单见 §2.1），然后 `/reload-plugins`、`/plugin` 检查 Errors 页；场景包 README 提供一键恢复命令 | 场景包 README |
| 8 | MCP 需在启动 `claude` 前设置环境变量：`MYSQL_HOST/PORT/DATABASE/USER/PASSWORD`、`POSTGRES_*`、`GLITCHTIP_URL`；首次打开项目需确认启用；只用其中一种数据库时删除另一个条目 | dot_mcp_jsons/README、backend README |
| 9 | 数据库 MCP `execute_sql` 可写，settings deny 拦不到 MCP → 只读账号、只连开发/测试库 | HANDOFF |
| 10 | backend-dev settings 的 PostToolUse hook 指向 `${CLAUDE_PROJECT_DIR}/.claude/hooks/go-fmt.sh`，该脚本**只在场景包中**；单独装 settings 模板会缺脚本 | settings/README |
| 11 | backend-dev 装好后应按技术栈删减 `rules/framework/`、不用的存储/中间件 rules、`rules/rpc/` | dot_claude_projects/README |
| 12 | OpenSpec 与 gsd-core 同一项目只启用一套；切换需编辑**项目上的**清单（注释/取消注释）后重跑 `install-open-supports.sh -t` | 清单注释、INDEX.md |
| 13 | OpenSpec 支持包会 `npm install -g`；codegraph 会 `curl \| sh` 装 CLI；均为项目外副作用 | 支持包脚本 |
| 14 | codegraph 装好后需在项目执行 `codegraph init` | 清单注释 |
| 15 | `-g` 修改 `~/.claude/settings.json` 的 `skillOverrides`（`-k` 跳过）；不用整份 merge 是因为本机插件可能来自其他市场，会重复启用同名插件 | settings/README |
| 16 | dev-ops 的 `permissions.ask` 会被全局 `deny`（docker rm、volume rm 等）先拦截 | settings/README |
| 17 | 本地级模板插件默认 `false`，需要时手动改 `true`；`settings.local*` 应加入 `.gitignore` | settings/README |
| 18 | 自定义场景：复制场景包为新 FLAG 即可用 `install-claude-project.sh -f <新FLAG>` 安装（需写入本仓库，属于改仓库） | dot_claude_projects/README |
| 19 | zsh 下 `for x in dir/*` 无匹配会中断；批处理用 `sh` 或先 `setopt nullglob` | HANDOFF |
| 20 | 预演副作用：`-d` 期间 macOS 系统 python3 在 `$HOME/Library/Caches/com.apple.python/` 写入 `.pyc` 缓存（实测于临时 HOME）；目标项目目录无任何写入 | 本次实测 |

---

## 4. 已有相关 skill 与约定

### 4.1 frontmatter

| 位置 | name | description（节选） | 其他字段 | 语言 |
|---|---|---|---|---|
| `skills/skills-open-supports/open-supports-install/SKILL.md`（79 行） | `open-supports-install` | Install or update open_supports packages for a project (-t) or user-wide (-g), one package (-n) or from a list, by using scripts/install-open-supports.sh. | `argument-hint` | 英文 |
| `dot_claude/skills/myhandoff/SKILL.md`（201 行，含 `scripts/`、`templates/`、`README.md`） | `myhandoff` | 保存或恢復專案進度交接… 觸發詞列表… 不屬本技能的情況 | `version: 2.2.0`、`allowed-tools` | 繁中 |
| `skills/skills-github-ops/github-release` | `github-release` | Publish a GitHub release using gh CLI… | `argument-hint` | 英文 |
| `skills/skills-codex-repair/npm-codex-enotempty-repair` | `npm-codex-enotempty-repair` | Fix npm global install failures for @openai/codex… | `argument-hint` | 英文 |
| 场景 skill（backend-dev 7 个、dev-ops 1 个） | 如 `db-schema-design` | 「做什么 + 用户说「…」时使用 + 什么情况不使用」 | — | 简中 |
| `open_supports/.copilot-skills/ost-*`（5 个） | `ost-support-workflow` 等 | 编写/维护支持包本身 | — | 英文 |
| `open_supports/ost_*/skill_for_setup/*_install`（10 个） | 如 `ost-garrytan-gstack-install` | 单个支持包的安装；项目级安装时作为 wrapper Skill 复制到项目 | — | 中/英 |

`open-supports-install` 结构：Pre-read（读项目清单、`open_supports/README.md`）→ Procedure（各模式命令；全局「先 `--dry-run` 并询问」）→ Reporting（按汇总计数报告 + 下一步命令）。可直接借鉴。

### 4.2 触发冲突

- 新 skill 与 `open-supports-install` 重叠在「安装支持包」；与 `ost-*-install`（被 wrapper 进项目后）重叠在「安装 gstack / OpenSpec …」。建议新 skill description 明确「本仓库的场景配置 / 配置包安装；只装单个支持包时用 open-supports-install」。
- 本机已启用的 `claude-code-setup:claude-automation-recommender`（「how to first set up Claude Code for a project」）与 `update-config`（settings.json 修改）有语义邻近，description 应以「本仓库」「场景包」「FLAG 名」为强锚点。
- 新 skill 不会自动触发 gstack（已 `user-invocable-only`）。

### 4.3 放置位置（按仓库约定推断）

| 选项 | 依据 | 优缺点 |
|---|---|---|
| `skills/skills-<新FLAG>/<skill>/`（如 `skills-config-install` 或并入 `skills-open-supports`） | `AGENTS.md`：skill 包放 `skills/skills-<FLAG>/`；`skills/README.md`「其他技能包」表收录非场景包 | 用 `install-skill-pkg.sh` 安装；语言为简中（`dot_claude/` 之外）。并入 `skills-open-supports` 最贴近现有「安装器包装」先例 |
| `dot_claude/skills/<skill>/` | myhandoff 先例；`install.sh -l user` 安装到 `~/.claude/skills/` 全局可用 | 须**繁体中文**；属个人用户级配置；仓库路径需在 skill 内定位（myhandoff 不依赖仓库） |
| 仓库内 `.claude/skills/` | 仓库根 `.claude/` 已入库 `settings.json`（`claudeMdExcludes`） | 只在本仓库为 cwd 时可用；约定文档未提及此位置（未验证是否符合作者意图） |

共同问题：脚本须从仓库根执行，skill 需要得到仓库绝对路径（`open-supports-install` 写作 "Run from the rule source repository"，未给定位方法）。新 skill 加入后需更新 `skills/README.md`（或 `dot_claude/README.md`）、HANDOFF 变更日志；若写测试，命名 `scripts/tests/test-<对象>.sh`。

### 4.4 语言约定

与用户沟通繁中；`dot_claude/` 与 Codex 模板繁中；其他仓库文档简中（HANDOFF「语言」）。配置中不得含未验证结论（未验证项只进 `docs/plans/`）。

---

## 5. 预演输出样例（实测）

命令（临时 HOME，空项目目录）：`sh scripts/install-claude-project.sh -f backend-dev -t <P> -d` → exit 0，66 行，项目目录无写入。

```
[DRY-RUN] copy .claude/settings.json -> <P>/.claude/settings.json
[DRY-RUN] copy .claude/open_supports_name_list.txt -> <P>/.claude/open_supports_name_list.txt
[DRY-RUN] copy .claude/agents/software-architect.md -> <P>/.claude/agents/software-architect.md
…（agents 6、hooks/go-fmt.sh、rules 16、skills 7 个含 references，共 50 条 copy）
[DRY-RUN] copy .mcp.json -> <P>/.mcp.json
[DRY-RUN] copy CLAUDE.md -> <P>/CLAUDE.md

复制完成。copied=0  forced=0  manual=0  empty=0  invalid=0

==> 安装支持包：<REPO>/dot_claude_projects/.claude-backend-dev/.claude/open_supports_name_list.txt

==> ost_colbymchenry_codegraph --target=claude --location=local {PROJECT_DIR}
[DRY-RUN] vendor <REPO>/open_supports/ost_colbymchenry_codegraph -> <P>/.claude/open_supports/ost_colbymchenry_codegraph
[DRY-RUN] generate wrapper Skill: <P>/.claude/skills/ost_colbymchenry_codegraph_install/SKILL.md
[DRY-RUN] run <P>/.claude/open_supports/ost_colbymchenry_codegraph/scripts_for_install/install.sh --target=claude --location=local <P>

==> ost_Fission-AI_OpenSpec --init-project --tools=claude {PROJECT_DIR}
[DRY-RUN] vendor … ; generate wrapper Skill … ; run …/install.sh --init-project --tools=claude <P>

完成。mode=project total=2 vendored=0 reused=0 stale=0 skill_generated=0 skill_reused=0 script_ok=0 missing=0 no_script=0 failed=0 conflict=0
```

冲突样例（目标已有 `CLAUDE.md`，`-f frontend-dev -d -N`）：

```
[MANUAL] 文件已存在，请手动处理：<P>/CLAUDE.md
复制完成。copied=0  forced=0  manual=1  empty=0  invalid=0
标记为 [MANUAL] 的文件已跳过。请删除或重命名后重新运行；或使用 -F 强制覆盖（会先备份）。
已指定 -N，跳过支持包安装。
```
（exit 0——skill 需要自己解析 `manual=` 计数来提示用户。）

全局 `sh scripts/install-claude-project.sh -g -d`（临时 HOME）→ exit 0，除 python `.pyc` 缓存外无写入：

```
[GLOBAL] 第 1/3 步：复制全局清单 .claude/open_supports_name_list.txt 到 <HOME>/.claude/（已存在时保留，-F 先备份再覆盖）
[DRY-RUN] copy .claude/open_supports_name_list.txt -> <HOME>/.claude/open_supports_name_list.txt
复制完成。copied=0 …
==> [GLOBAL] 第 2/3 步：同步 skillOverrides（gstack 默认只手动调用）：settings/settings.user.json -> <HOME>/.claude/settings.json
[DRY-RUN] run <REPO>/scripts/install-settings.sh -l user -m merge -K skillOverrides（先备份，只合并 skillOverrides）
==> [GLOBAL] 第 3/3 步：安装全局支持包（gstack 安装后会只读检查 skillOverrides 覆盖情况）
==> 安装支持包：<REPO>/dot_claude_projects/.claude/open_supports_name_list.txt
[GLOBAL] 用户级安装：不复制支持包、不写入任何项目目录；安装脚本会修改 ~ 下的用户配置
==> [GLOBAL] ost_garrytan_gstack
[DRY-RUN] run <REPO>/open_supports/ost_garrytan_gstack/scripts_for_install/install.sh
==> [GLOBAL] ost_eyaltoledano_claude-task-master --global
[DRY-RUN] run <REPO>/open_supports/ost_eyaltoledano_claude-task-master/scripts_for_install/install.sh --global
完成。mode=global total=2 … failed=0 conflict=0
```

错误样例：`-f nope` → `错误：源配置包不存在：…/.claude-nope`（exit 1）；`-f fullstack-dev` 同样 exit 1；目标不存在 → `错误：目标目录不存在：…`（exit 1）。

---

## 未验证

- codegraph CLI 经 `curl | sh` 安装的具体路径。
- `typescript-native-lsp@anthropic-plugin-directory` 在项目启用后是否自动加载（场景包 README 已标未验证）。
- 第三方市场插件名（`pm-skills`、`anthropic-agent-skills`）的离线校验（HANDOFF 已知问题）。
- 新 skill 放在仓库根 `.claude/skills/` 是否符合作者意图。
- 未对 install-settings / claude-md / dot-mcp / agent / skill / install.sh 做真实写入测试（这些脚本无预演，按任务约束未执行）；其冲突行为来自 `-h`、源码和 `scripts/tests/` 说明。
