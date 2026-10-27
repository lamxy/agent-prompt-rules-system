# DevOps 场景包（`.claude-dev-ops/`）

用 `sh scripts/install-claude-project.sh -f dev-ops -t <项目目录>` 安装。安装脚本只复制本目录的 `.claude/`、`.mcp.json`、`CLAUDE.md`，本文件不会复制到项目中。

## 插件：哪些会自动生效，哪些要手动安装

`.claude/settings.json` 的 `enabledPlugins` 只负责「启用」。按官方说明（<https://code.claude.com/docs/en/plugins/loading>「Enabled in project settings but not installed」），只在项目设定中启用的插件：

- **相对路径来源**的插件：信任项目目录后，从已登记的市场副本自动加载；
- **外部来源**（GitHub、git 子目录、URL、npm）的插件：不会自动下载，`/plugin` 的 Errors 页显示 `enabled in project settings but isn't installed here`，需要手动安装。

下表的来源类型按 2026-10-28 本机市场副本查询；上游调整来源后以 `/plugin` 的 Errors 页为准。

| 插件 | 来源类型 | 打开项目后 |
|------|---------|-----------|
| `terraform@claude-plugins-official` | 相对路径（`claude-plugins-official` 的 `external_plugins/terraform`） | 自动加载 |
| `pr-review-toolkit@claude-plugins-official` | 相对路径（`claude-plugins-official`） | 自动加载 |
| `semgrep@claude-plugins-official` | 外部（git 子目录：`semgrep/mcp-marketplace`） | **需手动安装** |
| `sonatype-guide@claude-plugins-official` | 外部（URL：`sonatype/sonatype-guide-claude-plugin`） | **需手动安装** |

## 手动安装与恢复

在**项目根目录**执行（已安装的插件会提示已安装并跳过，可重复执行）：

```sh
claude plugin install semgrep@claude-plugins-official --scope project
claude plugin install sonatype-guide@claude-plugins-official --scope project
```

一次恢复本场景全部插件（含自动加载的，用于换机器或缓存被清理后）：

```sh
python3 -c 'import json;[print(k) for k,v in json.load(open(".claude/settings.json")).get("enabledPlugins",{}).items() if v]' \
  | while read -r id; do claude plugin install "$id" --scope project; done
```

安装后在会话中执行 `/reload-plugins`，再用 `/plugin` 确认 Errors 页已清空。插件文件下载到 `~/.claude/plugins/`，`--scope project` 只在本项目启用。

## MCP 服务器

`.mcp.json` 中的 `glitchtip` 首次打开项目时需确认启用，并在启动 `claude` 前设置 `GLITCHTIP_URL`；状态用 `/mcp` 查看。


## 本地级可选插件

`settings/settings.local-dev-ops.json` 列出需要个人账号或托管服务的可选插件（默认 `false`）：

```sh
sh scripts/install-settings.sh -l local -s dev-ops -m ask -p <项目目录>/.claude
```

需要时在 `<项目目录>/.claude/settings.local.json` 把对应插件改为 `true`。按上述官方说明，未纳入 git 的 `settings.local.json` 设为 `true` 的外部来源插件会自动下载；仍未生效时用 `claude plugin install <插件>@claude-plugins-official --scope local` 安装。

## 支持包

`.claude/open_supports_name_list.txt` 中未注释的支持包在安装场景包时自动安装；只重装支持包：

```sh
sh scripts/install-open-supports.sh -t <项目目录>
```

注释掉的条目为第二场景或可选项，取消注释后再执行上面的命令。划分依据见 [`open_supports/INDEX.md`](../../open_supports/INDEX.md)「建议场景」。
