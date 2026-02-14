#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "" ]; then
  echo "Usage: bash scripts/check-index-coverage.sh <index-file>"
  echo "Example: bash scripts/check-index-coverage.sh cwf-index.md"
  exit 2
fi

INDEX_FILE="$1"
IGNORE_FILE=".cwf-index-ignore"

if [ ! -f "$INDEX_FILE" ]; then
  echo "Index file not found: $INDEX_FILE"
  exit 2
fi

if ! command -v git >/dev/null 2>&1; then
  echo "git is required"
  exit 2
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

LINKS_RAW="$TMP_DIR/links-raw.txt"
LINKS="$TMP_DIR/links.txt"
REQUIRED="$TMP_DIR/required.txt"
MISSING="$TMP_DIR/missing.txt"
REQUIRED_FILTERED="$TMP_DIR/required-filtered.txt"

ignore_patterns=()
if [ -f "$IGNORE_FILE" ]; then
  while IFS= read -r line; do
    trimmed="$(printf "%s" "$line" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
    if [ "$trimmed" = "" ]; then
      continue
    fi
    case "$trimmed" in
      \#*) continue ;;
    esac
    ignore_patterns+=("$trimmed")
  done < "$IGNORE_FILE"
fi

is_ignored() {
  local path="$1"
  local pattern
  for pattern in "${ignore_patterns[@]}"; do
    if [[ "$path" == $pattern ]]; then
      return 0
    fi
  done
  return 1
}

perl -ne 'while (/\[[^\]]+\]\(([^)]+)\)/g) { print "$1\n"; }' "$INDEX_FILE" > "$LINKS_RAW"

awk '
{
  p = $0
  sub(/[?#].*$/, "", p)
  gsub(/^\.\//, "", p)
  sub(/\/$/, "", p)
  if (p == "") next
  if (p ~ /^(https?:|mailto:|#|javascript:)/) next
  print p
}
' "$LINKS_RAW" | sort -u > "$LINKS"

{
  find docs -maxdepth 1 -type f -name "*.md" | sort
  find plugins/cwf/skills -mindepth 2 -maxdepth 2 -type f -name "SKILL.md" | sort
  find plugins/cwf/references -maxdepth 1 -type f -name "*.md" | sort
  find references -type f -name "*.md" | sort
} | sort -u > "$REQUIRED"

> "$REQUIRED_FILTERED"
while IFS= read -r path; do
  if is_ignored "$path"; then
    continue
  fi
  printf "%s\n" "$path" >> "$REQUIRED_FILTERED"
done < "$REQUIRED"

grep -Fvx -f "$LINKS" "$REQUIRED_FILTERED" > "$MISSING" || true

if [ -s "$MISSING" ]; then
  echo "Index coverage check FAILED: required docs missing from $INDEX_FILE"
  if [ "${#ignore_patterns[@]}" -gt 0 ]; then
    echo "Ignore file applied: $IGNORE_FILE (${#ignore_patterns[@]} pattern(s))"
  fi
  echo
  cat "$MISSING"
  exit 1
fi

echo "Index coverage check passed: $INDEX_FILE"
