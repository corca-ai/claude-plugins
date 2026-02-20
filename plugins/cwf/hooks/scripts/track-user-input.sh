#!/usr/bin/env bash
set -euo pipefail
# track-user-input.sh — UserPromptSubmit hook
# Modes:
#   --guard-only : synchronous session↔worktree binding guard (block on mismatch)
#   (default)    : async user prompt tracking + Slack thread parent creation
#
# On first prompt in a session:
#   - Creates a Slack parent message with hostname, cwd, and prompt text
#   - Saves the message ts for threading subsequent notifications
# On every prompt:
#   - Records the timestamp of last user interaction (for heartbeat idle detection)

MODE="full"
if [[ "${1:-}" == "--guard-only" ]]; then
    MODE="guard"
fi

# shellcheck disable=SC2034
HOOK_GROUP="attention"
if [[ "$MODE" == "guard" ]]; then
    # Worktree binding guard is part of compact-recovery resilience.
    HOOK_GROUP="compact_recovery"
fi
# shellcheck source=plugins/cwf/hooks/scripts/cwf-hook-gate.sh
source "$(dirname "${BASH_SOURCE[0]}")/cwf-hook-gate.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"
RESOLVER_SCRIPT="${PLUGIN_ROOT}/scripts/cwf-artifact-paths.sh"
LIVE_RESOLVER_SCRIPT="${PLUGIN_ROOT}/scripts/cwf-live-state.sh"

if [[ -f "$RESOLVER_SCRIPT" ]]; then
    # shellcheck source=plugins/cwf/scripts/cwf-artifact-paths.sh
    source "$RESOLVER_SCRIPT"
fi
if [[ -f "$LIVE_RESOLVER_SCRIPT" ]]; then
    # shellcheck source=plugins/cwf/scripts/cwf-live-state.sh
    source "$LIVE_RESOLVER_SCRIPT"
fi

# Read hook input
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

if [ -z "$CWD" ]; then
    CWD="$PWD"
fi

emit_block_payload() {
    local message="$1"
    local encoded=""
    encoded=$(printf '%s' "$message" | jq -Rs .)
    cat <<EOF
{"decision":"block","reason":${encoded}}
EOF
}

resolve_repo_root_for_cwd() {
    local cwd="$1"
    git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$cwd"
}

resolve_live_state_file_for_cwd() {
    local cwd="$1"
    local repo_root=""
    local root_state=""
    local effective_state=""

    repo_root=$(resolve_repo_root_for_cwd "$cwd")

    if declare -F resolve_cwf_state_file >/dev/null 2>&1; then
        root_state=$(resolve_cwf_state_file "$repo_root" 2>/dev/null || true)
    else
        root_state="$repo_root/.cwf/cwf-state.yaml"
    fi
    if [[ -z "$root_state" || ! -f "$root_state" ]]; then
        return 1
    fi

    effective_state="$root_state"
    if declare -F cwf_live_resolve_file >/dev/null 2>&1; then
        effective_state=$(cwf_live_resolve_file "$repo_root" 2>/dev/null || true)
    fi
    if [[ -n "$effective_state" && -f "$effective_state" ]]; then
        printf '%s\n' "$effective_state"
        return 0
    fi

    printf '%s\n' "$root_state"
    return 0
}

