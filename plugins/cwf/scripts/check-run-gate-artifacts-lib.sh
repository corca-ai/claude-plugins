#!/usr/bin/env bash
set -euo pipefail
# check-run-gate-artifacts-lib.sh: helper functions for run gate artifact checks.

usage() {
  cat <<'USAGE'
check-run-gate-artifacts.sh — validate cwf:run stage artifacts

Usage:
  check-run-gate-artifacts.sh [options]

Options:
  --stage <name>         Stage to validate (repeatable): review-code|refactor|retro|ship
  --session-dir <path>   Session directory to validate (default: resolve from live state)
  --base-dir <path>      Base directory for live-state resolution (default: .)
  --contract <path>      Contract file (YAML) overriding stage/policy modes
  --strict               Exit non-zero when any check fails
  --record-lessons       Append failure summary to {session-dir}/lessons.md
  -h, --help             Show this help
USAGE
}

append_fail() {
  local stage="$1"
  local msg="$2"
  FAILS+=("[$stage] $msg")
}

append_warn() {
  local stage="$1"
  local msg="$2"
  WARNS+=("[$stage] $msg")
}

append_pass() {
  local stage="$1"
  local msg="$2"
  PASSES+=("[$stage] $msg")
}

list_contains() {
  local needle="$1"
  shift || true
  local item=""
  for item in "$@"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

normalize_mode() {
  local raw="$1"
  local fallback="$2"
  local mode
  mode="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')"
  case "$mode" in
    off|warn|fail)
      printf '%s\n' "$mode"
      ;;
    *)
      printf '%s\n' "$fallback"
      ;;
  esac
}

