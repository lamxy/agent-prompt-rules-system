# scripts/

此目录包含用于安装、同步和测试本仓库各类配置资产的 POSIX shell 脚本。

所有脚本均从**仓库根目录**执行。脚本遵循 POSIX `sh` 规范，使用 `set -eu`，不依赖 Bash 扩展语法。

每个脚本顶部注释说明功能与边界；`-h` 显示完整用法，选项按「必选」「条件必选」「可选」分组，并附带注释的示例列表。本文只列要点，参数以 `-h` 为准。

---

## 脚本一览

### `install.sh` — 将 `dot_claude/` 同步到 `.claude/`

将 `dot_claude/` 源目录（`CLAUDE.md`、`commands/`、个人用户级 `settings.json`）同步到用户级或项目级的 `.claude/` 目录。2026-10-19 起 `dot_claude/` 改为精简版，原分层规约系统备份在 `dot_claude_legacy/`，本脚本不再使用它；原因见 `dot_claude/README.md`。

```sh
sh ./scripts/install.sh -l <user|project|local> [-p <target_path>] -m <overwrite|append|ask> [-e <file>] [-E <dir>] [-S] [-C]
```

| 选项 | 说明 |
|------|------|
| `-l user` | 同步到用户级默认路径 `~/.claude`（全局生效） |
| `-l project` | 同步到指定项目的 `.claude/` 目录（项目级共享） |
| `-l local` | 同步到本地个人覆盖目录 |
| `-m overwrite\|append\|ask` | 冲突处理模式；`ask` 从终端读取回答 |
| `-e <pattern>` | 排除指定文件名或 glob 模式，可重复使用 |
| `-E <dir>` | 排除指定目录（相对于源 `dot_claude/` 根），可重复使用 |
| `-S` | 在 project/local 层级同时安装 `settings.json`（默认跳过） |
| `-C` | 将目标中检测到的旧版文件移至 `<target>/legacy-backup-<时间戳>/` |

默认行为：

- **不安装 `README.md`**：它是本仓库的说明文件。
- **project/local 层级不安装 `settings.json`**：它是个人用户级设定（含 `autoMode`、`skillOverrides`，以及依赖本机 `myhandoff`、`rtk` 的 hooks）。项目级设定请用 `install-settings.sh`；确实需要时加 `-S`。
- **检测旧版残留**：目标若装过旧版（`rules/` 下的 `*-min.md`、`expandable/`、`hooks/subagent_stop_gate.py`、`commands/auditrules.md` 等），会以 `[LEGACY]` 列出。`rules/` 下没有 `paths` 的规则每次启动都会载入，会与新版冲突。默认只警告不移动；加 `-C` 才移至备份目录，不会删除。`RTK.md` 由 rtk 自行生成，不视为旧版。
- **旧版内容提示**：目标的 `CLAUDE.md` 仍是旧版内容，或 `settings.json` 仍注册 `subagent_stop_gate.py` 时，以 `[LEGACY-WARN]` 提示手动处理，脚本不修改这两个文件。

```sh
# 同步到用户级（已有个人 CLAUDE.md 时先手动合并，或用 -e CLAUDE.md 排除）
sh ./scripts/install.sh -l user -m ask

# 同步到项目级，并把旧版残留移至备份目录
sh ./scripts/install.sh -l project -p /path/to/project/.claude -m overwrite -C
```

> `.json` 文件已存在时脚本自动跳过，需手动合并以保证 JSON 结构合法。

---

### `install-settings.sh` — 安装场景化 settings 模板

```sh
sh ./scripts/install-settings.sh -l <user|project|local> [-s <scenario>] [--src <source_settings_json>] -m <overwrite|merge|ask> [-p <target_dir>]
```

```sh
# 用户级（settings.user.json，本机个人设定副本）
sh ./scripts/install-settings.sh -l user -m overwrite

# 项目级前端场景
sh ./scripts/install-settings.sh -l project -s frontend-dev -m overwrite -p /path/to/project/.claude

# 本地前端覆盖（融合到已有配置）
sh ./scripts/install-settings.sh -l local -s frontend-dev -m merge -p /path/to/project/.claude
```

可用场景见 `settings/README.md`；`-s` 写错或漏写时，脚本会列出该作用域可用的场景名。

- **备份**：覆盖或合并前把目标备份为 `settings.json.bak.<时间戳>`；同一秒内多次执行会加序号，不会覆盖先前的备份。
- **merge 范围**：只合并 `enabledPlugins` 和 `extraKnownMarketplaces`。源文件中的其他字段（如 `settings.user.json` 的 `permissions`、`hooks`、`sandbox`）不会写入，脚本以 `[WARN]` 列出；安装完整的用户级设定请用 `overwrite`。
- **ask 模式**：从终端（`/dev/tty`）读取回答；非交互环境会报错退出，请改用 `overwrite` 或 `merge`。

