# Dot MCP JSONs

本目录存放按场景分类的项目级 `.mcp.json` 模板，命名格式为 `dot-mcp-json-<FLAG>.json`。FLAG 与 `settings/`、`claude_mds/`、`agents/`、`skills/` 相同。

## 原则

- **只放插件没有提供的 MCP。** Figma、Playwright、Chrome DevTools、Sentry、Grafana、MongoDB、Terraform 等 MCP 已随 `settings/` 中启用的插件提供，这里不重复配置。
- **不写入任何凭据。** 连接信息一律用 `${VAR}` 引用环境变量；只有主机和端口给默认值。变量未设置时，Claude Code 会在 `/mcp` 与 `claude mcp list` 中提示缺少哪个变量。
- **默认只读。** 数据库使用只读账号，Kubernetes 使用只读配置文件。

## 各场景内容

| 文件 | MCP server | 说明 |
|------|-----------|------|
| `dot-mcp-json-prd-design.json` | 无（空文件） | 安装时跳过 |
| `dot-mcp-json-frontend-dev.json` | 无（空文件） | 浏览器与设计类 MCP 由插件提供 |
| `dot-mcp-json-backend-dev.json` | `mysql`、`postgres` | [MCP Toolbox for Databases](https://github.com/googleapis/genai-toolbox) 的预置工具集（`execute_sql`、`list_tables`、执行计划等）。MongoDB 由 `mongodb` 插件提供，Redis 由 `redis-development` 插件提供 skills |
| `dot-mcp-json-dev-ops.json` | `kubernetes` | [kubernetes-mcp-server](https://github.com/containers/kubernetes-mcp-server)，以只读配置启动 |

### 后端：数据库 MCP

需要的环境变量：

| 数据库 | 变量 |
|--------|------|
| MySQL | `MYSQL_HOST`（默认 `127.0.0.1`）、`MYSQL_PORT`（默认 `3306`）、`MYSQL_DATABASE`、`MYSQL_USER`、`MYSQL_PASSWORD` |
| PostgreSQL | `POSTGRES_HOST`（默认 `127.0.0.1`）、`POSTGRES_PORT`（默认 `5432`）、`POSTGRES_DATABASE`、`POSTGRES_USER`、`POSTGRES_PASSWORD` |

- MCP Toolbox 的 `execute_sql` **可以执行写操作**，工具本身没有只读开关。务必使用只读数据库账号，并只连开发或测试库。
- 项目只用其中一种数据库时，删除另一个条目，避免每次会话都启动用不到的 server。
- 预置工具集仍在 1.0 之前，版本更新可能调整工具名称。

### DevOps：Kubernetes MCP

1. 把 `kubernetes-mcp-server.readonly.toml` 复制到 `~/.config/kubernetes-mcp-server.toml`。它开启 `read_only`，并禁止读取 `Secret`。新版不再接受 `--read-only` 命令行参数，只读模式只能写在配置文件里。
2. 集群凭据沿用 `$KUBECONFIG` 或 `~/.kube/config`。建议为 MCP 单独准备一个只读 ServiceAccount 的 kubeconfig，再通过 `KUBECONFIG` 指定。

变更类命令（`kubectl apply/delete`、`helm upgrade`、`terraform apply` 等）由 `settings/settings.project-dev-ops.json` 的 `permissions.ask` 要求人工确认，不依赖 MCP 的只读设置。

## 使用方式

```sh
# 复制为目标项目的 .mcp.json（已存在则提示手动处理；空模板会跳过）
sh scripts/install-dot-mcp.sh -f backend-dev -t /path/to/project

# 强制覆盖（先备份为 .mcp.json.bak.<时间戳>）
sh scripts/install-dot-mcp.sh -f backend-dev -t /path/to/project -F
```

## 新增配置文件

1. 新建 `dot-mcp-json-<FLAG>.json`，先确认对应的 MCP 没有被该场景启用的插件提供
2. 凭据用 `${VAR}` 引用，并在本文件补充变量说明
3. 用 `-f <FLAG>` 参数安装到目标项目
