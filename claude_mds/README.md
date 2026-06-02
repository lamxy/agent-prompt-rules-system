# Claude MDs

本目录存放按项目/场景分类的 CLAUDE 配置文件，命名格式为 `CLAUDE-<FLAG>.md`，其中 `<FLAG>` 为**自定义标识**（如 `project-frontend-dev`、`user-productivity`）。

## 目录结构

```
claude_mds/
  CLAUDE-project-frontend-dev.md   # 前端开发项目场景
  CLAUDE-project-backend-dev.md
  CLAUDE-project-fullstack-dev.md
  CLAUDE-project-product-collab.md
  CLAUDE-project-release-ops.md
  CLAUDE-user-productivity.md
  CLAUDE-local-frontend-dev.md
  CLAUDE-local-backend-dev.md
  CLAUDE-local-experimental.md
  CLAUDE-local-low-connectivity.md
  CLAUDE-NAME-FLAG.md              # 命名模板，复制后重命名
```

## 使用方式

通过 `scripts/install-claude-md.sh` 将指定配置文件拷贝到目标项目目录：

```sh
# 基本用法（复制为 CLAUDE.md，已存在则提示手动处理）
sh scripts/install-claude-md.sh -f project-frontend-dev -t /path/to/project

# 指定目标文件名（如 AGENTS.md、GEMINI.md）
sh scripts/install-claude-md.sh -f project-frontend-dev -t /path/to/project -n AGENTS.md

# 强制覆盖已存在的目标文件
sh scripts/install-claude-md.sh -f project-frontend-dev -t /path/to/project -F

# 指定来源目录（默认为本仓库 claude_mds/ 目录）
sh scripts/install-claude-md.sh -f project-frontend-dev -t /path/to/project -s /custom/claude_mds
```

## 新增配置文件

1. 在 `claude_mds/` 下新建 `CLAUDE-<FLAG>.md` 文件
2. 用 `-f <FLAG>` 参数安装到目标项目