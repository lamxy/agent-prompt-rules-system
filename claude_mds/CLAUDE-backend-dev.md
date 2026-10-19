# CLAUDE.md — 后端开发

<!--
维护说明（注入上下文前会被移除）：
- 只写与 Claude Code 默认行为不同的约定；工具由 settings/settings.project-backend-dev.json 启用
  （gopls-lsp、typescript-native-lsp、postman、mongodb、redis-development 等），
  MySQL / PostgreSQL MCP 见 dot_mcp_jsons/dot-mcp-json-backend-dev.json。
- 破坏性数据库命令由 settings 的 permissions.deny 拦截，不在此重复。
-->

## 设计文档

- 系统规格说明、架构设计、数据库设计写在 `docs/design/`；技术栈与框架选型等重大决策记录为 ADR：`docs/adr/NNNN-<标题>.md`（背景、选项、决定、后果）。
- 动手实现跨模块功能前，先给出设计要点并确认。

## API

- 先改契约（OpenAPI / proto），再写实现；破坏性变更走新版本，不直接修改已发布的接口。
- 写操作接口要考虑幂等；列表接口必须分页；对外部依赖设置超时，重试只用于幂等操作。

## 数据库

- MySQL / PostgreSQL 的 schema 变更只通过 migration 文件，并附回滚步骤；不直接在库上执行 DDL。
- MongoDB 的索引与集合变更同样写成迁移脚本；查询需有对应索引。
- Redis key 按 `<服务>:<实体>:<id>` 命名，并设置 TTL；不使用 `KEYS *` 这类阻塞命令。
- 数据库 MCP 只连开发或测试库，使用只读账号。

## 可观测性

日志使用结构化格式并带 trace id；新接口补充耗时与错误率指标。
