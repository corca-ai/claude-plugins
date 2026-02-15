#!/usr/bin/env bash
set -euo pipefail
# check-markdown.sh — PostToolUse hook for Write|Edit
# Validates markdown files using markdownlint after write/edit operations.
# If violations are found, blocks with a reason so Claude can self-correct.
# Skips silently when: not a .md file, file doesn't exist, markdownlint not available,
# or file is under project artifacts (excluded from lint).

HOOK_GROUP="lint_markdown"
# shellcheck source=cwf-hook-gate.sh
source "$(dirname "${BASH_SOURCE[0]}")/cwf-hook-gate.sh"

# --- Parse stdin ---
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"

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

# Skip project artifact paths (these are session artifacts, not production docs)
case "$FILE_PATH" in
    */.cwf/projects/*|.cwf/projects/*) exit 0 ;;
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
REPO_ROOT="$(git -C "$LINT_DIR" rev-parse --show-toplevel 2>/dev/null || true)"
PROJECT_CONFIG=""
if [ -n "$REPO_ROOT" ] && [ -f "$REPO_ROOT/.markdownlint-cli2.jsonc" ]; then
    PROJECT_CONFIG="$REPO_ROOT/.markdownlint-cli2.jsonc"
fi

PLUGIN_CONFIG="$PLUGIN_ROOT/hooks/markdownlint/.markdownlint-cli2.jsonc"
LINT_CONFIG="$PROJECT_CONFIG"
if [ -z "$LINT_CONFIG" ] && [ -f "$PLUGIN_CONFIG" ]; then
    LINT_CONFIG="$PLUGIN_CONFIG"
fi

set +e
if [ -n "$LINT_CONFIG" ]; then
    LINT_OUTPUT=$(cd "$LINT_DIR" && npx --yes markdownlint-cli2 --config "$LINT_CONFIG" "$FILE_PATH" 2>&1)
else
    LINT_OUTPUT=$(cd "$LINT_DIR" && npx --yes markdownlint-cli2 "$FILE_PATH" 2>&1)
fi
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
