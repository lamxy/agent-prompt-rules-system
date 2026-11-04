#!/bin/sh
# Installs each real scenario bundle (prd-design, frontend-dev, backend-dev, dev-ops) into a temporary
# project with install-claude-project.sh -N (config only, no support packages, no network) and checks
# the result: every bundle file except README.md is copied, JSON parses, hooks resolve to executable
# files, agent and skill names match their paths, .mcp.json credentials come from ${VAR}, scenario
# support-package entries carry {PROJECT_DIR}, and decisions recorded in docs/ stay in place.
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"
INSTALLER="$REPO_ROOT/scripts/install-claude-project.sh"
# SCENARIO_BUNDLES overrides the source root (used to check that the checks catch broken bundles).
BUNDLES="${SCENARIO_BUNDLES:-$REPO_ROOT/dot_claude_projects}"

if ! command -v python3 >/dev/null 2>&1; then
  printf 'SKIP: python3 not found\n'
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM
FAILS=0

fail() { printf 'FAIL: %s\n' "$1"; FAILS=$((FAILS + 1)); }
pass() { printf 'ok   %s\n' "$1"; }

for flag in prd-design frontend-dev backend-dev dev-ops; do
  src="$BUNDLES/.claude-$flag"
  dst="$TMP/$flag"
  mkdir -p "$dst"

  if sh "$INSTALLER" -f "$flag" -t "$dst" -N -s "$BUNDLES" > "$TMP/$flag.log" 2>&1; then
    pass "$flag: installer exits 0"
  else
    fail "$flag: installer failed (see output below)"
    cat "$TMP/$flag.log"
    continue
  fi

  (cd "$src" && find . -type f ! -path ./README.md | LC_ALL=C sort) > "$TMP/$flag.want"
  (cd "$dst" && find . -type f | LC_ALL=C sort) > "$TMP/$flag.got"
  if diff "$TMP/$flag.want" "$TMP/$flag.got" > "$TMP/$flag.diff"; then
    pass "$flag: file set matches bundle (README.md excluded)"
  else
    fail "$flag: file set differs from bundle"
    cat "$TMP/$flag.diff"
  fi

  if python3 -I - "$flag" "$dst" > "$TMP/$flag.py" 2>&1 <<'PYEOF'
import json, os, re, sys

flag, root = sys.argv[1], sys.argv[2]
problems = []

def load(rel):
    with open(os.path.join(root, rel), encoding="utf-8") as fh:
        return json.load(fh)

def frontmatter_name(path):
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    m = re.match(r"---\n(.*?)\n---\n", text, re.S)
    if not m:
        return None
    for line in m.group(1).splitlines():
        if line.startswith("name:"):
            return line.split(":", 1)[1].strip().strip("'\"")
    return None

if not os.path.getsize(os.path.join(root, "CLAUDE.md")):
    problems.append("CLAUDE.md is empty")

for dirpath, _, files in os.walk(root):
    for name in files:
        if name.endswith(".json"):
            rel = os.path.relpath(os.path.join(dirpath, name), root)
            try:
                load(rel)
            except ValueError as exc:
                problems.append("invalid JSON %s: %s" % (rel, exc))

settings = load(".claude/settings.json")

# Hook commands that point into the project must resolve to an executable file.
for groups in settings.get("hooks", {}).values():
    for group in groups:
        for hook in group.get("hooks", []):
            cmd = hook.get("command", "")
            m = re.match(r'"?\$\{?CLAUDE_PROJECT_DIR\}?"?/(\S+)', cmd)
            if m:
                path = os.path.join(root, m.group(1).strip('"'))
                if not os.path.isfile(path):
                    problems.append("hook target missing: " + cmd)
                elif not os.access(path, os.X_OK):
                    problems.append("hook target not executable: " + cmd)

agents = os.path.join(root, ".claude", "agents")
for name in sorted(os.listdir(agents)) if os.path.isdir(agents) else []:
    want = name[:-3]
    got = frontmatter_name(os.path.join(agents, name))
    if got != want:
        problems.append("agent %s: frontmatter name %r" % (name, got))

skills = os.path.join(root, ".claude", "skills")
for name in sorted(os.listdir(skills)) if os.path.isdir(skills) else []:
    got = frontmatter_name(os.path.join(skills, name, "SKILL.md"))
    if got != name:
        problems.append("skill %s: frontmatter name %r" % (name, got))

# Credentials in .mcp.json must come from the environment, never literal values.
secret_key = re.compile(r"(PASSWORD|TOKEN|SECRET|API_?KEY|AUTHORIZATION)", re.I)
env_ref = re.compile(r"^\$\{[A-Za-z_][A-Za-z0-9_]*(:-[^}]*)?\}$")
if os.path.exists(os.path.join(root, ".mcp.json")):
    for server, cfg in load(".mcp.json").get("mcpServers", {}).items():
        for section in ("env", "headers"):
            for key, value in (cfg.get(section) or {}).items():
                if secret_key.search(key) and not env_ref.match(str(value)):
                    problems.append("%s.%s.%s is not a ${VAR} reference" % (server, section, key))
                if secret_key.search(key) and ":-" in str(value):
                    problems.append("%s.%s.%s has a default value" % (server, section, key))

# Scenario lists are project-level: every active entry must carry {PROJECT_DIR}.
active = []
with open(os.path.join(root, ".claude", "open_supports_name_list.txt"), encoding="utf-8") as fh:
    for line in fh:
        line = line.strip()
        if line and not line.startswith("#"):
            active.append(line)
            if "{PROJECT_DIR}" not in line:
                problems.append("support entry without {PROJECT_DIR}: " + line)

# Decisions recorded in docs/ (2026-11-04): gsd-core is never enabled by default;
# OpenSpec stays the backend-dev default; docker compose down asks in frontend, backend, dev-ops.
if any(e.split()[0] == "open-gsd/gsd-core" for e in active):
    problems.append("gsd-core is enabled by default")
if flag == "backend-dev" and not any(e.split()[0] == "Fission-AI/OpenSpec" for e in active):
    problems.append("OpenSpec is not enabled by default")
if flag in ("frontend-dev", "backend-dev", "dev-ops"):
    ask = settings.get("permissions", {}).get("ask", [])
    for rule in ("Bash(docker compose down*)", "Bash(docker-compose down*)"):
        if rule not in ask:
            problems.append("permissions.ask missing " + rule)

for p in problems:
    print(p)
sys.exit(1 if problems else 0)
PYEOF
  then
    pass "$flag: JSON, hooks, names, .mcp.json credentials, support list, recorded decisions"
  else
    fail "$flag: content checks"
    sed 's/^/     /' "$TMP/$flag.py"
  fi
done

printf '\n%s failure(s)\n' "$FAILS"
[ "$FAILS" -eq 0 ]