extract_live_scalar() {
    local state_file="$1"
    local key="$2"
    awk -v wanted="$key" '
        /^live:/ { in_live=1; next }
        in_live && /^[^[:space:]]/ { exit }
        in_live && $0 ~ "^[[:space:]]{2}" wanted ":[[:space:]]*" {
            line=$0
            sub("^[[:space:]]{2}" wanted ":[[:space:]]*", "", line)
            gsub(/^[\"\047]|[\"\047]$/, "", line)
            print line
            exit
        }
    ' "$state_file" 2>/dev/null
}

normalize_expected_worktree() {
    local repo_root="$1"
    local expected="$2"
    if [[ -z "$expected" ]]; then
        return 1
    fi
    if [[ "$expected" == /* ]]; then
        printf '%s\n' "$expected"
    else
        printf '%s\n' "$repo_root/$expected"
    fi
}

resolve_live_session_id_for_cwd() {
    local cwd="$1"
    local state_file=""
    state_file=$(resolve_live_state_file_for_cwd "$cwd" 2>/dev/null || true)
    [[ -n "$state_file" && -f "$state_file" ]] || return 1
    extract_live_scalar "$state_file" "session_id"
}

enforce_missing_session_guard() {
    local cwd="$1"
    local emit_block="${2:-false}"
    local map_file=""
    local current_root=""
    local repo_root=""
    local state_file=""
    local expected_worktree=""
    local normalized_expected=""
    local expected_branch=""

    current_root=$(resolve_repo_root_for_cwd "$cwd")
    repo_root="$current_root"

    map_file=$(session_map_file_for_cwd "$cwd" 2>/dev/null || true)
    if [[ -n "$map_file" && -s "$map_file" ]]; then
        if [[ "$emit_block" == "true" ]]; then
            emit_block_payload "BLOCKED: missing session_id in guard mode while session-worktree bindings exist. Retry from the bound session/worktree context."
        fi
        return 1
    fi

    state_file=$(resolve_live_state_file_for_cwd "$cwd" 2>/dev/null || true)
    if [[ -n "$state_file" && -f "$state_file" ]]; then
        expected_worktree=$(extract_live_scalar "$state_file" "worktree_root")
        expected_branch=$(extract_live_scalar "$state_file" "worktree_branch")
        normalized_expected=$(normalize_expected_worktree "$repo_root" "$expected_worktree" 2>/dev/null || true)
        if [[ -n "$normalized_expected" && "$current_root" != "$normalized_expected" ]]; then
            if [[ "$emit_block" == "true" ]]; then
                if [[ -n "$expected_branch" ]]; then
                    emit_block_payload "BLOCKED: missing session_id in guard mode and current worktree ($current_root) does not match live bound worktree ($normalized_expected, branch: $expected_branch)."
                else
                    emit_block_payload "BLOCKED: missing session_id in guard mode and current worktree ($current_root) does not match live bound worktree ($normalized_expected)."
                fi
            fi
            return 1
        fi
    fi

    return 0
}

session_map_file_for_cwd() {
    local cwd="$1"
    local repo_root=""
    local common_dir=""

    repo_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)
    common_dir=$(git -C "$cwd" rev-parse --git-common-dir 2>/dev/null || true)
    if [ -z "$repo_root" ] || [ -z "$common_dir" ]; then
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
    [ -f "$map_file" ] || return 1
    awk -F '\t' -v sid="$sid" '
        $1 == sid {
            print $2 "\t" $3 "\t" $4
            found=1
            exit
        }
        END { exit(found ? 0 : 1) }
    ' "$map_file"
}

session_map_upsert() {
    local map_file="$1"
    local sid="$2"
    local worktree_root="$3"
    local branch="$4"
    local updated_at="$5"
    local tmp_file=""

    mkdir -p "$(dirname "$map_file")"
    tmp_file="$(mktemp)"

    if [ -f "$map_file" ]; then
        awk -F '\t' -v sid="$sid" -v root="$worktree_root" -v branch="$branch" -v ts="$updated_at" '
            BEGIN { OFS="\t"; updated=0 }
            $1 == sid {
                print sid, root, branch, ts
                updated=1
                next
            }
            { print }
            END {
                if (!updated) {
                    print sid, root, branch, ts
                }
            }
        ' "$map_file" > "$tmp_file"
    else
        printf '%s\t%s\t%s\t%s\n' "$sid" "$worktree_root" "$branch" "$updated_at" > "$tmp_file"
    fi

    mv "$tmp_file" "$map_file"
}

enforce_worktree_binding() {
    local sid="$1"
    local cwd="$2"
    local emit_block="${3:-false}"
    local map_file=""
    local current_root=""
    local current_branch=""
    local expected=""
    local expected_root=""
    local expected_branch=""
    local expected_ts=""
    local updated_at=""
    local reason=""
    local branch_hint=""

    map_file=$(session_map_file_for_cwd "$cwd" 2>/dev/null || true)
    [ -n "$map_file" ] || return 0

    current_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$cwd")
    current_branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null || true)

    expected=$(session_map_lookup "$map_file" "$sid" 2>/dev/null || true)
    if [ -n "$expected" ]; then
        expected_root=$(printf '%s' "$expected" | awk -F '\t' '{print $1}')
        expected_branch=$(printf '%s' "$expected" | awk -F '\t' '{print $2}')
        expected_ts=$(printf '%s' "$expected" | awk -F '\t' '{print $3}')

        if [ -n "$expected_root" ] && [ "$current_root" != "$expected_root" ]; then
            if [ -n "$expected_branch" ]; then
                branch_hint=" (branch: $expected_branch)"
            fi

            if [ "$emit_block" = "true" ]; then
                reason=$(
                    {
                        printf 'BLOCKED: session %s is bound to worktree %s%s (recorded at epoch %s), but current worktree is %s. ' \
                            "$sid" "$expected_root" "$branch_hint" "${expected_ts:-unknown}" "$current_root"
                        printf 'Switch to the bound worktree before continuing.'
                    } | jq -Rs .
                )
                cat <<EOF
{"decision":"block","reason":${reason}}
EOF
            fi
            return 1
        fi
    fi

    updated_at=$(date +%s)
    session_map_upsert "$map_file" "$sid" "$current_root" "$current_branch" "$updated_at"
    return 0
}

if [ -z "$SESSION_ID" ]; then
    SESSION_ID="$(resolve_live_session_id_for_cwd "$CWD" 2>/dev/null || true)"
fi

if [ -z "$SESSION_ID" ]; then
    if [ "$MODE" = "guard" ]; then
        enforce_missing_session_guard "$CWD" "true" || exit 0
    fi
    exit 0
fi

if [ "$MODE" = "guard" ]; then
    enforce_worktree_binding "$SESSION_ID" "$CWD" "true" || exit 0
    exit 0
fi

# Keep mapping fresh in normal mode as well, but never rebind on mismatch.
enforce_worktree_binding "$SESSION_ID" "$CWD" "false" || true

# shellcheck source=plugins/cwf/hooks/scripts/slack-send.sh
source "$SCRIPT_DIR/slack-send.sh"

# Load config
slack_load_config

HASH=$(slack_session_hash "$SESSION_ID")

# Record user interaction timestamp (used by heartbeat.sh)
date +%s > "$(slack_state_file "$HASH" "last-user-ts")"

# Cancel any running timer (user responded via new prompt instead of PostToolUse)
TIMER_FILE=$(slack_state_file "$HASH" "timer.pid")
if [ -f "$TIMER_FILE" ]; then
    kill "$(cat "$TIMER_FILE")" 2>/dev/null || true
    rm -f "$TIMER_FILE"
    rm -f "$(slack_state_file "$HASH" "input.json")"
fi

# If no thread exists yet, create parent message with first prompt
# Use mkdir as atomic lock to prevent race between concurrent async instances
LOCK_DIR="/tmp/claude-attention-${HASH}-thread-lock"
# Clean stale lock (older than 1 minute)
if [ -d "$LOCK_DIR" ]; then
    if [ -n "$(find "$LOCK_DIR" -maxdepth 0 -mmin +1 2>/dev/null)" ]; then
        rmdir "$LOCK_DIR" 2>/dev/null || true
    fi
fi
if mkdir "$LOCK_DIR" 2>/dev/null; then
    trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT INT TERM

    THREAD_TS=$(slack_get_thread_ts "$HASH")
    if [ -z "$THREAD_TS" ]; then
        HOSTNAME_STR=$(hostname)
        CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
        if [ -z "$CWD" ]; then CWD="$PWD"; fi

        # Truncate prompt for display (max 500 chars)
        DISPLAY_PROMPT="$PROMPT"
        if [ ${#DISPLAY_PROMPT} -gt 500 ]; then
            DISPLAY_PROMPT="${DISPLAY_PROMPT:0:500}..."
        fi

        PARENT_MENTION=$(slack_attention_parent_mention)
        HEADER=":large_green_circle: Claude Code @ ${HOSTNAME_STR} | ${CWD}"
        if [ -n "$PARENT_MENTION" ]; then
            HEADER="${PARENT_MENTION} ${HEADER}"
        fi

        MESSAGE="${HEADER}"$'\n'":memo: ${DISPLAY_PROMPT}"

        slack_send "$HASH" "$MESSAGE" ""
    fi

fi

exit 0
