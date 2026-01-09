#!/bin/bash
# Test cases for attention.sh
# Run: ./hooks/scripts/attention.test.sh
#
# This test sources attention.sh to test the actual functions,
# ensuring tests fail when the implementation changes.

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the actual attention.sh to get the real functions
source "$SCRIPT_DIR/attention.sh"

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

# Test: 10 lines or less - should not truncate
INPUT_SHORT="line1
line2
line3
line4
line5
line6
line7
line8
line9
line10"
RESULT=$(truncate_text "$INPUT_SHORT")
assert_eq "$INPUT_SHORT" "$RESULT" "truncate_text: 10 lines unchanged"

# Test: more than 10 lines - should truncate
INPUT_LONG="line1
line2
line3
line4
line5
line6
line7
line8
line9
line10
line11
line12"
EXPECTED_LONG="line1
line2
line3
line4
line5

...(truncated)...

line8
line9
line10
line11
line12"
RESULT=$(truncate_text "$INPUT_LONG")
assert_eq "$EXPECTED_LONG" "$RESULT" "truncate_text: 12 lines truncated to 5+...+5"


# === TEST: LAST_HUMAN_TEXT extraction ===
echo ""
echo "=== Testing LAST_HUMAN_TEXT extraction ==="

# Fixtures directory (relative to script location - one level up)
FIXTURES_DIR="$SCRIPT_DIR/../fixtures"

# Helper: the jq query for human text (same as attention.sh)
JQ_HUMAN='[.[] | select(.type == "user" and .isMeta != true) |
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
  else "" end // ""'

# Test: string content (text-only message)
RESULT=$(jq -rs "$JQ_HUMAN" "$FIXTURES_DIR/human_string_content.jsonl")
assert_eq "Second message with text only" "$RESULT" "LAST_HUMAN_TEXT: string content"

# Test: array content (message with image) - should show [Image] and text
RESULT=$(jq -rs "$JQ_HUMAN" "$FIXTURES_DIR/human_array_with_image.jsonl")
EXPECTED="Message with image
[Image]"
assert_eq "$EXPECTED" "$RESULT" "LAST_HUMAN_TEXT: array content with image shows [Image]"

# Test: array with multiple text blocks
RESULT=$(jq -rs "$JQ_HUMAN" "$FIXTURES_DIR/human_multi_text.jsonl")
EXPECTED="First part
Second part"
assert_eq "$EXPECTED" "$RESULT" "LAST_HUMAN_TEXT: array with multiple text blocks"

# Test: skip tool_result-only messages (should get previous text message)
RESULT=$(jq -rs "$JQ_HUMAN" "$FIXTURES_DIR/human_skip_tool_result.jsonl")
assert_eq "Real user request" "$RESULT" "LAST_HUMAN_TEXT: skip tool_result-only messages"

# Test: skip isMeta messages (should get previous real user message)
RESULT=$(jq -rs "$JQ_HUMAN" "$FIXTURES_DIR/human_skip_ismeta.jsonl")
EXPECTED="Real request with image
[Image]"
assert_eq "$EXPECTED" "$RESULT" "LAST_HUMAN_TEXT: skip isMeta messages"


# === TEST: LAST_ASSISTANT_TEXT extraction ===
echo ""
echo "=== Testing LAST_ASSISTANT_TEXT extraction ==="

# Helper: the jq query for assistant text (current turn only, skip isMeta)
JQ_ASSISTANT='. as $all | ([to_entries[] | select(.value.type == "user" and .value.isMeta != true) | select(.value.message.content | (type == "string") or (type == "array" and any(type == "string" or .type == "text" or .type == "image"))) | .key] | last // -1) as $last_user_idx | $all | [to_entries[] | select(.key > $last_user_idx and .value.type == "assistant") | .value.message.content | if type == "array" then [.[] | select(.type == "text") | .text] else [. // ""] end] | flatten | map(select(. != "")) | join("\n\n")'

# Test: single assistant message
RESULT=$(jq -rs "$JQ_ASSISTANT" "$FIXTURES_DIR/assistant_single.jsonl")
assert_eq "Single response" "$RESULT" "LAST_ASSISTANT_TEXT: single message"

# Test: multiple assistant messages (tool calls interleaved, same turn)
RESULT=$(jq -rs "$JQ_ASSISTANT" "$FIXTURES_DIR/assistant_multi_interleaved.jsonl")
EXPECTED="First response

Second response after tool"
assert_eq "$EXPECTED" "$RESULT" "LAST_ASSISTANT_TEXT: multiple messages combined (same turn)"

# Test: only current turn responses (not previous turns)
RESULT=$(jq -rs "$JQ_ASSISTANT" "$FIXTURES_DIR/assistant_current_turn_only.jsonl")
assert_eq "Current turn response" "$RESULT" "LAST_ASSISTANT_TEXT: only current turn (not previous)"

# Test: assistant message with no text (only tool calls)
RESULT=$(jq -rs "$JQ_ASSISTANT" "$FIXTURES_DIR/assistant_tool_only.jsonl")
assert_eq "Has text" "$RESULT" "LAST_ASSISTANT_TEXT: filters out tool-only messages"


# === TEST: parse_todos ===
echo ""
echo "=== Testing parse_todos ==="

# Test: with todos
TODO_JSON=$(jq -s '[.[] | select(.type == "assistant") | .message.content[]? | select(.type == "tool_use" and .name == "TodoWrite") | .input.todos] | last // []' "$FIXTURES_DIR/todos_with_items.jsonl" 2>/dev/null)
COMPLETED=$(echo "$TODO_JSON" | jq '[.[] | select(.status == "completed")] | length')
IN_PROGRESS=$(echo "$TODO_JSON" | jq '[.[] | select(.status == "in_progress")] | length')
PENDING=$(echo "$TODO_JSON" | jq '[.[] | select(.status == "pending")] | length')

assert_eq "1" "$COMPLETED" "parse_todos: completed count"
assert_eq "1" "$IN_PROGRESS" "parse_todos: in_progress count"
assert_eq "1" "$PENDING" "parse_todos: pending count"

# Test: no todos
TODO_JSON=$(jq -s '[.[] | select(.type == "assistant") | .message.content[]? | select(.type == "tool_use" and .name == "TodoWrite") | .input.todos] | last // []' "$FIXTURES_DIR/todos_empty.jsonl" 2>/dev/null)
assert_eq "[]" "$TODO_JSON" "parse_todos: empty when no TodoWrite"


# === TEST: escape_json ===
echo ""
echo "=== Testing escape_json ==="

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
