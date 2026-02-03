#!/bin/bash
# smart-read: PreToolUse hook for Read tool.
# Checks file size before allowing full reads to prevent context waste.
# - Small files (≤WARN): allowed silently
# - Medium files (WARN..DENY]: allowed with additionalContext (line count)
# - Large files (>DENY): denied with guidance to use offset/limit or Grep
# Bypass: set offset or limit explicitly to signal intentional reading.

# --- Load environment variables ---
ENV_FILE="$HOME/.claude/.env"
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

WARN_LINES="${CLAUDE_CORCA_SMART_READ_WARN_LINES:-500}"
DENY_LINES="${CLAUDE_CORCA_SMART_READ_DENY_LINES:-2000}"

# Ensure WARN ≤ DENY (if user sets DENY < WARN, clamp WARN down)
if [ "$WARN_LINES" -gt "$DENY_LINES" ]; then
    WARN_LINES="$DENY_LINES"
fi

# --- Parse stdin ---
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
OFFSET=$(echo "$INPUT" | jq -r '.tool_input.offset // empty')
LIMIT=$(echo "$INPUT" | jq -r '.tool_input.limit // empty')

# --- Early exits (allow) ---

# If offset or limit already set, Claude is being intentional — allow
if [ -n "$OFFSET" ] || [ -n "$LIMIT" ]; then
    exit 0
fi

# No file path — allow (let Read handle it)
if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# File doesn't exist — allow (let Read report the error)
if [ ! -e "$FILE_PATH" ]; then
    exit 0
fi

# --- Binary file detection ---
# Read tool handles PDF, images, and notebooks natively — allow these through
MIME_TYPE=$(file --mime-type -b "$FILE_PATH" 2>/dev/null)
case "$MIME_TYPE" in
    application/pdf|application/octet-stream)
        exit 0
        ;;
    image/*)
        exit 0
        ;;
esac

# Check extension for Jupyter notebooks (.ipynb are JSON but need special handling)
case "$FILE_PATH" in
    *.ipynb)
        exit 0
        ;;
esac

# --- Count lines ---
LINE_COUNT=$(wc -l < "$FILE_PATH" 2>/dev/null)
LINE_COUNT=$(echo "$LINE_COUNT" | tr -d ' ')

if [ -z "$LINE_COUNT" ] || [ "$LINE_COUNT" -eq 0 ] 2>/dev/null; then
    # Can't determine line count or empty file — allow
    exit 0
fi

# --- Apply thresholds ---

if [ "$LINE_COUNT" -le "$WARN_LINES" ]; then
    # Small file — allow silently
    exit 0

elif [ "$LINE_COUNT" -le "$DENY_LINES" ]; then
    # Medium file — allow but inform Claude of the size
    cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"File has ${LINE_COUNT} lines. Consider using offset/limit to read specific sections if you only need part of it."}}
EOF

else
    # Large file — deny and guide to selective reading
    cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"File has ${LINE_COUNT} lines (exceeds ${DENY_LINES}-line threshold). To read this file, either: (1) Use Read with offset/limit to target specific sections, (2) Use Grep to find relevant parts first, or (3) Use the Task tool with Explore agent for broad understanding."}}
EOF
fi
