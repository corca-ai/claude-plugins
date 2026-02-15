#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "" ]; then
  echo "Usage: check-index-coverage.sh <index-file> [--profile repo|cap]"
  echo "Example: check-index-coverage.sh AGENTS.md --profile repo"
  echo "Example: check-index-coverage.sh .cwf/indexes/cwf-index.md --profile cap"
  exit 2
fi

INDEX_FILE="$1"
PROFILE="repo"
if [ "${2:-}" = "--profile" ]; then
  if [ "${3:-}" = "" ]; then
    echo "Missing value for --profile (expected: repo or cap)"
    exit 2
  fi
  PROFILE="$3"
fi

if ! command -v git >/dev/null 2>&1; then
  echo "git is required"
  exit 2
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
CALLER_PWD="$PWD"
cd "$REPO_ROOT"

INDEX_PATH="$INDEX_FILE"
case "$INDEX_PATH" in
  /*) ;;
  *) INDEX_PATH="$CALLER_PWD/$INDEX_PATH" ;;
esac

if [ ! -f "$INDEX_PATH" ]; then
  echo "Index file not found: $INDEX_FILE"
  exit 2
fi

case "$PROFILE" in
  repo)
    IGNORE_FILE="$REPO_ROOT/.cwf-index-ignore"
    ;;
  cap)
    IGNORE_FILE="$REPO_ROOT/.cwf-cap-index-ignore"
    ;;
  *)
    echo "Invalid --profile value: $PROFILE (expected: repo or cap)"
    exit 2
    ;;
esac

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

perl -ne 'while (/\[[^\]]+\]\(([^)]+)\)/g) { print "$1\n"; }' "$INDEX_PATH" > "$LINKS_RAW"

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

collect_required_paths_repo() {
  local file
  for file in README.md README.ko.md AGENTS.md CLAUDE.md; do
    if [ -f "$file" ]; then
      printf "%s\n" "$file"
    fi
  done

  if [ -d docs ]; then
    find docs -maxdepth 1 -type f -name "*.md" | sort
  fi

  if [ -f "plugins/cwf/hooks/README.md" ]; then
    printf "%s\n" "plugins/cwf/hooks/README.md"
  fi

  if [ -f "plugins/cwf/scripts/README.md" ]; then
    printf "%s\n" "plugins/cwf/scripts/README.md"
  fi

  if [ -d references ]; then
    find references -type f -name "*.md" | sort
  fi

  find . \
    \( -path "./.git" -o -path "./.claude" -o -path "./.cwf" -o -path "./node_modules" -o -path "./prompt-logs" \) -prune -o \
    -type f -name "SKILL.md" -print \
    | sed 's|^\./||' \
    | grep "/skills/" || true

  find . \
    \( -path "./.git" -o -path "./.claude" -o -path "./.cwf" -o -path "./node_modules" -o -path "./prompt-logs" \) -prune -o \
    -type f -name "*.md" -print \
    | sed 's|^\./||' \
    | grep "/references/" \
    | grep -v "/skills/.*/references/" || true
}

collect_required_paths_cap() {
  if [ -f "plugins/cwf/.claude-plugin/plugin.json" ]; then
    printf "%s\n" "plugins/cwf/.claude-plugin/plugin.json"
  fi

  if [ -f "plugins/cwf/hooks/hooks.json" ]; then
    printf "%s\n" "plugins/cwf/hooks/hooks.json"
  fi

  if [ -f "plugins/cwf/hooks/README.md" ]; then
    printf "%s\n" "plugins/cwf/hooks/README.md"
  fi

  if [ -f "plugins/cwf/hooks/scripts/cwf-hook-gate.sh" ]; then
    printf "%s\n" "plugins/cwf/hooks/scripts/cwf-hook-gate.sh"
  fi

  if [ -f "plugins/cwf/scripts/README.md" ]; then
    printf "%s\n" "plugins/cwf/scripts/README.md"
  fi

  if [ -d "plugins/cwf/skills" ]; then
    find plugins/cwf/skills -mindepth 2 -maxdepth 2 -type f -name "SKILL.md" | sort
  fi

  if [ -d "plugins/cwf/references" ]; then
    find plugins/cwf/references -type f -name "*.md" | sort
  fi
}

if [ "$PROFILE" = "repo" ]; then
  collect_required_paths_repo | sort -u > "$REQUIRED"
else
  collect_required_paths_cap | sort -u > "$REQUIRED"
fi

> "$REQUIRED_FILTERED"
while IFS= read -r path; do
  if is_ignored "$path"; then
    continue
  fi
  printf "%s\n" "$path" >> "$REQUIRED_FILTERED"
done < "$REQUIRED"

if [ ! -s "$REQUIRED_FILTERED" ]; then
  echo "Index coverage check passed: $INDEX_FILE (no coverage inventory files detected)"
  exit 0
fi

grep -Fvx -f "$LINKS" "$REQUIRED_FILTERED" > "$MISSING" || true

if [ -s "$MISSING" ]; then
  echo "Index coverage check FAILED: required paths missing from $INDEX_FILE (profile=$PROFILE)"
  if [ "${#ignore_patterns[@]}" -gt 0 ]; then
    echo "Ignore file applied: $(basename "$IGNORE_FILE") (${#ignore_patterns[@]} pattern(s))"
  fi
  echo
  cat "$MISSING"
  exit 1
fi

echo "Index coverage check passed: $INDEX_FILE (profile=$PROFILE)"
