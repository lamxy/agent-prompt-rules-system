# Dot Claude Projects

本目录存放可一次安装的配置包，由 `scripts/install-claude-project.sh` 分发：

- **场景包** `.claude-<FLAG>/`：一个场景的完整项目配置，安装到项目根目录。FLAG 与 `settings/`、`claude_mds/`、`dot_mcp_jsons/`、`agents/`、`skills/` 相同。
- **全局包** `.claude/`：没有场景标识，只含全局支持包清单，安装到 `~/.claude/`。

| 配置包 | 内容 | 安装到 |
|--------|------|--------|
| `.claude/` | `open_supports_name_list.txt`：gstack、task-master（用户级） | `~/.claude/` |
| `.claude-prd-design/` | settings、`CLAUDE.md`、6 个 agent；清单：pm-skills 以 `--scope project` 安装为项目插件 | 项目根目录 |
| `.claude-frontend-dev/` | settings、`CLAUDE.md`、5 个 agent；清单：codegraph（项目级），OpenSpec、gsd-core 为可选框架（注释状态） | 项目根目录 |
| `.claude-backend-dev/` | settings、`CLAUDE.md`、`.mcp.json`（MySQL、PostgreSQL）、6 个 agent；清单同前端 | 项目根目录 |
| `.claude-dev-ops/` | settings、`CLAUDE.md`、`.mcp.json`（Kubernetes 只读）、5 个 agent；清单无专属支持包 | 项目根目录 |
| `.claude-FLAG-NAME_template/` | 命名模板与清单格式说明 | — |

## 场景包与各维度目录的关系

场景包是各维度配置的**完整聚合**，初次由以下来源复制而来，之后**与来源目录分开维护**，不自动同步：

| 场景包中的文件 | 初始来源 | 单独安装该维度 |
|---------------|---------|---------------|
| `.claude/settings.json` | `settings/settings.project-<FLAG>.json` | `install-settings.sh -l project -s <FLAG>` |
| `CLAUDE.md` | `claude_mds/CLAUDE-<FLAG>.md` | `install-claude-md.sh -f <FLAG>` |
| `.mcp.json` | `dot_mcp_jsons/dot-mcp-json-<FLAG>.json`（空模板不复制） | `install-dot-mcp.sh -f <FLAG>` |
| `.claude/agents/*.md` | `agents/agents-<FLAG>/` | `install-agent-pkg.sh -f <FLAG>` |
| `.claude/skills/<name>/` | `skills/skills-<FLAG>/` 中含 `SKILL.md` 的目录（目前四个场景都还没有） | `install-skill-pkg.sh -f <FLAG>` |
| `.claude/open_supports_name_list.txt` | 只存在于场景包 | `install-open-supports.sh -t <project>` |

两种方式都不会静默覆盖：目标文件已存在时默认跳过（`[MANUAL]`），加 `-F` 时先备份再覆盖。`settings.local.json`、本地级插件等个人设定不放进场景包。

## 安装一个场景项目

```sh
P=/path/to/project
sh scripts/install-claude-project.sh -f backend-dev -t "$P" -d   # 预演
sh scripts/install-claude-project.sh -f backend-dev -t "$P"
```

脚本先逐个文件复制场景包，再调用 `install-open-supports.sh -t "$P"` 按项目上的清单安装支持包。顺序已内建：`settings.json` 先于 pm-skills 写入，不会被覆盖。`-N` 只复制不安装支持包。

日后用 `-F` 重装场景包会覆盖 `.claude/settings.json`（先备份），pm-skills 写入的条目随后由同一次运行的支持包安装重新写入。

## 安装全局支持包

```sh
sh scripts/install-claude-project.sh -g -d   # 预演
sh scripts/install-claude-project.sh -g
```

- 只把 `.claude/open_supports_name_list.txt` 复制到 `~/.claude/`；已存在时保留，`-F` 先备份为 `~/.claude/open_supports_name_list.txt.backup-<时间戳>`
- 再按 `~/.claude/` 上的清单调用 `install-open-supports.sh -g`：支持包不复制，直接在本仓库的 `open_supports/<ost>/` 中运行安装脚本
- 全局清单出现 `{PROJECT_DIR}`、`--local`、`--location=local` 时整份拒绝，不运行任何安装脚本
- mattpocock-skills 以插件形式在 `settings/settings.user.json` 启用，不在清单里

## Open Supports 清单格式

```text
# <支持包名称> [安装参数...]
colbymchenry/codegraph --target=claude --location=local {PROJECT_DIR}
```

- 名称可写 `OwnerName/RepoName` 或 `ost_OwnerName_RepoName`
- 参数原样传给该支持包的 `scripts_for_install/install.*`
- 项目清单：`{PROJECT_DIR}` 替换为项目绝对路径。安装脚本在复制后的支持包目录中运行，项目级安装必须带上它
- 全局清单：只放用户级条目
- 只支持整行注释；参数值不能含空格

完整说明见 `.claude-FLAG-NAME_template/README-open_supports_name-list.md`。

**为什么 OpenSpec、gsd-core 默认注释**：两者与全局的 superpowers 一样，都规定了「规划 → 拆解 → 执行」流程。同一项目启用多套会产生互相矛盾的指令，所以不设默认框架，需要时在项目中取消注释其中一个再安装。

## 新增场景

1. 复制 `.claude-FLAG-NAME_template/` 为 `.claude-<FLAG>/`
2. 从各维度目录复制同 FLAG 的配置（见上表），按 [`open_supports/INDEX.md`](../open_supports/INDEX.md) 的「建议场景」写清单；项目级安装带上 `{PROJECT_DIR}`
3. 在其他维度目录使用相同的 FLAG
