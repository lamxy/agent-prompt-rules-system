# 手动 smoke 测试

本目录的脚本需要本机已登录的 `claude` CLI，有的会调用模型，所以**不放进** `scripts/tests/run-all.sh`，按需手动执行。都在临时目录中安装场景包后运行，不改动本机配置；临时目录退出时删除。

| 脚本 | 验证什么 | 成本与副作用 | 何时跑 |
|---|---|---|---|
| `claude-config-smoke.sh [FLAG ...]` | 在每个场景的临时安装中执行 `claude mcp list`：`.mcp.json` 的服务器都列为 Pending approval（新项目未批准，不连接），没有 `.mcp.json` 的场景不出现项目服务器，诊断中没有 `[Error]`，也没有「缺少环境变量」以外的警告 | 不调用模型、不耗 token；会对你的用户级与插件 MCP 做健康检查（联网）；每个场景约 4 秒 | 改了 `.mcp.json`、`dot_mcp_jsons/` 或升级 Claude Code 后 |

脚本支持 `SCENARIO_BUNDLES=<目录>` 改用其他场景包来源，用于确认检查能发现问题。

最近一次结果记在 `docs/evaluation/2026-10-final.md` 第 5 节。
