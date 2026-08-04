# CodeGraph — 仓库核心介绍

> **安装作用域（模式 D / 本地为 B）**：`codegraph install --location=global` 配置用户级 Agent；本地配置由 CWD 决定。使用支持包时，本地模式必须传项目目录：`sh scripts_for_install/install.sh --location=local /path/to/project`，脚本会在子 Shell 中切换目录；全局模式为 `sh scripts_for_install/install.sh --global`。`codegraph init [path]` 则原生支持路径参数。依据：[官方 README](https://github.com/colbymchenry/codegraph#installing)。

> 官方仓库：[colbymchenry/codegraph](https://github.com/colbymchenry/codegraph)  
> 官方文档：[colbymchenry.github.io/codegraph](https://colbymchenry.github.io/codegraph/)

## 1. 概览

CodeGraph 是一个为 AI Agent 提供**语义代码智能**的本地 MCP 工具。它在本地预构建代码知识图谱，让 Agent 以单次工具调用获取精准上下文，替代逐文件 grep/read 的低效探索模式。

核心能力：

- **精准上下文**：一次 `codegraph_explore` 返回相关符号源码、调用路径及变更影响范围
- **全文符号搜索**：FTS5 驱动，按名称跨整个代码库即时定位符号
- **影响分析**：变更前追踪调用方、被调用方和完整影响半径
- **自动实时同步**：原生 OS 文件事件驱动，图谱随文件变化即时更新，无需手动维护
- **20+ 语言 · 17 种框架路由 · 100% 本地运行**，无 API Key，无数据外传

---

## 2. 安装与更新

**前置依赖**：无，安装包自带 Node.js 运行时。

### 安装 CLI

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh

# Windows（PowerShell）
irm https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.ps1 | iex
```

> 已有 Node.js 环境也可用 npm：`npm i -g @colbymchenry/codegraph`  
> 安装完成后**重新打开终端**，使 `codegraph` 命令在 PATH 中生效。

### 接入 Agent（每台机器只需一次）

```bash
codegraph install
```

自动检测并配置 Claude Code、Codex CLI、Cursor、opencode 等。  
`--yes` 跳过交互，`--target=claude,codex` 指定目标 Agent，`--location=global/local` 控制作用范围。

### 初始化项目（每个项目执行一次）

```bash
cd your-project
codegraph init
```

创建 `.codegraph/` 目录并构建完整图谱，之后自动增量同步。

### 更新

```bash
codegraph upgrade           # 升级到最新版
codegraph upgrade --check   # 仅检查是否有更新
```

### 验证安装

```bash
codegraph version
codegraph status            # 查看当前项目图谱状态及待同步文件
```

---

## 3. 使用示例

Agent 接入后自动调用 CodeGraph 工具，**在对话中直接提问即可**：

> "How does a request reach the database?"

**CLI 直接查询（不经过 Agent）**：

```bash
# 探索功能流程（返回相关源码 + 调用路径 + 影响范围）
codegraph explore "how does authentication work"

# 读取单个符号或文件（带行号）
codegraph node "UserService.login"
codegraph node "src/auth/service.ts"

# 分析变更影响
codegraph impact "UserService"

# 查找调用方 / 被调用方
codegraph callers "sendEmail"
codegraph callees "sendEmail"
```

---

## 4. 注意事项

- `codegraph install` **只配置 Agent，不索引代码**；每个项目必须单独执行 `codegraph init` 才会建立图谱
- CLI 安装后需**重新打开终端**，PATH 才生效
- Windows 使用 PowerShell 安装；sh 脚本需在 WSL / Git Bash 下执行
- `.codegraph/` 是本地索引目录，建议加入项目 `.gitignore`
- 全局安装（`--location global`）覆盖所有项目，`codegraph install` 只需执行一次；`codegraph init` 仍需在每个项目各执行一次
- 卸载：`codegraph uninstall`（从所有 Agent 移除配置）；`codegraph uninit`（移除单项目索引）

---

## 5. 补充与延伸

- **非交互式安装（CI / 脚本）**：`codegraph install --yes --target=claude,codex --location=global`
- **手动 MCP 配置**（不使用 `codegraph install`）：在 `~/.claude.json` 的 `mcpServers` 中添加 `command: "codegraph" args: ["serve", "--mcp"]`；详见 [README · Manual Setup](https://github.com/colbymchenry/codegraph#quick-start)
- **支持的语言与框架完整列表**：[官方文档](https://colbymchenry.github.io/codegraph/)
- **iOS / React Native 跨语言桥接**（Swift ↔ ObjC、RN Bridge、Expo Modules）：[README · Mixed iOS section](https://github.com/colbymchenry/codegraph#mixed-ios--react-native--expo-bridging)
- **基准测试方法论与原始数据**：[README · Benchmark Results](https://github.com/colbymchenry/codegraph#benchmark-results)
- **完整 CLI 命令参考**：[README · CLI Reference](https://github.com/colbymchenry/codegraph#cli-reference)
