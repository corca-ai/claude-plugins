#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$SCRIPT_DIR/../plugins/cwf/scripts/check-growth-drift.sh"

if [[ ! -x "$TARGET" ]]; then
  echo "Missing target script: $TARGET" >&2
  exit 2
fi

exec bash "$TARGET" "$@"
