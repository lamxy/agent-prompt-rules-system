# open_supports_name_list.txt

`open_supports_name_list.txt` 文件指定了哪些本地化的开源支持包（open source support packages）应被纳入（vendor）基于此模板创建的项目中。

该文件的安装路径为：

```text
.claude/open_supports_name_list.txt
```

请从规则源仓库单独安装列表中指定的包：

```sh
sh scripts/install-open-supports.sh -t /path/to/project
```

## 格式

每一行非空且非注释的内容均遵循以下格式：

```text
<support-name> [install args...]
```

支持的名称格式：

- `GithubName/RepoName`，例如 `colbymchenry/codegraph`
- `ost_GithubName_RepoName`，例如 `ost_colbymchenry_codegraph`

支持名称后的参数将传递给该包内包含的 `scripts_for_install/install.*` 脚本。

版本 1 不支持行内注释，也不支持包含空格的参数值。
请改用整行注释。

## 示例

```text
# 在项目范围内为 Claude Code 安装 CodeGraph。
colbymchenry/codegraph --target=claude --location=local

# 在项目范围内为 Claude Code 安装 GSD Core。
open-gsd/gsd-core --claude --local

# 内部的 ost_* 名称同样有效。
ost_garrytan_gstack
```