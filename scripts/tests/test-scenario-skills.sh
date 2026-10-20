#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

pass() {
  printf 'PASS: %s\n' "$1"
}

# skills/skills-<FLAG>/ and the bundle's .claude/skills/ are maintained as copies;
# each skill (including references/) must match and declare name/description.
test_skills_match_bundle() {
  flag="$1"
  dim_dir="$REPO_ROOT/skills/skills-$flag"
  bundle_dir="$REPO_ROOT/dot_claude_projects/.claude-$flag/.claude/skills"
  count=0

  for skill in "$dim_dir"/*/SKILL.md; do
    [ -f "$skill" ] || continue
    count=$((count + 1))
    name="$(basename "$(dirname "$skill")")"
    grep -q "^name: $name$" "$skill" || fail "skill name does not match directory: $skill"
    grep -q '^description: ' "$skill" || fail "skill has no description: $skill"
    diff -r "$dim_dir/$name" "$bundle_dir/$name" > /dev/null || fail "bundle copy differs: $flag/$name"
  done

  for skill in "$bundle_dir"/*/SKILL.md; do
    [ -f "$skill" ] || continue
    name="$(basename "$(dirname "$skill")")"
    [ -f "$dim_dir/$name/SKILL.md" ] || fail "bundle skill missing from skills/skills-$flag: $name"
  done

  pass "$flag: $count skills match the bundle copy"
}

for flag in prd-design frontend-dev backend-dev dev-ops; do
  test_skills_match_bundle "$flag"
done
