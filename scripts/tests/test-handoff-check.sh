#!/bin/sh
# Tests dot_claude/skills/myhandoff/scripts/handoff-check (3.0.0) in temporary git repos:
# template fill-in passes check, trigger index <-> GOTCHAS.md consistency (FAIL), secret scan over
# docs/handoff/ (check and pre-commit), pre-commit triggers on any docs/handoff/ file, size/format WARNs,
# old 2.x structure only WARNs, status interruption verdicts, SessionStart wording.
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"
SKILL="$REPO_ROOT/dot_claude/skills/myhandoff"
TOOL="$SKILL/scripts/handoff-check"

if ! command -v python3 >/dev/null 2>&1; then
  printf 'SKIP: python3 not found\n'
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM
FAILS=0

fail() { printf 'FAIL: %s\n' "$1"; FAILS=$((FAILS + 1)); }
pass() { printf 'PASS %s\n' "$1"; }

# gitleaks 結果依本機是否安裝而不同，測試只驗內建樣式。
export PATH="$(printf '%s' "$PATH" | tr ':' '\n' | while read -r d; do [ -x "$d/gitleaks" ] || printf '%s:' "$d"; done)"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@localhost GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@localhost

hc() { python3 "$TOOL" "$@"; }

# expect <描述> <預期 exit> <輸出需含的字串，空字串表示不檢查> -- 指令
expect() {
  desc="$1"; want_rc="$2"; want_text="$3"; shift 4
  set +e
  out="$("$@" 2>&1)"
  rc=$?
  set -e
  if [ "$rc" -ne "$want_rc" ]; then
    fail "$desc (exit $rc, want $want_rc)"; printf '%s\n' "$out" | sed 's/^/    /'
  elif [ -n "$want_text" ] && ! printf '%s' "$out" | grep -qF -- "$want_text"; then
    fail "$desc (missing: $want_text)"; printf '%s\n' "$out" | sed 's/^/    /'
  else
    pass "$desc"
  fi
}

# refute <描述> <不應出現的字串> -- 指令（不論 exit）
refute() {
  desc="$1"; bad="$2"; shift 3
  out="$("$@" 2>&1 || true)"
  if printf '%s' "$out" | grep -qF -- "$bad"; then
    fail "$desc (unexpected: $bad)"; printf '%s\n' "$out" | sed 's/^/    /'
  else
    pass "$desc"
  fi
}

new_repo() {
  dir="$TMP/$1"
  mkdir -p "$dir/docs/handoff"
  git init -q "$dir"
  printf '# x\n\n接手既有工作時先讀 docs/handoff/HANDOFF.md。\n' > "$dir/CLAUDE.md"
  printf 'app\n' > "$dir/app.txt"
  git -C "$dir" add . && git -C "$dir" commit -q -m init
  printf '%s' "$dir"
}

write_handoff() {
  cat > "$1/docs/handoff/HANDOFF.md" <<'EOF'
---
branch: main
head: 0000000
status: active
updated: 2026-11-27
---
# 進度交接

<!-- section: summary -->
## 摘要

- 進度：完成 A
- 停在：B 的設計
- 第一件事：寫 B 的測試

<!-- section: status -->
## 當前狀態

| 任務 | 狀態 | 說明 |
|---|---|---|
| B | 進行中 | 設計已定 |

<!-- section: next -->
## 建議的下一步

1. 寫 B 的測試（相關：G1）

<!-- section: gotchas -->
## 續作時必須知道的事

<!-- block: core -->
### 核心約束

- 不得推送（來源：CLAUDE.md）

<!-- block: triggers -->
### 觸發索引

- 跑測試 → 先清示範資料 → G1
- 改設定 → 用 Edit 不用 sed → G2

<!-- on-demand -->
**以下按需查閱**

<!-- section: pending -->
## 待處理事項

| 項目 | 位置 |
|---|---|
| C 未驗證 | G2 |

<!-- section: run -->
## 本機執行

`make test`

<!-- section: done -->
## 已完成內容

`src/a.py` A 的實作
EOF
  cat > "$1/docs/handoff/GOTCHAS.md" <<'EOF'
# 陷阱細節

### G1 測試逾時

現象：逾時。原因：示範資料。做法：先清除。

### G2 設定被覆寫

現象：設定遺失。原因：sed。做法：用 Edit。
EOF
}

