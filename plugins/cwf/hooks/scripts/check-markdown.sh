#!/usr/bin/env bash
set -euo pipefail
# check-markdown.sh — PostToolUse hook for Write|Edit
# Validates markdown files using markdownlint after write/edit operations.
# If violations are found, blocks with a reason so Claude can self-correct.
# Skips silently when: not a .md file, file doesn't exist, markdownlint not available,
# or file is under project artifacts (excluded from lint).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_GROUP="lint_markdown"
# shellcheck source=plugins/cwf/hooks/scripts/cwf-hook-gate.sh
source "$SCRIPT_DIR/cwf-hook-gate.sh"

resolve_abs_path() {
    local raw_path="$1"
    local base_dir="$2"
    local candidate=""
    local abs_dir=""

    if [[ "$raw_path" == /* ]]; then
        candidate="$raw_path"
    else
        candidate="$base_dir/$raw_path"
    fi

    abs_dir="$(cd "$(dirname "$candidate")" 2>/dev/null && pwd -P)" || return 1
    printf '%s/%s\n' "$abs_dir" "$(basename "$candidate")"
}

is_external_tmp_path() {
    local abs_path="$1"
    local tmp_root=""

    case "$abs_path" in
        /tmp/*|/private/tmp/*) return 0 ;;
    esac

    tmp_root="${TMPDIR:-}"
    tmp_root="${tmp_root%/}"
    if [[ -n "$tmp_root" && "$abs_path" == "$tmp_root"/* ]]; then
        return 0
    fi

    return 1
}

# --- Parse stdin ---
INPUT=$(cat)
FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty')
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
    */.cwf/projects/*|.cwf/projects/*|*/.cwf/prompt-logs/*|.cwf/prompt-logs/*) exit 0 ;;
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
ABS_FILE_PATH="$(resolve_abs_path "$FILE_PATH" "${LINT_DIR}" || true)"
if [[ -n "$ABS_FILE_PATH" ]]; then
    if is_external_tmp_path "$ABS_FILE_PATH"; then
        exit 0
    fi
    if [[ -n "$REPO_ROOT" && "$ABS_FILE_PATH" != "$REPO_ROOT" && "$ABS_FILE_PATH" != "$REPO_ROOT/"* ]]; then
        exit 0
    fi
fi

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
