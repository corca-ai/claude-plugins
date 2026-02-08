#!/usr/bin/env bash
set -euo pipefail
# start-timer.sh — PreToolUse hook for AskUserQuestion/EnterPlanMode/ExitPlanMode
# Starts background timer for attention notifications.
# If user responds before timer expires, cancel-timer.sh will kill this process.
#
# v2.0: Session-scoped state files via slack-send.sh

HOOK_GROUP="attention"
# shellcheck source=cwf-hook-gate.sh
source "$(dirname "${BASH_SOURCE[0]}")/cwf-hook-gate.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=slack-send.sh
source "$SCRIPT_DIR/slack-send.sh"

# Read and save the hook input for later use by attention.sh
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

# Session-scoped state files
if [ -n "$SESSION_ID" ]; then
    HASH=$(slack_session_hash "$SESSION_ID")
    TIMER_FILE=$(slack_state_file "$HASH" "timer.pid")
    INPUT_FILE=$(slack_state_file "$HASH" "input.json")
    DEBUG_LOG=$(slack_state_file "$HASH" "debug.log")
else
    # Fallback: non-session-scoped (legacy)
    TIMER_FILE="/tmp/claude-attention-timer.pid"
    INPUT_FILE="/tmp/claude-attention-input.json"
    DEBUG_LOG="/tmp/claude-attention-debug.log"
fi

# Configurable delay (seconds)
DELAY_SECONDS="${CLAUDE_CORCA_ATTENTION_DELAY:-${CLAUDE_ATTENTION_DELAY:-30}}"

# Debug: log that this script was called
echo "$(date): start-timer.sh called (session: ${SESSION_ID:-unknown})" >> "$DEBUG_LOG"

echo "$INPUT" > "$INPUT_FILE"

# Kill any existing timer
if [ -f "$TIMER_FILE" ]; then
    kill "$(cat "$TIMER_FILE")" 2>/dev/null || true
    rm -f "$TIMER_FILE"
fi

# Start background timer - use nohup to detach from process group
# Without nohup, Claude Code kills the subprocess when the hook exits,
# causing sleep to terminate immediately and trigger the notification right away
nohup bash -c "
    sleep $DELAY_SECONDS
    if [ -f '$TIMER_FILE' ]; then
        cat '$INPUT_FILE' | '$SCRIPT_DIR/attention.sh'
        rm -f '$TIMER_FILE' '$INPUT_FILE'
    fi
" > /dev/null 2>&1 &

# Save the background process PID
echo $! > "$TIMER_FILE"

exit 0
