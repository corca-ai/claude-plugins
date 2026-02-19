#!/usr/bin/env bash
set -euo pipefail
# cancel-timer.sh — PostToolUse hook for AskUserQuestion
# Cancels attention timer when user responds.
#
# v2.0: Session-scoped state files + records user interaction timestamp

HOOK_GROUP="attention"
# shellcheck source=cwf-hook-gate.sh
source "$(dirname "${BASH_SOURCE[0]}")/cwf-hook-gate.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=slack-send.sh
source "$SCRIPT_DIR/slack-send.sh"

# Read hook input
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

# Session-scoped state files
if [ -n "$SESSION_ID" ]; then
    HASH=$(slack_session_hash "$SESSION_ID")
    TIMER_FILE=$(slack_state_file "$HASH" "timer.pid")
    INPUT_FILE=$(slack_state_file "$HASH" "input.json")
    DEBUG_LOG=$(slack_state_file "$HASH" "debug.log")

    # Record user interaction timestamp (user responded to a question)
    date +%s > "$(slack_state_file "$HASH" "last-user-ts")"
else
    TIMER_FILE="/tmp/claude-attention-timer.pid"
    INPUT_FILE="/tmp/claude-attention-input.json"
    DEBUG_LOG="/tmp/claude-attention-debug.log"
fi

# Debug: log that this script was called
echo "$(date): cancel-timer.sh called (session: ${SESSION_ID:-unknown})" >> "$DEBUG_LOG"

if [ -f "$TIMER_FILE" ]; then
    echo "$(date): Found timer file, killing PID $(cat "$TIMER_FILE")" >> "$DEBUG_LOG"
    kill "$(cat "$TIMER_FILE")" 2>/dev/null || true
    rm -f "$TIMER_FILE" "$INPUT_FILE"
else
    echo "$(date): No timer file found" >> "$DEBUG_LOG"
fi

exit 0
