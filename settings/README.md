# settings/

此目录收录按**作用域**和**项目场景**分类的 Claude Code settings 模板，通过 `scripts/install-settings.sh` 安装到目标路径。

---

## 作用域与优先级

Claude Code settings 按三个作用域分层，优先级从高到低：

```
local > project > user
```

| 作用域 | 说明 | 默认路径 |
|--------|------|---------|
| `user` | 用户级全局配置，适用于所有项目 | `~/.claude/settings.json` |
| `project` | 项目级共享配置，纳入版本控制，团队共用 | `<project>/.claude/settings.json` |
| `local` | 本地个人覆盖，不提交 Git，仅影响当前机器 | `<project>/.claude/settings.local.json` |

---

## 可用模板与场景

项目场景与 `claude_mds/`、`agents/`、`skills/`、`dot_mcp_jsons/`、`dot_claude_projects/` 使用相同的 FLAG：`prd-design`、`frontend-dev`、`backend-dev`、`dev-ops`。

分层原则：

- **用户级只放所有项目都需要的插件**；和语言、框架、业务领域相关的插件放到项目级场景模板。插件在项目的 `.claude/settings.json` 中启用时只对该项目生效。
- **规格框架按场景启用**：superpowers 在全局；OpenSpec（后端）、gsd-core（前端）在 `dot_claude_projects/` 场景清单中默认启用，同一项目只启用其中一套，见 [`dot_claude_projects/README.md`](../dot_claude_projects/README.md)。
- **硬约束写在 `permissions`**：后端模板拒绝破坏性数据库命令，DevOps 模板对基础设施变更命令要求人工确认。
- **市场统一**：`anthropics/claude-code`（`claude-code-plugins`）中的插件在官方市场 `claude-plugins-official` 都有同名版本，模板不再引用前者。

### 插件池与分层（2026-10-28 集中梳理）

汇总参考的全局插件配置、`settings.user.json` 与各场景模板后的完整插件池。市场规则：同一插件在多个市场都有时用 `@claude-plugins-official`；只有内置目录 `anthropic-plugin-directory` 提供时才用它（`typescript-native-lsp`）。

| 插件 | 层级／场景 | 说明 |
|------|-----------|------|
| `superpowers`、`andrej-karpathy-skills`、`ralph-loop` | 全局 | 工作流与工程方法 |
| `mattpocock-skills` | prd-design、backend-dev | 需求追问、规格与任务拆分、领域建模；2026-10-28 移出全局，见下方「工作流框架分层」 |
| `context7`、`github`、`commit-commands` | 全局 | 文档查询与代码托管 |
| `security-guidance`、`open-code-review` | 全局 | 质量与安全 |
| `claude-code-setup`、`claude-md-management`、`skill-creator`、`hookify` | 全局 | Claude Code 自身配置 |
| `remember`、`session-report` | 全局 | 会话与记忆 |
| `playground` | prd-design、frontend-dev | 单文件 HTML 原型与交互探索 |
| `document-skills`（`@anthropic-agent-skills`） | prd-design | docx / pptx / xlsx / pdf 交付 |
| `typescript-native-lsp`（`@anthropic-plugin-directory`）、`frontend-design`、`playwright`、`chrome-devtools-mcp`、`modern-web-guidance`、`sentry` | frontend-dev | 语言服务、UI 实现、浏览器验证、Web 最佳实践、错误追踪 |
| `gopls-lsp`、`postman`、`mongodb`、`redis-development` | backend-dev | Go 语言服务、API 测试、MongoDB、Redis |
| `semgrep` | backend-dev、dev-ops | 静态安全扫描 |
| `terraform`、`sonatype-guide` | dev-ops | 基础设施即代码、依赖供应链安全 |
| `pr-review-toolkit` | frontend-dev、backend-dev、dev-ops | PR 审查代理 |
| `pyright-lsp`、`typescript-lsp` | 本地级可选（`false`） | 见下方本地级表 |
| `figma`、`notion`、`miro`、`vercel`、`supabase`、`neon`、`mongodb-atlas`、`datadog`、`pagerduty`、`incident-io`、`cloudflare`、`aws-core` | 本地级可选（`false`） | 需要个人账号或托管服务 |

