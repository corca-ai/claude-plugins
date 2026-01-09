#!/bin/bash
# Test cases for attention.sh
# Run: ./hooks/test_attention.sh

set -e

PASSED=0
FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

assert_eq() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    if [ "$expected" = "$actual" ]; then
        echo -e "${GREEN}PASS${NC}: $test_name"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}FAIL${NC}: $test_name"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        FAILED=$((FAILED + 1))
    fi
}

# === TEST: truncate_text ===
echo ""
echo "=== Testing truncate_text ==="

truncate_text() {
    local text="$1"
    local line_count=$(echo "$text" | wc -l)

    if [ "$line_count" -le 6 ]; then
        echo "$text"
    else
        local first=$(echo "$text" | head -n 3)
        local last=$(echo "$text" | tail -n 3)
        echo "$first"
        echo "..."
        echo "$last"
    fi
}

# Test: 6 lines or less - should not truncate
INPUT_SHORT="line1
line2
line3
line4
line5
line6"
RESULT=$(truncate_text "$INPUT_SHORT")
assert_eq "$INPUT_SHORT" "$RESULT" "truncate_text: 6 lines unchanged"

# Test: more than 6 lines - should truncate
INPUT_LONG="line1
line2
line3
line4
line5
line6
line7
line8
line9
line10"
EXPECTED_LONG="line1
line2
line3
...
line8
line9
line10"
RESULT=$(truncate_text "$INPUT_LONG")
assert_eq "$EXPECTED_LONG" "$RESULT" "truncate_text: 10 lines truncated to 3+...+3"


# === TEST: LAST_HUMAN_TEXT extraction ===
echo ""
echo "=== Testing LAST_HUMAN_TEXT extraction ==="

# Create temp transcript file
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Test: string content (text-only message)
cat > "$TEMP_DIR/transcript_string.jsonl" << 'EOF'
{"type":"user","message":{"content":"First message"}}
{"type":"assistant","message":{"content":[{"type":"text","text":"Response"}]}}
{"type":"user","message":{"content":"Second message with text only"}}
EOF

RESULT=$(jq -rs '[.[] | select(.type == "user")] | last | .message.content | if type == "string" then . elif type == "array" then [.[] | select(type == "string" or .type == "text") | if type == "string" then . else .text end] | join("\n") else "" end // ""' "$TEMP_DIR/transcript_string.jsonl")
assert_eq "Second message with text only" "$RESULT" "LAST_HUMAN_TEXT: string content"

# Test: array content (message with image)
cat > "$TEMP_DIR/transcript_array.jsonl" << 'EOF'
{"type":"user","message":{"content":"Old text message"}}
{"type":"assistant","message":{"content":[{"type":"text","text":"Response"}]}}
{"type":"user","message":{"content":[{"type":"image","source":{"type":"base64"}},{"type":"text","text":"Message with image"}]}}
EOF

RESULT=$(jq -rs '[.[] | select(.type == "user")] | last | .message.content | if type == "string" then . elif type == "array" then [.[] | select(type == "string" or .type == "text") | if type == "string" then . else .text end] | join("\n") else "" end // ""' "$TEMP_DIR/transcript_array.jsonl")
assert_eq "Message with image" "$RESULT" "LAST_HUMAN_TEXT: array content with image"

# Test: array with multiple text blocks
cat > "$TEMP_DIR/transcript_multi_text.jsonl" << 'EOF'
{"type":"user","message":{"content":[{"type":"text","text":"First part"},{"type":"text","text":"Second part"}]}}
EOF

RESULT=$(jq -rs '[.[] | select(.type == "user")] | last | .message.content | if type == "string" then . elif type == "array" then [.[] | select(type == "string" or .type == "text") | if type == "string" then . else .text end] | join("\n") else "" end // ""' "$TEMP_DIR/transcript_multi_text.jsonl")
EXPECTED="First part
Second part"
assert_eq "$EXPECTED" "$RESULT" "LAST_HUMAN_TEXT: array with multiple text blocks"


# === TEST: LAST_ASSISTANT_TEXT extraction ===
echo ""
echo "=== Testing LAST_ASSISTANT_TEXT extraction ==="

# Test: single assistant message
cat > "$TEMP_DIR/transcript_single_assistant.jsonl" << 'EOF'
{"type":"user","message":{"content":"Request"}}
{"type":"assistant","message":{"content":[{"type":"text","text":"Single response"}]}}
EOF

RESULT=$(jq -rs '[.[] | select(.type == "assistant") | .message.content | if type == "array" then [.[] | select(.type == "text") | .text] else [. // ""] end] | flatten | map(select(. != "")) | join("\n\n")' "$TEMP_DIR/transcript_single_assistant.jsonl")
assert_eq "Single response" "$RESULT" "LAST_ASSISTANT_TEXT: single message"

