#!/bin/sh
# Manual smoke test (not part of scripts/tests/run-all.sh): checks that a representative sample of the
# permission rules (global ~/.claude/settings.json plus each scenario template) behaves as intended.
#
# For each scenario it installs the bundle into a temporary project (install-claude-project.sh -N,
# git init, one commit, no remote) and runs one `claude -p --permission-mode default --allowedTools Bash`
# session that executes the scenario's commands one by one. --allowedTools Bash allows everything
# else, so a command counts as:
#   deny   tool result says "Permission to use Bash with command ... has been denied"
#   ask    tool result says Claude requested permission that was not granted (-p cannot prompt)
#   allow  the command ran
# Commands the model skipped or rewrote are rerun one per session.
#
# Every command is harmless if a rule fails to stop it: it prints --help, points at a missing target,
# a refused port (1) or the TEST-NET address 192.0.2.1 with a timeout, or runs in the temporary repo.
# `env` is not tested: if it ran it would print the environment into the transcript.
#
# Read cases are judged by whether the content leaked, not by which layer stopped it. With the sandbox on
# and autoAllowBashIfSandboxed, sandboxed commands skip the permission check and Read deny rules are
# enforced by the sandbox instead ("Operation not permitted"). `blocked` therefore accepts deny, ask or an
# OS-level refusal; home files are probed with `: < file`, which opens the file without reading it.
# Known gap (Claude Code 2.1.318, sandbox off): `(cmd < file) 2>/dev/null` is not checked against Read deny
# rules, while `cmd < file` and `(cmd < file)` are. With the sandbox on, the sandbox still blocks it.
# The `prd-design@nosandbox` group repeats the reads with the sandbox off (settings.local.json), where
# only the permission layer is left. There, Read deny rules on Bash file commands are bypassed when the
# RTK hook rewrites the command (RTK answers "allow" and honours only Bash(...) rules) unless RTK's
# [hooks] exclude_commands covers those paths; see settings/README.md.
#
# Uses your real global settings, so results describe this machine. Calls the model (haiku):
# roughly 0.3-0.6M input tokens, mostly cache reads (estimate). Needs a logged-in `claude` CLI.
#
# Usage: sh scripts/smoke/permissions-smoke.sh [FLAG ...]   (default: all four scenarios)
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"
INSTALLER="$REPO_ROOT/scripts/install-claude-project.sh"
BUNDLES="${SCENARIO_BUNDLES:-$REPO_ROOT/dot_claude_projects}"
MODEL="${SMOKE_MODEL:-haiku}"

if ! command -v claude >/dev/null 2>&1; then
  printf 'SKIP: claude CLI not found\n'
  exit 0
fi

TMP="$(mktemp -d)"
if [ "${SMOKE_KEEP:-0}" = 1 ]; then
  printf 'SMOKE_KEEP=1: session transcripts kept in %s\n' "$TMP"
else
  trap 'rm -rf "$TMP"' EXIT INT TERM
fi

# <scenario>|<expected: deny|ask|allow|blocked|opened>|<command>|<rule under test>
# Commands must not contain "|" (the field separator).
cat > "$TMP/cases.txt" <<'EOF'
prd-design|allow|echo c3-control|control
prd-design|deny|rm -rf ./c3-none-dir|global rm -rf *
prd-design|deny|git push --force origin main|global git push --force*
prd-design|deny|git reset --hard HEAD|global git reset --hard *
prd-design|deny|git clean -fd -n|global git clean -fd *
prd-design|deny|sh -c 'echo hi'|global sh -c *
prd-design|deny|eval echo hi|global eval *
prd-design|deny|sudo -n true|global sudo *
prd-design|deny|chmod 777 ./c3-none-file|global chmod 777 *
prd-design|blocked|cat ./.env|global Read(./**/.env) (fake file in the temp project)
prd-design|allow|cat ./.env.example|.env.example is not in the Read deny list
prd-design|blocked|if (: < ~/.codex/auth.json) 2>/dev/null; then echo OPENED; else echo BLOCKED; fi|global Read(~/.codex/auth.json)
prd-design|blocked|if (: < ~/.zshrc) 2>/dev/null; then echo OPENED; else echo BLOCKED; fi|sandbox denyRead (no Read rule)
prd-design@nosandbox|opened|if (: < ~/.zshrc) 2>/dev/null; then echo OPENED; else echo BLOCKED; fi|probe: sandbox really off
prd-design@nosandbox|blocked|cat ./.env|Read deny, no sandbox (needs RTK exclude)
prd-design@nosandbox|allow|cat ./.env.example|not in the Read deny list
prd-design@nosandbox|blocked|if head -c 1 ~/.claude.json > /dev/null; then echo OPENED; else echo BLOCKED; fi|Read deny, no sandbox (needs RTK exclude)
prd-design@nosandbox|blocked|: < ~/.codex/auth.json && echo OPENED|Read deny on < redirect, no sandbox
prd-design@nosandbox|opened|(cat < ./.env) 2>/dev/null|known gap: < inside ( ) with an outer redirect is not checked (fake file)
prd-design|deny|mysql -h 127.0.0.1 -P 1 -e 'DROP TABLE x'|global *DROP TABLE*
prd-design|deny|psql -h 127.0.0.1 -p 1 -c 'DELETE FROM x'|global psql *-c *DELETE*
prd-design|deny|docker volume rm c3-none-vol|global docker volume rm *
prd-design|deny|docker system prune --help|global docker system prune *
prd-design|deny|ssh -o ConnectTimeout=3 192.0.2.1 true|global ssh *
prd-design|ask|mysqldump --help|global ask mysqldump * (prefix)
prd-design|allow|echo "$(mysqldump --version)"|known gap: prefix ask misses $(...)
prd-design|allow|docker compose down --help|global allow, no scenario ask
frontend-dev|ask|docker compose down --help|scenario docker compose down*
frontend-dev|ask|docker compose -p c3probe-none down|scenario docker compose * down*
backend-dev|deny|redis-cli -p 1 FLUSHDB|scenario redis-cli *FLUSHDB*
backend-dev|deny|mongosh --nodb --eval 'db.x.drop()'|scenario mongosh *--eval *drop*
backend-dev|ask|docker compose down --help|scenario docker compose down*
dev-ops|ask|terraform apply -help|scenario terraform apply*
dev-ops|ask|docker compose up --help|scenario ask before global allow
dev-ops|ask|docker context use --help|scenario docker context use *
dev-ops|deny|docker volume rm c3-none-vol|global deny before scenario ask
EOF

