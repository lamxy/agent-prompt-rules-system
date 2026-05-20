#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<'USAGE'
Usage:
  sh scripts/install-skill-pkg.sh -f <FLAG> -t <target_skills_dir> [-s <skills_root>] [-F]

Options:
  -f  Skill package flag/identifier (e.g., frontend-dev → skills-frontend-dev/)
  -t  Target skills directory (e.g., /path/to/project/.claude/skills)
  -s  Source skills root (default: <repo>/skills)
  -F  Force overwrite: delete existing same-name skill dirs and recopy
  -h  Show this help message

Examples:
  sh scripts/install-skill-pkg.sh -f frontend-dev -t ~/.claude/skills
  sh scripts/install-skill-pkg.sh -f frontend-dev -t /my/project/.claude/skills -F
USAGE
}

FLAG=""
TARGET=""
SKILLS_ROOT=""
FORCE=0

while getopts "f:t:s:Fh" opt; do
  case "$opt" in
    f) FLAG="$OPTARG" ;;
    t) TARGET="$OPTARG" ;;
    s) SKILLS_ROOT="$OPTARG" ;;
    F) FORCE=1 ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

if [ -z "$FLAG" ] || [ -z "$TARGET" ]; then
  printf 'Error: -f <FLAG> and -t <target_skills_dir> are required.\n' >&2
  usage
  exit 1
fi

if [ -z "$SKILLS_ROOT" ]; then
  SKILLS_ROOT="$REPO_ROOT/skills"
fi

PKG_DIR="$SKILLS_ROOT/skills-$FLAG"

if [ ! -d "$PKG_DIR" ]; then
  printf 'Error: skill package not found: %s\n' "$PKG_DIR" >&2
  exit 1
fi

if [ ! -d "$TARGET" ]; then
  printf 'Error: target directory does not exist: %s\n' "$TARGET" >&2
  exit 1
fi

COPIED=0
SKIPPED=0
FORCED=0

for skill_dir in "$PKG_DIR"/*/; do
  # Skip if no subdirs exist
  [ -d "$skill_dir" ] || continue

  skill_name="$(basename "$skill_dir")"
  dest="$TARGET/$skill_name"

  if [ -d "$dest" ]; then
    if [ "$FORCE" -eq 1 ]; then
      printf '[FORCE] Removing existing: %s\n' "$dest"
      rm -rf "$dest"
      cp -r "$skill_dir" "$dest"
      printf '[COPIED] %s\n' "$skill_name"
      FORCED=$((FORCED + 1))
    else
      printf '[MANUAL] Skill already exists, please handle manually: %s\n' "$dest"
      SKIPPED=$((SKIPPED + 1))
    fi
  else
    cp -r "$skill_dir" "$dest"
    printf '[COPIED] %s\n' "$skill_name"
    COPIED=$((COPIED + 1))
  fi
done

printf '\nDone. copied=%d  forced=%d  manual=%d\n' "$COPIED" "$FORCED" "$SKIPPED"
if [ "$SKIPPED" -gt 0 ]; then
  printf 'Skills marked [MANUAL] were skipped. Remove or rename them in the target, then rerun; or use -F to force overwrite.\n'
fi