# ---------- 1. 模板填好後通過 check，固定文字不觸發佔位符 ----------
R="$(new_repo tpl)"
python3 - "$SKILL/templates/HANDOFF.md" "$R/docs/handoff/HANDOFF.md" <<'EOF'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
text = re.sub(r"\n<!--\n撰寫提醒.*?-->\n", "\n", text, flags=re.S)
body = text.split("---\n", 2)[2]
body = re.sub(r"\{[^{}]*\}", "x", body)
open(sys.argv[2], "w", encoding="utf-8").write("---\nstatus: active\n---\n" + body)
EOF
(cd "$R" && hc stamp >/dev/null)
expect "filled template passes check" 0 "OK 交接文件檢查通過" -- sh -c "cd '$R' && python3 '$TOOL' check"
refute "filled template: no structure WARN" "WARN" -- sh -c "cd '$R' && python3 '$TOOL' check"
cp "$SKILL/templates/HANDOFF.md" "$R/docs/handoff/HANDOFF.md"
expect "unfilled template fails check" 1 "撰寫提醒區塊尚未刪除" -- sh -c "cd '$R' && python3 '$TOOL' check"

# ---------- 2. 索引一致性 ----------
R="$(new_repo idx)"
write_handoff "$R"
(cd "$R" && hc stamp >/dev/null)
expect "consistent index passes" 0 "OK" -- sh -c "cd '$R' && python3 '$TOOL' check"
refute "consistent index: no WARN" "WARN" -- sh -c "cd '$R' && python3 '$TOOL' check"
sed -i.bak '/→ G2$/d' "$R/docs/handoff/HANDOFF.md"
expect "missing index line fails" 1 "G2 沒有出現在觸發索引" -- sh -c "cd '$R' && python3 '$TOOL' check"
write_handoff "$R"; (cd "$R" && hc stamp >/dev/null)
python3 - "$R/docs/handoff/HANDOFF.md" <<'EOF'
import sys
p = sys.argv[1]; t = open(p, encoding="utf-8").read()
open(p, "w", encoding="utf-8").write(t.replace("→ G2\n", "→ G2\n- 部署 → 先備份 → G9\n"))
EOF
expect "dangling index ref fails" 1 "G9 在 docs/handoff/GOTCHAS.md 沒有對應" -- sh -c "cd '$R' && python3 '$TOOL' check"
write_handoff "$R"; (cd "$R" && hc stamp >/dev/null)
rm "$R/docs/handoff/GOTCHAS.md"
expect "index refs without GOTCHAS.md fails" 1 "GOTCHAS.md 不存在" -- sh -c "cd '$R' && python3 '$TOOL' check"

# ---------- 3. 秘密掃描擴大到 docs/handoff/ ----------
R="$(new_repo sec)"
write_handoff "$R"; (cd "$R" && hc stamp >/dev/null)
printf '\nAKIAABCDEFGHIJKLMNOP\n' >> "$R/docs/handoff/GOTCHAS.md"
expect "secret in GOTCHAS.md fails check" 1 "GOTCHAS.md:" -- sh -c "cd '$R' && python3 '$TOOL' check"
write_handoff "$R"; (cd "$R" && hc stamp >/dev/null)
printf 'token = abcdefghijklmnop\n' > "$R/docs/handoff/notes.md"
expect "secret in other docs/handoff file fails check" 1 "notes.md:1: 疑似 assigned secret" -- sh -c "cd '$R' && python3 '$TOOL' check"
# 帶前綴的環境變數寫法（3.0.1 前因 \b 在底線處不成立而漏掉）
AWS_FAKE="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
for case in "AWS_SECRET_ACCESS_KEY=$AWS_FAKE|AWS secret access key" \
            "secret_access_key: $AWS_FAKE|assigned secret" \
            "DB_PASSWORD=abcdefghij|assigned secret" \
            "export GITHUB_API_TOKEN=\"abcdefghijklmnop\"|assigned secret" \
            "\"db_password\": \"abcdefghij\"|assigned secret"; do
  line="${case%|*}"; label="${case##*|}"
  printf '%s\n' "$line" > "$R/docs/handoff/notes.md"
  expect "prefixed secret caught: ${line%%[=:]*}" 1 "疑似 $label" -- sh -c "cd '$R' && python3 '$TOOL' check"
done
cat > "$R/docs/handoff/notes.md" <<'EOF'
AWS_SECRET_ACCESS_KEY=<從密碼管理器取得>
DB_PASSWORD=$DB_PASSWORD
API_TOKEN="${API_TOKEN}"
export ACCESS_KEY='<填入>'
max_tokens: 4096000000
TOKEN_URL=https://example.com/oauth/token
password_hash 欄位改用 bcrypt
PGPASS: ${DB_PASSWORD:?required_value}
appSecret: process.env.APP_SECRET
apiKey: 'YOUR_SEARCH_API_KEY'
docker run -v "$PWD":/backup:ro busybox
EOF
expect "placeholders and non-secret names not flagged" 0 "OK" -- sh -c "cd '$R' && python3 '$TOOL' check"
rm "$R/docs/handoff/notes.md"

