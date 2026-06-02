# Dot Claude Projects

本目录存放按项目/场景分类的项目级指令模板目录，命名格式为 `.claude-<FLAG>/`，其中 `<FLAG>` 为**自定义标识**（如 `frontend-dev`）。

每个模板目录包含完整的项目级配置：

```
.claude-<FLAG>/
  .claude/       # Claude 项目级配置目录
  .mcp.json      # MCP 工具配置
  CLAUDE.md      # 项目级 Claude 指令文件
```

## 目录结构

```
dot_claude_projects/
  .claude-frontend-dev/    # 前端开发项目场景
    .claude/
    .mcp.json
    CLAUDE.md
  .claude-FLAG-NAME/       # 命名模板，复制后重命名
  README.md
```

## 使用方式

通过 `scripts/install-claude-project.sh` 将指定模板目录中的所有文件拷贝到目标项目根目录：

```sh
# 基本用法（已存在则提示手动处理）
sh scripts/install-claude-project.sh -f frontend-dev -t /path/to/project

# 强制覆盖已存在的文件/目录
sh scripts/install-claude-project.sh -f frontend-dev -t /path/to/project -F

# 指定来源目录（默认为本仓库 dot_claude_projects/ 目录）
sh scripts/install-claude-project.sh -f frontend-dev -t /path/to/project -s /custom/dot_claude_projects
```

## 新增模板

1. 在 `dot_claude_projects/` 下新建 `.claude-<FLAG>/` 目录
2. 在其中放入 `.claude/`、`.mcp.json`、`CLAUDE.md`
3. 用 `-f <FLAG>` 参数安装到目标项目
