#!/usr/bin/env bash
set -euo pipefail
# check-links-local.sh — PostToolUse async hook for Write|Edit
# Runs check-links.sh --local on the edited .md file's directory context.
# Async hook: reports findings as additional_context, does not block.
# Skips silently when: not a .md file, file doesn't exist, lychee not available,
# or file is under prompt-logs/.

HOOK_GROUP="lint_markdown"
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

# Not a markdown file
case "$FILE_PATH" in
    *.md) ;;
    *) exit 0 ;;
esac

# Skip prompt-logs/ paths
case "$FILE_PATH" in
    */prompt-logs/*|prompt-logs/*) exit 0 ;;
esac

# File doesn't exist
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# lychee not available — skip silently
if ! command -v lychee >/dev/null 2>&1; then
    exit 0
fi

# --- Find repo root and check-links.sh ---
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || exit 0)
CHECK_LINKS="${REPO_ROOT}/scripts/check-links.sh"

if [ ! -x "$CHECK_LINKS" ]; then
    exit 0
fi

# --- Run link check on the single file ---
set +e
LINK_OUTPUT=$("$CHECK_LINKS" --local --file "$FILE_PATH" 2>&1)
LINK_EXIT=$?
set -e

if [ "$LINK_EXIT" -eq 0 ]; then
    exit 0
fi

# --- Report broken links as context ---
TRUNCATED=$(echo "$LINK_OUTPUT" | head -15)
LINE_COUNT=$(echo "$LINK_OUTPUT" | wc -l | tr -d ' ')
SUFFIX=""
if [ "$LINE_COUNT" -gt 15 ]; then
    SUFFIX=" ... (${LINE_COUNT} total lines, showing first 15)"
fi

REASON=$(printf 'Broken links detected in %s:\n%s%s' "$FILE_PATH" "$TRUNCATED" "$SUFFIX" | jq -Rs .)

cat <<EOF
{"decision":"block","reason":${REASON}}
EOF
