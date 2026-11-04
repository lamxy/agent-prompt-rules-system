---
name: myopensupports
description: 按序號列出本倉庫（agent-prompt-rules-system）open_supports/ 的支持包（OpenSpec、codegraph、gstack、pm-skills 等），產生安裝到目前專案的完整命令與安裝示例，移除專案中已安裝的支持包，並與倉庫索引同步清單。依賴環境變數 AGENT_RULES_REPO 指向本倉庫的本機克隆。
when_to_use: 使用者輸入 /myopensupports，或說「列出支持包」「安裝支持包 3」「這個專案裝 codegraph」「移除支持包」「同步支持包清單」時。整包場景配置用 myconfig；插件開關用 myplugins。
argument-hint: "[序號 | 序號 -- 參數… | remove 序號 | add Owner/Repo | sync] [--target 目錄]"
allowed-tools: Bash(python3 ~/.claude/skills/myopensupports/scripts/myopensupports *)
---

# 支持包管理

所有判斷交給腳本，不自己讀 INDEX 或拼命令。腳本命令要照字面單獨執行：寫成 `~/.claude/...`，不展開成絕對路徑、不加引號、不和其他命令串接、不重導向。

```sh
python3 ~/.claude/skills/myopensupports/scripts/myopensupports <子命令> [參數]
```

| 使用者輸入 | 執行 |
|---|---|
| 沒有內容，或要求列出 | `list` |
| 序號或包名（如 `3`、`codegraph` 對應的 `ost_…`） | `install <選擇>` |
| 序號加 `-- 參數…` | `install <選擇> -- <參數…>` |
| `remove <選擇>` | `remove <選擇>`（只印方案） |
| `add`、`sync` | 先讀 `references/details.md` 再執行 |

- 目標專案預設為目前專案；使用者指定其他目錄時加 `--target <目錄>`。
- 自然語言描述（如「這個專案裝 codegraph」）：先 `list` 找序號，再 `install`；對應不明確就問。
- 腳本輸出 `錯誤：` 且提到 `AGENT_RULES_REPO` 時，這是使用本技能的必要前提：把設定方法轉告使用者後停止，不自行設定環境變數或改用其他路徑。
- `注意：` 行照抄給使用者。

## 安裝與移除：給命令，由使用者決定

`install` 只印方案，不會安裝；`remove` 不帶 `--apply` 只印方案，不會刪除。方案印出後：

1. 轉述重點：預設參數及其來源、其他可選參數、完整命令；安裝示例照錄腳本輸出的區塊。
2. 用一次 AskUserQuestion 問（remove 只問第 2 題）：
   - **參數**：「用預設參數（推薦）」或「自訂參數」。選自訂時請使用者輸入參數，再用 `install <選擇> -- <參數…>` 重跑腳本，取得新的完整命令。
   - **執行方式**：「讓 Claude 關閉沙箱執行」或「自己用 `!` 執行」。
3. 依選擇處理：
   - **Claude 執行**：用 Bash 加 `dangerouslyDisableSandbox: true` 執行完整命令；使用者仍需在權限提示中核准。安裝建議先跑腳本給的預演命令，確認輸出沒有問題後再跑正式命令。
   - **自己執行**：給出 `! <完整命令>` 讓使用者貼上執行。
4. 使用者貼回失敗輸出時，原樣引用錯誤行與退出碼；只建議重跑失敗的那一條命令。

AskUserQuestion 不可用時，改用文字提問後停止。

上游工具本身的卸載命令（腳本輸出「上游工具本身的卸載」段）只轉述，不代為執行。

## 列出後的回覆

工具輸出已是完整清單，不要再轉成表格或重抄清單。回覆只含：

1. 有 `注意：` 行就照抄。
2. 下面的用法：

```
/myopensupports 3                 顯示第 3 個的安裝方案（預設參數、完整命令、安裝示例），不直接安裝
/myopensupports 3 -- <參數…>      用自訂參數產生命令；{PROJECT_DIR} 會換成專案路徑
/myopensupports 3 --target <目錄> 安裝到其他專案
/myopensupports remove 3          移除專案中本倉庫產生的支持包檔案（先備份）
/myopensupports add Owner/Repo | sync    維護清單（從倉庫查找／與倉庫索引比對）
```
