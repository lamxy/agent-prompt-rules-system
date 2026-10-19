#!/bin/sh
# Runs shell syntax checks and every test-*.sh in this directory.
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"
LOG_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$LOG_DIR"
}

trap cleanup EXIT HUP INT TERM

TOTAL=0
FAILED=0

for script in "$REPO_ROOT"/scripts/*.sh "$REPO_ROOT"/scripts/multi_client_support/*.sh "$SCRIPT_DIR"/*.sh; do
  if ! sh -n "$script"; then
    printf '[SYNTAX] %s\n' "$script" >&2
    FAILED=$((FAILED + 1))
  fi
done

for test_script in "$SCRIPT_DIR"/test-*.sh; do
  [ -f "$test_script" ] || continue

  test_name="$(basename "$test_script" .sh)"
  log_file="$LOG_DIR/$test_name.log"
  TOTAL=$((TOTAL + 1))

  if sh "$test_script" > "$log_file" 2>&1; then
    printf '[PASS] %s (%s)\n' "$test_name" "$(grep -c '^PASS' "$log_file" || true)"
  else
    printf '[FAIL] %s\n' "$test_name"
    tail -n 20 "$log_file" | sed 's/^/    /'
    FAILED=$((FAILED + 1))
  fi
done

printf '\nDone. tests=%d failed=%d\n' "$TOTAL" "$FAILED"
[ "$FAILED" -eq 0 ]
