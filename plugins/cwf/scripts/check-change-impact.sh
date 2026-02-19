#!/usr/bin/env bash
set -euo pipefail

# check-change-impact.sh
# Enforce change-impact rules between trigger files and required companion files.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONTRACT_PATH="$PLUGIN_ROOT/contracts/change-impact.json"
MODE="staged"

usage() {
  cat <<'USAGE'
check-change-impact.sh — validate file-change impact rules

Usage:
  check-change-impact.sh [options]

Options:
  --contract <path>  Change-impact JSON path (default: plugins/cwf/contracts/change-impact.json)
  --staged           Evaluate staged changes only (default)
  --working          Evaluate working-tree + staged + untracked changes
  -h, --help         Show this help
USAGE
}

fail() {
  echo "CHECK_FAIL: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"
}

matches_pattern() {
  local file="$1"
  local pattern="$2"
  # shellcheck disable=SC2254
  case "$file" in
    $pattern) return 0 ;;
    *) return 1 ;;
  esac
}

any_file_matches_any_pattern() {
  local -n files_ref=$1
  local -n patterns_ref=$2
  local file=""
  local pattern=""
  for file in "${files_ref[@]}"; do
    for pattern in "${patterns_ref[@]}"; do
      if matches_pattern "$file" "$pattern"; then
        return 0
      fi
    done
  done
  return 1
}

any_file_matches_pattern() {
  local -n files_ref=$1
  local pattern="$2"
  local file=""
  for file in "${files_ref[@]}"; do
    if matches_pattern "$file" "$pattern"; then
      return 0
    fi
  done
  return 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --contract)
      CONTRACT_PATH="${2-}"
      [[ -n "$CONTRACT_PATH" ]] || fail "--contract requires a path"
      shift 2
      ;;
    --staged)
      MODE="staged"
      shift
      ;;
    --working)
      MODE="working"
      shift
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

require_cmd jq

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
if [[ "$CONTRACT_PATH" != /* ]]; then
  if [[ -f "$REPO_ROOT/$CONTRACT_PATH" ]]; then
    CONTRACT_PATH="$REPO_ROOT/$CONTRACT_PATH"
  elif [[ -f "$PLUGIN_ROOT/$CONTRACT_PATH" ]]; then
    CONTRACT_PATH="$PLUGIN_ROOT/$CONTRACT_PATH"
  fi
fi

[[ -f "$CONTRACT_PATH" ]] || fail "contract file not found: $CONTRACT_PATH"

if ! jq -e '.version and (.rules | type == "array")' "$CONTRACT_PATH" >/dev/null; then
  fail "invalid contract schema: expected version + rules[]"
fi

changed_files=()
if [[ "$MODE" == "staged" ]]; then
  mapfile -t changed_files < <(git -C "$REPO_ROOT" diff --cached --name-only --diff-filter=ACMR | sed '/^$/d')
else
  mapfile -t changed_files < <(
    {
      git -C "$REPO_ROOT" diff --name-only --diff-filter=ACMR || true
      git -C "$REPO_ROOT" diff --cached --name-only --diff-filter=ACMR || true
      git -C "$REPO_ROOT" ls-files --others --exclude-standard || true
    } | awk 'NF && !seen[$0]++'
  )
fi

if [[ "${#changed_files[@]}" -eq 0 ]]; then
  echo "CHECK_OK: change-impact skipped (no changed files in mode=$MODE)"
  exit 0
fi

rule_count="$(jq '.rules | length' "$CONTRACT_PATH")"
fail_count=0

for ((i=0; i<rule_count; i++)); do
  rule_id="$(jq -r ".rules[$i].id // \"rule-$i\"" "$CONTRACT_PATH")"
  rule_msg="$(jq -r ".rules[$i].message // \"\"" "$CONTRACT_PATH")"

  mapfile -t when_changed < <(jq -r ".rules[$i].when_changed[]?" "$CONTRACT_PATH")
  if [[ "${#when_changed[@]}" -eq 0 ]]; then
    echo "CHECK_FAIL: [$rule_id] when_changed is empty" >&2
    fail_count=$((fail_count + 1))
    continue
  fi

  if ! any_file_matches_any_pattern changed_files when_changed; then
    continue
  fi

  mapfile -t require_all < <(jq -r ".rules[$i].require_all_changed[]?" "$CONTRACT_PATH")
  mapfile -t require_any < <(jq -r ".rules[$i].require_any_changed[]?" "$CONTRACT_PATH")

  if [[ "${#require_all[@]}" -gt 0 ]]; then
    for pattern in "${require_all[@]}"; do
      if ! any_file_matches_pattern changed_files "$pattern"; then
        echo "CHECK_FAIL: [$rule_id] missing required changed file (all): $pattern" >&2
        [[ -n "$rule_msg" ]] && echo "  -> $rule_msg" >&2
        fail_count=$((fail_count + 1))
      fi
    done
  fi

  if [[ "${#require_any[@]}" -gt 0 ]]; then
    if ! any_file_matches_any_pattern changed_files require_any; then
      echo "CHECK_FAIL: [$rule_id] requires at least one companion change: ${require_any[*]}" >&2
      [[ -n "$rule_msg" ]] && echo "  -> $rule_msg" >&2
      fail_count=$((fail_count + 1))
    fi
  fi
done

if [[ "$fail_count" -gt 0 ]]; then
  fail "change-impact validation failed ($fail_count issue(s))"
fi

echo "CHECK_OK: change-impact rules passed (mode=$MODE, changed=${#changed_files[@]})"
