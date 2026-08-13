#!/bin/sh

set -eu

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
assert_contains() { grep -F -- "$2" "$1" >/dev/null 2>&1 || fail "missing: $2"; }
assert_exit() { [ "$1" -eq "$2" ] || fail "exit=$1 want=$2"; }

[ -f /.dockerenv ] || fail "run this harness inside Docker"

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d /tmp/open-supports-shell.XXXXXX)
cleanup() {
  rm -rf "$tmp"
}
trap cleanup EXIT HUP INT TERM

cd "$ROOT"
TEST_LOG="$tmp/commands.log"
export TEST_LOG
: > "$TEST_LOG"
bin="$tmp/bin"
mkdir -p "$bin" "$tmp/home"
HOME="$tmp/home"
export HOME
[ "$HOME" = "$tmp/home" ] || fail "HOME=$HOME want=$tmp/home"

run_capture() {
  output=$1
  shift
  if "$@" >"$output" 2>&1; then
    RUN_STATUS=0
  else
    RUN_STATUS=$?
  fi
}

write_stub() {
  path=$1
  shift
  printf '%s\n' "$@" > "$bin/$path"
  chmod +x "$bin/$path"
}

write_stub node \
  '#!/bin/sh' \
  'printf "node %s\\n" "$*" >> "$TEST_LOG"' \
  'if [ "${1:-}" = "--version" ]; then printf "v20.19.0\\n"; fi'

write_stub bun \
  '#!/bin/sh' \
  'printf "bun %s\\n" "$*" >> "$TEST_LOG"'

write_stub npm \
  '#!/bin/sh' \
  'printf "npm %s\\n" "$*" >> "$TEST_LOG"' \
  'case "${1:-}" in' \
  '  --version) printf "10.0.0\\n" ;;' \
  '  prefix) [ "${2:-}" = "-g" ] && printf "/tmp/open-supports-npm\\n" ;;' \
  'esac'

write_stub npx \
  '#!/bin/sh' \
  'printf "npx %s\\n" "$*" >> "$TEST_LOG"'

write_stub claude \
  '#!/bin/sh' \
  'printf "claude cwd=%s args=%s\\n" "$PWD" "$*" >> "$TEST_LOG"' \
  'if [ "${1:-}" = "mcp" ] && [ "${2:-}" = "get" ] && [ "${3:-}" = "taskmaster-ai" ]; then' \
  '  [ "${CLAUDE_STUB_LEGACY:-no}" = "yes" ] && exit 0' \
  '  exit 1' \
  'fi' \
  'scope=""' \
  'while [ "$#" -gt 0 ]; do' \
  '  case "$1" in' \
  '    --scope) scope="${2:-}"; shift 2 ;;' \
  '    *) shift ;;' \
  '  esac' \
  'done' \
  'if [ "$scope" = "project" ]; then : > "$PWD/.mcp.json"; fi'

write_stub openspec \
  '#!/bin/sh' \
  'printf "openspec %s\\n" "$*" >> "$TEST_LOG"' \
  'if [ "${1:-}" = "--version" ]; then printf "openspec test\\n"; fi'

write_stub timeout \
  '#!/bin/sh' \
  'printf "timeout %s prompt=%s\\n" "$*" "${GIT_TERMINAL_PROMPT:-unset}" >> "$TEST_LOG"' \
  'seconds=$1' \
  'shift' \
  'exec "$@"'

write_stub gtimeout \
  '#!/bin/sh' \
  'printf "gtimeout %s prompt=%s\\n" "$*" "${GIT_TERMINAL_PROMPT:-unset}" >> "$TEST_LOG"' \
  'seconds=$1' \
  'shift' \
  'exec "$@"'

