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
  --contract <path>      Contract file (YAML) overriding stage/policy modes
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
CONTRACT_PATH=""
CONTRACT_SOURCE="builtin-defaults"
STRICT=false
RECORD_LESSONS=false
STAGES=()
FAILS=()
WARNS=()
PASSES=()
CONTRACT_STAGE_REVIEW_CODE="fail"
CONTRACT_STAGE_REFACTOR="fail"
CONTRACT_STAGE_RETRO="fail"
CONTRACT_STAGE_SHIP="fail"
CONTRACT_POLICY_PROVIDER_GEMINI_MODE="off"
CONTRACT_POLICY_REFACTOR_SKILL_COVERAGE_MODE="off"
CONTRACT_POLICY_REFACTOR_EXPECTED_SKILLS=()

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

list_contains() {
  local needle="$1"
  shift || true
  local item=""
  for item in "$@"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

normalize_mode() {
  local raw="$1"
  local fallback="$2"
  local mode
  mode="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')"
  case "$mode" in
    off|warn|fail)
      printf '%s\n' "$mode"
      ;;
    *)
      printf '%s\n' "$fallback"
      ;;
  esac
}

resolve_contract_file() {
  if [[ -n "$CONTRACT_PATH" ]]; then
    if [[ "$CONTRACT_PATH" != /* ]]; then
      CONTRACT_PATH="$REPO_ROOT/$CONTRACT_PATH"
    fi
    if [[ ! -f "$CONTRACT_PATH" ]]; then
      append_fail "contract" "explicit contract file not found: $CONTRACT_PATH"
      return 1
    fi
    CONTRACT_SOURCE="explicit"
    return 0
  fi

  if [[ -f "$SESSION_DIR/gate-contract.yaml" ]]; then
    CONTRACT_PATH="$SESSION_DIR/gate-contract.yaml"
    CONTRACT_SOURCE="session"
    return 0
  fi

  if [[ -f "$REPO_ROOT/.cwf/gate-contract.yaml" ]]; then
    CONTRACT_PATH="$REPO_ROOT/.cwf/gate-contract.yaml"
    CONTRACT_SOURCE="project"
    return 0
  fi

  CONTRACT_PATH=""
  CONTRACT_SOURCE="builtin-defaults"
  return 0
}

load_contract() {
  local line=""
  local section=""
  local key=""
  local value=""
  local skill_raw=""
  local skill=""
  local mode=""
  local stage_line_re='^[[:space:]]{2}(review-code|refactor|retro|ship):[[:space:]]*([A-Za-z_-]+)[[:space:]]*$'

  [[ -n "$CONTRACT_PATH" ]] || return 0

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="$(printf '%s' "$line" | sed 's/[[:space:]]*$//')"
    [[ -n "$line" ]] || continue

    if [[ "$line" =~ ^stages:[[:space:]]*$ ]]; then
      section="stages"
      continue
    fi
    if [[ "$line" =~ ^policies:[[:space:]]*$ ]]; then
      section="policies"
      continue
    fi

    if [[ "$section" == "stages" && "$line" =~ $stage_line_re ]]; then
      key="${BASH_REMATCH[1]}"
      value="${BASH_REMATCH[2]}"
      mode="$(normalize_mode "$value" "fail")"
      case "$key" in
        review-code) CONTRACT_STAGE_REVIEW_CODE="$mode" ;;
        refactor) CONTRACT_STAGE_REFACTOR="$mode" ;;
        retro) CONTRACT_STAGE_RETRO="$mode" ;;
        ship) CONTRACT_STAGE_SHIP="$mode" ;;
      esac
      continue
    fi

    if [[ "$section" == "policies" && "$line" =~ ^[[:space:]]{2}provider_gemini_mode:[[:space:]]*([A-Za-z_-]+)[[:space:]]*$ ]]; then
      CONTRACT_POLICY_PROVIDER_GEMINI_MODE="$(normalize_mode "${BASH_REMATCH[1]}" "off")"
      continue
    fi
    if [[ "$section" == "policies" && "$line" =~ ^[[:space:]]{2}refactor_skill_coverage_mode:[[:space:]]*([A-Za-z_-]+)[[:space:]]*$ ]]; then
      CONTRACT_POLICY_REFACTOR_SKILL_COVERAGE_MODE="$(normalize_mode "${BASH_REMATCH[1]}" "off")"
      continue
    fi
    if [[ "$section" == "policies" && "$line" =~ ^[[:space:]]{2}refactor_expected_skills:[[:space:]]*\[(.*)\][[:space:]]*$ ]]; then
      CONTRACT_POLICY_REFACTOR_EXPECTED_SKILLS=()
      while IFS= read -r skill_raw; do
        skill="$(printf '%s' "$skill_raw" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | tr '[:upper:]' '[:lower:]')"
        [[ -n "$skill" ]] || continue
        CONTRACT_POLICY_REFACTOR_EXPECTED_SKILLS+=("$skill")
      done < <(printf '%s' "${BASH_REMATCH[1]}" | tr ',' '\n')
      continue
    fi
  done < "$CONTRACT_PATH"
}

contract_stage_mode() {
  local stage="$1"
  case "$stage" in
    review-code) printf '%s\n' "$CONTRACT_STAGE_REVIEW_CODE" ;;
    refactor) printf '%s\n' "$CONTRACT_STAGE_REFACTOR" ;;
    retro) printf '%s\n' "$CONTRACT_STAGE_RETRO" ;;
    ship) printf '%s\n' "$CONTRACT_STAGE_SHIP" ;;
    *) printf 'fail\n' ;;
  esac
}

downgrade_stage_fails_to_warn() {
  local stage="$1"
  local fail_before="$2"
  local item=""
  local idx=0
  local kept=()

  for item in "${FAILS[@]}"; do
    if (( idx >= fail_before )) && [[ "$item" == "[$stage]"* ]]; then
      append_warn "$stage" "downgraded by contract(mode=warn): $item"
    else
      kept+=("$item")
    fi
    idx=$((idx + 1))
  done
  FAILS=("${kept[@]}")
}

run_stage_with_contract_mode() {
  local stage="$1"
  local mode=""
  local fail_before=0

  mode="$(contract_stage_mode "$stage")"
  case "$mode" in
    off)
      append_warn "$stage" "stage validation skipped by contract (mode=off)"
      return 0
      ;;
    warn|fail)
      ;;
    *)
      mode="fail"
      ;;
  esac

  fail_before=${#FAILS[@]}
  case "$stage" in
    review-code) check_review_code_stage ;;
    refactor) check_refactor_stage ;;
    retro) check_retro_stage ;;
    ship) check_ship_stage ;;
    *)
      append_fail "$stage" "unsupported stage (allowed: review-code|refactor|retro|ship)"
      ;;
  esac

  if [[ "$mode" == "warn" ]]; then
    downgrade_stage_fails_to_warn "$stage" "$fail_before"
  fi
}

apply_provider_gemini_policy() {
  local mode="$CONTRACT_POLICY_PROVIDER_GEMINI_MODE"
  local stage="policy-provider-gemini"
  local file=""
  local found=false
  local hits=()

  case "$mode" in
    off) return 0 ;;
    warn|fail) ;;
    *) mode="off" ;;
  esac

  if ! list_contains "review-code" "${STAGES[@]}"; then
    return 0
  fi

  shopt -s nullglob
  for file in "$SESSION_DIR"/review-correctness-*.md "$SESSION_DIR"/review-architecture-*.md; do
    [[ -f "$file" ]] || continue
    found=true
    if grep -Eiq '^tool:[[:space:]]*gemini([[:space:]]|$)' "$file"; then
      hits+=("${file#"$SESSION_DIR"/}")
    fi
  done
  shopt -u nullglob

  if [[ "$found" == false ]]; then
    append_warn "$stage" "policy enabled but no external review provenance files found"
    return 0
  fi

  if [[ "${#hits[@]}" -eq 0 ]]; then
    append_pass "$stage" "gemini provider not detected in external reviewer provenance"
    return 0
  fi

  if [[ "$mode" == "fail" ]]; then
    append_fail "$stage" "gemini provider detected: ${hits[*]}"
  else
    append_warn "$stage" "gemini provider detected: ${hits[*]}"
  fi
}

apply_refactor_skill_coverage_policy() {
  local mode="$CONTRACT_POLICY_REFACTOR_SKILL_COVERAGE_MODE"
  local stage="policy-refactor-skill-coverage"
  local skill=""
  local file=""
  local missing=()

  case "$mode" in
    off) return 0 ;;
    warn|fail) ;;
    *) mode="off" ;;
  esac

  if ! list_contains "refactor" "${STAGES[@]}"; then
    return 0
  fi

  if [[ "${#CONTRACT_POLICY_REFACTOR_EXPECTED_SKILLS[@]}" -eq 0 ]]; then
    append_warn "$stage" "coverage policy enabled but refactor_expected_skills is empty"
    return 0
  fi

  for skill in "${CONTRACT_POLICY_REFACTOR_EXPECTED_SKILLS[@]}"; do
    file="$SESSION_DIR/refactor-skill-$skill.md"
    if [[ ! -s "$file" ]]; then
      missing+=("refactor-skill-$skill.md")
    fi
  done

  if [[ "${#missing[@]}" -eq 0 ]]; then
    append_pass "$stage" "all expected per-skill refactor outputs are present"
    return 0
  fi

  if [[ "$mode" == "fail" ]]; then
    append_fail "$stage" "missing expected per-skill outputs: ${missing[*]}"
  else
    append_warn "$stage" "missing expected per-skill outputs: ${missing[*]}"
  fi
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
  local codebase_scan_json="$SESSION_DIR/refactor-codebase-scan.json"
  local codebase_experts_json="$SESSION_DIR/refactor-codebase-experts.json"
  local deep_file=""
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

  if [[ -s "$codebase_scan_json" ]]; then
    has_any=true
    append_pass "$stage" "artifact present: refactor-codebase-scan.json"
    if command -v jq >/dev/null 2>&1; then
      if jq -e '.summary and .findings and .contract and .scope' "$codebase_scan_json" >/dev/null; then
        append_pass "$stage" "codebase-scan JSON schema check passed"
      else
        append_fail "$stage" "codebase-scan JSON missing required keys (.summary/.findings/.contract/.scope)"
      fi
    else
      append_warn "$stage" "jq not available; skipped codebase-scan JSON schema check"
    fi
  fi

  if [[ -s "$codebase_experts_json" ]]; then
    has_any=true
    append_pass "$stage" "artifact present: refactor-codebase-experts.json"
    if command -v jq >/dev/null 2>&1; then
      if jq -e '.selected and .fixed and .contextual' "$codebase_experts_json" >/dev/null; then
        append_pass "$stage" "codebase-experts JSON schema check passed"
      else
        append_fail "$stage" "codebase-experts JSON missing required keys (.selected/.fixed/.contextual)"
      fi
    else
      append_warn "$stage" "jq not available; skipped codebase-experts JSON schema check"
    fi
  fi

  shopt -s nullglob
  for deep_file in "$SESSION_DIR"/refactor-deep-structural*.md; do
    [[ -s "$deep_file" ]] || continue
    has_any=true
    append_pass "$stage" "artifact present: ${deep_file#"$SESSION_DIR"/}"
    require_agent_complete_sentinel "$stage" "$deep_file" || true
  done
  for deep_file in "$SESSION_DIR"/refactor-deep-quality*.md; do
    [[ -s "$deep_file" ]] || continue
    has_any=true
    append_pass "$stage" "artifact present: ${deep_file#"$SESSION_DIR"/}"
    require_agent_complete_sentinel "$stage" "$deep_file" || true
  done
  local tidy_file=""
  for tidy_file in "$SESSION_DIR"/refactor-tidy-commit-*.md; do
    has_any=true
    append_pass "$stage" "artifact present: ${tidy_file#"$SESSION_DIR"/}"
    require_agent_complete_sentinel "$stage" "$tidy_file" || true
  done
  for deep_file in "$SESSION_DIR"/refactor-codebase-deep-*.md; do
    [[ -s "$deep_file" ]] || continue
    has_any=true
    append_pass "$stage" "artifact present: ${deep_file#"$SESSION_DIR"/}"
    require_agent_complete_sentinel "$stage" "$deep_file" || true
  done
  shopt -u nullglob

  if [[ "$has_any" == false ]]; then
    append_fail "$stage" "no refactor artifact found (expected summary/quick-scan/codebase-scan/codebase-experts/deep/tidy outputs)"
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
  local stage_provenance_file="$SESSION_DIR/run-stage-provenance.md"
  local stage_provenance_header='| Stage | Skill | Args | Started At (UTC) | Finished At (UTC) | Duration (s) | Artifacts | Gate Outcome |'
  local stage_provenance_schema='|---|---|---|---|---|---|---|---|'
  local stage_provenance_row_count=0
  local required_pattern=""
  local required_patterns=(
    '^## Execution Status'
    '^## Ambiguity Resolution'
    '^## Next Step'
    '^mode: (strict|defer-blocking|defer-reversible|explore-worktrees)$'
    '^blocking_open_count: [0-9]+$'
    '^blocking_issue_refs: '
    '^merge_allowed: (yes|no)$'
  )
  local mode=""
  local blocking_open_count_raw=""
  local blocking_open_count=0
  local merge_allowed=""

  ensure_nonempty_file "$stage" "$stage_provenance_file" || true
  if [[ -s "$stage_provenance_file" ]]; then
    if grep -Fqx "$stage_provenance_header" "$stage_provenance_file"; then
      append_pass "$stage" "stage provenance header contract present"
    else
      append_fail "$stage" "run-stage-provenance.md missing required header row"
    fi

    if grep -Fqx "$stage_provenance_schema" "$stage_provenance_file"; then
      append_pass "$stage" "stage provenance schema divider present"
    else
      append_fail "$stage" "run-stage-provenance.md missing required schema divider row"
    fi

    local stage_header_re='^\| Stage \| Skill \| Args \| Started At \(UTC\) \| Finished At \(UTC\) \|'
    stage_header_re+=' Duration \(s\) \| Artifacts \| Gate Outcome \|$'
    stage_provenance_row_count="$(awk -v header_re="$stage_header_re" '
      $0 ~ header_re { header_seen=1; next }
      header_seen && /^\|---\|---\|---\|---\|---\|---\|---\|---\|$/ { schema_seen=1; next }
      schema_seen && /^\|([^|]*\|){8}$/ { count += 1 }
      END { print count + 0 }
    ' "$stage_provenance_file")"
    if [[ "$stage_provenance_row_count" -gt 0 ]]; then
      append_pass "$stage" "stage provenance has at least one data row"
    else
      append_fail "$stage" "run-stage-provenance.md must include at least one data row"
    fi
  fi

  ensure_nonempty_file "$stage" "$ship_file" || return 0

  for required_pattern in "${required_patterns[@]}"; do
    if grep -Eq "$required_pattern" "$ship_file"; then
      append_pass "$stage" "ship pattern present: $required_pattern"
    else
      append_fail "$stage" "ship.md missing required pattern: $required_pattern"
    fi
  done

  mode="$(grep -E '^mode: ' "$ship_file" | head -n 1 | sed 's/^mode:[[:space:]]*//')"
  blocking_open_count_raw="$(grep -E '^blocking_open_count: ' "$ship_file" | head -n 1 | sed 's/^blocking_open_count:[[:space:]]*//')"
  merge_allowed="$(grep -E '^merge_allowed: ' "$ship_file" | head -n 1 | sed 's/^merge_allowed:[[:space:]]*//')"

  if [[ "$blocking_open_count_raw" =~ ^[0-9]+$ ]]; then
    blocking_open_count="$blocking_open_count_raw"
  else
    append_fail "$stage" "invalid blocking_open_count value: ${blocking_open_count_raw:-<empty>}"
    return 0
  fi

  if [[ "$mode" == "defer-blocking" && "$blocking_open_count" -gt 0 ]]; then
    if [[ "$merge_allowed" == "no" ]]; then
      append_pass "$stage" "defer-blocking debt correctly marks merge_allowed: no"
    else
      append_fail "$stage" "defer-blocking with open debt must set merge_allowed: no"
    fi
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
    --contract)
      if [[ $# -lt 2 ]]; then
        echo "--contract requires a value" >&2
        exit 2
      fi
      CONTRACT_PATH="$2"
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

if ! resolve_contract_file; then
  record_lessons_failure
  if [[ "$STRICT" == true ]]; then
    exit 1
  fi
  exit 0
fi
load_contract

for stage in "${STAGES[@]}"; do
  run_stage_with_contract_mode "$stage"
done

apply_provider_gemini_policy
apply_refactor_skill_coverage_policy

echo "Run gate artifact check"
echo "  session_dir : ${SESSION_DIR#"$REPO_ROOT"/}"
echo "  stages      : ${STAGES[*]}"
if [[ -n "$CONTRACT_PATH" ]]; then
  if [[ "$CONTRACT_PATH" == "$REPO_ROOT/"* ]]; then
    echo "  contract    : ${CONTRACT_SOURCE}:${CONTRACT_PATH#"$REPO_ROOT"/}"
  else
    echo "  contract    : ${CONTRACT_SOURCE}:${CONTRACT_PATH}"
  fi
else
  echo "  contract    : ${CONTRACT_SOURCE}"
fi
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
