# Cognee — 使用示例

> 来源：官方 README / 文档；本文件只保留 open_supports 使用者最常见的入口。

## 快速开始

### 写入并检索一条记忆

适用场景：已经安装 Cognee，并且当前 shell 已设置可用的 LLM / embedding provider 环境变量；想做一次最小端到端验证。

```python
import asyncio
import cognee


async def main():
    # 会清空当前 Cognee 数据和系统状态，只在演示环境或确认可清空时运行。
    await cognee.forget(everything=True)

    await cognee.remember("Cognee turns documents into AI memory.")

    results = await cognee.recall(query_text="What does Cognee do?")
    for result in results:
        print(result.text)


if __name__ == "__main__":
    asyncio.run(main())
```

预期结果：终端输出一段基于刚写入文本的回答，具体措辞会随 provider 和模型变化。

注意事项：`forget(everything=True)` 会清空当前 Cognee 数据；不要在已有重要记忆的环境中直接运行。来源：`repo_readme_summary.md` 第 3 部分。

## 常见场景

### 用 CLI 做 remember / recall 检查

适用场景：安装后确认 `cognee-cli`、provider 配置和本地默认存储都能工作。

```sh
cognee-cli remember "Cognee turns documents into AI memory."
cognee-cli recall "What does Cognee do?"
```

预期结果：第一条命令完成记忆写入；第二条命令返回与 Cognee 用途相关的回答。

注意事项：命令会写入当前 Cognee 默认记忆存储；如果报 provider 或 key 错误，先检查 `LLM_API_KEY` 或对应 provider 环境变量。来源：`scripts_for_install/install.sh` 验证提示、`repo_readme_summary.md` 第 2 部分。

### 启动本地 UI

适用场景：想用本地可视化界面管理或检查 Cognee 记忆，并且 Docker Desktop、Colima 或兼容 OCI runtime 已启动。

```sh
cognee-cli -ui
```

预期结果：Cognee 在 Docker 容器中启动本地 UI / MCP 相关服务；终端会显示启动日志或访问地址。

注意事项：此命令依赖 Docker；Docker daemon 未运行时会失败。来源：`repo_readme_summary.md` 第 2 部分、`skill_for_setup/ost_topoteretes_cognee_install/SKILL.md`。

### 连接 Cognee Cloud 或远程实例

适用场景：Python agent 需要把记忆操作发送到托管 Cognee 实例，而不是只使用本地默认后端。

```python
import asyncio
import cognee


async def main():
    await cognee.serve(url="https://your-instance.cognee.ai", api_key="ck_...")

    await cognee.remember("important context")
    results = await cognee.recall("what happened?")
    for result in results:
        print(result.text)

    await cognee.disconnect()


if __name__ == "__main__":
    asyncio.run(main())
```

预期结果：记忆写入和检索通过远程 Cognee 服务完成，脚本结束前断开连接。

注意事项：示例会向远程实例写入数据；请使用自己的实例 URL 和 API key。来源：`repo_readme_summary.md` 第 2 部分。

### 使用本地 Ollama provider 做记忆检索

适用场景：已按安装文档准备 `cognee[ollama]`，并希望使用本地 Ollama LLM 和 embedding 模型。

```sh
export LLM_PROVIDER="ollama"
export LLM_MODEL="llama3.1:8b"
export LLM_ENDPOINT="http://localhost:11434/v1"
export LLM_API_KEY="ollama"

export EMBEDDING_PROVIDER="ollama"
export EMBEDDING_MODEL="nomic-embed-text:latest"
export EMBEDDING_ENDPOINT="http://localhost:11434/api/embed"
export EMBEDDING_DIMENSIONS="768"

cognee-cli remember "Local models can back Cognee memory."
cognee-cli recall "What can back Cognee memory?"
```

预期结果：Cognee 通过本机 Ollama 服务完成写入和检索，`recall` 返回与本地模型记忆相关的回答。

注意事项：Ollama 服务和模型需要事先可用；`LLM_API_KEY="ollama"` 是 Cognee 需要的非空占位值。来源：`repo_readme_summary.md` 第 2 部分。

## 与 Agent 客户端配合

### 在 Claude Code 插件模式下启动

适用场景：已经按官方插件文档安装 `cognee-memory` 插件，想让 Claude Code 会话使用本地 Cognee 配置。

```sh
export LLM_API_KEY="sk-..."
claude
```

预期结果：Claude Code 启动后，已安装的 Cognee memory 插件可使用本地 provider 配置。