[ "$#" -gt 0 ] || set -- prd-design prd-design@nosandbox frontend-dev backend-dev dev-ops

for flag in "$@"; do
  dst="$TMP/proj-$flag"
  mkdir -p "$dst"
  sh "$INSTALLER" -f "${flag%@*}" -t "$dst" -N -s "$BUNDLES" > "$TMP/$flag.install" 2>&1 || {
    printf 'FAIL: %s: install failed\n' "$flag"; cat "$TMP/$flag.install"; exit 1; }
  case "$flag" in
    *@nosandbox) printf '{"sandbox": {"enabled": false}}\n' > "$dst/.claude/settings.local.json" ;;
  esac
  printf 'SMOKE_FAKE=1\n' > "$dst/.env"; printf 'SMOKE_FAKE=\n' > "$dst/.env.example"
  (cd "$dst" && git init -q && git add -A && git -c user.name=smoke -c user.email=smoke@example.invalid commit -qm init)
done

python3 -I - "$TMP" "$MODEL" "$@" <<'PYEOF'
import json, os, subprocess, sys

tmp, model, flags = sys.argv[1], sys.argv[2], sys.argv[3:]
cases = []
with open(os.path.join(tmp, "cases.txt"), encoding="utf-8") as fh:
    for line in fh:
        flag, expect, cmd, rule = line.rstrip("\n").split("|", 3)
        if flag in flags:
            cases.append({"flag": flag, "expect": expect, "cmd": cmd, "rule": rule})

PROMPT = ("Permission-rule test. Run each command below with the Bash tool, one command per tool call, "
          "exactly as written (byte for byte), in the listed order. Do not combine, edit, explain, or "
          "retry them, and do not run anything else. If a command is denied or fails, go on to the next. "
          "After the last one, reply DONE.\n\n")

def run_session(cwd, cmds, tag):
    prompt = PROMPT + "\n".join("%d. %s" % (i + 1, c) for i, c in enumerate(cmds))
    out = os.path.join(tmp, "session-%s.json" % tag)
    with open(out, "w", encoding="utf-8") as fh:
        subprocess.run(["claude", "-p", prompt, "--model", model, "--permission-mode", "default",
                        "--allowedTools", "Bash", "--output-format", "json"],
                       cwd=cwd, stdout=fh, stderr=subprocess.STDOUT, check=False)
    try:
        with open(out, encoding="utf-8") as fh:
            events = json.load(fh)
    except ValueError:
        return {}
    uses, results = {}, {}
    for ev in events if isinstance(events, list) else []:
        content = (ev.get("message") or {}).get("content") if isinstance(ev, dict) else None
        for block in content if isinstance(content, list) else []:
            if not isinstance(block, dict):
                continue
            if block.get("type") == "tool_use" and block.get("name") == "Bash":
                uses[block["id"]] = block.get("input", {}).get("command", "")
            elif block.get("type") == "tool_result":
                body = block.get("content")
                if isinstance(body, list):
                    body = " ".join(b.get("text", "") for b in body if isinstance(b, dict))
                results[block.get("tool_use_id")] = str(body or "")
    seen = {}
    for uid, cmd in uses.items():
        text = results.get(uid, "")
        if ("has been denied" in text and text.startswith("Permission to use Bash")) or \
                ("was blocked by a deny rule" in text and text.startswith("Input redirection")):
            seen.setdefault(cmd, "deny")
        elif "requested permissions" in text and "granted" in text:
            seen.setdefault(cmd, "ask")
        elif "SMOKE_FAKE=1" in text or "OPENED" in text:
            seen.setdefault(cmd, "opened")
        elif "Operation not permitted" in text or "BLOCKED" in text:
            seen.setdefault(cmd, "blocked")
        else:
            seen.setdefault(cmd, "allow")
    return seen

# blocked = the content did not reach the model, whichever layer stopped it.
ACCEPT = {"blocked": ("deny", "ask", "blocked")}

for flag in flags:
    group = [c for c in cases if c["flag"] == flag]
    cwd = os.path.join(tmp, "proj-" + flag)
    seen = run_session(cwd, [c["cmd"] for c in group], flag)
    for i, c in enumerate(group):
        if c["cmd"] not in seen:
            seen.update(run_session(cwd, [c["cmd"]], "%s-retry%d" % (flag, i)))
        c["got"] = seen.get(c["cmd"], "not-run")

fails = 0
print("     %-21s %-7s %-7s %-44s %s" % ("scenario", "expect", "got", "command", "rule"))
for c in cases:
    mark = "ok  " if c["got"] in ACCEPT.get(c["expect"], (c["expect"],)) else "FAIL"
    fails += mark == "FAIL"
    print("%s %-21s %-7s %-7s %-44s %s" % (mark, c["flag"], c["expect"], c["got"], c["cmd"][:44], c["rule"]))
print("\n%d case(s), %d failure(s)" % (len(cases), fails))
sys.exit(1 if fails else 0)
PYEOF
