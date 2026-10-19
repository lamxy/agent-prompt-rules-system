# CLAUDE.md — DevOps

<!--
维护说明（注入上下文前会被移除）：
- 只写与 Claude Code 默认行为不同的约定；工具由 settings/settings.project-dev-ops.json 启用
  （terraform、grafana-mcp、sentry、semgrep、sonatype-guide），Kubernetes MCP 见 dot_mcp_jsons。
- terraform apply、kubectl apply/delete、helm upgrade 等变更命令已由 permissions.ask 要求确认，不在此重复。
-->

## 变更前先给差异

执行任何变更前，先运行并展示对应的预览：`terraform plan`、`kubectl diff`、`helm diff upgrade`（需 helm-diff 插件）。用户确认预览后再执行变更。

## 环境

- 默认只操作开发或预发环境。执行 kubectl / helm 前先显示当前 context 与 namespace；目标是生产环境时，必须由用户明确指定。
- 密钥只通过 Secret 管理工具或 CI 的 secret 引用，不写入仓库、manifest 或日志。

## CI/CD 与上线

- 修改流水线配置时，说明影响哪些分支、环境和部署步骤。
- 每次上线说明回滚方式（镜像版本、Helm revision 或 Terraform 状态）。

## 可观测性

- 新服务需暴露 Prometheus 指标、输出结构化日志，并接入 Sentry。
- 新增告警规则需附 runbook 链接，阈值说明依据。
