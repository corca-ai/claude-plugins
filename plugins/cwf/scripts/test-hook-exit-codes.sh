#!/usr/bin/env bash
set -euo pipefail

# test-hook-exit-codes.sh — deterministic hook allow/block regression tests.
#
# Usage:
#   test-hook-exit-codes.sh --strict
#   test-hook-exit-codes.sh --suite path-filter
#   test-hook-exit-codes.sh --suite workflow-gate --suite deletion-safety
#   test-hook-exit-codes.sh --list-suites

usage() {
  cat <<'USAGE'
test-hook-exit-codes.sh — deterministic hook allow/block regression tests

Usage:
  test-hook-exit-codes.sh [--strict] [--suite <name> ...]
  test-hook-exit-codes.sh --list-suites

Options:
  --strict            Run the default strict suite set.
  --suite <name>      Run a specific suite (repeatable).
  --list-suites       Print available suites and exit.
  -h, --help          Show this message.

Suites:
  workflow-gate       UserPromptSubmit pipeline block/allow behavior.
  deletion-safety     PreToolUse deletion caller block/allow behavior.
  path-filter         /tmp prompt artifact filtering (allow) and in-repo deny fixtures.
  compact-context-no-jq  SessionStart compact recovery output without jq dependency.
USAGE
}

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

HOOKS_MANIFEST="plugins/cwf/hooks/hooks.json"
PLUGIN_ROOT_REL="plugins/cwf"

if [[ ! -f "$HOOKS_MANIFEST" ]]; then
  echo "[FAIL] hooks manifest missing: $HOOKS_MANIFEST" >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "[FAIL] jq is required" >&2
  exit 1
fi

PASS_COUNT=0
FAIL_COUNT=0
TOTAL_COUNT=0
LAST_OUTPUT=""
LAST_EXIT=0
CLEANUP_DIRS=()

pass() {
  local msg="$1"
  TOTAL_COUNT=$((TOTAL_COUNT + 1))
  PASS_COUNT=$((PASS_COUNT + 1))
  printf '[PASS] %s\n' "$msg"
}

fail() {
  local msg="$1"
  TOTAL_COUNT=$((TOTAL_COUNT + 1))
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf '[FAIL] %s\n' "$msg"
}

trap 'if [[ ${#CLEANUP_DIRS[@]} -gt 0 ]]; then rm -rf "${CLEANUP_DIRS[@]}"; fi' EXIT

manifest_hook_paths() {
  jq -r '.hooks | to_entries[].value[]?.hooks[]?.command // empty' "$HOOKS_MANIFEST" \
    | while IFS= read -r command; do
        [[ -n "$command" ]] || continue
        token="${command%% *}"
        token="${token//\$\{CLAUDE_PLUGIN_ROOT\}/$PLUGIN_ROOT_REL}"
        printf '%s/%s\n' "$REPO_ROOT" "$token"
      done \
    | sort -u
}

HOOK_INDEX_FILE="$(mktemp)"
CLEANUP_DIRS+=("$HOOK_INDEX_FILE")
manifest_hook_paths > "$HOOK_INDEX_FILE"

resolve_hook_path() {
  local base_name="$1"
  grep -E "/${base_name}$" "$HOOK_INDEX_FILE" | head -n 1
}

require_hook_path() {
  local base_name="$1"
  local path=""
  path="$(resolve_hook_path "$base_name" || true)"
  if [[ -z "$path" ]]; then
    fail "hook not found in manifest: $base_name"
    return 1
  fi
  if [[ ! -x "$path" ]]; then
    fail "hook from manifest is not executable: $path"
    return 1
  fi
  printf '%s\n' "$path"
}

new_sandbox_repo() {
  local dir=""
  dir="$(mktemp -d "${TMPDIR:-/tmp}/cwf-hook-suite-XXXXXX")"
  CLEANUP_DIRS+=("$dir")
  git -C "$dir" init -q
  printf '%s\n' "$dir"
}

