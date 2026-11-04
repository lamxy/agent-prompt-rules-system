#!/bin/sh
# Tests dot_claude/skills/myplugins/scripts/myplugins in temporary directories:
# shared (default) / local (--local, -c) writes keep other keys, dry-run flags,, off removes only one layer, marketplace
# declaration for shared third-party plugins, catalog add/remove, bad input, hint.
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"
TOOL="$REPO_ROOT/dot_claude/skills/myplugins/scripts/myplugins"

if ! command -v python3 >/dev/null 2>&1; then
  printf 'SKIP: python3 not found\n'
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM
FAILS=0

fail() { printf 'FAIL: %s\n' "$1"; FAILS=$((FAILS + 1)); }
pass() { printf 'ok   %s\n' "$1"; }

CD="$TMP/claude"; PROJ="$TMP/proj"
mkdir -p "$CD/plugins/cache/x" "$PROJ/.claude"
cat > "$CD/settings.json" <<'EOF'
{"enabledPlugins": {"frontend-design@claude-plugins-official": true, "hookify@claude-plugins-official": false}}
EOF
cat > "$CD/plugins/installed_plugins.json" <<EOF
{"version": 2, "plugins": {"frontend-design@claude-plugins-official": [{"scope": "user", "installPath": "$CD/plugins/cache/x"}]}}
EOF
cat > "$CD/plugins/known_marketplaces.json" <<'EOF'
{"karpathy-skills": {"source": {"source": "github", "repo": "forrestchang/andrej-karpathy-skills"}}}
EOF
printf '{"permissions": {"allow": ["Bash(ls)"]}}\n' > "$PROJ/.claude/settings.local.json"
(cd "$PROJ" && git init -q)

