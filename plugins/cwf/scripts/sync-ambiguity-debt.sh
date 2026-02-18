#!/usr/bin/env bash
set -euo pipefail

# sync-ambiguity-debt.sh
# Synchronize and validate live.blocking_decisions_pending using
# run-ambiguity-decisions.md (when present).
#
# Usage:
#   sync-ambiguity-debt.sh [--base-dir <path>] [--session-dir <path>] [--ambiguity-file <path>]
#   sync-ambiguity-debt.sh --check-only [--base-dir <path>] [--session-dir <path>] [--ambiguity-file <path>]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIVE_STATE_SCRIPT="$SCRIPT_DIR/cwf-live-state.sh"

MODE="sync"
BASE_DIR="."
SESSION_DIR=""
AMBIGUITY_FILE=""

usage() {
  cat <<'USAGE'
sync-ambiguity-debt.sh — sync/validate run ambiguity debt state

Usage:
  sync-ambiguity-debt.sh [options]
  sync-ambiguity-debt.sh --check-only [options]

Options:
  --check-only           Validation mode (do not write live state)
  --base-dir <path>      Base directory for live-state operations (default: .)
  --session-dir <path>   Explicit session directory (default: live.dir)
  --ambiguity-file <path> Explicit run-ambiguity-decisions.md path
  -h, --help             Show this help
USAGE
}

trim_ws() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

normalize_bool() {
  local raw="$1"
  raw="$(trim_ws "$raw")"
  raw="${raw%\"}"
  raw="${raw#\"}"
  case "$raw" in
    true|TRUE|True|1|yes|on) printf 'true\n' ;;
    false|FALSE|False|0|no|off) printf 'false\n' ;;
    *) printf '\n' ;;
  esac
}