build_path_without_jq() {
  local dir=""
  local cmd=""
  local target=""
  local required_cmds=(
    bash
    git
    awk
    cat
    date
    dirname
    grep
    head
    mktemp
    pwd
    sed
    tail
    tr
    wc
  )

  dir="$(mktemp -d "${TMPDIR:-/tmp}/cwf-hook-path-no-jq-XXXXXX")"
  CLEANUP_DIRS+=("$dir")

  for cmd in "${required_cmds[@]}"; do
    target="$(command -v "$cmd" || true)"
    [[ -n "$target" ]] || fail "required command not found for no-jq fixture: $cmd"
    ln -s "$target" "$dir/$cmd"
  done

  printf '%s\n' "$dir"
}

run_hook() {
  local script_path="$1"
  local cwd="$2"
  local input_json="$3"
  local path_override="${4:-}"
  local test_home="$cwd/.cwf-hook-test-home"

  mkdir -p "$test_home"

  set +e
  if [[ -n "$path_override" ]]; then
    LAST_OUTPUT="$(
      cd "$cwd" \
        && HOME="$test_home" PATH="$path_override" "$script_path" <<< "$input_json" 2>/dev/null
    )"
  else
    LAST_OUTPUT="$(cd "$cwd" && HOME="$test_home" "$script_path" <<< "$input_json" 2>/dev/null)"
  fi
  LAST_EXIT=$?
  set -e
}

extract_decision() {
  local output="$1"
  if [[ -z "$output" ]]; then
    printf '%s\n' ""
    return 0
  fi
  printf '%s' "$output" | jq -r '.decision // empty' 2>/dev/null || true
}

assert_decision() {
  local expected="$1"
  local label="$2"
  local got=""
  got="$(extract_decision "$LAST_OUTPUT")"
  if [[ "$got" == "$expected" ]]; then
    pass "$label (decision=$got)"
  else
    fail "$label (expected decision=$expected, got=${got:-<empty>})"
  fi
}

assert_no_output() {
  local label="$1"
  if [[ -z "$LAST_OUTPUT" ]]; then
    pass "$label"
  else
    fail "$label (expected empty output)"
  fi
}

assert_exit_code() {
  local expected="$1"
  local label="$2"
  if [[ "$LAST_EXIT" -eq "$expected" ]]; then
    pass "$label (exit=$LAST_EXIT)"
  else
    fail "$label (expected exit=$expected, got exit=$LAST_EXIT)"
  fi
}

