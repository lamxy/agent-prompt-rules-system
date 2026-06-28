#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
OPEN_SUPPORTS_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../../.." && pwd)
STATE_DIR=${OST_WORKFLOW_STATE_DIR:-"$OPEN_SUPPORTS_ROOT/.ost-workflow-state"}

usage() {
  cat <<'EOF'
Usage:
  state.sh init OWNER/REPO
  state.sh show OWNER/REPO
  state.sh set-stage OWNER/REPO STAGE STATUS
  state.sh block OWNER/REPO STAGE REASON QUESTION [SUGGESTED_DEFAULT]
  state.sh answer OWNER/REPO ANSWER
  state.sh agent-run OWNER/REPO STAGE STATUS SUMMARY
  state.sh test-result OWNER/REPO RESULT COMMAND EXIT_CODE SUMMARY
  state.sh complete OWNER/REPO
EOF
}

die() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

need_jq() {
  command -v jq >/dev/null 2>&1 || die "jq is required for workflow state JSON operations"
}

now_utc() {
  date -u '+%Y-%m-%dT%H:%M:%SZ'
}

state_name_for() {
  printf '%s' "$1" | tr '/' '_'
}

state_file_for() {
  printf '%s/%s.json' "$STATE_DIR" "$(state_name_for "$1")"
}

