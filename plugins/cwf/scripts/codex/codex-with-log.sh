#!/usr/bin/env bash
# codex-with-log.sh: Run Codex CLI and sync session logs after completion.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYNC_SCRIPT="$SCRIPT_DIR/sync-session-logs.sh"
POST_RUN_SCRIPT="$SCRIPT_DIR/post-run-checks.sh"
SELF_PATH="$(cd "$SCRIPT_DIR" && pwd)/$(basename "${BASH_SOURCE[0]}")"

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

set +e
"$REAL_CODEX" "$@"
EXIT_CODE=$?
set -e

if [ -x "$SYNC_SCRIPT" ]; then
  if [ -n "$RUN_START_EPOCH" ]; then
    "$SYNC_SCRIPT" --cwd "$PWD" --since-epoch "$RUN_START_EPOCH" --quiet || true
  else
    "$SYNC_SCRIPT" --cwd "$PWD" --quiet || true
  fi
fi

POST_RUN_ENABLED="${CWF_CODEX_POST_RUN_CHECKS:-true}"
POST_RUN_MODE="${CWF_CODEX_POST_RUN_MODE:-warn}"
POST_RUN_EXIT=0
if [ "$POST_RUN_ENABLED" = "true" ] && [ -x "$POST_RUN_SCRIPT" ]; then
  post_args=(--cwd "$PWD" --mode "$POST_RUN_MODE")
  if [ -n "$RUN_START_EPOCH" ]; then
    post_args+=(--since-epoch "$RUN_START_EPOCH")
  fi
  if [ "${CWF_CODEX_POST_RUN_QUIET:-false}" = "true" ]; then
    post_args+=(--quiet)
  fi
  if "$POST_RUN_SCRIPT" "${post_args[@]}"; then
    :
  else
    POST_RUN_EXIT=$?
  fi
fi

if [ "$EXIT_CODE" -eq 0 ] && [ "$POST_RUN_EXIT" -ne 0 ]; then
  EXIT_CODE="$POST_RUN_EXIT"
fi

exit "$EXIT_CODE"