write_stub git \
  '#!/bin/sh' \
  'printf "git prompt=%s %s\\n" "${GIT_TERMINAL_PROMPT:-unset}" "$*" >> "$TEST_LOG"' \
  'case "${GSTACK_TEST_GIT_FAIL:-}" in' \
  '  clone) [ "${1:-}" = clone ] && exit 124 ;;' \
  '  pull) [ "${1:-}" = -C ] && [ "${3:-}" = pull ] && exit 124 ;;' \
  'esac' \
  'if [ "${1:-}" != "clone" ]; then exit 0; fi' \
  'target=""' \
  'for arg in "$@"; do target="$arg"; done' \
  'repo_url=""' \
  'for arg in "$@"; do' \
  '  case "$arg" in' \
  '    https://github.com/garrytan/gstack.git|https://github.com/msitarzewski/agency-agents.git) repo_url="$arg" ;;' \
  '  esac' \
  'done' \
  'mkdir -p "$target/.git"' \
  'case "$repo_url" in' \
  '  https://github.com/garrytan/gstack.git)' \
  '    mkdir -p "$target/bin"' \
  '    printf "%s\\n" "#!/bin/sh" "printf '\''gstack setup %s\\n'\'' \"\$*\" >> \"\$TEST_LOG\"" "mkdir -p \"\$HOME/.codex/skills\"" ": > \"\$HOME/.codex/skills/gstack-setup-sentinel\"" > "$target/setup"' \
  '    printf "%s\\n" "#!/bin/sh" "test -f \"\$HOME/.codex/skills/gstack-setup-sentinel\"" "printf '\''gstack team %s sentinel=yes\\n'\'' \"\$1\" >> \"\$TEST_LOG\"" > "$target/bin/gstack-team-init"' \
  '    chmod +x "$target/setup" "$target/bin/gstack-team-init"' \
  '    ;;' \
  '  https://github.com/msitarzewski/agency-agents.git)' \
  '    mkdir -p "$target/scripts"' \
  '    printf "%s\\n" "#!/bin/sh" "printf '\''agency upstream %s\\n'\'' \"\$*\" >> \"\$TEST_LOG\"" > "$target/scripts/install.sh"' \
  '    printf "%s\\n" "#!/bin/sh" "exit 0" > "$target/scripts/convert.sh"' \
  '    chmod +x "$target/scripts/install.sh" "$target/scripts/convert.sh"' \
  '    ;;' \
  'esac'

write_stub bash \
  '#!/bin/sh' \
  'printf "bash %s\\n" "$*" >> "$TEST_LOG"' \
  'exec /bin/sh "$@"'

write_stub python3 \
  '#!/bin/sh' \
  'printf "python3 %s\\n" "$*" >> "$TEST_LOG"' \
  'case "${1:-}" in' \
  '  --version) printf "Python 3.11.0\\n" ;;' \
  '  -m)' \
  '    case "${2:-}" in' \
  '      venv)' \
  '        target=$3' \
  '        mkdir -p "$target/bin"' \
  '        printf "%s\\n" "#!/bin/sh" "printf '\''venv python %s\\n'\'' \"\$*\" >> \"\$TEST_LOG\"" "case \"\${1:-}\" in" "  -c) [ -f \"\$0.installed\" ] && exit 0; exit 1 ;;" "  -m) if [ \"\${2:-}\" = pip ]; then for arg in \"\$@\"; do case \"\$arg\" in cognee*) : > \"\$0.installed\" ;; esac; done; fi ;;" "esac" > "$target/bin/python"' \
  '        chmod +x "$target/bin/python"' \
  '        ;;' \
  '    esac' \
  '    ;;' \
  '  -c) exit 1 ;;' \
  'esac'

PATH="$bin:$PATH"
export PATH

find open_supports -type f -name '*.sh' -print > "$tmp/shell-files"
while IFS= read -r file; do
  printf 'syntax: %s\n' "$file"
  sh -n "$file" || fail "syntax: $file"
done < "$tmp/shell-files"

OST_WORKFLOW_STATE_DIR="$tmp/state" \
  sh open_supports/.copilot-skills/ost-support-workflow/scripts/test-state.sh

for installer in \
  open_supports/ost_colbymchenry_codegraph/scripts_for_install/install.sh \
  open_supports/ost_phuryn_pm-skills/scripts_for_install/install.sh \
  open_supports/ost_eyaltoledano_claude-task-master/scripts_for_install/install.sh \
  open_supports/ost_open-gsd_gsd-core/scripts_for_install/install.sh \
  open_supports/ost_msitarzewski_agency-agents/scripts_for_install/install.sh \
  open_supports/ost_garrytan_gstack/scripts_for_install/install.sh \
  open_supports/ost_Fission-AI_OpenSpec/scripts_for_install/install.sh \
  open_supports/ost_deanpeters_Product-Manager-Skills/scripts_for_install/install.sh \
  open_supports/ost_topoteretes_cognee/scripts_for_install/install.sh \
  open_supports/ost_GithubName_RepoName_TEMPLATE/scripts_for_install/install.sh