注意事项：本支持包不自动安装插件，也不写入 Claude 配置；远程 Cognee 服务模式使用 `COGNEE_BASE_URL` 和 `COGNEE_API_KEY`。来源：`repo_readme_summary.md` 第 2 部分。

### 启动 MCP HTTP transport 供 Agent 客户端连接

适用场景：需要给支持 MCP 的 Agent 客户端暴露 Cognee MCP server，并且已准备好 `.env` 与 Docker。

```sh
docker run \
  -e TRANSPORT_MODE=http \
  --env-file ./.env \
  -p 8000:8000 \
  --rm -it cognee/cognee-mcp:main
```

预期结果：MCP server 以 HTTP transport 启动，并监听容器映射出的本地端口。

注意事项：这是运行容器的命令，会读取当前目录 `.env`；具体 MCP 客户端配置键请按对应客户端文档填写。来源：`repo_readme_summary.md` 第 2 部分。

### 让 Codex 或 Claude Code 调用本支持包 Skill

适用场景：已经把 open_supports 包放在项目中，需要由 Agent 执行安装后验证或重新运行安装 Skill。

```sh
sh open_supports/ost_topoteretes_cognee/scripts_for_install/install.sh --dry-run
```

预期结果：脚本只打印平台、Python、安装位置、包规格和包管理器选择，不修改环境。

注意事项：真正安装或更新时去掉 `--dry-run`；脚本不会自动创建 `.env`、Docker、Claude、Agent 或 MCP 配置。来源：`skill_for_setup/README.md`、`skill_for_setup/ost_topoteretes_cognee_install/SKILL.md`。

## 验证与排错

### 验证 Python import

适用场景：确认当前解释器能导入 Cognee。

```sh
python -c 'import cognee; print("Cognee import OK:", cognee.__file__)'
```

预期结果：输出 `Cognee import OK:` 和当前解释器加载到的 `cognee` 路径。

注意事项：如果安装在本地 `.venv`，请先激活虚拟环境，或直接使用 `.venv/bin/python`。来源：`scripts_for_install/install.sh`、`skill_for_setup/ost_topoteretes_cognee_install/SKILL.md`。

### provider 或 API key 报错

适用场景：`remember` / `recall` 失败，错误信息指向 provider、model、API key 或 embedding 配置。

```sh
env | grep -E '^(LLM|EMBEDDING|HUGGINGFACE)_'
```

预期结果：能看到当前 shell 中已设置的 Cognee provider 相关变量。

注意事项：不要把命令输出中的真实 API key 粘贴到 issue、日志或聊天中；切换 LLM provider 时也要确认 embedding provider 是否符合预期。来源：`repo_readme_summary.md` 第 4 部分。

### `cognee-cli -ui` 启动失败

适用场景：本地 UI 无法启动，或错误信息指向 Docker / daemon / runtime。

```sh
docker info
docker run --rm hello-world
```

预期结果：`docker info` 能打印 server 信息，`hello-world` 能成功运行。

注意事项：Docker 容器内的 `localhost` 指向容器自身；Linux / Colima 网络场景可能需要额外网络配置。来源：`repo_readme_summary.md` 第 2、4 部分。

### `cognee-cli` 不在 PATH

适用场景：安装成功但 shell 提示 `cognee-cli: command not found`。

```sh
. .venv/bin/activate
.venv/bin/cognee-cli recall "What does Cognee do?"
```

预期结果：使用本地虚拟环境中的 CLI 执行 recall；如果没有写入过记忆，返回内容可能为空或提示没有相关结果。

注意事项：用户级安装时需要确认 Python user base bin 目录在 PATH 中；本地安装优先使用虚拟环境路径。来源：`scripts_for_install/install.sh`、`skill_for_setup/ost_topoteretes_cognee_install/SKILL.md`。

## 延伸阅读

- 快速开始：https://docs.cognee.ai/getting-started/quickstart
- 安装与 provider 配置：https://docs.cognee.ai/getting-started/installation
- LLM provider 配置：https://docs.cognee.ai/setup-configuration/llm-providers
- Embedding provider 配置：https://docs.cognee.ai/setup-configuration/embedding-providers
- MCP server README：https://github.com/topoteretes/cognee/blob/main/cognee-mcp/README.md
- Claude Code 插件：https://github.com/topoteretes/cognee-integrations/tree/main/integrations/claude-code
- Docker / Colima 排错：https://github.com/topoteretes/cognee/blob/main/docs/docker-colima-setup.md
- 示例目录：https://github.com/topoteretes/cognee/tree/main/examples
