#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ROOT_RESOLVER="$REPO_ROOT/scripts/cwf-artifact-paths.sh"
PLUGIN_RESOLVER="$REPO_ROOT/plugins/cwf/scripts/cwf-artifact-paths.sh"

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

resolve_with_env() {
  local resolver="$1"
  local base_dir="$2"
  local func="$3"
  shift 3

  env "$@" bash -c "set -euo pipefail; source \"$resolver\"; $func \"$base_dir\""
}

run_suite() {
  local resolver="$1"
  local label="$2"

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN

  local base_dir="$tmp_dir/repo"
  local external_projects="$tmp_dir/external-projects"
  mkdir -p "$base_dir/.cwf" "$external_projects"

  # 1) defaults
  assert_eq \
    "$label default artifact root" \
    "$base_dir/.cwf" \
    "$(resolve_with_env "$resolver" "$base_dir" resolve_cwf_artifact_root)"
  assert_eq \
    "$label default projects dir" \
    "$base_dir/.cwf/projects" \
    "$(resolve_with_env "$resolver" "$base_dir" resolve_cwf_projects_dir)"
  assert_eq \
    "$label default state file" \
    "$base_dir/.cwf/cwf-state.yaml" \
    "$(resolve_with_env "$resolver" "$base_dir" resolve_cwf_state_file)"
  assert_eq \
    "$label default projects relpath" \
    ".cwf/projects" \
    "$(resolve_with_env "$resolver" "$base_dir" resolve_cwf_projects_relpath)"

  # 2) process env overrides without project config files
  assert_eq \
    "$label env artifact root override" \
    "$base_dir/.cwf-env" \
    "$(resolve_with_env "$resolver" "$base_dir" resolve_cwf_artifact_root CWF_ARTIFACT_ROOT=.cwf-env)"
  assert_eq \
    "$label env projects override" \
    "$external_projects" \
    "$(resolve_with_env "$resolver" "$base_dir" resolve_cwf_projects_dir CWF_PROJECTS_DIR="$external_projects")"
  assert_eq \
    "$label env absolute projects relpath passthrough" \
    "$external_projects" \
    "$(resolve_with_env "$resolver" "$base_dir" resolve_cwf_projects_relpath CWF_PROJECTS_DIR="$external_projects")"

  # 3) shared config overrides env
  cat > "$base_dir/.cwf/config.yaml" <<'EOF'
CWF_ARTIFACT_ROOT: ".cwf-shared"
CWF_PROJECTS_DIR: ".cwf-shared/projects-shared"
CWF_STATE_FILE: ".cwf-shared/state-shared.yaml"
EOF

  assert_eq \
    "$label shared config wins over env artifact root" \
    "$base_dir/.cwf-shared" \
    "$(resolve_with_env "$resolver" "$base_dir" resolve_cwf_artifact_root CWF_ARTIFACT_ROOT=.cwf-env)"
  assert_eq \
    "$label shared config wins over env projects dir" \
    "$base_dir/.cwf-shared/projects-shared" \
    "$(resolve_with_env "$resolver" "$base_dir" resolve_cwf_projects_dir CWF_PROJECTS_DIR="$external_projects")"
  assert_eq \
    "$label shared config state file" \
    "$base_dir/.cwf-shared/state-shared.yaml" \
    "$(resolve_with_env "$resolver" "$base_dir" resolve_cwf_state_file CWF_STATE_FILE=.cwf-env/state-env.yaml)"

  # 4) local config overrides shared and supports inline comments
  cat > "$base_dir/.cwf/config.local.yaml" <<'EOF'
CWF_ARTIFACT_ROOT: ".cwf-local"
CWF_PROJECTS_DIR: ".cwf-local/projects-local" # local override
CWF_STATE_FILE: ".cwf-local/state-local.yaml"
EOF

  assert_eq \
    "$label local config wins over shared artifact root" \
    "$base_dir/.cwf-local" \
    "$(resolve_with_env "$resolver" "$base_dir" resolve_cwf_artifact_root)"
  assert_eq \
    "$label local config wins over shared projects dir" \
    "$base_dir/.cwf-local/projects-local" \
    "$(resolve_with_env "$resolver" "$base_dir" resolve_cwf_projects_dir)"
  assert_eq \
    "$label local config wins over shared state file" \
    "$base_dir/.cwf-local/state-local.yaml" \
    "$(resolve_with_env "$resolver" "$base_dir" resolve_cwf_state_file)"
  assert_eq \
    "$label local config projects relpath" \
    ".cwf-local/projects-local" \
    "$(resolve_with_env "$resolver" "$base_dir" resolve_cwf_projects_relpath)"

  rm -rf "$tmp_dir"
  trap - RETURN
}

run_suite "$ROOT_RESOLVER" "root resolver"
run_suite "$PLUGIN_RESOLVER" "plugin resolver"

echo "---"
echo "Fixtures: PASS=$PASS FAIL=$FAIL"

if [[ "$FAIL" -ne 0 ]]; then
  exit 1
fi
