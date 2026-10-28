# 命令對照與輸出判讀

`<R>` 為 catalog 輸出的倉庫路徑，`<P>` 為目標專案根目錄的絕對路徑。所有腳本由自身路徑推出倉庫根，保持目前目錄不變，以絕對路徑呼叫：`sh "<R>/scripts/<腳本>" …`。命令中的 `<R>`、`<P>` 一律加雙引號（例如 `-t "<P>"`、`-p "<P>/.claude"`），路徑可能含空格。

## 1. 單元 → 命令

### 專案級（會話中預演，寫入由使用者執行）

| 單元 | 預演 | 安裝 | 說明 |
|---|---|---|---|
| 場景整包 | `install-claude-project.sh -f <FLAG> -t <P> -d` | 去掉 `-d` | 複製 `.claude/**`、`.mcp.json`、`CLAUDE.md`，再安裝整包附帶的支援包；只要配置不要支援包加 `-N` |
| 整包更新 | 同上加 `-F` | 去掉 `-d` | `-F` 不會傳給支援包；報告有 `[STALE]` 時另跑 `install-open-supports.sh -t <P> -F`（先 `--dry-run`） |
| settings（專案） | 無，技能自行列出 | `install-settings.sh -l project -s <FLAG> -p <P>/.claude -m overwrite\|merge` | `-p` 是 `.claude` 目錄；不存在會自動建立 |
| settings（本地） | 無 | `install-settings.sh -l local -s <FLAG> -p <P>/.claude -m overwrite\|merge` | 寫 `settings.local.json`；提醒加入 `.gitignore` |
| CLAUDE.md | 無 | `install-claude-md.sh -f <FLAG> -t <P>` | 改名用 `-n AGENTS.md`；模板為空時直接跳過 |
| .mcp.json | 無 | `install-dot-mcp.sh -f <FLAG> -t <P>` | 只有 backend-dev、dev-ops 有內容 |
| agents | 無 | 先 `mkdir -p <P>/.claude/agents`，再 `install-agent-pkg.sh -f <FLAG> -t <P>/.claude/agents` | 目標目錄不存在會 exit 1 |
| skills | 無 | `install-skill-pkg.sh -f <FLAG> -t <P>/.claude/skills` | 目錄會自動建立；佔位包會提示「此包尚無 skill」 |
| 單個支援包 | `install-open-supports.sh -t "<P>" -n <包> --dry-run -- <參數>` | 去掉 `--dry-run` | `--dry-run` 必須在 `--` 之前，`--` 之後全部傳給支援包（放錯位置會變成真的安裝）；`<參數>` 照抄 `<R>/dot_claude_projects/.claude-<FLAG>/.claude/open_supports_name_list.txt` 中該包那一行（含 `{PROJECT_DIR}`） |

不支援預演的單元，由技能只讀列出「源檔 → 目標，已存在者標為將跳過」。源檔位置：`<R>/settings/settings.<project|local>-<FLAG>.json`、`<R>/claude_mds/CLAUDE-<FLAG>.md`、`<R>/dot_mcp_jsons/dot-mcp-json-<FLAG>.json`、`<R>/agents/agents-<FLAG>/`、`<R>/skills/skills-<FLAG>/`。

目標不在目前目錄時，預演一樣可以跑（只要沙箱能讀到目標），命令照樣給出。

多單元的執行順序：settings → CLAUDE.md／.mcp.json → agents → skills → 支援包。settings 必須在支援包之前，因為 pm-skills 會把外掛寫進專案 settings，先裝支援包再覆寫 settings 會把它沖掉。

### 全域與使用者層級（只給命令）

這些單元會寫入 `~/.claude`、`~/.codex`、`~/.local/share` 或做全域 `npm` 安裝，屬於本機配置，會話中不預演。給出命令時，附上「影響」欄的說明。

| 單元 | 建議命令 | 影響 |
|---|---|---|
| 全域工具（gstack、task-master） | `sh <R>/scripts/install-claude-project.sh -g -d`，確認後去掉 `-d` | gstack clone 到 `~/.local/share/gstack`（約 1.1GB）；`npm install -g`；合併 `skillOverrides` 進 `~/.claude/settings.json`（先備份；`-k` 可跳過這一步） |
| 個人使用者層級 skills（含本技能） | `sh <R>/scripts/install.sh -l user -m overwrite -E commands -e CLAUDE.md -e settings.json`（`-E`／`-e` 為排除，只留 skills/） | 覆蓋 `~/.claude/skills/` 下的同名檔，**不備份**；本技能以符號連結安裝時要再加 `-E skills/myconfig` |
| 個人 CLAUDE.md、commands | 先 `diff <R>/dot_claude/CLAUDE.md ~/.claude/CLAUDE.md`，再手動合併 | `install.sh` 覆寫不備份，本機 CLAUDE.md 常有專屬規則 |
| 全域 settings | 先比對 `<R>/settings/settings.user.json` 與 `~/.claude/settings.json`；只同步 gstack 分層用 `sh "<R>/scripts/install-settings.sh" -l user -m merge -K skillOverrides` | 整份 overwrite 會蓋掉本機設定（有備份） |
| Codex 個人規則 | `sh <R>/scripts/multi_client_support/codex.sh -d`，確認後去掉 `-d` | 只替換 `~/.codex/AGENTS.md` 的標記區塊，區塊外內容保留 |

