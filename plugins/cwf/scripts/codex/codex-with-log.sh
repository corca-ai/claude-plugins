#!/usr/bin/env bash
# codex-with-log.sh: Run Codex CLI and sync session logs after completion.

set -euo pipefail

resolve_script_path() {
  local source_path="${BASH_SOURCE[0]}"
  while [ -L "$source_path" ]; do
    local source_dir
    source_dir="$(cd "$(dirname "$source_path")" && pwd)"
    local target_path
    target_path="$(readlink "$source_path")"
    if [ "${target_path#/}" = "$target_path" ]; then
      source_path="$source_dir/$target_path"
    else
      source_path="$target_path"
    fi
  done
  local source_dir
  source_dir="$(cd "$(dirname "$source_path")" && pwd)"
  printf '%s/%s\n' "$source_dir" "$(basename "$source_path")"
}

SCRIPT_PATH="$(resolve_script_path)"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
SYNC_SCRIPT="$SCRIPT_DIR/sync-session-logs.sh"
POST_RUN_SCRIPT="$SCRIPT_DIR/post-run-checks.sh"
SELF_PATH="$SCRIPT_PATH"
INTERACTIVE_TTY="false"
if [ -t 0 ] && [ -t 1 ]; then
  INTERACTIVE_TTY="true"
fi
WRAPPER_DEBUG="${CWF_CODEX_WRAPPER_DEBUG:-false}"
WRAPPER_DEBUG_LOG="${CWF_CODEX_WRAPPER_DEBUG_LOG:-$HOME/.codex/log/cwf-codex-wrapper.log}"

# Keep trap path safe under nounset even if exit happens unexpectedly early.
RUN_START_EPOCH=""
SYNC_DONE="false"
EXIT_CODE=0
RUN_COMPLETED="false"
SYNC_TIMEOUT_SEC="${CWF_CODEX_SYNC_TIMEOUT_SEC:-10}"
SYNC_RETRY_TIMEOUT_SEC="${CWF_CODEX_SYNC_RETRY_TIMEOUT_SEC:-60}"
POST_RUN_TIMEOUT_SEC="${CWF_CODEX_POST_RUN_TIMEOUT_SEC:-15}"
SYNC_UNBOUNDED_FALLBACK="${CWF_CODEX_SYNC_UNBOUNDED_FALLBACK:-auto}"
if [ "$SYNC_UNBOUNDED_FALLBACK" = "auto" ]; then
  if [ "$INTERACTIVE_TTY" = "true" ]; then
    SYNC_UNBOUNDED_FALLBACK="false"
  else
    SYNC_UNBOUNDED_FALLBACK="true"
  fi
fi

wrapper_log() {
  if [ "$WRAPPER_DEBUG" != "true" ]; then
    return 0
  fi
  local ts
  local tty_name
  ts="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || printf 'unknown-time')"
  tty_name="$(tty 2>/dev/null || true)"
  if [ -z "$tty_name" ] || [ "$tty_name" = "not a tty" ]; then
    tty_name="notty"
  fi
  mkdir -p "$(dirname "$WRAPPER_DEBUG_LOG")" 2>/dev/null || true
  printf '%s pid=%s ppid=%s tty=%s %s\n' \
    "$ts" "$$" "${PPID:-0}" "$tty_name" "$*" >> "$WRAPPER_DEBUG_LOG" 2>/dev/null || true
}

wrapper_warn() {
  local msg="$*"
  printf '[cwf:codex wrapper] WARN: %s\n' "$msg" >&2
  wrapper_log "warn $msg"
}

is_same_file() {
  local a="$1"
  local b="$2"
  [ -e "$a" ] && [ -e "$b" ] && [ "$a" -ef "$b" ]
}

resolve_real_codex() {
  if [ -n "${CODEX_REAL_BIN:-}" ] && [ -x "${CODEX_REAL_BIN}" ]; then
    echo "$CODEX_REAL_BIN"
    return 0
  fi

  local candidate
  while IFS= read -r candidate; do
    [ -n "$candidate" ] || continue
    [ -x "$candidate" ] || continue
    if ! is_same_file "$candidate" "$SELF_PATH"; then
      echo "$candidate"
      return 0
    fi
  done < <(which -a codex 2>/dev/null | awk '!seen[$0]++')

  return 1
}

REAL_CODEX="$(resolve_real_codex || true)"
if [ -z "$REAL_CODEX" ]; then
  echo "Failed to resolve real codex binary." >&2
  exit 1
fi

RUN_START_EPOCH="$(date +%s 2>/dev/null || true)"
wrapper_log "start real_codex=$REAL_CODEX interactive=$INTERACTIVE_TTY cwd=$PWD args=$* start_epoch=$RUN_START_EPOCH"

run_with_optional_timeout() {
  local timeout_sec="$1"
  shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "$timeout_sec" "$@"
    return $?
  fi
  "$@"
  return $?
}

is_timeout_exit() {
  local code="${1:-0}"
  [ "$code" -eq 124 ] || [ "$code" -eq 137 ] || [ "$code" -eq 143 ]
}

