#!/usr/bin/env bash
# check-run-from-prereqs.sh — deterministic prerequisite gate for `cwf:run --from`.
#
# Usage:
#   bash plugins/cwf/scripts/check-run-from-prereqs.sh --from impl
#   bash plugins/cwf/scripts/check-run-from-prereqs.sh --from review-code --base-dir /path/to/repo
#
# Exit codes:
#   0 = prerequisites satisfied
#   1 = one or more prerequisites missing
#   2 = invalid usage

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BASE_DIR="."
FROM_STAGE=""

usage() {
  cat <<'USAGE' >&2
Usage: check-run-from-prereqs.sh --from <stage> [--base-dir <path>]

Stages with deterministic checks:
  impl         : session plan.md exists and is non-empty
  review-code  : impl stage completed (not Skipped) + tracked git changes are committed
  refactor     : review-code stage completed (not Skipped)
  retro        : refactor stage has an explicit run result (including Skipped)
  ship         : retro stage has an explicit run result (including Skipped)

Other stages currently pass without extra checks.
USAGE
}

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

stage_outcomes() {
  local stage="$1"
  local file_path="$2"

  [[ -s "$file_path" ]] || return 0

  awk -F'|' -v target="$stage" '
    /^\|/ {
      stage=$2
      outcome=$9
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", stage)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", outcome)
      if (stage == target && outcome != "" && outcome != "Gate Outcome") {
        print outcome
      }
    }
  ' "$file_path"
}

has_stage_non_skipped() {
  local stage="$1"
  local file_path="$2"
  local outcome

  while IFS= read -r outcome; do
    outcome="$(trim "$outcome")"
    [[ -n "$outcome" ]] || continue
    if [[ "$outcome" != "Skipped" ]]; then
      return 0
    fi
  done < <(stage_outcomes "$stage" "$file_path")

  return 1
}

has_stage_any() {
  local stage="$1"
  local file_path="$2"
  local outcome

  while IFS= read -r outcome; do
    outcome="$(trim "$outcome")"
    [[ -n "$outcome" ]] || continue
    return 0
  done < <(stage_outcomes "$stage" "$file_path")

  return 1
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --from)
        [[ $# -ge 2 ]] || {
          echo "--from requires a value" >&2
          usage
          exit 2
        }
        FROM_STAGE="$2"
        shift 2
        ;;
      --base-dir)
        [[ $# -ge 2 ]] || {
          echo "--base-dir requires a value" >&2
          usage
          exit 2
        }
        BASE_DIR="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown argument: $1" >&2
        usage
        exit 2
        ;;
    esac
  done

  [[ -n "$FROM_STAGE" ]] || {
    echo "--from is required" >&2
    usage
    exit 2
  }
}

parse_args "$@"

session_dir="$(bash "$SCRIPT_DIR/cwf-live-state.sh" get "$BASE_DIR" dir 2>/dev/null || true)"
stage_provenance_file="$(bash "$SCRIPT_DIR/cwf-live-state.sh" get "$BASE_DIR" stage_provenance_file 2>/dev/null || true)"
if [[ -z "$stage_provenance_file" && -n "$session_dir" ]]; then
  stage_provenance_file="$session_dir/run-stage-provenance.md"
fi

declare -a CHECKS=()
declare -a MISSING=()

add_ok() {
  CHECKS+=("[ok] $1")
}

add_missing() {
  local message="$1"
  CHECKS+=("[missing] $message")
  MISSING+=("$message")
}

check_plan_file() {
  if [[ -z "$session_dir" ]]; then
    add_missing "live session directory is unavailable; cannot verify plan.md for --from impl"
    return
  fi

  local plan_file="$session_dir/plan.md"
  if [[ -s "$plan_file" ]]; then
    add_ok "plan artifact exists: ${plan_file#"$BASE_DIR"/}"
  else
    add_missing "plan artifact missing or empty: ${plan_file#"$BASE_DIR"/}"
  fi
}

require_provenance_file() {
  if [[ -z "$stage_provenance_file" || ! -f "$stage_provenance_file" ]]; then
    add_missing "run stage provenance file missing; expected: ${stage_provenance_file:-<unresolved>}"
    return 1
  fi
  add_ok "stage provenance file found: ${stage_provenance_file#"$BASE_DIR"/}"
  return 0
}

check_tracked_git_clean() {
  if git -C "$BASE_DIR" diff --quiet --exit-code && git -C "$BASE_DIR" diff --cached --quiet --exit-code; then
    add_ok "tracked git working tree is clean (no unstaged/staged changes)"
  else
    add_missing "tracked git working tree has uncommitted changes; commit implementation before --from review-code"
  fi
}

case "$FROM_STAGE" in
  impl)
    check_plan_file
    ;;
  review-code)
    if require_provenance_file; then
      if has_stage_non_skipped "impl" "$stage_provenance_file"; then
        add_ok "impl stage completion row exists (outcome != Skipped)"
      else
        add_missing "impl stage completion row not found (or only Skipped) in run-stage-provenance.md"
      fi
    fi
    check_tracked_git_clean
    ;;
  refactor)
    if require_provenance_file; then
      if has_stage_non_skipped "review-code" "$stage_provenance_file"; then
        add_ok "review-code stage completion row exists (outcome != Skipped)"
      else
        add_missing "review-code stage completion row not found (or only Skipped) in run-stage-provenance.md"
      fi
    fi
    ;;
  retro)
    if require_provenance_file; then
      if has_stage_any "refactor" "$stage_provenance_file"; then
        add_ok "refactor stage row exists (run or explicitly Skipped)"
      else
        add_missing "refactor stage row missing in run-stage-provenance.md"
      fi
    fi
    ;;
  ship)
    if require_provenance_file; then
      if has_stage_any "retro" "$stage_provenance_file"; then
        add_ok "retro stage row exists (run or explicitly Skipped)"
      else
        add_missing "retro stage row missing in run-stage-provenance.md"
      fi
    fi
    ;;
  gather|clarify|plan|review-plan)
    add_ok "no additional deterministic gate is required for --from $FROM_STAGE"
    ;;
  *)
    add_missing "unsupported --from stage: $FROM_STAGE"
    ;;
esac

if [[ "${#MISSING[@]}" -eq 0 ]]; then
  printf 'RUN_FROM_PRECHECK: PASS\n'
else
  printf 'RUN_FROM_PRECHECK: FAIL\n'
fi

printf 'from_stage=%s\n' "$FROM_STAGE"
printf 'session_dir=%s\n' "${session_dir:-<unresolved>}"
printf 'stage_provenance=%s\n' "${stage_provenance_file:-<unresolved>}"
printf '\nChecks:\n'
for line in "${CHECKS[@]}"; do
  printf '  - %s\n' "$line"
done

if [[ "${#MISSING[@]}" -eq 0 ]]; then
  exit 0
fi

exit 1
