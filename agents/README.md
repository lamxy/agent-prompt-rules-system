# Agents

本目录存放按项目/场景分组的 agent 包。每个 agent 包是一个以 `agents-<FLAG>` 命名的目录，其中 `<FLAG>` 为自定义标识（如 `frontend-dev`、`experiment`），包含该场景所需的 agent 定义文件（`*.md`）。

## 目录结构

```
agents/
  agents-frontend-dev/   # 前端开发场景 agent 包（FLAG=frontend-dev）
    backend-agent.md
    review-agent.md
  agents-NAME-FLAG/      # 命名模板，复制后重命名
```

## 使用方式

通过 `scripts/install-agent-pkg.sh` 将指定 agent 包中的 `*.md` 文件拷贝到目标项目的 agent 目录：

```sh
# 基本用法（同名文件提示手动处理，其他直接拷贝）
sh scripts/install-agent-pkg.sh -f frontend-dev -t /path/to/project/.claude/agents

# 强制覆盖（删除同名文件后重新拷贝）
sh scripts/install-agent-pkg.sh -f frontend-dev -t /path/to/project/.claude/agents -F

# 指定 agent 包来源目录（默认为本仓库 agents/ 目录）
sh scripts/install-agent-pkg.sh -f frontend-dev -t /path/to/project/.claude/agents -s /custom/agents/root
```

## 新增 agent 包

1. 在 `agents/` 下新建 `agents-<FLAG>/` 目录
2. 在其中放置 agent 定义 `*.md` 文件
3. 用 `-f <FLAG>` 参数安装到目标项目