run() {
  MYPLUGINS_CLAUDE_DIR="$CD" MYPLUGINS_HOME="$TMP/home" MYPLUGINS_PROJECT_DIR="$PROJ" \
    CLAUDE_PROJECT_DIR= python3 "$TOOL" "$@"
}
# jget evaluates fixed expressions written in this file against test JSON only.
jget() { python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(eval(sys.argv[2]))' "$1" "$2"; }

out="$(run)"
printf '%s\n' "$out" | grep -q ' 7\. frontend-design@claude-plugins-official .*啟用（全局）' \
  && pass "list numbers catalog and shows user layer" || fail "list output: $out"
[ -f "$TMP/home/catalog.json" ] && pass "catalog seeded" || fail "catalog not seeded"
printf '%s\n' "$out" | grep -q '未安裝' && pass "list marks not installed" || fail "no 未安裝 mark"

run 8 4 -c >/dev/null
[ "$(jget "$PROJ/.claude/settings.local.json" 'sorted(d["enabledPlugins"])')" = "['chrome-devtools-mcp@claude-plugins-official', 'hookify@claude-plugins-official']" ] \
  && pass "enable with -c writes local" || fail "local enabledPlugins wrong"
[ "$(jget "$PROJ/.claude/settings.local.json" 'd["permissions"]["allow"]')" = "['Bash(ls)']" ] \
  && pass "local keeps other keys" || fail "local lost permissions"
[ ! -f "$PROJ/.claude/settings.json" ] && pass "shared untouched by local enable" || fail "shared written"
run status | grep -q ' 4\. hookify.*啟用（本地）' && pass "local overrides user false" || fail "hookify state"
out="$(run status)"
printf '%s\n' "$out" | grep -q '^已啟用：.*4 hookify（本地）' && printf '%s\n' "$out" | grep -q ' 4\. hookify.*✅ 啟用' \
  && printf '%s\n' "$out" | grep -q ' 6\. .*⬜ 停用' && pass "list shows enabled summary and status symbols" || fail "symbols: $out"

run off 4 --local >/dev/null
[ "$(jget "$PROJ/.claude/settings.local.json" '"hookify@claude-plugins-official" in d["enabledPlugins"]')" = "False" ] \
  && pass "off removes key instead of writing false" || fail "off did not remove"
run status | grep -q ' 4\. hookify.*停用（全局）' && pass "off falls back to user layer" || fail "fallback state"

run off all --local >/dev/null
[ "$(jget "$PROJ/.claude/settings.local.json" '"enabledPlugins" in d')" = "False" ] \
  && pass "off all drops empty enabledPlugins" || fail "empty enabledPlugins left"

for f in --dry-run -t --test; do
  out="$(run 1 "$f")"
  [ ! -f "$PROJ/.claude/settings.json" ] && printf '%s\n' "$out" | grep -q '預演' \
    && pass "$f previews and writes nothing" || fail "$f wrote: $out"
done
if run 1 --local --shared >/dev/null 2>&1; then fail "--local with --shared accepted"; else pass "--local with --shared rejected"; fi

run add andrej-karpathy-skills@karpathy-skills 測試 --category 方法 >/dev/null
n="$(jget "$TMP/home/catalog.json" 'len(d["plugins"])')"
run "$n" >/dev/null
[ -f "$PROJ/.claude/settings.json" ] && pass "default writes shared settings.json" || fail "default did not write shared"
[ "$(jget "$PROJ/.claude/settings.json" 'd["extraKnownMarketplaces"]["karpathy-skills"]["source"]["repo"]')" = "forrestchang/andrej-karpathy-skills" ] \
  && pass "shared third-party plugin declares marketplace" || fail "marketplace not declared"
run frontend-design >/dev/null
[ "$(jget "$PROJ/.claude/settings.json" '"claude-plugins-official" in d.get("extraKnownMarketplaces", {})')" = "False" ] \
  && pass "official marketplace not declared" || fail "official declared"

if run add andrej-karpathy-skills@karpathy-skills >/dev/null 2>&1; then fail "duplicate add accepted"; else pass "duplicate add rejected"; fi
if run add noat >/dev/null 2>&1; then fail "id without @ accepted"; else pass "id without @ rejected"; fi
if run 99 >/dev/null 2>&1; then fail "out of range accepted"; else pass "out of range rejected"; fi
if run nosuch >/dev/null 2>&1; then fail "unknown name accepted"; else pass "unknown name rejected"; fi

out="$(run remove andrej-karpathy-skills)"
[ "$(jget "$TMP/home/catalog.json" 'len(d["plugins"])')" = "21" ] && printf '%s\n' "$out" | grep -q '共享設定仍有' \
  && pass "remove updates catalog and warns about project layer" || fail "remove: $out"

printf '{bad json' > "$PROJ/.claude/settings.local.json"
if run 1 --local >/dev/null 2>&1; then fail "bad json overwritten"; else
  [ "$(cat "$PROJ/.claude/settings.local.json")" = "{bad json" ] && pass "bad json left untouched" || fail "bad json changed"
fi
printf '{}\n' > "$PROJ/.claude/settings.local.json"

run 1 --local >/dev/null
h="$(printf '{"source":"startup"}' | run hint)"
printf '%s\n' "$h" | python3 -c 'import json,sys; m=json.load(sys.stdin)["systemMessage"]; assert "/myplugins 1" in m and "當前目錄已啟用" in m and "frontend-design" in m' \
  && pass "hint emits systemMessage with enabled list" || fail "hint: $h"
[ -z "$(printf '{"source":"compact"}' | run hint)" ] && pass "hint silent on compact" || fail "hint on compact"
EMPTY="$TMP/empty"; mkdir -p "$EMPTY"
h="$(printf '{"source":"startup"}' | MYPLUGINS_PROJECT_DIR="$EMPTY" MYPLUGINS_CLAUDE_DIR="$CD" MYPLUGINS_HOME="$TMP/home" CLAUDE_PROJECT_DIR= python3 "$TOOL" hint)"
printf '%s\n' "$h" | grep -q '當前目錄未啟用' && pass "hint says nothing enabled in plain directory" || fail "hint empty dir: $h"

printf '\n%s failure(s)\n' "$FAILS"
[ "$FAILS" -eq 0 ]
