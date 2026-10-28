# PRD 与原型设计 场景包（`.claude-prd-design/`）

用 `sh scripts/install-claude-project.sh -f prd-design -t <项目目录>` 安装。安装脚本只复制本目录的 `.claude/`、`CLAUDE.md`，本文件不会复制到项目中。

## 插件：哪些会自动生效，哪些要手动安装

`.claude/settings.json` 的 `enabledPlugins` 只负责「启用」。按官方说明（<https://code.claude.com/docs/en/plugins/loading>「Enabled in project settings but not installed」），只在项目设定中启用的插件：

- **相对路径来源**的插件：信任项目目录后，从已登记的市场副本自动加载；
- **外部来源**（GitHub、git 子目录、URL、npm）的插件：不会自动下载，`/plugin` 的 Errors 页显示 `enabled in project settings but isn't installed here`，需要手动安装。

下表的来源类型按 2026-10-28 本机市场副本查询；上游调整来源后以 `/plugin` 的 Errors 页为准。

| 插件 | 来源类型 | 打开项目后 |
|------|---------|-----------|
| `playground@claude-plugins-official` | 相对路径（`claude-plugins-official`） | 自动加载 |
| `document-skills@anthropic-agent-skills` | 相对路径（`anthropic-agent-skills`，`anthropics/skills`） | 自动加载：settings 已在 `extraKnownMarketplaces` 声明该市场，信任目录后登记 |
| `mattpocock-skills@claude-plugins-official` | 外部（URL：`mattpocock/skills`） | **需手动安装** |

## 手动安装与恢复

在**项目根目录**执行（已安装的插件会提示已安装并跳过，可重复执行）：

```sh
claude plugin install mattpocock-skills@claude-plugins-official --scope project
# document-skills 为相对路径来源，通常无需手动安装；市场未登记时先执行：
claude plugin marketplace add anthropics/skills --scope project
claude plugin install document-skills@anthropic-agent-skills --scope project
```

一次恢复本场景全部插件（含自动加载的，用于换机器或缓存被清理后）：

```sh
python3 -c 'import json;[print(k) for k,v in json.load(open(".claude/settings.json")).get("enabledPlugins",{}).items() if v]' \
  | while read -r id; do claude plugin install "$id" --scope project; done
```

安装后在会话中执行 `/reload-plugins`，再用 `/plugin` 确认 Errors 页已清空。插件文件下载到 `~/.claude/plugins/`，`--scope project` 只在本项目启用。

## PM Skills

PM Skills 不在 `enabledPlugins` 模板里，由支持包 `phuryn/pm-skills` 以 `--scope project` 安装（见下方「支持包」）。单独恢复：

```sh
claude plugin marketplace add phuryn/pm-skills --scope project
for p in pm-product-discovery pm-product-strategy pm-execution pm-market-research pm-data-analytics; do
  claude plugin install "$p@pm-skills" --scope project
done
```


## gstack

gstack 是全局工具，62 个 skill 在全局 `skillOverrides` 中默认只能手动调用。本场景的 `.claude/settings.json` 把 `gstack-office-hours`、`gstack-plan-ceo-review` 设为 `on`，让 Claude 在需求讨论中可以自动调用。分层理由见 [`settings/README.md`](../../settings/README.md)「工作流框架分层」。

## 本地级可选插件

`settings/settings.local-prd-design.json` 列出需要个人账号或托管服务的可选插件（默认 `false`）：

```sh
sh scripts/install-settings.sh -l local -s prd-design -m ask -p <项目目录>/.claude
```

需要时在 `<项目目录>/.claude/settings.local.json` 把对应插件改为 `true`。按上述官方说明，未纳入 git 的 `settings.local.json` 设为 `true` 的外部来源插件会自动下载；仍未生效时用 `claude plugin install <插件>@claude-plugins-official --scope local` 安装。

## 支持包

`.claude/open_supports_name_list.txt` 中未注释的支持包在安装场景包时自动安装；只重装支持包：

```sh
sh scripts/install-open-supports.sh -t <项目目录>
```

注释掉的条目为第二场景或可选项，取消注释后再执行上面的命令。划分依据见 [`open_supports/INDEX.md`](../../open_supports/INDEX.md)「建议场景」。
