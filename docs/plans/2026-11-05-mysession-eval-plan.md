# mysession-eval Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 實作全域技能 `mysession-eval`：使用者在真實專案做完一件事時呼叫，腳本從本會話記錄擷取客觀指標，Claude 推定主觀項目後寫入本機日誌；覆盤時腳本匯總、Claude 依判定規則初判。

**Architecture:** 單一 Python 3 腳本（同 myplugins 慣例）提供 `extract`／`append`／`summarize` 三個子命令，所有解析、計數、匯總都在腳本內；`SKILL.md` 只指揮 Claude 呼叫腳本、做推定與詢問；覆盤規則放 `references/review.md`，覆盤時才讀。測試用 Python `unittest` 搭配合成 jsonl，由 `scripts/tests/test-mysession-eval.sh` 呼叫，`run-all.sh` 自動收錄。使用者只用 `/mysession-eval` 與 `/mysession-eval review [場景] [--final]`；`extract`／`append`／`summarize` 是腳本子命令，由技能呼叫，使用者不直接執行。

**Tech Stack:** Python 3.9+ 標準庫（無第三方依賴）、POSIX `sh`。

**Spec:** `docs/plans/2026-11-05-mysession-eval-design.md`（執行者必須同時讀設計稿；本計畫只記實作決定）

## Global Constraints

- Python 3.9 相容，只用標準庫。
- 腳本命令一律寫成 `python3 ~/.claude/skills/mysession-eval/scripts/mysession-eval <子命令> [參數]`，照字面單獨執行，不展開路徑、不加引號包住路徑、不串接、不用管線或重導向（沙箱排除規則按命令文字比對）。
- `SKILL.md` frontmatter 必含 `disable-model-invocation: true` 與 `allowed-tools: Bash(python3 ~/.claude/skills/mysession-eval/scripts/mysession-eval *)`。
- `dot_claude/` 下內容用繁體中文。
- 會話 id 只從環境變數 `CLAUDE_CODE_SESSION_ID`（或 `--session` 參數）取得；找不到會話檔時報錯，**不退回**「取最新 jsonl」。
- 日誌與輸出不得含 Claude 回覆原文、工具輸出原文；使用者訊息只出現在 `extract` 的輸出（截斷後），**不寫入日誌**。
- 樣本門檻：單一配置 3 筆、場景整體 10 筆（設計稿第 9 條）。
- 日誌：`~/.claude/mysession-eval/log.jsonl`，每筆一行，含 `schema: 1`。
- 測試只用暫存目錄，不讀寫真實 `~/.claude`。環境變數覆寫：`MSE_CLAUDE_DIR`（預設 `~/.claude`）、`MSE_HOME`（預設 `<MSE_CLAUDE_DIR>/mysession-eval`）、`MSE_PROJECT_DIR`（預設 `CLAUDE_PROJECT_DIR` 或目前目錄）。
- 不修改本機 `~/.claude/` 任何檔案；本機安裝與設定由使用者執行（Task 7 給命令）。

## Review Focus

1. 使用者在技能詢問時用一般文字回答（不是選項框），該回答與之後的 `append` 不得被算進下一次記錄的區段 → Task 1 測試 `test_segment_skips_previous_skill_run`。
2. 連續呼叫兩次、中間沒做事 → `extract` 回報 `segment.empty: true`，技能告訴使用者無可記錄、不寫入 → Task 1 測試 `test_empty_segment`、Task 6 SKILL.md 規則。
3. 很長的會話（上百則使用者訊息）→ 訊息截斷與數量上限生效，輸出大小受控 → Task 2 測試 `test_user_messages_capped`。
4. 日誌有損壞的行（手動編輯、寫入中斷）→ `summarize` 略過並回報 `bad_lines`，不整體失敗 → Task 5 測試 `test_summarize_skips_bad_lines`。
5. 同一配置期中被修改 → 前後兩版分開計算，不混算 → Task 5 測試 `test_config_versions_split`。

---

### Task 1: 會話定位與區段切分

**Files:**
- Create: `dot_claude/skills/mysession-eval/scripts/mysession-eval`（可執行，`#!/usr/bin/env python3`，模組 docstring 列子命令與環境變數，格式仿 myplugins）
- Create: `scripts/tests/mysession_eval_test.py`（`unittest`；以 `importlib.machinery.SourceFileLoader` 載入無副檔名的腳本；內建合成 jsonl 的 helper）
- Create: `scripts/tests/test-mysession-eval.sh`（POSIX sh；python3 不存在時 `SKIP`；執行 `python3 -I scripts/tests/mysession_eval_test.py`，失敗則非零結束）