# Test: multiple assistant messages (tool calls interleaved)
cat > "$TEMP_DIR/transcript_multi_assistant.jsonl" << 'EOF'
{"type":"user","message":{"content":"Request"}}
{"type":"assistant","message":{"content":[{"type":"text","text":"First response"},{"type":"tool_use","name":"Bash"}]}}
{"type":"user","message":{"content":[{"type":"tool_result","content":"tool output"}]}}
{"type":"assistant","message":{"content":[{"type":"text","text":"Second response after tool"}]}}
EOF

RESULT=$(jq -rs '[.[] | select(.type == "assistant") | .message.content | if type == "array" then [.[] | select(.type == "text") | .text] else [. // ""] end] | flatten | map(select(. != "")) | join("\n\n")' "$TEMP_DIR/transcript_multi_assistant.jsonl")
EXPECTED="First response

Second response after tool"
assert_eq "$EXPECTED" "$RESULT" "LAST_ASSISTANT_TEXT: multiple messages combined"

# Test: assistant message with no text (only tool calls)
cat > "$TEMP_DIR/transcript_no_text.jsonl" << 'EOF'
{"type":"user","message":{"content":"Request"}}
{"type":"assistant","message":{"content":[{"type":"text","text":"Has text"}]}}
{"type":"user","message":{"content":[{"type":"tool_result","content":"result"}]}}
{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash"}]}}
EOF

RESULT=$(jq -rs '[.[] | select(.type == "assistant") | .message.content | if type == "array" then [.[] | select(.type == "text") | .text] else [. // ""] end] | flatten | map(select(. != "")) | join("\n\n")' "$TEMP_DIR/transcript_no_text.jsonl")
assert_eq "Has text" "$RESULT" "LAST_ASSISTANT_TEXT: filters out tool-only messages"


# === TEST: parse_todos ===
echo ""
echo "=== Testing parse_todos ==="

# Test: with todos
cat > "$TEMP_DIR/transcript_todos.jsonl" << 'EOF'
{"type":"assistant","message":{"content":[{"type":"tool_use","name":"TodoWrite","input":{"todos":[{"content":"Task 1","status":"completed"},{"content":"Task 2","status":"in_progress"},{"content":"Task 3","status":"pending"}]}}]}}
EOF

TODO_JSON=$(jq -s '[.[] | select(.type == "assistant") | .message.content[]? | select(.type == "tool_use" and .name == "TodoWrite") | .input.todos] | last // []' "$TEMP_DIR/transcript_todos.jsonl" 2>/dev/null)
COMPLETED=$(echo "$TODO_JSON" | jq '[.[] | select(.status == "completed")] | length')
IN_PROGRESS=$(echo "$TODO_JSON" | jq '[.[] | select(.status == "in_progress")] | length')
PENDING=$(echo "$TODO_JSON" | jq '[.[] | select(.status == "pending")] | length')

assert_eq "1" "$COMPLETED" "parse_todos: completed count"
assert_eq "1" "$IN_PROGRESS" "parse_todos: in_progress count"
assert_eq "1" "$PENDING" "parse_todos: pending count"

# Test: no todos
cat > "$TEMP_DIR/transcript_no_todos.jsonl" << 'EOF'
{"type":"assistant","message":{"content":[{"type":"text","text":"No todos here"}]}}
EOF

TODO_JSON=$(jq -s '[.[] | select(.type == "assistant") | .message.content[]? | select(.type == "tool_use" and .name == "TodoWrite") | .input.todos] | last // []' "$TEMP_DIR/transcript_no_todos.jsonl" 2>/dev/null)
assert_eq "[]" "$TODO_JSON" "parse_todos: empty when no TodoWrite"


# === TEST: escape_json ===
echo ""
echo "=== Testing escape_json ==="

escape_json() {
    local text="$1"
    text="${text//\\/\\\\}"
    text="${text//\"/\\\"}"
    text="${text//$'\n'/\\n}"
    text="${text//$'\t'/\\t}"
    echo "$text"
}

# Test: newlines
RESULT=$(escape_json "line1
line2")
assert_eq 'line1\nline2' "$RESULT" "escape_json: newlines"

# Test: quotes
RESULT=$(escape_json 'say "hello"')
assert_eq 'say \"hello\"' "$RESULT" "escape_json: quotes"

# Test: tabs
RESULT=$(escape_json $'col1\tcol2')
assert_eq 'col1\tcol2' "$RESULT" "escape_json: tabs"

# Test: backslashes
RESULT=$(escape_json 'path\to\file')
assert_eq 'path\\to\\file' "$RESULT" "escape_json: backslashes"


# === SUMMARY ===
echo ""
echo "================================"
echo -e "Results: ${GREEN}$PASSED passed${NC}, ${RED}$FAILED failed${NC}"
echo "================================"

if [ "$FAILED" -gt 0 ]; then
    exit 1
fi
