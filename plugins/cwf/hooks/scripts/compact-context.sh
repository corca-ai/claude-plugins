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

# Read stdin to extract session_id for session log lookup
INPUT=$(cat)
HOOK_SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || true)

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
decisions=()
decision_journal=()
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
        elif [[ "$line" =~ ^[[:space:]]+dir:[[:space:]]*\"?([^\"]*)\"? ]]; then
            dir="${BASH_REMATCH[1]}"
            current_list=""
        elif [[ "$line" =~ ^[[:space:]]+branch:[[:space:]]*\"?([^\"]*)\"? ]]; then
            branch="${BASH_REMATCH[1]}"
            current_list=""
        elif [[ "$line" =~ ^[[:space:]]+phase:[[:space:]]*\"?([^\"]*)\"? ]]; then
            phase="${BASH_REMATCH[1]}"
            current_list=""
        elif [[ "$line" =~ ^[[:space:]]+task:[[:space:]]*\"?([^\"]*)\"? ]]; then
            task="${BASH_REMATCH[1]}"
            current_list=""
        elif [[ "$line" =~ ^[[:space:]]+key_files: ]]; then
            current_list="key_files"
        elif [[ "$line" =~ ^[[:space:]]+dont_touch: ]]; then
            current_list="dont_touch"
        elif [[ "$line" =~ ^[[:space:]]+decisions: ]]; then
            current_list="decisions"
        elif [[ "$line" =~ ^[[:space:]]+decision_journal: ]]; then
            current_list="decision_journal"
        elif [[ "$line" =~ ^[[:space:]]+-[[:space:]]+(.+) ]]; then
            item="${BASH_REMATCH[1]}"
            if [[ "$current_list" == "key_files" ]]; then
                key_files+=("$item")
            elif [[ "$current_list" == "dont_touch" ]]; then
                dont_touch+=("$item")
            elif [[ "$current_list" == "decisions" ]]; then
                # Strip surrounding quotes
                item="${item#\"}"
                item="${item%\"}"
                decisions+=("$item")
            elif [[ "$current_list" == "decision_journal" ]]; then
                # Strip surrounding quotes from journal entries
                item="${item#\"}"
                item="${item%\"}"
                decision_journal+=("$item")
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

if [[ ${#decisions[@]} -gt 0 ]]; then
    context="${context}
Key decisions:"
    for d in "${decisions[@]}"; do
        context="${context}
  - ${d}"
    done
fi

# ── Append recent turns from prompt-logger session log (if available) ─────────
# Provides conversational context alongside structural metadata from live section.
# Gracefully skips if prompt-logger is not installed or no log exists.
MAX_TURNS=3
MAX_LINES=100
recent_turns=""

if [[ -n "$HOOK_SESSION_ID" ]]; then
    # prompt-logger stores session log path in /tmp/claude-prompt-logger-{session_id}/out_file
    PL_STATE_DIR="/tmp/claude-prompt-logger-${HOOK_SESSION_ID}"
    if [[ -f "$PL_STATE_DIR/out_file" ]]; then
        SESSION_LOG=$(cat "$PL_STATE_DIR/out_file")
        if [[ -f "$SESSION_LOG" ]]; then
            # Extract last N turns: turns are separated by "---" lines,
            # each starting with "## Turn N".
            # Strategy: split by "---", take last MAX_TURNS turn blocks, cap at MAX_LINES.
            recent_turns=$(awk -v max_turns="$MAX_TURNS" '
                /^---$/ { block_count++; next }
                /^## Turn [0-9]/ { turn_start = 1 }
                turn_start {
                    blocks[block_count] = blocks[block_count] (blocks[block_count] ? "\n" : "") $0
                }
                END {
                    start = block_count - max_turns + 1
                    if (start < 1) start = 1
                    for (i = start; i <= block_count; i++) {
                        if (blocks[i] != "") print blocks[i]
                        if (i < block_count) print "---"
                    }
                }
            ' "$SESSION_LOG" | tail -n "$MAX_LINES")
        fi
    fi
fi

# ── Phase-aware context enrichment ────────────────────────────────────────────
# Impl phase has 10-50x higher decision density than clarify/plan.
# Inject plan.md summary and decision journal when phase=impl.
plan_content=""
if [[ "$phase" == *impl* ]]; then
    # Find plan.md from key_files or session dir
    plan_path=""
    for f in "${key_files[@]}"; do
        if [[ "$f" == *plan.md ]]; then
            plan_path="${CLAUDE_PROJECT_DIR:-.}/${f}"
            break
        fi
    done
    # Fallback: look in session dir
    if [[ -z "$plan_path" ]] && [[ -n "$dir" ]]; then
        plan_path="${CLAUDE_PROJECT_DIR:-.}/${dir}/plan.md"
    fi
    if [[ -n "$plan_path" ]] && [[ -f "$plan_path" ]]; then
        plan_content=$(head -n 80 "$plan_path")
    fi
fi

if [[ -n "$plan_content" ]]; then
    context="${context}

Plan summary (first 80 lines):
${plan_content}"
fi

if [[ ${#decision_journal[@]} -gt 0 ]]; then
    context="${context}

Decision journal (impl-phase decisions made before compact):"
    for entry in "${decision_journal[@]}"; do
        context="${context}
  - ${entry}"
    done
fi

context="${context}

Read cwf-state.yaml and the plan file in the session dir to restore full context."

if [[ -n "$recent_turns" ]]; then
    context="${context}

Recent conversation (last ${MAX_TURNS} turns before compact):
${recent_turns}"
fi

# Output JSON with additionalContext
jq -n --arg ctx "$context" \
    '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":$ctx}}'
