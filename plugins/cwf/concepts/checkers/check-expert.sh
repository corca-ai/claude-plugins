#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=plugins/cwf/concepts/checkers/lib.sh
source "$SCRIPT_DIR/lib.sh"

concept_check \
  "expert" \
  "Expert" \
  "plugins/cwf/concepts/expert.md" \
  "## Definition" \
  "## Ownership Boundaries" \
  "## Operational Rules" \
  "## Related Concepts"
