#!/bin/sh
# Checks settings/*.json templates: valid JSON, every third-party marketplace an
# enabled plugin uses is declared, and plugin names exist in the marketplace
# catalogs cached under ~/.claude/plugins (read-only; uncached ones are skipped).
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"

if ! command -v python3 >/dev/null 2>&1; then
  printf 'SKIP: python3 not found\n'
  exit 0
fi

python3 - "$REPO_ROOT/settings" "${CLAUDE_PLUGINS_DIR:-$HOME/.claude/plugins}" <<'EOF'
import glob
import json
import os
import sys

settings_dir, plugins_dir = sys.argv[1:3]

# Marketplaces that need no extraKnownMarketplaces entry.
BUILT_IN = {"claude-plugins-official", "anthropic-plugin-directory"}

catalogs = {}
for path in glob.glob(os.path.join(plugins_dir, "marketplaces", "*", ".claude-plugin", "marketplace.json")):
    try:
        with open(path, encoding="utf-8") as handle:
            data = json.load(handle)
        catalogs[data["name"]] = {plugin["name"] for plugin in data.get("plugins", [])}
    except (OSError, ValueError, KeyError):
        continue

failures = []
skipped = set()
files = sorted(glob.glob(os.path.join(settings_dir, "settings.*.json")))

for path in files:
    name = os.path.basename(path)
    try:
        with open(path, encoding="utf-8") as handle:
            data = json.load(handle)
    except ValueError as error:
        failures.append(f"{name}: invalid JSON ({error})")
        continue

    declared = set(data.get("extraKnownMarketplaces", {}))
    for key in data.get("enabledPlugins", {}):
        if "@" not in key:
            failures.append(f"{name}: plugin '{key}' has no @marketplace")
            continue
        plugin, market = key.rsplit("@", 1)
        if market not in BUILT_IN and market not in declared:
            failures.append(f"{name}: '{key}' uses marketplace '{market}' that is not declared")
        if market in catalogs:
            if plugin not in catalogs[market]:
                failures.append(f"{name}: '{plugin}' not found in cached marketplace '{market}'")
        elif market != "anthropic-plugin-directory":
            skipped.add(market)

    permissions = data.get("permissions", {})
    for rule_type in ("allow", "ask", "deny"):
        rules = permissions.get(rule_type, [])
        if not isinstance(rules, list) or not all(isinstance(rule, str) for rule in rules):
            failures.append(f"{name}: permissions.{rule_type} must be a list of strings")

for failure in failures:
    print(f"FAIL: {failure}", file=sys.stderr)

if skipped:
    print(f"NOTE: marketplaces not cached locally, plugin names not checked: {', '.join(sorted(skipped))}")

if failures:
    sys.exit(1)

print(f"PASS: {len(files)} settings templates are valid and reference declared marketplaces")
EOF
