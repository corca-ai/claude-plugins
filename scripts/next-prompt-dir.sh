#!/usr/bin/env bash
set -euo pipefail

# next-prompt-dir.sh — Output the next prompt-logs directory path for today.
# Usage: scripts/next-prompt-dir.sh <title>
# Output: prompt-logs/YYMMDD-NN-title (NN = zero-padded sequence number)
# Optional env for deterministic testing:
#   CWF_NEXT_PROMPT_DATE=YYMMDD   Override today's date
#   CWF_PROMPT_LOGS_DIR=/path     Override prompt-logs scan directory

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <title>" >&2
  exit 1
fi

title="$1"

resolve_project_root() {
  # Prefer git root so this script works from both repository-level and
  # plugin-copied locations.
  if git_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    printf '%s\n' "$git_root"
    return 0
  fi

  script_dir="$(cd "$(dirname "$0")" && pwd)"
  for rel in .. ../.. ../../..; do
    candidate="$(cd "$script_dir/$rel" 2>/dev/null && pwd || true)"
    if [[ -n "$candidate" && -d "$candidate/prompt-logs" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  # Last-resort fallback keeps prior behavior if prompt-logs does not exist yet.
  printf '%s\n' "$(cd "$script_dir/.." && pwd)"
}

project_root="$(resolve_project_root)"
prompt_logs_dir="${CWF_PROMPT_LOGS_DIR:-$project_root/prompt-logs}"
if [[ "$prompt_logs_dir" != /* ]]; then
  prompt_logs_dir="$project_root/$prompt_logs_dir"
fi

# Get date in YYMMDD format (overridable for fixture tests).
today="${CWF_NEXT_PROMPT_DATE:-$(date +%y%m%d)}"
if [[ ! "$today" =~ ^[0-9]{6}$ ]]; then
  echo "Error: CWF_NEXT_PROMPT_DATE must match YYMMDD, got '$today'" >&2
  exit 2
fi

# Find existing directories for today and determine the next sequence number
max_seq=0
if [[ -d "$prompt_logs_dir" ]]; then
  while IFS= read -r -d '' dir; do
    basename="$(basename "$dir")"

    # Match only YYMMDD-NN-*; ignore other same-day directories.
    if [[ "$basename" =~ ^${today}-([0-9]{2})- ]]; then
      seq_str="${BASH_REMATCH[1]}"
      seq_num=$((10#$seq_str))
      if (( seq_num > max_seq )); then
        max_seq=$seq_num
      fi
    fi
  done < <(
    find "$prompt_logs_dir" -mindepth 1 -maxdepth 1 -type d -name "${today}-*" -print0 2>/dev/null
  )
fi

next_seq=$(( max_seq + 1 ))
next_seq_padded=$(printf "%02d" "$next_seq")

echo "prompt-logs/${today}-${next_seq_padded}-${title}"
