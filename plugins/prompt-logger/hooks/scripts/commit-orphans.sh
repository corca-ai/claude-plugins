#!/usr/bin/env bash
set -euo pipefail
# commit-orphans.sh — SessionStart(startup) hook
# Detects and auto-commits orphaned session log .md files in prompt-logs/sessions/.
# Orphans occur when a session is interrupted before SessionEnd fires.
#
# Input: stdin JSON with session_id, cwd (SessionStart common fields)
# Output: silent (no additionalContext needed)
#
# Guard: only runs when AUTO_COMMIT is enabled and git is clean (no staged changes).

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

if [ -z "$CWD" ]; then
    exit 0
fi

# ── Load config ──────────────────────────────────────────────────────────────
[ -f "$HOME/.claude/.env" ] && { set -a; source "$HOME/.claude/.env"; set +a; }

_safe_load() {
  local _var="$1"; local _line
  _line=$(grep -shm1 "^export ${_var}=" ~/.zshrc ~/.bashrc 2>/dev/null) || true
  if [ -n "${_line:-}" ]; then
    local _val="${_line#*=}"
    _val="${_val#[\"\']}" ; _val="${_val%[\"\']}"
    printf -v "$_var" '%s' "$_val"
    export "$_var"
  fi
}
[ -z "${CLAUDE_CORCA_PROMPT_LOGGER_DIR:-}" ] && _safe_load CLAUDE_CORCA_PROMPT_LOGGER_DIR
[ -z "${CLAUDE_CORCA_PROMPT_LOGGER_AUTO_COMMIT:-}" ] && _safe_load CLAUDE_CORCA_PROMPT_LOGGER_AUTO_COMMIT

AUTO_COMMIT="${CLAUDE_CORCA_PROMPT_LOGGER_AUTO_COMMIT:-false}"
if [ "$AUTO_COMMIT" != "true" ]; then
    exit 0
fi

LOG_DIR="${CLAUDE_CORCA_PROMPT_LOGGER_DIR:-${CWD}/prompt-logs/sessions}"
if [ ! -d "$LOG_DIR" ]; then
    exit 0
fi

# ── Check git repo ───────────────────────────────────────────────────────────
if ! git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    exit 0
fi

# Don't interfere with pre-existing staged changes
if ! git -C "$CWD" diff --cached --quiet 2>/dev/null; then
    exit 0
fi

# ── Find orphaned session logs ───────────────────────────────────────────────
SESSION_FILES=$(git -C "$CWD" ls-files --others --modified -- "$LOG_DIR/*.md" 2>/dev/null) || true

if [ -z "$SESSION_FILES" ]; then
    exit 0
fi

# ── Auto-commit orphans ─────────────────────────────────────────────────────
echo "$SESSION_FILES" | xargs -I{} git -C "$CWD" add -- "{}" 2>/dev/null

FILE_COUNT=$(echo "$SESSION_FILES" | wc -l | tr -d ' ')
if [ "$FILE_COUNT" -eq 1 ]; then
    BASENAME=$(basename "$(echo "$SESSION_FILES" | head -1)" .md)
    COMMIT_MSG="prompt-log: ${BASENAME}"
else
    COMMIT_MSG="prompt-log: ${FILE_COUNT} orphaned sessions"
fi

git -C "$CWD" commit --no-verify -m "$COMMIT_MSG" 2>/dev/null || true

exit 0