do
  run_capture "$tmp/help.out" sh "$installer" --help
  assert_exit "$RUN_STATUS" 0
done
[ ! -s "$TEST_LOG" ] || fail 'an installer --help path invoked a stubbed command'

: > "$TEST_LOG"
for unsupported_host in cursor slate openclaw hermes gbrain
do
  run_capture "$tmp/unsupported-$unsupported_host.out" \
    env GSTACK_GIT_TIMEOUT_SECONDS=17 HOME="$tmp/home" \
      sh open_supports/ost_garrytan_gstack/scripts_for_install/install.sh \
        --host="$unsupported_host" --install-dir="$tmp/$unsupported_host"
  if [ "$RUN_STATUS" -ne 1 ]; then
    cat "$tmp/unsupported-$unsupported_host.out" >&2
  fi
  assert_exit "$RUN_STATUS" 1
  case "$unsupported_host" in
    cursor|slate)
      assert_contains "$tmp/unsupported-$unsupported_host.out" \
        "Error: --host=$unsupported_host is unsupported by upstream setup."
      ;;
    openclaw|hermes|gbrain)
      assert_contains "$tmp/unsupported-$unsupported_host.out" \
        "Error: --host=$unsupported_host requires a separate artifact-generation/session workflow."
      ;;
  esac
  [ ! -s "$TEST_LOG" ] || fail "unsupported host invoked Git: $unsupported_host"
done

: > "$TEST_LOG"
for invalid_timeout in 0 -1 1.5 nope
do
  run_capture "$tmp/invalid-timeout.out" \
    env GSTACK_GIT_TIMEOUT_SECONDS="$invalid_timeout" HOME="$tmp/home" \
      sh open_supports/ost_garrytan_gstack/scripts_for_install/install.sh \
        --host=codex --install-dir="$tmp/invalid-timeout"
  assert_exit "$RUN_STATUS" 1
  assert_contains "$tmp/invalid-timeout.out" \
    'Error: GSTACK_GIT_TIMEOUT_SECONDS must be a positive decimal integer.'
  [ ! -s "$TEST_LOG" ] || fail "invalid timeout invoked Git: $invalid_timeout"
done

: > "$TEST_LOG"
gstack_dir="$tmp/gstack"
run_capture "$tmp/gstack.out" \
  env GSTACK_GIT_TIMEOUT_SECONDS=17 HOME="$tmp/home" \
    sh open_supports/ost_garrytan_gstack/scripts_for_install/install.sh \
    --host=codex --team=required --install-dir="$gstack_dir"
if [ "$RUN_STATUS" -ne 0 ]; then
  cat "$tmp/gstack.out" >&2
fi
assert_exit "$RUN_STATUS" 0
assert_contains "$TEST_LOG" "timeout 17 git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git $gstack_dir prompt=0"
assert_contains "$TEST_LOG" "git prompt=0 clone --single-branch --depth 1 https://github.com/garrytan/gstack.git $gstack_dir"
assert_contains "$TEST_LOG" 'gstack setup --host codex'
assert_contains "$TEST_LOG" 'gstack team required sentinel=yes'

: > "$TEST_LOG"
unset GSTACK_GIT_TIMEOUT_SECONDS
default_timeout_dir="$tmp/gstack-default-timeout"
run_capture "$tmp/gstack-default-timeout.out" \
  env HOME="$tmp/home" sh open_supports/ost_garrytan_gstack/scripts_for_install/install.sh \
    --host=auto --install-dir="$default_timeout_dir"
assert_exit "$RUN_STATUS" 0
assert_contains "$TEST_LOG" "timeout 120 git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git $default_timeout_dir prompt=0"

