#!/usr/bin/env bash
# codex-with-log.sh: Run Codex CLI and sync session logs after completion.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYNC_SCRIPT="$SCRIPT_DIR/sync-session-logs.sh"
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

set +e
"$REAL_CODEX" "$@"
EXIT_CODE=$?
set -e

if [ -x "$SYNC_SCRIPT" ]; then
  "$SYNC_SCRIPT" --cwd "$PWD" --quiet || true
fi

exit "$EXIT_CODE"
