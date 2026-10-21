# Dot Claude Projects

本目录存放可一次安装的配置包，由 `scripts/install-claude-project.sh` 分发：

- **场景包** `.claude-<FLAG>/`：一个场景的完整项目配置，安装到项目根目录。FLAG 与 `settings/`、`claude_mds/`、`dot_mcp_jsons/`、`agents/`、`skills/` 相同。
- **全局包** `.claude/`：没有场景标识，只含全局支持包清单，安装到 `~/.claude/`。

| 配置包 | 内容 | 安装到 |
|--------|------|--------|
| `.claude/` | `open_supports_name_list.txt`：gstack、task-master（用户级） | `~/.claude/` |
| `.claude-prd-design/` | settings、`CLAUDE.md`、6 个 agent；清单：pm-skills 以 `--scope project` 安装为项目插件 | 项目根目录 |
| `.claude-frontend-dev/` | settings、`CLAUDE.md`、5 个 agent；清单：codegraph（项目级），OpenSpec、gsd-core 为可选框架（注释状态） | 项目根目录 |
| `.claude-backend-dev/` | Go 参考实现：settings（含 gofmt hook）、`CLAUDE.md`、`.mcp.json`（MySQL、PostgreSQL）、6 个 agent、path rules（Go、框架、存储与中间件）、5 个 skill；清单同前端 | 项目根目录 |
| `.claude-dev-ops/` | settings、`CLAUDE.md`、`.mcp.json`（Kubernetes 只读）、5 个 agent、`middleware-ops` skill；清单无专属支持包 | 项目根目录 |
| `.claude-FLAG-NAME_template/` | 命名模板与清单格式说明 | — |

## 范围与自定义场景

仓库只维护上表四个场景包，每个都是该场景的**参考实现**，不提供覆盖所有技术栈的模板。以 `backend-dev` 为例：只以 Go 技术栈实现（Gin、Fiber、自定义框架、RPC，MySQL、PostgreSQL、MongoDB、Elasticsearch、Redis、Kafka、RabbitMQ），Java、Python 等其他后端技术栈不在仓库范围内。

其他场景、其他技术栈或特定项目，由使用者自行实现：

- **复制场景包**：复制最接近的场景包，以项目名或技术栈作为新 FLAG，再改写内容。例如：

  ```sh
  cp -R dot_claude_projects/.claude-backend-dev dot_claude_projects/.claude-order-service
  # 改写 CLAUDE.md、.claude/rules/、.claude/skills/ 中与技术栈、目录结构有关的内容
  sh scripts/install-claude-project.sh -f order-service -t /path/to/project -d   # 预演
  ```

  FLAG 只需在 `dot_claude_projects/` 中存在即可安装整包；要用各维度脚本单独安装时，再在对应维度目录建立同名 FLAG（见「新增场景」）。

- **切分支修改**：在自己的 fork 中切出分支，直接修改现有场景包，主分支保持与上游一致，方便日后合并更新。

## backend-dev：Go 参考实现

