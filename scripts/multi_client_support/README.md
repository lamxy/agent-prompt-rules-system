# 多客戶端支援

此目錄包含適配器，用於讓 Claude Code 以外的客戶端使用本倉庫的代理規則來源。

## 目前狀態

目前只實作 Codex 第一階段適配器。

Codex 適配器聚焦於指令文件與可選的規則來源內嵌。它不會產生 `.codex/config.toml`、Codex hooks、Codex `.rules`、Codex skills 或 Codex custom agents。

## Codex 適配器

使用 `codex.sh` 從模板產生 Codex-native 指令文件。

```sh
sh scripts/multi_client_support/codex.sh -l <user|project> [-p <target_dir>] [-n <filename>] [-F] [-v]
```

選項：

- `-l user|project`：目標層級。
- `-p <target_dir>`：既有專案目標目錄。`project` 必填，`user` 不可使用。
- `-n <filename>`：輸出檔名。預設為 `AGENTS.codex.md`。
- `-F`：強制覆寫既有輸出檔。搭配 `-v` 時，更新相符的內嵌檔案，同時保留無關的額外檔案。
- `-v`：對專案目標，將本倉庫的 `.claude/` 目錄複製到 `<target>/.agent-rules/claude/`。

範例：

```sh
# 在 ${CODEX_HOME:-$HOME/.codex} 下產生使用者層級 Codex 指令
sh scripts/multi_client_support/codex.sh -l user

# 產生專案層級 Codex 指令草稿
sh scripts/multi_client_support/codex.sh -l project -p /path/to/project

# 產生專案指令並內嵌 Claude 規則來源
sh scripts/multi_client_support/codex.sh -l project -p /path/to/project -v

# 直接寫入 AGENTS.md
sh scripts/multi_client_support/codex.sh -l project -p /path/to/project -n AGENTS.md -F
```

## 產生的檔案

預設專案輸出：

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

此內嵌目錄樹為摘要示意；`codex.sh` 會遞迴複製本倉庫 `.claude/` 下的所有檔案與目錄。

`AGENTS.codex.md` 是 Codex-native 入口。內嵌的 `.agent-rules/claude/` 目錄是參考材料。除非已另行安裝 Codex-native 設定，否則 Claude 專用 settings、hooks、plugins 與 `SendMessage` references 不是生效中的 Codex 執行時設定。

## 驗證

執行：

```sh
sh -n scripts/multi_client_support/codex.sh
sh scripts/test-multi-client-codex.sh
```

## 未來方向

未來階段可能會將選定的 Claude rule intent 轉換為 Codex-native config、hooks、command rules、skills 或 custom agents。這些範圍刻意不納入第一階段。
