#!/usr/bin/env bash
set -euo pipefail

# check-lessons-metadata.sh
# Validates required promotion metadata for deep retro lessons.

usage() {
  cat <<'USAGE'
check-lessons-metadata.sh — validate deep retro lesson metadata fields

Usage:
  check-lessons-metadata.sh [options]

Options:
  --root <path>          Root directory to scan (default: .cwf/projects)
  --pattern <prefix>     Section heading prefix (default: "## Deep Retro Lesson")
  --file <path>          Validate a single lessons file (repeatable)
  --json                 Emit JSON summary
  -h, --help             Show this help
USAGE
}

ROOT_DIR=".cwf/projects"
HEADING_PREFIX="## Deep Retro Lesson"
JSON_OUTPUT="false"
declare -a FILES=()

# shellcheck disable=SC2016
awk_checker='\
BEGIN { in_section=0; section_heading=""; missing=0; owner=0; apply=0; promotion=0; due=0; }
function check_section() {
  if (!in_section) {
    return
  }
  if (!owner) {
    printf "%s:%s: missing field: Owner\\n", file, section_heading
    missing=1
  }
  if (!apply) {
    printf "%s:%s: missing field: Apply Layer\\n", file, section_heading
    missing=1
  }
  if (!promotion) {
    printf "%s:%s: missing field: Promotion Target\\n", file, section_heading
    missing=1
  }
  if (!due) {
    printf "%s:%s: missing field: Due Release\\n", file, section_heading
    missing=1
  }
}
{
  if (index($0, heading_prefix) == 1) {
    check_section()
    in_section=1
    section_heading=$0
    owner=0
    apply=0
    promotion=0
    due=0
    next
  }

  if (in_section && index($0, "## ") == 1) {
    check_section()
    in_section=0
  }

  if (in_section) {
    if ($0 ~ /^- \*\*Owner\*\*:[[:space:]]*`(repo|plugin)`/) {
      owner=1
    }
    if ($0 ~ /^- \*\*Apply Layer\*\*:[[:space:]]*`(local|upstream)`/) {
      apply=1
    }
    if ($0 ~ /^- \*\*Promotion Target\*\*:[[:space:]]*`[^`]+`/) {
      promotion=1
    }
    if ($0 ~ /^- \*\*Due Release\*\*:[[:space:]]*`[^`]+`/) {
      due=1
    }
  }
}
END {
  check_section()
  exit missing
}
'

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      ROOT_DIR="${2:-}"
      shift 2
      ;;
    --pattern)
      HEADING_PREFIX="${2:-}"
      shift 2
      ;;
    --file)
      FILES+=("${2:-}")
      shift 2
      ;;
    --json)
      JSON_OUTPUT="true"
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

if [[ "${#FILES[@]}" -eq 0 ]]; then
  if [[ ! -d "$ROOT_DIR" ]]; then
    if [[ "$JSON_OUTPUT" == "true" ]]; then
      jq -n --arg root "$ROOT_DIR" '{status:"PASS", root:$root, files_scanned:0, findings:[]}'
    else
      echo "status=PASS"
      echo "root=$ROOT_DIR"
      echo "files_scanned=0"
      echo "message=root directory missing; skipped"
    fi
    exit 0
  fi

  while IFS= read -r file; do
    FILES+=("$file")
  done < <(find "$ROOT_DIR" -type f -name lessons.md | sort)
fi

if [[ "${#FILES[@]}" -eq 0 ]]; then
  if [[ "$JSON_OUTPUT" == "true" ]]; then
    jq -n '{status:"PASS", files_scanned:0, findings:[]}'
  else
    echo "status=PASS"
    echo "files_scanned=0"
  fi
  exit 0
fi

findings_file="$(mktemp "${TMPDIR:-/tmp}/lessons-metadata-findings.XXXXXX")"
trap 'rm -f "$findings_file"' EXIT INT TERM

scan_count=0
fail_count=0
for file in "${FILES[@]}"; do
  [[ -f "$file" ]] || continue
  scan_count=$((scan_count + 1))

  if ! grep -Fq "$HEADING_PREFIX" "$file"; then
    continue
  fi

  set +e
  awk -v file="$file" -v heading_prefix="$HEADING_PREFIX" "$awk_checker" "$file" >> "$findings_file"
  rc=$?
  set -e
  if [[ "$rc" -ne 0 ]]; then
    fail_count=$((fail_count + 1))
  fi
done

if [[ "$JSON_OUTPUT" == "true" ]]; then
  jq -n \
    --arg status "$(if [[ "$fail_count" -eq 0 ]]; then echo PASS; else echo FAIL; fi)" \
    --argjson files_scanned "$scan_count" \
    --argjson files_failed "$fail_count" \
    --argjson findings "$(jq -R . < "$findings_file" | jq -s .)" \
    '{status:$status, files_scanned:$files_scanned, files_failed:$files_failed, findings:$findings}'
else
  echo "status=$(if [[ "$fail_count" -eq 0 ]]; then echo PASS; else echo FAIL; fi)"
  echo "files_scanned=$scan_count"
  echo "files_failed=$fail_count"
  if [[ -s "$findings_file" ]]; then
    cat "$findings_file"
  fi
fi

if [[ "$fail_count" -ne 0 ]]; then
  exit 1
fi
