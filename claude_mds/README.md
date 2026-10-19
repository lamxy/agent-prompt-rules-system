# Claude MDs

本目录存放按项目场景分类的 CLAUDE 配置文件，命名格式为 `CLAUDE-<FLAG>.md`。

项目场景与 `settings/`、`agents/`、`dot_mcp_jsons/` 使用相同的 FLAG：

| FLAG | 场景 | 主要约定 |
|------|------|---------|
| `prd-design` | PRD 与原型设计 | PRD 与原型的存放位置、写之前先追问、PRD 必含 8 项（含埋点、灰度与 A/B、待定问题） |
| `frontend-dev` | 前端开发 | 以 API 契约为准不臆造字段、使用设计系统 token、完成前在浏览器验证三种宽度与无障碍基本项 |
| `backend-dev` | 后端开发 | 设计文档与 ADR 位置、契约先行、幂等与分页、MySQL/PostgreSQL/MongoDB 迁移与 Redis key 规范 |
| `dev-ops` | DevOps | 变更前先给 plan/diff、默认只操作非生产环境、上线附回滚方式、可观测性要求 |

每个文件约 30 行，只写与 Claude Code 默认行为不同的约定。工具由同 FLAG 的 `settings/` 模板启用；需要强制的边界（如破坏性数据库命令、`terraform apply`）写在 settings 的 `permissions` 中，不在 `CLAUDE.md` 重复。文档路径是建议值，项目已有约定时直接修改。

## 目录结构

```
claude_mds/
  CLAUDE-prd-design.md
  CLAUDE-frontend-dev.md
  CLAUDE-backend-dev.md
  CLAUDE-dev-ops.md
  CLAUDE-FLAG-NAME.md      # 命名模板，复制后重命名
```

## 使用方式

通过 `scripts/install-claude-md.sh` 将指定配置文件拷贝到目标项目目录：

```sh
# 基本用法（复制为 CLAUDE.md，已存在则提示手动处理）
sh scripts/install-claude-md.sh -f frontend-dev -t /path/to/project

# 指定目标文件名（如 AGENTS.md、GEMINI.md）
sh scripts/install-claude-md.sh -f frontend-dev -t /path/to/project -n AGENTS.md

# 强制覆盖已存在的目标文件（先备份为 CLAUDE.md.bak.<时间戳>）
sh scripts/install-claude-md.sh -f frontend-dev -t /path/to/project -F

# 指定来源目录（默认为本仓库 claude_mds/ 目录）
sh scripts/install-claude-md.sh -f frontend-dev -t /path/to/project -s /custom/claude_mds
```

## 新增配置文件

1. 复制 `CLAUDE-FLAG-NAME.md` 为 `CLAUDE-<FLAG>.md`；新场景请同步在 `settings/`、`agents/`、`dot_mcp_jsons/` 使用相同的 FLAG
2. 只写该场景与 Claude Code 默认行为不同、且确有需要的约束（原因见根目录 README「转型说明」）
3. 用 `-f <FLAG>` 参数安装到目标项目
