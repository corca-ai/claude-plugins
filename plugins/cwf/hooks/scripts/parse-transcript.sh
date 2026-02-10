#!/usr/bin/env bash
# Parse Claude Code transcript and extract structured information
#
# Usage:
#   ./parse-transcript.sh <transcript_path>
#
# Output (eval-able shell variables):
#   PARSED_HUMAN_TEXT - Last user message text
#   PARSED_ASSISTANT_TEXT - Assistant response text (current turn)
#   PARSED_ASK_QUESTION - AskUserQuestion content if present
#   PARSED_TODO_STATUS - Todo status summary
#
# Example:
#   eval "$(./parse-transcript.sh /path/to/transcript.jsonl)"
#   echo "$PARSED_HUMAN_TEXT"

set -euo pipefail

# === HELPER FUNCTIONS ===

# Escape text for shell variable assignment (single quotes)
escape_for_shell() {
    local text="$1"
    # Replace single quotes with '\'' (end quote, escaped quote, start quote)
    printf '%s' "$text" | sed "s/'/'\\\\''/g"
}

# Parse last human message text
parse_human_text() {
    local transcript="$1"

    jq -rs '[.[] | select(.type == "user" and (.isMeta | not)) |
        select((.message.content | type == "string") or
               (.message.content | type == "array" and any(.[]; type == "string" or .type == "text" or .type == "image")))] |
        last |
        .message.content |
        if type == "string" then .
        elif type == "array" then
            [.[] | if .type == "image" then "[Image]"
                   elif type == "string" then .
                   elif .type == "text" then .text
                   else empty end] | join("\n")
        else "" end // ""' "$transcript" 2>/dev/null
}

# Parse assistant text from current turn (text content only)
parse_assistant_text() {
    local transcript="$1"

    jq -rs '. as $all |
        ([to_entries[] |
          select(.value.type == "user" and (.value.isMeta | not)) |
          select(.value.message.content | (type == "string") or (type == "array" and any(type == "string" or .type == "text" or .type == "image"))) |
          .key] | last // -1) as $last_user_idx |
        $all |
        [to_entries[] |
         select(.key > $last_user_idx and .value.type == "assistant") |
         .value.message.content |
         if type == "array" then [.[] | select(.type == "text") | .text] else [. // ""] end] |
        flatten |
        map(select(. != "")) |
        join("\n") |
        gsub("^[\\s\\n]+"; "") |
        gsub("[\\s\\n]+$"; "") |
        gsub("\\n{3,}"; "\n\n")' "$transcript" 2>/dev/null
}

# Parse AskUserQuestion tool calls from current turn
parse_ask_question() {
    local transcript="$1"

    # Find AskUserQuestion in the last assistant message of current turn
    local ask_json=$(jq -rs '. as $all |
        ([to_entries[] |
          select(.value.type == "user" and (.value.isMeta | not)) |
          select(.value.message.content | (type == "string") or (type == "array" and any(type == "string" or .type == "text" or .type == "image"))) |
          .key] | last // -1) as $last_user_idx |
        $all |
        [to_entries[] |
         select(.key > $last_user_idx and .value.type == "assistant") |
         .value.message.content[]? |
         select(.type == "tool_use" and .name == "AskUserQuestion") |
         .input] |
        last // null' "$transcript" 2>/dev/null)

    if [ -z "$ask_json" ] || [ "$ask_json" = "null" ]; then
        echo ""
        return
    fi

    # Format the questions for display
    echo "$ask_json" | jq -r '
        if .questions then
            .questions | to_entries | map(
                "[\(.value.header // "Question")]"
                + "\n" + .value.question
                + "\n" + (
                    .value.options | to_entries | map(
                        "  " + ((.key + 1) | tostring) + ". " + .value.label +
                        (if .value.description then " - " + .value.description else "" end)
                    ) | join("\n")
                )
            ) | join("\n\n")
        else
            ""
        end
    ' 2>/dev/null
}

# Parse todo status from transcript
parse_todos() {
    local transcript="$1"

    local todo_json=$(jq -s '
        [.[] | select(.type == "assistant") |
         .message.content[]? |
         select(.type == "tool_use" and .name == "TodoWrite") |
         .input.todos] |
        last // []
    ' "$transcript" 2>/dev/null)

    if [ -z "$todo_json" ] || [ "$todo_json" = "null" ] || [ "$todo_json" = "[]" ]; then
        echo ""
        return
    fi

    echo "$todo_json" | jq -r '
        def item_lines($status; $icon):
            [.[] | select(.status == $status) | "  " + $icon + " " + (.content // "")]
            | map(select(length > 0));

        ([.[] | select(.status == "completed")] | length) as $completed |
        ([.[] | select(.status == "in_progress")] | length) as $in_progress |
        ([.[] | select(.status == "pending")] | length) as $pending |
        ($completed + $in_progress + $pending) as $total |

        if $total == 0 then
            ""
        else
            ([":white_check_mark: Todo: " + ($completed|tostring) + "/" + ($total|tostring) + " done"]
            + item_lines("in_progress"; ":arrow_forward:")
            + item_lines("pending"; ":white_circle:")
            + item_lines("completed"; ":white_check_mark:"))
            | join("\n")
        end
    '
}

# === MAIN LOGIC ===
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    TRANSCRIPT_PATH="$1"

    if [ -z "$TRANSCRIPT_PATH" ]; then
        echo "Usage: $0 <transcript_path>" >&2
        exit 1
    fi

    if [ ! -f "$TRANSCRIPT_PATH" ]; then
        echo "Error: Transcript file not found: $TRANSCRIPT_PATH" >&2
        exit 1
    fi

    # Parse all components
    HUMAN_TEXT=$(parse_human_text "$TRANSCRIPT_PATH")
    ASSISTANT_TEXT=$(parse_assistant_text "$TRANSCRIPT_PATH")
    ASK_QUESTION=$(parse_ask_question "$TRANSCRIPT_PATH")
    TODO_STATUS=$(parse_todos "$TRANSCRIPT_PATH")

    # Output as eval-able shell variables
    echo "PARSED_HUMAN_TEXT='$(escape_for_shell "$HUMAN_TEXT")'"
    echo "PARSED_ASSISTANT_TEXT='$(escape_for_shell "$ASSISTANT_TEXT")'"
    echo "PARSED_ASK_QUESTION='$(escape_for_shell "$ASK_QUESTION")'"
    echo "PARSED_TODO_STATUS='$(escape_for_shell "$TODO_STATUS")'"
fi