**Interfaces:**
- Produces:
  - `class Fail(Exception)`：使用者可讀的錯誤，CLI 印到 stderr、結束碼 2。
  - `find_session_file(session_id: str, claude_dir: str) -> str`：以 `glob(<claude_dir>/projects/*/<id>.jsonl)` 找唯一檔案；0 個或 id 空白時 `raise Fail`。
  - `load_entries(path: str) -> list[dict]`：逐行 `json.loads`，壞行略過。
  - `is_invocation(entry: dict) -> bool`：`type == "user"`、非 `isMeta`、`message.content` 為字串且含 `<command-name>/mysession-eval</command-name>`。
  - `is_skill_script_call(entry: dict) -> set[str]`：回傳該 assistant 項目中、Bash `command` 含 `skills/mysession-eval/scripts/mysession-eval` 的 `tool_use.id` 集合（非 assistant 回空集合）。
  - `segment_bounds(entries: list[dict]) -> tuple[int, int]`：`end` = 最後一個 invocation 的索引（不含）；沒有 invocation 時 `end = len(entries)`。`start`：若 `end` 之前還有前一個 invocation，取「該 invocation 之後、`end` 之前，最後一個屬於本技能腳本呼叫的 `tool_result`」所在項目的下一個索引；沒有這類 tool_result 時取前一個 invocation 的下一個索引；沒有前一個 invocation 時為 0。

- [ ] **Step 1: 寫失敗測試**（合成 jsonl helper：`user(text)`、`meta(text)`、`invoke()`、`script_call(id)`、`script_result(id)`、`assistant_text()`、`tool_use(name, input, id)`、`tool_result(id, content, is_error=False)`）

```python
def test_find_session_file_missing_raises(self):  # 空目錄 → Fail；id 為空字串 → Fail
def test_find_session_file_found(self):           # projects/x/<id>.jsonl 存在 → 回傳該路徑
def test_bounds_no_previous_invocation(self):      # [user, assistant, invoke] → (0, 2)
def test_bounds_with_previous_invocation(self):    # [user, invoke, script_call, script_result, assistant_text, user, assistant, invoke]
                                                   # → start = script_result 索引 + 1 = 4, end = 7
def test_segment_skips_previous_skill_run(self):   # 前一次 invoke 後：script_call(extract)、assistant 問問題、user 純文字回答、
                                                   # script_call(append)、script_result → start 落在 append 的 result 之後
def test_empty_segment(self):                      # [.., invoke, script_call, script_result, invoke] → start == end
def test_bounds_previous_invocation_without_script(self):  # [invoke, user, invoke] → (1, 2)
```

- [ ] **Step 2:** 執行 `sh scripts/tests/test-mysession-eval.sh`，預期 FAIL（腳本不存在或函式未定義）。
- [ ] **Step 3:** 依 Interfaces 實作上列函式與 `Fail`；`main(argv)` 先只放子命令分派骨架（未知子命令 `raise Fail`）。
- [ ] **Step 4:** 執行 `sh scripts/tests/test-mysession-eval.sh`，預期全部 `ok`。
- [ ] **Step 5:** 提交 `feat: mysession-eval 會話定位與區段切分`。

### Task 2: 區段指標擷取與 `extract`

**Files:**
- Modify: `dot_claude/skills/mysession-eval/scripts/mysession-eval`
- Modify: `scripts/tests/mysession_eval_test.py`

**Interfaces:**
- Consumes: Task 1 的 `find_session_file`、`load_entries`、`segment_bounds`、`is_skill_script_call`。
- Produces:
  - `segment_metrics(entries: list[dict], start: int, end: int, subagent_dir: str | None) -> dict`，回傳鍵：
    `turns`、`empty`、`start_ts`、`end_ts`、`skills: {name: n}`、`agents: {type: n}`、`mcp: {tool: n}`、`rules_loaded: {path: n}`、`denials: {total, by_kind: {deny_rule, denied, not_granted}, by_tool: {name: n}}`、`tool_errors: {total, sandbox}`、`interrupts`、`compactions`、`tokens: {input, cache_creation, cache_read, output}`、`subagents: {count, tokens, mcp, denials_total, tool_errors_total}`。
  - `user_messages(entries, start, end, max_chars=300, max_count=30) -> tuple[list[str], int]`：回傳（訊息清單，省略則數）；超過 `max_count` 時保留前 10 與後 20。
  - CLI `extract [--session ID]`：stdout 輸出一個 JSON 物件，鍵：`session_id`、`project`（專案目錄 basename）、`segment`（`segment_metrics` 結果）、`user_messages`、`user_messages_omitted`。

