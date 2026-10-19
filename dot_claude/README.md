# dot_claude

Claude Code 設定來源目錄，由 `scripts/install.sh` 同步到 `~/.claude/` 或專案的 `.claude/`。2026-10-19 以精簡版取代原本的分層規約系統，原內容備份在 `dot_claude_legacy/`。

## 內容

| 檔案 | 說明 |
|---|---|
| `CLAUDE.md` | 約 30 行，只寫與 Claude Code 預設行為不同的約束：資訊來源驗證、弱網降級、LSP 優先、RTK 原始輸出 |
| `commands/analyze-github-repo.md` | `/analyze-github-repo`：輕量探測優先的單一 GitHub 倉庫分析 |
| `settings.json` | 個人使用者層級設定（權限、沙箱、hooks、外掛），與本機 `~/.claude/settings.json` 同步 |
| `README.md` | 本說明，不會被載入為指令 |

## 安裝注意

- `settings.json` 是個人使用者層級設定：其中 `autoMode`、`skillOverrides` 等鍵與依賴 `~/.claude/skills/myhandoff/`、`rtk` 的 hooks 不適合放進專案。`install.sh` 在 project/local 層級預設不安裝它（`-S` 可強制安裝），專案請改用 `settings/` 下的範本。
- `README.md`（本檔）預設不會被 `install.sh` 安裝。
- 目標若裝過舊版，`install.sh` 會以 `[LEGACY]` 列出殘留檔案；`rules/` 下的舊規則每次啟動都會載入並與本版衝突。加 `-C` 會移至 `<target>/legacy-backup-<時間戳>/`，不會刪除。
- 以 `-l user` 安裝時，`CLAUDE.md` 會覆蓋現有的 `~/.claude/CLAUDE.md`；若其中有本機專屬規則（例如 Homebrew、curl 重試、`@RTK.md` 匯入），需先手動合併。已存在的 `settings.json` 會被安裝腳本跳過，需手動合併。

## 為什麼精簡

原系統約 22KB 常駐上下文（CLAUDE.md + RTK.md + 7 個 rules），加上 `expandable/` 按需規約、10 個輸出範本、2 個 hook 與 1 個審計命令。對照目前的 Claude Code 與官方文件，問題如下：

1. 大部分規則已是預設行為：先給結論、簡潔、不編造、只問一個關鍵問題、壓縮工具輸出、不可逆操作先確認。官方建議單一 CLAUDE.md 少於 200 行，過長會降低遵循度。
2. `expandable/` 靠模型自行記得讀檔，不可靠；官方的按需載入機制是 skill 與帶 `paths` frontmatter 的 rules。
3. 子代理與團隊協定（派發範本、`[agent]` 欄位、150 行／3000 字元分流、SendMessage 糾正流程）在模擬平台當時缺少的能力，現已由 Agent 工具、agent 定義的 `model:` frontmatter、`/loop`、Plan mode 取代。
4. 規則之間或與其他設定衝突，例如「最多重試 1 次」與全域 curl 重試規則矛盾；官方說明兩條指令矛盾時模型可能任選其一。
5. hooks 有實際錯誤（見下方），修正後收益仍低。

## 遷移對照

| 原內容（`dot_claude_legacy/`） | 處理 | 替代 |
|---|---|---|
| CLAUDE.md §1–§5、`general-task-rule-min.md` | 刪除 | 新版系統提示詞的預設行為 |
| `tool-call-rule-min.md` | 刪除 | 預設行為；「最多重試 1 次」與全域 curl 重試規則衝突 |
| `sub-agent-rule-min.md`、`dispatch-template.md`、6 個輸出範本 | 刪除 | Agent 工具內建約束、agent 定義的 `model:` frontmatter |
| `agent-team-rule-min.md` | 刪除 | 同上 |
| `subagent-cost-rule-min.md` | 刪除 | agent 定義的 `model:` frontmatter |
| `loop-cron-rule-min.md` | 刪除 | 內建 `/loop` |
| `design-first-rule-min.md` | 刪除 | Plan mode、brainstorming skill |
| `env-tools-min.md` | 壓縮為 1 條 | 內建 Grep（基於 rg）、LSP 工具 |
| `source-verification-min.md` | 保留並壓縮 | CLAUDE.md「資訊來源」 |
| `network-degraded-preference-min.md` | 保留並壓縮 | CLAUDE.md「弱網環境」 |
| `skill-trigger-constraint-min.md` | 改為硬約束 | settings.json `skillOverrides: {"claude-api": "user-invocable-only"}`：模型看不到該技能，`/claude-api` 仍可手動執行 |
| `instruction-writing-style-min.md` | 改為維護註解 | CLAUDE.md 頂部 HTML 註解 |
| `RTK.md` | 壓縮為 1 段 | CLAUDE.md「RTK」；rtk 1.0.1 起 `rtk proxy` 已改為 `rtk bypass` |
| `commands/auditrules.md`、`expandable/audit/` | 刪除 | `/doctor prompt-audit` |
| `commands/analyze-github-repo.md` | 保留，移除派發範本 | `commands/analyze-github-repo.md` |
| `hooks/subagent_stop_gate.py` | 刪除 | — |
| `hooks/artifact_read_gate.py` | 不採用（原本就未註冊） | — |
| `audi_reports/` | 不遷移 | 已更名為 `dot_claude_legacy/audit-reports/`（與 `/auditrules` 的輸出路徑一致），供查閱 |

