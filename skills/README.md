# Skills

本目录存放按项目/场景分组的技能包。每个技能包是一个以 `skills-<FLAG>` 命名的目录，包含该场景下所需的 skill 子目录集合（每个 skill 含 `SKILL.md`）。

## 场景技能包

项目场景与 `claude_mds/`、`settings/`、`agents/`、`dot_mcp_jsons/` 使用相同的 FLAG：

| FLAG | 场景 | 状态 |
|------|------|------|
| `prd-design` | PRD 设计 | 自定义 skill 待补充；PM 类 skill 由 `open_supports/ost_phuryn_pm-skills` 以项目级插件提供 |
| `frontend-dev` | 前端开发 | 自定义 skill 待补充；外部 skills 安装方式见 `skills-frontend-dev/README.md` |
| `backend-dev` | 后端开发 | `go-new-module`、`db-schema-design`、`cache-design`、`mq-design`、`rpc-design`、`system-design-doc`、`go-perf-diagnose`（与场景包 `.claude/skills/` 保持一致） |
| `dev-ops` | DevOps | `middleware-ops`（中间件与 gRPC 服务的部署、调优、迁移与监控基线） |

场景所需的第三方 skill 优先使用 `open_supports/` 收录的支持包（如 pm-skills、mattpocock-skills）或 `settings/` 中启用的插件（如 document-skills），本目录只放它们没有覆盖、需要自己编写的 skill。

场景化指引优先写成 skill，而不是写进 `CLAUDE-<FLAG>.md` 常驻上下文：skill 只在相关时载入（原因见根目录 README「转型说明」）。

## 其他技能包

| 目录 | 内容 |
|------|------|
| `skills-codex-repair/` | npm 安装 Codex 时 `ENOTEMPTY` 错误的修复 |
| `skills-github-ops/` | GitHub release 发布 |
| `skills-open-supports/` | 安装 `open_supports/` 支持包 |

## 目录结构

```
skills/
  skills-prd-design/
  skills-frontend-dev/
  skills-backend-dev/
  skills-dev-ops/
    my-skill-a/
      SKILL.md
  skills-NAME-FLAG/      # 命名模板，复制后重命名
```

## 使用方式

通过 `scripts/install-skill-pkg.sh` 将指定技能包中的技能拷贝到目标项目的技能目录。脚本只复制含 `SKILL.md` 的子目录，包内的 `README.md`、`.gitkeep` 不会被安装；目标目录不存在时自动创建；占位包会提示「此包尚无 skill」。`-F` 会先把同名 skill 移到与目标同级的 `<target>.backup-<时间戳>/` 再覆盖。

```sh
# 基本用法（同名目录提示手动处理，其他直接拷贝）
sh scripts/install-skill-pkg.sh -f frontend-dev -t /path/to/project/.claude/skills

# 强制覆盖（删除同名目录后重新拷贝）
sh scripts/install-skill-pkg.sh -f frontend-dev -t /path/to/project/.claude/skills -F

# 指定技能包来源目录（默认为本仓库 skills/ 目录）
sh scripts/install-skill-pkg.sh -f frontend-dev -t /path/to/project/.claude/skills -s /custom/skills/root
```

## 新增技能包

1. 在 `skills/` 下新建 `skills-<FLAG>/` 目录；新场景请同步在 `claude_mds/`、`settings/`、`agents/`、`dot_mcp_jsons/` 使用相同的 FLAG
2. 在其中放置各 skill 子目录（每个 skill 含 `SKILL.md`，`description` 写清楚何时使用）
3. 用 `-f <FLAG>` 参数安装到目标项目
