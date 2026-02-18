#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
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

PROJECTS_DIR="$TMP_DIR/projects"
mkdir -p "$PROJECTS_DIR"

mkdir -p \
  "$PROJECTS_DIR/260214-01-alpha" \
  "$PROJECTS_DIR/260214-02-beta" \
  "$PROJECTS_DIR/260214-xx-ignore" \
  "$PROJECTS_DIR/260214-99" \
  "$PROJECTS_DIR/260213-11-prev-day"

expected_today="$PROJECTS_DIR/260214-03-s26"
actual_plugin_today="$(CWF_PROJECTS_DIR="$PROJECTS_DIR" CWF_NEXT_PROMPT_DATE=260214 bash "$PLUGIN_SCRIPT" s26)"

assert_eq "plugin script uses max same-day sequence" "$expected_today" "$actual_plugin_today"

expected_next_day="$PROJECTS_DIR/260215-01-s26"
actual_plugin_next_day="$(CWF_PROJECTS_DIR="$PROJECTS_DIR" CWF_NEXT_PROMPT_DATE=260215 bash "$PLUGIN_SCRIPT" s26)"

assert_eq "plugin script resets sequence across day boundary" "$expected_next_day" "$actual_plugin_next_day"

expected_artifact_root=".cwf/projects/990101-01-s26"
actual_plugin_artifact="$(CWF_ARTIFACT_ROOT=".cwf" CWF_NEXT_PROMPT_DATE=990101 bash "$PLUGIN_SCRIPT" s26)"

assert_eq "plugin script supports artifact-root based output path" "$expected_artifact_root" "$actual_plugin_artifact"

STATE_FILE="$TMP_DIR/cwf-state.yaml"
cat > "$STATE_FILE" <<'EOF'
workflow:
  current_stage: harden
sessions:
  - id: S-prev
    title: "Previous Session"
    dir: ".cwf/projects/260214-00-prev"
    branch: "main"
tools: {}
hooks: {}
live:
  session_id: ""
  dir: ""
  branch: ""
  phase: ""
  task: ""
EOF

plugin_bootstrap_path="$(
  CWF_PROJECTS_DIR="$PROJECTS_DIR" \
  CWF_STATE_FILE="$STATE_FILE" \
  CWF_NEXT_PROMPT_DATE=260214 \
  bash "$PLUGIN_SCRIPT" --bootstrap boot-plugin
)"
expected_plugin_bootstrap="$PROJECTS_DIR/260214-03-boot-plugin"
assert_eq "plugin bootstrap returns resolved path" "$expected_plugin_bootstrap" "$plugin_bootstrap_path"

if [[ -d "$expected_plugin_bootstrap" ]]; then
  pass "plugin bootstrap creates session directory"
else
  fail "plugin bootstrap creates session directory"
fi

if [[ -f "$expected_plugin_bootstrap/plan.md" ]]; then
  pass "plugin bootstrap initializes plan.md"
else
  fail "plugin bootstrap initializes plan.md"
fi

if [[ -f "$expected_plugin_bootstrap/lessons.md" ]]; then
  pass "plugin bootstrap initializes lessons.md"
else
  fail "plugin bootstrap initializes lessons.md"
fi

if grep -Fq "dir: \"$expected_plugin_bootstrap\"" "$STATE_FILE"; then
  pass "plugin bootstrap registers session dir in state"
else
  fail "plugin bootstrap registers session dir in state"
fi

set +e
CWF_PROJECTS_DIR="$PROJECTS_DIR" CWF_NEXT_PROMPT_DATE=2026-02-14 bash "$PLUGIN_SCRIPT" bad >/dev/null 2>&1
invalid_status=$?
set -e

if [[ "$invalid_status" -ne 0 ]]; then
  pass "invalid override date is rejected"
else
  fail "invalid override date is rejected"
fi

ROOT_FIXTURE="$TMP_DIR/root-resolution"
mkdir -p "$ROOT_FIXTURE/sub/dir" "$ROOT_FIXTURE/.cwf/projects"
git -C "$ROOT_FIXTURE" init -q

expected_from_cwd=".cwf/projects/260216-01-root-cwd"
actual_from_cwd="$(
  cd "$ROOT_FIXTURE/sub/dir" \
    && CWF_NEXT_PROMPT_DATE=260216 bash "$PLUGIN_SCRIPT" root-cwd
)"
assert_eq "plugin resolves project root from caller cwd git context" "$expected_from_cwd" "$actual_from_cwd"

mkdir -p "$ROOT_FIXTURE/.cwf/projects/260216-01-existing"
expected_from_override=".cwf/projects/260216-02-root-override"
actual_from_override="$(
  cd "$TMP_DIR" \
    && CWF_PROJECT_ROOT="$ROOT_FIXTURE" CWF_NEXT_PROMPT_DATE=260216 bash "$PLUGIN_SCRIPT" root-override
)"
assert_eq "plugin honors CWF_PROJECT_ROOT override for root resolution" "$expected_from_override" "$actual_from_override"

echo "---"
echo "Fixtures: PASS=$PASS FAIL=$FAIL"

if [[ "$FAIL" -ne 0 ]]; then
  exit 1
fi
