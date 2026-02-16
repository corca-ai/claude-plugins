#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC2001

# provenance-check.sh — Verify provenance sidecar files against current system state
# Usage: provenance-check.sh [--level inform|warn|stop] [--json] [-h|--help]
#   --level   Response level threshold (default: warn)
#             inform: report all, exit 0 even if stale
#             warn:   report all, exit 1 if any stale
#             stop:   report all, exit 1 if any stale (same as warn for scripts)
#   --json    Output machine-readable JSON
#   -h|--help Show this usage message
# Exit 0 = all fresh, Exit 1 = stale detected (at warn/stop level)

usage() {
  sed -n '3,11p' "$0" | sed 's/^# \?//'
  exit 0
}

LEVEL="warn"
JSON_OUTPUT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      ;;
    --level)
      if [[ $# -lt 2 ]]; then
        echo "Error: --level requires a value (inform|warn|stop)" >&2
        exit 1
      fi
      LEVEL="$2"
      shift 2
      ;;
    --json)
      JSON_OUTPUT=true
      shift
      ;;
    *)
      echo "Error: Unknown option: $1" >&2
      echo "Run with --help for usage." >&2
      exit 1
      ;;
  esac
done

# Validate level
case "$LEVEL" in
  inform|warn|stop) ;;
  *)
    echo "Invalid level: $LEVEL (must be inform, warn, or stop)" >&2
    exit 1
    ;;
esac

# Colors (disabled for non-TTY output and JSON mode)
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  NC='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  NC=''
fi

# Find repo root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$REPO_ROOT"

# Count current skills and hooks
CURRENT_SKILLS=$(find plugins/cwf/skills -name "SKILL.md" -mindepth 2 -maxdepth 2 2>/dev/null | wc -l | tr -d ' ')
CURRENT_HOOKS=$(find plugins/cwf/hooks/scripts -name "*.sh" ! -name "cwf-hook-gate.sh" 2>/dev/null | wc -l | tr -d ' ')

# Find all provenance files
PROVENANCE_FILES=()
while IFS= read -r f; do
  PROVENANCE_FILES+=("$f")
done < <(find . -name "*.provenance.yaml" -type f 2>/dev/null | sort)

