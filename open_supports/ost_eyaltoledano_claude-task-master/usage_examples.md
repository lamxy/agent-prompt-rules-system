# Taskmaster — 使用示例

> 来源：官方 README / 文档；本文件只保留 open_supports 使用者最常见的入口。

## 快速开始

安装完成后，先在项目里初始化 Taskmaster，再从 PRD 生成任务。

### 初始化当前项目并解析 PRD

适用场景：第一次在某个项目中使用 Taskmaster，并且已经准备好产品需求文档。

```sh
task-master init
task-master parse-prd .taskmaster/docs/prd.txt
task-master list
task-master next
```

预期结果：当前项目出现 `.taskmaster/` 目录；PRD 被解析为任务；`list` 显示任务列表；`next` 给出下一个可执行任务。

注意事项：`task-master init` 和 `parse-prd` 会修改当前项目目录下的 Taskmaster 状态文件。使用本地安装时，把命令改为 `npx task-master ...`。

来源：`repo_readme_summary.md` 第 2、3 部分；官方 README Quick Start。

## 常见场景

### 配置模型和检查 API key 状态

适用场景：已经安装 CLI，但 AI 命令提示缺少模型或 API key。

```sh
task-master models --setup
task-master models
```

预期结果：交互式配置 main、research、fallback 模型；随后显示当前模型和 API key 状态。

注意事项：CLI 使用项目根 `.env` 中的 API keys；MCP 使用 MCP 配置 `env` 区块中的 API keys。不要把 `.env` 或包含真实密钥的 MCP JSON 提交到 git。

来源：`repo_readme_summary.md` 第 2、4 部分；官方配置文档。

### 从 PRD 生成并查看任务

适用场景：PRD 已放在 `.taskmaster/docs/prd.txt`，现在要生成任务并查看下一步。

```sh
task-master parse-prd .taskmaster/docs/prd.txt
task-master list
task-master next
task-master show 1
```

预期结果：Taskmaster 生成任务结构，列出所有任务，选择下一个未被依赖阻塞的任务，并展示任务 1 的细节。

注意事项：`parse-prd` 是 AI 命令，必须有可用 provider；MCP 场景下长任务可能需要把 MCP timeout 调到 300 秒。

来源：`repo_readme_summary.md` 第 3 部分；官方教程。

### 标记任务进度

适用场景：实现过程中需要让 Taskmaster 记录任务状态。

```sh
task-master set-status --id=1 --status=in-progress
task-master set-status --id=1 --status=done
task-master next
```

预期结果：任务 1 状态先变为进行中，再变为完成；`next` 根据依赖和优先级推荐后续任务。

注意事项：状态变化会写入 `.taskmaster/` 中的任务状态文件。团队协作时建议先确认当前 git 工作区状态。

来源：`repo_readme_summary.md` 第 3 部分；官方 examples 文档。

### 拆分复杂任务

适用场景：某个任务太大，需要生成可执行的 subtasks。

```sh
task-master analyze-complexity
task-master expand --id=5
task-master show 5
```

预期结果：Taskmaster 分析任务复杂度，展开任务 5 的子任务，并显示更新后的任务结构。

注意事项：复杂度分析和展开通常会调用 AI provider；如需联网研究能力，可按官方命令加 `--research`，前提是 research 模型和 API key 已配置。

来源：`repo_readme_summary.md` 第 1、3 部分；官方 task structure 与 examples 文档。

### 使用 tags 管理分支或并行工作流

适用场景：同一项目中有多个功能分支、实验线或团队并行工作，需要隔离任务上下文。

```sh
task-master add-tag --from-branch
task-master tags --show-metadata
task-master use-tag feature-auth
task-master list
```

预期结果：Taskmaster 基于当前 git branch 创建 tag，展示 tag 元数据，切换到指定 tag 后列出该上下文的任务。

注意事项：tag 会改变 Taskmaster 当前任务上下文；切换前确认自己要操作的工作流。

来源：官方教程和 examples 文档。

## 与 Agent 客户端配合

### Claude Code MCP：日常使用入口

适用场景：已通过 `claude mcp add ... task-master-ai` 配置 Claude Code MCP，希望通过自然语言让 Agent 操作任务。

```text
Initialize taskmaster-ai in my project
Can you parse my PRD at .taskmaster/docs/prd.txt?
What's the next task I should work on?
Can you help me implement task 3?
```

预期结果：Claude Code 通过 MCP 调用 Taskmaster 工具，完成项目初始化、PRD 解析、任务查询和任务执行辅助。

注意事项：MCP 配置中需要有可用 API keys，或 Taskmaster 项目配置使用 Claude Code / Codex CLI provider 并且对应 CLI 已认证。

来源：`repo_readme_summary.md` 第 2、3 部分；官方 README Quick Start。

### 控制 MCP 工具加载数量

适用场景：Taskmaster MCP 工具占用上下文较多，希望降低 token 使用。

```sh
claude mcp add task-master-ai --scope user \
  --env TASK_MASTER_TOOLS="core" \
  -- npx -y task-master-ai@latest
```

预期结果：Claude Code 注册 Taskmaster MCP server，并把工具加载模式设置为 `core`。

