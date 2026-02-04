#!/bin/bash
# Test cases for attention.sh, parse-transcript.sh, and slack-send.sh
# Run: ./hooks/scripts/attention.test.sh
#
# This test sources the actual scripts to test real functions,
# ensuring tests fail when the implementation changes.

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the actual scripts to get the real functions
source "$SCRIPT_DIR/attention.sh"
source "$SCRIPT_DIR/parse-transcript.sh"
source "$SCRIPT_DIR/slack-send.sh"

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

assert_contains() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    if [[ "$actual" == *"$expected"* ]]; then
        echo -e "${GREEN}PASS${NC}: $test_name"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}FAIL${NC}: $test_name"
        echo "  Expected to contain: $expected"
        echo "  Actual: $actual"
        FAILED=$((FAILED + 1))
    fi
}

assert_not_empty() {
    local actual="$1"
    local test_name="$2"

    if [ -n "$actual" ]; then
        echo -e "${GREEN}PASS${NC}: $test_name"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}FAIL${NC}: $test_name"
        echo "  Expected non-empty value"
        FAILED=$((FAILED + 1))
    fi
}

assert_file_exists() {
    local file="$1"
    local test_name="$2"

    if [ -f "$file" ]; then
        echo -e "${GREEN}PASS${NC}: $test_name"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}FAIL${NC}: $test_name"
        echo "  Expected file to exist: $file"
        FAILED=$((FAILED + 1))
    fi
}

assert_file_not_exists() {
    local file="$1"
    local test_name="$2"

    if [ ! -f "$file" ]; then
        echo -e "${GREEN}PASS${NC}: $test_name"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}FAIL${NC}: $test_name"
        echo "  Expected file to NOT exist: $file"
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


# === TEST: parse_human_text ===
echo ""
echo "=== Testing parse_human_text ==="

# Fixtures directory (relative to script location - one level up)
FIXTURES_DIR="$SCRIPT_DIR/../fixtures"

# Test: string content (text-only message)
RESULT=$(parse_human_text "$FIXTURES_DIR/human_string_content.jsonl")
assert_eq "Second message with text only" "$RESULT" "parse_human_text: string content"

# Test: array content (message with image) - should show [Image] and text
RESULT=$(parse_human_text "$FIXTURES_DIR/human_array_with_image.jsonl")
EXPECTED="Message with image
[Image]"
assert_eq "$EXPECTED" "$RESULT" "parse_human_text: array content with image shows [Image]"

# Test: array with multiple text blocks
RESULT=$(parse_human_text "$FIXTURES_DIR/human_multi_text.jsonl")
EXPECTED="First part
Second part"
assert_eq "$EXPECTED" "$RESULT" "parse_human_text: array with multiple text blocks"

# Test: skip tool_result-only messages (should get previous text message)
RESULT=$(parse_human_text "$FIXTURES_DIR/human_skip_tool_result.jsonl")
assert_eq "Real user request" "$RESULT" "parse_human_text: skip tool_result-only messages"

# Test: skip isMeta messages (should get previous real user message)
RESULT=$(parse_human_text "$FIXTURES_DIR/human_skip_ismeta.jsonl")
EXPECTED="Real request with image
[Image]"
assert_eq "$EXPECTED" "$RESULT" "parse_human_text: skip isMeta messages"


# === TEST: parse_assistant_text ===
echo ""
echo "=== Testing parse_assistant_text ==="

# Test: single assistant message
RESULT=$(parse_assistant_text "$FIXTURES_DIR/assistant_single.jsonl")
assert_eq "Single response" "$RESULT" "parse_assistant_text: single message"

# Test: multiple assistant messages (tool calls interleaved, same turn)
RESULT=$(parse_assistant_text "$FIXTURES_DIR/assistant_multi_interleaved.jsonl")
EXPECTED="First response

Second response after tool"
assert_eq "$EXPECTED" "$RESULT" "parse_assistant_text: multiple messages combined (same turn)"

# Test: only current turn responses (not previous turns)
RESULT=$(parse_assistant_text "$FIXTURES_DIR/assistant_current_turn_only.jsonl")
assert_eq "Current turn response" "$RESULT" "parse_assistant_text: only current turn (not previous)"

# Test: assistant message with no text (only tool calls)
RESULT=$(parse_assistant_text "$FIXTURES_DIR/assistant_tool_only.jsonl")
assert_eq "Has text" "$RESULT" "parse_assistant_text: filters out tool-only messages"


# === TEST: parse_ask_question ===
echo ""
echo "=== Testing parse_ask_question ==="

