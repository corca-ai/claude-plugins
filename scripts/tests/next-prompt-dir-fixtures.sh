#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ROOT_SCRIPT="$REPO_ROOT/scripts/next-prompt-dir.sh"
PLUGIN_SCRIPT="$REPO_ROOT/plugins/cwf/scripts/next-prompt-dir.sh"

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

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

PROMPT_LOGS_DIR="$TMP_DIR/prompt-logs"
mkdir -p "$PROMPT_LOGS_DIR"

mkdir -p \
  "$PROMPT_LOGS_DIR/260214-01-alpha" \
  "$PROMPT_LOGS_DIR/260214-02-beta" \
  "$PROMPT_LOGS_DIR/260214-xx-ignore" \
  "$PROMPT_LOGS_DIR/260214-99" \
  "$PROMPT_LOGS_DIR/260213-11-prev-day"

expected_today="prompt-logs/260214-03-s26"
actual_root_today="$(CWF_PROMPT_LOGS_DIR="$PROMPT_LOGS_DIR" CWF_NEXT_PROMPT_DATE=260214 bash "$ROOT_SCRIPT" s26)"
actual_plugin_today="$(CWF_PROMPT_LOGS_DIR="$PROMPT_LOGS_DIR" CWF_NEXT_PROMPT_DATE=260214 bash "$PLUGIN_SCRIPT" s26)"

assert_eq "root script uses max same-day sequence" "$expected_today" "$actual_root_today"
assert_eq "plugin script matches root sequence logic" "$expected_today" "$actual_plugin_today"

expected_next_day="prompt-logs/260215-01-s26"
actual_root_next_day="$(CWF_PROMPT_LOGS_DIR="$PROMPT_LOGS_DIR" CWF_NEXT_PROMPT_DATE=260215 bash "$ROOT_SCRIPT" s26)"
actual_plugin_next_day="$(CWF_PROMPT_LOGS_DIR="$PROMPT_LOGS_DIR" CWF_NEXT_PROMPT_DATE=260215 bash "$PLUGIN_SCRIPT" s26)"

assert_eq "root script resets sequence across day boundary" "$expected_next_day" "$actual_root_next_day"
assert_eq "plugin script resets sequence across day boundary" "$expected_next_day" "$actual_plugin_next_day"

set +e
CWF_PROMPT_LOGS_DIR="$PROMPT_LOGS_DIR" CWF_NEXT_PROMPT_DATE=2026-02-14 bash "$ROOT_SCRIPT" bad >/dev/null 2>&1
invalid_status=$?
set -e

if [[ "$invalid_status" -ne 0 ]]; then
  pass "invalid override date is rejected"
else
  fail "invalid override date is rejected"
fi

echo "---"
echo "Fixtures: PASS=$PASS FAIL=$FAIL"

if [[ "$FAIL" -ne 0 ]]; then
  exit 1
fi