require_owner_repo() {
  case "${1:-}" in
    */*) ;;
    *) die "owner/repo is required" ;;
  esac
}

valid_stage() {
  case "$1" in
    repo_readme_summary|install_script|skill_for_setup|optional_test_install) return 0 ;;
    *) return 1 ;;
  esac
}

valid_stage_status() {
  case "$1" in
    pending|in_progress|done|blocked|waiting_user|skipped|failed) return 0 ;;
    *) return 1 ;;
  esac
}

ensure_state_exists() {
  [ -f "$state_file" ] || die "state file not found: $state_file"
}

write_jq() {
  filter=$1
  shift
  tmp="${state_file}.tmp.$$"
  if jq "$@" "$filter" "$state_file" > "$tmp"; then
    mv "$tmp" "$state_file"
  else
    rm -f "$tmp"
    exit 1
  fi
}

cmd_init() {
  require_owner_repo "$1"
  owner_repo=$1
  state_name=$(state_name_for "$owner_repo")
  state_file=$(state_file_for "$owner_repo")
  mkdir -p "$STATE_DIR"
  [ ! -e "$state_file" ] || die "state file already exists: $state_file"
  now=$(now_utc)

  tmp="${state_file}.tmp.$$"
  jq -n \
    --arg owner_repo "$owner_repo" \
    --arg package_dir "ost_$state_name" \
    --arg now "$now" \
    '{
      owner_repo: $owner_repo,
      package_dir: $package_dir,
      workflow_status: "in_progress",
      current_stage: "repo_readme_summary",
      stages: {
        repo_readme_summary: "pending",
        install_script: "pending",
        skill_for_setup: "pending",
        optional_test_install: "pending"
      },
      clarifications: [],
      test_install: {
        offered: false,
        decision: "pending",
        script_command: null,
        verify_commands: [],
        result: null
      },
      execution: {
        mode: "subagent_preferred",
        fallback: "inline",
        current_agent_stage: null,
        agent_runs: []
      },
      updated_at: $now
    }' > "$tmp"
  mv "$tmp" "$state_file"
  printf '%s\n' "$state_file"
}

cmd_show() {
  require_owner_repo "$1"
  state_file=$(state_file_for "$1")
  ensure_state_exists
  jq '.' "$state_file"
}

cmd_set_stage() {
  require_owner_repo "$1"
  stage=$2
  status=$3
  valid_stage "$stage" || die "unknown stage: $stage"
  valid_stage_status "$status" || die "unknown stage status: $status"
  state_file=$(state_file_for "$1")
  ensure_state_exists
  now=$(now_utc)

  write_jq '
    .stages[$stage] = $status
    | .current_stage = $stage
    | .workflow_status = (if ($status == "blocked" or $status == "failed") then "blocked" else "in_progress" end)
    | .execution.current_agent_stage = (if $status == "in_progress" then $stage else .execution.current_agent_stage end)
    | .updated_at = $now
  ' --arg stage "$stage" --arg status "$status" --arg now "$now"
}

cmd_block() {
  require_owner_repo "$1"
  stage=$2
  reason=$3
  question=$4
  suggested_default=${5:-""}
  valid_stage "$stage" || die "unknown stage: $stage"
  state_file=$(state_file_for "$1")
  ensure_state_exists
  now=$(now_utc)

  write_jq '
    .stages[$stage] = "blocked"
    | .current_stage = $stage
    | .workflow_status = "blocked"
    | .clarifications += [{
        stage: $stage,
        reason: $reason,
        question: $question,
        suggested_default: (if $suggested_default == "" then null else $suggested_default end),
        status: "open",
        created_at: $now
      }]
    | .updated_at = $now
  ' \
    --arg stage "$stage" \
    --arg reason "$reason" \
    --arg question "$question" \
    --arg suggested_default "$suggested_default" \
    --arg now "$now"
}

cmd_answer() {
  require_owner_repo "$1"
  answer=$2
  state_file=$(state_file_for "$1")
  ensure_state_exists
  now=$(now_utc)

  write_jq '
    (.clarifications | to_entries | map(select(.value.status == "open")) | last | .key) as $idx
    | if $idx == null then
        error("no open clarification")
      else
        (.clarifications[$idx].stage) as $stage
        | .clarifications[$idx].status = "answered"
        | .clarifications[$idx].answer = $answer
        | .clarifications[$idx].answered_at = $now
        | .workflow_status = "in_progress"
        | .current_stage = $stage
        | .stages[$stage] = "in_progress"
        | .updated_at = $now
      end
  ' --arg answer "$answer" --arg now "$now"
}

cmd_agent_run() {
  require_owner_repo "$1"
  stage=$2
  status=$3
  summary=$4
  valid_stage "$stage" || die "unknown stage: $stage"
  state_file=$(state_file_for "$1")
  ensure_state_exists
  now=$(now_utc)

  write_jq '
    .execution.current_agent_stage = $stage
    | .execution.agent_runs += [{
        stage: $stage,
        status: $status,
        summary: $summary,
        recorded_at: $now
      }]
    | .updated_at = $now
  ' --arg stage "$stage" --arg status "$status" --arg summary "$summary" --arg now "$now"
}

cmd_test_result() {
  require_owner_repo "$1"
  result=$2
  command=$3
  exit_code=$4
  summary=$5
  case "$result" in
    passed|failed|skipped) ;;
    *) die "test result must be passed, failed, or skipped" ;;
  esac
  state_file=$(state_file_for "$1")
  ensure_state_exists
  now=$(now_utc)

  write_jq '
    .current_stage = "optional_test_install"
    | .stages.optional_test_install = (
        if $result == "passed" then "done"
        elif $result == "skipped" then "skipped"
        else "failed"
        end
      )
    | .workflow_status = (
        if $result == "failed" then "blocked"
        elif $result == "skipped" then "done"
        else "in_progress"
        end
      )
    | .test_install.result = $result
    | .test_install.updated_at = $now
    | .test_install.last_command = {
        command: $command,
        exit_code: $exit_code,
        summary: $summary,
        recorded_at: $now
      }
    | if $result == "failed" then
        .test_install.failure = {
          command: $command,
          exit_code: $exit_code,
          output_summary: $summary,
          recorded_at: $now
        }
      else
        .
      end
    | .updated_at = $now
  ' \
    --arg result "$result" \
    --arg command "$command" \
    --arg exit_code "$exit_code" \
    --arg summary "$summary" \
    --arg now "$now"
}

cmd_complete() {
  require_owner_repo "$1"
  state_file=$(state_file_for "$1")
  ensure_state_exists
  now=$(now_utc)

  write_jq '
    .workflow_status = "done"
    | .updated_at = $now
  ' --arg now "$now"
}

need_jq

cmd=${1:-}
[ -n "$cmd" ] || { usage >&2; exit 2; }
shift || true

case "$cmd" in
  init)
    [ "$#" -eq 1 ] || { usage >&2; exit 2; }
    cmd_init "$1"
    ;;
  show)
    [ "$#" -eq 1 ] || { usage >&2; exit 2; }
    cmd_show "$1"
    ;;
  set-stage)
    [ "$#" -eq 3 ] || { usage >&2; exit 2; }
    cmd_set_stage "$1" "$2" "$3"
    ;;
  block)
    [ "$#" -eq 4 ] || [ "$#" -eq 5 ] || { usage >&2; exit 2; }
    cmd_block "$@"
    ;;
  answer)
    [ "$#" -eq 2 ] || { usage >&2; exit 2; }
    cmd_answer "$1" "$2"
    ;;
  agent-run)
    [ "$#" -eq 4 ] || { usage >&2; exit 2; }
    cmd_agent_run "$1" "$2" "$3" "$4"
    ;;
  test-result)
    [ "$#" -eq 5 ] || { usage >&2; exit 2; }
    cmd_test_result "$1" "$2" "$3" "$4" "$5"
    ;;
  complete)
    [ "$#" -eq 1 ] || { usage >&2; exit 2; }
    cmd_complete "$1"
    ;;
  --help|-h|help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
