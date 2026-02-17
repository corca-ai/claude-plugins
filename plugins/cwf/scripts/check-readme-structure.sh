#!/usr/bin/env bash
set -euo pipefail

# check-readme-structure.sh — verify README heading structure parity.
#
# Compares heading-level structure between README.md and README.ko.md.
# Detects count drift, missing/extra headings, and level-order mismatches.
#
# Usage:
#   check-readme-structure.sh [--strict] [--en README.md] [--ko README.ko.md]

usage() {
  cat <<'USAGE'
check-readme-structure.sh — verify README heading structure parity

Usage:
  check-readme-structure.sh [--strict] [--en <path>] [--ko <path>]

Options:
  --strict     Exit non-zero on mismatch.
  --en <path>  English README path (default: README.md)
  --ko <path>  Korean README path (default: README.ko.md)
  -h, --help   Show this message.
USAGE
}

STRICT="false"
README_EN="README.md"
README_KO="README.ko.md"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict)
      STRICT="true"
      shift
      ;;
    --en)
      README_EN="${2:-}"
      shift 2
      ;;
    --ko)
      README_KO="${2:-}"
      shift 2
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

if [[ ! -f "$README_EN" ]]; then
  echo "[FAIL] missing file: $README_EN" >&2
  exit 1
fi
if [[ ! -f "$README_KO" ]]; then
  echo "[FAIL] missing file: $README_KO" >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

EN_HEADINGS="$TMP_DIR/en.tsv"
KO_HEADINGS="$TMP_DIR/ko.tsv"

extract_headings() {
  local src="$1"
  local out="$2"
  awk '
    /^```/ {
      in_code = !in_code
      next
    }
    in_code {
      next
    }
    match($0, /^#{1,6}[[:space:]]+/) {
      level = RLENGTH - 1
      title = substr($0, RLENGTH + 1)
      gsub(/[[:space:]]+$/, "", title)
      idx += 1
      printf "%d\t%d\t%s\n", idx, level, title
    }
  ' "$src" > "$out"
}

extract_headings "$README_EN" "$EN_HEADINGS"
extract_headings "$README_KO" "$KO_HEADINGS"

EN_COUNT="$(wc -l < "$EN_HEADINGS" | tr -d ' ')"
KO_COUNT="$(wc -l < "$KO_HEADINGS" | tr -d ' ')"

FAIL_COUNT=0

report_fail() {
  local msg="$1"
  echo "[FAIL] $msg"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

echo "README structure check"
echo "  en headings : $EN_COUNT ($README_EN)"
echo "  ko headings : $KO_COUNT ($README_KO)"

if [[ "$EN_COUNT" -ne "$KO_COUNT" ]]; then
  report_fail "heading count mismatch: en=$EN_COUNT ko=$KO_COUNT"
fi

MIN_COUNT="$EN_COUNT"
if [[ "$KO_COUNT" -lt "$MIN_COUNT" ]]; then
  MIN_COUNT="$KO_COUNT"
fi

idx=1
while [[ "$idx" -le "$MIN_COUNT" ]]; do
  en_level="$(awk -F '\t' -v i="$idx" '$1 == i { print $2 }' "$EN_HEADINGS")"
  ko_level="$(awk -F '\t' -v i="$idx" '$1 == i { print $2 }' "$KO_HEADINGS")"
  en_title="$(awk -F '\t' -v i="$idx" '$1 == i { print $3 }' "$EN_HEADINGS")"
  ko_title="$(awk -F '\t' -v i="$idx" '$1 == i { print $3 }' "$KO_HEADINGS")"

  if [[ "$en_level" != "$ko_level" ]]; then
    report_fail "heading level/order mismatch at position $idx: en(h$en_level)='$en_title' vs ko(h$ko_level)='$ko_title'"
  fi

  idx=$((idx + 1))
done

if [[ "$EN_COUNT" -gt "$KO_COUNT" ]]; then
  idx=$((KO_COUNT + 1))
  while [[ "$idx" -le "$EN_COUNT" ]]; do
    en_title="$(awk -F '\t' -v i="$idx" '$1 == i { print $3 }' "$EN_HEADINGS")"
    report_fail "missing in $README_KO at position $idx: '$en_title'"
    idx=$((idx + 1))
  done
fi

if [[ "$KO_COUNT" -gt "$EN_COUNT" ]]; then
  idx=$((EN_COUNT + 1))
  while [[ "$idx" -le "$KO_COUNT" ]]; do
    ko_title="$(awk -F '\t' -v i="$idx" '$1 == i { print $3 }' "$KO_HEADINGS")"
    report_fail "extra in $README_KO at position $idx: '$ko_title'"
    idx=$((idx + 1))
  done
fi

if [[ "$FAIL_COUNT" -eq 0 ]]; then
  echo "[PASS] README heading structures are aligned"
  exit 0
fi

if [[ "$STRICT" == "true" ]]; then
  exit 1
fi

exit 0
