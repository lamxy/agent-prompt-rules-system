#!/bin/sh
# Tests dot_claude/skills/mysession-eval/scripts/mysession-eval with synthetic session logs
# in temporary directories (unittest suite in mysession_eval_test.py).
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

if ! command -v python3 >/dev/null 2>&1; then
  printf 'SKIP: python3 not found\n'
  exit 0
fi

python3 -I "$SCRIPT_DIR/mysession_eval_test.py"