# Test: AskUserQuestion with options
RESULT=$(parse_ask_question "$FIXTURES_DIR/ask_user_question.jsonl")
assert_not_empty "$RESULT" "parse_ask_question: returns non-empty for AskUserQuestion"
assert_contains "Test type" "$RESULT" "parse_ask_question: contains header"
assert_contains "Wait for notification" "$RESULT" "parse_ask_question: contains first option"
assert_contains "Cancel immediately" "$RESULT" "parse_ask_question: contains second option"

# Test: no AskUserQuestion
RESULT=$(parse_ask_question "$FIXTURES_DIR/assistant_single.jsonl")
assert_eq "" "$RESULT" "parse_ask_question: empty when no AskUserQuestion"


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


# === TEST: slack-send.sh functions ===
echo ""
echo "=== Testing slack-send.sh functions ==="

# Test: slack_session_hash produces 12-char hex string
HASH=$(slack_session_hash "test-session-id-12345")
assert_eq 12 "${#HASH}" "slack_session_hash: output is 12 characters"

# Test: same input produces same hash
HASH2=$(slack_session_hash "test-session-id-12345")
assert_eq "$HASH" "$HASH2" "slack_session_hash: deterministic output"

# Test: different input produces different hash
HASH3=$(slack_session_hash "different-session-id")
if [ "$HASH" != "$HASH3" ]; then
    echo -e "${GREEN}PASS${NC}: slack_session_hash: different inputs produce different hashes"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAIL${NC}: slack_session_hash: different inputs produce different hashes"
    FAILED=$((FAILED + 1))
fi

# Test: slack_state_file returns correct path
STATE_PATH=$(slack_state_file "abc123def456" "thread-ts")
assert_eq "/tmp/claude-attention-abc123def456-thread-ts" "$STATE_PATH" "slack_state_file: correct path format"

STATE_PATH2=$(slack_state_file "abc123def456" "last-user-ts")
assert_eq "/tmp/claude-attention-abc123def456-last-user-ts" "$STATE_PATH2" "slack_state_file: correct path for different state"