suite_workflow_gate() {
  local hook=""
  local sandbox=""
  local input_json=""
  local gate=""

  write_state() {
    local override_reason="$1"
    shift
    {
      echo "live:"
      echo "  session_id: \"S-TEST-1\""
      echo "  phase: \"impl\""
      echo "  state_version: \"7\""
      echo "  active_pipeline: \"cwf:run\""
      echo "  pipeline_override_reason: \"$override_reason\""
      if [[ $# -eq 0 ]]; then
        echo "  remaining_gates: []"
      else
        echo "  remaining_gates:"
        for gate in "$@"; do
          echo "    - \"$gate\""
        done
      fi
    } > "$sandbox/.cwf/cwf-state.yaml"
  }

  hook="$(require_hook_path "workflow-gate.sh")" || return
  sandbox="$(new_sandbox_repo)"
  mkdir -p "$sandbox/.cwf"
  write_state "" review-code ship

  input_json="$(jq -nc \
    --arg cwd "$sandbox" \
    --arg session "S-TEST-1" \
    --arg prompt "다음 단계 진행" \
    '{cwd:$cwd,session_id:$session,prompt:$prompt}')"
  run_hook "$hook" "$sandbox" "$input_json"
  assert_decision "allow" "workflow-gate allows non-blocked prompt"
  assert_exit_code 0 "workflow-gate allow exit code"

  for gate in review-code refactor retro ship; do
    write_state "" "$gate"
    input_json="$(jq -nc \
      --arg cwd "$sandbox" \
      --arg session "S-TEST-1" \
      --arg prompt "git push 해" \
      '{cwd:$cwd,session_id:$session,prompt:$prompt}')"
    run_hook "$hook" "$sandbox" "$input_json"
    assert_decision "block" "workflow-gate blocks push while $gate pending"
    assert_exit_code 1 "workflow-gate block exit code while $gate pending"
  done

  write_state "" plan
  input_json="$(jq -nc \
    --arg cwd "$sandbox" \
    --arg session "S-TEST-1" \
    --arg prompt "git push 해" \
    '{cwd:$cwd,session_id:$session,prompt:$prompt}')"
  run_hook "$hook" "$sandbox" "$input_json"
  assert_decision "allow" "workflow-gate allows push when only non-closing gates remain"
  assert_exit_code 0 "workflow-gate allow exit code for non-closing gate only"

  write_state "manual override approved" review-code
  input_json="$(jq -nc \
    --arg cwd "$sandbox" \
    --arg session "S-TEST-1" \
    --arg prompt "git push 해" \
    '{cwd:$cwd,session_id:$session,prompt:$prompt}')"
  run_hook "$hook" "$sandbox" "$input_json"
  assert_decision "allow" "workflow-gate allows blocked action when override reason exists"
  assert_exit_code 0 "workflow-gate override allow exit code"

  write_state "" review-code
  input_json="$(jq -nc \
    --arg cwd "$sandbox" \
    --arg session "S-TEST-2" \
    --arg prompt "git push 해" \
    '{cwd:$cwd,session_id:$session,prompt:$prompt}')"
  run_hook "$hook" "$sandbox" "$input_json"
  assert_decision "allow" "workflow-gate allows stale pipeline session mismatch"
  assert_exit_code 0 "workflow-gate stale pipeline allow exit code"

  write_state "" review-code
  input_json="$(jq -nc \
    --arg cwd "$sandbox" \
    --arg session "S-TEST-1" \
    --arg prompt "커밋해" \
    '{cwd:$cwd,session_id:$session,prompt:$prompt}')"
  run_hook "$hook" "$sandbox" "$input_json"
  assert_decision "block" "workflow-gate blocks Korean commit intent while closing gate pending"
  assert_exit_code 1 "workflow-gate Korean commit block exit code"

  cat > "$sandbox/.cwf/cwf-state.yaml" <<'EOF_STATE_MISSING_ACTIVE'
live:
  session_id: "S-TEST-1"
  phase: "impl"
  remaining_gates:
    - "review-code"
EOF_STATE_MISSING_ACTIVE
  input_json="$(jq -nc \
    --arg cwd "$sandbox" \
    --arg session "S-TEST-1" \
    --arg prompt "다음 단계 진행" \
    '{cwd:$cwd,session_id:$session,prompt:$prompt}')"
  run_hook "$hook" "$sandbox" "$input_json"
  assert_decision "allow" "workflow-gate allows non-protected prompt when active_pipeline key is missing"
  assert_exit_code 0 "workflow-gate missing active_pipeline allow exit code"

  input_json="$(jq -nc \
    --arg cwd "$sandbox" \
    --arg session "S-TEST-1" \
    --arg prompt "git push 해" \
    '{cwd:$cwd,session_id:$session,prompt:$prompt}')"
  run_hook "$hook" "$sandbox" "$input_json"
  assert_decision "block" "workflow-gate blocks protected prompt when active_pipeline key is missing"
  assert_exit_code 1 "workflow-gate missing active_pipeline block exit code"

  cat > "$sandbox/.cwf/cwf-state.yaml" <<'EOF_STATE_MISSING_OPTIONAL'
live:
  session_id: "S-TEST-1"
  active_pipeline: "cwf:run"
  remaining_gates:
    - "review-code"
EOF_STATE_MISSING_OPTIONAL
  input_json="$(jq -nc \
    --arg cwd "$sandbox" \
    --arg session "S-TEST-1" \
    --arg prompt "git push 해" \
    '{cwd:$cwd,session_id:$session,prompt:$prompt}')"
  run_hook "$hook" "$sandbox" "$input_json"
  assert_decision "block" "workflow-gate still blocks push when optional live keys are missing"
  assert_exit_code 1 "workflow-gate missing optional keys block exit code"
}

suite_deletion_safety() {
  local hook=""
  local sandbox=""
  local input_json=""

  hook="$(require_hook_path "check-deletion-safety.sh")" || return
  sandbox="$(new_sandbox_repo)"
  mkdir -p "$sandbox/scripts"

  cat > "$sandbox/scripts/target.sh" <<'EOF_TARGET'
#!/usr/bin/env bash
echo target
EOF_TARGET

  cat > "$sandbox/scripts/caller.sh" <<'EOF_CALLER'
#!/usr/bin/env bash
scripts/target.sh
EOF_CALLER

  input_json="$(jq -nc --arg cmd 'echo hello' '{tool_name:"Bash",tool_input:{command:$cmd}}')"
  run_hook "$hook" "$sandbox" "$input_json"
  assert_no_output "deletion-safety allows non-deletion commands"
  assert_exit_code 0 "deletion-safety allow exit code"

  input_json="$(jq -nc --arg cmd 'rm scripts/target.sh' '{tool_name:"Bash",tool_input:{command:$cmd}}')"
  run_hook "$hook" "$sandbox" "$input_json"
  assert_decision "block" "deletion-safety blocks deletion with callers"
  assert_exit_code 1 "deletion-safety block exit code"
}

suite_path_filter() {
  local hook_markdown=""
  local hook_shell=""
  local hook_links=""
  local hook_delete=""
  local sandbox=""
  local tmp_md=""
  local tmp_sh=""
  local tmp_delete=""
  local input_json=""

  hook_markdown="$(require_hook_path "check-markdown.sh")" || return
  hook_shell="$(require_hook_path "check-shell.sh")" || return
  hook_links="$(require_hook_path "check-links-local.sh")" || return
  hook_delete="$(require_hook_path "check-deletion-safety.sh")" || return

  sandbox="$(new_sandbox_repo)"
  mkdir -p "$sandbox/docs" "$sandbox/tmp"

  tmp_md="$(mktemp "${TMPDIR:-/tmp}/cwf-hook-path-filter-XXXXXX.md")"
  tmp_sh="$(mktemp "${TMPDIR:-/tmp}/cwf-hook-path-filter-XXXXXX.sh")"
  tmp_delete="$(mktemp "${TMPDIR:-/tmp}/cwf-hook-path-filter-delete-XXXXXX")"
  CLEANUP_DIRS+=("$tmp_md" "$tmp_sh" "$tmp_delete")

  printf '#Title\ntext\n' > "$tmp_md"
  cat > "$tmp_sh" <<'EOF_TMP_SH'
#!/usr/bin/env bash
echo "$UNSET_VAR"
EOF_TMP_SH

  input_json="$(jq -nc --arg fp "$tmp_md" --arg cwd "$sandbox" '{tool_input:{file_path:$fp},cwd:$cwd}')"
  run_hook "$hook_markdown" "$sandbox" "$input_json"
  assert_no_output "check-markdown skips external /tmp file"

  input_json="$(jq -nc --arg fp "$tmp_sh" --arg cwd "$sandbox" '{tool_input:{file_path:$fp},cwd:$cwd}')"
  run_hook "$hook_shell" "$sandbox" "$input_json"
  assert_no_output "check-shell skips external /tmp file"

  input_json="$(jq -nc --arg fp "$tmp_md" --arg cwd "$sandbox" '{tool_input:{file_path:$fp},cwd:$cwd}')"
  run_hook "$hook_links" "$sandbox" "$input_json"
  assert_no_output "check-links-local skips external /tmp file"

  cat > "$sandbox/docs/broken.md" <<'EOF_LINKS'
[broken](./missing-local.md)
EOF_LINKS

  input_json="$(jq -nc --arg fp 'docs/broken.md' --arg cwd "$sandbox" '{tool_input:{file_path:$fp},cwd:$cwd}')"
  run_hook "$hook_links" "$sandbox" "$input_json"
  assert_decision "block" "check-links-local does not skip in-repo path"

  cat > "$sandbox/tmp/hook-delete-target.sh" <<'EOF_TARGET'
#!/usr/bin/env bash
echo target
EOF_TARGET

  cat > "$sandbox/tmp/hook-delete-caller.sh" <<'EOF_CALLER'
#!/usr/bin/env bash
tmp/hook-delete-target.sh
EOF_CALLER

  input_json="$(jq -nc --arg cmd 'rm /tmp/cwf-hook-path-filter-delete-nonrepo' '{tool_name:"Bash",tool_input:{command:$cmd}}')"
  run_hook "$hook_delete" "$sandbox" "$input_json"
  assert_no_output "check-deletion-safety skips external /tmp deletion target"

  input_json="$(jq -nc --arg cmd 'rm tmp/hook-delete-target.sh' '{tool_name:"Bash",tool_input:{command:$cmd}}')"
  run_hook "$hook_delete" "$sandbox" "$input_json"
  assert_decision "block" "check-deletion-safety does not skip in-repo tmp/ path"
}

suite_compact_context_no_jq() {
  local hook_compact=""
  local sandbox=""
  local input_json=""
  local context=""
  local no_jq_path=""

  hook_compact="$(require_hook_path "compact-context.sh")" || return
  sandbox="$(new_sandbox_repo)"
  mkdir -p "$sandbox/.cwf/projects/s1"

  cat > "$sandbox/.cwf/cwf-state.yaml" <<'EOF_STATE'
live:
  session_id: "S-NO-JQ"
  dir: ".cwf/projects/s1"
  branch: "test-branch"
  phase: "impl"
  task: "Compact no-jq fixture"
  key_files:
    - ".cwf/projects/s1/plan.md"
  dont_touch: []
  decisions: []
  decision_journal:
    - "{\"decision_id\":\"d-no-jq\",\"question\":\"Proceed without jq?\",\"answer\":\"Yes\"}"
  remaining_gates: []
  state_version: "1"
EOF_STATE

  cat > "$sandbox/.cwf/projects/s1/plan.md" <<'EOF_PLAN'
# Plan

No-jq compact context fixture.
EOF_PLAN

  no_jq_path="$(build_path_without_jq)"
  input_json="$(jq -nc --arg sid "S-NO-JQ" --arg cwd "$sandbox" '{session_id:$sid,cwd:$cwd}')"
  run_hook "$hook_compact" "$sandbox" "$input_json" "$no_jq_path"
  assert_exit_code 0 "compact-context runs without jq dependency"

  context="$(printf '%s' "$LAST_OUTPUT" | jq -r '.hookSpecificOutput.additionalContext // empty' 2>/dev/null || true)"
  if [[ "$context" == *"[Compact Recovery] Session: S-NO-JQ"* && "$context" == *"Decision journal"* ]]; then
    pass "compact-context no-jq output includes recovery context"
  else
    fail "compact-context no-jq output includes recovery context"
  fi
}

SUITE_DECISION_JOURNAL_LIB="$REPO_ROOT/plugins/cwf/scripts/test-hook-exit-codes-suite-decision-journal.sh"
if [[ ! -f "$SUITE_DECISION_JOURNAL_LIB" ]]; then
  fail "missing suite library: $SUITE_DECISION_JOURNAL_LIB"
fi
# shellcheck source=plugins/cwf/scripts/test-hook-exit-codes-suite-decision-journal.sh
source "$SUITE_DECISION_JOURNAL_LIB"

run_suite() {
  local suite="$1"
  printf '\n== Suite: %s ==\n' "$suite"
  case "$suite" in
    workflow-gate)
      suite_workflow_gate
      ;;
    deletion-safety)
      suite_deletion_safety
      ;;
    path-filter)
      suite_path_filter
      ;;
    compact-context-no-jq)
      suite_compact_context_no_jq
      ;;
    decision-journal-e2e)
      suite_decision_journal_e2e
      ;;
    *)
      fail "unknown suite: $suite"
      ;;
  esac
}

STRICT_SUITES=(workflow-gate deletion-safety path-filter compact-context-no-jq)
SELECTED_SUITES=()
USE_STRICT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict)
      USE_STRICT=true
      shift
      ;;
    --suite)
      if [[ $# -lt 2 ]]; then
        echo "--suite requires a value" >&2
        exit 2
      fi
      SELECTED_SUITES+=("$2")
      shift 2
      ;;
    --list-suites)
      printf '%s\n' "workflow-gate" "deletion-safety" "path-filter" "compact-context-no-jq" "decision-journal-e2e"
      exit 0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ "$USE_STRICT" == true || ${#SELECTED_SUITES[@]} -eq 0 ]]; then
  SELECTED_SUITES=("${STRICT_SUITES[@]}")
fi

for suite in "${SELECTED_SUITES[@]}"; do
  run_suite "$suite"
done

printf '\nSummary: total=%d pass=%d fail=%d\n' "$TOTAL_COUNT" "$PASS_COUNT" "$FAIL_COUNT"

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  exit 1
fi

exit 0
