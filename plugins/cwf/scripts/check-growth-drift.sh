#!/usr/bin/env bash
set -euo pipefail

# check-growth-drift.sh — Detect cross-surface mismatches as CWF evolves.
# Usage: check-growth-drift.sh [--level inform|warn|stop] [-h|--help]
#
# Surfaces checked (v2):
#   1) Skill inventory vs README.ko workflow table
#   2) Default workflow chain sync (README.ko, README, run/SKILL)
#   3) Root/plugin mirrored script drift
#   4) hybrid live state pointer validity (root + session live state)
#   5) Provenance freshness summary
#
# Exit behavior:
#   inform: always exit 0
#   warn|stop: exit 1 when any mismatch is found

usage() {
  sed -n '3,20p' "$0" | sed 's/^# \?//'
  exit 0
}

LEVEL="warn"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --level)
      if [[ $# -lt 2 ]]; then
        echo "Error: --level requires a value (inform|warn|stop)" >&2
        exit 1
      fi
      LEVEL="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Error: unknown option: $1" >&2
      usage
      ;;
  esac
done

case "$LEVEL" in
  inform|warn|stop) ;;
  *)
    echo "Invalid level: $LEVEL (must be inform, warn, or stop)" >&2
    exit 1
    ;;
esac

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

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

FAIL_ITEMS=()
PASS_ITEMS=()
FAIL_COUNT=0