不采用：

| 插件 | 原因 |
|------|------|
| `code-review`（内置目录中为 `code-review-anthropics`） | PR 审查已有内置 `/code-review`、`pr-review-toolkit`、`open-code-review`、gstack `/review`，再加一套重叠过多 |
| `mongodb-self-managed-mcp`（内置目录） | 与 `mongodb@claude-plugins-official` 同源（`mongodb/agent-skills` 的 `plugins/mongodb`），不重复收录 |
| `@claude-code-plugins` 市场的 `commit-commands` 等 | 官方市场都有同名版本，不再声明该市场 |

`settings/settings.project-<FLAG>.json` 与 `dot_claude_projects/.claude-<FLAG>/.claude/settings.json` 本次梳理后保持一致；之后仍按「分开维护」处理，除非明确要求再次对齐。

### 工作流框架分层（2026-10-28）

依据：`docs/evaluation/2026-10-28-skill-overrides-experiment.md`（实测）与 `docs/plans/2026-10-28-workflow-frameworks-tiering.md`（讨论记录）。

- 判断标准不是插件数量：本机全局 + gstack 共 131 个 skill，清单仍未超出预算。要看的是同一意图可自动触发的 skill 不超过 1 个。
- `skillOverrides` 只对个人、项目、内置 skill 生效，**对插件 skill 无效**；跨作用域逐键合并，高层可以放宽，也可以收紧。
- 插件只能整包开关：项目级 `enabledPlugins` 设为 `false` 可以关掉全局已启用的插件。

| 框架 | 形态 | 分层 |
|------|------|------|
| superpowers | 插件 | 全局启用 |
| mattpocock-skills | 插件 | 不在全局；prd-design、backend-dev 的 `enabledPlugins` 启用。上游已把 27 个 skill 中 16 个设为只能手动调用；其余可自动触发的 `tdd`、`diagnosing-bugs`、`code-review` 与 superpowers 重叠，因此不放全局 |
| gstack | 个人 skill（`--prefix` 安装，名称为 `gstack-*`） | `settings.user.json` 的 `skillOverrides` 把 62 个 skill 及路由 `gstack`、`_gstack-command` 设为 `user-invocable-only`（`/` 菜单可用，模型看不到）；iOS、gbrain、ubicloud 共 8 个设为 `off`。场景模板只把需要的设为 `on`：prd-design 为 `gstack-office-hours`、`gstack-plan-ceo-review`；dev-ops 为 `gstack-ship`、`gstack-land-and-deploy`、`gstack-canary`、`gstack-cso` |

gstack 各 skill 之间多以读取对方 `SKILL.md` 串接，不经 Skill 工具，隐藏后不影响串接；只有路由 skill 用 Skill 工具派发，它本身也已隐藏。gstack 升级新增 skill 时，新 skill 默认为 `on`，需要把它补进 `skillOverrides`。

### 用户级（`-l user`）

| 文件 | `-s` 参数 | 说明 |
|------|-----------|------|
| `settings.user.json` | （不带 `-s`） | 推荐的全局基础设定：以本机 `~/.claude/settings.json` 为基础，只调整了插件与市场 |

全局插件：

| 类别 | 插件 |
|------|------|
| 工作流与工程方法 | `superpowers`、`andrej-karpathy-skills`、`ralph-loop` |
| 文档与代码托管 | `context7`、`github`、`commit-commands` |
| 质量与安全 | `security-guidance`、`open-code-review` |
| Claude Code 自身配置 | `claude-code-setup`、`claude-md-management`、`skill-creator`、`hookify` |
| 会话与记忆 | `remember`、`session-report` |

