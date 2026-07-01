# Agency Agents — 使用示例

> 来源：官方 README / 文档；本文件只保留 open_supports 使用者最常见的入口。

## 快速开始

安装完成后，先重启目标 AI 工具，让它重新加载 agent 文件。随后在对话中直接点名已安装的角色。

```text
Use Frontend Developer to review this component.
```

预期结果：目标工具会按已安装的 `Frontend Developer` agent 说明处理请求，或提示该 agent/角色不可用。

来源：`repo_readme_summary.md` 第 3 部分；`skill_for_setup/ost_msitarzewski_agency-agents_install/SKILL.md` 的安装完成提示。

## 常见场景

### 让工程 agent 审查代码

适用场景：已经安装 engineering division，想让对应专业角色参与代码审查、实现建议或问题定位。

```text
Use Backend Developer to review the API changes and call out risks.
```

预期结果：目标工具按 `Backend Developer` agent 的职责生成审查意见。

注意事项：Claude Code 支持完整 agent specification；其他工具通过转换脚本适配，实际能力取决于目标工具支持的 agent/command 格式。

来源：`repo_readme_summary.md` 第 1、3、4 部分。

### 查看官方仓库当前可用 agent

适用场景：准备向团队说明可用角色，或安装后想确认上游 checkout 和 installer 能列出 agent。

```sh
sh scripts_for_install/install.sh --list=agents
```

预期结果：脚本会更新或复用官方 checkout，然后调用上游 installer 输出可用 agent 列表；该命令本身不执行安装。

注意事项：wrapper 仍需要 `git` 和 `bash`，并会维护 `--repo-dir` 指向的官方 checkout 缓存。

来源：`scripts_for_install/install.sh`、`skill_for_setup/README.md`。

### 查看可用 team/division 名称

适用场景：想确认 `engineering`、`frontend` 等名称是否仍被上游 installer 支持，避免后续更新时传错筛选条件。

```sh
sh scripts_for_install/install.sh --list=teams
```

预期结果：输出上游支持的 team/division 名称；该命令本身不执行安装。

来源：`repo_readme_summary.md` 第 2 部分；`skill_for_setup/ost_msitarzewski_agency-agents_install/SKILL.md` 的验证说明。

### 更新前预览将写入的位置

适用场景：多工具安装或项目级工具目录不确定，想在下一次更新前确认写入范围。

```sh
sh scripts_for_install/install.sh --tool=codex --division=engineering --project-dir=/path/to/project --dry-run
```

预期结果：脚本打印上游安装计划，不写入目标工具配置。

注意事项：把 `/path/to/project` 换成实际项目目录；`--dry-run` 用于预览，后续真正更新仍需去掉该参数。

来源：`scripts_for_install/install.sh`、`repo_readme_summary.md` 第 2、4 部分。

## 与 Agent 客户端配合

### Claude Code

适用场景：已安装到 Claude Code，希望确认日常调用方式。

```text
Use Product Manager to refine this feature request.
```

预期结果：重启 Claude Code 后，可在自然语言请求中提到已安装 agent 名称，例如 `Product Manager`、`Frontend Developer` 或 `QA Engineer`。

注意事项：官方摘要没有提供 Claude Code 专用命令行验证命令；若没有生效，先重启 Claude Code，再检查安装目标目录。

来源：`repo_readme_summary.md` 第 1、3 部分；`skill_for_setup/ost_msitarzewski_agency-agents_install/SKILL.md`。

### Codex CLI

适用场景：已为 Codex 安装或转换 Agency Agents，想确认 Codex CLI 本身可用。

```sh
codex --help
```

预期结果：Codex CLI 输出帮助信息。

注意事项：该命令只验证 Codex CLI 可执行；agent 文件是否被正确加载仍取决于 Codex 的配置路径和重启/重载行为。

来源：`repo_readme_summary.md` 第 2、3 部分。

### OpenCode

适用场景：已为 OpenCode 安装 Agency Agents，想查看 OpenCode 侧可见的 agent。

```sh
opencode agent list
```

预期结果：OpenCode 输出可用 agent 列表。

来源：`repo_readme_summary.md` 第 2 部分。

## 验证与排错

### Wrapper 自检

适用场景：安装后怀疑官方 checkout 或上游 installer 不完整，先确认支持包 wrapper 能正常连到上游脚本。

```sh
sh scripts_for_install/install.sh --verify-only
```

预期结果：输出已验证官方 checkout，并确认上游 installer 能响应 `--list tools`。

来源：`scripts_for_install/install.sh`、`skill_for_setup/ost_msitarzewski_agency-agents_install/SKILL.md`。

### 常见失败现象

| 现象 | 处理 |
|------|------|
| `missing required command: git` | 安装 Git 后重试，或按 `repo_readme_summary.md` 第 2 部分选择手动路径。 |
| `missing required command: bash` | 安装 Bash 3.2 或更新版本后重试。 |
| `unsupported platform` | 改用 macOS、Linux、WSL 或 Windows Git Bash/MSYS；桌面应用见延伸阅读。 |
| `checkout has local changes` | 处理 `--repo-dir` 指向 checkout 的本地修改，或换一个新的 `--repo-dir=PATH`。 |
| `--tool must be ...` | 改用 wrapper 白名单内工具名，例如 `claude-code`、`codex`、`opencode`、`cursor`、`gemini-cli`。 |
| 安装后目标工具没有显示 agents | 重启目标 AI 工具；必要时用相同参数加 `--dry-run` 检查目标路径，或用 `--path=PATH` 明确目标目录。 |

来源：`skill_for_setup/ost_msitarzewski_agency-agents_install/SKILL.md` 的 Troubleshooting；`scripts_for_install/install.sh` 的参数校验。

## 延伸阅读

- 主仓库 README：https://github.com/msitarzewski/agency-agents
- 桌面应用文档：https://agencyagents.app/
- 桌面应用 release：https://github.com/msitarzewski/agency-agents-app/releases/latest
- Claude Code 安装、选择性安装、dry-run 与手动安装：https://github.com/msitarzewski/agency-agents
- 多工具转换、目标目录和转换后同步：https://github.com/msitarzewski/agency-agents
