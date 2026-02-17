#!/usr/bin/env bash
set -euo pipefail
# check-links-local.sh — PostToolUse blocking hook for Write|Edit
# Runs check-links.sh --local on the edited .md file's directory context.
# Skips silently when: not a .md file, file doesn't exist, or file is under project artifacts.
# Blocks when deterministic tooling is unavailable (lychee/check-links.sh missing).

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
    local repo_root="${2:-}"
    local tmp_root=""

    if [[ -n "$repo_root" && ("$abs_path" == "$repo_root" || "$abs_path" == "$repo_root/"*) ]]; then
        return 1
    fi

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

# Skip project artifact paths
case "$FILE_PATH" in
    */.cwf/projects/*|.cwf/projects/*) exit 0 ;;
esac

# File doesn't exist
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# --- Resolve repo scope and skip external temp artifacts ---
LINT_DIR="${CWD:-.}"
REPO_ROOT="$(git -C "$LINT_DIR" rev-parse --show-toplevel 2>/dev/null || true)"
ABS_FILE_PATH="$(resolve_abs_path "$FILE_PATH" "$LINT_DIR" || true)"
if [[ -n "$ABS_FILE_PATH" ]]; then
    if is_external_tmp_path "$ABS_FILE_PATH" "$REPO_ROOT"; then
        exit 0
    fi
    if [[ -n "$REPO_ROOT" && "$ABS_FILE_PATH" != "$REPO_ROOT" && "$ABS_FILE_PATH" != "$REPO_ROOT/"* ]]; then
        exit 0
    fi
fi

# lychee not available — block (deterministic gate unavailable)
if ! command -v lychee >/dev/null 2>&1; then
    REASON=$(printf 'Link checker unavailable for %s: lychee is not installed.\nInstall lychee to continue markdown edits safely.' "$FILE_PATH" | jq -Rs .)
    cat <<EOF
{"decision":"block","reason":${REASON}}
EOF
    exit 0
fi

# --- Find plugin check-links.sh ---
if [ -z "$REPO_ROOT" ]; then
    exit 0
fi
CHECK_LINKS="${REPO_ROOT}/plugins/cwf/skills/refactor/scripts/check-links.sh"

if [ ! -x "$CHECK_LINKS" ]; then
    REASON=$(printf 'Link checker unavailable for %s: plugins/cwf/skills/refactor/scripts/check-links.sh is missing or not executable.' "$FILE_PATH" | jq -Rs .)
    cat <<EOF
{"decision":"block","reason":${REASON}}
EOF
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

REASON=$(printf 'Broken links detected in %s:\n%s%s\nFor triage guidance, see references/agent-patterns.md § Broken Link Triage Protocol' "$FILE_PATH" "$TRUNCATED" "$SUFFIX" | jq -Rs .)

cat <<EOF
{"decision":"block","reason":${REASON}}
EOF
