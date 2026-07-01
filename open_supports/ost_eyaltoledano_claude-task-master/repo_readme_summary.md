# Taskmaster — 仓库核心介绍

> 官方仓库：[eyaltoledano/claude-task-master](https://github.com/eyaltoledano/claude-task-master)  
> 官方文档：[Taskmaster Docs](https://tryhamster.com/docs/taskmaster)

## 1. 概览

Taskmaster 是面向 AI 驱动开发的任务管理系统，可把 PRD 拆成结构化任务，并通过 CLI 或 MCP 让 AI Agent 查询、扩展、更新和推进任务。

- npm 包名是 `task-master-ai`，CLI 命令是 `task-master`，MCP server 命令可通过 `task-master-ai` 或 `task-master-mcp` 启动。
- 推荐路径是 MCP：在 Cursor、Windsurf、VS Code、Q Developer CLI 或 Claude Code 中注册 `task-master-ai` MCP server，然后用自然语言让 Agent 初始化和操作任务。
- CLI 路径支持 `task-master init`、`parse-prd`、`list`、`next`、`show`、`set-status`、`models`、`research`、`move`、`rules add` 等命令。
- 项目状态存放在 `.taskmaster/` 下；新配置结构使用 `.taskmaster/config.json`，旧 `.taskmasterconfig` 可用 `task-master migrate` 迁移。
- 官方仓库：https://github.com/eyaltoledano/claude-task-master；官方文档：https://tryhamster.com/docs/taskmaster。

## 2. 安装与更新

### 前置依赖

- Node.js >= 20.0.0
- npm / npx
- 使用 Claude Code provider 时，需要 Claude Code CLI 已安装并已登录。
- 使用 Codex CLI provider 时，需要 Codex CLI >= 0.42.0，官方推荐 >= 0.44.0，并通过 `codex login` 完成 OAuth。
- AI 命令至少需要一个可用模型提供方：可使用 Anthropic、OpenAI、Google、Perplexity、xAI、OpenRouter 等 API key；也可使用 Claude Code 或 Codex CLI provider。

检查命令：

```bash
node --version
npm --version
claude --version
codex --version
```

### MCP 安装：Claude Code

官方 README 给出的 Claude Code 快速安装命令：

```bash
claude mcp add taskmaster-ai -- npx -y task-master-ai
```

官方配置文档还给出带工具加载模式的 Claude Code CLI 示例：

```bash
claude mcp add task-master-ai --scope user \
  --env TASK_MASTER_TOOLS="core" \
  -- npx -y task-master-ai@latest
```

自定义工具集合示例：

```bash
claude mcp add task-master-ai --scope user \
  --env TASK_MASTER_TOOLS="get_tasks,next_task,set_task_status" \
  -- npx -y task-master-ai@latest
```

安装后仍需把 API keys 放到项目根 `.env`，或放到 MCP 配置的 `env` 区块中。使用 Claude Code / Codex CLI provider 时可不配置对应 API key，但需本机 CLI 已认证。

### MCP 安装：Cursor 一键安装

官方 README 提供 Cursor 1.0+ 一键安装链接：

```text
https://cursor.com/en/install-mcp?name=task-master-ai&config=...
```

点击后仍需把占位 API keys 替换为真实值。

### MCP 安装：Cursor / Windsurf / Q Developer CLI 手动配置

Linux / macOS 路径：

| Editor | Scope | Path | Key |
| --- | --- | --- | --- |
| Cursor | Global | `~/.cursor/mcp.json` | `mcpServers` |
| Cursor | Project | `<project_folder>/.cursor/mcp.json` | `mcpServers` |
| Windsurf | Global | `~/.codeium/windsurf/mcp_config.json` | `mcpServers` |
| Q CLI | Global | `~/.aws/amazonq/mcp.json` | `mcpServers` |

Windows 路径：

| Editor | Scope | Path | Key |
| --- | --- | --- | --- |
| Cursor | Global | `%USERPROFILE%\.cursor\mcp.json` | `mcpServers` |
| Cursor | Project | `<project_folder>\.cursor\mcp.json` | `mcpServers` |
| Windsurf | Global | `%USERPROFILE%\.codeium\windsurf\mcp_config.json` | `mcpServers` |

官方 JSON 结构：

```json
{
  "mcpServers": {
    "task-master-ai": {
      "command": "npx",
      "args": ["-y", "task-master-ai"],
      "env": {
        "ANTHROPIC_API_KEY": "YOUR_ANTHROPIC_API_KEY_HERE",
        "PERPLEXITY_API_KEY": "YOUR_PERPLEXITY_API_KEY_HERE",
        "OPENAI_API_KEY": "YOUR_OPENAI_KEY_HERE",
        "GOOGLE_API_KEY": "YOUR_GOOGLE_KEY_HERE",
        "MISTRAL_API_KEY": "YOUR_MISTRAL_KEY_HERE",
        "GROQ_API_KEY": "YOUR_GROQ_KEY_HERE",
        "OPENROUTER_API_KEY": "YOUR_OPENROUTER_KEY_HERE",
        "XAI_API_KEY": "YOUR_XAI_KEY_HERE",
        "AZURE_OPENAI_API_KEY": "YOUR_AZURE_KEY_HERE",
        "OLLAMA_API_KEY": "YOUR_OLLAMA_API_KEY_HERE"
      }
    }
  }
}
```

### MCP 安装：VS Code

Linux / macOS 路径：

| Editor | Scope | Path | Key |
| --- | --- | --- | --- |
| VS Code | Project | `<project_folder>/.vscode/mcp.json` | `servers` |

Windows 路径：

| Editor | Scope | Path | Key |
| --- | --- | --- | --- |
| VS Code | Project | `<project_folder>\.vscode\mcp.json` | `servers` |

官方 JSON 结构：

```json
{
  "servers": {
    "task-master-ai": {
      "command": "npx",
      "args": ["-y", "task-master-ai"],
      "env": {
        "ANTHROPIC_API_KEY": "YOUR_ANTHROPIC_API_KEY_HERE",
        "PERPLEXITY_API_KEY": "YOUR_PERPLEXITY_API_KEY_HERE",
        "OPENAI_API_KEY": "YOUR_OPENAI_KEY_HERE",
        "GOOGLE_API_KEY": "YOUR_GOOGLE_KEY_HERE"
      },
      "type": "stdio"
    }
  }
}
```

### CLI 安装

macOS / Linux / WSL / Windows（已安装 Node.js 与 npm）均使用官方 npm 命令：

```bash
# Install globally
npm install -g task-master-ai

# OR install locally within your project
npm install task-master-ai
```

初始化项目：

```bash
# If installed globally
task-master init

# If installed locally
npx task-master init

# Initialize project with specific rules
task-master init --rules cursor,windsurf,vscode
```

### 模型与配置

创建或修复 `.taskmaster/config.json` 的官方命令：

```bash
task-master models --setup
```

迁移旧配置：

```bash
task-master migrate
```

Claude Code provider 示例：

```bash
task-master models --set-main sonnet --claude-code
```

Codex CLI provider 示例：

```bash
task-master models --set-main gpt-5-codex --codex-cli
task-master models --set-fallback gpt-5 --codex-cli
task-master models
```

### 更新命令

全局 CLI 更新：

```bash
npm install -g task-master-ai@latest
```

项目内本地包更新：

```bash
npm install task-master-ai@latest
```

Claude Code MCP 配置更新可重新运行官方 `claude mcp add ... task-master-ai@latest` 命令；使用 `npx -y task-master-ai` / `task-master-ai@latest` 的 MCP server 会在启动时通过 npx 拉取可用版本。

### 验证命令

CLI 可用性：

```bash
task-master --version
task-master --help
```

本地安装可用：

```bash
npx task-master --version
npx task-master --help
```

配置与 API key 状态：

```bash
task-master models
```

项目初始化后验证：

```bash
task-master list
task-master next
```

## 3. 使用示例

CLI 最小路径：

```bash
task-master init
task-master parse-prd .taskmaster/docs/prd.txt
task-master list
task-master next
task-master show 1
task-master set-status --id=1 --status=done
```

这条路径会在当前项目初始化 `.taskmaster/`，从 PRD 生成任务，列出任务，选择下一个可执行任务，查看任务详情，并在完成后更新状态。

MCP 最小路径是在编辑器 AI chat 中说：

```text
Initialize taskmaster-ai in my project
Can you parse my PRD at .taskmaster/docs/prd.txt?
What's the next task I should work on?
Can you help me implement task 3?
```

## 4. 注意事项

- API keys 不应提交到 git；CLI 使用项目根 `.env`，MCP 使用 MCP 配置的 `env` 区块或客户端支持的安全配置。
- 官方文档建议 `.env` 只放 API keys / endpoint，`TASK_MASTER_TOOLS` 这类非 secret 设置优先放 MCP 配置或部署环境变量。
- 如果 MCP 设置页显示 `0 tools enabled`，重启编辑器并检查 API keys 是否正确。
- 长时间 MCP 操作如 `parse_prd`、`expand_task`、`research`、`analyze_project_complexity` 可能超过默认 60 秒 timeout；官方建议在 MCP config 加 `timeout: 300`。
- `task-master init` 不响应时，官方建议用 Node 直接运行初始化脚本，或 clone 仓库后运行 `node scripts/init.js`。
- 许可证是 MIT License with Commons Clause：可使用、修改和分发，但不能销售 Taskmaster 本身、托管 Taskmaster 服务，或基于 Taskmaster 创建竞品。

---

## 5. 补充与延伸

- 完整官方文档入口：https://tryhamster.com/docs/taskmaster
- 安装页：https://tryhamster.com/docs/taskmaster/getting-started/quick-start/installation
- API keys 与 providers：https://tryhamster.com/docs/taskmaster/getting-started/api-keys
- MCP tools 参考：https://tryhamster.com/docs/taskmaster/capabilities/mcp
- CLI commands 参考：https://tryhamster.com/docs/taskmaster/capabilities/cli-root-commands
- Task structure：https://tryhamster.com/docs/taskmaster/capabilities/task-structure
- Claude Code provider 示例：https://github.com/eyaltoledano/claude-task-master/blob/main/docs/examples/claude-code-usage.md
- Codex CLI provider 配置在官方 `docs/configuration.md` 的 "Codex CLI Provider" 小节。
