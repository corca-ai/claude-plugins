#!/usr/bin/env bash
set -euo pipefail

# check-hook-sync.sh
# Verify generated .githooks files are synchronized with configure-git-hooks generator script.

usage() {
  cat <<'USAGE'
check-hook-sync.sh — validate .githooks sync marker

Usage:
  check-hook-sync.sh [--repo-root <path>]

Options:
  --repo-root <path>  Explicit repository root (default: git top-level)
  -h, --help          Show this help
USAGE
}

fail() {
  echo "CHECK_FAIL: $*" >&2
  exit 1
}

compute_sha256() {
  local file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
    return 0
  fi
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
    return 0
  fi
  return 1
}

REPO_ROOT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-root)
      REPO_ROOT="${2-}"
      [[ -n "$REPO_ROOT" ]] || fail "--repo-root requires a value"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown option: $1"
      ;;
  esac
done

if [[ -z "$REPO_ROOT" ]]; then
  REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi

CONFIG_SCRIPT="$REPO_ROOT/plugins/cwf/skills/setup/scripts/configure-git-hooks.sh"
[[ -f "$CONFIG_SCRIPT" ]] || fail "generator script not found: $CONFIG_SCRIPT"

EXPECTED_SHA="$(compute_sha256 "$CONFIG_SCRIPT" 2>/dev/null || true)"
[[ -n "$EXPECTED_SHA" ]] || fail "unable to compute SHA-256 for $CONFIG_SCRIPT"

fail_count=0
for hook in pre-commit pre-push; do
  hook_path="$REPO_ROOT/.githooks/$hook"
  if [[ ! -f "$hook_path" ]]; then
    echo "CHECK_FAIL: missing generated hook: .githooks/$hook" >&2
    fail_count=$((fail_count + 1))
    continue
  fi

  marker="$(grep -m1 '^# cwf-hook-source-sha=' "$hook_path" | sed 's/^# cwf-hook-source-sha=//' | tr -d '[:space:]')"
  if [[ -z "$marker" ]]; then
    echo "CHECK_FAIL: .githooks/$hook missing source SHA marker" >&2
    fail_count=$((fail_count + 1))
    continue
  fi

  if [[ "$marker" != "$EXPECTED_SHA" ]]; then
    echo "CHECK_FAIL: .githooks/$hook out of sync (expected $EXPECTED_SHA, got $marker)" >&2
    fail_count=$((fail_count + 1))
  fi
done

if [[ "$fail_count" -gt 0 ]]; then
  fail "hook sync check failed ($fail_count issue(s)); run configure-git-hooks.sh to regenerate hooks"
fi

echo "CHECK_OK: generated hooks are synchronized with configure-git-hooks.sh"