判定規則（依設計稿「指標對應的 jsonl 欄位」表）：
- skill：assistant `tool_use` 名為 `Skill` 時取 `input.skill`；或非 meta user 字串含 `<command-name>/X</command-name>` 且下一則 `isMeta` user 以 `Base directory for this skill:` 開頭時記 `X`。`/clear`、`/compact` 等內建命令不算。
- agent：`tool_use` 名為 `Agent` 或 `Task`，取 `input.subagent_type`，缺省記 `general-purpose`。
- MCP：`tool_use` 名以 `mcp__` 開頭。
- rule：`type == "attachment"` 且 `attachment.type == "nested_memory"`，取 `attachment.content.path`。
- 權限拒絕：`tool_result.is_error` 為真且內容含 `is in a directory that is denied by your permission settings`（deny_rule）、`has been denied`（denied）、`but you haven't granted it yet`（not_granted）；`by_tool` 以對應 `tool_use` 名稱計。
- 工具錯誤：其餘 `is_error` 為真者；內容含 `Operation not permitted` 另計 `sandbox`。
- 中斷：user 內容文字以 `[Request interrupted by user` 開頭。
- 壓縮：`type == "system"` 且 `subtype == "compact_boundary"`。
- token：assistant `message.usage`，按 `message.id` 去重後加總。
- 使用者訊息：非 meta、非 `isCompactSummary`、內容為字串或含 text 區塊、不屬 tool_result；移除 `<system-reminder>…</system-reminder>`；斜線命令只保留 `/名稱 參數`；`<local-command-stdout>` 類整則略過。
- 子代理：讀 `subagent_dir/agent-*.meta.json`，`toolUseId` 屬於區段內 Agent／Task `tool_use.id` 者才計入；其 jsonl 以同一套規則計 token、MCP、拒絕、錯誤。
- 本技能自身的腳本呼叫與其 tool_result 不計入任何指標。

- [ ] **Step 1: 寫失敗測試**

```python
def test_metrics_skill_slash_and_tool(self):    # Skill tool_use(skill="db-schema-design") + "/myplugins" 斜線命令(含 Base directory meta) + "/clear"
                                                # → skills == {"db-schema-design": 1, "myplugins": 1}
def test_metrics_agents_mcp_rules(self):        # Agent(subagent_type 缺) + mcp__x__q ×2 + nested_memory(path=".../go.md")
                                                # → agents == {"general-purpose": 1}; mcp == {"mcp__x__q": 2}; rules_loaded == {".../go.md": 1}
def test_metrics_denials_and_errors(self):      # 三種拒絕訊息各一 + "Exit code 1" + "Operation not permitted"
                                                # → denials.total == 3, by_kind 各 1; tool_errors.total == 2, sandbox == 1
def test_metrics_interrupt_compact(self):       # → interrupts == 1, compactions == 1
def test_tokens_dedup_by_message_id(self):      # 同 message.id 3 行、usage output=10 → tokens.output == 10
def test_metrics_exclude_skill_script(self):    # 區段內本技能 script_call + 錯誤 result → tool_errors.total == 0
def test_subagent_linked_by_tool_use_id(self):  # meta toolUseId 在區段內 → subagents.count == 1；不在 → 0
def test_user_messages_cleaned(self):           # 含 <system-reminder> 被移除；"/foo bar" 斜線命令保留為 "/foo bar"；tool_result 不出現
def test_user_messages_capped(self):            # 100 則、每則 1000 字 → 回傳 30 則、每則 ≤ 300 字、omitted == 70
def test_extract_cli(self):                     # 設 MSE_CLAUDE_DIR、CLAUDE_CODE_SESSION_ID → stdout 可 json.loads，含 segment 與 user_messages
def test_extract_cli_no_session_env(self):      # 未設 CLAUDE_CODE_SESSION_ID 且無 --session → 結束碼 2，stderr 有說明
```

