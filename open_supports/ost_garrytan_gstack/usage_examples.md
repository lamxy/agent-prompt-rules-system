# gstack — 使用示例

> 来源：官方 README / 文档；本文件只保留 open_supports 使用者最常见的入口。

## 快速开始

安装完成并重启目标 Agent 后，先从产品讨论开始，再把产物交给评审或实现流程。

### 从产品 office hours 开始

适用场景：已经安装 gstack，现在要为一个新功能或产品方向生成可被后续技能读取的设计上下文。

```text
/office-hours
```

预期结果：gstack 会围绕目标、用户、约束和范围提问，并产出后续 `/plan-ceo-review`、`/review` 等技能可读取的设计文档或讨论上下文。

来源：`repo_readme_summary.md` 第 1、3 部分；官方 README：https://github.com/garrytan/gstack

## 常见场景

### 做 CEO / 范围评审

适用场景：已经通过 `/office-hours` 或手写文档整理了产品计划，需要从战略、范围和取舍角度审查。

```text
/plan-ceo-review
```

预期结果：gstack 读取现有设计上下文并给出计划评审，帮助识别范围、定位、优先级和风险问题。

来源：`repo_readme_summary.md` 第 1、3 部分；官方 README：https://github.com/garrytan/gstack

### 审查当前分支改动

适用场景：当前项目已有代码改动，需要让 gstack 做代码审查并处理明显问题。

```text
/review
```

预期结果：gstack 检查当前工作区或分支改动，自动修复明显问题，并标出需要用户判断的事项。

注意事项：该命令可能读取并修改当前项目代码。执行前建议确认 git 工作区状态。

来源：`repo_readme_summary.md` 第 1、3 部分；官方 README：https://github.com/garrytan/gstack

### 对 staging URL 做浏览器 QA

适用场景：功能已经部署到可访问的测试环境，需要 gstack 用真实浏览器检查页面和交互。

```text
/qa https://staging.myapp.com
```

预期结果：gstack 打开 Chromium 测试指定 URL，记录发现的问题；在可修复范围内可能修复问题并生成回归测试。

注意事项：该命令会访问指定 URL，并可能依赖浏览器构建和登录态配置。不要把生产管理页面或敏感环境 URL 当作无风险示例运行。

来源：`repo_readme_summary.md` 第 1、3、4 部分；浏览器说明：https://github.com/garrytan/gstack/blob/main/BROWSER.md

### 构建功能的端到端流程

适用场景：希望 gstack 先规划，再协助实现，最后进入发布前检查。

```text
/autoplan
/ship
```

预期结果：`/autoplan` 生成实现计划并推动实现；`/ship` 进入交付前检查、整理和发布准备流程。

注意事项：这些命令可能修改当前项目代码、测试和文档。执行前确认当前分支和未提交改动。

来源：`repo_readme_summary.md` 第 1、2 部分；`skill_for_setup/ost_garrytan_gstack_install/SKILL.md`

### 记录项目经验

适用场景：完成一轮工作后，希望让 gstack 保留偏好、工程经验或项目约定，供后续会话使用。

```text
/learn
```

预期结果：gstack 将重要经验写入其记忆路径；如已配置 GBrain，可结合 GBrain 集成做跨会话记忆。

注意事项：记忆同步范围取决于本地 gstack / GBrain 配置；不要记录密钥、私有凭据或不应共享的项目细节。

来源：`repo_readme_summary.md` 第 1、2、4 部分；GBrain 文档：https://github.com/garrytan/gstack/blob/main/USING_GBRAIN_WITH_GSTACK.md

## 与 Agent 客户端配合

### Claude Code

适用场景：使用 gstack 的主要客户端，并希望 Claude Code 在日常工作中优先使用 gstack 技能。

```text
/office-hours
/review
/qa https://example.com
```

预期结果：Claude Code 识别 gstack slash commands，并按对应技能进入产品讨论、代码审查或浏览器 QA。

注意事项：如果 Claude Code 看不到技能，重启会话；仍不可见时，按安装摘要把 upstream `## gstack` 指引和可用技能列表加入项目 `CLAUDE.md`。

来源：`repo_readme_summary.md` 第 2、3 部分；`skill_for_setup/ost_garrytan_gstack_install/SKILL.md`

### Codex CLI 或其他 supported host

适用场景：已经用支持包安装脚本为非 Claude host 安装 gstack，需要确认该 host 加载了技能。

```sh
sh scripts_for_install/install.sh --host=codex
```

预期结果：脚本更新或克隆 gstack，运行官方 `./setup --host codex`，并提示重启 Codex 后确认 gstack skills 是否出现。