run_sync_once() {
  if [ "${SYNC_DONE:-false}" = "true" ]; then
    wrapper_log "sync skipped reason=already_done"
    return 0
  fi
  SYNC_DONE="true"

  if [ ! -x "${SYNC_SCRIPT:-}" ]; then
    wrapper_log "sync skipped reason=missing_script path=${SYNC_SCRIPT:-}"
    return 0
  fi

  local sync_status=0
  local force_unbounded="false"

  # First pass: bounded to this wrapper invocation window.
  if [ -n "${RUN_START_EPOCH:-}" ]; then
    wrapper_log "sync bounded begin since_epoch=$RUN_START_EPOCH timeout=$SYNC_TIMEOUT_SEC"
    if run_with_optional_timeout "$SYNC_TIMEOUT_SEC" \
      "$SYNC_SCRIPT" --cwd "$PWD" --since-epoch "$RUN_START_EPOCH" --quiet; then
      wrapper_log "sync bounded end status=ok"
    else
      sync_status=$?
      force_unbounded="true"
      wrapper_log "sync bounded end status=fail exit=$sync_status"
      if is_timeout_exit "$sync_status"; then
        wrapper_warn "session log sync timed out (${SYNC_TIMEOUT_SEC}s); retrying with ${SYNC_RETRY_TIMEOUT_SEC}s."
      else
        wrapper_warn "session log sync failed (exit=$sync_status); retrying with ${SYNC_RETRY_TIMEOUT_SEC}s."
      fi

      if run_with_optional_timeout "$SYNC_RETRY_TIMEOUT_SEC" \
        "$SYNC_SCRIPT" --cwd "$PWD" --since-epoch "$RUN_START_EPOCH" --quiet; then
        wrapper_log "sync bounded retry end status=ok"
        force_unbounded="false"
      else
        sync_status=$?
        wrapper_log "sync bounded retry end status=fail exit=$sync_status"
        if is_timeout_exit "$sync_status"; then
          wrapper_warn "session log retry also timed out (${SYNC_RETRY_TIMEOUT_SEC}s)."
        else
          wrapper_warn "session log retry failed (exit=$sync_status)."
        fi
      fi
    fi
  fi

  # Optional second pass: unbounded fallback can pick unrelated sessions when many are active.
  if [ "$SYNC_UNBOUNDED_FALLBACK" = "true" ] || [ "$force_unbounded" = "true" ]; then
    wrapper_log "sync unbounded begin timeout=$SYNC_RETRY_TIMEOUT_SEC"
    if run_with_optional_timeout "$SYNC_RETRY_TIMEOUT_SEC" \
      "$SYNC_SCRIPT" --cwd "$PWD" --quiet; then
      wrapper_log "sync unbounded end status=ok"
    else
      sync_status=$?
      wrapper_log "sync unbounded end status=fail exit=$sync_status"
      if is_timeout_exit "$sync_status"; then
        wrapper_warn "unbounded session log sync timed out (${SYNC_RETRY_TIMEOUT_SEC}s). Run manually: $SYNC_SCRIPT --cwd \"$PWD\""
      else
        wrapper_warn "unbounded session log sync failed (exit=$sync_status). Run manually: $SYNC_SCRIPT --cwd \"$PWD\""
      fi
    fi
  fi

  return 0
}

cleanup_on_exit() {
  # shellcheck disable=SC2317
  wrapper_log "trap EXIT"
  # shellcheck disable=SC2317
  run_sync_once
}

trap cleanup_on_exit EXIT

set +e
"$REAL_CODEX" "$@"
EXIT_CODE=$?
RUN_COMPLETED="true"
set -e
wrapper_log "real codex returned exit_code=$EXIT_CODE"

run_sync_once

if [ "$INTERACTIVE_TTY" = "true" ]; then
  POST_RUN_ENABLED="${CWF_CODEX_POST_RUN_CHECKS:-false}"
else
  POST_RUN_ENABLED="${CWF_CODEX_POST_RUN_CHECKS:-true}"
fi
POST_RUN_MODE="${CWF_CODEX_POST_RUN_MODE:-warn}"
POST_RUN_EXIT=0
if [ "$RUN_COMPLETED" = "true" ] && [ "$POST_RUN_ENABLED" = "true" ] && [ -x "$POST_RUN_SCRIPT" ]; then
  post_args=(--cwd "$PWD" --mode "$POST_RUN_MODE")
  if [ -n "$RUN_START_EPOCH" ]; then
    post_args+=(--since-epoch "$RUN_START_EPOCH")
  fi
  if [ "${CWF_CODEX_POST_RUN_QUIET:-false}" = "true" ]; then
    post_args+=(--quiet)
  fi
  wrapper_log "post_run begin mode=$POST_RUN_MODE"
  if run_with_optional_timeout "$POST_RUN_TIMEOUT_SEC" "$POST_RUN_SCRIPT" "${post_args[@]}"; then
    wrapper_log "post_run end status=ok"
    :
  else
    POST_RUN_EXIT=$?
    wrapper_log "post_run end status=fail exit=$POST_RUN_EXIT"
  fi
fi

if [ "$EXIT_CODE" -eq 0 ] && [ "$POST_RUN_EXIT" -ne 0 ]; then
  EXIT_CODE="$POST_RUN_EXIT"
fi

wrapper_log "exit final_exit=$EXIT_CODE"

exit "$EXIT_CODE"
