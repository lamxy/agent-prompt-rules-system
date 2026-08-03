# scripts/

此目录包含用于安装、同步和测试本仓库各类配置资产的 POSIX shell 脚本。

所有脚本均从**仓库根目录**执行。脚本遵循 POSIX `sh` 规范，使用 `set -eu`，不依赖 Bash 扩展语法。

---

## 脚本一览

### `install.sh` — 将 `dot_claude/` 同步到 `.claude/`

将整个 `dot_claude/` 源目录（规则、命令、hooks、基础 settings 等）同步到用户级或项目级的 `.claude/` 目录：

```sh
sh ./scripts/install.sh -l <user|project|local> [-p <target_path>] -m <overwrite|append|ask> [-e <file>] [-E <dir>]
```

| 选项 | 说明 |
|------|------|
| `-l user` | 同步到用户级默认路径 `~/.claude`（全局生效） |
| `-l project` | 同步到指定项目的 `.claude/` 目录（项目级共享） |
| `-l local` | 同步到本地个人覆盖目录 |
| `-m overwrite\|append\|ask` | 冲突处理模式 |
| `-e <pattern>` | 排除指定文件名或 glob 模式，可重复使用 |
| `-E <dir>` | 排除指定目录（相对于源 `dot_claude/` 根），可重复使用 |

```sh
# 同步到用户级，排除 audit_reports 目录和 CLAUDE.md 文件
sh ./scripts/install.sh -l user -m overwrite -E audit_reports -e CLAUDE.md

# 同步到项目级，排除 expandable 目录及所有 *-min.md 规约文件
sh ./scripts/install.sh -l project -p /path/to/project/.claude -m overwrite \
  -E expandable -e '*-min.md'
```

> `.json` 文件已存在时脚本自动跳过，需手动合并以保证 JSON 结构合法。

---

### `install-settings.sh` — 安装场景化 settings 模板

```sh
sh ./scripts/install-settings.sh -l <user|project|local> [-s <scenario>] [--src <source_settings_json>] -m <overwrite|merge|ask> [-p <target_dir>]
```

```sh
# 用户级默认（productivity）
sh ./scripts/install-settings.sh -l user -m overwrite

# 项目级前端场景
sh ./scripts/install-settings.sh -l project -s frontend-dev -m overwrite -p /path/to/project/.claude

# 本地弱网场景（融合到已有配置）
sh ./scripts/install-settings.sh -l local -s low-connectivity -m merge -p /path/to/project/.claude
```

可用场景见 `settings/README.md`。

---

### `install-agent-pkg.sh` — 安装 Agent 包

```sh
sh ./scripts/install-agent-pkg.sh -f <FLAG> -t /path/to/project/.claude/agents [-F]
```

将 `agents/agents-<FLAG>/` 下的 `*.md` 文件安装到目标项目的 agents 目录。`-F` 表示强制覆盖同名文件。

---

### `install-skill-pkg.sh` — 安装 Skill 包

```sh
sh ./scripts/install-skill-pkg.sh -f <FLAG> -t /path/to/project/.claude/skills [-F]
```

将 `skills/skills-<FLAG>/` 下的技能目录安装到目标项目的 skills 目录。

---

### `install-claude-md.sh` — 安装 CLAUDE.md 配置

```sh
sh ./scripts/install-claude-md.sh -f <FLAG> -t /path/to/project [-n CLAUDE.md] [-F]
```

将 `claude_mds/CLAUDE-<FLAG>.md` 复制为目标项目的 `CLAUDE.md`（或 `AGENTS.md`、`GEMINI.md` 等）。

---

### `install-dot-mcp.sh` — 安装 .mcp.json 配置

```sh
sh ./scripts/install-dot-mcp.sh -f <FLAG> -t /path/to/project [-F]
```

将 `dot_mcp_jsons/dot-mcp-json-<FLAG>.json` 复制为目标项目的 `.mcp.json`。

---

### `install-claude-project.sh` — 安装项目级完整配置包

```sh
sh ./scripts/install-claude-project.sh -f <FLAG> -t /path/to/project [-F]
```

将 `dot_claude_projects/.claude-<FLAG>/` 下的 `.claude/`、`.mcp.json`、`CLAUDE.md` 一次性复制到目标项目根目录，适合快速初始化新项目。

---

### `install-open-supports.sh` — 安装项目声明的 open_supports 支持包

```sh
sh ./scripts/install-open-supports.sh -t /path/to/project [--dry-run] [--skills-only] [--no-skills] [-F]
```

读取目标项目 `.claude/open_supports_name_list.txt` 中声明的支持包并执行安装。  
详细说明见 `open_supports/README.md`。

---

### `test-install-open-supports.sh` — open_supports 安装器回归测试

```sh
sh ./scripts/test-install-open-supports.sh
```

对 `install-open-supports.sh` 执行回归测试，使用临时目录，不影响真实配置。

---

### `test-multi-client-codex.sh` — Codex 适配器测试

```sh
sh ./scripts/test-multi-client-codex.sh
```

对 `multi_client_support/codex.sh` 执行语法检查与 smoke test。

---

## 子目录

### `multi_client_support/`

包含面向 Claude Code 以外客户端的适配器脚本。目前实现了 Codex 第一阶段适配器（`codex.sh`）。  
详细说明见 `multi_client_support/README.md`。

---

## 修改脚本前

变更任何脚本前，先运行语法检查：

```sh
sh -n scripts/*.sh
```
