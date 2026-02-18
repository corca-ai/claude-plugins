#!/usr/bin/env bash
set -euo pipefail
# check-markdown.sh — PostToolUse hook for Write|Edit
# Validates markdown files using markdownlint after write/edit operations.
# If violations are found, blocks with a reason so Claude can self-correct.
# Skips silently when: not a .md file, file doesn't exist, or file is under
# project artifacts (excluded from lint). Missing markdownlint is a hard block.

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

normalize_abs_path() {
    local value="$1"
    value="${value%/}"
    printf '%s' "$value"
}

append_runtime_skip_dir() {
    local candidate="${1:-}"
    local normalized=""
    local existing=""

    [[ -n "$candidate" ]] || return 0
    normalized="$(normalize_abs_path "$candidate")"
    [[ -n "$normalized" ]] || return 0

    for existing in "${RUNTIME_SKIP_DIRS[@]}"; do
        if [[ "$existing" == "$normalized" ]]; then
            return 0
        fi
    done
    RUNTIME_SKIP_DIRS+=("$normalized")
}

init_runtime_skip_dirs() {
    local base_dir="$1"
    local projects_dir=""
    local sessions_dir=""
    local prompt_logs_dir=""
    base_dir="$(cd "$base_dir" 2>/dev/null && pwd -P || printf '%s' "$base_dir")"

    RUNTIME_SKIP_DIRS=()
    if [[ -f "$ARTIFACT_PATHS_SCRIPT" ]]; then
        # shellcheck source=plugins/cwf/scripts/cwf-artifact-paths.sh
        source "$ARTIFACT_PATHS_SCRIPT"
        projects_dir="$(resolve_cwf_projects_dir "$base_dir" 2>/dev/null || true)"
        sessions_dir="$(resolve_cwf_session_logs_dir "$base_dir" 2>/dev/null || true)"
        prompt_logs_dir="$(resolve_cwf_prompt_logs_dir "$base_dir" 2>/dev/null || true)"
        append_runtime_skip_dir "$projects_dir"
        append_runtime_skip_dir "$sessions_dir"
        append_runtime_skip_dir "$prompt_logs_dir"
    fi

    append_runtime_skip_dir "$base_dir/.cwf/projects"
    append_runtime_skip_dir "$base_dir/.cwf/sessions"
    append_runtime_skip_dir "$base_dir/.cwf/prompt-logs"
}

is_runtime_artifact_path() {
    local abs_path="$1"
    local skip_dir=""
    for skip_dir in "${RUNTIME_SKIP_DIRS[@]}"; do
        if [[ "$abs_path" == "$skip_dir" || "$abs_path" == "$skip_dir/"* ]]; then
            return 0
        fi
    done
    return 1
}

# --- Parse stdin ---
INPUT=$(cat)
FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty')
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"
ARTIFACT_PATHS_SCRIPT="$PLUGIN_ROOT/scripts/cwf-artifact-paths.sh"
RUNTIME_SKIP_DIRS=()

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

# File doesn't exist (may have been deleted or path is virtual)
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# Resolve repo scope first so /tmp artifact filtering is deterministic even
# when markdownlint dependencies are missing.
LINT_DIR="${CWD:-.}"
REPO_ROOT="$(git -C "$LINT_DIR" rev-parse --show-toplevel 2>/dev/null || true)"
ABS_FILE_PATH="$(resolve_abs_path "$FILE_PATH" "${LINT_DIR}" || true)"
if [[ -n "$ABS_FILE_PATH" ]]; then
    if is_external_tmp_path "$ABS_FILE_PATH" "$REPO_ROOT"; then
        exit 0
    fi
    if [[ -n "$REPO_ROOT" && "$ABS_FILE_PATH" != "$REPO_ROOT" && "$ABS_FILE_PATH" != "$REPO_ROOT/"* ]]; then
        exit 0
    fi
fi

if [[ -n "$ABS_FILE_PATH" ]]; then
    init_runtime_skip_dirs "${REPO_ROOT:-$LINT_DIR}"
    if is_runtime_artifact_path "$ABS_FILE_PATH"; then
        exit 0
    fi
fi

# markdownlint-cli2 not available — block (deterministic gate unavailable)
if ! command -v markdownlint-cli2 >/dev/null 2>&1; then
    REASON=$(
        printf 'Markdown lint gate unavailable for %s: markdownlint-cli2 is not installed.\nInstall markdownlint-cli2 (for example, run cwf:setup --tools) and retry.' \
            "$FILE_PATH" | jq -Rs .
    )
    cat <<EOF
{"decision":"block","reason":${REASON}}
EOF
    exit 0
fi

# --- Run markdownlint ---
# Run from CWD if available (to pick up .markdownlint.json and .markdownlintignore)
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
    LINT_OUTPUT=$(cd "$LINT_DIR" && markdownlint-cli2 --config "$LINT_CONFIG" "$FILE_PATH" 2>&1)
else
    LINT_OUTPUT=$(cd "$LINT_DIR" && markdownlint-cli2 "$FILE_PATH" 2>&1)
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
