#!/usr/bin/env bash
set -euo pipefail
# compact-context.sh — SessionStart(compact) hook
# Reads the CWF state file live section and injects context after auto-compact.
#
# Input: stdin JSON with source: "compact" (SessionStart common fields)
# Output: JSON with hookSpecificOutput.additionalContext (or silent exit 0)
#
# Three outcomes (never silent when live is populated):
#   1. INJECT — live section populated → additionalContext with session state
#   2. SKIP   — live section empty → exit 0 (pre-live session, no action)
#   3. SKIP   — state file not found → exit 0

HOOK_GROUP="compact_recovery"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=plugins/cwf/hooks/scripts/cwf-hook-gate.sh
source "$SCRIPT_DIR/cwf-hook-gate.sh"

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"
RESOLVER_SCRIPT="${PLUGIN_ROOT}/scripts/cwf-artifact-paths.sh"
LIVE_RESOLVER_SCRIPT="${PLUGIN_ROOT}/scripts/cwf-live-state.sh"

if [[ ! -f "$RESOLVER_SCRIPT" ]]; then
    exit 0
fi

# shellcheck source=plugins/cwf/scripts/cwf-artifact-paths.sh
source "$RESOLVER_SCRIPT"
if [[ -f "$LIVE_RESOLVER_SCRIPT" ]]; then
    # shellcheck source=plugins/cwf/scripts/cwf-live-state.sh
    source "$LIVE_RESOLVER_SCRIPT"
fi

# Read stdin to extract session_id for session log lookup
INPUT=$(cat)
HOOK_SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || true)
HOOK_CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)
if [[ -z "$HOOK_CWD" ]]; then
    HOOK_CWD="${CLAUDE_PROJECT_DIR:-$PWD}"
fi