: > "$TEST_LOG"
auto_dir="$tmp/gstack-auto"
run_capture "$tmp/gstack-auto.out" \
  env GSTACK_GIT_TIMEOUT_SECONDS=17 HOME="$tmp/home" \
    sh open_supports/ost_garrytan_gstack/scripts_for_install/install.sh \
      --host=auto --install-dir="$auto_dir"
assert_exit "$RUN_STATUS" 0
assert_contains "$TEST_LOG" "git prompt=0 clone --single-branch --depth 1 https://github.com/garrytan/gstack.git $auto_dir"
assert_contains "$TEST_LOG" 'gstack setup --host auto'

gtimeout_bin="$tmp/bin-gtimeout"
mkdir -p "$gtimeout_bin"
for utility in dirname grep mkdir chmod sed uname
do
  utility_path=$(PATH=/usr/bin:/bin command -v "$utility")
  ln -s "$utility_path" "$gtimeout_bin/$utility"
done
ln -s "$bin/bun" "$gtimeout_bin/bun"
ln -s "$bin/git" "$gtimeout_bin/git"
ln -s "$bin/gtimeout" "$gtimeout_bin/gtimeout"
ln -s "$bin/node" "$gtimeout_bin/node"
: > "$TEST_LOG"
gtimeout_dir="$tmp/gstack-gtimeout"
run_capture "$tmp/gstack-gtimeout.out" \
  env GSTACK_GIT_TIMEOUT_SECONDS=17 HOME="$tmp/home" PATH="$gtimeout_bin" \
    /bin/sh open_supports/ost_garrytan_gstack/scripts_for_install/install.sh \
      --host=auto --install-dir="$gtimeout_dir"
assert_exit "$RUN_STATUS" 0
assert_contains "$TEST_LOG" "gtimeout 17 git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git $gtimeout_dir prompt=0"
assert_contains "$TEST_LOG" "git prompt=0 clone --single-branch --depth 1 https://github.com/garrytan/gstack.git $gtimeout_dir"

: > "$TEST_LOG"
clone_timeout_dir="$tmp/gstack-clone-timeout"
run_capture "$tmp/gstack-clone-timeout.out" \
  env GSTACK_GIT_TIMEOUT_SECONDS=17 GSTACK_TEST_GIT_FAIL=clone HOME="$tmp/home" \
    sh open_supports/ost_garrytan_gstack/scripts_for_install/install.sh \
      --host=codex --install-dir="$clone_timeout_dir"
assert_exit "$RUN_STATUS" 124
assert_contains "$tmp/gstack-clone-timeout.out" \
  "Error: gstack Git clone failed for $clone_timeout_dir (timeout=17s, exit=124)."
assert_contains "$TEST_LOG" "timeout 17 git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git $clone_timeout_dir prompt=0"

: > "$TEST_LOG"
pull_timeout_dir="$tmp/gstack-pull-timeout"
mkdir -p "$pull_timeout_dir/.git"
run_capture "$tmp/gstack-pull-timeout.out" \
  env GSTACK_GIT_TIMEOUT_SECONDS=17 GSTACK_TEST_GIT_FAIL=pull HOME="$tmp/home" \
    sh open_supports/ost_garrytan_gstack/scripts_for_install/install.sh \
      --host=codex --install-dir="$pull_timeout_dir"
assert_exit "$RUN_STATUS" 124
assert_contains "$tmp/gstack-pull-timeout.out" \
  "Error: gstack Git pull failed for $pull_timeout_dir (timeout=17s, exit=124)."
assert_contains "$TEST_LOG" "timeout 17 git -C $pull_timeout_dir pull --ff-only prompt=0"
assert_contains "$TEST_LOG" "git prompt=0 -C $pull_timeout_dir pull --ff-only"

no_timeout_bin="$tmp/bin-no-timeout"
mkdir -p "$no_timeout_bin"
for utility in dirname grep mkdir chmod sed uname
do
  utility_path=$(PATH=/usr/bin:/bin command -v "$utility")
  ln -s "$utility_path" "$no_timeout_bin/$utility"
