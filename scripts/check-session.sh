#!/usr/bin/env bash
set -euo pipefail

# check-session.sh — Verify session completion artifacts
# Usage: check-session.sh [--impl|--live] [session-id]
#   --impl    Check impl_complete artifacts only (plan.md, lessons.md, next-session.md)
#             Use after implementation, before retro. Prevents dismissing FAIL
#             because "retro.md is expected to be missing at this stage."
#   --live    Check that cwf-state.yaml live section has required fields populated
#             (session_id, dir, phase, task). Use to verify context is preserved
#             for compact recovery.
#   (default) Check all artifacts (always + milestone)
# If no session-id, checks the most recent session in cwf-state.yaml
# Reads expected artifacts from session entry or session_defaults
# Exit 0 = all good, Exit 1 = missing/empty artifacts

PHASE=""
if [[ "${1:-}" == "--impl" ]]; then
  PHASE="impl"
  shift
elif [[ "${1:-}" == "--live" ]]; then
  PHASE="live"
  shift
fi

STATE_FILE="cwf-state.yaml"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [[ ! -f "$STATE_FILE" ]]; then
  echo -e "${RED}Error: $STATE_FILE not found${NC}" >&2
  exit 1
fi

# --live: validate live section has required fields
if [[ "$PHASE" == "live" ]]; then
  echo "Checking cwf-state.yaml live section..."
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
      if [[ "$line" =~ ^[[:space:]]+session_id:[[:space:]]*\"?([^\"]*)\"? ]]; then
        live_session_id="${BASH_REMATCH[1]}"
      elif [[ "$line" =~ ^[[:space:]]+dir:[[:space:]]*(.+) ]]; then
        live_dir="${BASH_REMATCH[1]}"
      elif [[ "$line" =~ ^[[:space:]]+phase:[[:space:]]*(.+) ]]; then
        live_phase="${BASH_REMATCH[1]}"
      elif [[ "$line" =~ ^[[:space:]]+task:[[:space:]]*\"?([^\"]*)\"? ]]; then
        live_task="${BASH_REMATCH[1]}"
      fi
    fi
  done < "$STATE_FILE"

  for field_name in session_id dir phase task; do
    eval "val=\$live_${field_name}"
    if [[ -n "$val" ]]; then
      echo -e "  ${GREEN}✓${NC} ${field_name}: ${val}"
      live_pass=$((live_pass + 1))
    else
      echo -e "  ${RED}✗${NC} ${field_name}: (empty)"
      live_fail=$((live_fail + 1))
    fi
  done

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

# Parse session_defaults from cwf-state.yaml
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
          DEFAULTS_IMPL_COMPLETE=$(echo "$line" | sed 's/.*impl_complete:\s*//')
        fi
        if [[ "$line" =~ ^[[:space:]]*always: ]]; then
          DEFAULTS_ALWAYS=$(echo "$line" | sed 's/.*always:\s*//')
        fi
        if [[ "$line" =~ ^[[:space:]]*milestone: ]]; then
          DEFAULTS_MILESTONE=$(echo "$line" | sed 's/.*milestone:\s*//')
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

parse_defaults

SESSION_ID="${1:-}"

# Find the session block in cwf-state.yaml
# If no session ID given, use the last session entry
if [[ -z "$SESSION_ID" ]]; then
  # Get the last session ID
  SESSION_ID=$(grep '^\s*- id:' "$STATE_FILE" | tail -1 | sed 's/.*id:\s*//' | tr -d ' "')
  if [[ -z "$SESSION_ID" ]]; then
    echo -e "${RED}Error: No sessions found in $STATE_FILE${NC}" >&2
    exit 1
  fi
  echo -e "${YELLOW}No session ID specified, checking most recent: ${SESSION_ID}${NC}"
fi

# Extract session dir and artifacts
SESSION_DIR=""
ARTIFACTS_LINE=""
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
      ARTIFACTS_LINE=$(echo "$line" | sed 's/.*artifacts:\s*//')
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
