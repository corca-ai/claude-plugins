#!/usr/bin/env bash
set -euo pipefail

# check-run-gate-artifacts.sh — deterministic artifact gate for cwf:run stages.
#
# Validates stage completion artifacts for:
#   review-code, refactor, retro, ship
#
# Usage:
#   check-run-gate-artifacts.sh --stage review-code --session-dir .cwf/projects/...
#   check-run-gate-artifacts.sh --stage retro --strict --record-lessons

usage() {
  cat <<'USAGE'
check-run-gate-artifacts.sh — validate cwf:run stage artifacts

Usage:
  check-run-gate-artifacts.sh [options]

Options:
  --stage <name>         Stage to validate (repeatable): review-code|refactor|retro|ship
  --session-dir <path>   Session directory to validate (default: resolve from live state)
  --base-dir <path>      Base directory for live-state resolution (default: .)
  --strict               Exit non-zero when any check fails
  --record-lessons       Append failure summary to {session-dir}/lessons.md
  -h, --help             Show this help
USAGE
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || (cd "$SCRIPT_DIR/../../.." && pwd))"
LIVE_STATE_SCRIPT="$SCRIPT_DIR/cwf-live-state.sh"

BASE_DIR="."
SESSION_DIR=""
STRICT=false
RECORD_LESSONS=false
STAGES=()
FAILS=()
WARNS=()
PASSES=()

append_fail() {
  local stage="$1"
  local msg="$2"
  FAILS+=("[$stage] $msg")
}

append_warn() {
  local stage="$1"
  local msg="$2"
  WARNS+=("[$stage] $msg")
}

append_pass() {
  local stage="$1"
  local msg="$2"
  PASSES+=("[$stage] $msg")
}

ensure_nonempty_file() {
  local stage="$1"
  local file_path="$2"
  if [[ -s "$file_path" ]]; then
    append_pass "$stage" "artifact present: ${file_path#"$SESSION_DIR"/}"
    return 0
  fi
  append_fail "$stage" "artifact missing or empty: ${file_path#"$SESSION_DIR"/}"
  return 1
}

require_agent_complete_sentinel() {
  local stage="$1"
  local file_path="$2"
  if grep -q '<!-- AGENT_COMPLETE -->' "$file_path" 2>/dev/null; then
    append_pass "$stage" "sentinel present: ${file_path#"$SESSION_DIR"/}"
    return 0
  fi
  append_fail "$stage" "missing sentinel <!-- AGENT_COMPLETE --> in ${file_path#"$SESSION_DIR"/}"
  return 1
}