---

### `install-agent-pkg.sh` — 安装 Agent 包

```sh
sh ./scripts/install-agent-pkg.sh -f <FLAG> -t /path/to/project/.claude/agents [-F]
```

将 `agents/agents-<FLAG>/` 下的 `*.md` 文件安装到目标项目的 agents 目录。`-F` 表示强制覆盖同名文件，旧文件先移到与目标同级的 `<target>.backup-<时间戳>/`（不放在目标目录内，以免被当成 agent 载入）。

---

### `install-skill-pkg.sh` — 安装 Skill 包

```sh
sh ./scripts/install-skill-pkg.sh -f <FLAG> -t /path/to/project/.claude/skills [-F]
```

将 `skills/skills-<FLAG>/` 下的技能目录安装到目标项目的 skills 目录。

- 只安装含 `SKILL.md` 的子目录，其他子目录以 `[WARN]` 跳过；包内的 `README.md`、`.gitkeep` 不会被安装
- 目标目录不存在时自动创建
- `-F` 先把同名 skill 目录移到与目标同级的 `<target>.backup-<时间戳>/`，再重新复制，不直接删除
- 占位包（只有 `.gitkeep`）会提示「此包尚无 skill」

---

### `install-claude-md.sh` — 安装 CLAUDE.md 配置

```sh
sh ./scripts/install-claude-md.sh -f <FLAG> -t /path/to/project [-n CLAUDE.md] [-F]
```

将 `claude_mds/CLAUDE-<FLAG>.md` 复制为目标项目的 `CLAUDE.md`（或 `AGENTS.md`、`GEMINI.md` 等）。模板为空文件时跳过；`-F` 覆盖前先备份为 `<文件>.bak.<时间戳>`。

---

### `install-dot-mcp.sh` — 安装 .mcp.json 配置

```sh
sh ./scripts/install-dot-mcp.sh -f <FLAG> -t /path/to/project [-F]
```

将 `dot_mcp_jsons/dot-mcp-json-<FLAG>.json` 复制为目标项目的 `.mcp.json`。模板为空文件时跳过，不是合法 JSON 时报错；`-F` 覆盖前先备份为 `.mcp.json.bak.<时间戳>`。

---

### `install-claude-project.sh` — 分发 `dot_claude_projects/` 的配置包

```sh
sh ./scripts/install-claude-project.sh -f <FLAG> -t /path/to/project [-F] [-N] [-d]   # 项目级
sh ./scripts/install-claude-project.sh -g [-F] [-N] [-d]                              # 全局
```

负责**复制配置**，复制后调用 `install-open-supports.sh` 安装清单中的支持包。

- 项目级：把场景包 `.claude-<FLAG>/` 的 `.claude/`、`.mcp.json`、`CLAUDE.md` 逐个文件复制到项目根目录；场景包是 settings、`CLAUDE.md`、`.mcp.json`、agents、skills 的完整聚合
- 全局：只把 `dot_claude_projects/.claude/open_supports_name_list.txt` 复制到 `~/.claude/`，再以 `-g` 安装全局支持包
- 目标文件已存在时标记 `[MANUAL]` 跳过，支持包仍按目标上的清单安装；`-F` 先备份（项目级到 `<project>/.claude-project-backup-<时间戳>/`，全局为清单旁的 `.backup-<时间戳>`）
- `-N` 只复制不安装；`-d` 预演，不写入任何文件；`-o` 指定 open_supports 根目录
- 空文件、`.gitkeep` 与不合法的 JSON 会被跳过

---

### `install-open-supports.sh` — 安装 `open_supports/` 支持包

```sh
sh ./scripts/install-open-supports.sh -t /path/to/project [-n <支持包> [-- 参数...] | -l <清单>] [--dry-run] [--skills-only] [--no-skills] [-F]
sh ./scripts/install-open-supports.sh -g [-n <支持包> [-- 参数...] | -l <清单>] [--dry-run]
```

负责**安装支持包**：用 `-n` 安装单一支持包，或按清单批量安装；都不给时读默认清单（`-t` 为 `<project>/.claude/open_supports_name_list.txt`，`-g` 为 `~/.claude/open_supports_name_list.txt`）。

