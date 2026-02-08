#!/usr/bin/env bash
set -euo pipefail
# check-markdown.sh — PostToolUse hook for Write|Edit
# Validates markdown files using markdownlint after write/edit operations.
# If violations are found, blocks with a reason so Claude can self-correct.
# Skips silently when: not a .md file, file doesn't exist, markdownlint not available,
# or file is under prompt-logs/ (excluded from lint).

HOOK_GROUP="lint_markdown"
# shellcheck source=cwf-hook-gate.sh
source "$(dirname "${BASH_SOURCE[0]}")/cwf-hook-gate.sh"

# --- Parse stdin ---
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# --- Early exits ---

# No file path
if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Not a markdown file
case "$FILE_PATH" in
    *.md) ;;
    *) exit 0 ;;
esac

# Skip prompt-logs/ paths (these are session artifacts, not production docs)
case "$FILE_PATH" in
    */prompt-logs/*|prompt-logs/*) exit 0 ;;
esac

# File doesn't exist (may have been deleted or path is virtual)
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# markdownlint-cli2 not available
if ! command -v npx >/dev/null 2>&1; then
    exit 0
fi

# --- Run markdownlint ---
# Run from CWD if available (to pick up .markdownlint.json and .markdownlintignore)
LINT_DIR="${CWD:-.}"

set +e
LINT_OUTPUT=$(cd "$LINT_DIR" && npx --yes markdownlint-cli2 "$FILE_PATH" 2>&1)
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
