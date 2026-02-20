#!/usr/bin/env bash
set -euo pipefail

# hook-core-smoke.sh — deterministic smoke checks for core CWF hooks.
#
# Scope (no external package dependencies):
# - read-guard.sh
# - check-deletion-safety.sh
# - workflow-gate.sh
#
# Exit codes:
#   0 = all checks passed
#   1 = at least one check failed

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
HOOK_DIR="$REPO_ROOT/plugins/cwf/hooks/scripts"

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

assert_empty() {
  local name="$1"
  local value="$2"
  if [[ -z "$value" ]]; then
    pass "$name"
  else
    fail "$name"
    echo "  expected: <empty>"
    echo "  actual  : $value"
  fi
}

run_capture() {
  local output
  local rc
  set +e
  output="$("$@" 2>&1)"
  rc=$?
  set -e
  printf '%s\n%s\n' "$rc" "$output"
}

if [[ ! -x "$HOOK_DIR/read-guard.sh" ]] \
  || [[ ! -x "$HOOK_DIR/check-deletion-safety.sh" ]] \
  || [[ ! -x "$HOOK_DIR/workflow-gate.sh" ]]; then
  echo "Error: expected hook scripts are missing or not executable under $HOOK_DIR" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required for hook smoke checks." >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

#
# Case group A: read-guard
#
SMALL_FILE="$TMP_DIR/small.txt"
LARGE_FILE="$TMP_DIR/large.txt"
for i in $(seq 1 50); do echo "small-$i" >> "$SMALL_FILE"; done
for i in $(seq 1 2105); do echo "large-$i" >> "$LARGE_FILE"; done

result="$(run_capture bash -c "jq -nc --arg p '$SMALL_FILE' '{tool_name:\"Read\",tool_input:{file_path:\$p}}' | bash '$HOOK_DIR/read-guard.sh'")"
rc="$(printf '%s\n' "$result" | sed -n '1p')"
out="$(printf '%s\n' "$result" | sed -n '2,$p')"
assert_eq "read-guard allows small file" "0" "$rc"
assert_empty "read-guard small file output is empty" "$out"

result="$(run_capture bash -c "jq -nc --arg p '$LARGE_FILE' '{tool_name:\"Read\",tool_input:{file_path:\$p}}' | bash '$HOOK_DIR/read-guard.sh'")"
rc="$(printf '%s\n' "$result" | sed -n '1p')"
out="$(printf '%s\n' "$result" | sed -n '2,$p')"
assert_eq "read-guard large file exits 0 with deny payload" "0" "$rc"
assert_contains "read-guard large file includes deny decision" "\"permissionDecision\":\"deny\"" "$out"

#
# Case group B: deletion-safety
#
ALLOW_TARGET="$TMP_DIR/allow-delete.txt"
echo "tmp" > "$ALLOW_TARGET"

result="$(run_capture bash -c "jq -nc '{tool_name:\"Bash\",tool_input:{command:\"rm plugins/cwf/hooks/scripts/cwf-hook-gate.sh\"}}' | bash '$HOOK_DIR/check-deletion-safety.sh'")"
rc="$(printf '%s\n' "$result" | sed -n '1p')"
out="$(printf '%s\n' "$result" | sed -n '2,$p')"
assert_eq "deletion-safety blocks repo file deletion" "1" "$rc"
assert_contains "deletion-safety block payload" "\"decision\":\"block\"" "$out"

result="$(run_capture bash -c "jq -nc --arg cmd 'rm $ALLOW_TARGET' '{tool_name:\"Bash\",tool_input:{command:\$cmd}}' | bash '$HOOK_DIR/check-deletion-safety.sh'")"
rc="$(printf '%s\n' "$result" | sed -n '1p')"
out="$(printf '%s\n' "$result" | sed -n '2,$p')"
assert_eq "deletion-safety allows /tmp deletion" "0" "$rc"
assert_empty "deletion-safety allow output is empty" "$out"

#
# Case group C: workflow-gate
#
WF_REPO="$TMP_DIR/workflow-repo"
mkdir -p "$WF_REPO/.cwf"
git -C "$WF_REPO" init -q
cat > "$WF_REPO/.cwf/cwf-state.yaml" <<'EOF'
workflow:
  current_stage: run
sessions: []
tools: {}
hooks: {}
live:
  active_pipeline: "cwf:run"
  session_id: "sess-h35"
  phase: "impl"
  remaining_gates:
    - review-code
    - refactor
    - retro
    - ship
  pipeline_override_reason: ""
  state_version: "7"
EOF

result="$(run_capture bash -c "jq -nc --arg prompt 'git push origin main' --arg sid 'sess-h35' --arg cwd '$WF_REPO' '{prompt:\$prompt,session_id:\$sid,cwd:\$cwd}' | bash '$HOOK_DIR/workflow-gate.sh'")"
rc="$(printf '%s\n' "$result" | sed -n '1p')"
out="$(printf '%s\n' "$result" | sed -n '2,$p')"
assert_eq "workflow-gate blocks push while closing gates remain" "0" "$rc"
assert_contains "workflow-gate block reason includes pending gates" "run-closing gates are still pending" "$out"

result="$(run_capture bash -c "jq -nc --arg prompt '다음 게이트 진행해' --arg sid 'sess-h35' --arg cwd '$WF_REPO' '{prompt:\$prompt,session_id:\$sid,cwd:\$cwd}' | bash '$HOOK_DIR/workflow-gate.sh'")"
rc="$(printf '%s\n' "$result" | sed -n '1p')"
out="$(printf '%s\n' "$result" | sed -n '2,$p')"
assert_eq "workflow-gate allows non-protected prompt" "0" "$rc"
assert_contains "workflow-gate allow payload" "\"additionalContext\":" "$out"

echo "---"
echo "Hook smoke summary: PASS=$PASS FAIL=$FAIL"

if [[ "$FAIL" -ne 0 ]]; then
  exit 1
fi
