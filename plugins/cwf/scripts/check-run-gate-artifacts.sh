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
RETRO_SOFT_WARNINGS=()
CONTRACT_STAGE_REVIEW_CODE="fail"
CONTRACT_STAGE_REFACTOR="fail"
CONTRACT_STAGE_RETRO="fail"
CONTRACT_STAGE_SHIP="fail"
CONTRACT_POLICY_PROVIDER_GEMINI_MODE="off"
PERSISTENCE_GATE="PASS"

# shellcheck source=plugins/cwf/scripts/check-run-gate-artifacts-lib.sh
source "$SCRIPT_DIR/check-run-gate-artifacts-lib.sh"

mark_soft_continue() {
  if [[ "$PERSISTENCE_GATE" != "HARD_FAIL" ]]; then
    PERSISTENCE_GATE="SOFT_CONTINUE"
  fi
}

append_retro_soft_warning() {
  local message="$1"
  RETRO_SOFT_WARNINGS+=("$message")
}

check_retro_critical_output() {
  local stage="$1"
  local file_path="$2"
  ensure_nonempty_file "$stage" "$file_path" || return 1
  require_agent_complete_sentinel "$stage" "$file_path" || return 1
  return 0
}

check_retro_noncritical_output() {
  local stage="$1"
  local file_path="$2"
  local rel="${file_path#"$SESSION_DIR"/}"

  if [[ ! -s "$file_path" ]]; then
    append_warn "$stage" "soft gate: non-critical artifact missing or empty: $rel (continue with omission note)"
    append_retro_soft_warning "$rel: missing or empty non-critical artifact"
    mark_soft_continue
    return 1
  fi
  append_pass "$stage" "artifact present: $rel"

  if grep -q '<!-- AGENT_COMPLETE -->' "$file_path" 2>/dev/null; then
    append_pass "$stage" "sentinel present: $rel"
    return 0
  fi

  append_warn "$stage" "soft gate: missing sentinel <!-- AGENT_COMPLETE --> in $rel (continue with omission note)"
  append_retro_soft_warning "$rel: missing sentinel <!-- AGENT_COMPLETE -->"
  mark_soft_continue
  return 1
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
  local noncritical_file=""
  local coverage_file=""
  local critical_file="$SESSION_DIR/retro-cdm-analysis.md"
  local noncritical_files=(
    "$SESSION_DIR/retro-learning-resources.md"
    "$SESSION_DIR/retro-expert-alpha.md"
    "$SESSION_DIR/retro-expert-beta.md"
  )
  local coverage_files=(
    "$SESSION_DIR/coverage/diff-all-excl-session-logs.txt"
    "$SESSION_DIR/coverage/diff-top-level-breakdown.txt"
    "$SESSION_DIR/coverage/project-lessons-retro-primary.txt"
  )

  ensure_nonempty_file "$stage" "$retro_file" || return 0
  mode_line="$(grep -im1 '^- Mode:' "$retro_file" || true)"
  if [[ -z "$mode_line" ]]; then
    append_fail "$stage" "retro.md missing '- Mode:' declaration"
    return 0
  fi

  append_pass "$stage" "mode declaration: $mode_line"
  if printf '%s' "$mode_line" | grep -Eiq 'deep'; then
    if grep -Eiq 'Coverage Matrix' "$retro_file"; then
      append_pass "$stage" "deep retro includes Coverage Matrix section"
    else
      append_fail "$stage" "deep retro missing Coverage Matrix section"
    fi

    for coverage_file in "${coverage_files[@]}"; do
      ensure_nonempty_file "$stage" "$coverage_file" || true
    done

    check_retro_critical_output "$stage" "$critical_file" || true
    for noncritical_file in "${noncritical_files[@]}"; do
      check_retro_noncritical_output "$stage" "$noncritical_file" || true
    done
  fi
}