目录结构以 [FiberHouse](https://github.com/lamxy/fiberhouse) 的 `example_application/` 为准（`apivo/`、`command/`、`module/<名称>-module/{api,service,repository,model,entity,dto}/`、`providers/`），同样适用于原生 Gin、Fiber 项目。

| 位置 | 加载时机 | 内容 |
|---|---|---|
| `CLAUDE.md` | 每次会话 | 技术栈、目录与依赖方向、设计文档、API、存储与中间件规范索引、验证命令 |
| `.claude/rules/go/` | 编辑匹配的 `.go` 文件时 | `code-style.md`（错误、panic 与退出）、`concurrency.md`（context、goroutine 生命周期、定时器、锁、出站 HTTP、容器运行时参数）、`layering.md`（分层职责与类型转换）、`testing.md`、`logging.md`（日志级别与字段） |
| `.claude/rules/framework/` | 编辑 handler、路由、Provider 时 | `fiberhouse.md`、`fiber.md`、`gin.md` |
| `.claude/rules/database/` | 编辑 SQL、migration、`model` / `repository` / `entity` 等目录时 | `mysql.md`、`mongodb.md`、`elasticsearch.md` |
| `.claude/rules/redis.md`、`.claude/rules/mq/` | 编辑缓存、Kafka、RabbitMQ 相关代码时 | key 与 value 设计、命令限制；`kafka.md`、`rabbitmq.md`（命名、确认、幂等、连接） |
| `.claude/rules/rpc/` | 编辑 `.proto`、`buf.yaml`、gRPC 传输层代码时 | `proto.md`（命名、兼容性、字段语义）、`grpc-go.md`（错误映射、deadline、拦截器、客户端配置） |
| `.claude/skills/` | 调用或判断相关时 | `go-new-module`（新增业务模块）、`db-schema-design`、`cache-design`、`mq-design`、`rpc-design`（gRPC 契约与实现）、`system-design-doc`（上下文图与结构图）、`go-perf-diagnose`（泄漏、内存、CPU、锁竞争排查与 benchmark）；理由与参数表在各自的 `references/` |
| `.claude/hooks/go-fmt.sh` | 每次 Edit / Write `.go` 文件后 | goimports 或 gofmt；语法错误时回报给 Claude |

安装到项目后按实际技术栈删减 `rules/framework/`：使用 FiberHouse 时保留 `fiberhouse.md` 与所用内核的 `fiber.md` 或 `gin.md`；只用原生框架时删除 `fiberhouse.md`。path rules 按目录匹配，无法区分框架，多留的文件会在编辑 handler 时一并载入。不使用的存储或中间件，删除对应的 rules 文件即可（不用 gRPC 时删除 `rules/rpc/`）。

中间件与 gRPC 服务的部署、调优、迁移与监控基线属于运维面，放在 `.claude-dev-ops/` 的 `middleware-ops` skill。

## 场景包与各维度目录的关系

场景包是各维度配置的**完整聚合**，初次由以下来源复制而来，之后**与来源目录分开维护**，不自动同步：

| 场景包中的文件 | 初始来源 | 单独安装该维度 |
|---------------|---------|---------------|
| `.claude/settings.json` | `settings/settings.project-<FLAG>.json` | `install-settings.sh -l project -s <FLAG>` |
| `CLAUDE.md` | `claude_mds/CLAUDE-<FLAG>.md` | `install-claude-md.sh -f <FLAG>` |
| `.mcp.json` | `dot_mcp_jsons/dot-mcp-json-<FLAG>.json`（空模板不复制） | `install-dot-mcp.sh -f <FLAG>` |
| `.claude/agents/*.md` | `agents/agents-<FLAG>/` | `install-agent-pkg.sh -f <FLAG>` |
| `.claude/skills/<name>/` | `skills/skills-<FLAG>/` 中含 `SKILL.md` 的目录（目前有 `backend-dev`、`dev-ops`） | `install-skill-pkg.sh -f <FLAG>` |
| `.claude/open_supports_name_list.txt` | 只存在于场景包 | `install-open-supports.sh -t <project>` |
| `.claude/rules/`、`.claude/hooks/` | 只存在于场景包（目前只有 `backend-dev`） | 随场景包安装 |

两种方式都不会静默覆盖：目标文件已存在时默认跳过（`[MANUAL]`），加 `-F` 时先备份再覆盖。`settings.local.json`、本地级插件等个人设定不放进场景包。

## 安装一个场景项目

```sh
P=/path/to/project
sh scripts/install-claude-project.sh -f backend-dev -t "$P" -d   # 预演
sh scripts/install-claude-project.sh -f backend-dev -t "$P"
```

脚本先逐个文件复制场景包，再调用 `install-open-supports.sh -t "$P"` 按项目上的清单安装支持包。顺序已内建：`settings.json` 先于 pm-skills 写入，不会被覆盖。`-N` 只复制不安装支持包。

日后用 `-F` 重装场景包会覆盖 `.claude/settings.json`（先备份），pm-skills 写入的条目随后由同一次运行的支持包安装重新写入。

## 安装全局支持包

```sh
sh scripts/install-claude-project.sh -g -d   # 预演
sh scripts/install-claude-project.sh -g
```

- 只把 `.claude/open_supports_name_list.txt` 复制到 `~/.claude/`；已存在时保留，`-F` 先备份为 `~/.claude/open_supports_name_list.txt.backup-<时间戳>`
- 再按 `~/.claude/` 上的清单调用 `install-open-supports.sh -g`：支持包不复制，直接在本仓库的 `open_supports/<ost>/` 中运行安装脚本
- 全局清单出现 `{PROJECT_DIR}`、`--local`、`--location=local` 时整份拒绝，不运行任何安装脚本
- mattpocock-skills 以插件形式在 `settings/settings.user.json` 启用，不在清单里

## Open Supports 清单格式

```text
# <支持包名称> [安装参数...]
colbymchenry/codegraph --target=claude --location=local {PROJECT_DIR}
```

- 名称可写 `OwnerName/RepoName` 或 `ost_OwnerName_RepoName`
- 参数原样传给该支持包的 `scripts_for_install/install.*`
- 项目清单：`{PROJECT_DIR}` 替换为项目绝对路径。安装脚本在复制后的支持包目录中运行，项目级安装必须带上它
- 全局清单：只放用户级条目
- 只支持整行注释；参数值不能含空格

完整说明见 `.claude-FLAG-NAME_template/README-open_supports_name-list.md`。

**为什么 OpenSpec、gsd-core 默认注释**：两者与全局的 superpowers 一样，都规定了「规划 → 拆解 → 执行」流程。同一项目启用多套会产生互相矛盾的指令，所以不设默认框架，需要时在项目中取消注释其中一个再安装。

## 新增场景

1. 复制 `.claude-FLAG-NAME_template/` 为 `.claude-<FLAG>/`
2. 从各维度目录复制同 FLAG 的配置（见上表），按 [`open_supports/INDEX.md`](../open_supports/INDEX.md) 的「建议场景」写清单；项目级安装带上 `{PROJECT_DIR}`
3. 在其他维度目录使用相同的 FLAG