- 项目级（`-t`）：支持包复制到 `<project>/.claude/open_supports/<ost>/` 后运行安装脚本；`{PROJECT_DIR}` 替换为项目绝对路径；同一支持包可写多行，只复制一次
- 全局（`-g`）：不复制、不生成 wrapper Skill，直接在本仓库的支持包目录中运行安装脚本；清单含 `{PROJECT_DIR}`、`--local`、`--location=local` 时整份拒绝；不接受 `-F`、`--skills-only`
- 安装脚本保留调用端的 stdin，读取输入的脚本不会吞掉清单的后续行
- wrapper Skill（仅项目级，`.claude/skills/<ost_name>_install/`）记录该支持包的全部安装命令，带生成标记的每次按清单重新生成；`-n` 单独安装只在 Skill 不存在时创建
- 已安装的支持包与源不一致时提示 `[STALE]`；`-F` 替换前把旧的支持包与 wrapper Skill 备份到 `.claude/open_supports.backup-<时间戳>/`

详细说明见 `open_supports/README.md`。

---

### `tests/` — 安装脚本回归测试

所有测试集中在 `scripts/tests/`，一律使用临时目录与临时 `HOME`，不影响真实配置。一次跑完（含 `sh -n` 语法检查）：

```sh
sh ./scripts/tests/run-all.sh
```

| 测试 | 覆盖 |
|------|------|
| `test-install.sh` | `install.sh` 与 `codex.sh` 从 `dot_claude/` 取源；默认跳过 `README.md`、project 层级跳过 `settings.json`（`-S` 可安装）；`RTK.md` 不视为旧版；旧版残留只警告、`-C` 移至备份且保留用户文件；旧版 `CLAUDE.md` 与 hook 注册的提示 |
| `test-install-settings.sh` | 所有场景模板可安装；错误场景名列出可用场景；源文件名与作用域匹配；连续执行不丢备份；用户级 merge 列出未写入的字段；merge 保留非 ASCII 与四格缩进；ask 模式的读取与无终端报错 |
| `test-install-templates.sh` | `install-claude-md.sh`、`install-dot-mcp.sh`、`install-claude-project.sh`：路径含空格、参数不被执行、空模板跳过、不合法 JSON、`-F` 备份、`-n` 拒绝路径、项目 `-F` 保留无关文件；四个场景包安装 settings、`CLAUDE.md`、agents 与清单，项目级条目都带 `{PROJECT_DIR}`；复制后按目标清单安装支持包、`-N` 不安装、`-d` 不写入；`-g` 只复制清单到 `~/.claude/` 并全局安装 |
| `test-install-pkg.sh` | `install-skill-pkg.sh` 自动创建目标、跳过缺少 `SKILL.md` 的目录与 `README.md`、占位包提示、冲突处理与 `-F` 备份；`install-agent-pkg.sh` 的 `-F` 备份 |
| `test-install-open-supports.sh` | `install-open-supports.sh`：vendor、wrapper Skill（记录全部命令、按清单重新生成、保留手动维护版本）、安装脚本执行、`{PROJECT_DIR}` 替换、安装脚本读 stdin 不吞清单、`[STALE]` 提示、`-F` 备份、不安全的支持包名称、冲突；`-n` 单一安装、`-t`/`-g` 与 `-n`/`-l` 互斥、`-g` 不复制且拒绝项目级条目、项目清单中用户级条目的警告 |
| `test-settings-templates.sh` | `settings/*.json` 合法；启用插件引用的第三方市场已声明；插件名称存在于本机已缓存的市场目录（只读，未缓存的市场跳过） |
| `test-pm-skills-claude-scope.sh` | `ost_phuryn_pm-skills` 的 `--client=claude-code`：`--location=local` 在项目目录的子 shell 中以 `--scope project` 安装、默认保持用户级、未加 `--location=local` 时拒绝项目目录（以替身 `claude` 执行，不改动真实配置） |
| `test-open-supports-index.sh` | `open_supports/INDEX.md` 登记了每个支持包，且分类与各包 `repo_readme_summary.md` 的「模式 X」一致 |
| `test-open-support-install-scopes.sh` | 各 `open_supports` 安装脚本拒绝不存在的目标目录，且 `--help` 可用 |
| `test-multi-client-codex.sh` | `multi_client_support/codex.sh` 的 smoke test |

单独执行某个测试：`sh ./scripts/tests/test-install-settings.sh`。新增测试命名为 `test-<对象>.sh` 放在此目录，`run-all.sh` 会自动执行。

---

## 子目录

### `multi_client_support/`

包含面向 Claude Code 以外客户端的适配器脚本。目前实现了 Codex 第一阶段适配器（`codex.sh`）。  
详细说明见 `multi_client_support/README.md`。

---

## 修改脚本前

变更任何脚本前后，运行全部测试（含语法检查）：

```sh
sh ./scripts/tests/run-all.sh
```
