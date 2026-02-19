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
  *FAIL_CASE*)
    echo "fail case" >&2
    exit 7
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
fail|FAIL_CASE
timeout|TIMEOUT_CASE
EOF

status="$(run_status bash "$SMOKE_SCRIPT" \
  --plugin-dir "$PLUGIN_DIR" \
  --workdir "$REPO_ROOT" \
  --cases-file "$CASES_FILE" \
  --claude-bin "$MOCK_CLAUDE" \
  --timeout 1 \
  --max-failures 1 \
  --max-timeouts 1 \
  --output-dir "$OUTPUT_A")"
assert_eq "gate passes when thresholds allow fail/timeout" "0" "$status"
assert_file_contains "summary has PASS row" "$OUTPUT_A/summary.tsv" "$(printf 'pass\tPASS')"
assert_file_contains "summary has FAIL row" "$OUTPUT_A/summary.tsv" "$(printf 'fail\tFAIL')"
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
