#!/usr/bin/env bash
# retro-collect-evidence.sh: Collect retrospective evidence from session artifacts and logs.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIVE_RESOLVER_SCRIPT="$SCRIPT_DIR/cwf-live-state.sh"
CODEX_SYNC_SCRIPT="$SCRIPT_DIR/codex/sync-session-logs.sh"

SESSION_DIR=""
OUT_FILE=""
SINCE_EPOCH=""
QUIET=false

usage() {
  cat <<'USAGE'
Collect retrospective evidence from session artifacts and logs.

Usage:
  retro-collect-evidence.sh [options]

Options:
  --session-dir <path>   Explicit session directory (default: resolve from live state)
  --out <path>           Output markdown path (default: {session_dir}/retro-evidence.md)
  --since-epoch <sec>    Optional epoch filter used for file-level freshness checks
  --quiet                Suppress informational output
  -h, --help             Show help
USAGE
}

log() {
  if [[ "$QUIET" != "true" ]]; then
    echo "[cwf:retro evidence] $*"
  fi
}

warn() {
  echo "[cwf:retro evidence] WARN: $*" >&2
}

run_best_effort_codex_sync() {
  local args=()
  if [[ ! -x "$CODEX_SYNC_SCRIPT" ]]; then
    return 0
  fi

  args=(--cwd "$REPO_ROOT" --quiet)
  if [[ -n "$SINCE_EPOCH" ]]; then
    args+=(--since-epoch "$SINCE_EPOCH")
  fi

  if ! bash "$CODEX_SYNC_SCRIPT" "${args[@]}"; then
    warn "best-effort Codex session log sync failed; continuing evidence collection"
  fi
}

file_mtime_epoch() {
  local path="$1"
  stat -c %Y "$path" 2>/dev/null || stat -f %m "$path" 2>/dev/null || echo "0"
}

extract_live_dir_value() {
  local state_file="$1"
  awk '
    /^live:/ { in_live=1; next }
    in_live && /^[^[:space:]]/ { exit }
    in_live && /^[[:space:]]{2}dir:[[:space:]]*/ {
      sub(/^[[:space:]]{2}dir:[[:space:]]*/, "", $0)
      gsub(/^[\"\047]|[\"\047]$/, "", $0)
      print $0
      exit
    }
  ' "$state_file"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session-dir)
      SESSION_DIR="${2:-}"
      if [[ -z "$SESSION_DIR" ]]; then
        echo "Error: --session-dir requires a value" >&2
        exit 1
      fi
      shift 2
      ;;
    --out)
      OUT_FILE="${2:-}"
      if [[ -z "$OUT_FILE" ]]; then
        echo "Error: --out requires a value" >&2
        exit 1
      fi
      shift 2
      ;;
    --since-epoch)
      SINCE_EPOCH="${2:-}"
      if [[ -z "$SINCE_EPOCH" ]]; then
        echo "Error: --since-epoch requires a value" >&2
        exit 1
      fi
      shift 2
      ;;
    --quiet)
      QUIET=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"
run_best_effort_codex_sync

