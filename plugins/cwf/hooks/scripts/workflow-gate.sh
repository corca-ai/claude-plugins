#!/usr/bin/env bash
set -euo pipefail
# workflow-gate.sh — UserPromptSubmit gate for cwf:run workflows.
# Emits status warnings, blocks cwf:run when setup prerequisites are missing,
# and blocks ship/push/commit intents while critical run gates remain.

HOOK_GROUP="workflow_gate"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=plugins/cwf/hooks/scripts/cwf-hook-gate.sh
source "$SCRIPT_DIR/cwf-hook-gate.sh"

INPUT="$(cat)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIVE_STATE_SCRIPT="$PLUGIN_ROOT/scripts/cwf-live-state.sh"
ARTIFACT_PATHS_SCRIPT="$PLUGIN_ROOT/scripts/cwf-artifact-paths.sh"
SETUP_READINESS_SCRIPT="$PLUGIN_ROOT/scripts/check-setup-readiness.sh"
BLOCKED_ACTION_REGEX='(^|[[:space:]])(cwf:ship|/ship|git[[:space:]]+push|git[[:space:]]+merge|'
BLOCKED_ACTION_REGEX+='gh[[:space:]]+pr[[:space:]]+create|gh[[:space:]]+pr[[:space:]]+merge|'
BLOCKED_ACTION_REGEX+='커밋해|푸시해|배포해)([[:space:]]|$)'
RUN_COMMAND_REGEX='^[[:space:]]*cwf:run([[:space:]]|$)'
RUN_CLOSING_GATES=(review-code refactor retro ship)

json_block() {
  local reason="$1"
  local reason_json="$reason"
  if command -v jq >/dev/null 2>&1; then
    reason_json="$(printf '%s' "$reason" | jq -Rs .)"
  else
    reason_json="${reason_json//\\/\\\\}"
    reason_json="${reason_json//\"/\\\"}"
    reason_json="${reason_json//$'\n'/ }"
    reason_json="\"$reason_json\""
  fi
  cat <<JSON
{"decision":"block","reason":${reason_json}}
JSON
  exit 0
}

json_allow() {
  local reason="${1:-}"
  if [[ -n "$reason" ]]; then
    local reason_json="$reason"
    if command -v jq >/dev/null 2>&1; then
      reason_json="$(printf '%s' "$reason" | jq -Rs .)"
    else
      reason_json="${reason_json//\\/\\\\}"
      reason_json="${reason_json//\"/\\\"}"
      reason_json="${reason_json//$'\n'/ }"
      reason_json="\"$reason_json\""
    fi
    cat <<JSON
{"additionalContext":${reason_json}}
JSON
  fi
  exit 0
}

extract_json_field() {
  local input_json="$1"
  local field="$2"

  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input_json" | jq -r --arg key "$field" '.[$key] // empty'
    return
  fi

  # Best-effort fallback for dependency-degraded mode.
  printf '%s' "$input_json" \
    | sed -n "s/.*\"${field}\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" \
    | head -n 1
}

read_live_scalar() {
  local base_dir="$1"
  local key="$2"
  bash "$LIVE_STATE_SCRIPT" get "$base_dir" "$key"
}

read_live_list() {
  local base_dir="$1"
  local key="$2"
  bash "$LIVE_STATE_SCRIPT" list-get "$base_dir" "$key"
}

live_scalar_key_declared() {
  local key="$1"
  grep -Eq "^[[:space:]]{2}${key}:[[:space:]]*" "$LIVE_STATE_FILE"
}

resolve_base_dir() {
  local input_json="$1"
  local cwd_from_input=""
  local base_dir="$PWD"

  cwd_from_input="$(printf '%s' "$input_json" | jq -r '.cwd // empty')"
  if [[ -n "$cwd_from_input" && -d "$cwd_from_input" ]]; then
    base_dir="$cwd_from_input"
  fi

  printf '%s' "$base_dir"
}

