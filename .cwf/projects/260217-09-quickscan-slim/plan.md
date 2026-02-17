# Quick Scan Follow-up Plan

## Goal

Resolve full-skill quick-scan findings by fixing gather unreferenced script and slimming refactor/review SKILL docs below warning thresholds.

## Actions

1. Fix `gather` SKILL reference gap for `scripts/csv-to-toon.sh` without behavior changes.
2. Slim `refactor` SKILL by extracting docs-review detailed procedures into a new reference.
3. Slim `review` SKILL by extracting heavy orchestration/fallback and synthesis/template/gates blocks into new references.
4. Update skill-local README file maps and SKILL references to include new docs.
5. Run markdownlint + local link check + full quick-scan, then persist results.
