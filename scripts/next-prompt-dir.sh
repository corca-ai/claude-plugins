#!/usr/bin/env bash
set -euo pipefail

# next-prompt-dir.sh — Output the next prompt-logs directory path for today.
# Usage: scripts/next-prompt-dir.sh <title>
# Output: prompt-logs/YYMMDD-NN-title (NN = zero-padded sequence number)

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <title>" >&2
  exit 1
fi

title="$1"

# Get today's date in YYMMDD format
today=$(date +%y%m%d)

# Find the project root (where prompt-logs/ lives)
script_dir="$(cd "$(dirname "$0")" && pwd)"
project_root="$(cd "$script_dir/.." && pwd)"
prompt_logs_dir="$project_root/prompt-logs"

# Find existing directories for today and determine the next sequence number
max_seq=0
if [[ -d "$prompt_logs_dir" ]]; then
  for dir in "$prompt_logs_dir"/"${today}"-*/; do
    [[ -d "$dir" ]] || continue
    basename="$(basename "$dir")"
    # Extract sequence number: YYMMDD-NN-...
    seq_str="${basename#"${today}"-}"
    seq_str="${seq_str%%-*}"
    # Remove leading zeros for arithmetic
    seq_num=$((10#$seq_str)) 2>/dev/null || continue
    if (( seq_num > max_seq )); then
      max_seq=$seq_num
    fi
  done
fi

next_seq=$(( max_seq + 1 ))
next_seq_padded=$(printf "%02d" "$next_seq")

echo "prompt-logs/${today}-${next_seq_padded}-${title}"
