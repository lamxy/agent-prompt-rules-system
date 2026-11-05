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

## 编写约定

依据官方《Skill authoring best practices》（platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices，2026-11-06 读原文），加上本仓库的要求：

- **先找缺口再写**：先不用 skill 完成一次真实任务，记下反复补充的上下文或出错点；写至少 3 个评估情境（含应触发与不应触发），量一次没有 skill 时的表现，再写刚好够用的内容
- **写与测分开**：一个会话起草（可用 `skill-creator`），另开新会话在真实素材上测（如阶段 3 专案的 run tag），观察后回到起草会话修改
- **description**：第三人称；写清做什么与何时使用（用户会说的话、相关文件或场景）；上限 1024 字符，`name` 只用小写字母、数字、连字号
- **精简**：只写 Claude 不知道的项目约定；`SKILL.md` 正文控制在 500 行内，超出拆到 `references/`；参考文件只从 `SKILL.md` 往下一层，超过 100 行的参考文件开头放目录
- **流程与校验**：多步骤任务给编号步骤或检查清单；质量关键的步骤加「校验 → 修正 → 再校验」；确定性操作用脚本，写明是执行还是只读参考
- **不写会过时的内容**：不绑版本与日期，必要时放「旧做法」段
- **MCP 工具**写完整名称（如 `mcp__plugin_mongodb_mongodb__find`）
- **本仓库要求**：结论须有实测或一手来源（根目录 `AGENTS.md`「Unverified Content」）；只引用项目已有规范时注明出处；`skills/skills-<FLAG>/` 与场景包各放一份（`test-scenario-skills.sh` 校验）

候选清单（claude-code-setup 推荐、尚未实现）见 `docs/evaluation/2026-11-claude-code-setup-review.md` 3.6 节。

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
