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
- **不设默认工作流框架**：superpowers 在全局；OpenSpec、gsd-core 与它同类，同一项目启用多套会产生互相矛盾的指令，所以只在 `dot_claude_projects/` 清单中以注释形式提供，按需启用其一。
- **硬约束写在 `permissions`**：后端模板拒绝破坏性数据库命令，DevOps 模板对基础设施变更命令要求人工确认。
- **市场统一**：`anthropics/claude-code`（`claude-code-plugins`）中的插件在官方市场 `claude-plugins-official` 都有同名版本，模板不再引用前者。

### 用户级（`-l user`）

| 文件 | `-s` 参数 | 说明 |
|------|-----------|------|
| `settings.user.json` | （不带 `-s`） | 推荐的全局基础设定：以本机 `~/.claude/settings.json` 为基础，只调整了插件与市场 |

全局插件：

| 类别 | 插件 |
|------|------|
| 工作流与工程方法 | `superpowers`、`mattpocock-skills`、`andrej-karpathy-skills`、`ralph-loop` |
| 文档与代码托管 | `context7`、`github`、`commit-commands` |
| 质量与安全 | `security-guidance`、`open-code-review` |
| Claude Code 自身配置 | `claude-code-setup`、`claude-md-management`、`skill-creator`、`hookify` |
| 会话与记忆 | `remember`、`session-report` |

相对本机设定的调整：

| 调整 | 原因 |
|------|------|
| 移出 `gopls-lsp`、`pyright-lsp`、`typescript-native-lsp`、`typescript-lsp`（停用项） | 语言相关，移到前端、后端场景 |
| 移出 `frontend-design`、`chrome-devtools-mcp`、`playground` | 只在前端或 PRD 场景使用 |
| 新增 `mattpocock-skills` | 全局工具（官方市场已收录） |
| `commit-commands`、`skill-creator`、`claude-md-management`、`security-guidance` 改用 `@claude-plugins-official` | 原来分别来自 `claude-code-plugins` 与内置插件目录；统一到官方市场，换机器也能复现 |
| 删除 `claude-code-plugins` 市场 | 其插件官方市场都有 |

`dot_claude/settings.json` 仍是本机设定的镜像，未做上述调整；要在本机采用新的全局设定，需手动执行 `install-settings.sh -l user`（会先备份）。这份设定还包含 `autoMode`、`skillOverrides`、沙箱路径，以及依赖本机 `rtk`、`~/.claude/skills/myhandoff/` 的 hooks，在其他机器上使用前请先确认这些依赖存在，或删除对应的 hook。

全局工具中，gstack、task-master 不是插件，登记在全局清单 `dot_claude_projects/.claude/open_supports_name_list.txt`，用 `sh scripts/install-claude-project.sh -g` 安装，见 [`open_supports/INDEX.md`](../open_supports/INDEX.md)「全局工具」。场景的 settings 也已聚合进 `dot_claude_projects/.claude-<FLAG>/.claude/settings.json`，两处分开维护。

### 项目级（`-l project`）

| 文件 | `-s` 参数 | 插件 | 其他 |
|------|-----------|------|------|
| `settings.project-prd-design.json` | `prd-design` | `playground`、`document-skills`（docx/pptx/xlsx/pdf） | 声明 `anthropic-agent-skills` 市场。PM Skills 由 `open_supports/ost_phuryn_pm-skills` 以项目级插件安装，见下方说明 |
| `settings.project-frontend-dev.json` | `frontend-dev` | `typescript-native-lsp`、`frontend-design`、`playwright`、`chrome-devtools-mcp`、`modern-web-guidance`、`playground`、`pr-review-toolkit`、`sentry` | — |
| `settings.project-backend-dev.json` | `backend-dev` | `gopls-lsp`、`typescript-native-lsp`、`postman`、`mongodb`、`redis-development`、`semgrep`、`sentry`、`pr-review-toolkit` | `permissions.deny`：MySQL、PostgreSQL、MongoDB（含 `mongosh`）、Redis 的破坏性命令 |
| `settings.project-dev-ops.json` | `dev-ops` | `terraform`、`grafana-mcp`（可查询 Prometheus、Loki）、`sentry`、`semgrep`、`sonatype-guide`、`pr-review-toolkit` | `permissions.ask`：`terraform apply/destroy/import/state`、`kubectl apply/delete/scale/rollout/patch/edit/drain/cordon`、`helm install/upgrade/uninstall/rollback` |
| `settings.project-fullstack-dev.json` | `fullstack-dev` | 前端 + 后端去重 | 与后端相同的 `permissions.deny` |