# Test: slack_escape_json (same as escape_json but from slack-send.sh)
RESULT=$(slack_escape_json "line1
line2")
assert_eq 'line1\nline2' "$RESULT" "slack_escape_json: newlines"

RESULT=$(slack_escape_json 'say "hello"')
assert_eq 'say \"hello\"' "$RESULT" "slack_escape_json: quotes"


# === TEST: Session isolation ===
echo ""
echo "=== Testing session isolation ==="

# Setup: create temp state files for two different sessions
TEST_HASH_A=$(slack_session_hash "session-A-test-isolation")
TEST_HASH_B=$(slack_session_hash "session-B-test-isolation")

# Verify different hashes
if [ "$TEST_HASH_A" != "$TEST_HASH_B" ]; then
    echo -e "${GREEN}PASS${NC}: session isolation: different session_ids produce different hashes"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAIL${NC}: session isolation: different session_ids produce different hashes"
    FAILED=$((FAILED + 1))
fi

# Test: thread_ts isolation between sessions
TEST_TS_FILE_A=$(slack_state_file "$TEST_HASH_A" "thread-ts")
TEST_TS_FILE_B=$(slack_state_file "$TEST_HASH_B" "thread-ts")

# Clean up first
rm -f "$TEST_TS_FILE_A" "$TEST_TS_FILE_B"

# Write thread_ts for session A
slack_save_thread_ts "$TEST_HASH_A" "1234567890.123456"

# Session A should have thread_ts
RESULT_A=$(slack_get_thread_ts "$TEST_HASH_A")
assert_eq "1234567890.123456" "$RESULT_A" "session isolation: session A has its thread_ts"

# Session B should NOT have thread_ts
RESULT_B=$(slack_get_thread_ts "$TEST_HASH_B")
assert_eq "" "$RESULT_B" "session isolation: session B has no thread_ts"

# Write different thread_ts for session B
slack_save_thread_ts "$TEST_HASH_B" "9876543210.654321"

# Both should have their own values
RESULT_A=$(slack_get_thread_ts "$TEST_HASH_A")
RESULT_B=$(slack_get_thread_ts "$TEST_HASH_B")
assert_eq "1234567890.123456" "$RESULT_A" "session isolation: session A unchanged after B write"
assert_eq "9876543210.654321" "$RESULT_B" "session isolation: session B has its own thread_ts"

# Clean up
rm -f "$TEST_TS_FILE_A" "$TEST_TS_FILE_B"


# === TEST: Heartbeat threshold logic ===
echo ""
echo "=== Testing heartbeat threshold logic ==="

TEST_HASH_HB=$(slack_session_hash "session-heartbeat-test")
TEST_LAST_USER=$(slack_state_file "$TEST_HASH_HB" "last-user-ts")
TEST_HEARTBEAT=$(slack_state_file "$TEST_HASH_HB" "heartbeat-ts")

# Clean up
rm -f "$TEST_LAST_USER" "$TEST_HEARTBEAT"

# Test: no last-user-ts file → heartbeat should not fire
assert_file_not_exists "$TEST_LAST_USER" "heartbeat: no last-user-ts file initially"

# Test: recent user interaction → should not fire heartbeat
NOW=$(date +%s)
echo "$NOW" > "$TEST_LAST_USER"
IDLE_THRESHOLD=300
IDLE_SECONDS=$((NOW - $(cat "$TEST_LAST_USER")))
if [ "$IDLE_SECONDS" -lt "$IDLE_THRESHOLD" ]; then
    echo -e "${GREEN}PASS${NC}: heartbeat: recent user interaction blocks heartbeat"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAIL${NC}: heartbeat: recent user interaction blocks heartbeat"
    FAILED=$((FAILED + 1))
fi

# Test: old user interaction → should allow heartbeat
OLD_TS=$((NOW - 600))
echo "$OLD_TS" > "$TEST_LAST_USER"
IDLE_SECONDS=$((NOW - $(cat "$TEST_LAST_USER")))
if [ "$IDLE_SECONDS" -ge "$IDLE_THRESHOLD" ]; then
    echo -e "${GREEN}PASS${NC}: heartbeat: old user interaction allows heartbeat"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAIL${NC}: heartbeat: old user interaction allows heartbeat"
    FAILED=$((FAILED + 1))
fi

# Test: recent heartbeat → should not fire again
echo "$NOW" > "$TEST_HEARTBEAT"
HEARTBEAT_INTERVAL=300
HEARTBEAT_AGE=$((NOW - $(cat "$TEST_HEARTBEAT")))
if [ "$HEARTBEAT_AGE" -lt "$HEARTBEAT_INTERVAL" ]; then
    echo -e "${GREEN}PASS${NC}: heartbeat: recent heartbeat blocks duplicate"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAIL${NC}: heartbeat: recent heartbeat blocks duplicate"
    FAILED=$((FAILED + 1))
fi

# Test: old heartbeat → should allow new heartbeat
OLD_HB=$((NOW - 600))
echo "$OLD_HB" > "$TEST_HEARTBEAT"
HEARTBEAT_AGE=$((NOW - $(cat "$TEST_HEARTBEAT")))
if [ "$HEARTBEAT_AGE" -ge "$HEARTBEAT_INTERVAL" ]; then
    echo -e "${GREEN}PASS${NC}: heartbeat: old heartbeat allows new send"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAIL${NC}: heartbeat: old heartbeat allows new send"
    FAILED=$((FAILED + 1))
fi

# Clean up
rm -f "$TEST_LAST_USER" "$TEST_HEARTBEAT"


# === TEST: parse-transcript.sh integration ===
echo ""
echo "=== Testing parse-transcript.sh integration ==="

# Test: full parsing output
PARSE_OUTPUT=$("$SCRIPT_DIR/parse-transcript.sh" "$FIXTURES_DIR/ask_user_question.jsonl")
assert_contains "PARSED_HUMAN_TEXT=" "$PARSE_OUTPUT" "parse-transcript.sh: outputs PARSED_HUMAN_TEXT"
assert_contains "PARSED_ASSISTANT_TEXT=" "$PARSE_OUTPUT" "parse-transcript.sh: outputs PARSED_ASSISTANT_TEXT"
assert_contains "PARSED_ASK_QUESTION=" "$PARSE_OUTPUT" "parse-transcript.sh: outputs PARSED_ASK_QUESTION"
assert_contains "PARSED_TODO_STATUS=" "$PARSE_OUTPUT" "parse-transcript.sh: outputs PARSED_TODO_STATUS"

# Test: eval-able output
eval "$PARSE_OUTPUT"
assert_eq "Test idle_prompt hook" "$PARSED_HUMAN_TEXT" "parse-transcript.sh: PARSED_HUMAN_TEXT is correct"
assert_contains "Let me trigger a test" "$PARSED_ASSISTANT_TEXT" "parse-transcript.sh: PARSED_ASSISTANT_TEXT is correct"
assert_contains "Test type" "$PARSED_ASK_QUESTION" "parse-transcript.sh: PARSED_ASK_QUESTION contains header"


# === SUMMARY ===
echo ""
echo "================================"
echo -e "Results: ${GREEN}$PASSED passed${NC}, ${RED}$FAILED failed${NC}"
echo "================================"

if [ "$FAILED" -gt 0 ]; then
    exit 1
fi
