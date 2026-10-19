# open_supports_name_list.txt

`open_supports_name_list.txt` 文件指定了哪些本地化的开源支持包（open source support packages）应被纳入（vendor）基于此模板创建的项目中。

该文件的安装路径为：

```text
.claude/open_supports_name_list.txt
```

安装场景包时，`install-claude-project.sh` 复制清单后会自动安装其中的包。只重装支持包时，从规则源仓库执行：

```sh
sh scripts/install-open-supports.sh -t /path/to/project
```

用户级（全局）支持包不写进场景清单，而是写进 `dot_claude_projects/.claude/open_supports_name_list.txt`，用 `sh scripts/install-claude-project.sh -g` 安装；全局清单中不能出现 `{PROJECT_DIR}`、`--local`、`--location=local`。

## 格式

每一行非空且非注释的内容均遵循以下格式：

```text
<support-name> [install args...]
```

支持的名称格式：

- `OwnerName/RepoName`，例如 `colbymchenry/codegraph`
- `ost_OwnerName_RepoName`，例如 `ost_colbymchenry_codegraph`

支持名称后的参数将传递给该包内包含的 `scripts_for_install/install.*` 脚本。

参数中的 `{PROJECT_DIR}` 会被替换为目标项目的绝对路径。安装脚本在 vendor 后的支持包目录中运行，默认目标 `.` 指向支持包目录而不是项目，所以项目级安装必须带上 `{PROJECT_DIR}`。

版本 1 不支持行内注释，也不支持包含空格的参数值。
请改用整行注释。

## 示例

```text
# 在项目范围内为 Claude Code 安装 CodeGraph。
colbymchenry/codegraph --target=claude --location=local {PROJECT_DIR}

# 在项目范围内为 Claude Code 安装 GSD Core。
open-gsd/gsd-core --claude --local {PROJECT_DIR}

# 内部的 ost_* 名称同样有效。
ost_garrytan_gstack
```