- [ ] **Step 2:** 執行測試，預期新增項 FAIL。
- [ ] **Step 3:** 實作 `segment_metrics`、`user_messages`、`extract` 子命令。
- [ ] **Step 4:** 執行測試，預期全部 `ok`。
- [ ] **Step 5:** 提交 `feat: mysession-eval 區段指標擷取`。

### Task 3: 已安裝配置清單與場景判斷

**Files:**
- Create: `dot_claude/skills/mysession-eval/scenarios.json`
- Modify: `dot_claude/skills/mysession-eval/scripts/mysession-eval`
- Modify: `scripts/tests/mysession_eval_test.py`

**Interfaces:**
- Produces:
  - `inventory(project_dir: str) -> list[dict]`：每項 `{kind, name, path, hash}`，`hash` 為檔案內容 sha256 前 12 碼，`path` 相對專案根。涵蓋：`skill`（`.claude/skills/*/SKILL.md`，name 取目錄名）、`agent`（`.claude/agents/*.md`）、`rule`（`.claude/rules/**/*.md`）、`mcp`（`.mcp.json` 的 `mcpServers` 每個鍵，hash 取該鍵的 JSON 序列化）、`settings`（`.claude/settings.json` 整檔一項）、`claude_md`（專案根 `CLAUDE.md` 或 `.claude/CLAUDE.md`）。檔案不存在就略過，不報錯。
  - `detect_scenario(project_dir: str, items: list[dict], scenarios: dict) -> str | None`：先比 `CLAUDE.md` 首行是否等於 `scenarios[s]["claude_md_heading"]`；不中則比 agent 名稱，與某場景 `agents` 交集 ≥ 3 且為唯一最大者；都不中回 `None`。
  - `scenarios.json` 格式：`{"<FLAG>": {"claude_md_heading": "<首行>", "agents": ["<名稱>", ...]}}`，四個場景，值取自 `dot_claude_projects/.claude-<FLAG>/CLAUDE.md` 首行與 `.claude/agents/*.md` 檔名（去 `.md`）。
  - `extract` 輸出新增 `scenario`（字串或 `null`）與 `installed`（`inventory` 結果）。

- [ ] **Step 1: 寫失敗測試**

```python
def test_inventory_kinds_and_hash(self):     # 暫存專案放 skill、agent、rules/sub/x.md、.mcp.json(兩個 server)、settings.json、CLAUDE.md
                                             # → kinds 計數 {"skill":1,"agent":1,"rule":1,"mcp":2,"settings":1,"claude_md":1}；hash 長 12；改檔內容後 hash 改變
def test_inventory_empty_project(self):      # 空目錄 → []
def test_detect_by_heading(self):            # CLAUDE.md 首行 "# CLAUDE.md — 后端开发（Go）" → "backend-dev"
def test_detect_by_agents(self):             # 無 CLAUDE.md，agents 有 sre、devops-automator、git-workflow-master → "dev-ops"
def test_detect_unknown(self):               # → None
def test_scenarios_json_matches_bundles(self):  # 讀倉庫 dot_claude_projects/.claude-<FLAG>/，heading 與 agents 須與 scenarios.json 一致
```

- [ ] **Step 2:** 執行測試，預期 FAIL。
- [ ] **Step 3:** 實作 `inventory`、`detect_scenario`，由倉庫檔案產生 `scenarios.json`，`extract` 加入兩個鍵。腳本以 `os.path.join(os.path.dirname(HERE), "scenarios.json")` 讀取。
- [ ] **Step 4:** 執行測試，預期全部 `ok`。
- [ ] **Step 5:** 提交 `feat: mysession-eval 已安裝配置清單與場景判斷`。

### Task 4: `append` 寫入日誌與累積計數

**Files:**
- Modify: `dot_claude/skills/mysession-eval/scripts/mysession-eval`
- Modify: `scripts/tests/mysession_eval_test.py`

