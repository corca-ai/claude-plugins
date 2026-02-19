#!/usr/bin/env bash
set -euo pipefail

# check-session.sh — Verify session completion artifacts
# Usage: check-session.sh [--impl|--live|--semantic-gap] [session-id|session-dir]
#   --impl    Check impl_complete artifacts only (next-session.md is optional)
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

# shellcheck source=plugins/cwf/scripts/cwf-artifact-paths.sh
source "$RESOLVER_SCRIPT"
if [[ -f "$LIVE_RESOLVER_SCRIPT" ]]; then
  # shellcheck source=plugins/cwf/scripts/cwf-live-state.sh
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

# shellcheck source=plugins/cwf/scripts/check-session-lib.sh
source "$SCRIPT_DIR/check-session-lib.sh"

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
parse_defaults

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
  all_items=$(exclude_optional_impl_artifacts "$all_items")
  echo -e "${YELLOW}Phase: impl — checking impl_complete artifacts (next-session.md optional)${NC}"
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