list_contains() {
  local needle="$1"
  shift
  local item=""
  for item in "$@"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

prompt_requests_blocked_action() {
  local prompt="$1"
  printf '%s' "$prompt" | grep -Eiq "$BLOCKED_ACTION_REGEX"
}

prompt_requests_run_command() {
  local prompt="$1"
  printf '%s' "$prompt" | grep -Eiq "$RUN_COMMAND_REGEX"
}

PROMPT="$(extract_json_field "$INPUT" "prompt")"
SESSION_ID="$(extract_json_field "$INPUT" "session_id")"
BLOCKED_REQUEST="false"
RUN_REQUEST="false"
if prompt_requests_blocked_action "$PROMPT" || prompt_requests_blocked_action "$INPUT"; then
  BLOCKED_REQUEST="true"
fi
if prompt_requests_run_command "$PROMPT"; then
  RUN_REQUEST="true"
fi

if ! command -v jq >/dev/null 2>&1; then
  if [[ "$RUN_REQUEST" == "true" ]]; then
    json_block "BLOCKED: workflow gate dependency missing (jq). Run cwf:setup after installing jq, then retry cwf:run."
  fi
  if [[ "$BLOCKED_REQUEST" == "true" ]]; then
    json_block "BLOCKED: workflow gate dependency missing (jq). Protected actions are denied until jq is available."
  fi
  json_allow "[WARNING] workflow gate dependency missing (jq). Non-protected prompts are allowed."
fi

if [[ ! -f "$LIVE_STATE_SCRIPT" ]]; then
  if [[ "$RUN_REQUEST" == "true" ]]; then
    json_block "BLOCKED: workflow gate dependency missing (${LIVE_STATE_SCRIPT}). Reinstall CWF before cwf:run."
  fi
  if [[ "$BLOCKED_REQUEST" == "true" ]]; then
    json_block "BLOCKED: workflow gate dependency missing (${LIVE_STATE_SCRIPT}). Protected actions are denied."
  fi
  json_allow "[WARNING] workflow gate dependency missing (${LIVE_STATE_SCRIPT}). Non-protected prompts are allowed."
fi

BASE_DIR="$(resolve_base_dir "$INPUT")"

if [[ "$RUN_REQUEST" == "true" ]]; then
  if [[ ! -x "$SETUP_READINESS_SCRIPT" ]]; then
    json_block "BLOCKED: setup readiness checker missing (${SETUP_READINESS_SCRIPT}). Reinstall CWF and run cwf:setup before cwf:run."
  fi

  set +e
  setup_readiness_summary="$(bash "$SETUP_READINESS_SCRIPT" --base-dir "$BASE_DIR" --summary 2>&1)"
  setup_readiness_rc=$?
  set -e

  if [[ "$setup_readiness_rc" -ne 0 ]]; then
    setup_readiness_summary="$(printf '%s' "$setup_readiness_summary" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/[[:space:]]$//')"
    json_block "BLOCKED: cwf:run requires setup readiness (${setup_readiness_summary}). Run 'cwf:setup' first."
  fi
fi

LIVE_STATE_FILE="$(bash "$LIVE_STATE_SCRIPT" resolve "$BASE_DIR" 2>/dev/null || true)"
if [[ -z "$LIVE_STATE_FILE" || ! -f "$LIVE_STATE_FILE" ]]; then
  STATE_FILE_PROBE=""
  if [[ -f "$ARTIFACT_PATHS_SCRIPT" ]]; then
    # shellcheck source=plugins/cwf/scripts/cwf-artifact-paths.sh
    source "$ARTIFACT_PATHS_SCRIPT"
    STATE_FILE_PROBE="$(resolve_cwf_state_file "$BASE_DIR" 2>/dev/null || true)"
  fi
  if [[ -z "$STATE_FILE_PROBE" ]]; then
    STATE_FILE_PROBE="$BASE_DIR/.cwf/cwf-state.yaml"
  fi
  if [[ "$BLOCKED_REQUEST" == "true" && -f "$STATE_FILE_PROBE" ]]; then
    json_block "BLOCKED: live state file is unavailable while protected action was requested. Resolve live-state before ship/push."
  fi
  json_allow "[WARNING] live state file unavailable; workflow gate skipped."
fi

if ! live_scalar_key_declared "active_pipeline"; then
  if [[ "$BLOCKED_REQUEST" == "true" ]]; then
    json_block "BLOCKED: workflow gate expected live.active_pipeline in ${LIVE_STATE_FILE}, but key is missing."
  fi
  json_allow "[WARNING] live.active_pipeline key missing; workflow gate skipped for non-protected prompts."
fi

ACTIVE_PIPELINE="$(read_live_scalar "$BASE_DIR" "active_pipeline" 2>/dev/null || true)"
if [[ -z "$ACTIVE_PIPELINE" ]]; then
  json_allow "[WARNING] live.active_pipeline is empty; workflow gate treated this as no active pipeline."
fi

# Stale pipeline detection: if stored session_id differs from current, the
# pipeline belongs to a previous session and should be cleaned up.
STORED_SESSION_ID="$(read_live_scalar "$BASE_DIR" "session_id" 2>/dev/null || true)"
if [[ -n "$SESSION_ID" && -n "$STORED_SESSION_ID" && "$SESSION_ID" != "$STORED_SESSION_ID" ]]; then
  stale_reason="[WARNING] Stale pipeline detected: active_pipeline='${ACTIVE_PIPELINE}' "
  stale_reason+="belongs to session '${STORED_SESSION_ID}' but current session is '${SESSION_ID}'. "
  stale_reason+="Run: bash ${LIVE_STATE_SCRIPT} set . active_pipeline=\"\" to clean up."
  json_allow "$stale_reason"
fi

PHASE="$(read_live_scalar "$BASE_DIR" "phase" 2>/dev/null || true)"
OVERRIDE_REASON="$(read_live_scalar "$BASE_DIR" "pipeline_override_reason" 2>/dev/null || true)"
STATE_VERSION="$(read_live_scalar "$BASE_DIR" "state_version" 2>/dev/null || true)"

REMAINING_GATES_RAW="$(read_live_list "$BASE_DIR" "remaining_gates" 2>/dev/null || true)"
REMAINING_GATES=()
if [[ -n "$REMAINING_GATES_RAW" ]]; then
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    REMAINING_GATES+=("$line")
  done <<< "$REMAINING_GATES_RAW"
fi

if [[ "${#REMAINING_GATES[@]}" -eq 0 ]]; then
  missing_gate_reason="[WARNING] Active pipeline '${ACTIVE_PIPELINE}' has no remaining_gates in live state. "
  missing_gate_reason+="Run cleanup or reinitialize run-state before continuing."
  json_allow "$missing_gate_reason"
fi

gate_chain="$(IFS=' -> '; echo "${REMAINING_GATES[*]}")"
status_msg="[PIPELINE] Active: ${ACTIVE_PIPELINE} (phase: ${PHASE:-unknown}, "
status_msg+="state_version: ${STATE_VERSION:-unset}). Remaining gates: ${gate_chain}. "
status_msg+="Do NOT skip gates. Use Skill tool to invoke next stage."

pending_run_closing_gates=()
for run_stage in "${RUN_CLOSING_GATES[@]}"; do
  if list_contains "$run_stage" "${REMAINING_GATES[@]}"; then
    pending_run_closing_gates+=("$run_stage")
  fi
done

if [[ "$BLOCKED_REQUEST" == "true" && "${#pending_run_closing_gates[@]}" -gt 0 ]]; then
  pending_gate_chain="$(IFS=','; echo "${pending_run_closing_gates[*]}")"
  if [[ -n "$OVERRIDE_REASON" && "$OVERRIDE_REASON" != "null" ]]; then
    json_allow "${status_msg} Override active: ${OVERRIDE_REASON}."
  fi
  json_block "${status_msg} BLOCKED action: ship/push/commit requested while run-closing gates are still pending (${pending_gate_chain})."
fi

json_allow "$status_msg"