record_fail() {
  local category="$1"
  local message="$2"
  FAIL_ITEMS+=("${category}|${message}")
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

record_pass() {
  local category="$1"
  local message="$2"
  PASS_ITEMS+=("${category}|${message}")
}

trim_ws() {
  echo "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

strip_quotes() {
  local v="$1"
  if [[ "$v" =~ ^\".*\"$ ]] || [[ "$v" =~ ^\'.*\'$ ]]; then
    v="${v:1:${#v}-2}"
  fi
  printf '%s' "$v"
}

normalize_yaml_scalar() {
  local v="$1"
  v="${v%%#*}"
  v="$(trim_ws "$v")"
  v="$(strip_quotes "$v")"
  printf '%s' "$v"
}

extract_live_field() {
  local file="$1"
  local key="$2"
  awk -v key="$key" '
    /^live:/ { in_live=1; next }
    in_live && /^[^[:space:]]/ { exit }
    in_live {
      pat = "^[[:space:]]{2}" key ":[[:space:]]*"
      if ($0 ~ pat) {
        sub(pat, "", $0)
        print $0
        exit
      }
    }
  ' "$file"
}

extract_live_hitl_field() {
  local file="$1"
  local key="$2"
  awk -v key="$key" '
    /^live:/ { in_live=1; next }
    in_live && /^[^[:space:]]/ { exit }
    in_live {
      if ($0 ~ /^[[:space:]]+hitl:[[:space:]]*$/) {
        in_hitl=1
        next
      }
      if (in_hitl && $0 ~ /^[[:space:]]{2}[A-Za-z0-9_-]+:/ && $0 !~ /^[[:space:]]{4}/) {
        in_hitl=0
      }
      if (in_hitl) {
        pat = "^[[:space:]]{4}" key ":[[:space:]]*"
        if ($0 ~ pat) {
          sub(pat, "", $0)
          print $0
          exit
        }
      }
    }
  ' "$file"
}

normalize_chain() {
  echo "$1" | tr -d '[:space:]'
}

extract_chain_line() {
  local file="$1"
  grep -m1 -E 'gather[[:space:]]*→[[:space:]]*clarify.*review\(code\).*ship' "$file" \
    | sed -nE 's/.*(gather[[:space:]]*→[[:space:]]*clarify[[:space:]]*→[[:space:]]*plan[[:space:]]*→[[:space:]]*review\(plan\)[[:space:]]*→[[:space:]]*impl[[:space:]]*→[[:space:]]*review\(code\)[[:space:]]*→[[:space:]]*refactor[[:space:]]*→[[:space:]]*retro[[:space:]]*→[[:space:]]*ship).*/\1/p' \
    || true
}

check_skill_inventory_vs_readme_ko() {
  local category="skills_vs_readme_ko"
  local fs_file="$TMP_DIR/fs-skills.txt"
  local readme_file="$TMP_DIR/readme-ko-skills.txt"
  local missing=0
  local extra=0
  local fs_count=0
  local readme_count=0

  if [[ ! -f "README.ko.md" ]]; then
    record_fail "$category" "README.ko.md not found"
    return
  fi

  if [[ ! -d "plugins/cwf/skills" ]]; then
    record_fail "$category" "plugins/cwf/skills directory not found"
    return
  fi

  : > "$fs_file"
  for f in plugins/cwf/skills/*/SKILL.md; do
    [[ -f "$f" ]] || continue
    dirname "$f" | xargs basename >> "$fs_file"
  done
  sort -u "$fs_file" -o "$fs_file"

  grep -E '^\|[[:space:]]*[0-9]+[[:space:]]*\|' README.ko.md \
    | sed -nE 's/^\|[[:space:]]*[0-9]+[[:space:]]*\|[[:space:]]*\[([^]]+)\]\(#[^)]+\)[[:space:]]*\|.*/\1/p' \
    | sort -u > "$readme_file"

  fs_count="$(wc -l < "$fs_file" | tr -d ' ')"
  readme_count="$(wc -l < "$readme_file" | tr -d ' ')"

  while IFS= read -r skill; do
    [[ -n "$skill" ]] || continue
    if ! grep -qxF "$skill" "$readme_file"; then
      record_fail "$category" "Missing in README.ko workflow table: $skill"
      missing=$((missing + 1))
    fi
  done < "$fs_file"

  while IFS= read -r skill; do
    [[ -n "$skill" ]] || continue
    if ! grep -qxF "$skill" "$fs_file"; then
      record_fail "$category" "Listed in README.ko but missing skill directory: $skill"
      extra=$((extra + 1))
    fi
  done < "$readme_file"

  if [[ "$missing" -eq 0 && "$extra" -eq 0 ]]; then
    record_pass "$category" "Skill inventory aligned (filesystem=$fs_count, readme_ko=$readme_count)"
  fi
}

check_run_chain_sync() {
  local category="run_chain_sync"
  local line_ko=""
  local line_en=""
  local line_run=""
  local norm_ko=""
  local norm_en=""
  local norm_run=""

  line_ko="$(extract_chain_line README.ko.md || true)"
  line_en="$(extract_chain_line README.md || true)"
  line_run="$(extract_chain_line plugins/cwf/skills/run/SKILL.md || true)"

  if [[ -z "$line_ko" ]]; then
    record_fail "$category" "Could not find default chain in README.ko.md"
    return
  fi
  if [[ -z "$line_en" ]]; then
    record_fail "$category" "Could not find default chain in README.md"
    return
  fi
  if [[ -z "$line_run" ]]; then
    record_fail "$category" "Could not find default chain in plugins/cwf/skills/run/SKILL.md"
    return
  fi

  norm_ko="$(normalize_chain "$line_ko")"
  norm_en="$(normalize_chain "$line_en")"
  norm_run="$(normalize_chain "$line_run")"

  if [[ "$norm_ko" != "$norm_en" || "$norm_ko" != "$norm_run" ]]; then
    record_fail "$category" "Default chain mismatch across README.ko/README/run-SKILL"
    record_fail "$category" "README.ko: $line_ko"
    record_fail "$category" "README: $line_en"
    record_fail "$category" "run/SKILL: $line_run"
    return
  fi

  record_pass "$category" "Default chain aligned: $line_run"
}

check_mirror_script_drift() {
  local category="mirror_script_drift"
  local pair_count=0
  local drift_count=0
  local pair=""
  local left=""
  local right=""

  while IFS= read -r pair; do
    [[ -n "$pair" ]] || continue
    left="${pair%%|*}"
    right="${pair#*|}"
    pair_count=$((pair_count + 1))

    if [[ ! -f "$left" || ! -f "$right" ]]; then
      record_fail "$category" "Missing mirror pair file: $left | $right"
      drift_count=$((drift_count + 1))
      continue
    fi

    if ! cmp -s "$left" "$right"; then
      record_fail "$category" "Mirror drift detected: $left != $right"
      drift_count=$((drift_count + 1))
    fi
  done <<'EOF'
scripts/check-session.sh|plugins/cwf/scripts/check-session.sh
scripts/next-prompt-dir.sh|plugins/cwf/scripts/next-prompt-dir.sh
scripts/cwf-artifact-paths.sh|plugins/cwf/scripts/cwf-artifact-paths.sh
scripts/cwf-live-state.sh|plugins/cwf/scripts/cwf-live-state.sh
scripts/codex/codex-with-log.sh|plugins/cwf/scripts/codex/codex-with-log.sh
scripts/codex/verify-skill-links.sh|plugins/cwf/scripts/codex/verify-skill-links.sh
scripts/codex/sync-session-logs.sh|plugins/cwf/scripts/codex/sync-session-logs.sh
scripts/codex/redact-session-logs.sh|plugins/cwf/scripts/codex/redact-session-logs.sh
scripts/codex/redact-jsonl.sh|plugins/cwf/scripts/codex/redact-jsonl.sh
scripts/codex/redact-sensitive.pl|plugins/cwf/scripts/codex/redact-sensitive.pl
EOF

  if [[ "$drift_count" -eq 0 ]]; then
    record_pass "$category" "All mirror script pairs aligned ($pair_count pairs)"
  fi
}

check_live_state_pointers() {
  local category="state_pointer_validity"
  local resolver="scripts/cwf-artifact-paths.sh"
  local live_resolver="scripts/cwf-live-state.sh"
  local state_file=""
  local effective_state_file=""
  local resolved_effective=""
  local state_pointer_raw=""
  local state_pointer_path=""
  local phase=""
  local dir_raw=""
  local dir_path=""
  local hitl_state_raw=""
  local hitl_rules_raw=""
  local summary_key=""
  local root_summary_val=""
  local effective_summary_val=""
  local summary_sync_ok=1
  local phase_ok=0
  local p=""

  if [[ ! -f "$resolver" ]]; then
    record_fail "$category" "Resolver script not found: $resolver"
    return
  fi
  if [[ ! -f "$live_resolver" ]]; then
    record_fail "$category" "Live resolver script not found: $live_resolver"
    return
  fi

  # shellcheck source=./cwf-artifact-paths.sh
  source "$resolver"
  # shellcheck source=./cwf-live-state.sh
  source "$live_resolver"
  state_file="$(resolve_cwf_state_file "$REPO_ROOT")"

  if [[ ! -f "$state_file" ]]; then
    record_fail "$category" "State file not found: $state_file"
    return
  fi

  effective_state_file="$state_file"
  if declare -F cwf_live_resolve_file >/dev/null 2>&1; then
    resolved_effective="$(cwf_live_resolve_file "$REPO_ROOT" 2>/dev/null || true)"
    if [[ -n "$resolved_effective" && -f "$resolved_effective" ]]; then
      effective_state_file="$resolved_effective"
    fi
  fi

  state_pointer_raw="$(extract_live_field "$state_file" "state_file" || true)"
  state_pointer_raw="$(normalize_yaml_scalar "$state_pointer_raw")"
  if [[ -n "$state_pointer_raw" ]]; then
    if [[ "$state_pointer_raw" == /* ]]; then
      state_pointer_path="$state_pointer_raw"
    else
      state_pointer_path="$REPO_ROOT/$state_pointer_raw"
    fi
    if [[ ! -f "$state_pointer_path" ]]; then
      record_fail "$category" "live.state_file missing: $state_pointer_raw"
    fi
  fi

  if [[ "$effective_state_file" != "$state_file" ]]; then
    for summary_key in session_id dir branch phase task; do
      root_summary_val="$(extract_live_field "$state_file" "$summary_key" || true)"
      effective_summary_val="$(extract_live_field "$effective_state_file" "$summary_key" || true)"
      root_summary_val="$(normalize_yaml_scalar "$root_summary_val")"
      effective_summary_val="$(normalize_yaml_scalar "$effective_summary_val")"
      if [[ "$root_summary_val" != "$effective_summary_val" ]]; then
        record_fail "$category" "root live.${summary_key} != effective live.${summary_key} ($root_summary_val != $effective_summary_val)"
        summary_sync_ok=0
      fi
    done
  fi

  phase="$(extract_live_field "$effective_state_file" "phase" || true)"
  phase="$(normalize_yaml_scalar "$phase")"
  if [[ -z "$phase" ]]; then
    record_fail "$category" "live.phase is empty"
  else
    for p in setup update gather clarify plan review review-plan impl review-code refactor retro handoff ship run hitl done; do
      if [[ "$phase" == "$p" ]]; then
        phase_ok=1
        break
      fi
    done
    if [[ "$phase_ok" -eq 0 ]]; then
      record_fail "$category" "live.phase is unknown: $phase"
    fi
  fi

  dir_raw="$(extract_live_field "$effective_state_file" "dir" || true)"
  dir_raw="$(normalize_yaml_scalar "$dir_raw")"
  if [[ -z "$dir_raw" ]]; then
    record_fail "$category" "live.dir is empty"
  else
    if [[ "$dir_raw" == /* ]]; then
      dir_path="$dir_raw"
    else
      dir_path="$REPO_ROOT/$dir_raw"
    fi
    if [[ ! -d "$dir_path" ]]; then
      record_fail "$category" "live.dir path does not exist: $dir_raw"
    fi
  fi

  hitl_state_raw="$(extract_live_hitl_field "$effective_state_file" "state_file" || true)"
  hitl_rules_raw="$(extract_live_hitl_field "$effective_state_file" "rules_file" || true)"
  hitl_state_raw="$(normalize_yaml_scalar "$hitl_state_raw")"
  hitl_rules_raw="$(normalize_yaml_scalar "$hitl_rules_raw")"

  if [[ -n "$hitl_state_raw" ]]; then
    if [[ "$hitl_state_raw" == /* ]]; then
      dir_path="$hitl_state_raw"
    else
      dir_path="$REPO_ROOT/$hitl_state_raw"
    fi
    if [[ ! -f "$dir_path" ]]; then
      record_fail "$category" "live.hitl.state_file missing: $hitl_state_raw"
    fi
  fi

  if [[ -n "$hitl_rules_raw" ]]; then
    if [[ "$hitl_rules_raw" == /* ]]; then
      dir_path="$hitl_rules_raw"
    else
      dir_path="$REPO_ROOT/$hitl_rules_raw"
    fi
    if [[ ! -f "$dir_path" ]]; then
      record_fail "$category" "live.hitl.rules_file missing: $hitl_rules_raw"
    fi
  fi

  if [[ "$phase_ok" -eq 1 && "$summary_sync_ok" -eq 1 ]]; then
    record_pass "$category" "live pointers are structurally valid (effective=$(basename "$effective_state_file"))"
  fi
}

check_provenance_freshness_summary() {
  local category="provenance_freshness"
  local checker="scripts/provenance-check.sh"
  local output=""
  local stale=""
  local total=""

  if [[ ! -x "$checker" ]]; then
    record_fail "$category" "Missing checker: $checker"
    return
  fi

  output="$(bash "$checker" --level inform --json 2>/dev/null || true)"
  if [[ -z "$output" ]]; then
    record_fail "$category" "No JSON output from provenance checker"
    return
  fi

  stale="$(echo "$output" | sed -n 's/.*"stale":[[:space:]]*\([0-9][0-9]*\).*/\1/p' | tail -1)"
  total="$(echo "$output" | sed -n 's/.*"total":[[:space:]]*\([0-9][0-9]*\).*/\1/p' | tail -1)"

  if [[ -z "$stale" || -z "$total" ]]; then
    record_fail "$category" "Failed to parse provenance summary from checker output"
    return
  fi

  if [[ "$stale" -gt 0 ]]; then
    record_fail "$category" "Stale provenance detected: $stale/$total"
  else
    record_pass "$category" "All provenance files fresh ($total checked)"
  fi
}

check_skill_inventory_vs_readme_ko
check_run_chain_sync
check_mirror_script_drift
check_live_state_pointers
check_provenance_freshness_summary

echo "CWF Growth Drift Check (v2)"
echo "Level: $LEVEL"
echo "---"

if [[ ${#PASS_ITEMS[@]} -gt 0 ]]; then
  for entry in "${PASS_ITEMS[@]}"; do
    category="${entry%%|*}"
    message="${entry#*|}"
    echo -e "  ${GREEN}PASS${NC} [$category] $message"
  done
fi

if [[ ${#FAIL_ITEMS[@]} -gt 0 ]]; then
  for entry in "${FAIL_ITEMS[@]}"; do
    category="${entry%%|*}"
    message="${entry#*|}"
    echo -e "  ${RED}FAIL${NC} [$category] $message"
  done
fi

echo "---"
echo "Summary: ${#PASS_ITEMS[@]} pass, ${#FAIL_ITEMS[@]} fail"

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  if [[ "$LEVEL" == "inform" ]]; then
    echo -e "${YELLOW}Inform${NC}: mismatches detected (non-blocking)"
    exit 0
  fi
  echo -e "${RED}Drift detected${NC}: mismatches require alignment"
  exit 1
fi

echo -e "${GREEN}Aligned${NC}: no drift detected"
exit 0
