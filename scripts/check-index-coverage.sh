#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$SCRIPT_DIR/../plugins/cwf/skills/setup/scripts/check-index-coverage.sh"

if [ ! -f "$TARGET" ]; then
  echo "Missing target script: $TARGET" >&2
  exit 2
fi

exec bash "$TARGET" "$@"