done
ln -s "$bin/bun" "$no_timeout_bin/bun"
ln -s "$bin/git" "$no_timeout_bin/git"
ln -s "$bin/node" "$no_timeout_bin/node"
: > "$TEST_LOG"
no_timeout_dir="$tmp/gstack-no-timeout"
run_capture "$tmp/gstack-no-timeout.out" \
  env GSTACK_GIT_TIMEOUT_SECONDS=17 HOME="$tmp/home" PATH="$no_timeout_bin" \
    /bin/sh open_supports/ost_garrytan_gstack/scripts_for_install/install.sh \
      --host=auto --install-dir="$no_timeout_dir"
assert_exit "$RUN_STATUS" 0
assert_contains "$tmp/gstack-no-timeout.out" \
  'Warning: timeout/gtimeout unavailable; running Git without a wall-clock limit.'
assert_contains "$TEST_LOG" "git prompt=0 clone --single-branch --depth 1 https://github.com/garrytan/gstack.git $no_timeout_dir"

: > "$TEST_LOG"
taskmaster_project="$tmp/taskmaster-project"
mkdir -p "$taskmaster_project"
run_capture "$tmp/taskmaster.out" \
  sh open_supports/ost_eyaltoledano_claude-task-master/scripts_for_install/install.sh \
    --location=local --project-dir="$taskmaster_project"
assert_exit "$RUN_STATUS" 0
assert_contains "$TEST_LOG" 'npm install task-master-ai@latest'
assert_contains "$TEST_LOG" 'npx task-master --version'

: > "$TEST_LOG"
taskmaster_invocation="$tmp/taskmaster-invocation"
taskmaster_mcp_project="$tmp/taskmaster-mcp-project"
mkdir -p "$taskmaster_invocation" "$taskmaster_mcp_project"
run_capture "$tmp/taskmaster-project-mcp.out" \
  sh -c 'cd "$1" && shift && exec "$@"' sh "$taskmaster_invocation" \
  sh "$ROOT/open_supports/ost_eyaltoledano_claude-task-master/scripts_for_install/install.sh" \
    --local --claude-mcp --tools=standard --mcp-scope=project \
    --project-dir="$taskmaster_mcp_project"
assert_exit "$RUN_STATUS" 0
[ ! -e "$taskmaster_invocation/.mcp.json" ] || fail 'Taskmaster wrote MCP config in invocation directory'
[ -f "$taskmaster_mcp_project/.mcp.json" ] || fail 'Taskmaster did not write MCP config in target project directory'
assert_contains "$TEST_LOG" "claude cwd=$taskmaster_mcp_project args=mcp add task-master-ai --scope project --env TASK_MASTER_TOOLS=standard -- npx -y task-master-ai@latest"

: > "$TEST_LOG"
taskmaster_no_tools_invocation="$tmp/taskmaster-no-tools-invocation"
taskmaster_no_tools_project="$tmp/taskmaster-no-tools-project"
mkdir -p "$taskmaster_no_tools_invocation" "$taskmaster_no_tools_project"
run_capture "$tmp/taskmaster-no-tools-mcp.out" \
  sh -c 'cd "$1" && shift && exec "$@"' sh "$taskmaster_no_tools_invocation" \
  sh "$ROOT/open_supports/ost_eyaltoledano_claude-task-master/scripts_for_install/install.sh" \
    --local --claude-mcp --mcp-scope=project \
    --project-dir="$taskmaster_no_tools_project"
assert_exit "$RUN_STATUS" 0
[ ! -e "$taskmaster_no_tools_invocation/.mcp.json" ] || fail 'Taskmaster no-tools wrote MCP config in invocation directory'
[ -f "$taskmaster_no_tools_project/.mcp.json" ] || fail 'Taskmaster no-tools did not write MCP config in target project directory'
assert_contains "$TEST_LOG" "claude cwd=$taskmaster_no_tools_project args=mcp add task-master-ai --scope project -- npx -y task-master-ai"

: > "$TEST_LOG"
taskmaster_legacy_invocation="$tmp/taskmaster-legacy-invocation"
taskmaster_legacy_project="$tmp/taskmaster-legacy-project"
mkdir -p "$taskmaster_legacy_invocation" "$taskmaster_legacy_project"
run_capture "$tmp/taskmaster-legacy-mcp.out" \
  env CLAUDE_STUB_LEGACY=yes \
    sh -c 'cd "$1" && shift && exec "$@"' sh "$taskmaster_legacy_invocation" \
    sh "$ROOT/open_supports/ost_eyaltoledano_claude-task-master/scripts_for_install/install.sh" \
      --local --claude-mcp --mcp-scope=project \
      --project-dir="$taskmaster_legacy_project"