if [[ -z "$SESSION_DIR" ]]; then
  if [[ -x "$LIVE_RESOLVER_SCRIPT" ]]; then
    live_state_file="$(bash "$LIVE_RESOLVER_SCRIPT" resolve 2>/dev/null || true)"
    if [[ -n "$live_state_file" && -f "$live_state_file" ]]; then
      live_dir="$(extract_live_dir_value "$live_state_file" || true)"
      if [[ -n "$live_dir" ]]; then
        if [[ "$live_dir" == /* ]]; then
          SESSION_DIR="$live_dir"
        else
          SESSION_DIR="$REPO_ROOT/$live_dir"
        fi
      fi
    fi
  fi
fi

if [[ -z "$SESSION_DIR" ]]; then
  warn "failed to resolve session directory"
  exit 1
fi

if [[ ! -d "$SESSION_DIR" ]]; then
  warn "session directory does not exist: $SESSION_DIR"
  exit 1
fi

if [[ -z "$OUT_FILE" ]]; then
  OUT_FILE="$SESSION_DIR/retro-evidence.md"
elif [[ "$OUT_FILE" != /* ]]; then
  OUT_FILE="$REPO_ROOT/$OUT_FILE"
fi

mkdir -p "$(dirname "$OUT_FILE")"

scratchpad_file="$SESSION_DIR/hitl/hitl-scratchpad.md"
events_file="$SESSION_DIR/hitl/events.log"
session_logs_dir="$SESSION_DIR/session-logs"
codex_tui_log="${CODEX_TUI_LOG:-$HOME/.codex/log/codex-tui.log}"

scratchpad_status="missing"
scratchpad_count="0"
scratchpad_recent="_none_"
if [[ -f "$scratchpad_file" ]]; then
  scratchpad_status="present"
  scratchpad_count="$(grep -E -c '^- D-[0-9]{3}' "$scratchpad_file" || true)"
  scratchpad_recent="$(grep -E '^- D-[0-9]{3}' "$scratchpad_file" | tail -n 8 || true)"
  [[ -n "$scratchpad_recent" ]] || scratchpad_recent="_none_"
fi

events_status="missing"
events_tail="_none_"
if [[ -f "$events_file" ]]; then
  events_status="present"
  events_tail="$(tail -n 12 "$events_file" || true)"
  [[ -n "$events_tail" ]] || events_tail="_none_"
fi

token_limit_hits="_none_"
if [[ -f "$codex_tui_log" ]]; then
  token_limit_hits="$(grep -n 'token_limit_reached=true' "$codex_tui_log" | tail -n 12 || true)"
  [[ -n "$token_limit_hits" ]] || token_limit_hits="_none_"
fi

session_warns="_none_"
if [[ -d "$session_logs_dir" ]]; then
  session_warns="$(grep -h -E 'WARN:|warning' "$session_logs_dir"/*.codex.md 2>/dev/null | tail -n 20 || true)"
  [[ -n "$session_warns" ]] || session_warns="_none_"
fi

find_skills_status="unavailable"
if command -v find-skills >/dev/null 2>&1; then
  find_skills_status="available"
fi

since_note="not set"
if [[ -n "$SINCE_EPOCH" ]]; then
  since_note="$SINCE_EPOCH"
fi

freshness_note="n/a"
if [[ -n "$SINCE_EPOCH" && -f "$scratchpad_file" ]]; then
  scratchpad_mtime="$(file_mtime_epoch "$scratchpad_file")"
  if [[ "$scratchpad_mtime" -ge "$SINCE_EPOCH" ]]; then
    freshness_note="scratchpad updated after since-epoch"
  else
    freshness_note="scratchpad older than since-epoch"
  fi
fi

changed_files_snapshot="$(git status --short || true)"
[[ -n "$changed_files_snapshot" ]] || changed_files_snapshot="_clean worktree_"

cat > "$OUT_FILE" <<EOF
# Retro Evidence Snapshot

- Generated at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- Repository root: $REPO_ROOT
- Session dir: $SESSION_DIR
- Since epoch filter: $since_note

## Sources

- scratchpad: $scratchpad_file ($scratchpad_status)
- hitl events: $events_file ($events_status)
- codex tui log: $codex_tui_log
- session logs dir: $session_logs_dir
- find-skills: $find_skills_status

## Token Limit Signals

\`\`\`text
$token_limit_hits
\`\`\`

## HITL Decisions (Recent)

- Decision count: $scratchpad_count

\`\`\`text
$scratchpad_recent
\`\`\`

## HITL Event Tail

\`\`\`text
$events_tail
\`\`\`

## Session Warning Signals

\`\`\`text
$session_warns
\`\`\`

## Scratchpad Freshness

- $freshness_note

## Changed Files Snapshot

\`\`\`text
$changed_files_snapshot
\`\`\`
EOF

log "wrote evidence snapshot: $OUT_FILE"
