#!/bin/sh
# Checks the gstack wrapper's default checkout location and the setup flags it
# passes, using stub git/bun and a fake checkout (no network, temporary HOME).
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"
INSTALLER="$REPO_ROOT/open_supports/ost_garrytan_gstack/scripts_for_install/install.sh"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT HUP INT TERM

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

pass() {
  printf 'PASS: %s\n' "$1"
}

# Stub git and bun so the wrapper's prerequisite check and `git pull` succeed.
mkdir -p "$TMP_DIR/bin"
printf '#!/bin/sh\nexit 0\n' > "$TMP_DIR/bin/git"
printf '#!/bin/sh\nexit 0\n' > "$TMP_DIR/bin/bun"
chmod +x "$TMP_DIR/bin/git" "$TMP_DIR/bin/bun"

# new_home <name> [saved config keys...]: a HOME with a fake checkout at the
# default location; setup records its arguments, gstack-config reports the
# given keys as saved.
new_home() {
  home="$TMP_DIR/$1"
  shift
  checkout="$home/.local/share/gstack"
  mkdir -p "$checkout/.git" "$checkout/bin"
  printf '#!/bin/sh\nprintf "%%s\\n" "$*" > "%s/setup-args"\n' "$home" > "$checkout/setup"
  printf '#!/bin/sh\n[ "$1" = has ] || exit 2\ncase " %s " in *" $2 "*) exit 0 ;; esac\nexit 1\n' "$*" > "$checkout/bin/gstack-config"
  chmod +x "$checkout/setup" "$checkout/bin/gstack-config"
}

test_defaults_on_first_install() {
  new_home first
  HOME="$home" PATH="$TMP_DIR/bin:$PATH" sh "$INSTALLER" > "$home/out" 2>&1 || fail "installer failed: $(cat "$home/out")"
  [ "$(cat "$home/setup-args")" = "--prefix --no-timeline-stop-hook --no-plan-tune-hooks" ] \
    || fail "unexpected setup args: $(cat "$home/setup-args")"
  pass "first install checks out to ~/.local/share/gstack and passes prefix and hook-off flags"
}

test_saved_choices_are_respected() {
  new_home saved skill_prefix timeline_stop_hook plan_tune_hooks
  HOME="$home" PATH="$TMP_DIR/bin:$PATH" sh "$INSTALLER" > "$home/out" 2>&1 || fail "installer failed: $(cat "$home/out")"
  [ -z "$(cat "$home/setup-args")" ] || fail "expected no flags, got: $(cat "$home/setup-args")"
  pass "keys already saved with gstack-config are not overridden"
}

test_other_hosts_get_no_claude_flags() {
  new_home codex
  HOME="$home" PATH="$TMP_DIR/bin:$PATH" sh "$INSTALLER" --host=codex > "$home/out" 2>&1 || fail "installer failed: $(cat "$home/out")"
  [ "$(cat "$home/setup-args")" = "--host codex" ] || fail "unexpected setup args: $(cat "$home/setup-args")"
  pass "non-Claude hosts get only --host"
}

test_legacy_checkout_stops_before_setup() {
  new_home legacy
  mkdir -p "$home/.claude/skills/gstack/.git"
  if HOME="$home" PATH="$TMP_DIR/bin:$PATH" sh "$INSTALLER" > "$home/out" 2>&1; then
    fail "expected failure with a legacy checkout in ~/.claude/skills/gstack"
  fi
  [ ! -f "$home/setup-args" ] || fail "setup ran despite the legacy checkout"
  grep -F -- '--install-dir=' "$home/out" > /dev/null || fail "missing guidance: $(cat "$home/out")"
  [ -d "$home/.claude/skills/gstack/.git" ] || fail "legacy checkout was modified"
  pass "a legacy checkout in ~/.claude/skills/gstack stops the install untouched"
}

test_legacy_checkout_can_be_updated_in_place() {
  new_home inplace
  mkdir -p "$home/.claude/skills"
  mv "$home/.local/share/gstack" "$home/.claude/skills/gstack"
  HOME="$home" PATH="$TMP_DIR/bin:$PATH" sh "$INSTALLER" --install-dir="$home/.claude/skills/gstack" > "$home/out" 2>&1 \
    || fail "installer failed: $(cat "$home/out")"
  [ -f "$home/setup-args" ] || fail "setup did not run"
  pass "--install-dir pointing at the legacy checkout updates it in place"
}

test_defaults_on_first_install
test_saved_choices_are_respected
test_other_hosts_get_no_claude_flags
test_legacy_checkout_stops_before_setup
test_legacy_checkout_can_be_updated_in_place