## 2. 輸出判讀

| 腳本 | 結尾摘要 | 退出碼 |
|---|---|---|
| `install-claude-project.sh` | `复制完成。copied= forced= manual= empty= invalid=`（原文），之後是支援包的摘要 | 參數、源或目標錯誤時 exit 1；否則**取自支援包階段**，所以 exit 1 時配置可能已複製完成 |
| `install-open-supports.sh` | `完成。mode= total= vendored= reused= stale= … missing= no_script= failed= conflict=` | missing、no_script、failed、conflict 任一大於 0 時 exit 1；`stale>0` 仍 exit 0 |
| `install-agent-pkg.sh` | `Done. copied= forced= manual=` | 源或目標不存在時 exit 1 |
| `install-skill-pkg.sh` | `Done. copied= forced= manual= invalid=` | 同上 |
| `install-claude-md.sh`、`install-dot-mcp.sh` | 無摘要，只有 `[COPIED]`／`[MANUAL]`／`[BACKUP]` | 已存在而跳過時仍 exit 0；`.mcp.json` 不合法時 exit 1 |
| `install-settings.sh` | 新建只輸出 `[CREATED]`；覆蓋 `[OVERWRITE]`、合併 `[MERGE]`（兩者前有 `[BACKUP]`），結尾 `配置安装完成。`（原文）；merge 未給 `-K` 時，未寫入的欄位以 `[WARN]` 列出 | 錯誤時 exit 1 |

預演（`-d`）時摘要的 copied、forced 恆為 0：新增數以 `[DRY-RUN] copy` 行計，已存在數以 `[MANUAL]` 行計。

需要計數並回報的標籤：

- `[MANUAL]`：已存在而跳過。即使 exit 0 也要明說「N 個檔案已存在，未更動」，並提供 `-F`。
- `[STALE]`：支援包已存在但與倉庫不一致。
- `[CONFLICT]`、`[FAILED]`、`[MISSING]`、`[NO_SCRIPT]`：支援包失敗。
- `[BACKUP]`：備份路徑。報告時全部列出。
- `[INVALID]`：源 JSON 不合法而跳過；skills 中缺 `SKILL.md` 的目錄以 `[WARN]` 報出並計入 `invalid=`。
- `[SKIP]`：模板為空而跳過（CLAUDE.md、.mcp.json）。
- `[WARN]`：merge 時沒有寫入的欄位（例如 permissions），或缺 python3 無法校驗 JSON。

支援包失敗時，只建議重跑失敗的那一個：`install-open-supports.sh -t "<P>" -n <包> --dry-run -- <清單中該行的參數>`，確認後去掉 `--dry-run`。不重跑整包。

## 3. 備份位置

都在專案內，報告時提醒「確認無誤後刪除，或加入 `.gitignore`」：

- 整包 `-F`：`<P>/.claude-project-backup-<時間戳>/`
- `CLAUDE.md`、`.mcp.json`、`settings*.json`：同目錄下的 `<檔名>.bak.<時間戳>`
- agents、skills `-F`：`<目標目錄>.backup-<時間戳>/`
- 支援包 `-F`：`<P>/.claude/open_supports.backup-<時間戳>/`

## 4. 跨場景陷阱

場景包 README 沒寫，但安裝時要提醒的事：

- 只裝 backend-dev 的 settings 時，PostToolUse hook 指向的 `.claude/hooks/go-fmt.sh` 只在整包裡有。建議改裝整包，或從 `<R>/dot_claude_projects/.claude-backend-dev/.claude/hooks/` 複製。
- 單獨用 overwrite 重裝 settings 會沖掉 pm-skills 寫入的條目，之後要重跑 `install-open-supports.sh -t <P>`。
- backend-dev、dev-ops、fullstack-dev 的模板含 permissions。merge 只合併 `enabledPlugins`、`extraKnownMarketplaces`、`skillOverrides`，不會寫入 permissions。
- `fullstack-dev` 只有 settings 模板，沒有整包。前後端都有的專案，裝 backend-dev 或 frontend-dev 整包，再裝 `fullstack-dev` settings。
- 不用 `-m ask`：Bash 工具沒有 tty，會報錯退出。
- 支援包的專案外副作用不會復原：OpenSpec `npm install -g`、codegraph `curl | sh`、pm-skills 下載外掛到 `~/.claude/plugins/`。
- 資料庫 MCP 的 `execute_sql` 可以寫入；範本的 deny 只攔 Bash 的 mysql、psql、mongosh、redis-cli 破壞性命令，不涵蓋 MCP 呼叫。只用唯讀帳號，只連開發或測試庫。