# ---------- 4. pre-commit 觸發條件 ----------
R="$(new_repo pc)"
write_handoff "$R"; (cd "$R" && hc stamp >/dev/null)
git -C "$R" add docs && git -C "$R" commit -q -m handoff
printf '\nAKIAABCDEFGHIJKLMNOP\n' >> "$R/docs/handoff/GOTCHAS.md"
git -C "$R" add docs/handoff/GOTCHAS.md
expect "pre-commit: GOTCHAS-only commit with secret fails" 1 "疑似 AWS access key" -- sh -c "cd '$R' && python3 '$TOOL' git-pre-commit"
git -C "$R" checkout -q HEAD -- docs/handoff/GOTCHAS.md
printf '\n補充說明。\n' >> "$R/docs/handoff/GOTCHAS.md"
git -C "$R" add docs/handoff/GOTCHAS.md
expect "pre-commit: clean GOTCHAS-only commit passes" 0 "" -- sh -c "cd '$R' && python3 '$TOOL' git-pre-commit"
git -C "$R" commit -q -m gotchas --no-verify
git -C "$R" rm -q docs/handoff/GOTCHAS.md
expect "pre-commit: deleting GOTCHAS.md leaves dangling index" 1 "GOTCHAS.md 不存在" -- sh -c "cd '$R' && python3 '$TOOL' git-pre-commit"
git -C "$R" reset -q HEAD -- docs/handoff/GOTCHAS.md && git -C "$R" checkout -q -- docs/handoff/GOTCHAS.md
printf '\n補充。\n' >> "$R/docs/handoff/GOTCHAS.md"; printf 'x\n' >> "$R/app.txt"
git -C "$R" add docs/handoff/GOTCHAS.md app.txt
expect "pre-commit: GOTCHAS plus feature file is mixed" 1 "另外夾帶了：app.txt" -- sh -c "cd '$R' && python3 '$TOOL' git-pre-commit"
git -C "$R" reset -q
expect "pre-commit: no docs/handoff file staged is ignored" 0 "" -- sh -c "cd '$R' && git add app.txt && python3 '$TOOL' git-pre-commit"
git -C "$R" reset -q; git -C "$R" checkout -q -- .

# ---------- 5. 只發 WARN 的項目 ----------
R="$(new_repo warn)"
write_handoff "$R"
python3 - "$R/docs/handoff/HANDOFF.md" <<'EOF'
import sys
p = sys.argv[1]; t = open(p, encoding="utf-8").read()
t = t.replace("- 第一件事：寫 B 的測試\n", "- 第一件事：寫 B 的測試\n- 停在：舊的一條\n")
t = t.replace("1. 寫 B 的測試（相關：G1）\n", "1. 寫 B 的測試（相關：G1）\n2. 已完成：A\n")
t = t.replace("| B | 進行中 | 設計已定 |\n", "| B | 進行中 | 設計已定 |\n" + "| A | 完成 | ok |\n" * 4 + "| D | 待開始 |\n")
t = t.replace("`src/a.py` A 的實作\n", "`src/a.py` A 的實作\n" + "填充文字。" * 1700 + "\n")
t = t.replace("（相關：G1）", "（相關：G1、G7）")
open(p, "w", encoding="utf-8").write(t)
EOF
(cd "$R" && hc stamp >/dev/null)
for w in "全文" "摘要應為三項" "建議的下一步含「已完成」" "4 列已完成" "表格列有 2 欄，表頭是 3 欄" "引用了不存在的條目 G7"; do
  expect "WARN only: $w" 0 "$w" -- sh -c "cd '$R' && python3 '$TOOL' check"
done
python3 - "$R/docs/handoff/HANDOFF.md" <<'EOF'
import sys
p = sys.argv[1]; t = open(p, encoding="utf-8").read()
open(p, "w", encoding="utf-8").write(t.replace("- 跑測試 → 先清示範資料 → G1\n", "".join(f"- 動作{i} → 做法 → G1\n" for i in range(31))))
EOF
expect "WARN only: trigger index too long" 0 "觸發索引 32 行" -- sh -c "cd '$R' && python3 '$TOOL' check"

