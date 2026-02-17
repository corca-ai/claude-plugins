#!/usr/bin/env bash
set -euo pipefail
# workflow-gate.sh — UserPromptSubmit gate for active cwf:run workflows.
# Emits status warnings and blocks ship/push/commit intents while critical gates remain.

HOOK_GROUP="workflow_gate"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=plugins/cwf/hooks/scripts/cwf-hook-gate.sh
source "$SCRIPT_DIR/cwf-hook-gate.sh"

INPUT="$(cat)"

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIVE_STATE_SCRIPT="$PLUGIN_ROOT/scripts/cwf-live-state.sh"

if [[ ! -f "$LIVE_STATE_SCRIPT" ]]; then
  exit 0
fi

json_block() {
  local reason="$1"
  local reason_json
  reason_json="$(printf '%s' "$reason" | jq -Rs .)"
  cat <<JSON
{"decision":"block","reason":${reason_json}}
JSON
  exit 1
}

json_allow() {
  local reason="$1"
  local reason_json
  reason_json="$(printf '%s' "$reason" | jq -Rs .)"
  cat <<JSON
{"decision":"allow","reason":${reason_json}}
JSON
  exit 0
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

read_live_scalar_or_block() {
  local base_dir="$1"
  local key="$2"
  local value=""
  if ! value="$(read_live_scalar "$base_dir" "$key" 2>/dev/null)"; then
    json_block "BLOCKED: workflow gate could not parse live.${key} from ${LIVE_STATE_FILE}. Fix live-state parser/state before continuing."
  fi
  printf '%s' "$value"
}

read_live_list_or_block() {
  local base_dir="$1"
  local key="$2"
  local value=""
  if ! value="$(read_live_list "$base_dir" "$key" 2>/dev/null)"; then
    json_block "BLOCKED: workflow gate could not parse live.${key} from ${LIVE_STATE_FILE}. Fix live-state parser/state before continuing."
  fi
  printf '%s' "$value"
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
  printf '%s' "$prompt" | grep -Eiq '(^|[[:space:]])(cwf:ship|/ship|git[[:space:]]+push|git[[:space:]]+merge|gh[[:space:]]+pr[[:space:]]+create|gh[[:space:]]+pr[[:space:]]+merge|커밋해|푸시해|배포해)([[:space:]]|$)'
}

PROMPT="$(printf '%s' "$INPUT" | jq -r '.prompt // empty')"
SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.session_id // empty')"
BASE_DIR="$(resolve_base_dir "$INPUT")"

LIVE_STATE_FILE="$(bash "$LIVE_STATE_SCRIPT" resolve "$BASE_DIR" 2>/dev/null || true)"
if [[ -z "$LIVE_STATE_FILE" || ! -f "$LIVE_STATE_FILE" ]]; then
  exit 0
fi

ACTIVE_PIPELINE="$(read_live_scalar_or_block "$BASE_DIR" "active_pipeline")"
if [[ -z "$ACTIVE_PIPELINE" ]]; then
  exit 0
fi

# Stale pipeline detection: if stored session_id differs from current, the
# pipeline belongs to a previous session and should be cleaned up.
STORED_SESSION_ID="$(read_live_scalar_or_block "$BASE_DIR" "session_id")"
if [[ -n "$SESSION_ID" && -n "$STORED_SESSION_ID" && "$SESSION_ID" != "$STORED_SESSION_ID" ]]; then
  json_allow "[WARNING] Stale pipeline detected: active_pipeline='${ACTIVE_PIPELINE}' belongs to session '${STORED_SESSION_ID}' but current session is '${SESSION_ID}'. Run: bash ${LIVE_STATE_SCRIPT} set . active_pipeline=\"\" to clean up."
fi

PHASE="$(read_live_scalar_or_block "$BASE_DIR" "phase")"
OVERRIDE_REASON="$(read_live_scalar_or_block "$BASE_DIR" "pipeline_override_reason")"
STATE_VERSION="$(read_live_scalar_or_block "$BASE_DIR" "state_version")"

REMAINING_GATES_RAW="$(read_live_list_or_block "$BASE_DIR" "remaining_gates")"
REMAINING_GATES=()
if [[ -n "$REMAINING_GATES_RAW" ]]; then
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    REMAINING_GATES+=("$line")
  done <<< "$REMAINING_GATES_RAW"
fi

if [[ "${#REMAINING_GATES[@]}" -eq 0 ]]; then
  json_allow "[WARNING] Active pipeline '${ACTIVE_PIPELINE}' has no remaining_gates in live state. Run cleanup or reinitialize run-state before continuing."
fi

gate_chain="$(IFS=' -> '; echo "${REMAINING_GATES[*]}")"
status_msg="[PIPELINE] Active: ${ACTIVE_PIPELINE} (phase: ${PHASE:-unknown}, state_version: ${STATE_VERSION:-unset}). Remaining gates: ${gate_chain}. Do NOT skip gates. Use Skill tool to invoke next stage."

if list_contains "review-code" "${REMAINING_GATES[@]}" && prompt_requests_blocked_action "$PROMPT"; then
  if [[ -n "$OVERRIDE_REASON" && "$OVERRIDE_REASON" != "null" ]]; then
    json_allow "${status_msg} Override active: ${OVERRIDE_REASON}."
  fi
  json_block "${status_msg} BLOCKED action: ship/push/commit requested while review-code is still pending."
fi

json_allow "$status_msg"