注意事项：官方配置文档说明 `core` / `lean` 只加载核心工具，`standard` 加载常用工具，`all` 加载完整工具集。已有 MCP 配置变更后通常需要重启客户端。

来源：`repo_readme_summary.md` 第 2 部分；官方配置文档。

### 使用 Claude Code provider

适用场景：希望 Taskmaster AI 命令使用本机 Claude Code CLI，而不是 Anthropic API key。

```sh
claude
task-master models --set-main sonnet --claude-code
task-master models
```

预期结果：Claude Code CLI 完成认证；Taskmaster main 模型切到 Claude Code provider；`models` 显示当前配置。

注意事项：官方示例要求 Claude Code CLI 已安装并认证。部分 SDK 参数可能被 Claude Code CLI 忽略，以官方 provider 文档为准。

来源：`repo_readme_summary.md` 第 2、5 部分；官方 Claude Code provider 示例。

### 使用 Codex CLI provider

适用场景：希望 Taskmaster AI 命令使用 Codex CLI 的 OAuth 订阅模型。

```sh
codex login
task-master models --set-main gpt-5-codex --codex-cli
task-master models --set-fallback gpt-5 --codex-cli
task-master models
```

预期结果：Codex CLI 完成 OAuth；Taskmaster main / fallback 模型切到 Codex CLI provider；`models` 显示当前配置。

注意事项：官方配置文档要求 Codex CLI >= 0.42.0，推荐 >= 0.44.0。OAuth 访问依赖可用的 ChatGPT 订阅。

来源：`repo_readme_summary.md` 第 2、5 部分；官方配置文档 Codex CLI Provider 小节。

## 验证与排错

### 最小 CLI 验证

适用场景：确认 npm 安装后的 CLI 能被当前 shell 调用。

```sh
task-master --version
task-master --help
```

预期结果：输出 Taskmaster 版本或 CLI 帮助。

注意事项：本地安装时使用 `npx task-master --version` 和 `npx task-master --help`。

来源：`repo_readme_summary.md` 第 2 部分；`scripts_for_install/install.sh`。

### 检查模型和密钥配置

适用场景：Taskmaster 命令可运行，但 AI 相关命令失败。

```sh
task-master models
```

预期结果：显示 main、research、fallback 模型和 API key 状态。

注意事项：CLI AI 命令需要项目 `.env` 中有对应 key；MCP AI 命令需要 MCP config `env` 中有对应 key。Claude Code / Codex CLI provider 需要本机 CLI 登录状态可用。

来源：官方 README Requirements；官方配置文档。

### MCP 工具显示为 0

适用场景：编辑器 MCP 设置里 Taskmaster server 已存在，但没有可用工具。

```sh
task-master models
```

预期结果：确认项目模型和 key 状态；修正 MCP config 后重启编辑器，工具应重新加载。

注意事项：官方 README 建议遇到 `0 tools enabled` 时重启编辑器，并检查 API keys 是否正确配置。

来源：`repo_readme_summary.md` 第 4 部分；官方 README Quick Start。

### MCP 请求超时

适用场景：`parse_prd`、`expand_task`、`research`、`analyze_project_complexity` 等操作在 60 秒左右失败。

```json
{
  "mcpServers": {
    "task-master-ai": {
      "command": "npx",
      "args": ["-y", "--package=task-master-ai", "task-master-ai"],
      "timeout": 300,
      "env": {
        "ANTHROPIC_API_KEY": "your-anthropic-api-key"
      }
    }
  }
}
```

预期结果：MCP 客户端允许 Taskmaster 长任务运行到 300 秒。

注意事项：真实 API key 应存放在用户自己的安全配置中，不应提交到仓库。

来源：官方配置文档 MCP Timeout Configuration。

### 初始化命令无响应

适用场景：运行 `task-master init` 后没有正常进入初始化流程。

```sh
node node_modules/claude-task-master/scripts/init.js
```

预期结果：直接通过 Node 运行官方初始化脚本。

注意事项：如果是从源码调试，官方 README 还给出 clone 仓库后运行 `node scripts/init.js` 的路径；支持包不默认执行 clone 或源码路径。

来源：`repo_readme_summary.md` 第 4 部分；官方 README Troubleshooting。

## 延伸阅读

- 官方仓库：https://github.com/eyaltoledano/claude-task-master
- 官方文档：https://tryhamster.com/docs/taskmaster
- Quick Start：https://tryhamster.com/docs/taskmaster/getting-started/quick-start/quick-start
- Installation：https://tryhamster.com/docs/taskmaster/getting-started/quick-start/installation
- API Keys & Providers：https://tryhamster.com/docs/taskmaster/getting-started/api-keys
- MCP Tools Reference：https://tryhamster.com/docs/taskmaster/capabilities/mcp
- CLI Commands Reference：https://tryhamster.com/docs/taskmaster/capabilities/cli-root-commands
- Task Structure：https://tryhamster.com/docs/taskmaster/capabilities/task-structure
- Claude Code provider 示例：https://github.com/eyaltoledano/claude-task-master/blob/main/docs/examples/claude-code-usage.md
