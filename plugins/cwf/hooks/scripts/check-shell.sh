#!/usr/bin/env bash
set -euo pipefail
# check-shell.sh — PostToolUse hook for Write|Edit
# Validates shell scripts using shellcheck after write/edit operations.
# If violations are found, blocks with a reason so Claude can self-correct.
# Skips silently when: not a .sh file, file doesn't exist, shellcheck not available,
# or file is under project artifacts (excluded from lint).

HOOK_GROUP="lint_shell"
# shellcheck source=cwf-hook-gate.sh
source "$(dirname "${BASH_SOURCE[0]}")/cwf-hook-gate.sh"

# --- Parse stdin ---
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# --- Early exits ---

# No file path
if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Not a shell script
case "$FILE_PATH" in
    *.sh) ;;
    *) exit 0 ;;
esac

# Skip project artifact paths (these are session artifacts, not production code)
case "$FILE_PATH" in
    */.cwf/projects/*|.cwf/projects/*) exit 0 ;;
esac

# File doesn't exist (may have been deleted or path is virtual)
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# shellcheck not available
if ! command -v shellcheck >/dev/null 2>&1; then
    exit 0
fi

# --- Run shellcheck ---
set +e
LINT_OUTPUT=$(shellcheck -f gcc "$FILE_PATH" 2>&1)
LINT_EXIT=$?
set -e

if [ "$LINT_EXIT" -eq 0 ]; then
    # Clean — pass silently
    exit 0
fi

# --- Report violations ---
# Truncate output to avoid flooding context
TRUNCATED=$(echo "$LINT_OUTPUT" | head -20)
LINE_COUNT=$(echo "$LINT_OUTPUT" | wc -l | tr -d ' ')
SUFFIX=""
if [ "$LINE_COUNT" -gt 20 ]; then
    SUFFIX=" ... (${LINE_COUNT} total lines, showing first 20)"
fi

# Escape for JSON
REASON=$(printf '%s%s' "$TRUNCATED" "$SUFFIX" | jq -Rs .)

cat <<EOF
{"decision":"block","reason":${REASON}}
EOF
