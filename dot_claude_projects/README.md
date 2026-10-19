# Dot Claude Projects

本目录存放按场景分类的项目启动包，命名格式为 `.claude-<FLAG>/`。FLAG 与 `settings/`、`claude_mds/`、`dot_mcp_jsons/`、`agents/`、`skills/` 相同。

启动包只负责**声明该场景需要哪些 `open_supports` 支持包**（`.claude/open_supports_name_list.txt`）。清单只为 Claude Code 配置；Codex 由使用者自行运行 `open_supports/` 下的安装脚本。settings、`CLAUDE.md`、`.mcp.json` 各有专属目录与安装脚本，不在启动包里重复一份，避免两处内容不同步。

| 启动包 | 声明的支持包 |
|--------|-------------|
| `.claude-prd-design/` | pm-skills：以 `--scope project` 安装为本项目的 Claude Code 插件（PRD 常用的 5 个）；gstack 为全局工具 |
| `.claude-frontend-dev/` | codegraph（项目级）；OpenSpec、gsd-core 作为可选框架（注释状态） |
| `.claude-backend-dev/` | 同前端 |
| `.claude-dev-ops/` | 无专属支持包 |
| `.claude-FLAG-NAME_template/` | 命名模板与清单格式说明 |

全局工具（task-master、mattpocock-skills、cognee、gstack）不写进任何项目清单，安装方式见 [`open_supports/INDEX.md`](../open_supports/INDEX.md)「全局工具」。

**为什么 OpenSpec、gsd-core 默认注释**：两者与全局的 superpowers 一样，都规定了「规划 → 拆解 → 执行」流程。同一项目启用多套会产生互相矛盾的指令，所以不设默认框架，需要时在项目中取消注释其中一个再安装。

## 初始化一个场景项目

从仓库根目录依次执行（以 `backend-dev` 为例）：

```sh
P=/path/to/project
sh scripts/install-settings.sh -l project -s backend-dev -m overwrite -p "$P/.claude"
sh scripts/install-claude-md.sh -f backend-dev -t "$P"
sh scripts/install-dot-mcp.sh -f backend-dev -t "$P"
sh scripts/install-agent-pkg.sh -f backend-dev -t "$P/.claude/agents"
sh scripts/install-skill-pkg.sh -f backend-dev -t "$P/.claude/skills"
sh scripts/install-claude-project.sh -f backend-dev -t "$P"
sh scripts/install-open-supports.sh -t "$P" --dry-run   # 确认后去掉 --dry-run
```

空模板会被各脚本跳过；已存在的文件默认不覆盖，加 `-F` 时先备份。

顺序要求：settings 模板必须在 `install-open-supports.sh` 之前安装。PRD 场景的 pm-skills 会以 `--scope project` 写入 `.claude/settings.json`，之后若用 `-m overwrite` 重装 settings 模板会覆盖这些条目，需重新运行 `install-open-supports.sh`，或改用 `-m merge`。

## Open Supports 清单格式

```text
# <支持包名称> [安装参数...]
colbymchenry/codegraph --target=claude --location=local {PROJECT_DIR}
```

- 名称可写 `OwnerName/RepoName` 或 `ost_OwnerName_RepoName`
- 参数原样传给该支持包的 `scripts_for_install/install.*`
- `{PROJECT_DIR}` 会替换为目标项目的绝对路径。安装脚本在 vendor 后的支持包目录中运行，项目级安装必须带上它，否则默认目标 `.` 会指向支持包目录
- 只支持整行注释；参数值不能含空格

完整说明见 `.claude-FLAG-NAME_template/README-open_supports_name-list.md`。

## 新增场景

1. 复制 `.claude-FLAG-NAME_template/` 为 `.claude-<FLAG>/`，只保留 `.claude/open_supports_name_list.txt`
2. 按 [`open_supports/INDEX.md`](../open_supports/INDEX.md) 的「建议场景」挑选支持包；项目级安装带上 `{PROJECT_DIR}`
3. 在其他场景目录使用相同的 FLAG
