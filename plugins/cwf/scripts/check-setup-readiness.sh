#!/usr/bin/env bash
set -euo pipefail

# check-setup-readiness.sh — validate whether a repository is ready to run cwf:run.
#
# Readiness contract (fail-closed):
#   1) cwf-state.yaml exists and contains hooks/sessions keys
#   2) setup-contract.yaml exists
#   3) .cwf-config.yaml exists
#   4) CWF_RUN_AMBIGUITY_MODE is configured (env or project config)
#
# Usage:
#   check-setup-readiness.sh [--base-dir <path>] [--summary]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARTIFACT_PATHS_SCRIPT="$SCRIPT_DIR/cwf-artifact-paths.sh"

BASE_DIR="."
SUMMARY_ONLY="false"

usage() {
  cat <<'USAGE'
check-setup-readiness.sh — validate cwf:run setup preconditions

Usage:
  check-setup-readiness.sh [options]

Options:
  --base-dir <path>  Repository/worktree root to inspect (default: .)
  --summary          Print one-line machine-friendly summary
  -h, --help         Show this help
USAGE
}

trim_ws() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

strip_wrapping_quotes() {
  local value="$1"
  if [[ "$value" =~ ^\".*\"$ ]] || [[ "$value" =~ ^\'.*\'$ ]]; then
    value="${value:1:${#value}-2}"
  fi
  printf '%s' "$value"
}

extract_yaml_scalar_from_line() {
  local line="$1"
  local value=""

  value="${line#*:}"
  value="$(trim_ws "$value")"

  if [[ ! "$value" =~ ^\".*\"$ ]] && [[ ! "$value" =~ ^\'.*\'$ ]]; then
    value="${value%%#*}"
    value="$(trim_ws "$value")"
  fi
  value="$(strip_wrapping_quotes "$value")"
  printf '%s' "$value"
}

read_run_mode_from_configs() {
  local cfg_line=""
  local cfg=""
  for cfg in "$@"; do
    [[ -f "$cfg" ]] || continue
    cfg_line="$(grep -shm1 -E '^[[:space:]]*CWF_RUN_AMBIGUITY_MODE[[:space:]]*:' "$cfg" || true)"
    if [[ -n "$cfg_line" ]]; then
      extract_yaml_scalar_from_line "$cfg_line"
      return 0
    fi
  done
  return 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-dir)
      BASE_DIR="${2-}"
      [[ -n "$BASE_DIR" ]] || {
        echo "Error: --base-dir requires a path." >&2
        exit 2
      }
      shift 2
      ;;
    --summary)
      SUMMARY_ONLY="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ ! -d "$BASE_DIR" ]]; then
  echo "Error: base directory not found: $BASE_DIR" >&2
  exit 2
fi

if [[ ! -f "$ARTIFACT_PATHS_SCRIPT" ]]; then
  echo "Error: missing dependency: $ARTIFACT_PATHS_SCRIPT" >&2
  exit 2
fi

# shellcheck source=plugins/cwf/scripts/cwf-artifact-paths.sh
source "$ARTIFACT_PATHS_SCRIPT"

BASE_ABS="$(cd "$BASE_DIR" && pwd)"
STATE_FILE="$(resolve_cwf_state_file "$BASE_ABS")"
ARTIFACT_ROOT="$(resolve_cwf_artifact_root "$BASE_ABS")"
SETUP_CONTRACT_FILE="$ARTIFACT_ROOT/setup-contract.yaml"
SHARED_CONFIG_FILE="$BASE_ABS/.cwf-config.yaml"
LOCAL_CONFIG_FILE="$BASE_ABS/.cwf-config.local.yaml"

missing=()
missing_labels=()
run_mode=""

if [[ ! -s "$STATE_FILE" ]]; then
  missing+=("state_file")
  missing_labels+=("cwf-state")
else
  if ! grep -Eq '^hooks:[[:space:]]*$' "$STATE_FILE"; then
    missing+=("hooks_section")
    missing_labels+=("hooks")
  fi
  if ! grep -Eq '^sessions:[[:space:]]*' "$STATE_FILE"; then
    missing+=("sessions_key")
    missing_labels+=("sessions")
  fi
fi

if [[ ! -s "$SETUP_CONTRACT_FILE" ]]; then
  missing+=("setup_contract")
  missing_labels+=("setup-contract")
fi

if [[ ! -s "$SHARED_CONFIG_FILE" ]]; then
  missing+=("shared_config")
  missing_labels+=("shared-config")
fi

if [[ -n "${CWF_RUN_AMBIGUITY_MODE:-}" ]]; then
  run_mode="${CWF_RUN_AMBIGUITY_MODE}"
else
  run_mode="$(read_run_mode_from_configs "$LOCAL_CONFIG_FILE" "$SHARED_CONFIG_FILE" || true)"
fi

if [[ -z "$run_mode" ]]; then
  missing+=("run_mode")
  missing_labels+=("run-mode")
fi

if [[ "${#missing[@]}" -eq 0 ]]; then
  if [[ "$SUMMARY_ONLY" == "true" ]]; then
    printf 'ready=yes base_dir=%s run_mode=%s state_file=%s setup_contract=%s\n' \
      "$BASE_ABS" "$run_mode" "$STATE_FILE" "$SETUP_CONTRACT_FILE"
  else
    cat <<EOF
Setup readiness: READY
base_dir: $BASE_ABS
state_file: $STATE_FILE
setup_contract: $SETUP_CONTRACT_FILE
shared_config: $SHARED_CONFIG_FILE
run_mode: $run_mode
EOF
  fi
  exit 0
fi

missing_csv="$(IFS=,; echo "${missing_labels[*]}")"
if [[ "$SUMMARY_ONLY" == "true" ]]; then
  printf 'ready=no base_dir=%s missing=%s hint=%s\n' \
    "$BASE_ABS" "$missing_csv" "run-cwf:setup"
else
  echo "Setup readiness: NOT_READY"
  echo "base_dir: $BASE_ABS"
  echo "missing: $missing_csv"
  echo "state_file: $STATE_FILE"
  echo "setup_contract: $SETUP_CONTRACT_FILE"
  echo "shared_config: $SHARED_CONFIG_FILE"
  echo "run_mode: ${run_mode:-<unset>}"
  echo "hint: Run 'cwf:setup' first, then retry 'cwf:run'."
fi

exit 1
