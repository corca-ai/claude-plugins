#!/usr/bin/env bash
set -euo pipefail

# agent-slot-preflight.sh: Recommend sub-agent launch batching before parallel runs.
#
# Usage:
#   agent-slot-preflight.sh --required <N> [--active <N>] [--limit <N>] [--json]
#
# Environment defaults:
#   CWF_AGENT_THREAD_LIMIT   default slot limit when --limit omitted (default: 6)
#   CWF_AGENT_ACTIVE_THREADS default active slot count when --active omitted (default: 0)

usage() {
  cat <<'USAGE'
agent-slot-preflight.sh — recommend launch batching for sub-agent orchestration

Usage:
  agent-slot-preflight.sh --required <N> [--active <N>] [--limit <N>] [--json]

Options:
  --required <N>  Required sub-agent slots for upcoming launch (required)
  --active <N>    Currently active sub-agent slots (default: CWF_AGENT_ACTIVE_THREADS or 0)
  --limit <N>     Runtime slot limit (default: CWF_AGENT_THREAD_LIMIT or 6)
  --json          Emit JSON output
  -h, --help      Show help

Exit codes:
  0  Preflight completed (launch possible now, with or without batching)
  2  Launch not possible now (available slots = 0 while required > 0)
USAGE
}

REQUIRED=""
ACTIVE="${CWF_AGENT_ACTIVE_THREADS:-0}"
LIMIT="${CWF_AGENT_THREAD_LIMIT:-6}"
JSON=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --required)
      REQUIRED="${2:-}"
      shift 2
      ;;
    --active)
      ACTIVE="${2:-}"
      shift 2
      ;;
    --limit)
      LIMIT="${2:-}"
      shift 2
      ;;
    --json)
      JSON=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$REQUIRED" ]]; then
  echo "Error: --required is mandatory" >&2
  usage >&2
  exit 1
fi

if ! [[ "$REQUIRED" =~ ^[0-9]+$ ]]; then
  echo "Error: --required must be a non-negative integer" >&2
  exit 1
fi
if ! [[ "$ACTIVE" =~ ^[0-9]+$ ]]; then
  echo "Error: --active must be a non-negative integer" >&2
  exit 1
fi
if ! [[ "$LIMIT" =~ ^[0-9]+$ ]] || [[ "$LIMIT" -le 0 ]]; then
  echo "Error: --limit must be a positive integer" >&2
  exit 1
fi

required="$REQUIRED"
active="$ACTIVE"
limit="$LIMIT"

available=$((limit - active))
if [[ "$available" -lt 0 ]]; then
  available=0
fi

can_launch=true
first_batch_size=0
batches=0
remaining_after_first=0

if [[ "$required" -eq 0 ]]; then
  can_launch=true
  batches=0
elif [[ "$available" -eq 0 ]]; then
  can_launch=false
  batches=0
else
  can_launch=true
  first_batch_size=$(( required < available ? required : available ))
  remaining_after_first=$(( required - first_batch_size ))
  batches=$(( (required + available - 1) / available ))
fi

launch_mode="single_batch"
if [[ "$required" -eq 0 ]]; then
  launch_mode="none"
elif [[ "$can_launch" != "true" ]]; then
  launch_mode="blocked"
elif [[ "$batches" -gt 1 ]]; then
  launch_mode="multi_batch"
fi

if [[ "$JSON" == "true" ]]; then
  jq -n \
    --argjson required "$required" \
    --argjson active "$active" \
    --argjson limit "$limit" \
    --argjson available "$available" \
    --arg mode "$launch_mode" \
    --argjson can_launch "$([[ "$can_launch" == "true" ]] && echo true || echo false)" \
    --argjson batches "$batches" \
    --argjson first_batch_size "$first_batch_size" \
    --argjson remaining_after_first "$remaining_after_first" \
    '{
      required: $required,
      active: $active,
      limit: $limit,
      available: $available,
      launch_mode: $mode,
      can_launch: $can_launch,
      batches: $batches,
      first_batch_size: $first_batch_size,
      remaining_after_first: $remaining_after_first
    }'
else
  echo "required=$required"
  echo "active=$active"
  echo "limit=$limit"
  echo "available=$available"
  echo "launch_mode=$launch_mode"
  echo "can_launch=$can_launch"
  echo "batches=$batches"
  echo "first_batch_size=$first_batch_size"
  echo "remaining_after_first=$remaining_after_first"
fi

if [[ "$can_launch" != "true" ]]; then
  exit 2
fi
