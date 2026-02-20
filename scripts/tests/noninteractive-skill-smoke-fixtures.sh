#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SMOKE_SCRIPT="$REPO_ROOT/scripts/noninteractive-skill-smoke.sh"
PLUGIN_DIR="$REPO_ROOT/plugins/cwf"

PASS=0
FAIL=0

pass() {
  echo "[PASS] $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "[FAIL] $1"
  FAIL=$((FAIL + 1))
}

assert_eq() {
  local name="$1"
  local expected="$2"
  local actual="$3"

  if [[ "$expected" == "$actual" ]]; then
    pass "$name"
  else
    fail "$name"
    echo "  expected: $expected"
    echo "  actual  : $actual"
  fi
}

assert_file_contains() {
  local name="$1"
  local file_path="$2"
  local text="$3"

  if [[ -f "$file_path" ]] && grep -Fq "$text" "$file_path"; then
    pass "$name"
  else
    fail "$name"
    echo "  file   : $file_path"
    echo "  expect : $text"
  fi
}

run_status() {
  set +e
  "$@" >/dev/null 2>&1
  local status=$?
  set -e
  echo "$status"
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

MOCK_CLAUDE="$TMP_DIR/mock-claude.sh"
CASES_FILE="$TMP_DIR/cases.txt"
OUTPUT_A="$TMP_DIR/out-a"
OUTPUT_B="$TMP_DIR/out-b"

cat > "$MOCK_CLAUDE" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
prompt=""
prev=""
for arg in "$@"; do
  if [[ "$prev" == "--print" ]]; then
    prompt="$arg"
    break
  fi
  prev="$arg"
done
if [[ -z "$prompt" ]]; then
  prompt="${@: -1}"
fi

case "$prompt" in
  *PASS_CASE*)
    echo "pass case"
    exit 0
    ;;
  *WAIT_INPUT_CASE*)
    echo "What task would you like the full CWF pipeline to work on?"
    echo "Please describe the task."
    exit 0
    ;;
  *WAIT_INPUT_ALT_CASE*)
    echo "A bare file path isn't a supported input. What did you have in mind?"
    echo "Which would you like?"
    exit 0
    ;;
  *WAIT_INPUT_RUN_CASE*)
    echo "What would you like cwf:run to work on?"
    echo "Please provide your task description."
    exit 0
    ;;
  *WAIT_INPUT_CONFIRM_CASE*)
    echo "Could you confirm which file to review?"
    echo "Please confirm."
    exit 0
    ;;
  *WAIT_INPUT_PIPELINE_CASE*)
    echo "What task should the cwf:run pipeline execute?"
    echo "Which file should I review?"
    echo "Would you like to provide a different path?"
    exit 0
    ;;
  *WAIT_INPUT_SETUP_CASE*)
    echo "WAIT_INPUT: setup requires user selection at phase 2.8."
    echo "Could you choose one of the following for project config bootstrap?"
    echo "Please reply with your choice."
    exit 0
    ;;
  *FAIL_CASE*)
    echo "fail case" >&2
    exit 7
    ;;
  *EMPTY_CASE*)
    exit 0
    ;;
  *TIMEOUT_CASE*)
    sleep 3
    echo "late pass"
    exit 0
    ;;
  *)
    echo "default pass"
    exit 0
    ;;
esac
EOF
chmod +x "$MOCK_CLAUDE"

cat > "$CASES_FILE" <<'EOF'
pass|PASS_CASE
wait|WAIT_INPUT_CASE
wait-alt|WAIT_INPUT_ALT_CASE
wait-run|WAIT_INPUT_RUN_CASE
wait-confirm|WAIT_INPUT_CONFIRM_CASE
wait-pipeline|WAIT_INPUT_PIPELINE_CASE
wait-setup|WAIT_INPUT_SETUP_CASE
fail|FAIL_CASE
empty|EMPTY_CASE
timeout|TIMEOUT_CASE
EOF

status="$(run_status bash "$SMOKE_SCRIPT" \
  --plugin-dir "$PLUGIN_DIR" \
  --workdir "$REPO_ROOT" \
  --cases-file "$CASES_FILE" \
  --claude-bin "$MOCK_CLAUDE" \
  --timeout 1 \
  --max-failures 8 \
  --max-timeouts 1 \
  --output-dir "$OUTPUT_A")"
assert_eq "gate passes when thresholds allow fail/timeout" "0" "$status"
assert_file_contains "summary has PASS row" "$OUTPUT_A/summary.tsv" "$(printf 'pass\tPASS')"
assert_file_contains "summary has WAIT_INPUT row" "$OUTPUT_A/summary.tsv" "$(printf 'wait\tFAIL\tWAIT_INPUT')"
assert_file_contains "summary has WAIT_INPUT alt row" "$OUTPUT_A/summary.tsv" "$(printf 'wait-alt\tFAIL\tWAIT_INPUT')"
assert_file_contains "summary has WAIT_INPUT run row" "$OUTPUT_A/summary.tsv" "$(printf 'wait-run\tFAIL\tWAIT_INPUT')"
assert_file_contains "summary has WAIT_INPUT confirm row" "$OUTPUT_A/summary.tsv" "$(printf 'wait-confirm\tFAIL\tWAIT_INPUT')"
assert_file_contains "summary has WAIT_INPUT pipeline row" "$OUTPUT_A/summary.tsv" "$(printf 'wait-pipeline\tFAIL\tWAIT_INPUT')"
assert_file_contains "summary has WAIT_INPUT setup row" "$OUTPUT_A/summary.tsv" "$(printf 'wait-setup\tFAIL\tWAIT_INPUT')"
assert_file_contains "summary has FAIL row" "$OUTPUT_A/summary.tsv" "$(printf 'fail\tFAIL')"
assert_file_contains "summary has NO_OUTPUT row" "$OUTPUT_A/summary.tsv" "$(printf 'empty\tFAIL\tNO_OUTPUT')"
assert_file_contains "summary has TIMEOUT row" "$OUTPUT_A/summary.tsv" "$(printf 'timeout\tTIMEOUT')"

status="$(run_status bash "$SMOKE_SCRIPT" \
  --plugin-dir "$PLUGIN_DIR" \
  --workdir "$REPO_ROOT" \
  --cases-file "$CASES_FILE" \
  --claude-bin "$MOCK_CLAUDE" \
  --timeout 1 \
  --max-failures 0 \
  --max-timeouts 0 \
  --output-dir "$OUTPUT_B")"
assert_eq "gate fails when thresholds are strict" "1" "$status"
assert_file_contains "strict run summary exists" "$OUTPUT_B/summary.tsv" "result"

echo "---"
echo "Fixtures: PASS=$PASS FAIL=$FAIL"

if [[ "$FAIL" -ne 0 ]]; then
  exit 1
fi
