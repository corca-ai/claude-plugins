#!/usr/bin/env bash
set -euo pipefail

# check-session.sh — Verify session completion artifacts
# Usage: check-session.sh [session-id]
# If no session-id, checks the most recent session in cwf-state.yaml
# Reads expected artifacts from cwf-state.yaml, verifies file existence + non-empty
# Exit 0 = all good, Exit 1 = missing/empty artifacts

STATE_FILE="cwf-state.yaml"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [[ ! -f "$STATE_FILE" ]]; then
  echo -e "${RED}Error: $STATE_FILE not found${NC}" >&2
  exit 1
fi

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

# Extract session dir — find the id line, then the next dir line
SESSION_DIR=""
ARTIFACTS_LINE=""
found=false
while IFS= read -r line; do
  if [[ "$found" == "true" ]]; then
    # Check if we hit the next session entry (new "- id:" line)
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*id: ]] && [[ "$line" != *"$SESSION_ID"* ]]; then
      break
    fi
    if [[ "$line" =~ ^[[:space:]]*dir: ]]; then
      SESSION_DIR=$(echo "$line" | sed 's/.*dir:\s*//' | tr -d ' "')
    fi
    if [[ "$line" =~ ^[[:space:]]*artifacts: ]]; then
      ARTIFACTS_LINE=$(echo "$line" | sed 's/.*artifacts:\s*//')
    fi
  fi
  if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*id:[[:space:]]*"?${SESSION_ID}"?$ ]] || \
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

if [[ -z "$ARTIFACTS_LINE" ]]; then
  echo -e "${RED}Error: No artifacts defined for session '$SESSION_ID'${NC}" >&2
  echo "Add an 'artifacts:' line to the session entry in $STATE_FILE"
  exit 1
fi

# Parse artifacts from YAML inline list: [plan.md, lessons.md, retro.md]
# Remove brackets, split by comma
ARTIFACTS_LINE="${ARTIFACTS_LINE#\[}"
ARTIFACTS_LINE="${ARTIFACTS_LINE%\]}"

IFS=',' read -ra ARTIFACTS <<< "$ARTIFACTS_LINE"

echo "Session: $SESSION_ID"
echo "Directory: $SESSION_DIR"
echo "---"

pass_count=0
fail_count=0

for artifact in "${ARTIFACTS[@]}"; do
  # Trim whitespace
  artifact=$(echo "$artifact" | xargs)
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