注意事项：把 `codex` 替换为 wrapper 支持的 host：`opencode`、`factory`、`kiro` 或 `auto`。`cursor`、`slate` 会被提前拒绝；`openclaw`、`hermes`、`gbrain` 应走各自的 artifact-generation 或 session workflow。该命令会写入目标 Agent 的技能目录。

来源：`repo_readme_summary.md` 第 2 部分；`scripts_for_install/install.sh`

### OpenClaw

适用场景：OpenClaw agent 需要把编码任务委托给 Claude Code 会话，或使用 ClawHub 原生 gstack 方法论技能。

```text
Load gstack. Run /review
Load gstack. Run /qa https://...
Load gstack. Run /autoplan, implement the plan, then run /ship
```

预期结果：OpenClaw 启动或指示 Claude Code 会话加载 gstack，并运行对应工作流。

注意事项：OpenClaw 集成是 prompt/template 与 native skills，不需要额外 daemon 或 JSON-RPC 协议。

来源：`repo_readme_summary.md` 第 2、4、5 部分；OpenClaw 文档：https://github.com/garrytan/gstack/blob/main/docs/OPENCLAW.md

## 验证与排错

### 最小可用性验证

适用场景：安装完成后确认目标 Agent 已经加载 gstack。

```text
/office-hours
```

预期结果：目标 Agent 识别命令并开始产品 office hours 对话。

注意事项：安装后通常需要重启目标 Agent 或开始新会话。

来源：`repo_readme_summary.md` 第 2、3 部分；`skill_for_setup/ost_garrytan_gstack_install/SKILL.md`

### 重新运行官方 setup

适用场景：Claude Code 看不到技能，或 Windows 无 Developer Mode 环境中手动 `git pull` 后需要刷新复制出来的文件。

```sh
cd ~/.claude/skills/gstack && ./setup
```

预期结果：官方 setup 重新执行，目标客户端的 gstack 技能目录和配置恢复到可加载状态。

注意事项：这是恢复 / 确认动作，不是独立 `--version` 或 `doctor` 命令；gstack 官方摘要未提供单独版本检查命令。

来源：`repo_readme_summary.md` 第 2、4 部分；`skill_for_setup/ost_garrytan_gstack_install/SKILL.md`

### 浏览器能力构建失败

适用场景：`/browse`、`/qa` 或浏览器相关命令失败，怀疑依赖或构建产物不完整。

```sh
cd ~/.claude/skills/gstack && bun install && bun run build
```

预期结果：Bun 安装依赖并完成浏览器相关构建；之后重启 Agent 再运行 `/qa https://example.com`。

注意事项：Windows / WSL 场景还需要 Node.js 在 `PATH` 上，因为官方说明浏览器 fallback 需要 Node.js。

来源：`repo_readme_summary.md` 第 2、4 部分；`skill_for_setup/ost_garrytan_gstack_install/SKILL.md`

### 安装目录不是 git checkout

适用场景：支持包安装脚本报错：目标安装目录已存在但不是 git checkout。

```sh
sh scripts_for_install/install.sh --install-dir="$HOME/gstack"
```

预期结果：脚本在指定目录克隆或更新官方 gstack 仓库，然后运行官方 setup。

注意事项：不要自动删除已有目录；先移动或选择新的 `--install-dir`。该命令会写入指定安装目录和目标 Agent 技能目录。

来源：`scripts_for_install/install.sh`；`skill_for_setup/ost_garrytan_gstack_install/SKILL.md`

### Git 网络超时或代理环境

适用场景：clone 或 pull 因网络延迟失败，或运行环境需要代理。

```sh
GSTACK_GIT_TIMEOUT_SECONDS=180 sh scripts_for_install/install.sh --host=codex
```

预期结果：脚本以非交互方式运行 Git，并在可用时使用 timeout/gtimeout；失败信息包含 clone/pull、安装目录、timeout 和 exit code。

注意事项：`GSTACK_GIT_TIMEOUT_SECONDS` 只能是正十进制整数。已导出的 `HTTP_PROXY`、`HTTPS_PROXY`、`NO_PROXY` 等变量会继承给 Git 和 upstream `./setup`；Docker 测试必须显式注入这些变量。

## 延伸阅读

- 官方 README：https://github.com/garrytan/gstack
- 浏览器能力说明：https://github.com/garrytan/gstack/blob/main/BROWSER.md
- 架构与 prompt injection defense：https://github.com/garrytan/gstack/blob/main/ARCHITECTURE.md
- OpenClaw 集成：https://github.com/garrytan/gstack/blob/main/docs/OPENCLAW.md
- 新增 Agent host：https://github.com/garrytan/gstack/blob/main/docs/ADDING_A_HOST.md
- GBrain 集成：https://github.com/garrytan/gstack/blob/main/USING_GBRAIN_WITH_GSTACK.md
- 版本变化：https://github.com/garrytan/gstack/blob/main/CHANGELOG.md