## 刪除 hooks 的原因

- `subagent_stop_gate.py`：回傳不合法的 `"decision": "approve"`（只有 `block` 合法）；誤以為 block 後子代理已無法寫檔，實際上 block 會讓子代理繼續工作並把 `reason` 當成下一步指示。修好後收益仍低，因為子代理只回傳最後一則訊息，輸出長度由派發提示控制即可。
- `artifact_read_gate.py`：沒有在 settings 中註冊；攔截路徑 `/tmp/` 與規約中的 `.claude/artifacts/` 不一致；對所有非 artifact 的 Read 回傳 `allow`（官方定義會略過權限確認）；對 artifact 每次都拒絕，即使已聲明「加工」也無法讀取。
- `PreCompact` prompt hook：官方文件說明 PreCompact 的 `systemMessage` 會被捨棄，這個 hook 沒有任何作用。

以上問題已在 `dot_claude_legacy/` 中修正（見該目錄 README），但本版仍不採用這些 hook。

## settings 調整

`settings.json` 與本機 `~/.claude/settings.json` 保持一致（2026-10-19 同步）。相對於優化前的本機設定（備份 `~/.claude/settings.json.bak-20261019`），已做的調整：

| 項目 | 處理 | 原因 |
|---|---|---|
| `skillOverrides` | 新增 `claude-api: user-invocable-only` | 取代 CLAUDE.md 的軟約束（已實測模型看不到該技能） |
| `alwaysThinkingEnabled: false` | 移除（回到預設） | 官方定義：`false` 會在所有工作階段關閉 extended thinking，`true` 無作用 |
| `autoCompactEnabled: false` | 移除（回到預設 `true`） | 關閉後長對話會直接撞上上下文上限；要調整觸發時機用 `autoCompactWindow` 或 `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` |
| `env.API_TIMEOUT_MS: 300000` | 移除（回到預設 600000） | 設定值比預設還小；官方建議慢網路或經代理時應調大 |
| `env.DISABLE_AUTOUPDATER: "0"` | 移除 | 標準布林變數，`0` 等於未設定，沒有作用 |
| `modelSettings` 的 `claude-sonnet-5`、`claude-opus-5` | 移除 | 舊型號 |
| `sandbox.filesystem.allowWrite` 的 `~/.claude/artifacts` | 移除 | 已不使用 artifact 落盤機制 |
| `allowWrite` 的 `~/.kube`、`allowRead` 的 `~/.kube/config` | 去重 | 重複項 |
| `frontend-design@claude-code-plugins`、`security-guidance@claude-code-plugins` | 移除 | 與其他 marketplace 的同名外掛重複，skill 與 hook 會重複載入 |
| `typescript-lsp@claude-plugins-official` | 設為 `false` | 與 `typescript-native-lsp` 註冊相同副檔名，只會啟動其一；native 版同時支援 TypeScript 7 與 6 以下 |
| `Bash(git reset --hard *)` | 從 allow 移到 deny | 避免未提交的修改被清除 |
| `askUserQuestionTimeout: "5m"` | 移除 | 提問時等待使用者回答，不自動繼續 |
| `env.BASH_DEFAULT_TIMEOUT_MS` | 600000 改為 300000 | 卡住的命令 5 分鐘逾時 |

保留原狀的項目：

- `SessionStart` hook `zsh -c '. ~/.zshrc'`：在子 shell 中執行，對 Claude 的環境沒有作用；依使用者決定保留。
- `Bash(docker run *)`、`Bash(docker exec *)` 在 allow 中，`docker *` 在 `sandbox.excludedCommands` 中；官方明言排除「不是安全邊界」。auto 模式加上 `autoMode.classifyAllShell: true` 時，shell allow 規則會暫停並交由分類器判斷，切到其他模式時則直接放行。
- `Stop`、`StopFailure` hook 依賴 `~/.claude/skills/myhandoff/`，`PreToolUse` 依賴 `rtk`；在未安裝它們的機器上會報錯。
- `typescript-native-lsp` 是第三方外掛；TypeScript 6 以下的專案需在專案內或全域安裝 `typescript-language-server`。
- `DO_NOT_TRACK` 與 `DISABLE_TELEMETRY` 效果重複，無害。

## 經驗

1. 只寫與預設行為的差異：刪掉一條後行為不變，就不該寫。
2. 強制約束的優先順序：權限與沙箱 → hook → Plan mode → 提示詞。
3. 按需載入用 skill 或 `paths` rules，不用「需要時讀取某檔案」。沒有 `paths` 的 rules 每次啟動都會載入；`@import` 也不會減少上下文成本。
4. `PostToolUse` 不用 `type: prompt` hook，會中斷執行鏈（見 `dot_claude_legacy/audit-reports/2026-04-28-posttooluse-hook-pitfall.md`）。
5. hook 輸出以最新官方文件為準；放行時不輸出 `decision`，不要無條件回傳 `allow`。
6. 規則衝突比缺漏更糟，兩條矛盾時模型可能任選其一；定期執行 `/doctor prompt-audit`。
7. 新模型遵循度高，「[強制]」「嚴格禁止」等措辭容易造成過度觸發；寫清楚原因比加強語氣有效。
8. 引用外部工具指令前先對照目前安裝的版本（例如 `rtk --help`），避免規則指向已不存在的子命令。