**Interfaces:**
- Consumes: Task 2 的 `segment_metrics`、Task 3 的 `inventory`、`detect_scenario`。
- Produces:
  - CLI `append --task T --status {done,partial,aborted} --corrections N --new-requests N --satisfaction {1..5} --sat-source {estimated,user} --basis TEXT --include {yes,no} [--exclude-reason TEXT] [--missed NAME[,NAME...]] [--note TEXT] [--scenario S] [--session ID]`：重新計算本區段的客觀指標（不從 Claude 傳入），組成紀錄追加到 `<MSE_HOME>/log.jsonl`，stdout 印一行摘要。
  - 紀錄鍵：`schema`(=1)、`recorded_at`（ISO 8601 UTC）、`session_id`、`project`、`scenario`、`installed`、`metrics`（`segment_metrics` 結果）、`task`、`status`、`corrections`、`new_requests`、`satisfaction`、`satisfaction_source`、`basis`、`include`(bool)、`exclude_reason`、`missed`（應觸發而未觸發的配置名稱清單，由 Claude 判斷，可空）、`note`。
  - `extract` 輸出新增 `recent_tasks`：日誌中同一 `project` 最近 10 筆的 `task` 名稱（去重、新到舊），供 Claude 判斷是否延續；日誌不存在時為空清單。
  - `scenario_counts(home: str, scenario: str) -> tuple[int, int]`：（列入判定筆數，總筆數）。
  - 摘要行格式：`已記錄：<task>（<scenario>，滿意度 <n>〔推定|使用者確認〕）。<scenario> 已累積 <included> 筆列入判定，場景判定門檻 10 筆` ；`included >= 10` 時句尾加 `，可覆盤`。
  - 驗證：`satisfaction` 非 1～5、`--include no` 卻無 `--exclude-reason`、區段為空時 → `raise Fail`，不寫入。`--scenario` 未給且偵測為 `None` 時記 `"unknown"`。

- [ ] **Step 1: 寫失敗測試**

```python
def test_append_writes_one_line(self):        # 呼叫兩次 → log.jsonl 兩行，皆 schema == 1、include 為 bool
def test_append_record_has_no_user_text(self):  # 使用者訊息含 "SECRETMARK" → log.jsonl 不含 "SECRETMARK"
def test_append_validation(self):             # satisfaction 6 → 結束碼 2；--include no 無理由 → 結束碼 2；兩者 log 皆未寫入
def test_append_empty_segment_refused(self):  # 區段為空 → 結束碼 2，未寫入
def test_append_summary_counter(self):        # 已有 9 筆 backend-dev include → 第 10 筆摘要含 "已累積 10 筆" 與 "可覆盤"；第 9 筆時不含 "可覆盤"
def test_append_unknown_scenario(self):       # 無法偵測且無 --scenario → scenario == "unknown"
def test_append_missed_list(self):            # --missed a,b → missed == ["a", "b"]；未給 → []
def test_extract_recent_tasks(self):          # 日誌有同專案 12 筆、他專案 1 筆 → recent_tasks 長度 10、不含他專案任務
```

- [ ] **Step 2:** 執行測試，預期 FAIL。
- [ ] **Step 3:** 實作 `append`、`scenario_counts`；寫入用 `open(path, "a")` 一次寫一行，目錄不存在時建立。
- [ ] **Step 4:** 執行測試，預期全部 `ok`。
- [ ] **Step 5:** 提交 `feat: mysession-eval 寫入日誌與累積計數`。

### Task 5: `summarize` 覆盤匯總

**Files:**
- Modify: `dot_claude/skills/mysession-eval/scripts/mysession-eval`
- Modify: `scripts/tests/mysession_eval_test.py`

**Interfaces:**
- Consumes: Task 4 的日誌格式。
- Produces:
  - `summarize(records: list[dict], scenario: str | None = None) -> dict`，結構：`{"bad_lines": n, "scenarios": {<s>: {...}}}`，每個場景：
    - `records_total`、`records_included`、`scenario_threshold`(=10)、`scenario_eligible`(bool)、`scenario_missing`（差幾筆，≥0）
    - `tasks`：`[{name, records, sessions, last_status}]`，以 `task` 字串完全相同歸併
    - `satisfaction`：`{dist: {"1".."5": n}, by_source: {estimated: n, user: n}}`（只計列入判定者）
    - `interventions_trend`：`{n, first_half_avg, second_half_avg}`（依 `recorded_at` 排序，`corrections` 平均；n < 4 時兩個平均為 `null`）
    - `items`：`[{kind, name, hash, first_seen, last_seen, records_installed, records_used, uses, missed, item_threshold: 3, item_eligible}]`（`missed` 為該配置名稱出現在紀錄 `missed` 中的筆數），以 `(kind, name, hash)` 為鍵，所以同一配置不同版本分成多項；`records_used` / `uses` 依 `metrics` 中對應的 skills／agents／mcp／rules_loaded 計算（rule 以 path 對應）
    - `used_not_installed`：本場景用到但不在專案清單中的 skill／agent／MCP（多半是全域配置）
    - `denials_by_tool`、`tool_errors_total`、`tokens_avg`
  - CLI `summarize [--scenario S]`：讀 `<MSE_HOME>/log.jsonl`，stdout 輸出上述 JSON；日誌不存在時 `raise Fail("尚無記錄")`。
  - 只用列入判定（`include` 為真）的紀錄計算 `items`、`satisfaction`、`interventions_trend`；`records_total` 含全部。

