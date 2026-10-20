#!/bin/sh
# go-fmt.sh - PostToolUse hook：Claude 编辑 .go 文件后自动格式化
#
# 从 stdin 的 hook JSON 读取 tool_input.file_path；只处理已存在的 .go 文件。
# 优先用 goimports（同时整理 import），没有时退回 gofmt；两者都没有时静默跳过。
# 格式化失败（通常是语法错误）时以 exit 2 把错误回报给 Claude，工具调用本身不受影响。
set -eu

input="$(cat)"
# Not a full JSON parser: file_path is a plain string without escaped quotes in practice.
file="$(printf '%s' "$input" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"

case "$file" in
  *.go) ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

if command -v goimports >/dev/null 2>&1; then
  formatter=goimports
elif command -v gofmt >/dev/null 2>&1; then
  formatter=gofmt
else
  exit 0
fi

if ! out="$("$formatter" -w "$file" 2>&1)"; then
  printf '%s 格式化失败：%s\n%s\n' "$formatter" "$file" "$out" >&2
  exit 2
fi
