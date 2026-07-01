# Cognee — 仓库核心介绍

> 官方仓库：[topoteretes/cognee](https://github.com/topoteretes/cognee)
> 官方文档：[Cognee Documentation](https://docs.cognee.ai/)

## 1. 概览

Cognee 是面向 AI Agent 的开源长期记忆平台：把文档、会话和业务数据转成可检索、可推理、可自托管的知识图谱与向量记忆层。

核心能力：

- 使用 `remember` / `recall` / `forget` / `improve` 管理长期记忆、会话记忆和图谱增强。
- 默认本地运行，基础安装使用 SQLite、LanceDB、Kuzu，无需额外数据库服务。
- 支持 OpenAI、Gemini、Anthropic、Ollama、Groq、Mistral 等 LLM / embedding 配置。
- 可切换 Postgres、Neo4j、Neptune、Redis、S3、OpenTelemetry 等后端和集成。
- 提供 Python 包、CLI、本地 UI / MCP、Docker 镜像、Claude Code 插件、Rust 与 TypeScript 客户端。

官方入口：

- 仓库：https://github.com/topoteretes/cognee
- 安装文档：https://docs.cognee.ai/getting-started/installation
- 快速开始：https://docs.cognee.ai/getting-started/quickstart
- MCP README：https://github.com/topoteretes/cognee/blob/main/cognee-mcp/README.md

## 2. 安装与更新

### 前置依赖

- Python **3.10 - 3.14**。
- 默认 OpenAI 路径需要可用的 `LLM_API_KEY`。
- `cognee-cli -ui` 会在 Docker 容器中启动 MCP server，因此需要 Docker Desktop、Colima 或其他可用的 OCI runtime，并且 `docker` CLI 可用。
- 从源码运行 `cognee-mcp` 的可视化 / workspace UI bundle 时需要 Node.js。
- Windows 推荐使用 PowerShell 或 CMD 的专用激活命令，不使用 `source`。

### 虚拟环境

macOS / Linux shell：

```bash
uv venv && source .venv/bin/activate
```

```bash
python -m venv .venv
source .venv/bin/activate
```

WSL shell（官方未给 WSL 专用命令；在 WSL 的 Linux shell 中使用官方 shell 命令）：

```bash
uv venv && source .venv/bin/activate
```

```bash
python -m venv .venv
source .venv/bin/activate
```

Windows PowerShell：

```powershell
uv venv
.\.venv\Scripts\Activate.ps1
```

如遇执行策略错误：

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Windows Command Prompt：

```cmd
uv venv
.venv\Scripts\activate.bat
```

Windows 安装 `uv`：

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

若 `pip install uv` 后 `uv` 不在 PATH：

```powershell
python -m uv pip install cognee
```

### Python 包安装：OpenAI 默认路径

`.env`：

```bash
LLM_API_KEY="your_openai_api_key"
```

安装：

```bash
# Standard pip
pip install cognee

# Or with uv
uv pip install cognee
```

README 快速安装命令：

```bash
uv pip install cognee
```

### Python 包安装：其他 Provider

Gemini 示例 `.env`：

```bash
# LLM
LLM_PROVIDER="gemini"
LLM_MODEL="gemini/gemini-flash-latest"
LLM_API_KEY="your_gemini_api_key"

# Embeddings
EMBEDDING_PROVIDER="gemini"
EMBEDDING_MODEL="gemini/gemini-embedding-001"
EMBEDDING_API_KEY="your_gemini_api_key"
```

Provider 相关安装：

| Provider path | Install command |
| --- | --- |
| Gemini through Google AI Studio | No extra package |
| Gemini through Vertex AI | `uv pip install google-cloud-aiplatform` |
| Anthropic | `uv pip install "cognee[anthropic]"` |
| Ollama | `uv pip install "cognee[ollama]"` |
| Groq | `uv pip install "cognee[groq]"` |
| Mistral | `uv pip install "cognee[mistral]"` |

### Python 包安装：Ollama 本地路径

`.env`：

```bash
# LLM — Ollama
LLM_PROVIDER="ollama"
LLM_MODEL="llama3.1:8b"
LLM_ENDPOINT="http://localhost:11434/v1"
LLM_API_KEY="ollama"

# Embeddings — Ollama
EMBEDDING_PROVIDER="ollama"
EMBEDDING_MODEL="nomic-embed-text:latest"
EMBEDDING_ENDPOINT="http://localhost:11434/api/embed"
EMBEDDING_DIMENSIONS="768"
HUGGINGFACE_TOKENIZER="nomic-ai/nomic-embed-text-v1.5"  # optional, recommended for accurate token counting
```

安装并拉取模型：

```bash
uv pip install "cognee[ollama]"
ollama pull llama3.1:8b
ollama pull nomic-embed-text:latest
```

### Python extras

通用 extras 安装格式：

```bash
pip install "cognee[extra1,extra2]"
# or with uv:
uv pip install "cognee[extra1,extra2]"
```

常见组合：

| Use case | Install |
| --- | --- |
| PostgreSQL as the database backend | `uv pip install "cognee[postgres]"` |
| Neo4j graph store + AWS S3 storage | `uv pip install "cognee[neo4j,aws]"` |
| Distributed execution on Modal | `uv pip install "cognee[distributed]"` |
| Code graph analysis | `uv pip install "cognee[codegraph]"` |
| OpenTelemetry tracing | `uv pip install "cognee[tracing]"` |
| Web scraping + extended document formats | `uv pip install "cognee[scraping,docs]"` |
| BAML structured output backend | `uv pip install "cognee[baml]"` |
| Anthropic Claude models | `uv pip install "cognee[anthropic]"` |

Postgres-only README 命令：

```bash
pip install "cognee[postgres]"
```

### CLI / 本地 UI

CLI 示例：

```bash
cognee-cli remember "Cognee turns documents into AI memory."

cognee-cli recall "What does Cognee do?"

cognee-cli forget --all
```

打开本地 UI：

```bash
cognee-cli -ui
```

### Docker：Compose 从源码启动

```bash
cp .env.template .env   # then edit .env and set LLM_API_KEY

# Start the API server (http://localhost:8000)
docker compose up

# Optional profiles (combine as needed):
docker compose --profile ui up        # + frontend on http://localhost:3000
docker compose --profile mcp up       # + MCP server on http://localhost:8001
docker compose --profile postgres up  # + Postgres/PGVector
docker compose --profile neo4j up     # + Neo4j
```

### Docker：预构建镜像

```bash
# Create a minimal .env in the current directory
echo 'LLM_API_KEY="YOUR_OPENAI_API_KEY"' > .env

# API server
docker run --env-file ./.env -p 8000:8000 --rm -it cognee/cognee:main

# MCP server (HTTP transport)
docker pull cognee/cognee-mcp:main
docker run -e TRANSPORT_MODE=http --env-file ./.env -p 8000:8000 --rm -it cognee/cognee-mcp:main
```

### MCP server：源码运行

```bash
git clone https://github.com/topoteretes/cognee.git
```

```bash
cd cognee/cognee-mcp
```

```bash
pip install uv
```

```bash
uv sync --dev --all-extras --reinstall
```

```bash
source .venv/bin/activate
```

```bash
LLM_API_KEY="YOUR_OPENAI_API_KEY"
```

可选 UI bundle：

```bash
cd apps-src && npm install && npm run build && cd ..
```

运行 stdio / SSE / HTTP transport：

```bash
python src/server.py
```

```bash
python src/server.py --transport sse
```

```bash
python src/server.py --transport http --host 127.0.0.1 --port 8000 --path /mcp
```

### MCP server：Docker

本地构建：

```bash
docker rmi cognee/cognee-mcp:main || true
docker build --no-cache -f cognee-mcp/Dockerfile -t cognee/cognee-mcp:main .
```

运行：

```bash
# For HTTP transport (recommended for web deployments)
docker run -e TRANSPORT_MODE=http --env-file ./.env -p 8000:8000 --rm -it cognee/cognee-mcp:main
# For SSE transport
docker run -e TRANSPORT_MODE=sse --env-file ./.env -p 8000:8000 --rm -it cognee/cognee-mcp:main
# For stdio transport (default)
docker run -e TRANSPORT_MODE=stdio --env-file ./.env --rm -it cognee/cognee-mcp:main
```

预构建 MCP 镜像：

```bash
# Pull the prebuilt image
docker pull cognee/cognee-mcp:main

# Create a minimal .env in the current directory (no repo checkout required)
echo 'LLM_API_KEY="YOUR_OPENAI_API_KEY"' > .env
```

```bash
# With HTTP transport (recommended for web deployments)
docker run -e TRANSPORT_MODE=http --env-file ./.env -p 8000:8000 --rm -it cognee/cognee-mcp:main
# With SSE transport
docker run -e TRANSPORT_MODE=sse --env-file ./.env -p 8000:8000 --rm -it cognee/cognee-mcp:main
# With stdio transport (default)
docker run -e TRANSPORT_MODE=stdio --env-file ./.env --rm -it cognee/cognee-mcp:main
```

MCP Docker runtime extras：

```bash
# Install a single optional dependency group at runtime
docker run \
  -e TRANSPORT_MODE=http \
  -e EXTRAS=aws \
  --env-file ./.env \
  -p 8000:8000 \
  --rm -it cognee/cognee-mcp:main

# Install multiple optional dependency groups at runtime (comma-separated)
docker run \
  -e TRANSPORT_MODE=sse \
  -e EXTRAS=aws,postgres,neo4j \
  --env-file ./.env \
  -p 8000:8000 \
  --rm -it cognee/cognee-mcp:main
```

### Claude Code 插件

安装：

```bash
# Add the marketplace and install the plugin (one-time, user-scoped)
claude plugin marketplace add topoteretes/cognee-integrations
claude plugin install cognee-memory@cognee

# Set env vars for your mode (see below), then launch
export LLM_API_KEY="sk-..."   # local mode; or COGNEE_BASE_URL + COGNEE_API_KEY for cloud
claude
```

本地模式：

```bash
export LLM_API_KEY="sk-..."
```

Cognee Cloud / 远程服务：

```bash
export COGNEE_BASE_URL="https://your-instance.cognee.ai"
export COGNEE_API_KEY="ck_..."
```

### Cognee Cloud

Python agent 连接托管实例：

```python
import cognee

await cognee.serve(url="https://your-instance.cognee.ai", api_key="ck_...")

await cognee.remember("important context")
results = await cognee.recall("what happened?")

await cognee.disconnect()
```

### Rust / TypeScript 客户端

Rust：

```bash
cargo add cognee
```

TypeScript：

```bash
npm install @cognee/cognee-ts
```

### 更新命令

官方 README 与安装文档没有给出专用更新命令；本文不推导 `pip` / `uv` / Docker tag 的更新命令。下游安装脚本如需更新逻辑，应在执行前重新核对官方安装页或对应包管理器 / 镜像标签策略。

### 验证命令

Python import 验证：

```powershell
python -c "import cognee; print(cognee.__file__)"
```

```cmd
python -c "import cognee; print(cognee.__file__)"
```

Docker daemon 验证：

```bash
docker info   # Should print server information without errors
docker run --rm hello-world
```

## 3. 使用示例

最小可运行示例来自官方 Quickstart，用于验证 `remember` 写入记忆、`recall` 从记忆检索：

```python
import cognee
import asyncio

async def main():
    # Create a clean slate for cognee -- reset data and system state
    await cognee.forget(everything=True)

    # Store content in memory (ingests, builds knowledge graph, enriches)
    text = "Cognee turns documents into AI memory."
    await cognee.remember(text)

    # Retrieve from memory
    results = await cognee.recall(
        query_text="What does Cognee do?"
    )

    # Print
    for result in results:
        print(result.text)

if __name__ == '__main__':
    asyncio.run(main())
```

成功后输出应基于刚写入的文本回答 Cognee 的用途；具体措辞会随 provider 和模型变化。

## 4. 注意事项

- Cognee 大量 API 是 async，需要在 `async def` 中使用 `await`，并用 `asyncio.run(...)` 启动示例。
- 默认 OpenAI 路径会同时用 `LLM_API_KEY` 处理 LLM 和 embeddings；切换 LLM provider 但未配置 embedding provider 时，embeddings 仍默认走 OpenAI。
- Ollama 本地模式中 `LLM_API_KEY="ollama"` 是必需占位值；Ollama 会忽略该值，但 Cognee 要求非空。
- Windows 中 `.env` 的路径值应使用正斜杠或双反斜杠；单反斜杠不是有效 `.env` 值。
- Windows 常见 `ModuleNotFoundError: No module named 'cognee'` 通常是终端、IDE 或脚本未使用 `.venv` 解释器。
- `cognee-cli -ui` 依赖 Docker；Docker Desktop、Colima 或兼容 runtime 未启动时会失败。
- Docker 容器内的 `localhost` 指向容器自身；MCP entrypoint 会尝试把 host API 地址改写到可达 host 地址，但 Linux / Colima 网络仍可能需要额外配置。
- MCP Docker 使用环境变量（如 `-e TRANSPORT_MODE=http`），直接 Python 使用命令行参数（如 `python src/server.py --transport http`），两者不要混用。

---

## 5. 补充与延伸

- 安装与 provider 配置详表：https://docs.cognee.ai/getting-started/installation
- LLM provider 配置：https://docs.cognee.ai/setup-configuration/llm-providers
- Embedding provider 配置：https://docs.cognee.ai/setup-configuration/embedding-providers
- 快速开始示例：https://docs.cognee.ai/getting-started/quickstart
- Docker / Colima 依赖与排错：https://github.com/topoteretes/cognee/blob/main/docs/docker-colima-setup.md
- MCP server SSE / stdio / HTTP、Docker extras、API mode：https://github.com/topoteretes/cognee/blob/main/cognee-mcp/README.md
- Claude Code 插件：https://github.com/topoteretes/cognee-integrations/tree/main/integrations/claude-code
- Rust 客户端：https://github.com/topoteretes/cognee-rs
- TypeScript 客户端：https://www.npmjs.com/package/@cognee/cognee-ts
- `.env` 模板：https://github.com/topoteretes/cognee/blob/main/.env.template
- 示例目录：https://github.com/topoteretes/cognee/tree/main/examples
- 部署脚本目录：https://github.com/topoteretes/cognee/tree/main/distributed
