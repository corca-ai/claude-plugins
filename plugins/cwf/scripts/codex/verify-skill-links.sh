#!/usr/bin/env bash
# verify-skill-links.sh: Validate relative references in Codex skill files.
#
# Checks per SKILL.md:
# - Markdown relative links: (../../foo/bar.md)
# - SKILL_DIR placeholder paths: {SKILL_DIR}/../../foo
#
# Exit codes:
# - 0: all checked paths exist
# - 1: one or more missing paths
# - 2: usage/config error

set -euo pipefail

SKILLS_DIR="${HOME}/.agents/skills"
STRICT=true

usage() {
  cat <<'EOF'
Validate Codex skill relative references.

Usage:
  verify-skill-links.sh [options]

Options:
  --skills-dir <path>   Skills directory to scan (default: ~/.agents/skills)
  --no-strict           Always exit 0 even if missing paths are found
  -h, --help            Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skills-dir)
      SKILLS_DIR="${2:-}"
      shift 2
      ;;
    --no-strict)
      STRICT=false
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ ! -d "$SKILLS_DIR" ]]; then
  echo "Skills directory not found: $SKILLS_DIR" >&2
  exit 2
fi

if ! command -v rg >/dev/null 2>&1; then
  echo "rg is required but not found in PATH." >&2
  exit 2
fi

if ! command -v realpath >/dev/null 2>&1; then
  echo "realpath is required but not found in PATH." >&2
  exit 2
fi

skill_count=0
checked_count=0
missing_count=0

for skill_dir in "$SKILLS_DIR"/*; do
  [[ -d "$skill_dir" ]] || continue
  skill_md="$skill_dir/SKILL.md"
  [[ -f "$skill_md" ]] || continue
  skill_name="$(basename "$skill_dir")"
  skill_count=$((skill_count + 1))

  echo "== $skill_name =="

  # 1) Markdown relative links: (.../path)
  # Use a conservative character class to avoid trailing punctuation.
  while IFS= read -r rel; do
    [[ -n "$rel" ]] || continue
    checked_count=$((checked_count + 1))
    abs="$(realpath -m "$skill_dir/$rel")"
    if [[ -e "$abs" ]]; then
      echo "OK   mdlink  $rel -> $abs"
    else
      echo "MISS mdlink  $rel -> $abs"
      missing_count=$((missing_count + 1))
    fi
  done < <(rg -o '\((\.\.?/[A-Za-z0-9._/\-]+)\)' "$skill_md" -N | sed -E 's/^\((.*)\)$/\1/' | sort -u || true)

  # 2) Placeholder references: {SKILL_DIR}/...
  while IFS= read -r raw; do
    [[ -n "$raw" ]] || continue
    rel="${raw#\{SKILL_DIR\}/}"
    checked_count=$((checked_count + 1))
    abs="$(realpath -m "$skill_dir/$rel")"
    if [[ -e "$abs" ]]; then
      echo "OK   skdir   $raw -> $abs"
    else
      echo "MISS skdir   $raw -> $abs"
      missing_count=$((missing_count + 1))
    fi
  done < <(rg -o '\{SKILL_DIR\}/[A-Za-z0-9._/\-]+' "$skill_md" -N | sort -u || true)
done

echo "---"
echo "Skills scanned : $skill_count"
echo "Paths checked  : $checked_count"
echo "Missing paths  : $missing_count"

if [[ "$missing_count" -gt 0 && "$STRICT" == "true" ]]; then
  exit 1
fi

exit 0
