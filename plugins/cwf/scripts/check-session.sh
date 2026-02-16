#!/usr/bin/env bash
set -euo pipefail

# check-session.sh — Verify session completion artifacts
# Usage: check-session.sh [--impl|--live|--semantic-gap] [session-id|session-dir]
#   --impl    Check impl_complete artifacts only (plan.md, lessons.md, next-session.md)
#             Use after implementation, before retro. Prevents dismissing FAIL
#             because "retro.md is expected to be missing at this stage."
#   --live    Check that the CWF state file live section has required fields populated
#             (session_id, dir, phase, task). Use to verify context is preserved
#             for compact recovery.
#   --semantic-gap
#             Check first-wave semantic closure relations for gap-analysis artifacts:
#             (1) GAP(Unresolved/Unknown) -> BL linkage, (2) CW -> GAP linkage,
#             (3) optional RANGE consistency.
#   (default) Check all artifacts (always + milestone)
# If no selector, checks the most recent session in the CWF state file
# Reads expected artifacts from session entry or session_defaults
# Exit 0 = all good, Exit 1 = missing/empty artifacts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || (cd "$SCRIPT_DIR/.." && pwd))"
RESOLVER_SCRIPT="$SCRIPT_DIR/cwf-artifact-paths.sh"
LIVE_RESOLVER_SCRIPT="$SCRIPT_DIR/cwf-live-state.sh"

if [[ ! -f "$RESOLVER_SCRIPT" ]]; then
  echo "Error: resolver script not found: $RESOLVER_SCRIPT" >&2
  exit 1
fi

# shellcheck source=./cwf-artifact-paths.sh
# shellcheck disable=SC1090,SC1091
source "$RESOLVER_SCRIPT"
if [[ -f "$LIVE_RESOLVER_SCRIPT" ]]; then
  # shellcheck source=./cwf-live-state.sh
  # shellcheck disable=SC1090,SC1091
  source "$LIVE_RESOLVER_SCRIPT"
fi

PHASE=""
if [[ "${1:-}" == "--impl" ]]; then
  PHASE="impl"
  shift
elif [[ "${1:-}" == "--live" ]]; then
  PHASE="live"
  shift
elif [[ "${1:-}" == "--semantic-gap" ]]; then
  PHASE="semantic_gap"
  shift
fi

