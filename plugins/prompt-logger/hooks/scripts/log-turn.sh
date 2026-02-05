#!/usr/bin/env bash
set -euo pipefail

# prompt-logger: Log conversation turns to markdown files
# Called by Stop and SessionEnd hooks (async)
# Idempotent — safe to call multiple times per turn
# SessionEnd passes "session_end" arg to trigger auto-commit

HOOK_TYPE="${1:-stop}"

# ── Read hook input ──────────────────────────────────────────────────────────
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

if [ -z "$SESSION_ID" ] || [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
    exit 0
fi

# ── Wait for transcript flush (async hook may race with file writes) ─────────
sleep 0.3

# ── Load config ──────────────────────────────────────────────────────────────
# 1. Shell env (already set)
# 2. ~/.claude/.env
[ -f "$HOME/.claude/.env" ] && { set -a; source "$HOME/.claude/.env"; set +a; }
# 3. Shell profiles (fallback)
[ -z "${CLAUDE_CORCA_PROMPT_LOGGER_DIR:-}" ] && \
    eval "$(grep -sh '^export CLAUDE_CORCA_PROMPT_LOGGER_DIR=' ~/.zshrc ~/.bashrc 2>/dev/null)" || true
[ -z "${CLAUDE_CORCA_PROMPT_LOGGER_ENABLED:-}" ] && \
    eval "$(grep -sh '^export CLAUDE_CORCA_PROMPT_LOGGER_ENABLED=' ~/.zshrc ~/.bashrc 2>/dev/null)" || true
[ -z "${CLAUDE_CORCA_PROMPT_LOGGER_TRUNCATE:-}" ] && \
    eval "$(grep -sh '^export CLAUDE_CORCA_PROMPT_LOGGER_TRUNCATE=' ~/.zshrc ~/.bashrc 2>/dev/null)" || true
[ -z "${CLAUDE_CORCA_PROMPT_LOGGER_AUTO_COMMIT:-}" ] && \
    eval "$(grep -sh '^export CLAUDE_CORCA_PROMPT_LOGGER_AUTO_COMMIT=' ~/.zshrc ~/.bashrc 2>/dev/null)" || true

ENABLED="${CLAUDE_CORCA_PROMPT_LOGGER_ENABLED:-true}"
if [ "$ENABLED" != "true" ]; then
    exit 0
fi

LOG_DIR="${CLAUDE_CORCA_PROMPT_LOGGER_DIR:-${CWD}/prompt-logs/sessions}"
TRUNCATE_THRESHOLD="${CLAUDE_CORCA_PROMPT_LOGGER_TRUNCATE:-10}"
AUTO_COMMIT="${CLAUDE_CORCA_PROMPT_LOGGER_AUTO_COMMIT:-true}"

# ── Timezone helpers (transcript timestamps are UTC) ─────────────────────────
LOCAL_TZ=$(date +%Z)

utc_to_epoch() {
    local ts_short
    ts_short=$(echo "$1" | cut -c1-19)
    TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "$ts_short" "+%s" 2>/dev/null || \
    date -d "${ts_short}Z" "+%s" 2>/dev/null || \
    echo ""
}

utc_to_local() {
    local fmt="${2:-%H:%M:%S}"
    local epoch
    epoch=$(utc_to_epoch "$1")
    if [ -n "$epoch" ]; then
        date -r "$epoch" "+$fmt" 2>/dev/null || \
        date -d "@$epoch" "+$fmt" 2>/dev/null || \
        echo ""
    fi
}

# ── Session hash & state ─────────────────────────────────────────────────────
HASH=$(echo -n "$SESSION_ID" | shasum -a 256 | cut -c1-8)
STATE_DIR="/tmp/claude-prompt-logger-${HASH}"
mkdir -p "$STATE_DIR"

# ── Atomic lock (prevent race between Stop and SessionEnd) ────────────────────
LOCK_DIR="${STATE_DIR}/lock"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    # Another instance is running — exit silently
    exit 0
fi
TEMP_ENTRIES=$(mktemp)
trap 'rm -f "$TEMP_ENTRIES"; rmdir "$LOCK_DIR" 2>/dev/null' EXIT

# ── Incremental offset ───────────────────────────────────────────────────────
OFFSET_FILE="${STATE_DIR}/offset"
LAST_OFFSET=0
if [ -f "$OFFSET_FILE" ]; then
    LAST_OFFSET=$(cat "$OFFSET_FILE")
fi

TOTAL_LINES=$(wc -l < "$TRANSCRIPT_PATH" | tr -d ' ')

if [ "$TOTAL_LINES" -lt "$LAST_OFFSET" ]; then
    # Transcript was truncated (e.g., user rewound with Esc+Esc)
    # Re-read everything; we'll skip already-logged turns and only log new ones
    REWOUND=true
    LAST_OFFSET=0
elif [ "$TOTAL_LINES" -eq "$LAST_OFFSET" ]; then
    # No new lines — but SessionEnd still needs to auto-commit the existing log
    if [ "$HOOK_TYPE" = "session_end" ] && [ "$AUTO_COMMIT" = "true" ]; then
        DATE_STR=$(date +%y%m%d)
        OUT_FILE="${LOG_DIR}/${DATE_STR}-${HASH}.md"
        if [ -f "$OUT_FILE" ] && git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            if git -C "$CWD" diff --cached --quiet 2>/dev/null; then
                git -C "$CWD" add -- "$OUT_FILE" 2>/dev/null && \
                git -C "$CWD" commit --no-verify -m "prompt-log: $(basename "$OUT_FILE" .md)" 2>/dev/null || true
            fi
        fi
    fi
    exit 0
fi

# ── Read new JSONL entries (use temp file to avoid bash null-byte stripping) ──
tail -n +"$((LAST_OFFSET + 1))" "$TRANSCRIPT_PATH" > "$TEMP_ENTRIES"

# ── Parse turns with jq ──────────────────────────────────────────────────────
# Group entries into turns: user message → assistant messages until next user
TURNS_JSON=$(jq -s '
  # Filter to user/assistant entries only (skip snapshots, etc.)
  [ .[] | select(.type == "user" or .type == "assistant") ] |

  # Group into turns
  reduce .[] as $e (
    {turns: [], cur: null};
    if $e.type == "user" and ($e.isMeta | not) and
       ($e.message.content |
         (type == "string" and length > 0) or
         (type == "array" and any(
           type == "string" or .type == "text" or .type == "image"
         ))
       )
    then
      # New user turn — flush previous
      {
        turns: (if .cur then .turns + [.cur] else .turns end),
        cur: {user: $e, assistants: []}
      }
    elif $e.type == "assistant" and .cur then
      # Add assistant entry to current turn
      .cur.assistants += [$e] | .
    else . end
  ) |
  # Flush final turn
  if .cur then .turns + [.cur] else .turns end
' < "$TEMP_ENTRIES" 2>/dev/null || echo '[]')

TURN_COUNT=$(echo "$TURNS_JSON" | jq 'length')
if [ "$TURN_COUNT" -eq 0 ]; then
    # Update offset even if no turns (skip meta/snapshot entries)
    echo "$TOTAL_LINES" > "$OFFSET_FILE"
    exit 0
fi

# ── Determine turn numbering ─────────────────────────────────────────────────
TURN_NUM_FILE="${STATE_DIR}/turn_num"
TURN_START=1
if [ -f "$TURN_NUM_FILE" ]; then
    TURN_START=$(cat "$TURN_NUM_FILE")
fi

# ── Ensure output directory exists ────────────────────────────────────────────
mkdir -p "$LOG_DIR"

# ── Determine output file ────────────────────────────────────────────────────
DATE_STR=$(date +%y%m%d)
OUT_FILE="${LOG_DIR}/${DATE_STR}-${HASH}.md"

# ── Write session header if first write ───────────────────────────────────────
if [ ! -f "$OUT_FILE" ]; then
    # Extract metadata from first assistant entry
    MODEL=$(jq -rs '[.[] | select(.type == "assistant") | .message.model // empty] | first // empty' < "$TEMP_ENTRIES")
    [ -z "$MODEL" ] && MODEL="unknown"

    BRANCH=$(jq -rs '[.[] | select(.gitBranch) | .gitBranch // empty] | first // empty' < "$TEMP_ENTRIES")
    [ -z "$BRANCH" ] && BRANCH="unknown"

    VERSION=$(jq -rs '[.[] | select(.version) | .version // empty] | first // empty' < "$TEMP_ENTRIES")
    [ -z "$VERSION" ] && VERSION="unknown"

    FIRST_TS=$(jq -rs '[.[] | select(.timestamp) | .timestamp // empty] | first // empty' < "$TEMP_ENTRIES")
    if [ -n "$FIRST_TS" ]; then
        STARTED=$(utc_to_local "$FIRST_TS" "%Y-%m-%d %H:%M:%S")
        [ -z "$STARTED" ] && STARTED="$FIRST_TS"
    else
        STARTED=$(date "+%Y-%m-%d %H:%M:%S")
    fi

    cat > "$OUT_FILE" <<EOF
# Session: ${HASH}
Model: ${MODEL} | Branch: ${BRANCH}
CWD: ${CWD}
Started: ${STARTED} ${LOCAL_TZ} | Claude Code v${VERSION}
EOF
fi

# ── Handle rewind: mark and skip already-logged turns ────────────────────────
FIRST_TURN_IDX=0
if [ "${REWOUND:-}" = "true" ]; then
    if [ -f "$OUT_FILE" ]; then
        REWIND_TS=$(date "+%H:%M:%S")
        {
            echo ""
            echo "---"
            echo "## ⟲ Rewind [${REWIND_TS}] (after Turn $((TURN_START - 1)))"
        } >> "$OUT_FILE"
    fi
    # Skip already-logged turns; at minimum, log the last turn (the new one)
    ALREADY_LOGGED=$((TURN_START - 1))
    if [ "$ALREADY_LOGGED" -ge "$TURN_COUNT" ]; then
        FIRST_TURN_IDX=$((TURN_COUNT - 1))
    else
        FIRST_TURN_IDX="$ALREADY_LOGGED"
    fi
    # Keep TURN_START unchanged — new turns continue the sequence
fi

# ── Format and append each turn ───────────────────────────────────────────────
TURN_IDX=$FIRST_TURN_IDX
while [ "$TURN_IDX" -lt "$TURN_COUNT" ]; do
    TURN=$(echo "$TURNS_JSON" | jq ".[$TURN_IDX]")
    CURRENT_TURN_NUM=$((TURN_START + TURN_IDX - FIRST_TURN_IDX))

    # ── Timestamps ────────────────────────────────────────────────────────
    USER_TS=$(echo "$TURN" | jq -r '.user.timestamp // empty')
    LAST_ASSISTANT_TS=$(echo "$TURN" | jq -r '.assistants[-1].timestamp // empty')

    USER_TIME=$(utc_to_local "$USER_TS")
    ASSISTANT_TIME=$(utc_to_local "$LAST_ASSISTANT_TS")

    # Duration
    DURATION_STR=""
    if [ -n "$USER_TS" ] && [ -n "$LAST_ASSISTANT_TS" ]; then
        USER_EPOCH=$(utc_to_epoch "$USER_TS")
        ASSISTANT_EPOCH=$(utc_to_epoch "$LAST_ASSISTANT_TS")
        if [ -n "$USER_EPOCH" ] && [ -n "$ASSISTANT_EPOCH" ]; then
            DURATION=$((ASSISTANT_EPOCH - USER_EPOCH))
            if [ "$DURATION" -ge 0 ]; then
                DURATION_STR=" (${DURATION}s)"
            fi
        fi
    fi

    # ── Token usage ───────────────────────────────────────────────────────
    TOKEN_STR=""
    INPUT_TOKENS=$(echo "$TURN" | jq '[.assistants[].message.usage.input_tokens // 0] | add')
    OUTPUT_TOKENS=$(echo "$TURN" | jq '[.assistants[].message.usage.output_tokens // 0] | add')
    if [ "$INPUT_TOKENS" != "null" ] && [ "$INPUT_TOKENS" != "0" ]; then
        TOKEN_STR=" | Tokens: ${INPUT_TOKENS}↑ ${OUTPUT_TOKENS}↓"
    fi

    # ── Turn header ───────────────────────────────────────────────────────
    TIME_RANGE=""
    if [ -n "$USER_TIME" ] && [ -n "$ASSISTANT_TIME" ]; then
        TIME_RANGE=" [${USER_TIME} → ${ASSISTANT_TIME}]"
    elif [ -n "$USER_TIME" ]; then
        TIME_RANGE=" [${USER_TIME}]"
    fi

    {
        echo ""
        echo "---"
        echo "## Turn ${CURRENT_TURN_NUM}${TIME_RANGE}${DURATION_STR}${TOKEN_STR}"
    } >> "$OUT_FILE"

    # ── User content ──────────────────────────────────────────────────────
    USER_CONTENT=$(echo "$TURN" | jq -r '
      .user.message.content |
      if type == "string" then .
      elif type == "array" then
        [ .[] |
          if type == "string" then .
          elif .type == "text" then .text
          elif .type == "image" then "[Image]"
          else empty end
        ] | join("\n")
      else "" end
    ')

    {
        echo ""
        echo "### User"
        echo "$USER_CONTENT"
    } >> "$OUT_FILE"

    # ── Assistant content ─────────────────────────────────────────────────
    ASSISTANT_TEXT=$(echo "$TURN" | jq -r '
      [.assistants[].message.content[] |
        select(.type == "text") | .text
      ] | join("\n")
      # Strip leading/trailing blank lines
      | gsub("^[\\s\\n]+"; "") | gsub("[\\s\\n]+$"; "")
    ')

    if [ -n "$ASSISTANT_TEXT" ]; then
        LINE_COUNT=$(echo "$ASSISTANT_TEXT" | wc -l | tr -d ' ')

        {
            echo ""
            echo "### Assistant${LINE_COUNT:+ (${LINE_COUNT} lines$([ "$LINE_COUNT" -gt "$TRUNCATE_THRESHOLD" ] && echo " → truncated"))}"
        } >> "$OUT_FILE"

        if [ "$LINE_COUNT" -gt "$TRUNCATE_THRESHOLD" ]; then
            HALF=$((TRUNCATE_THRESHOLD / 2))
            OMITTED=$((LINE_COUNT - TRUNCATE_THRESHOLD))
            {
                echo "$ASSISTANT_TEXT" | head -n "$HALF"
                echo ""
                echo "...(${OMITTED} lines truncated)..."
                echo ""
                echo "$ASSISTANT_TEXT" | tail -n "$HALF"
            } >> "$OUT_FILE"
        else
            echo "$ASSISTANT_TEXT" >> "$OUT_FILE"
        fi
    fi

    # ── Tool calls ────────────────────────────────────────────────────────
    TOOLS_JSON=$(echo "$TURN" | jq -c '
      [.assistants[].message.content[] |
        select(.type == "tool_use") |
        {name, input}
      ]
    ')

    TOOL_COUNT=$(echo "$TOOLS_JSON" | jq 'length')
    if [ "$TOOL_COUNT" -gt 0 ]; then
        echo "" >> "$OUT_FILE"
        echo "### Tools" >> "$OUT_FILE"

        TOOL_IDX=0
        while [ "$TOOL_IDX" -lt "$TOOL_COUNT" ]; do
            TOOL=$(echo "$TOOLS_JSON" | jq ".[$TOOL_IDX]")
            TOOL_NAME=$(echo "$TOOL" | jq -r '.name')

            TOOL_SUMMARY=$(echo "$TOOL" | jq -r --arg name "$TOOL_NAME" '
              if $name == "Read" then
                "Read `\(.input.file_path // "?")`"
              elif $name == "Bash" then
                "Bash `\(.input.command // "?" | .[0:80])`"
              elif $name == "Edit" then
                "Edit `\(.input.file_path // "?")`"
              elif $name == "Write" then
                "Write `\(.input.file_path // "?")`"
              elif $name == "Task" then
                "Task[\(.input.subagent_type // "?")] \"\(.input.description // "?")\""
              elif $name == "Grep" then
                "Grep `\(.input.pattern // "?")` \(.input.path // "")"
              elif $name == "Glob" then
                "Glob `\(.input.pattern // "?")`"
              elif $name == "Skill" then
                "Skill `\(.input.skill // "?")`"
              elif $name == "AskUserQuestion" then
                "AskUserQuestion \"\(.input.questions[0].question // .input.questions[0].header // "?" | .[0:60])\""
              elif $name == "EnterPlanMode" then
                "EnterPlanMode"
              elif $name == "ExitPlanMode" then
                "ExitPlanMode"
              elif $name == "WebFetch" then
                "WebFetch `\(.input.url // "?" | .[0:60])`"
              elif $name == "WebSearch" then
                "WebSearch `\(.input.query // "?" | .[0:60])`"
              elif $name == "TaskCreate" then
                "TaskCreate \"\(.input.subject // "?")\""
              elif $name == "TaskUpdate" then
                "TaskUpdate #\(.input.taskId // "?") → \(.input.status // "?")"
              elif $name == "NotebookEdit" then
                "NotebookEdit `\(.input.notebook_path // "?")`"
              else
                $name
              end
            ')

            TOOL_NUM=$((TOOL_IDX + 1))
            echo "${TOOL_NUM}. ${TOOL_SUMMARY}" >> "$OUT_FILE"
            TOOL_IDX=$((TOOL_IDX + 1))
        done
    fi

    TURN_IDX=$((TURN_IDX + 1))
done

# ── Update state ──────────────────────────────────────────────────────────────
echo "$TOTAL_LINES" > "$OFFSET_FILE"
echo "$((TURN_START + TURN_COUNT - FIRST_TURN_IDX))" > "$TURN_NUM_FILE"

# ── Auto-commit session log on SessionEnd ────────────────────────────────────
if [ "$HOOK_TYPE" = "session_end" ] && [ "$AUTO_COMMIT" = "true" ] && [ -f "$OUT_FILE" ]; then
    if git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        # Only proceed if no pre-existing staged changes (don't interfere)
        if git -C "$CWD" diff --cached --quiet 2>/dev/null; then
            git -C "$CWD" add -- "$OUT_FILE" 2>/dev/null && \
            git -C "$CWD" commit --no-verify -m "prompt-log: $(basename "$OUT_FILE" .md)" 2>/dev/null || true
        fi
    fi
fi

exit 0
