# 多客户端支持

此目录包含适配器，用于让 Claude Code 以外的客户端使用本仓库的代理规则来源。

## 目前状态

目前只实现了 Codex 第一阶段适配器。

Codex 适配器聚焦于指令文件与可选的规则来源内嵌。它不会生成 `.codex/config.toml`、Codex hooks、Codex `.rules`、Codex skills 或 Codex custom agents。

## Codex 适配器

使用 `codex.sh` 从模板生成 Codex-native 指令文件。

```sh
sh scripts/multi_client_support/codex.sh -l <user|project> [-p <target_dir>] [-n <filename>] [-F] [-v]
```

选项：

- `-l user|project`：目标层级。
- `-p <target_dir>`：现有项目目标目录。`project` 必填，`user` 不可使用。
- `-n <filename>`：输出文件名。默认为 `AGENTS.codex.md`。
- `-F`：强制覆盖现有输出文件。搭配 `-v` 时，更新匹配的内嵌文件，同时保留无关的额外文件。
- `-v`：对项目目标，将本仓库的 `.claude/` 目录复制到 `<target>/.agent-rules/claude/`。

示例：

```sh
# 在 ${CODEX_HOME:-$HOME/.codex} 下生成用户层级 Codex 指令
sh scripts/multi_client_support/codex.sh -l user

# 生成项目层级 Codex 指令草稿
sh scripts/multi_client_support/codex.sh -l project -p /path/to/project

# 生成项目指令并内嵌 Claude 规则来源
sh scripts/multi_client_support/codex.sh -l project -p /path/to/project -v

# 直接写入 AGENTS.md
sh scripts/multi_client_support/codex.sh -l project -p /path/to/project -n AGENTS.md -F
```

## 生成的文件

默认项目输出：

```text
target-project/
  AGENTS.codex.md
```

使用 `-v`：

```text
target-project/
  AGENTS.codex.md
  .agent-rules/
    claude/
      CLAUDE.md
      RTK.md
      rules/
      expandable/
      hooks/
      settings.json
      ...
```

此内嵌目录树为摘要示意；`codex.sh` 会递归复制本仓库 `.claude/` 下的所有文件与目录。

`AGENTS.codex.md` 是 Codex-native 入口。内嵌的 `.agent-rules/claude/` 目录是参考材料。除非已另行安装 Codex-native 设定，否则 Claude 专用 settings、hooks、plugins 与 `SendMessage` references 不是生效中的 Codex 执行时设定。

## 验证

运行：

```sh
sh -n scripts/multi_client_support/codex.sh
sh scripts/test-multi-client-codex.sh
```

## 未来方向

未来阶段可能会将选定的 Claude rule intent 转换为 Codex-native config、hooks、command rules、skills 或 custom agents。这些范围刻意不纳入第一阶段。