if [[ ${#PROVENANCE_FILES[@]} -eq 0 ]]; then
  if [[ "$JSON_OUTPUT" == "true" ]]; then
    echo '{"current":{"skills":'"$CURRENT_SKILLS"',"hooks":'"$CURRENT_HOOKS"'},"files":[],"summary":{"total":0,"fresh":0,"stale":0}}'
  else
    echo -e "${YELLOW}No .provenance.yaml files found${NC}"
  fi
  exit 0
fi

fresh_count=0
stale_count=0
json_files=""

for pfile in "${PROVENANCE_FILES[@]}"; do
  # Strip leading ./
  pfile_rel="${pfile#./}"

  # Parse YAML fields with grep + sed (no yq dependency)
  target=""
  written_session=""
  last_reviewed=""
  recorded_skills=""
  recorded_hooks=""

  while IFS= read -r line; do
    case "$line" in
      target:*)
        # shellcheck disable=SC2001
        target=$(echo "$line" | sed 's/^target:[[:space:]]*//')
        ;;
      written_session:*)
        # shellcheck disable=SC2001
        written_session=$(echo "$line" | sed 's/^written_session:[[:space:]]*//')
        ;;
      last_reviewed:*)
        # shellcheck disable=SC2001
        last_reviewed=$(echo "$line" | sed 's/^last_reviewed:[[:space:]]*//')
        ;;
      skill_count:*)
        # shellcheck disable=SC2001
        recorded_skills=$(echo "$line" | sed 's/^skill_count:[[:space:]]*//')
        ;;
      hook_count:*)
        # shellcheck disable=SC2001
        recorded_hooks=$(echo "$line" | sed 's/^hook_count:[[:space:]]*//')
        ;;
    esac
  done < "$pfile"

  # Validate required fields — missing counts are treated as stale
  is_stale=false
  skill_delta=0
  hook_delta=0
  reasons=""

  if [[ -z "$recorded_skills" ]]; then
    is_stale=true
    if [[ -n "$reasons" ]]; then reasons="$reasons, "; fi
    reasons="${reasons}skill_count: missing"
  elif ! [[ "$recorded_skills" =~ ^[0-9]+$ ]]; then
    is_stale=true
    if [[ -n "$reasons" ]]; then reasons="$reasons, "; fi
    reasons="${reasons}skill_count: invalid (${recorded_skills})"
  elif [[ "$recorded_skills" != "$CURRENT_SKILLS" ]]; then
    is_stale=true
    skill_delta=$((CURRENT_SKILLS - recorded_skills))
    local_sign=""
    if [[ $skill_delta -gt 0 ]]; then local_sign="+"; fi
    if [[ -n "$reasons" ]]; then reasons="$reasons, "; fi
    reasons="${reasons}skills: ${recorded_skills} → ${CURRENT_SKILLS} (${local_sign}${skill_delta})"
  fi

  if [[ -z "$recorded_hooks" ]]; then
    is_stale=true
    if [[ -n "$reasons" ]]; then reasons="$reasons, "; fi
    reasons="${reasons}hook_count: missing"
  elif ! [[ "$recorded_hooks" =~ ^[0-9]+$ ]]; then
    is_stale=true
    if [[ -n "$reasons" ]]; then reasons="$reasons, "; fi
    reasons="${reasons}hook_count: invalid (${recorded_hooks})"
  elif [[ "$recorded_hooks" != "$CURRENT_HOOKS" ]]; then
    is_stale=true
    hook_delta=$((CURRENT_HOOKS - recorded_hooks))
    local_sign=""
    if [[ $hook_delta -gt 0 ]]; then local_sign="+"; fi
    if [[ -n "$reasons" ]]; then reasons="$reasons, "; fi
    reasons="${reasons}hooks: ${recorded_hooks} → ${CURRENT_HOOKS} (${local_sign}${hook_delta})"
  fi

  if [[ "$is_stale" == "true" ]]; then
    stale_count=$((stale_count + 1))
  else
    fresh_count=$((fresh_count + 1))
  fi

  # Output
  if [[ "$JSON_OUTPUT" == "true" ]]; then
    status="fresh"
    if [[ "$is_stale" == "true" ]]; then status="stale"; fi
    # Escape double quotes and backslashes for JSON safety
    json_file="${pfile_rel//\\/\\\\}"; json_file="${json_file//\"/\\\"}"
    json_target="${target//\\/\\\\}"; json_target="${json_target//\"/\\\"}"
    json_written="${written_session//\\/\\\\}"; json_written="${json_written//\"/\\\"}"
    json_reviewed="${last_reviewed//\\/\\\\}"; json_reviewed="${json_reviewed//\"/\\\"}"
    entry=$(printf '{"file":"%s","target":"%s","written_session":"%s","last_reviewed":"%s","recorded_skills":%s,"recorded_hooks":%s,"status":"%s","skill_delta":%d,"hook_delta":%d}' \
      "$json_file" "$json_target" "$json_written" "$json_reviewed" \
      "${recorded_skills:-null}" "${recorded_hooks:-null}" \
      "$status" "$skill_delta" "$hook_delta")
    if [[ -n "$json_files" ]]; then json_files="$json_files,"; fi
    json_files="$json_files$entry"
  else
    if [[ "$is_stale" == "true" ]]; then
      echo -e "  ${RED}STALE${NC}  $pfile_rel → $target ($reasons)"
    else
      echo -e "  ${GREEN}FRESH${NC}  $pfile_rel → $target"
    fi
  fi
done

# Summary output
if [[ "$JSON_OUTPUT" == "true" ]]; then
  total=$((fresh_count + stale_count))
  printf '{"current":{"skills":%d,"hooks":%d},"files":[%s],"summary":{"total":%d,"fresh":%d,"stale":%d}}\n' \
    "$CURRENT_SKILLS" "$CURRENT_HOOKS" "$json_files" "$total" "$fresh_count" "$stale_count"
else
  echo "---"
  echo "System state: ${CURRENT_SKILLS} skills, ${CURRENT_HOOKS} hooks"
  total=$((fresh_count + stale_count))
  echo "Checked: ${total} provenance files"

  if [[ "$stale_count" -gt 0 ]]; then
    echo -e "${RED}STALE${NC}: ${stale_count}/${total} file(s) have outdated provenance"
  else
    echo -e "${GREEN}FRESH${NC}: All ${total} provenance files match current system state"
  fi
fi

# Exit code
if [[ "$stale_count" -gt 0 ]] && [[ "$LEVEL" != "inform" ]]; then
  exit 1
fi
exit 0
