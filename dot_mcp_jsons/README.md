# Dot MCP JSONs

本目录存放按项目/场景分类的 MCP 配置文件，命名格式为 `dot-mcp-json-<FLAG>.json`，其中 `<FLAG>` 为**自定义标识**（如 `frontend-dev`、`backend-dev`）。

## 目录结构

```
dot_mcp_jsons/
  dot-mcp-json-frontend-dev.json   # 前端开发项目场景
  dot-mcp-json-FLAG-NAME.json      # 命名模板，复制后重命名
  README.md
```

## 使用方式

通过 `scripts/install-dot-mcp.sh` 将指定配置文件拷贝到目标项目目录（目标文件名固定为 `.mcp.json`）：

```sh
# 基本用法（复制为 .mcp.json，已存在则提示手动处理）
sh scripts/install-dot-mcp.sh -f frontend-dev -t /path/to/project

# 强制覆盖已存在的目标文件
sh scripts/install-dot-mcp.sh -f frontend-dev -t /path/to/project -F

# 指定来源目录（默认为本仓库 dot_mcp_jsons/ 目录）
sh scripts/install-dot-mcp.sh -f frontend-dev -t /path/to/project -s /custom/dot_mcp_jsons
```

## 新增配置文件

1. 在 `dot_mcp_jsons/` 下新建 `dot-mcp-json-<FLAG>.json` 文件
2. 用 `-f <FLAG>` 参数安装到目标项目
