#!/usr/bin/env bash
set -euo pipefail
# compact-context.sh — SessionStart(compact) hook
# Reads cwf-state.yaml live section and injects context after auto-compact.
#
# Input: stdin JSON with source: "compact" (SessionStart common fields)
# Output: JSON with hookSpecificOutput.additionalContext (or silent exit 0)
#
# Three outcomes (never silent when live is populated):
#   1. INJECT — live section populated → additionalContext with session state
#   2. SKIP   — live section empty → exit 0 (pre-live session, no action)
#   3. SKIP   — cwf-state.yaml not found → exit 0

HOOK_GROUP="compact_recovery"
# shellcheck source=cwf-hook-gate.sh
source "$(dirname "${BASH_SOURCE[0]}")/cwf-hook-gate.sh"

# Consume stdin (required for hook protocol)
cat > /dev/null

# Find cwf-state.yaml relative to project root
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/cwf-state.yaml"
if [[ ! -f "$STATE_FILE" ]]; then
    exit 0
fi

# Parse live section from cwf-state.yaml using simple line-by-line parsing
# (no yq/jq dependency for YAML — keeps it portable)
in_live=false
session_id=""
dir=""
branch=""
phase=""
task=""
key_files=()
dont_touch=()
current_list=""

while IFS= read -r line; do
    # Detect live section start
    if [[ "$line" =~ ^live: ]]; then
        in_live=true
        continue
    fi

    # Exit live section on next top-level key (non-indented, non-comment, non-empty)
    if $in_live && [[ "$line" =~ ^[a-z#] ]] && [[ ! "$line" =~ ^[[:space:]] ]]; then
        break
    fi

    if $in_live; then
        # Simple scalar fields
        if [[ "$line" =~ ^[[:space:]]+session_id:[[:space:]]*\"?([^\"]*)\"? ]]; then
            session_id="${BASH_REMATCH[1]}"
            current_list=""
        elif [[ "$line" =~ ^[[:space:]]+dir:[[:space:]]*(.+) ]]; then
            dir="${BASH_REMATCH[1]}"
            current_list=""
        elif [[ "$line" =~ ^[[:space:]]+branch:[[:space:]]*(.+) ]]; then
            branch="${BASH_REMATCH[1]}"
            current_list=""
        elif [[ "$line" =~ ^[[:space:]]+phase:[[:space:]]*(.+) ]]; then
            phase="${BASH_REMATCH[1]}"
            current_list=""
        elif [[ "$line" =~ ^[[:space:]]+task:[[:space:]]*\"?([^\"]*)\"? ]]; then
            task="${BASH_REMATCH[1]}"
            current_list=""
        elif [[ "$line" =~ ^[[:space:]]+key_files: ]]; then
            current_list="key_files"
        elif [[ "$line" =~ ^[[:space:]]+dont_touch: ]]; then
            current_list="dont_touch"
        elif [[ "$line" =~ ^[[:space:]]+-[[:space:]]+(.+) ]]; then
            item="${BASH_REMATCH[1]}"
            if [[ "$current_list" == "key_files" ]]; then
                key_files+=("$item")
            elif [[ "$current_list" == "dont_touch" ]]; then
                dont_touch+=("$item")
            fi
        fi
    fi
done < "$STATE_FILE"

# Skip if live section is empty (no session active)
if [[ -z "$session_id" ]] && [[ -z "$task" ]]; then
    exit 0
fi

# Assemble context string
context="[Compact Recovery] Session: ${session_id} | Phase: ${phase}
Task: ${task}
Branch: ${branch}
Session dir: ${dir}"

if [[ ${#key_files[@]} -gt 0 ]]; then
    context="${context}
Key files to read for context:"
    for f in "${key_files[@]}"; do
        context="${context}
  - ${f}"
    done
fi

if [[ ${#dont_touch[@]} -gt 0 ]]; then
    context="${context}
Do NOT modify:"
    for f in "${dont_touch[@]}"; do
        context="${context}
  - ${f}"
    done
fi

context="${context}

Read cwf-state.yaml and the plan file in the session dir to restore full context."

# Output JSON with additionalContext
jq -n --arg ctx "$context" \
    '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":$ctx}}'
