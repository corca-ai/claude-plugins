#!/usr/bin/env bash
set -euo pipefail

# check-configure-git-hooks-runtime.sh
# Runtime regression checks for configure-git-hooks rendering and fallback paths.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SCRIPT="$SCRIPT_DIR/configure-git-hooks.sh"

fail() {
  echo "CHECK_FAIL: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"
}

require_cmd bash
require_cmd git
require_cmd grep
[[ -x "$CONFIG_SCRIPT" ]] || fail "configure script missing: $CONFIG_SCRIPT"

tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/cwf-hook-config-check.XXXXXX")"
cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT

fixture_repo="$tmp_root/repo"
mkdir -p "$fixture_repo"
git -C "$fixture_repo" init -q

run_config() {
  (
    cd "$fixture_repo"
    env "$@" bash "$CONFIG_SCRIPT" --install both --profile balanced >/dev/null
  )
}

hook_marker() {
  local hook_path="$1"
  grep -m1 '^# cwf-hook-source-sha=' "$hook_path" \
    | sed 's/^# cwf-hook-source-sha=//' \
    | tr -d '[:space:]'
}

assert_rendered_hook() {
  local hook_path="$1"
  [[ -f "$hook_path" ]] || fail "generated hook missing: ${hook_path#"$fixture_repo"/}"
  [[ -x "$hook_path" ]] || fail "generated hook is not executable: ${hook_path#"$fixture_repo"/}"
  grep -Fq 'PROFILE="balanced"' "$hook_path" || fail "profile token not rendered: ${hook_path#"$fixture_repo"/}"
  grep -Fq 'CWF_PLUGIN_ROOT=' "$hook_path" || fail "plugin root token not rendered: ${hook_path#"$fixture_repo"/}"
  if grep -Fq '__PROFILE__' "$hook_path"; then
    fail "unrendered __PROFILE__ token remains: ${hook_path#"$fixture_repo"/}"
  fi
  if grep -Fq '__CWF_PLUGIN_ROOT__' "$hook_path"; then
    fail "unrendered __CWF_PLUGIN_ROOT__ token remains: ${hook_path#"$fixture_repo"/}"
  fi
  if grep -Fq '__CONFIG_SHA__' "$hook_path"; then
    fail "unrendered __CONFIG_SHA__ token remains: ${hook_path#"$fixture_repo"/}"
  fi
}

run_config
assert_rendered_hook "$fixture_repo/.githooks/pre-commit"
assert_rendered_hook "$fixture_repo/.githooks/pre-push"
default_marker="$(hook_marker "$fixture_repo/.githooks/pre-push")"
[[ -n "$default_marker" ]] || fail "default marker is empty"

run_config CWF_HOOKS_RENDER_WITH_SED=1
assert_rendered_hook "$fixture_repo/.githooks/pre-commit"
assert_rendered_hook "$fixture_repo/.githooks/pre-push"

run_config CWF_HOOKS_DISABLE_SHA=1
sha_fallback_marker="$(hook_marker "$fixture_repo/.githooks/pre-push")"
[[ "$sha_fallback_marker" == "sha-unavailable" ]] || fail "expected sha-unavailable marker, got: $sha_fallback_marker"

hooks_path="$(git -C "$fixture_repo" config --get core.hooksPath || true)"
[[ "$hooks_path" == ".githooks" ]] || fail "expected core.hooksPath=.githooks, got: ${hooks_path:-<unset>}"

echo "CHECK_OK: configure-git-hooks runtime verified (default + sed-render + sha-unavailable)"
