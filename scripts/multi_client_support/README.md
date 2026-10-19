# 多客户端支持

让 Claude Code 以外的客户端复用本仓库的配置。目前只有 Codex。

原则：只转换 Codex 用得上的部分；Codex 能直接读取的格式（`SKILL.md`、项目 `CLAUDE.md`）不复制、不转换，只说明怎么用。

## Codex 能复用什么

| 本仓库的配置 | Codex 的做法 | 命令 |
|-------------|-------------|------|
| `dot_claude/CLAUDE.md`（个人差异规则） | 写入 `~/.codex/AGENTS.md` 的标记区块 | `codex.sh` |
| 场景约定 `CLAUDE.md` | 方式 a：在 `~/.codex/config.toml` 加 `project_doc_fallback_filenames = ["CLAUDE.md"]`，项目没有 `AGENTS.md` 时 Codex 读取 `CLAUDE.md`，两个客户端共用一份<br>方式 b：另外输出一份 `AGENTS.md` | a：`install-claude-project.sh -f <FLAG> -t <project>` 安装场景包后手动改 Codex 配置<br>b：`install-claude-md.sh -f <FLAG> -t <project> -n AGENTS.md` |
| `skills/` 下的 skill | Codex 与 Claude Code 使用相同的 `SKILL.md` 格式，读取 `<repo>/.agents/skills` 与 `~/.agents/skills` | `install-skill-pkg.sh -f <FLAG> -t <project>/.agents/skills` |
| `open_supports/` 支持包 | 由使用者自行运行各支持包的安装脚本，带上 Codex 参数（如 `--target=codex`、`--client=codex`、`--codex`） | 见各支持包 README |
| agents、settings、hooks、`.mcp.json` | 不转换：Codex 有自己的配置格式，本仓库尚未验证 | — |

`project_doc_fallback_filenames` 会改动本机 Codex 配置，脚本不会自动写入。Codex 在每个目录只读一份文件，顺序为 `AGENTS.override.md` → `AGENTS.md` → fallback 名称，所以项目已有 `AGENTS.md` 时不会再读 `CLAUDE.md`。

## `codex.sh`

```sh
sh scripts/multi_client_support/codex.sh [-d] [-F]
```

把 `templates/AGENTS.codex-user.md` 写入 `${CODEX_HOME:-~/.codex}/AGENTS.md` 中的标记区块：

```text
<!-- agent-prompt-rules -->
...模板内容...
<!-- /agent-prompt-rules -->
```

- 文件不存在时创建；没有区块时追加到末尾；区块存在时只替换区块内容
- 区块外的内容（例如本机专属的 Homebrew、curl 规则）一律保留
- 内容没有变化时报告 `[UNCHANGED]`，不写入、不备份；其他修改前都先备份为 `AGENTS.md.bak.<时间戳>`
- `-d` 预演；标记缺失、重复或顺序颠倒时报 `[BROKEN]` 退出，`-F` 先备份再删除所有标记区块并重新追加

完整说明见 `codex.sh -h`。

## 模板与 `dot_claude/CLAUDE.md` 的对应

`templates/AGENTS.codex-user.md` 只写与 Codex 默认行为不同、确有需要的规则，对应 `dot_claude/CLAUDE.md`：

| `CLAUDE.md` 段落 | Codex 模板 |
|-----------------|-----------|
| 资讯来源 | 保留；Claude 专属工具名（GitHub MCP `get_file_contents`、WebFetch）改为通用说法 |
| 弱网环境 | 保留 |
| 程式码操作（LSP） | 删除：Codex 没有 LSP 工具 |
| RTK | 保留 |
| —— | 新增「回覆语言」：Claude 由 `settings.json` 的 `language` 设定，Codex 没有对应设定 |

两份文件分开维护，修改 `CLAUDE.md` 时需同步模板。模板会被注入 Codex 上下文，维护说明只写在本文件，不写进模板。

## 已移除（2026-10-20）

- `-l project`、`-p`、`-n`：Codex 只自动读取 `AGENTS.md`，旧的默认输出 `AGENTS.codex.md` 不会生效；项目级改用上表的方式
- `-v` 与 `.agent-rules/claude/`：原为旧版分层规则（`dot_claude_legacy/`）设计的按需读取流程，精简后的 `dot_claude/` 不再需要，且会把个人用户级配置复制进项目
- `templates/AGENTS.codex-project.md`

## 验证

```sh
sh scripts/tests/test-multi-client-codex.sh
```