resolve_contract_file() {
  if [[ -n "$CONTRACT_PATH" ]]; then
    if [[ "$CONTRACT_PATH" != /* ]]; then
      CONTRACT_PATH="$REPO_ROOT/$CONTRACT_PATH"
    fi
    if [[ ! -f "$CONTRACT_PATH" ]]; then
      append_fail "contract" "explicit contract file not found: $CONTRACT_PATH"
      return 1
    fi
    CONTRACT_SOURCE="explicit"
    return 0
  fi

  if [[ -f "$SESSION_DIR/gate-contract.yaml" ]]; then
    CONTRACT_PATH="$SESSION_DIR/gate-contract.yaml"
    CONTRACT_SOURCE="session"
    return 0
  fi

  if [[ -f "$REPO_ROOT/.cwf/gate-contract.yaml" ]]; then
    CONTRACT_PATH="$REPO_ROOT/.cwf/gate-contract.yaml"
    CONTRACT_SOURCE="project"
    return 0
  fi

  # shellcheck disable=SC2034
  CONTRACT_PATH=""
  # shellcheck disable=SC2034
  CONTRACT_SOURCE="builtin-defaults"
  return 0
}

load_contract() {
  local line=""
  local section=""
  local key=""
  local value=""
  local mode=""
  local stage_line_re='^[[:space:]]{2}(review-code|refactor|retro|ship):[[:space:]]*([A-Za-z_-]+)[[:space:]]*$'

  [[ -n "$CONTRACT_PATH" ]] || return 0

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="$(printf '%s' "$line" | sed 's/[[:space:]]*$//')"
    [[ -n "$line" ]] || continue

    if [[ "$line" =~ ^stages:[[:space:]]*$ ]]; then
      section="stages"
      continue
    fi
    if [[ "$line" =~ ^policies:[[:space:]]*$ ]]; then
      section="policies"
      continue
    fi

    if [[ "$section" == "stages" && "$line" =~ $stage_line_re ]]; then
      key="${BASH_REMATCH[1]}"
      value="${BASH_REMATCH[2]}"
      mode="$(normalize_mode "$value" "fail")"
      case "$key" in
        review-code) CONTRACT_STAGE_REVIEW_CODE="$mode" ;;
        refactor) CONTRACT_STAGE_REFACTOR="$mode" ;;
        retro) CONTRACT_STAGE_RETRO="$mode" ;;
        ship) CONTRACT_STAGE_SHIP="$mode" ;;
      esac
      continue
    fi

    if [[ "$section" == "policies" && "$line" =~ ^[[:space:]]{2}provider_gemini_mode:[[:space:]]*([A-Za-z_-]+)[[:space:]]*$ ]]; then
      CONTRACT_POLICY_PROVIDER_GEMINI_MODE="$(normalize_mode "${BASH_REMATCH[1]}" "off")"
      continue
    fi
  done < "$CONTRACT_PATH"
}

contract_stage_mode() {
  local stage="$1"
  case "$stage" in
    review-code) printf '%s\n' "$CONTRACT_STAGE_REVIEW_CODE" ;;
    refactor) printf '%s\n' "$CONTRACT_STAGE_REFACTOR" ;;
    retro) printf '%s\n' "$CONTRACT_STAGE_RETRO" ;;
    ship) printf '%s\n' "$CONTRACT_STAGE_SHIP" ;;
    *) printf 'fail\n' ;;
  esac
}

downgrade_stage_fails_to_warn() {
  local stage="$1"
  local fail_before="$2"
  local item=""
  local idx=0
  local kept=()

  for item in "${FAILS[@]}"; do
    if (( idx >= fail_before )) && [[ "$item" == "[$stage]"* ]]; then
      append_warn "$stage" "downgraded by contract(mode=warn): $item"
    else
      kept+=("$item")
    fi
    idx=$((idx + 1))
  done
  FAILS=("${kept[@]}")
}

run_stage_with_contract_mode() {
  local stage="$1"
  local mode=""
  local fail_before=0

  mode="$(contract_stage_mode "$stage")"
  case "$mode" in
    off)
      append_warn "$stage" "stage validation skipped by contract (mode=off)"
      return 0
      ;;
    warn|fail)
      ;;
    *)
      mode="fail"
      ;;
  esac

  fail_before=${#FAILS[@]}
  case "$stage" in
    review-code) check_review_code_stage ;;
    refactor) check_refactor_stage ;;
    retro) check_retro_stage ;;
    ship) check_ship_stage ;;
    *)
      append_fail "$stage" "unsupported stage (allowed: review-code|refactor|retro|ship)"
      ;;
  esac

  if [[ "$mode" == "warn" ]]; then
    downgrade_stage_fails_to_warn "$stage" "$fail_before"
  fi
}

apply_provider_gemini_policy() {
  local mode="$CONTRACT_POLICY_PROVIDER_GEMINI_MODE"
  local stage="policy-provider-gemini"
  local file=""
  local found=false
  local hits=()

  case "$mode" in
    off) return 0 ;;
    warn|fail) ;;
    *) mode="off" ;;
  esac

  if ! list_contains "review-code" "${STAGES[@]}"; then
    return 0
  fi

  shopt -s nullglob
  for file in "$SESSION_DIR"/review-correctness-*.md "$SESSION_DIR"/review-architecture-*.md; do
    [[ -f "$file" ]] || continue
    found=true
    if grep -Eiq '^tool:[[:space:]]*gemini([[:space:]]|$)' "$file"; then
      hits+=("${file#"$SESSION_DIR"/}")
    fi
  done
  shopt -u nullglob

  if [[ "$found" == false ]]; then
    append_warn "$stage" "policy enabled but no external review provenance files found"
    return 0
  fi

  if [[ "${#hits[@]}" -eq 0 ]]; then
    append_pass "$stage" "gemini provider not detected in external reviewer provenance"
    return 0
  fi

  if [[ "$mode" == "fail" ]]; then
    append_fail "$stage" "gemini provider detected: ${hits[*]}"
  else
    append_warn "$stage" "gemini provider detected: ${hits[*]}"
  fi
}

ensure_nonempty_file() {
  local stage="$1"
  local file_path="$2"
  if [[ -s "$file_path" ]]; then
    append_pass "$stage" "artifact present: ${file_path#"$SESSION_DIR"/}"
    return 0
  fi
  append_fail "$stage" "artifact missing or empty: ${file_path#"$SESSION_DIR"/}"
  return 1
}

require_agent_complete_sentinel() {
  local stage="$1"
  local file_path="$2"
  if grep -q '<!-- AGENT_COMPLETE -->' "$file_path" 2>/dev/null; then
    append_pass "$stage" "sentinel present: ${file_path#"$SESSION_DIR"/}"
    return 0
  fi
  append_fail "$stage" "missing sentinel <!-- AGENT_COMPLETE --> in ${file_path#"$SESSION_DIR"/}"
  return 1
}

resolve_session_dir() {
  local raw_dir=""
  if [[ -n "$SESSION_DIR" ]]; then
    return 0
  fi
  if [[ ! -x "$LIVE_STATE_SCRIPT" ]]; then
    append_fail "global" "live-state resolver not found: $LIVE_STATE_SCRIPT"
    return 1
  fi
  raw_dir="$(bash "$LIVE_STATE_SCRIPT" get "$BASE_DIR" dir 2>/dev/null || true)"
  if [[ -z "$raw_dir" ]]; then
    append_fail "global" "unable to resolve session dir from live state"
    return 1
  fi
  if [[ "$raw_dir" == /* ]]; then
    SESSION_DIR="$raw_dir"
  else
    SESSION_DIR="$REPO_ROOT/$raw_dir"
  fi
  return 0
}
