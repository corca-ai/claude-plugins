#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SMOKE_SCRIPT="$REPO_ROOT/scripts/runtime-residual-smoke.sh"
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

assert_file_exists() {
  local name="$1"
  local file_path="$2"
  if [[ -f "$file_path" ]]; then
    pass "$name"
  else
    fail "$name"
    echo "  missing: $file_path"
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
STATE_FILE="$TMP_DIR/setup-run-count.txt"
OUT_OBS="$TMP_DIR/out-observe"
OUT_STRICT_FAIL="$TMP_DIR/out-strict-fail"
OUT_STRICT_PASS="$TMP_DIR/out-strict-pass"

cat > "$MOCK_CLAUDE" <<'EOF_MOCK'
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

mode="${MOCK_MODE:-mixed}"
state_file="${MOCK_STATE_FILE:-}"

if [[ "$prompt" == "cwf:retro --light" ]]; then
  case "$mode" in
    mixed)
      sleep 2
      ;;
    clean)
      echo "retro ok"
      ;;
    *)
      echo "retro default"
      ;;
  esac
  exit 0
fi

if [[ "$prompt" == "cwf:setup" || "$prompt" == "cwf:setup --hooks" ]]; then
  run_no=1
  if [[ -n "$state_file" ]]; then
    if [[ -f "$state_file" ]]; then
      run_no="$(( $(cat "$state_file") + 1 ))"
    fi
    echo "$run_no" > "$state_file"
  fi

  case "$mode" in
    mixed)
      if [[ "$run_no" -eq 2 ]]; then
        # no output
        exit 0
      fi
      echo "WAIT_INPUT: setup requires user selection at phase 1.2."
      echo "Please reply with your choice."
      ;;
    clean)
      echo "WAIT_INPUT: setup requires user selection at phase 1.2."
      echo "Please reply with your choice."
      ;;
    *)
      echo "WAIT_INPUT: setup requires user selection at phase 1.2."
      ;;
  esac
  exit 0
fi

echo "unknown prompt"
exit 0
EOF_MOCK
chmod +x "$MOCK_CLAUDE"

status="$(run_status env MOCK_MODE=mixed MOCK_STATE_FILE="$STATE_FILE" bash "$SMOKE_SCRIPT" \
  --mode observe \
  --plugin-dir "$PLUGIN_DIR" \
  --workdir "$REPO_ROOT" \
  --claude-bin "$MOCK_CLAUDE" \
  --k46-timeout 1 \
  --s10-timeout 1 \
  --s10-runs 3 \
  --output-dir "$OUT_OBS")"
assert_eq "observe mode exits 0 on residuals" "0" "$status"
assert_file_contains "observe summary has K46 timeout" "$OUT_OBS/summary.tsv" "$(printf 'K46\t1\tFAIL\tTIMEOUT')"
assert_file_contains "observe summary retries S10 into WAIT_INPUT" "$OUT_OBS/summary.tsv" "$(printf 'S10\t2\tPASS\tWAIT_INPUT')"
assert_file_exists "observe output keeps retry evidence" "$OUT_OBS/S10-run2.log.retry2"

rm -f "$STATE_FILE"
status="$(run_status env MOCK_MODE=mixed MOCK_STATE_FILE="$STATE_FILE" bash "$SMOKE_SCRIPT" \
  --mode strict \
  --plugin-dir "$PLUGIN_DIR" \
  --workdir "$REPO_ROOT" \
  --claude-bin "$MOCK_CLAUDE" \
  --k46-timeout 1 \
  --s10-timeout 1 \
  --s10-runs 3 \
  --output-dir "$OUT_STRICT_FAIL")"
assert_eq "strict mode fails on timeout/no_output" "1" "$status"

rm -f "$STATE_FILE"
status="$(run_status env MOCK_MODE=clean MOCK_STATE_FILE="$STATE_FILE" bash "$SMOKE_SCRIPT" \
  --mode strict \
  --plugin-dir "$PLUGIN_DIR" \
  --workdir "$REPO_ROOT" \
  --claude-bin "$MOCK_CLAUDE" \
  --k46-timeout 1 \
  --s10-timeout 1 \
  --s10-runs 3 \
  --output-dir "$OUT_STRICT_PASS")"
assert_eq "strict mode passes when residuals absent" "0" "$status"
assert_file_contains "strict pass summary has K46 OK" "$OUT_STRICT_PASS/summary.tsv" "$(printf 'K46\t1\tPASS\tOK')"


echo "---"
echo "Fixtures: PASS=$PASS FAIL=$FAIL"

if [[ "$FAIL" -ne 0 ]]; then
  exit 1
fi