check_ship_stage() {
  local stage="ship"
  local ship_file="$SESSION_DIR/ship.md"
  local stage_provenance_file="$SESSION_DIR/run-stage-provenance.md"
  local ambiguity_sync_script="$SCRIPT_DIR/sync-ambiguity-debt.sh"
  local ambiguity_sync_output=""
  local ambiguity_sync_summary=""
  local derived_blocking_count=""
  local derived_mode=""
  local sync_rc=0
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
    '^issue_ref: '
    '^pr_ref: '
    '^merge_allowed: (yes|no)$'
  )
  local mode=""
  local blocking_open_count_raw=""
  local blocking_open_count=0
  local issue_ref=""
  local pr_ref=""
  local merge_allowed=""
  local current_branch=""
  local resolved_base_branch=""
  local stage_provenance_header_seen=0
  local stage_provenance_schema_seen=0

  ensure_nonempty_file "$stage" "$stage_provenance_file" || true
  if [[ -s "$stage_provenance_file" ]]; then
    if grep -Fqx "$stage_provenance_header" "$stage_provenance_file"; then
      append_pass "$stage" "stage provenance header contract present"
      stage_provenance_header_seen=1
    else
      append_fail "$stage" "run-stage-provenance.md missing required header row"
    fi

    if grep -Fqx "$stage_provenance_schema" "$stage_provenance_file"; then
      append_pass "$stage" "stage provenance schema divider present"
      stage_provenance_schema_seen=1
    else
      append_fail "$stage" "run-stage-provenance.md missing required schema divider row"
    fi

    if [[ "$stage_provenance_header_seen" -eq 1 && "$stage_provenance_schema_seen" -eq 1 ]]; then
      stage_provenance_row_count="$(awk -v header_row="$stage_provenance_header" -v schema_row="$stage_provenance_schema" '
        $0 == header_row { header_seen=1; next }
        header_seen && $0 == schema_row { schema_seen=1; next }
        schema_seen && /^\|.*\|$/ {
          row = $0
          pipe_count = gsub(/\|/, "", row)
          if (pipe_count == 9) {
            split($0, cols, "|")
            stage_value = cols[2]
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", stage_value)
            if (stage_value != "" && stage_value !~ /^-+$/) {
              count += 1
            }
          }
        }
        END { print count + 0 }
      ' "$stage_provenance_file")"
      if [[ "$stage_provenance_row_count" -gt 0 ]]; then
        append_pass "$stage" "stage provenance has at least one data row"
      else
        append_fail "$stage" "run-stage-provenance.md must include at least one data row"
      fi
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
  issue_ref="$(grep -E '^issue_ref: ' "$ship_file" | head -n 1 | sed 's/^issue_ref:[[:space:]]*//')"
  pr_ref="$(grep -E '^pr_ref: ' "$ship_file" | head -n 1 | sed 's/^pr_ref:[[:space:]]*//')"
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

  current_branch="$(git -C "$BASE_DIR" branch --show-current 2>/dev/null || true)"
  resolved_base_branch="$(git -C "$BASE_DIR" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || true)"
  if [[ -z "$resolved_base_branch" ]]; then
    if git -C "$BASE_DIR" show-ref --verify --quiet refs/heads/main; then
      resolved_base_branch="main"
    elif git -C "$BASE_DIR" show-ref --verify --quiet refs/heads/master; then
      resolved_base_branch="master"
    fi
  fi

  if [[ -n "$current_branch" && -n "$resolved_base_branch" ]]; then
    if [[ "$current_branch" != "$resolved_base_branch" ]]; then
      if [[ "$issue_ref" == "none" || -z "$issue_ref" ]]; then
        append_fail "$stage" "non-base ship requires issue_ref URL (branch=$current_branch base=$resolved_base_branch)"
      elif [[ "$issue_ref" =~ ^https://github\.com/[^/]+/[^/]+/issues/[0-9]+$ ]]; then
        append_pass "$stage" "issue_ref URL present for non-base ship"
      else
        append_fail "$stage" "invalid issue_ref URL format: $issue_ref"
      fi

      if [[ "$pr_ref" == "none" || -z "$pr_ref" ]]; then
        append_fail "$stage" "non-base ship requires pr_ref URL (branch=$current_branch base=$resolved_base_branch)"
      elif [[ "$pr_ref" =~ ^https://github\.com/[^/]+/[^/]+/pull/[0-9]+$ ]]; then
        append_pass "$stage" "pr_ref URL present for non-base ship"
      else
        append_fail "$stage" "invalid pr_ref URL format: $pr_ref"
      fi
    else
      append_pass "$stage" "base-branch ship detected; issue/pr URL requirement skipped"
    fi
  else
    append_warn "$stage" "base/non-base branch policy check skipped (branch or base unresolved)"
  fi

  if [[ -x "$ambiguity_sync_script" ]]; then
    set +e
    ambiguity_sync_output="$(bash "$ambiguity_sync_script" --base-dir "$BASE_DIR" --session-dir "$SESSION_DIR" --check-only 2>&1)"
    sync_rc=$?
    set -e

    if [[ "$sync_rc" -ne 0 ]]; then
      ambiguity_sync_summary="$(printf '%s' "$ambiguity_sync_output" | tr '\n' '; ' | sed 's/; $//')"
      append_fail "$stage" "ambiguity debt sync check failed: ${ambiguity_sync_summary:-unknown}"
      return 0
    fi

    append_pass "$stage" "ambiguity debt state synchronized with live state"
    derived_blocking_count="$(
      printf '%s\n' "$ambiguity_sync_output" \
        | sed -n -E 's/^blocking_open_count:[[:space:]]*([0-9]+)$/\1/p' \
        | head -n 1
    )"
    derived_mode="$(printf '%s\n' "$ambiguity_sync_output" | sed -n -E 's/^mode:[[:space:]]*(.*)$/\1/p' | head -n 1)"

    if [[ -n "$derived_blocking_count" && "$derived_blocking_count" -ne "$blocking_open_count" ]]; then
      append_fail "$stage" "ship.md blocking_open_count mismatch (ship=$blocking_open_count derived=$derived_blocking_count)"
    else
      append_pass "$stage" "ship.md blocking_open_count aligned with ambiguity ledger"
    fi

    if [[ -n "$derived_mode" && "$derived_mode" != "$mode" ]]; then
      append_fail "$stage" "ship.md mode mismatch (ship=$mode derived=$derived_mode)"
    else
      append_pass "$stage" "ship.md mode aligned with ambiguity ledger/live mode"
    fi
  else
    append_warn "$stage" "sync-ambiguity-debt.sh unavailable; skipped ambiguity synchronization check"
  fi
}

record_lessons_failure() {
  local lessons_file="$SESSION_DIR/lessons.md"
  local ts=""
  local item=""

  [[ "$RECORD_LESSONS" == true ]] || return 0
  if [[ "${#FAILS[@]}" -eq 0 && "${#RETRO_SOFT_WARNINGS[@]}" -eq 0 ]]; then
    return 0
  fi

  ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  if [[ ! -f "$lessons_file" ]]; then
    cat > "$lessons_file" <<'EOF_LESSONS'
# Lessons

EOF_LESSONS
  fi

  {
    if [[ "${#FAILS[@]}" -gt 0 ]]; then
      printf '\n## Run Gate Violation — %s\n' "$ts"
    else
      printf '\n## Run Gate Soft Continue — %s\n' "$ts"
    fi
    printf -- "- **Owner**: \`plugin\`\n"
    printf -- "- **Apply Layer**: \`upstream\`\n"
    printf -- "- **Promotion Target**: \`plugins/cwf/scripts/check-run-gate-artifacts.sh\`\n"
    printf -- "- **Due Release**: \`next-release\`\n"
    printf -- "- Gate checker: \`%s\`\n" "plugins/cwf/scripts/check-run-gate-artifacts.sh"
    printf -- "- Persistence gate: \`%s\`\n" "$PERSISTENCE_GATE"
    if [[ "${#FAILS[@]}" -gt 0 ]]; then
      printf -- '- Recorded failures:\n'
      for item in "${FAILS[@]}"; do
        printf '  - %s\n' "$item"
      done
    fi
    if [[ "${#RETRO_SOFT_WARNINGS[@]}" -gt 0 ]]; then
      printf -- '- Retro soft-gate omissions (SOFT_CONTINUE):\n'
      for item in "${RETRO_SOFT_WARNINGS[@]}"; do
        printf '  - %s\n' "$item"
      done
    fi
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

if [[ "${#FAILS[@]}" -gt 0 ]]; then
  PERSISTENCE_GATE="HARD_FAIL"
fi

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
echo "  PERSISTENCE_GATE=$PERSISTENCE_GATE"
if [[ "${#RETRO_SOFT_WARNINGS[@]}" -gt 0 ]]; then
  echo "  Retro soft-gate omissions (PERSISTENCE_GATE=SOFT_CONTINUE):"
  for item in "${RETRO_SOFT_WARNINGS[@]}"; do
    echo "    - $item"
  done
fi

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
