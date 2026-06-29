#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
STATE_SH="$SCRIPT_DIR/state.sh"

TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/ost-workflow-state-test.XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT HUP INT TERM

export OST_WORKFLOW_STATE_DIR="$TMP_DIR/state"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_jq() {
  _file=$1
  _filter=$2
  _expected=$3
  _actual=$(jq -r "$_filter" "$_file")
  [ "$_actual" = "$_expected" ] || fail "$_filter expected $_expected, got $_actual"
}

run_state() {
  sh "$STATE_SH" "$@"
}

OWNER_REPO="ExampleOwner/example-repo"
STATE_FILE="$OST_WORKFLOW_STATE_DIR/ExampleOwner_example-repo.json"

run_state init "$OWNER_REPO"

[ -f "$STATE_FILE" ] || fail "state file was not created"
assert_jq "$STATE_FILE" '.owner_repo' "$OWNER_REPO"
assert_jq "$STATE_FILE" '.package_dir' 'ost_ExampleOwner_example-repo'
assert_jq "$STATE_FILE" '.workflow_status' 'in_progress'
assert_jq "$STATE_FILE" '.current_stage' 'repo_readme_summary'
assert_jq "$STATE_FILE" '.stages.install_script' 'pending'
assert_jq "$STATE_FILE" '.stages.optional_usage_examples' 'pending'
assert_jq "$STATE_FILE" '.usage_examples.decision' 'pending'
assert_jq "$STATE_FILE" '.execution.mode' 'subagent_preferred'

run_state set-stage "$OWNER_REPO" install_script in_progress
assert_jq "$STATE_FILE" '.current_stage' 'install_script'
assert_jq "$STATE_FILE" '.stages.install_script' 'in_progress'

run_state block "$OWNER_REPO" install_script "Missing default scope" "Use local by default?" "local"
assert_jq "$STATE_FILE" '.workflow_status' 'blocked'
assert_jq "$STATE_FILE" '.stages.install_script' 'blocked'
assert_jq "$STATE_FILE" '.clarifications[-1].status' 'open'
assert_jq "$STATE_FILE" '.clarifications[-1].question' 'Use local by default?'
assert_jq "$STATE_FILE" '.clarifications[-1].suggested_default' 'local'

run_state answer "$OWNER_REPO" "Yes, use local."
assert_jq "$STATE_FILE" '.workflow_status' 'in_progress'
assert_jq "$STATE_FILE" '.stages.install_script' 'in_progress'
assert_jq "$STATE_FILE" '.clarifications[-1].status' 'answered'
assert_jq "$STATE_FILE" '.clarifications[-1].answer' 'Yes, use local.'

run_state agent-run "$OWNER_REPO" install_script DONE "Created install.sh"
assert_jq "$STATE_FILE" '.execution.agent_runs[-1].stage' 'install_script'
assert_jq "$STATE_FILE" '.execution.agent_runs[-1].status' 'DONE'
assert_jq "$STATE_FILE" '.execution.agent_runs[-1].summary' 'Created install.sh'

run_state usage-examples "$OWNER_REPO" accepted "CLI, Agent integration" pending
assert_jq "$STATE_FILE" '.usage_examples.offered' 'true'
assert_jq "$STATE_FILE" '.usage_examples.decision' 'accepted'
assert_jq "$STATE_FILE" '.usage_examples.matched_criteria[0]' 'CLI, Agent integration'
assert_jq "$STATE_FILE" '.usage_examples.result' 'pending'
assert_jq "$STATE_FILE" '.stages.optional_usage_examples' 'in_progress'
assert_jq "$STATE_FILE" '.current_stage' 'optional_usage_examples'
assert_jq "$STATE_FILE" '.stages.optional_usage_examples' 'in_progress'

run_state agent-run "$OWNER_REPO" optional_usage_examples DONE "Created usage_examples.md"
assert_jq "$STATE_FILE" '.execution.agent_runs[-1].stage' 'optional_usage_examples'
assert_jq "$STATE_FILE" '.execution.agent_runs[-1].status' 'DONE'
assert_jq "$STATE_FILE" '.execution.agent_runs[-1].summary' 'Created usage_examples.md'

run_state set-stage "$OWNER_REPO" optional_usage_examples done
assert_jq "$STATE_FILE" '.stages.optional_usage_examples' 'done'

run_state test-result "$OWNER_REPO" failed "sh install.sh" "1" "network unavailable"
assert_jq "$STATE_FILE" '.workflow_status' 'blocked'
assert_jq "$STATE_FILE" '.stages.optional_test_install' 'failed'
assert_jq "$STATE_FILE" '.test_install.result' 'failed'
assert_jq "$STATE_FILE" '.test_install.failure.command' 'sh install.sh'

run_state test-result "$OWNER_REPO" passed "tool version" "0" "version printed"
assert_jq "$STATE_FILE" '.workflow_status' 'in_progress'
assert_jq "$STATE_FILE" '.stages.optional_test_install' 'done'
assert_jq "$STATE_FILE" '.test_install.result' 'passed'

run_state complete "$OWNER_REPO"
assert_jq "$STATE_FILE" '.workflow_status' 'done'
assert_jq "$STATE_FILE" '.stages.optional_usage_examples' 'done'

run_state show "$OWNER_REPO" >/dev/null

printf 'PASS: state.sh behavior\n'