resolve_session_dir() {
  local raw_dir=""
  if [[ -n "$SESSION_DIR" ]]; then
    return 0
  fi
  if [[ ! -x "$LIVE_STATE_SCRIPT" ]]; then
    append_fail "global" "live-state resolver not found: $LIVE_STATE_SCRIPT"
    return 1
  fi
  raw_dir="$(bash "$LIVE_STATE_SCRIPT" get "$BASE_DIR" dir 2>/dev/null || true)"
  if [[ -z "$raw_dir" ]]; then
    append_fail "global" "unable to resolve session dir from live state"
    return 1
  fi
  if [[ "$raw_dir" == /* ]]; then
    SESSION_DIR="$raw_dir"
  else
    SESSION_DIR="$REPO_ROOT/$raw_dir"
  fi
  return 0
}

check_review_code_stage() {
  local stage="review-code"
  local synthesis_file="$SESSION_DIR/review-synthesis-code.md"
  local slot_file=""
  local slot_files=(
    "$SESSION_DIR/review-security-code.md"
    "$SESSION_DIR/review-ux-dx-code.md"
    "$SESSION_DIR/review-correctness-code.md"
    "$SESSION_DIR/review-architecture-code.md"
    "$SESSION_DIR/review-expert-alpha-code.md"
    "$SESSION_DIR/review-expert-beta-code.md"
  )
  local required_pattern=""
  local required_patterns=(
    '^## Review Synthesis'
    '^### Verdict: '
    'session_log_present: '
    'session_log_lines: '
    'session_log_turns: '
    'session_log_last_turn: '
    'session_log_cross_check: '
  )

  for slot_file in "${slot_files[@]}"; do
    ensure_nonempty_file "$stage" "$slot_file" || true
    require_agent_complete_sentinel "$stage" "$slot_file" || true
  done

  ensure_nonempty_file "$stage" "$synthesis_file" || return 0
  for required_pattern in "${required_patterns[@]}"; do
    if grep -Eq "$required_pattern" "$synthesis_file"; then
      append_pass "$stage" "synthesis pattern present: $required_pattern"
    else
      append_fail "$stage" "synthesis missing required pattern: $required_pattern"
    fi
  done
}

check_refactor_stage() {
  local stage="refactor"
  local summary_file="$SESSION_DIR/refactor-summary.md"
  local quick_scan_json="$SESSION_DIR/refactor-quick-scan.json"
  local deep_structural="$SESSION_DIR/refactor-deep-structural.md"
  local deep_quality="$SESSION_DIR/refactor-deep-quality.md"
  local has_any=false

  if [[ -s "$summary_file" ]]; then
    has_any=true
    append_pass "$stage" "artifact present: refactor-summary.md"
    if grep -Eq '^## Refactor Summary' "$summary_file"; then
      append_pass "$stage" "summary heading contract present"
    else
      append_fail "$stage" "refactor-summary.md missing heading: ## Refactor Summary"
    fi
  fi

  if [[ -s "$quick_scan_json" ]]; then
    has_any=true
    append_pass "$stage" "artifact present: refactor-quick-scan.json"
    if command -v jq >/dev/null 2>&1; then
      if jq -e '.total_skills and .results' "$quick_scan_json" >/dev/null; then
        append_pass "$stage" "quick-scan JSON schema check passed"
      else
        append_fail "$stage" "quick-scan JSON missing required keys (.total_skills/.results)"
      fi
    else
      append_warn "$stage" "jq not available; skipped quick-scan JSON schema check"
    fi
  fi

  if [[ -s "$deep_structural" ]]; then
    has_any=true
    append_pass "$stage" "artifact present: refactor-deep-structural.md"
    require_agent_complete_sentinel "$stage" "$deep_structural" || true
  fi
  if [[ -s "$deep_quality" ]]; then
    has_any=true
    append_pass "$stage" "artifact present: refactor-deep-quality.md"
    require_agent_complete_sentinel "$stage" "$deep_quality" || true
  fi

  shopt -s nullglob
  local tidy_file=""
  for tidy_file in "$SESSION_DIR"/refactor-tidy-commit-*.md; do
    has_any=true
    append_pass "$stage" "artifact present: ${tidy_file#"$SESSION_DIR"/}"
    require_agent_complete_sentinel "$stage" "$tidy_file" || true
  done
  shopt -u nullglob

  if [[ "$has_any" == false ]]; then
    append_fail "$stage" "no refactor artifact found (expected summary/quick-scan/deep/tidy outputs)"
  fi
}

check_retro_stage() {
  local stage="retro"
  local retro_file="$SESSION_DIR/retro.md"
  local mode_line=""
  local deep_file=""
  local deep_files=(
    "$SESSION_DIR/retro-cdm-analysis.md"
    "$SESSION_DIR/retro-learning-resources.md"
    "$SESSION_DIR/retro-expert-alpha.md"
    "$SESSION_DIR/retro-expert-beta.md"
  )

  ensure_nonempty_file "$stage" "$retro_file" || return 0
  mode_line="$(grep -im1 '^- Mode:' "$retro_file" || true)"
  if [[ -z "$mode_line" ]]; then
    append_fail "$stage" "retro.md missing '- Mode:' declaration"
    return 0
  fi

  append_pass "$stage" "mode declaration: $mode_line"
  if printf '%s' "$mode_line" | grep -Eiq 'deep'; then
    for deep_file in "${deep_files[@]}"; do
      ensure_nonempty_file "$stage" "$deep_file" || true
      require_agent_complete_sentinel "$stage" "$deep_file" || true
    done
  fi
}

check_ship_stage() {
  local stage="ship"
  local ship_file="$SESSION_DIR/ship.md"

  ensure_nonempty_file "$stage" "$ship_file" || return 0
  if grep -Eq '^## Execution Status' "$ship_file"; then
    append_pass "$stage" "ship execution status block present"
  else
    append_fail "$stage" "ship.md missing section: ## Execution Status"
  fi
}

record_lessons_failure() {
  local lessons_file="$SESSION_DIR/lessons.md"
  local ts=""
  local item=""

  [[ "$RECORD_LESSONS" == true ]] || return 0
  [[ "${#FAILS[@]}" -gt 0 ]] || return 0

  ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  if [[ ! -f "$lessons_file" ]]; then
    cat > "$lessons_file" <<'EOF_LESSONS'
# Lessons

EOF_LESSONS
  fi

  {
    printf '\n## Run Gate Violation — %s\n' "$ts"
    printf -- "- Gate checker: \`%s\`\n" "plugins/cwf/scripts/check-run-gate-artifacts.sh"
    printf -- '- Recorded failures:\n'
    for item in "${FAILS[@]}"; do
      printf '  - %s\n' "$item"
    done
  } >> "$lessons_file"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --stage)
      if [[ $# -lt 2 ]]; then
        echo "--stage requires a value" >&2
        exit 2
      fi
      STAGES+=("$2")
      shift 2
      ;;
    --session-dir)
      if [[ $# -lt 2 ]]; then
        echo "--session-dir requires a value" >&2
        exit 2
      fi
      SESSION_DIR="$2"
      shift 2
      ;;
    --base-dir)
      if [[ $# -lt 2 ]]; then
        echo "--base-dir requires a value" >&2
        exit 2
      fi
      BASE_DIR="$2"
      shift 2
      ;;
    --strict)
      STRICT=true
      shift
      ;;
    --record-lessons)
      RECORD_LESSONS=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ "${#STAGES[@]}" -eq 0 ]]; then
  STAGES=(review-code refactor retro ship)
fi

if ! resolve_session_dir; then
  record_lessons_failure
  if [[ "$STRICT" == true ]]; then
    exit 1
  fi
  exit 0
fi

if [[ "$SESSION_DIR" != /* ]]; then
  SESSION_DIR="$REPO_ROOT/$SESSION_DIR"
fi

if [[ ! -d "$SESSION_DIR" ]]; then
  append_fail "global" "session dir not found: $SESSION_DIR"
  record_lessons_failure
  if [[ "$STRICT" == true ]]; then
    exit 1
  fi
  exit 0
fi

for stage in "${STAGES[@]}"; do
  case "$stage" in
    review-code)
      check_review_code_stage
      ;;
    refactor)
      check_refactor_stage
      ;;
    retro)
      check_retro_stage
      ;;
    ship)
      check_ship_stage
      ;;
    *)
      append_fail "$stage" "unsupported stage (allowed: review-code|refactor|retro|ship)"
      ;;
  esac
done

echo "Run gate artifact check"
echo "  session_dir : ${SESSION_DIR#"$REPO_ROOT"/}"
echo "  stages      : ${STAGES[*]}"
echo "  pass        : ${#PASSES[@]}"
echo "  warn        : ${#WARNS[@]}"
echo "  fail        : ${#FAILS[@]}"

for item in "${WARNS[@]}"; do
  echo "[WARN] $item"
done
for item in "${FAILS[@]}"; do
  echo "[FAIL] $item"
done

record_lessons_failure

if [[ "${#FAILS[@]}" -gt 0 && "$STRICT" == true ]]; then
  exit 1
fi

exit 0