session_map_file_for_cwd() {
    local cwd="$1"
    local repo_root=""
    local common_dir=""

    repo_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)
    common_dir=$(git -C "$cwd" rev-parse --git-common-dir 2>/dev/null || true)
    if [[ -z "$repo_root" || -z "$common_dir" ]]; then
        return 1
    fi

    if [[ "$common_dir" == /* ]]; then
        printf '%s\n' "$common_dir/cwf-session-worktree-map.tsv"
    else
        printf '%s\n' "$repo_root/$common_dir/cwf-session-worktree-map.tsv"
    fi
}

session_map_lookup() {
    local map_file="$1"
    local sid="$2"
    [[ -f "$map_file" ]] || return 1
    awk -F '\t' -v sid="$sid" '
        $1 == sid {
            print $2 "\t" $3 "\t" $4
            found=1
            exit
        }
        END { exit(found ? 0 : 1) }
    ' "$map_file"
}

# Find CWF state file relative to project root
STATE_BASE_DIR="${CLAUDE_PROJECT_DIR:-.}"
ROOT_STATE_FILE="$(resolve_cwf_state_file "$STATE_BASE_DIR")"
if [[ ! -f "$ROOT_STATE_FILE" ]]; then
    exit 0
fi
STATE_FILE="$ROOT_STATE_FILE"
if declare -F cwf_live_resolve_file >/dev/null 2>&1; then
    RESOLVED_LIVE_STATE="$(cwf_live_resolve_file "$STATE_BASE_DIR" 2>/dev/null || true)"
    if [[ -n "$RESOLVED_LIVE_STATE" && -f "$RESOLVED_LIVE_STATE" ]]; then
        STATE_FILE="$RESOLVED_LIVE_STATE"
    fi
fi

# Parse live section from the state file using simple line-by-line parsing
# (no yq/jq dependency for YAML — keeps it portable)
in_live=false
session_id=""
dir=""
branch=""
phase=""
task=""
worktree_root=""
worktree_branch=""
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
        elif [[ "$line" =~ ^[[:space:]]+worktree_root:[[:space:]]*\"?([^\"]*)\"? ]]; then
            worktree_root="${BASH_REMATCH[1]}"
            current_list=""
        elif [[ "$line" =~ ^[[:space:]]+worktree_branch:[[:space:]]*\"?([^\"]*)\"? ]]; then
            worktree_branch="${BASH_REMATCH[1]}"
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

# Resolve expected worktree from session map (preferred) or live fields (fallback).
expected_worktree=""
expected_branch=""
expected_recorded_at=""
current_worktree_root=$(git -C "$HOOK_CWD" rev-parse --show-toplevel 2>/dev/null || true)

if [[ -n "$HOOK_SESSION_ID" ]]; then
    SESSION_MAP_FILE=$(session_map_file_for_cwd "$HOOK_CWD" 2>/dev/null || true)
    if [[ -n "$SESSION_MAP_FILE" ]]; then
        SESSION_MAP_ROW=$(session_map_lookup "$SESSION_MAP_FILE" "$HOOK_SESSION_ID" 2>/dev/null || true)
        if [[ -n "$SESSION_MAP_ROW" ]]; then
            expected_worktree=$(printf '%s' "$SESSION_MAP_ROW" | awk -F '\t' '{print $1}')
            expected_branch=$(printf '%s' "$SESSION_MAP_ROW" | awk -F '\t' '{print $2}')
            expected_recorded_at=$(printf '%s' "$SESSION_MAP_ROW" | awk -F '\t' '{print $3}')
        fi
    fi
fi

if [[ -z "$expected_worktree" && -n "$worktree_root" ]]; then
    if [[ "$worktree_root" == /* ]]; then
        expected_worktree="$worktree_root"
    else
        expected_worktree="${CLAUDE_PROJECT_DIR:-.}/$worktree_root"
    fi
fi
if [[ -z "$expected_branch" && -n "$worktree_branch" ]]; then
    expected_branch="$worktree_branch"
fi

# Assemble context string
context="[Compact Recovery] Session: ${session_id} | Phase: ${phase}
Task: ${task}
Branch: ${branch}
Session dir: ${dir}"

if [[ -n "$expected_worktree" ]]; then
    context="${context}
Expected worktree: ${expected_worktree}"
fi

if [[ -n "$expected_branch" ]]; then
    context="${context}
Expected worktree branch: ${expected_branch}"
fi

if [[ -n "$expected_worktree" && -n "$current_worktree_root" && "$current_worktree_root" != "$expected_worktree" ]]; then
    context="${context}

[WORKTREE ALERT] Current worktree (${current_worktree_root}) does not match bound session worktree (${expected_worktree}).
Switch before continuing:
  cd ${expected_worktree}"
    if [[ -n "$expected_branch" ]]; then
        context="${context}
  git switch ${expected_branch}"
    fi
    if [[ -n "$expected_recorded_at" ]]; then
        context="${context}
Binding recorded at epoch: ${expected_recorded_at}"
    fi
fi

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

# ── Append recent turns from session log (if available) ─────────────────────
# Provides conversational context alongside structural metadata from live section.
# Gracefully skips if session logging is not enabled or no log exists.
MAX_TURNS=3
MAX_LINES=100
recent_turns=""

if [[ -n "$HOOK_SESSION_ID" ]]; then
    # Session logger stores current output path in:
    # - /tmp/cwf-session-log-{session_id}/out_file
    PL_STATE_DIR="/tmp/cwf-session-log-${HOOK_SESSION_ID}"
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
        decoded_entry="$(printf '%s' "$entry" | sed 's/\\"/"/g')"
        entry_summary="$(printf '%s' "$decoded_entry" | jq -r '
            if type == "object" and (.decision_id // "") != "" then
                "[" + .decision_id + "] " + (.question // "?") + " => " + (.answer // "?")
            else
                empty
            end
        ' 2>/dev/null || true)"
        if [[ -n "$entry_summary" ]]; then
            context="${context}
  - ${entry_summary}"
            continue
        fi
        context="${context}
  - ${entry}"
    done
fi

context="${context}

Read the CWF state file and the plan file in the session dir to restore full context."

if [[ -n "$recent_turns" ]]; then
    context="${context}

Recent conversation (last ${MAX_TURNS} turns before compact):
${recent_turns}"
fi

# Output JSON with additionalContext
jq -n --arg ctx "$context" \
    '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":$ctx}}'