相对本机设定的调整：

| 调整 | 原因 |
|------|------|
| 移出 `gopls-lsp`、`pyright-lsp`、`typescript-native-lsp`、`typescript-lsp`（停用项） | 语言相关，移到前端、后端场景 |
| 移出 `frontend-design`、`chrome-devtools-mcp`、`playground` | 只在前端或 PRD 场景使用 |
| `skillOverrides` 新增 gstack 64 项 | gstack 默认只能手动调用，见「工作流框架分层」（2026-10-28；同日 `mattpocock-skills` 移出全局，改为场景启用） |
| `commit-commands`、`skill-creator`、`claude-md-management`、`security-guidance` 改用 `@claude-plugins-official` | 原来分别来自 `claude-code-plugins` 与内置插件目录；统一到官方市场，换机器也能复现 |
| 删除 `claude-code-plugins` 市场 | 其插件官方市场都有 |

`dot_claude/settings.json` 仍是本机设定的镜像，未做上述调整；要在本机采用新的全局设定，需手动执行 `install-settings.sh -l user`（会先备份）。

这份设定保留了作者本机的环境与偏好，在其他机器上使用前逐项确认：

| 项目 | 依赖或影响 | 其他机器上的处理 |
|------|-----------|-----------------|
| `PreToolUse` hook `rtk hook claude` | 本机安装的 `rtk` 命令，用于压缩命令输出 | 每次 Bash 调用前都会执行；没有 `rtk` 时安装它，或删除该 hook |
| `Stop`、`StopFailure` hook | `~/.claude/skills/myhandoff/scripts/handoff-hook` | 由 `sh scripts/install.sh -l user` 随 `dot_claude/skills/myhandoff/` 安装；未安装时删除这两个 hook |
| `SessionStart` hook `zsh -c '. ~/.zshrc'` | 在子 shell 中载入 `~/.zshrc`，执行完即退出，不会改变 Claude 的环境 | 非 zsh 环境会报错，可直接删除 |
| `sandbox`（`filesystem`、`network`）、`excludedCommands` | 路径按 macOS 与作者的工具链（Go、Rust、Node、Python、Flutter）设定；`failIfUnavailable: true` 在沙箱无法启动时（缺依赖或平台不支持，如原生 Windows）让 Claude Code 启动即报错退出（[官方说明](https://code.claude.com/docs/en/settings-reference)） | 按自己的工具链调整路径；不支持沙箱的环境改为 `false`（命令改为不经沙箱执行） |
| `permissions` | `allow` 放行了大量构建、包管理、`docker compose up/down`、`git push` 命令；`deny` 禁止所有 `docker rm`、`volume rm`、`network rm`、`prune` 等删除类命令 | 按自己的风险偏好删减；`deny` 跨作用域优先于项目级的 `ask`，见下方 dev-ops 说明 |
| `autoMode.environment`、`defaultMode: auto` | 自动模式的环境描述按作者的前端 + Go 后端工作流编写 | 改写为自己的技术栈 |
| `model`、`effortLevel`、`language`、`theme`、`tui`、`skillOverrides` | 个人偏好 | 按需修改 |

全局工具中，gstack、task-master 不是插件，登记在全局清单 `dot_claude_projects/.claude/open_supports_name_list.txt`，用 `sh scripts/install-claude-project.sh -g` 安装，见 [`open_supports/INDEX.md`](../open_supports/INDEX.md)「全局工具」。场景的 settings 也已聚合进 `dot_claude_projects/.claude-<FLAG>/.claude/settings.json`，两处分开维护。

### 项目级（`-l project`）

| 文件 | `-s` 参数 | 插件 | 其他 |
|------|-----------|------|------|
| `settings.project-prd-design.json` | `prd-design` | `playground`、`document-skills`（docx/pptx/xlsx/pdf） | 声明 `anthropic-agent-skills` 市场。PM Skills 由 `open_supports/ost_phuryn_pm-skills` 以项目级插件安装，见下方说明 |
| `settings.project-frontend-dev.json` | `frontend-dev` | `typescript-native-lsp`、`frontend-design`、`playwright`、`chrome-devtools-mcp`、`modern-web-guidance`、`playground`、`pr-review-toolkit`、`sentry` | — |
| `settings.project-backend-dev.json` | `backend-dev` | `gopls-lsp`、`postman`、`mongodb`、`redis-development`、`semgrep`、`pr-review-toolkit` | `permissions.deny`：MySQL、PostgreSQL、MongoDB（含 `mongosh`）、Redis 的破坏性命令；`PostToolUse` hook 在编辑 `.go` 文件后执行 `.claude/hooks/go-fmt.sh`（脚本只在场景包中提供） |
| `settings.project-dev-ops.json` | `dev-ops` | `terraform`、`semgrep`、`sonatype-guide`、`pr-review-toolkit` | `permissions.ask`：`terraform apply/destroy/import/state`、`docker compose up/down/rm`、`docker rm`、`docker volume rm/prune`、`docker system/image prune`、`docker network rm`、`docker context use` |
| `settings.project-fullstack-dev.json` | `fullstack-dev` | 前端 + 后端去重 | 与后端相同的 `permissions.deny` |

- PRD 场景的 PM Skills 来自本仓库收录的 `open_supports/ost_phuryn_pm-skills`，不在 settings 模板中重复启用：`dot_claude_projects/.claude-prd-design/` 的清单以 `--client=claude-code --location=local` 安装，插件以 `--scope project` 写入项目的 `.claude/settings.json`。因此要先安装 settings 模板，再运行 `install-open-supports.sh`；之后若用 `-m overwrite` 重装 settings 模板，PM Skills 的条目会被覆盖（备份中仍有），需重新运行 `install-open-supports.sh` 或改用 `-m merge`。
- 后端的 MySQL、PostgreSQL 没有通用的官方插件，由 `dot_mcp_jsons/dot-mcp-json-backend-dev.json` 提供 MCP。
- `typescript-native-lsp` 来自 Claude Code 内置插件目录（`@anthropic-plugin-directory`），无需声明市场；TypeScript 6 以下的项目需另装 `typescript-language-server`。
- 插件需要的账号（Postman 等）在首次使用时按插件提示登录或配置。
- dev-ops 的 `permissions.ask` 与全局设定同时安装时：权限按 `deny` → `ask` → `allow` 判定，且任一作用域的 `deny` 都先于其他作用域生效（[官方说明](https://code.claude.com/docs/en/permissions)）。因此 `settings.user.json` 的 `deny` 中已有的 `docker rm`、`docker volume rm`、`docker network rm`、`docker compose rm`、`docker system/image prune`（带参数）在 dev-ops 项目里会被直接拒绝而不是要求确认，需要时由人手动执行；`docker compose up/down`、`docker context use`、`terraform apply` 等仍会要求确认（全局只 `allow` 了 compose up/down，`ask` 先于 `allow`）。这些 `ask` 条目保留，供未安装本仓库全局设定的机器使用。
- backend-dev、dev-ops 不启用 `sentry`（其 MCP 连接 sentry.io，不支持自建的 GlitchTip）与 `grafana-mcp`（起步阶段不部署 Grafana；升级到 Prometheus + Grafana 后再启用）；错误追踪查询改用 GlitchTip 内置 MCP（`dot_mcp_jsons/`）。frontend-dev 的 `sentry` 暂未调整。

### 本地级（`-l local`）

本地级是个人覆盖，必须指定 `-s`。模板列出该场景**可选、需要个人账号或特定托管服务**的插件，默认为 `false`；需要时改为 `true`。也可以把项目级已启用的插件设为 `false` 来个人停用。

| 文件 | `-s` 参数 | 可选插件 |
|------|-----------|---------|
| `settings.local-prd-design.json` | `prd-design` | `figma`、`notion`、`miro` |
| `settings.local-frontend-dev.json` | `frontend-dev` | `figma`、`vercel`；`typescript-lsp`（项目级 `typescript-native-lsp` 不适用时的替代，启用时把后者设为 `false`） |
| `settings.local-backend-dev.json` | `backend-dev` | `supabase`、`neon`、`mongodb-atlas`（托管数据库）；`pyright-lsp`（项目含 Python 代码时） |
| `settings.local-dev-ops.json` | `dev-ops` | `datadog`、`pagerduty`、`incident-io`、`cloudflare`、`aws-core` |

### 参考文件

| 文件 | 说明 |
|------|------|
| `settings.local-proxy.json.README` | 第三方代理环境的带注释设定示例（`availableModels`、默认模型映射、非必要流量等）。对应的 JSON 模板已删除，需要时参考此文件手动写入 `settings.local.json` |

---

## 安装方式

使用 `install-settings.sh` 安装到目标路径：

```sh
sh ./scripts/install-settings.sh -l <user|project|local> [-s <scenario>] [--src <source_settings_json>] -m <overwrite|merge|ask> [-p <target_dir>]
```

```sh
# 用户级基础配置（settings.user.json）
sh ./scripts/install-settings.sh -l user -m overwrite

# 项目级 PRD 设计场景
sh ./scripts/install-settings.sh -l project -s prd-design -m overwrite -p /path/to/project/.claude

# 项目级全栈（直接用组合模板）
sh ./scripts/install-settings.sh -l project -s fullstack-dev -m overwrite -p /path/to/project/.claude

# 本地前端覆盖（合并到已有的 settings.local.json）
sh ./scripts/install-settings.sh -l local -s frontend-dev -m merge -p /path/to/project/.claude

# 使用自定义源文件（文件名须符合作用域，如 settings.project-*.json）
sh ./scripts/install-settings.sh -l project --src /path/to/settings.project-custom.json -m overwrite -p /path/to/project/.claude
```

---

## 注意事项

- **`.json` 文件已存在时不会自动覆盖**（除非显式指定 `-m overwrite`），覆盖或合并前都会先备份。
- **`-m merge` 只逐键合并 `enabledPlugins`、`extraKnownMarketplaces` 和 `skillOverrides`**。后端、全栈、DevOps 模板的 `permissions` 和 `settings.user.json` 的其他字段都不会写入（脚本会以 `[WARN]` 列出）；需要这些字段时用 `-m overwrite`，或手动合并 `permissions`。
- 新增场景时，复制一个现有场景模板改名为 `settings.<作用域>-<FLAG>.json`，并同步使用 `claude_mds/`、`agents/`、`dot_mcp_jsons/` 中相同的 FLAG。
- 本机设定变更后，同步到 `dot_claude/settings.json`（本机镜像）；`settings.user.json` 只在全局插件与市场需要调整时修改。
- 修改插件后运行 `sh scripts/tests/test-settings-templates.sh`，检查 JSON 合法、插件名称在已缓存的市场目录中存在、引用的第三方市场已声明。
- 2026-10-19 收敛记录：
  - 用户级只保留 `settings.user.json`（本机设定副本），删除 `user-productivity`、`user-moreopen`
  - 项目级 `product-collab` 更名为 `prd-design`，`release-ops` 更名为 `dev-ops`（内容不变）；删除 `xxx`（占位模板）
  - 本地级新增 `prd-design`、`dev-ops` 最小模板；删除 `settings.local.json`（安装脚本本就不接受此文件名作为本地级来源）、`experimental`、`low-connectivity`、`proxy`（其注释版 `.README` 保留为参考文件）
- 提交项目时，`settings.local*` 系列文件应加入 `.gitignore`，避免将本地个人配置纳入版本控制。