- [ ] **Step 1: 寫失敗測試**

```python
def test_summarize_thresholds(self):          # 9 筆 include → scenario_eligible False, scenario_missing 1；某 skill 用在 3 筆 → item_eligible True
def test_config_versions_split(self):         # 同一 skill 前 2 筆 hash A、後 2 筆 hash B → items 中兩項，records_installed 各 2，皆非 eligible
def test_summarize_excluded_records(self):    # 1 筆 include=False → records_total 比 records_included 多 1，其滿意度不入 dist
def test_summarize_task_merge(self):          # 同名 task 兩個 session → tasks 中一項，records 2、sessions 2
def test_summarize_skips_bad_lines(self):     # log 中一行非 JSON → bad_lines == 1，其餘正常
def test_summarize_missed_counted(self):      # 2 筆 missed 含 "db-schema-design" → 該 item 的 missed == 2
def test_summarize_used_not_installed(self):  # metrics.skills 有 "superpowers:brainstorming" 但 installed 無 → 出現在 used_not_installed
```

- [ ] **Step 2:** 執行測試，預期 FAIL。
- [ ] **Step 3:** 實作 `summarize` 與子命令。
- [ ] **Step 4:** 執行測試，預期全部 `ok`。
- [ ] **Step 5:** 提交 `feat: mysession-eval 覆盤匯總`。

### Task 6: 技能文件、覆盤規則與設定鏡像

**Files:**
- Create: `dot_claude/skills/mysession-eval/SKILL.md`
- Create: `dot_claude/skills/mysession-eval/references/review.md`
- Modify: `settings/settings.user.json`（`sandbox.excludedCommands` 加 `python3 ~/.claude/skills/mysession-eval/scripts/mysession-eval *`）
- Modify: `dot_claude/settings.json`（同上，鏡像）
- Modify: `dot_claude/README.md`（目錄表加一列；新增「mysession-eval 安裝」小節：`cp -R`、excludedCommands）
- Modify: `scripts/tests/mysession_eval_test.py`

**Interfaces:**
- Consumes: Task 2～5 的子命令與輸出鍵名。

**SKILL.md 必含內容**（繁體中文；結構仿 myplugins，常用規則留本檔）：
- frontmatter：`name: mysession-eval`、`description`（一句：在真實專案試用場景配置時記錄一件事的評估資料並覆盤）、`disable-model-invocation: true`、`argument-hint: "[review [場景] [--final]]"`、`allowed-tools`（見 Global Constraints）。
- 記錄流程：
  1. 執行 `extract`。`segment.empty` 為真 → 告訴使用者「自上次記錄後沒有新活動」，結束。
  2. 只根據輸出推定：任務名稱（與 `recent_tasks` 相近時沿用原名，視為延續）、完成狀態、糾正與新需求次數、推定滿意度與依據、是否列入判定、應觸發而未觸發的配置（對照 `installed`，傳 `--missed`）、備註。依據與備註用概述，不引用使用者原文。
  3. 只在三種情況一次列出問題詢問：推定滿意度 ≤ 3；訊號矛盾；可能不該列入判定。使用者回答過的滿意度用 `--sat-source user`。
  4. 執行 `append`，回覆只照抄腳本摘要行。
- 覆盤：使用者輸入 `review` 時先讀 `references/review.md`。
- 腳本報錯（結束碼 2）時轉述錯誤，不自行改用其他方式找會話檔。

