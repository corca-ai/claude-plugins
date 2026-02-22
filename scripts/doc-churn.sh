#!/usr/bin/env bash
set -euo pipefail

# doc-churn.sh — Analyze document churn via git history
# Usage: doc-churn.sh [--days N] [--stale-days N] [--stale-only] [--json] [--include-project-artifacts] [-h|--help]
#   --days N               Lookback period for commit counting (default: 30)
#   --stale-days N         Threshold for stale classification (default: 90)
#   --stale-only           Only show files classified as stale or archival
#   --json                 Output machine-readable JSON
#   --include-project-artifacts  Include project artifact directories (off by default)
#   -h|--help              Show this usage message
# Exit 0 always (informational tool, not a linter)

usage() {
  sed -n '3,12p' "$0" | sed 's/^# \?//'
  exit 0
}

DAYS=30
STALE_DAYS=90
STALE_ONLY=false
JSON_OUTPUT=false
INCLUDE_PROJECT_ARTIFACTS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      ;;
    --days)
      if [[ $# -lt 2 ]]; then
        echo "Error: --days requires a value" >&2
        exit 1
      fi
      DAYS="$2"
      shift 2
      ;;
    --stale-days)
      if [[ $# -lt 2 ]]; then
        echo "Error: --stale-days requires a value" >&2
        exit 1
      fi
      STALE_DAYS="$2"
      shift 2
      ;;
    --stale-only)
      STALE_ONLY=true
      shift
      ;;
    --json)
      JSON_OUTPUT=true
      shift
      ;;
    --include-project-artifacts)
      INCLUDE_PROJECT_ARTIFACTS=true
      shift
      ;;
    *)
      echo "Error: Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$REPO_ROOT"

# Colors (disabled for non-TTY output and JSON mode)
if [[ -t 1 ]] && [[ "$JSON_OUTPUT" != "true" ]]; then
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

NOW=$(date +%s)
CUTOFF_EPOCH=$((NOW - DAYS * 86400))
STALE_EPOCH=$((NOW - STALE_DAYS * 86400))
FRESH_EPOCH=$((NOW - 7 * 86400))
CURRENT_EPOCH=$((NOW - 30 * 86400))

# Collect markdown files while honoring .gitignore.
MD_FILES=()
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  while IFS= read -r md_file; do
    MD_FILES+=("$md_file")
  done < <(
    git ls-files --cached --others --exclude-standard -- '*.md' \
      | sort
  )
else
  while IFS= read -r md_file; do
    MD_FILES+=("$md_file")
  done < <(
    find . -name "*.md" -type f ! -path "./.git/*" ! -path "*/node_modules/*" \
      | sed 's|^\./||' \
      | sort
  )
fi

# Filter project artifact directories unless requested
if [[ "$INCLUDE_PROJECT_ARTIFACTS" != "true" ]]; then
  FILTERED=()
  for f in "${MD_FILES[@]}"; do
    case "$f" in
      ./.cwf/projects/*) continue ;;
      *) FILTERED+=("$f") ;;
    esac
  done
  MD_FILES=("${FILTERED[@]+"${FILTERED[@]}"}")
fi

if [[ ${#MD_FILES[@]} -eq 0 ]]; then
  if [[ "$JSON_OUTPUT" == "true" ]]; then
    echo '[]'
  else
    echo "No Markdown files found."
  fi
  exit 0
fi

# Helper: classify file status by last-commit epoch
classify_status() {
  local epoch="$1"
  if [[ "$epoch" -eq 0 ]]; then
    echo "unknown"
  elif [[ "$epoch" -ge "$FRESH_EPOCH" ]]; then
    echo "fresh"
  elif [[ "$epoch" -ge "$CURRENT_EPOCH" ]]; then
    echo "current"
  elif [[ "$epoch" -ge "$STALE_EPOCH" ]]; then
    echo "stale"
  else
    echo "archival"
  fi
}

# Helper: color for status
status_color() {
  local status="$1"
  case "$status" in
    fresh|current) echo "$GREEN" ;;
    stale)         echo "$YELLOW" ;;
    archival)      echo "$RED" ;;
    *)             echo "$NC" ;;
  esac
}

# Helper: epoch to ISO 8601
epoch_to_iso() {
  local epoch="$1"
  if [[ "$epoch" -eq 0 ]]; then
    echo "never"
  else
    date -d "@$epoch" -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null \
      || date -r "$epoch" -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null \
      || echo "epoch:$epoch"
  fi
}

json_entries=""
table_lines=()

for fpath in "${MD_FILES[@]}"; do
  rel="${fpath#./}"

  # Last commit epoch (may be empty for untracked files)
  last_epoch=$(git log -1 --format=%at -- "$rel" 2>/dev/null || true)

  if [[ -z "$last_epoch" ]]; then
    # Untracked file — no git history
    status="unknown"
    last_iso="never"
    commits=0
    lines_changed=0
  else
    status=$(classify_status "$last_epoch")
    last_iso=$(epoch_to_iso "$last_epoch")

    # Commit count in lookback period
    commits=$(git log --after="$CUTOFF_EPOCH" --oneline -- "$rel" 2>/dev/null | wc -l | tr -d ' ')

    # Lines changed in lookback period (additions + deletions)
    lines_changed=0
    while IFS=$'\t' read -r added removed _rest; do
      # Skip binary files (shown as '-')
      if [[ "$added" != "-" ]] && [[ "$removed" != "-" ]]; then
        lines_changed=$((lines_changed + added + removed))
      fi
    done < <(git log --after="$CUTOFF_EPOCH" --numstat --format="" -- "$rel" 2>/dev/null || true)
  fi

  # Apply --stale-only filter
  if [[ "$STALE_ONLY" == "true" ]]; then
    case "$status" in
      stale|archival) ;;
      *) continue ;;
    esac
  fi

  if [[ "$JSON_OUTPUT" == "true" ]]; then
    # JSON escape path
    json_path="${rel//\\/\\\\}"
    json_path="${json_path//\"/\\\"}"
    entry=$(printf '{"path":"%s","last_modified":"%s","last_modified_epoch":%s,"commits":%d,"lines_changed":%d,"status":"%s"}' \
      "$json_path" "$last_iso" "${last_epoch:-0}" "$commits" "$lines_changed" "$status")
    if [[ -n "$json_entries" ]]; then
      json_entries="$json_entries,$entry"
    else
      json_entries="$entry"
    fi
  else
    color=$(status_color "$status")
    # Pad status to 8 chars for alignment
    padded_status=$(printf '%-8s' "$status")
    table_lines+=("$(printf '  %b%s%b  %-30s  commits: %-4d  lines: %-6d  last: %s' \
      "$color" "$padded_status" "$NC" "$rel" "$commits" "$lines_changed" "$last_iso")")
  fi
done

# Output
if [[ "$JSON_OUTPUT" == "true" ]]; then
  printf '[%s]\n' "$json_entries"
else
  if [[ ${#table_lines[@]} -eq 0 ]]; then
    echo "No files match the current filter."
  else
    echo "Document churn analysis (last ${DAYS} days, stale threshold: ${STALE_DAYS} days)"
    echo "---"
    for line in "${table_lines[@]}"; do
      echo -e "$line"
    done
    echo "---"
    echo "Total: ${#table_lines[@]} file(s)"
  fi
fi

exit 0
