#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT_PATH="$REPO_ROOT/scripts/check-marketplace-entry.sh"

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

assert_contains() {
  local name="$1"
  local needle="$2"
  local haystack="$3"

  if printf '%s' "$haystack" | grep -Fq "$needle"; then
    pass "$name"
  else
    fail "$name"
    echo "  expected to contain: $needle"
    echo "  actual            : $haystack"
  fi
}

run_capture() {
  local output
  local status

  set +e
  output="$("$@" 2>&1)"
  status=$?
  set -e

  printf "%s\n%s\n" "$status" "$output"
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

MARKETPLACE_FILE="$TMP_DIR/marketplace.json"
INVALID_FILE="$TMP_DIR/invalid-marketplace.json"

cat > "$MARKETPLACE_FILE" <<'EOF'
{
  "name": "corca-plugins",
  "plugins": [
    { "name": "cwf", "source": "./plugins/cwf" },
    { "name": "read-guard", "source": "./plugins/read-guard" }
  ]
}
EOF

cat > "$INVALID_FILE" <<'EOF'
{
  "name": "broken-shape"
}
EOF

result="$(run_capture bash "$SCRIPT_PATH" --source "$MARKETPLACE_FILE" --plugin "cwf")"
status="$(printf '%s\n' "$result" | sed -n '1p')"
output="$(printf '%s\n' "$result" | sed -n '2,$p')"
assert_eq "found entry exits 0" "0" "$status"
assert_contains "found entry status output" "status=FOUND" "$output"

result="$(run_capture bash "$SCRIPT_PATH" "$MARKETPLACE_FILE" "CWF")"
status="$(printf '%s\n' "$result" | sed -n '1p')"
output="$(printf '%s\n' "$result" | sed -n '2,$p')"
assert_eq "case-insensitive plugin name is accepted" "0" "$status"
assert_contains "case-insensitive output status" "status=FOUND" "$output"

result="$(run_capture bash "$SCRIPT_PATH" --source "$MARKETPLACE_FILE" --plugin "missing")"
status="$(printf '%s\n' "$result" | sed -n '1p')"
output="$(printf '%s\n' "$result" | sed -n '2,$p')"
assert_eq "missing entry exits 4" "4" "$status"
assert_contains "missing entry status output" "status=MISSING_ENTRY" "$output"

result="$(run_capture bash "$SCRIPT_PATH" --source "$INVALID_FILE" --plugin "cwf")"
status="$(printf '%s\n' "$result" | sed -n '1p')"
output="$(printf '%s\n' "$result" | sed -n '2,$p')"
assert_eq "invalid marketplace exits 3" "3" "$status"
assert_contains "invalid marketplace status output" "status=INVALID_MARKETPLACE" "$output"

result="$(run_capture bash "$SCRIPT_PATH" --source "$TMP_DIR/does-not-exist.json" --plugin "cwf")"
status="$(printf '%s\n' "$result" | sed -n '1p')"
output="$(printf '%s\n' "$result" | sed -n '2,$p')"
assert_eq "missing file exits 2" "2" "$status"
assert_contains "missing file status output" "status=LOOKUP_FAILED" "$output"

result="$(run_capture bash "$SCRIPT_PATH" --source "$MARKETPLACE_FILE" --plugin "cwf" --json)"
status="$(printf '%s\n' "$result" | sed -n '1p')"
json_output="$(printf '%s\n' "$result" | sed -n '2,$p')"
assert_eq "json mode exits 0 for found entry" "0" "$status"
assert_eq \
  "json mode status field" \
  "FOUND" \
  "$(printf '%s' "$json_output" | jq -r '.status')"

echo "---"
echo "Fixtures: PASS=$PASS FAIL=$FAIL"

if [[ "$FAIL" -ne 0 ]]; then
  exit 1
fi
