#!/bin/sh
# Checks that open_supports/INDEX.md lists every support package and that each
# row's scope class matches the package's repo_readme_summary.md.
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"
SUPPORTS_DIR="$REPO_ROOT/open_supports"
INDEX="$SUPPORTS_DIR/INDEX.md"

FAILED=0

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  FAILED=$((FAILED + 1))
}

[ -f "$INDEX" ] || { printf 'FAIL: missing %s\n' "$INDEX" >&2; exit 1; }

CHECKED=0

for pkg_dir in "$SUPPORTS_DIR"/ost_*/; do
  [ -d "$pkg_dir" ] || continue
  pkg="$(basename "$pkg_dir")"

  case "$pkg" in
    *_TEMPLATE) continue ;;
  esac

  CHECKED=$((CHECKED + 1))
  summary="$pkg_dir/repo_readme_summary.md"

  # First "模式 X" in the summary's scope line is the package's class.
  summary_class="$(sed -n 's/.*安装作用域（模式 \([A-D]\).*/\1/p' "$summary" 2>/dev/null | head -n 1)"
  if [ -z "$summary_class" ]; then
    fail "$pkg: repo_readme_summary.md has no '安装作用域（模式 X' line"
    continue
  fi

  # The package row in the "已收录支持包" table: | `pkg` | upstream | purpose | class | examples |
  row="$(grep -F "| \`$pkg\` | [" "$INDEX" | head -n 1 || true)"
  if [ -z "$row" ]; then
    fail "$pkg: not listed in INDEX.md"
    continue
  fi

  index_class="$(printf '%s\n' "$row" | awk -F'|' '{ gsub(/^ +/, "", $5); print substr($5, 1, 1) }')"
  if [ "$index_class" != "$summary_class" ]; then
    fail "$pkg: INDEX.md class '$index_class' does not match summary class '$summary_class'"
  fi

  if ! grep -F "| \`$pkg\` | \`sh " "$INDEX" > /dev/null; then
    fail "$pkg: missing from the install command table in INDEX.md"
  fi
done

# Rows for packages that no longer exist.
for listed in $(sed -n 's/^| `\(ost_[^`{]*\)` | \[.*/\1/p' "$INDEX"); do
  [ -d "$SUPPORTS_DIR/$listed" ] || fail "$listed: listed in INDEX.md but the directory does not exist"
done

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi

printf 'PASS: INDEX.md lists all %d support packages with matching scope classes\n' "$CHECKED"
