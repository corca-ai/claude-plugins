#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$REPO_ROOT/plugins/cwf/scripts/retro-coverage-contract.sh"

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

assert_file_nonempty() {
  local name="$1"
  local file="$2"
  if [[ -s "$file" ]]; then
    pass "$name"
  else
    fail "$name"
    echo "  missing_or_empty: $file"
  fi
}

assert_file_exists() {
  local name="$1"
  local file="$2"
  if [[ -f "$file" ]]; then
    pass "$name"
  else
    fail "$name"
    echo "  missing: $file"
  fi
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

SESSION_DIR="$TMP_DIR/session"
mkdir -p "$SESSION_DIR"

base_ref=""
if git -C "$REPO_ROOT" rev-parse --verify HEAD~1 >/dev/null 2>&1; then
  base_ref="HEAD~1"
else
  base_ref="HEAD"
fi

bash "$SCRIPT" \
  --repo-root "$REPO_ROOT" \
  --session-dir "$SESSION_DIR" \
  --base-ref "$base_ref" >/dev/null

assert_file_nonempty "coverage summary exists" "$SESSION_DIR/coverage/coverage-contract-summary.txt"
if [[ "$base_ref" == "HEAD" ]]; then
  assert_file_exists "diff all file exists (single-commit fallback)" "$SESSION_DIR/coverage/diff-all-excl-session-logs.txt"
else
  assert_file_nonempty "diff all exists" "$SESSION_DIR/coverage/diff-all-excl-session-logs.txt"
fi
assert_file_nonempty "top-level breakdown exists" "$SESSION_DIR/coverage/diff-top-level-breakdown.txt"
assert_file_nonempty "project primary corpus exists" "$SESSION_DIR/coverage/project-lessons-retro-primary.txt"

echo "---"
echo "Fixtures: PASS=$PASS FAIL=$FAIL"

if [[ "$FAIL" -ne 0 ]]; then
  exit 1
fi
