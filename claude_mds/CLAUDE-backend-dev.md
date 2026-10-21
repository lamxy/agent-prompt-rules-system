# CLAUDE.md — 后端开发（Go）

<!--
维护说明（注入上下文前会被移除）：
- 本场景以 Go 技术栈为参考实现；其他技术栈请复制场景包后改写，见 dot_claude_projects/README.md。
- 只写每个会话都需要、且与 Claude Code 默认行为不同的约定。只在编辑特定文件时才需要的规范放
  .claude/rules/（带 paths），设计流程与完整规范放 .claude/skills/。
- 工具由 settings/settings.project-backend-dev.json 启用（gopls-lsp、postman、mongodb、
  redis-development 等），MySQL / PostgreSQL MCP 见 dot_mcp_jsons/dot-mcp-json-backend-dev.json。
- 破坏性数据库命令由 settings 的 permissions.deny 拦截；.go 文件格式由 PostToolUse hook 处理，不在此重复。
-->

## 技术栈

Go；HTTP 框架为 FiberHouse（可切换 Fiber、Gin、Hertz 内核）或原生 Gin、Fiber；gRPC；MySQL、PostgreSQL、MongoDB、Elasticsearch、Redis、Kafka、RabbitMQ。项目实际使用哪些，以 `go.mod` 为准。

## 目录结构

应用目录（FiberHouse 示例中为 `example_application/`）的典型结构：

| 目录 | 职责 |
|---|---|
| `apivo/<模块>/requestvo/`、`responsevo/` | 对外接口的请求与响应结构（对外契约） |
| `module/<名称>-module/api/` | 传输层：handler、路由注册、依赖装配 |
| `module/<名称>-module/service/` | 业务用例，与传输层和框架无关 |
| `module/<名称>-module/repository/` | 数据存取，对 service 隐藏存储细节 |
| `module/<名称>-module/model/` | 对具体存储（MongoDB 集合、GORM 表）的访问模型 |
| `module/<名称>-module/entity/` | 持久化的数据结构与类型 |
| `module/<名称>-module/dto/` | 层间传递的数据，隔离存储类型（如 BSON）与对外 JSON 契约 |
| `module/<名称>-module/task/`、`transport/` | 异步任务；领域错误到传输层错误的映射 |
| `module/common-module/` | 跨模块共享的字段、属性、常量 |
| `command/` | 命令行子应用（urfave/cli），与 HTTP 层同级的另一种传输层 |
| `providers/` | 框架扩展点：中间件、钩子、路由注册、校验、异常 |

依赖只向内：`api / command → service → repository → model`。新项目不一定有全部目录，新增代码放在已有的对应层，不另造平行目录。

## 设计文档

- 系统规格说明、架构设计、数据库设计写在 `docs/design/`；技术栈与框架选型等重大决策记录为 ADR：`docs/adr/NNNN-<标题>.md`（背景、选项、决定、后果）。
- 动手实现跨模块功能前，先给出设计要点并确认。新增业务模块用 `/go-new-module`。

## API

- 先改契约（`apivo/`、OpenAPI 注解或 proto），再写实现；破坏性变更走新版本，不直接修改已发布的接口。
- 写操作接口要考虑幂等；列表接口必须分页；对外部依赖设置超时，重试只用于幂等操作。

## 存储与中间件

- MySQL、MongoDB、Elasticsearch、Redis、Kafka、RabbitMQ、gRPC（`rules/rpc/`）的规范在 `.claude/rules/`，编辑对应代码时自动加载；日志规范在 `.claude/rules/go/logging.md`。
- 设计新表或集合用 `/db-schema-design`，缓存用 `/cache-design`，消息用 `/mq-design`，gRPC 接口用 `/rpc-design`，系统架构图用 `/system-design-doc`。
- schema 变更只通过 migration 文件并附回滚步骤，不直接在库上执行 DDL。
- 数据库 MCP 只连开发或测试库，使用只读账号。

## 验证

改动 Go 代码后，至少运行 `go build ./...`、`go vet ./...` 和受影响包的 `go test`；涉及并发的改动加 `-race`。项目有 `Makefile` 或 `golangci-lint` 配置时，以项目的命令为准。