- PRD 场景的 PM Skills 来自本仓库收录的 `open_supports/ost_phuryn_pm-skills`，不在 settings 模板中重复启用：`dot_claude_projects/.claude-prd-design/` 的清单以 `--client=claude-code --location=local` 安装，插件以 `--scope project` 写入项目的 `.claude/settings.json`。因此要先安装 settings 模板，再运行 `install-open-supports.sh`；之后若用 `-m overwrite` 重装 settings 模板，PM Skills 的条目会被覆盖（备份中仍有），需重新运行 `install-open-supports.sh` 或改用 `-m merge`。
- 后端的 MySQL、PostgreSQL 没有通用的官方插件，由 `dot_mcp_jsons/dot-mcp-json-backend-dev.json` 提供 MCP；Kubernetes MCP 同理。
- `typescript-native-lsp` 来自 Claude Code 内置插件目录（`@anthropic-plugin-directory`），无需声明市场；TypeScript 6 以下的项目需另装 `typescript-language-server`。
- 插件需要的账号（Sentry、Grafana、Postman 等）在首次使用时按插件提示登录或配置。

### 本地级（`-l local`）

本地级是个人覆盖，必须指定 `-s`。模板列出该场景**可选、需要个人账号或特定托管服务**的插件，默认为 `false`；需要时改为 `true`。也可以把项目级已启用的插件设为 `false` 来个人停用。

| 文件 | `-s` 参数 | 可选插件 |
|------|-----------|---------|
| `settings.local-prd-design.json` | `prd-design` | `figma`、`notion`、`miro` |
| `settings.local-frontend-dev.json` | `frontend-dev` | `figma`、`vercel` |
| `settings.local-backend-dev.json` | `backend-dev` | `supabase`、`neon`、`prisma`、`mongodb-atlas`（托管数据库） |
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
- **`-m merge` 只合并 `enabledPlugins` 和 `extraKnownMarketplaces`**。后端、全栈、DevOps 模板的 `permissions` 和 `settings.user.json` 的其他字段都不会写入（脚本会以 `[WARN]` 列出）；需要这些字段时用 `-m overwrite`，或手动合并 `permissions`。
- 新增场景时，复制一个现有场景模板改名为 `settings.<作用域>-<FLAG>.json`，并同步使用 `claude_mds/`、`agents/`、`dot_mcp_jsons/` 中相同的 FLAG。
- 本机设定变更后，同步到 `dot_claude/settings.json`（本机镜像）；`settings.user.json` 只在全局插件与市场需要调整时修改。
- 修改插件后运行 `sh scripts/tests/test-settings-templates.sh`，检查 JSON 合法、插件名称在已缓存的市场目录中存在、引用的第三方市场已声明。
- 2026-10-19 收敛记录：
  - 用户级只保留 `settings.user.json`（本机设定副本），删除 `user-productivity`、`user-moreopen`
  - 项目级 `product-collab` 更名为 `prd-design`，`release-ops` 更名为 `dev-ops`（内容不变）；删除 `xxx`（占位模板）
  - 本地级新增 `prd-design`、`dev-ops` 最小模板；删除 `settings.local.json`（安装脚本本就不接受此文件名作为本地级来源）、`experimental`、`low-connectivity`、`proxy`（其注释版 `.README` 保留为参考文件）
- 提交项目时，`settings.local*` 系列文件应加入 `.gitignore`，避免将本地个人配置纳入版本控制。