assert_exit "$RUN_STATUS" 0
assert_contains "$tmp/taskmaster-legacy-mcp.out" \
  'Warning: legacy Claude MCP entry "taskmaster-ai" detected. Verify it points to Taskmaster; run "claude mcp remove taskmaster-ai" from that project to avoid duplicate tools.'
assert_contains "$TEST_LOG" "claude cwd=$taskmaster_legacy_invocation args=mcp get taskmaster-ai"
assert_contains "$TEST_LOG" "claude cwd=$taskmaster_legacy_project args=mcp add task-master-ai --scope project -- npx -y task-master-ai"
if grep -F -- 'mcp remove taskmaster-ai' "$TEST_LOG" >/dev/null 2>&1; then
  fail 'Taskmaster removed a legacy Claude MCP entry'
fi
[ ! -e "$taskmaster_legacy_invocation/.mcp.json" ] || fail 'Taskmaster legacy check wrote MCP config in invocation directory'
[ -f "$taskmaster_legacy_project/.mcp.json" ] || fail 'Taskmaster legacy check did not register canonical MCP in target project directory'

: > "$TEST_LOG"
taskmaster_missing_project="$tmp/taskmaster-missing-project"
run_capture "$tmp/taskmaster-missing-project.out" \
  sh open_supports/ost_eyaltoledano_claude-task-master/scripts_for_install/install.sh \
    --global --claude-mcp --mcp-scope=project \
    --project-dir="$taskmaster_missing_project"
assert_exit "$RUN_STATUS" 1
assert_contains "$tmp/taskmaster-missing-project.out" \
  "Target project directory does not exist: $taskmaster_missing_project"
[ ! -s "$TEST_LOG" ] || fail 'missing Taskmaster project directory invoked npm or Claude'

: > "$TEST_LOG"
run_capture "$tmp/openspec.out" \
  sh open_supports/ost_Fission-AI_OpenSpec/scripts_for_install/install.sh
assert_exit "$RUN_STATUS" 0
assert_contains "$TEST_LOG" 'npm install -g @fission-ai/openspec@latest'
assert_contains "$TEST_LOG" 'openspec --version'

: > "$TEST_LOG"
cognee_venv="$tmp/cognee-venv"
run_capture "$tmp/cognee-dry.out" \
  sh open_supports/ost_topoteretes_cognee/scripts_for_install/install.sh \
    --dry-run --manager=pip --venv-dir="$cognee_venv"
assert_exit "$RUN_STATUS" 0
if grep -F -- 'python3 -m pip' "$TEST_LOG" >/dev/null 2>&1; then
  fail 'cognee dry-run invoked pip'
fi
run_capture "$tmp/cognee-local.out" \
  sh open_supports/ost_topoteretes_cognee/scripts_for_install/install.sh \
    --manager=pip --venv-dir="$cognee_venv"
assert_exit "$RUN_STATUS" 0
assert_contains "$TEST_LOG" "python3 -m venv $cognee_venv"
assert_contains "$TEST_LOG" 'venv python -m pip install --upgrade cognee'

: > "$TEST_LOG"
agency_dir="$tmp/agency-cache"
run_capture "$tmp/agency.out" \
  sh open_supports/ost_msitarzewski_agency-agents/scripts_for_install/install.sh \
    --verify-only --repo-dir="$agency_dir"
assert_exit "$RUN_STATUS" 0
assert_contains "$TEST_LOG" "git prompt=unset clone --depth 1 https://github.com/msitarzewski/agency-agents.git $agency_dir"
assert_contains "$TEST_LOG" "bash $agency_dir/scripts/install.sh --list tools"
assert_contains "$TEST_LOG" 'agency upstream --list tools'
if grep -F -- '--no-interactive' "$TEST_LOG" >/dev/null 2>&1; then
  fail 'agency verify-only invoked installation mode'
fi

printf 'PASS: open_supports shell regressions\n'
