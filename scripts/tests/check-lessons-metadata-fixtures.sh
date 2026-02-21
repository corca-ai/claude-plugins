#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CHECKER="$REPO_ROOT/plugins/cwf/scripts/check-lessons-metadata.sh"

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

run_status() {
  set +e
  "$@" >/dev/null 2>&1
  local status=$?
  set -e
  echo "$status"
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

GOOD="$TMP_DIR/good-lessons.md"
BAD="$TMP_DIR/bad-lessons.md"

cat > "$GOOD" <<'EOF_GOOD'
# Lessons

## Deep Retro Lesson — Example (2026-02-21)
- **Owner**: `plugin`
- **Apply Layer**: `upstream`
- **Promotion Target**: `scripts/premerge-cwf-gate.sh`
- **Due Release**: `0.8.9`
- **Expected**: X
- **Actual**: Y
- **Takeaway**: Z
EOF_GOOD

cat > "$BAD" <<'EOF_BAD'
# Lessons

## Deep Retro Lesson — Missing Metadata (2026-02-21)
- **Expected**: X
- **Actual**: Y
- **Takeaway**: Z
EOF_BAD

status="$(run_status bash "$CHECKER" --file "$GOOD")"
assert_eq "good lessons pass" "0" "$status"

status="$(run_status bash "$CHECKER" --file "$BAD")"
assert_eq "bad lessons fail" "1" "$status"

echo "---"
echo "Fixtures: PASS=$PASS FAIL=$FAIL"

if [[ "$FAIL" -ne 0 ]]; then
  exit 1
fi
