# Agents

本目录存放按项目/场景分组的 agent 包。每个 agent 包是一个以 `agents-<FLAG>` 命名的目录，包含该场景所需的 agent 定义文件（`*.md`）。

## 场景 agent 包

项目场景与 `claude_mds/`、`settings/`、`skills/`、`dot_mcp_jsons/` 使用相同的 FLAG：

| FLAG | 场景 | 包含的 agent |
|------|------|-------------|
| `prd-design` | PRD 与原型设计 | product-manager、feedback-synthesizer、sprint-prioritizer、trend-researcher、ux-researcher、ux-architect |
| `frontend-dev` | 前端开发 | frontend-developer、ui-designer、accessibility-auditor、performance-benchmarker、api-tester |
| `backend-dev` | 后端开发 | backend-architect、software-architect、database-optimizer、api-tester、security-engineer、technical-writer |
| `dev-ops` | DevOps | devops-automator、sre、incident-response-commander、security-engineer、git-workflow-master |

四个场景包都挑选自 `agents-agency-agent-based-dev/`，正文未改动，只做了两处调整：

- 文件名去掉 `engineering-`、`design-`、`testing-`、`product-` 前缀
- frontmatter 的 `name` 从显示名（如 `SRE (Site Reliability Engineer)`）改为与文件名一致的小写连字符形式（如 `sre`），符合 Claude Code 的 agent 命名格式

上游更新时，重新从 `agents-agency-agent-based-dev/` 复制并做同样的调整。

## 其他 agent 包

| 目录 | 内容 |
|------|------|
| `agents-agency-agent-based-dev/` | 来自 msitarzewski/agency-agents 的设计、工程、产品、测试类 agent（约 50 个） |

需要其他 agent 时，从 `agents-agency-agent-based-dev/` 挑选复制到对应的场景包（按上面的方式调整文件名与 `name`），不必整包安装。

## 目录结构

```
agents/
  agents-prd-design/
  agents-frontend-dev/
  agents-backend-dev/
  agents-dev-ops/
    sre.md
  agents-agency-agent-based-dev/
  agents-FLAG-NAME/      # 命名模板，复制后重命名
```

## 使用方式

通过 `scripts/install-agent-pkg.sh` 将指定 agent 包中的 `*.md` 文件拷贝到目标项目的 agent 目录。

```sh
# 基本用法（同名文件提示手动处理，其他直接拷贝）
sh scripts/install-agent-pkg.sh -f frontend-dev -t /path/to/project/.claude/agents

# 强制覆盖（旧文件先移到 <target>.backup-<时间戳>/）
sh scripts/install-agent-pkg.sh -f frontend-dev -t /path/to/project/.claude/agents -F

# 指定 agent 包来源目录（默认为本仓库 agents/ 目录）
sh scripts/install-agent-pkg.sh -f frontend-dev -t /path/to/project/.claude/agents -s /custom/agents/root
```

## 新增 agent 包

1. 在 `agents/` 下新建 `agents-<FLAG>/` 目录；新场景请同步在 `claude_mds/`、`settings/`、`skills/`、`dot_mcp_jsons/` 使用相同的 FLAG
2. 在其中放置 agent 定义 `*.md` 文件（frontmatter 含 `name`、`description`，可用 `model:` 指定模型）
3. 不要在 agent 包内放 `README.md`：安装脚本会复制包内所有 `*.md`，README 会被当成 agent 安装
4. 用 `-f <FLAG>` 参数安装到目标项目
