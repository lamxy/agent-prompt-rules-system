# Agents

本目录存放按项目/场景分组的 agent 包。每个 agent 包是一个以 `agents-<FLAG>` 命名的目录，包含该场景所需的 agent 定义文件（`*.md`）。

## 场景 agent 包

项目场景与 `claude_mds/`、`settings/`、`skills/`、`dot_mcp_jsons/` 使用相同的 FLAG：

| FLAG | 场景 | 包含的 agent |
|------|------|-------------|
| `backend-dev` | 后端开发 | `go-reviewer`：只读审查 Go 改动（分层、API、存储、并发），依据项目 `CLAUDE.md` 与 `.claude/rules/` |
| `dev-ops` | DevOps | `deploy-reviewer`：只读审查 compose、Dockerfile、流水线（镜像 tag、密钥、端口、资源、可观测性），依据 `CLAUDE.md` 与 `middleware-ops` |
| `prd-design`、`frontend-dev` | — | 暂无；试用中出现需求再写 |

只放**自写、只读、贴合场景**的审查 agent，由用户手动调用（「用 go-reviewer 审查这次改动」）。原因（2026-11-05，见 `docs/evaluation/2026-11-claude-code-setup-review.md`）：

- 原先四个场景共 21 个 agent 挑选自 `agents-agency-agent-based-dev/`，是通用人设，内容与场景约定冲突（如 PostgreSQL／Supabase、Slack／PagerDuty、原型场景写生产代码），且都没有 `tools:` 限制
- 阶段 1、3 共 72 个测验会话中调用 0 次；场景约定已在 `CLAUDE.md`、rules 与自写 skill 中，主会话自己完成
- 子代理相对主会话的实际收益在「干净上下文的独立审查」，所以只保留这一类

写法约定：frontmatter 写 `tools:`；正文只引用项目已有的规范文件，不写新的结论（新结论先进规范并有依据）；输出带 `文件:行号` 与依据。

## 其他 agent 包

| 目录 | 内容 |
|------|------|
| `agents-agency-agent-based-dev/` | 来自 msitarzewski/agency-agents 的设计、工程、产品、测试类 agent（约 50 个），作为挑选参考库 |

从参考库挑选时：去掉文件名的 `engineering-` 等前缀，frontmatter 的 `name` 改为与文件名一致的小写连字符形式；按场景改写冲突内容并加 `tools:`，不要原样放进场景包。

## 目录结构

```
agents/
  agents-backend-dev/
    go-reviewer.md
  agents-dev-ops/
    deploy-reviewer.md
  agents-agency-agent-based-dev/
  agents-FLAG-NAME/      # 命名模板，复制后重命名
```

场景包 `dot_claude_projects/.claude-<FLAG>/.claude/agents/` 各放一份，内容相同。

## 使用方式

通过 `scripts/install-agent-pkg.sh` 将指定 agent 包中的 `*.md` 文件拷贝到目标项目的 agent 目录。

```sh
# 基本用法（同名文件提示手动处理，其他直接拷贝）
sh scripts/install-agent-pkg.sh -f backend-dev -t /path/to/project/.claude/agents

# 强制覆盖（旧文件先移到 <target>.backup-<时间戳>/）
sh scripts/install-agent-pkg.sh -f backend-dev -t /path/to/project/.claude/agents -F

# 指定 agent 包来源目录（默认为本仓库 agents/ 目录）
sh scripts/install-agent-pkg.sh -f backend-dev -t /path/to/project/.claude/agents -s /custom/agents/root
```

## 新增 agent 包

1. 在 `agents/` 下新建 `agents-<FLAG>/` 目录；新场景请同步在 `claude_mds/`、`settings/`、`skills/`、`dot_mcp_jsons/` 使用相同的 FLAG
2. 在其中放置 agent 定义 `*.md` 文件（frontmatter 含 `name`、`description`、`tools`，可用 `model:` 指定模型）
3. 不要在 agent 包内放 `README.md`：安装脚本会复制包内所有 `*.md`，README 会被当成 agent 安装
4. 用 `-f <FLAG>` 参数安装到目标项目；同步更新 `dot_claude/skills/mysession-eval/scenarios.json` 的 `agents` 名单（测试会核对）
