#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$REPO_ROOT/plugins/cwf/scripts/check-setup-readiness.sh"

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

assert_contains() {
  local name="$1"
  local haystack="$2"
  local needle="$3"
  if printf '%s' "$haystack" | grep -Fq "$needle"; then
    pass "$name"
  else
    fail "$name"
    echo "  expected to contain: $needle"
    echo "  actual: $haystack"
  fi
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

FIXTURE="$TMP_DIR/repo"
mkdir -p "$FIXTURE/.cwf"

cat > "$FIXTURE/.cwf/cwf-state.yaml" <<'EOF'
hooks:
  attention: true
sessions: []
EOF

cat > "$FIXTURE/.cwf/setup-contract.yaml" <<'EOF'
version: 1
policy:
  core_tools_required: true
EOF

cat > "$FIXTURE/.cwf-config.yaml" <<'EOF'
CWF_RUN_AMBIGUITY_MODE: "defer-blocking"
EOF

ready_output="$(bash "$SCRIPT" --base-dir "$FIXTURE" --summary)"
assert_contains "ready fixture returns ready=yes" "$ready_output" "ready=yes"

cat > "$FIXTURE/.cwf/cwf-state.yaml" <<'EOF'
hooks:
  attention: true
EOF

set +e
missing_sessions_output="$(bash "$SCRIPT" --base-dir "$FIXTURE" --summary 2>&1)"
missing_sessions_rc=$?
set -e
if [[ "$missing_sessions_rc" -ne 0 ]]; then
  pass "missing sessions fixture returns failure"
else
  fail "missing sessions fixture returns failure"
fi
assert_contains "missing sessions reports sessions token" "$missing_sessions_output" "missing="
assert_contains "missing sessions includes sessions label" "$missing_sessions_output" "sessions"

cat > "$FIXTURE/.cwf/cwf-state.yaml" <<'EOF'
hooks:
  attention: true
sessions: []
EOF
cat > "$FIXTURE/.cwf-config.yaml" <<'EOF'
# run mode intentionally omitted
EOF

env_ready_output="$(
  CWF_RUN_AMBIGUITY_MODE="strict" \
    bash "$SCRIPT" --base-dir "$FIXTURE" --summary
)"
assert_contains "env run mode satisfies readiness" "$env_ready_output" "ready=yes"
assert_contains "env run mode surfaced in summary" "$env_ready_output" "run_mode=strict"

echo "---"
echo "Fixtures: PASS=$PASS FAIL=$FAIL"

if [[ "$FAIL" -ne 0 ]]; then
  exit 1
fi