**references/review.md 必含內容**：
- 執行 `summarize [--scenario S]`；不帶 `--final` 為期中覆盤，帶 `--final` 為最終覆盤。
- 判定對照設計稿第 9 條與計畫 3.5：單一配置只看客觀訊號（安裝而從未使用、`missed` 次數、權限拒絕集中、rule 該載入未載入〔注意 Bash 讀檔不載入 rule〕）；滿意度只用於場景整體；未達門檻寫「尚不能判斷，還差 N 筆」；同配置多版本分開陳述。
- 建議「調整／移除」必須寫出：配置檔路徑、改法、依據筆數；證據不足標「觀察中」；無問題時列出看過的面向與筆數。
- 基線對照只做定性：讀 `docs/evaluation/2026-10-baseline.md`、`2026-10-final.md` 的問題清單，標出在試用中再現者（需要本倉庫路徑時用 `AGENT_RULES_REPO`；未設定則略過此項並註明）。
- 輸出結構：場景判定 → 建議（調整／移除）→ 觀察中 → 尚不能判斷 → 推定滿意度分布。
- 期中：結論標「階段性」，不寫回。最終：去識別化（專案目錄名換成 `<場景>-<序號>`、不含真實專案名與原始碼）後，提出寫入 `docs/evaluation/2026-10-final.md` 試用章節的文字，經使用者確認才寫入與提交。

- [ ] **Step 1: 寫失敗測試**

```python
def test_skill_frontmatter(self):         # SKILL.md 有 disable-model-invocation: true、allowed-tools 與 Global Constraints 字串完全相同、name == 目錄名
def test_command_consistent_three_places(self):  # SKILL.md 中所有腳本命令皆以 "python3 ~/.claude/skills/mysession-eval/scripts/mysession-eval " 開頭；
                                                  # settings/settings.user.json 與 dot_claude/settings.json 的 excludedCommands 皆含該前綴 + "*"
def test_review_reference_exists(self):   # references/review.md 存在且含 "尚不能判斷"、"觀察中"、"--final"
```

- [ ] **Step 2:** 執行測試，預期 FAIL。
- [ ] **Step 3:** 撰寫 `SKILL.md`、`references/review.md`，修改兩份 settings 與 README。
- [ ] **Step 4:** 執行 `sh scripts/tests/run-all.sh`，預期全部通過（含既有 `test-settings-templates.sh`）。
- [ ] **Step 5:** 提交 `feat: mysession-eval 技能文件與設定`。

### Task 7: 本機安裝與端到端驗證（需使用者操作）

**Files:**
- Modify: `docs/plans/2026-11-05-mysession-eval-design.md`（「token 預算」補實測值）
- Modify: `docs/plans/2026-10-20-scenario-config-evaluation-plan.md`（3.4 該項打勾、註明實作完成）

- [ ] **Step 1:** 給使用者兩條命令，由使用者執行：`cp -R dot_claude/skills/mysession-eval ~/.claude/skills/`；在本機 `~/.claude/settings.json` 的 `sandbox.excludedCommands` 加入 `python3 ~/.claude/skills/mysession-eval/scripts/mysession-eval *`（建議先備份）。
- [ ] **Step 2:** 在 scratchpad 建臨時專案（放 backend-dev 場景包的 `CLAUDE.md` 與 agents），請使用者在新終端開互動會話：做一件小事（例如讀一個檔、改一行）→ `/mysession-eval` → 再做一件事 → `/mysession-eval` → `/exit`。
- [ ] **Step 3:** 核對：`~/.claude/mysession-eval/log.jsonl` 新增 2 行；第二筆的指標不含第一次呼叫的活動；`scenario == "backend-dev"`；日誌不含使用者原文；兩次記錄的 token 用量（由該會話 jsonl 的 usage 計算，扣除前後差）。驗證後提供刪除這 2 筆測試紀錄的命令給使用者（日誌在 `~/.claude/`）。
- [ ] **Step 4:** 在同一臨時目錄執行 `/mysession-eval review`，確認輸出「尚不能判斷，還差 N 筆」，並記錄 token。
- [ ] **Step 5:** token 實測值超出設計稿預算（記錄 8k、覆盤 12k）時停下，回報使用者並提出刪減方案；未超出則把實測值寫入設計稿，計畫 3.4 打勾，提交 `docs: mysession-eval 端到端驗證與 token 實測`。
