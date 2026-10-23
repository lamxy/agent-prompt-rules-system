# CLAUDE.md — DevOps

<!--
维护说明（注入上下文前会被移除）：
- 只写与 Claude Code 默认行为不同的约定；工具由 settings/settings.project-dev-ops.json 启用
  （terraform、grafana-mcp、sentry、semgrep、sonatype-guide）。
- terraform apply、docker compose up/down、docker volume rm 等变更命令已由 permissions.ask 要求确认，不在此重复。
- 当前阶段部署围绕 Docker / Docker Compose，不涉及 Kubernetes。
-->

## 变更前先给差异

执行任何变更前，先运行并展示对应的预览：`terraform plan`；Compose 变更先 `docker compose config` 展示合并后的配置，并说明哪些服务会被重建。用户确认后再执行变更。

## 环境

- 默认只操作开发或预发环境。执行 docker 命令前先显示当前 `docker context` 与 Compose 项目名；目标是生产主机时，必须由用户明确指定。
- 密钥通过 `.env`（不入库）、Docker secrets 或 CI 的 secret 引用注入，不写入仓库、compose 文件或日志。

## CI/CD 与上线

- 修改流水线配置时，说明影响哪些分支、环境和部署步骤。
- 每次上线说明回滚方式（上一个镜像 tag 或 Terraform 状态）；镜像用固定 tag，不用 `latest` 上线。

## 可观测性

- 按 `middleware-ops` skill 的 `references/observability.md` 建设：起步阶段不引入分布式追踪与重型日志平台，外部探测与错误告警放在业务主机之外，通知统一发到 Telegram。
- 新增告警说明阈值依据与处理步骤。