to_abs_path() {
  local repo_root="$1"
  local path="$2"
  if [[ "$path" == "~"* ]]; then
    path="${path/#\~/$HOME}"
  fi
  if [[ "$path" == /* ]]; then
    printf '%s\n' "$path"
  else
    printf '%s\n' "$repo_root/$path"
  fi
}

to_repo_relative() {
  local repo_root="$1"
  local path="$2"
  if [[ "$path" == "$repo_root/"* ]]; then
    printf '%s\n' "${path#"$repo_root"/}"
  else
    printf '%s\n' "$path"
  fi
}

read_scalar_line() {
  local file_path="$1"
  local key="$2"
  if [[ ! -f "$file_path" ]]; then
    return 1
  fi
  sed -n -E "s/^${key}:[[:space:]]*(.*)$/\\1/p" "$file_path" | head -n 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check-only)
      MODE="check"
      shift
      ;;
    --base-dir)
      BASE_DIR="${2-}"
      [[ -n "$BASE_DIR" ]] || {
        echo "CHECK_FAIL: --base-dir requires a path" >&2
        exit 1
      }
      shift 2
      ;;
    --session-dir)
      SESSION_DIR="${2-}"
      [[ -n "$SESSION_DIR" ]] || {
        echo "CHECK_FAIL: --session-dir requires a path" >&2
        exit 1
      }
      shift 2
      ;;
    --ambiguity-file)
      AMBIGUITY_FILE="${2-}"
      [[ -n "$AMBIGUITY_FILE" ]] || {
        echo "CHECK_FAIL: --ambiguity-file requires a path" >&2
        exit 1
      }
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "CHECK_FAIL: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

[[ -x "$LIVE_STATE_SCRIPT" ]] || {
  echo "CHECK_FAIL: live-state helper not executable: $LIVE_STATE_SCRIPT" >&2
  exit 1
}

BASE_ABS="$(cd "$BASE_DIR" && pwd)"
REPO_ROOT="$(git -C "$BASE_ABS" rev-parse --show-toplevel 2>/dev/null || printf '%s\n' "$BASE_ABS")"

if [[ -z "$SESSION_DIR" ]]; then
  SESSION_DIR="$(bash "$LIVE_STATE_SCRIPT" get "$BASE_ABS" dir 2>/dev/null || true)"
fi
[[ -n "$SESSION_DIR" ]] || {
  echo "CHECK_FAIL: unable to resolve session directory (live.dir is empty)" >&2
  exit 1
}

SESSION_DIR_ABS="$(to_abs_path "$REPO_ROOT" "$SESSION_DIR")"

live_mode="$(bash "$LIVE_STATE_SCRIPT" get "$BASE_ABS" ambiguity_mode 2>/dev/null || true)"
live_pending_raw="$(bash "$LIVE_STATE_SCRIPT" get "$BASE_ABS" blocking_decisions_pending 2>/dev/null || true)"
live_pending_norm="$(normalize_bool "$live_pending_raw")"
live_file_raw="$(bash "$LIVE_STATE_SCRIPT" get "$BASE_ABS" ambiguity_decisions_file 2>/dev/null || true)"

if [[ -n "$AMBIGUITY_FILE" ]]; then
  AMBIGUITY_FILE_ABS="$(to_abs_path "$REPO_ROOT" "$AMBIGUITY_FILE")"
elif [[ -n "$live_file_raw" ]]; then
  AMBIGUITY_FILE_ABS="$(to_abs_path "$REPO_ROOT" "$live_file_raw")"
else
  AMBIGUITY_FILE_ABS="$SESSION_DIR_ABS/run-ambiguity-decisions.md"
fi

mode="$live_mode"
if [[ -z "$mode" ]]; then
  mode="defer-blocking"
fi

blocking_open_count=0
source_kind="live-default"
if [[ -f "$AMBIGUITY_FILE_ABS" ]]; then
  parsed_mode="$(read_scalar_line "$AMBIGUITY_FILE_ABS" "mode" || true)"
  parsed_blocking="$(read_scalar_line "$AMBIGUITY_FILE_ABS" "open_blocking_count" || true)"
  if [[ -z "$parsed_blocking" ]]; then
    parsed_blocking="$(read_scalar_line "$AMBIGUITY_FILE_ABS" "blocking_open_count" || true)"
  fi

  if [[ -n "$parsed_mode" ]]; then
    mode="$(trim_ws "$parsed_mode")"
  fi
  if [[ -n "$parsed_blocking" ]]; then
    parsed_blocking="$(trim_ws "$parsed_blocking")"
    if [[ ! "$parsed_blocking" =~ ^[0-9]+$ ]]; then
      echo "CHECK_FAIL: invalid blocking count in ambiguity file: $parsed_blocking" >&2
      exit 1
    fi
    blocking_open_count="$parsed_blocking"
  fi
  source_kind="ambiguity-file"
fi

derived_pending="false"
if [[ "$mode" == "defer-blocking" && "$blocking_open_count" -gt 0 ]]; then
  derived_pending="true"
fi

ambiguity_file_rel="$(to_repo_relative "$REPO_ROOT" "$AMBIGUITY_FILE_ABS")"

if [[ "$MODE" == "check" ]]; then
  fail_count=0

  if [[ -z "$live_pending_norm" ]]; then
    echo "CHECK_FAIL: live.blocking_decisions_pending is invalid or empty: ${live_pending_raw:-<empty>}" >&2
    fail_count=$((fail_count + 1))
  elif [[ "$live_pending_norm" != "$derived_pending" ]]; then
    echo "CHECK_FAIL: blocking pending mismatch (live=$live_pending_norm derived=$derived_pending)" >&2
    fail_count=$((fail_count + 1))
  fi

  if [[ -n "$live_file_raw" ]]; then
    live_file_abs="$(to_abs_path "$REPO_ROOT" "$live_file_raw")"
    if [[ "$live_file_abs" != "$AMBIGUITY_FILE_ABS" ]]; then
      echo "CHECK_FAIL: ambiguity file pointer mismatch (live=$live_file_abs derived=$AMBIGUITY_FILE_ABS)" >&2
      fail_count=$((fail_count + 1))
    fi
  fi

  echo "mode: $mode"
  echo "blocking_open_count: $blocking_open_count"
  echo "blocking_decisions_pending: $derived_pending"
  echo "source: $source_kind"
  echo "ambiguity_file: $ambiguity_file_rel"

  if [[ "$fail_count" -gt 0 ]]; then
    exit 1
  fi

  echo "CHECK_OK: ambiguity debt state is synchronized"
  exit 0
fi

bash "$LIVE_STATE_SCRIPT" set "$BASE_ABS" \
  blocking_decisions_pending="$derived_pending" \
  ambiguity_decisions_file="$ambiguity_file_rel" >/dev/null

confirmed_pending="$(bash "$LIVE_STATE_SCRIPT" get "$BASE_ABS" blocking_decisions_pending 2>/dev/null || true)"
confirmed_pending="$(normalize_bool "$confirmed_pending")"
if [[ "$confirmed_pending" != "$derived_pending" ]]; then
  echo "CHECK_FAIL: failed to persist blocking_decisions_pending (expected=$derived_pending got=${confirmed_pending:-<empty>})" >&2
  exit 1
fi

echo "mode: $mode"
echo "blocking_open_count: $blocking_open_count"
echo "blocking_decisions_pending: $derived_pending"
echo "source: $source_kind"
echo "ambiguity_file: $ambiguity_file_rel"
echo "CHECK_OK: ambiguity debt state synchronized"