# ---------- 6. 舊 2.x 結構只出 WARN ----------
R="$(new_repo old)"
write_handoff "$R"
python3 - "$R/docs/handoff/HANDOFF.md" <<'EOF'
import re, sys
p = sys.argv[1]; t = open(p, encoding="utf-8").read()
t = re.sub(r"<!-- block: core -->.*?<!-- on-demand -->\n\*\*以下按需查閱\*\*\n", "### 陷阱\n\n現象、原因、做法。\n\n", t, flags=re.S)
open(p, "w", encoding="utf-8").write(t)
EOF
rm "$R/docs/handoff/GOTCHAS.md"
python3 - "$R/docs/handoff/HANDOFF.md" <<'EOF'
import sys
p = sys.argv[1]; t = open(p, encoding="utf-8").read()
open(p, "w", encoding="utf-8").write(t.replace("（相關：G1）", "").replace("| G2 |", "| 設計文件 |"))
EOF
(cd "$R" && hc stamp >/dev/null)
expect "old structure passes with marker WARN" 0 "缺少停止標記" -- sh -c "cd '$R' && python3 '$TOOL' check"
printf '\n變更日誌提到 `<!-- on-demand -->` 與 `<!-- section: summary -->` 不算錨點。\n' >> "$R/docs/handoff/HANDOFF.md"
expect "inline mention of marker is not the marker" 0 "缺少停止標記" -- sh -c "cd '$R' && python3 '$TOOL' check"
refute "inline mention does not cause order WARN" "章節順序不符" -- sh -c "cd '$R' && python3 '$TOOL' check"
sed -i.bak 's/^<!-- section: summary -->$/摘要錨點被刪/' "$R/docs/handoff/HANDOFF.md"
expect "anchor only mentioned inline is missing" 1 "缺少章節錨點 <!-- section: summary -->" -- sh -c "cd '$R' && python3 '$TOOL' check"

# ---------- 7. status 中斷判定 ----------
R="$(new_repo st)"
write_handoff "$R"; (cd "$R" && hc stamp >/dev/null)
touch -t 202001010000 "$R/app.txt"
printf 'before save\n' > "$TMP/x"; cp "$TMP/x" "$R/app.txt"; touch -t 202001010000 "$R/app.txt"
git -C "$R" add docs && GIT_COMMITTER_DATE="$(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ)" git -C "$R" commit -q -m handoff
expect "status: change older than save is not interruption" 0 "中斷判定：否" -- sh -c "cd '$R' && python3 '$TOOL' status"
printf 'after save\n' >> "$R/app.txt"
expect "status: change after save is interruption" 0 "未提交變更的修改時間晚於交接保存時間：app.txt" -- sh -c "cd '$R' && python3 '$TOOL' status"
printf 'new\n' > "$R/new.txt"
expect "status: untracked file after save is interruption" 0 "new.txt" -- sh -c "cd '$R' && python3 '$TOOL' status"
rm "$R/new.txt"; git -C "$R" checkout -q -- app.txt
git -C "$R" rm -q app.txt
expect "status: deleted file reported separately" 0 "無法判定刪除時間：app.txt" -- sh -c "cd '$R' && python3 '$TOOL' status"
git -C "$R" commit -q -m feature
expect "status: non-handoff commit is interruption" 0 "交接之後有 1 個非交接提交" -- sh -c "cd '$R' && python3 '$TOOL' status"
R="$(new_repo sf)"
write_handoff "$R"; (cd "$R" && hc stamp >/dev/null); git -C "$R" add docs && git -C "$R" commit -q -m handoff
(cd "$R" && hc stamp >/dev/null); git -C "$R" add docs && git -C "$R" commit -q -m stamp
expect "status: clean repo is not interruption" 0 "中斷判定：否" -- sh -c "cd '$R' && python3 '$TOOL' status"
mkdir -p "$R/.git/handoff"
printf -- '---\nevent: stop-failure\nclient: claude\ntime: 2026-11-27T10:00:00\nerror: rate_limit\n---\n' > "$R/.git/handoff/snapshot.md"
expect "status: stop-failure snapshot is interruption" 0 "因 rate_limit 中斷" -- sh -c "cd '$R' && python3 '$TOOL' status"

# ---------- 8. SessionStart 注入措辭 ----------
expect "session-start mentions stop marker" 0 "讀到停止標記" -- sh -c "cd '$R' && printf '{}' | python3 '$TOOL' hook session-start"

if [ "$FAILS" -ne 0 ]; then
  printf '%d failure(s)\n' "$FAILS"
  exit 1
fi
printf 'all handoff-check tests passed\n'
