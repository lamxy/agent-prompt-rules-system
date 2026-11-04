#!/bin/sh
# Manual smoke test (not part of scripts/tests/run-all.sh): installs each scenario bundle into a
# temporary project (install-claude-project.sh -N) and runs `claude mcp list` there, to confirm that
# Claude Code reads the project's .mcp.json.
#
# Pass: every server in the bundle's .mcp.json is listed as "Pending approval" (a fresh project has not
# approved them, so they are not connected), no project server is listed for bundles without
# .mcp.json, and the diagnostics contain no [Error] and no warning other than missing environment
# variables (expected: the temporary project sets none).
#
# Needs a logged-in `claude` CLI. Makes no model calls (no tokens), but `claude mcp list` health-checks
# your user-level and plugin MCP servers, so those are contacted over the network.
#
# Usage: sh scripts/smoke/claude-config-smoke.sh [FLAG ...]   (default: all four scenarios)
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"
INSTALLER="$REPO_ROOT/scripts/install-claude-project.sh"
# SCENARIO_BUNDLES overrides the source root (used to check that the smoke test catches broken bundles).
BUNDLES="${SCENARIO_BUNDLES:-$REPO_ROOT/dot_claude_projects}"

if ! command -v claude >/dev/null 2>&1; then
  printf 'SKIP: claude CLI not found\n'
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM
FAILS=0

fail() { printf 'FAIL: %s\n' "$1"; FAILS=$((FAILS + 1)); }
pass() { printf 'ok   %s\n' "$1"; }

[ "$#" -gt 0 ] || set -- prd-design frontend-dev backend-dev dev-ops

for flag in "$@"; do
  dst="$TMP/$flag"
  mkdir -p "$dst"
  if ! sh "$INSTALLER" -f "$flag" -t "$dst" -N -s "$BUNDLES" > "$TMP/$flag.install" 2>&1; then
    fail "$flag: install failed"
    cat "$TMP/$flag.install"
    continue
  fi
  (cd "$dst" && claude mcp list > "$TMP/$flag.out" 2>&1) || true

  if python3 -I - "$dst" "$TMP/$flag.out" > "$TMP/$flag.py" 2>&1 <<'PYEOF'
import json, os, re, sys

root, out_path = sys.argv[1], sys.argv[2]
with open(out_path, encoding="utf-8", errors="replace") as fh:
    text = fh.read()
# Drop ANSI colour codes and OSC 8 hyperlinks.
text = re.sub(r"\x1b\]8;[^\x07\x1b]*(\x07|\x1b\\)", "", text)
text = re.sub(r"\x1b\[[0-9;]*[A-Za-z]", "", text)

want = set()
mcp = os.path.join(root, ".mcp.json")
if os.path.exists(mcp):
    with open(mcp, encoding="utf-8") as fh:
        want = set(json.load(fh).get("mcpServers", {}))

problems = []
pending = set(re.findall(r"^([A-Za-z0-9_.-]+): .* - \S* ?Pending approval", text, re.M))
for name in sorted(want - pending):
    problems.append("server %s from .mcp.json not listed as Pending approval" % name)
for name in sorted(pending - want):
    problems.append("unexpected pending server: " + name)
for line in text.splitlines():
    if "[Error]" in line:
        problems.append(line.strip())
    elif "[Warning]" in line and "Missing environment variables" not in line:
        problems.append(line.strip())

print("pending: " + (", ".join(sorted(pending)) or "(none)"))
for p in problems:
    print(p)
sys.exit(1 if problems else 0)
PYEOF
  then
    pass "$flag: $(head -1 "$TMP/$flag.py")"
  else
    fail "$flag: claude mcp list"
    sed 's/^/     /' "$TMP/$flag.py"
    printf '     --- raw output ---\n'
    sed 's/^/     /' "$TMP/$flag.out"
  fi
done

printf '\n%s failure(s)\n' "$FAILS"
[ "$FAILS" -eq 0 ]