usage() {
  cat <<'USAGE'
Usage:
  check-session.sh [--impl|--live|--semantic-gap] [session-id|session-dir]

Examples:
  check-session.sh
  check-session.sh S14
  check-session.sh .cwf/projects/260216-03-hitl-readme-restart
  check-session.sh --impl S14
  check-session.sh --live
USAGE
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

STATE_FILE="$(resolve_cwf_state_file "$REPO_ROOT")"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [[ ! -f "$STATE_FILE" ]]; then
  echo -e "${RED}Error: state file not found: $STATE_FILE${NC}" >&2
  exit 1
fi

# --live: validate live section has required fields
if [[ "$PHASE" == "live" ]]; then
  live_state_file="$STATE_FILE"
  if declare -F cwf_live_resolve_file >/dev/null 2>&1; then
    resolved_live_state="$(cwf_live_resolve_file "$REPO_ROOT" 2>/dev/null || true)"
    if [[ -n "$resolved_live_state" && -f "$resolved_live_state" ]]; then
      live_state_file="$resolved_live_state"
    fi
  fi

  echo "Checking CWF state live section..."
  echo "Root state: $STATE_FILE"
  if [[ "$live_state_file" != "$STATE_FILE" ]]; then
    echo "Resolved live state: $live_state_file"
  fi
  echo "---"

  live_pass=0
  live_fail=0
  in_live=false
  live_session_id=""
  live_dir=""
  live_phase=""
  live_task=""

  while IFS= read -r line; do
    if [[ "$line" =~ ^live: ]]; then
      in_live=true
      continue
    fi
    if $in_live && [[ "$line" =~ ^[a-z#] ]] && [[ ! "$line" =~ ^[[:space:]] ]]; then
      break
    fi
    if $in_live; then
      if [[ "$line" =~ ^[[:space:]]{2}session_id:[[:space:]]*\"?([^\"]*)\"? ]]; then
        live_session_id="${BASH_REMATCH[1]}"
      elif [[ "$line" =~ ^[[:space:]]{2}dir:[[:space:]]*(.+) ]]; then
        live_dir="${BASH_REMATCH[1]}"
      elif [[ "$line" =~ ^[[:space:]]{2}phase:[[:space:]]*(.+) ]]; then
        live_phase="${BASH_REMATCH[1]}"
      elif [[ "$line" =~ ^[[:space:]]{2}task:[[:space:]]*\"?([^\"]*)\"? ]]; then
        live_task="${BASH_REMATCH[1]}"
      fi
    fi
  done < "$live_state_file"

  if [[ -n "$live_session_id" ]]; then
    echo -e "  ${GREEN}✓${NC} session_id: ${live_session_id}"
    live_pass=$((live_pass + 1))
  else
    echo -e "  ${RED}✗${NC} session_id: (empty)"
    live_fail=$((live_fail + 1))
  fi
  if [[ -n "$live_dir" ]]; then
    echo -e "  ${GREEN}✓${NC} dir: ${live_dir}"
    live_pass=$((live_pass + 1))
  else
    echo -e "  ${RED}✗${NC} dir: (empty)"
    live_fail=$((live_fail + 1))
  fi
  if [[ -n "$live_phase" ]]; then
    echo -e "  ${GREEN}✓${NC} phase: ${live_phase}"
    live_pass=$((live_pass + 1))
  else
    echo -e "  ${RED}✗${NC} phase: (empty)"
    live_fail=$((live_fail + 1))
  fi
  if [[ -n "$live_task" ]]; then
    echo -e "  ${GREEN}✓${NC} task: ${live_task}"
    live_pass=$((live_pass + 1))
  else
    echo -e "  ${RED}✗${NC} task: (empty)"
    live_fail=$((live_fail + 1))
  fi

  echo "---"
  total=$((live_pass + live_fail))
  echo -e "Result: ${live_pass}/${total} live fields populated"

  if [[ "$live_fail" -gt 0 ]]; then
    echo -e "${RED}FAIL${NC}: ${live_fail} live field(s) empty — compact recovery will not work"
    exit 1
  else
    echo -e "${GREEN}PASS${NC}: Live section ready for compact recovery"
    exit 0
  fi
fi

# Parse session_defaults from the CWF state file
# Extracts session_defaults.artifacts.always and .milestone lists
parse_defaults() {
  local in_defaults=false
  local in_artifacts=false
  DEFAULTS_ALWAYS=""
  DEFAULTS_MILESTONE=""
  DEFAULTS_IMPL_COMPLETE=""

  while IFS= read -r line; do
    if [[ "$line" =~ ^session_defaults: ]]; then
      in_defaults=true
      continue
    fi
    # Exit defaults block on next top-level key
    if [[ "$in_defaults" == "true" ]] && [[ "$line" =~ ^[a-z] ]]; then
      break
    fi
    if [[ "$in_defaults" == "true" ]]; then
      if [[ "$line" =~ ^[[:space:]]*artifacts: ]]; then
        in_artifacts=true
        continue
      fi
      if [[ "$in_artifacts" == "true" ]]; then
        if [[ "$line" =~ ^[[:space:]]*impl_complete: ]]; then
          DEFAULTS_IMPL_COMPLETE="$(trim_ws "${line#*:}")"
        fi
        if [[ "$line" =~ ^[[:space:]]*always: ]]; then
          DEFAULTS_ALWAYS="$(trim_ws "${line#*:}")"
        fi
        if [[ "$line" =~ ^[[:space:]]*milestone: ]]; then
          DEFAULTS_MILESTONE="$(trim_ws "${line#*:}")"
        fi
      fi
    fi
  done < "$STATE_FILE"
}

# Parse inline YAML list [a, b, c] into space-separated string
parse_yaml_list() {
  local raw="$1"
  raw="${raw#\[}"
  raw="${raw%\]}"
  echo "$raw" | tr ',' '\n' | xargs
}

trim_ws() {
  echo "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

run_semantic_gap_checks() {
  local session_dir="$1"
  local semantic_pass=0
  local semantic_fail=0

  local gap_file="$session_dir/gap-candidates.md"
  local backlog_file="$session_dir/discussion-backlog.md"
  local cw_file="$session_dir/consistency-check.md"

  echo -e "${YELLOW}Phase: semantic-gap — checking closure integrity${NC}"
  echo "Session: $SESSION_ID"
  echo "Directory: $session_dir"
  echo "---"

  # Required files for first-wave semantic checks
  for required in "$gap_file" "$backlog_file" "$cw_file"; do
    if [[ -s "$required" ]]; then
      echo -e "  ${GREEN}✓${NC} required: $(basename "$required")"
      semantic_pass=$((semantic_pass + 1))
    else
      echo -e "  ${RED}✗${NC} required: $(basename "$required") (missing or empty)"
      semantic_fail=$((semantic_fail + 1))
    fi
  done

  if [[ "$semantic_fail" -gt 0 ]]; then
    echo "---"
    total_pre=$((semantic_pass + semantic_fail))
    echo -e "Result: ${semantic_pass}/${total_pre} preconditions satisfied"
    echo -e "${RED}FAIL${NC}: required semantic files missing"
    return 1
  fi

  # SC-S1: every Unresolved/Unknown GAP appears in discussion-backlog linkage
  local all_gaps
  local open_gaps
  local backlog_gaps
  local missing_open=""
  local open_count=0
  local backlog_count=0

  all_gaps=$(awk -F'|' '/^\| GAP-[0-9]+ /{id=$2; gsub(/^[ \t]+|[ \t]+$/,"",id); print id}' "$gap_file")
  open_gaps=$(awk -F'|' '/^\| GAP-[0-9]+ /{id=$2; cls=$7; gsub(/^[ \t]+|[ \t]+$/,"",id); gsub(/^[ \t]+|[ \t]+$/,"",cls); if (cls=="Unresolved" || cls=="Unknown") print id}' "$gap_file")
  backlog_gaps=$(grep -oE 'GAP-[0-9]+' "$backlog_file" | sort -u || true)

  if [[ -n "$open_gaps" ]]; then
    while IFS= read -r gap; do
      [[ -n "$gap" ]] || continue
      open_count=$((open_count + 1))
      if ! echo "$backlog_gaps" | grep -qx "$gap"; then
        missing_open="${missing_open}${gap} "
      fi
    done <<< "$open_gaps"
  fi

  if [[ -n "$backlog_gaps" ]]; then
    backlog_count=$(echo "$backlog_gaps" | grep -c '^GAP-' || true)
  fi

  if [[ -z "$missing_open" ]]; then
    echo -e "  ${GREEN}✓${NC} SC-S1 GAP(open)->BL linkage (open=${open_count}, backlog_gap_refs=${backlog_count})"
    semantic_pass=$((semantic_pass + 1))
  else
    echo -e "  ${RED}✗${NC} SC-S1 GAP(open)->BL linkage broken: missing in backlog -> ${missing_open}"
    semantic_fail=$((semantic_fail + 1))
  fi

  # SC-S2: every CW row maps to a valid GAP id that exists in gap-candidates
  local cw_total=0
  local invalid_cw=""
  local unknown_gap_cw=""

  while IFS= read -r line; do
    [[ "$line" =~ ^\|[[:space:]]CW-[0-9]+[[:space:]]\| ]] || continue
    local cw_id raw_gap gap_id
    cw_id=$(trim_ws "$(echo "$line" | awk -F'|' '{print $2}')")
    raw_gap=$(echo "$line" | awk -F'|' '{print $4}')
    gap_id=$(trim_ws "$raw_gap")
    cw_total=$((cw_total + 1))

    if [[ ! "$gap_id" =~ ^GAP-[0-9]+$ ]]; then
      invalid_cw="${invalid_cw}${cw_id} "
      continue
    fi
    if ! echo "$all_gaps" | grep -qx "$gap_id"; then
      unknown_gap_cw="${unknown_gap_cw}${cw_id}->${gap_id} "
    fi
  done < "$cw_file"

  if [[ -z "$invalid_cw" && -z "$unknown_gap_cw" ]]; then
    echo -e "  ${GREEN}✓${NC} SC-S2 CW->GAP linkage (cw_rows=${cw_total})"
    semantic_pass=$((semantic_pass + 1))
  else
    if [[ -n "$invalid_cw" ]]; then
      echo -e "  ${RED}✗${NC} SC-S2 invalid linked_gap_id format for CW rows: ${invalid_cw}"
    fi
    if [[ -n "$unknown_gap_cw" ]]; then
      echo -e "  ${RED}✗${NC} SC-S2 CW rows linked to non-existent GAP ids: ${unknown_gap_cw}"
    fi
    semantic_fail=$((semantic_fail + 1))
  fi

  # SC-S3 (optional): RANGE consistency across analysis artifacts
  local range_pairs=""
  local range_sources=0
  local range_base=""
  local range_mismatch=""
  local range_file

  for range_file in \
    "$session_dir/gap-candidates.md" \
    "$session_dir/discussion-backlog.md" \
    "$session_dir/consistency-check.md" \
    "$session_dir/summary.md" \
    "$session_dir/completion-check.md" \
    "$session_dir/gap-decisions.md"
  do
    if [[ -f "$range_file" ]]; then
      local range_val
      range_val=$(grep -m1 '^- RANGE:' "$range_file" | sed 's/^- RANGE:[[:space:]]*//' || true)
      if [[ -n "$range_val" ]]; then
        range_pairs="${range_pairs}${range_file}::${range_val}"$'\n'
        range_sources=$((range_sources + 1))
      fi
    fi
  done

  if [[ "$range_sources" -lt 2 ]]; then
    echo -e "  ${YELLOW}!${NC} SC-S3 RANGE consistency skipped (range_sources=${range_sources})"
  else
    while IFS= read -r pair; do
      [[ -n "$pair" ]] || continue
      local pair_val pair_file
      pair_file="${pair%%::*}"
      pair_val="${pair##*::}"
      if [[ -z "$range_base" ]]; then
        range_base="$pair_val"
      elif [[ "$pair_val" != "$range_base" ]]; then
        range_mismatch="${range_mismatch}$(basename "$pair_file") "
      fi
    done <<< "$range_pairs"

    if [[ -z "$range_mismatch" ]]; then
      echo -e "  ${GREEN}✓${NC} SC-S3 RANGE consistency (${range_sources} sources)"
      semantic_pass=$((semantic_pass + 1))
    else
      echo -e "  ${RED}✗${NC} SC-S3 RANGE mismatch detected in: ${range_mismatch}"
      semantic_fail=$((semantic_fail + 1))
    fi
  fi

  echo "---"
  local semantic_total
  semantic_total=$((semantic_pass + semantic_fail))
  echo -e "Result: ${semantic_pass}/${semantic_total} semantic checks passed"

  if [[ "$semantic_fail" -gt 0 ]]; then
    echo -e "${RED}FAIL${NC}: ${semantic_fail} semantic check(s) failed"
    return 1
  fi

  echo -e "${GREEN}PASS${NC}: Semantic closure checks passed"
  return 0
}

parse_defaults

normalize_session_dir_selector() {
  local selector="$1"
  local abs=""

  if [[ "$selector" == /* ]]; then
    abs="$selector"
  else
    abs="$REPO_ROOT/$selector"
  fi

  [[ -d "$abs" ]] || return 1

  if command -v realpath >/dev/null 2>&1; then
    abs="$(realpath "$abs")"
  else
    abs="$(cd "$abs" && pwd)"
  fi

  if [[ "$abs" == "$REPO_ROOT/"* ]]; then
    printf '%s\n' "${abs#"$REPO_ROOT"/}"
  else
    printf '%s\n' "$abs"
  fi
}

find_session_by_dir() {
  local target_dir="$1"
  local current_id=""
  local current_dir=""
  local current_artifacts=""
  local in_sessions=false

  while IFS= read -r line; do
    if [[ "$line" =~ ^sessions: ]]; then
      in_sessions=true
      continue
    fi
    if [[ "$in_sessions" == "true" && "$line" =~ ^[a-z#] ]]; then
      break
    fi
    if [[ "$in_sessions" != "true" ]]; then
      continue
    fi

    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*id:[[:space:]]*\"?([^\"[:space:]]+)\"?[[:space:]]*$ ]]; then
      if [[ -n "$current_id" && "$current_dir" == "$target_dir" ]]; then
        SESSION_ID="$current_id"
        SESSION_DIR="$current_dir"
        ARTIFACTS_LINE="$current_artifacts"
        return 0
      fi
      current_id="${BASH_REMATCH[1]}"
      current_dir=""
      current_artifacts=""
      continue
    fi

    if [[ "$line" =~ ^[[:space:]]*dir:[[:space:]]*(.+)$ ]]; then
      current_dir=$(echo "${BASH_REMATCH[1]}" | tr -d '"')
      continue
    fi

    if [[ "$line" =~ ^[[:space:]]*artifacts:[[:space:]]*(.+)$ ]]; then
      current_artifacts="${BASH_REMATCH[1]}"
      continue
    fi
  done < "$STATE_FILE"

  if [[ -n "$current_id" && "$current_dir" == "$target_dir" ]]; then
    SESSION_ID="$current_id"
    SESSION_DIR="$current_dir"
    ARTIFACTS_LINE="$current_artifacts"
    return 0
  fi

  return 1
}

SESSION_SELECTOR="${1:-}"
SESSION_ID=""
SESSION_DIR=""
ARTIFACTS_LINE=""

# Selector resolution priority:
#   1) empty selector -> most recent session ID
#   2) existing directory selector -> check by explicit session dir
#   3) fallback -> treat selector as session ID
if [[ -z "$SESSION_SELECTOR" ]]; then
  # Get the last session ID
  SESSION_ID=$(grep '^\s*- id:' "$STATE_FILE" | tail -1 | sed 's/.*id:\s*//' | tr -d ' "')
  if [[ -z "$SESSION_ID" ]]; then
    echo -e "${RED}Error: No sessions found in $STATE_FILE${NC}" >&2
    exit 1
  fi
  echo -e "${YELLOW}No session ID specified, checking most recent: ${SESSION_ID}${NC}"
else
  selector_dir="$(normalize_session_dir_selector "$SESSION_SELECTOR" 2>/dev/null || true)"
  if [[ -n "$selector_dir" ]]; then
    SESSION_DIR="$selector_dir"
    if find_session_by_dir "$selector_dir"; then
      :
    else
      # Path mode without matching session metadata: use defaults for artifact set.
      SESSION_ID="$(basename "$selector_dir")"
      echo -e "${YELLOW}Session dir selector provided; no matching session ID found in state. Using defaults for: ${SESSION_DIR}${NC}"
    fi
  else
    if [[ "$SESSION_SELECTOR" == */* ]]; then
      echo -e "${RED}Error: Session directory selector not found: $SESSION_SELECTOR${NC}" >&2
      exit 1
    fi
    SESSION_ID="$SESSION_SELECTOR"
  fi
fi

if [[ -z "$SESSION_DIR" ]]; then
  # Extract session dir and artifacts by SESSION_ID
  found=false
  while IFS= read -r line; do
    if [[ "$found" == "true" ]]; then
      # Check if we hit the next session entry or left the sessions block
      if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*id: ]] && [[ "$line" != *"$SESSION_ID"* ]]; then
        break
      fi
      # Top-level key (not indented) means we've left the sessions block
      if [[ "$line" =~ ^[a-z#] ]]; then
        break
      fi
      if [[ "$line" =~ ^[[:space:]]*dir: ]]; then
        SESSION_DIR=$(echo "$line" | sed 's/.*dir:\s*//' | tr -d ' "')
      fi
      if [[ "$line" =~ ^[[:space:]]*artifacts: ]]; then
        ARTIFACTS_LINE="$(trim_ws "${line#*:}")"
      fi
    fi
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*id:[[:space:]]*\"?${SESSION_ID}\"?$ ]] || \
       [[ "$line" =~ ^[[:space:]]*-[[:space:]]*id:[[:space:]]*${SESSION_ID}[[:space:]]*$ ]]; then
      found=true
    fi
  done < "$STATE_FILE"

  if [[ "$found" != "true" ]]; then
    echo -e "${RED}Error: Session '$SESSION_ID' not found in $STATE_FILE${NC}" >&2
    exit 1
  fi

  if [[ -z "$SESSION_DIR" ]]; then
    echo -e "${RED}Error: No dir found for session '$SESSION_ID'${NC}" >&2
    exit 1
  fi
fi

if [[ "$PHASE" == "semantic_gap" ]]; then
  run_semantic_gap_checks "$SESSION_DIR"
  exit $?
fi

# Determine artifacts to check:
# --impl flag → use session_defaults.impl_complete
# Session has explicit artifacts → use those
# Otherwise → use session_defaults.always + session_defaults.milestone
if [[ "$PHASE" == "impl" ]]; then
  if [[ -z "$DEFAULTS_IMPL_COMPLETE" ]]; then
    echo -e "${RED}Error: No impl_complete defaults found in $STATE_FILE${NC}" >&2
    exit 1
  fi
  all_items=$(parse_yaml_list "$DEFAULTS_IMPL_COMPLETE")
  echo -e "${YELLOW}Phase: impl — checking impl_complete artifacts${NC}"
elif [[ -z "$ARTIFACTS_LINE" ]]; then
  if [[ -z "$DEFAULTS_ALWAYS" ]] && [[ -z "$DEFAULTS_MILESTONE" ]]; then
    echo -e "${RED}Error: No artifacts defined for session '$SESSION_ID' and no session_defaults found${NC}" >&2
    exit 1
  fi
  # Merge always + milestone defaults
  always_items=$(parse_yaml_list "$DEFAULTS_ALWAYS")
  milestone_items=$(parse_yaml_list "$DEFAULTS_MILESTONE")
  all_items="$always_items $milestone_items"
  echo -e "${YELLOW}No explicit artifacts — using session_defaults (always + milestone)${NC}"
else
  all_items=$(parse_yaml_list "$ARTIFACTS_LINE")
fi

echo "Session: $SESSION_ID"
echo "Directory: $SESSION_DIR"
echo "---"

pass_count=0
fail_count=0

for artifact in $all_items; do
  filepath="$SESSION_DIR/$artifact"

  if [[ -f "$filepath" ]] && [[ -s "$filepath" ]]; then
    echo -e "  ${GREEN}✓${NC} $artifact"
    pass_count=$((pass_count + 1))
  elif [[ -f "$filepath" ]]; then
    echo -e "  ${RED}✗${NC} $artifact (empty)"
    fail_count=$((fail_count + 1))
  else
    echo -e "  ${RED}✗${NC} $artifact (missing)"
    fail_count=$((fail_count + 1))
  fi
done

echo "---"
total=$((pass_count + fail_count))
echo -e "Result: ${pass_count}/${total} artifacts present"

if [[ "$fail_count" -gt 0 ]]; then
  echo -e "${RED}FAIL${NC}: $fail_count artifact(s) missing or empty"
  exit 1
else
  echo -e "${GREEN}PASS${NC}: All artifacts verified"
  exit 0
fi
