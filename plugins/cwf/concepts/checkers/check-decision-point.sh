#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=plugins/cwf/concepts/checkers/lib.sh
source "$SCRIPT_DIR/lib.sh"

concept_check \
  "decision-point" \
  "Decision Point" \
  "plugins/cwf/concepts/decision-point.md" \
  "## Definition" \
  "## Ownership Boundaries" \
  "## Operational Rules" \
  "## Related Concepts"
