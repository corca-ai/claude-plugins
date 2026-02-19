# Quick Scan Follow-up Results

## Scope

- Fix gather unreferenced script flag (`scripts/csv-to-toon.sh`)
- Slim refactor/review SKILL docs by extracting heavy procedures to references

## Changes Applied

1. `plugins/cwf/skills/gather/SKILL.md`
   - Added explicit script reference to `scripts/csv-to-toon.sh` in Google Export section.

2. `plugins/cwf/skills/refactor/SKILL.md`
   - Replaced verbose `--docs` procedure block with concise routing summary.
   - Added references to deterministic docs-mode helper scripts.

3. `plugins/cwf/skills/refactor/references/docs-review-flow.md` (new)
   - Moved full docs-review procedure details from SKILL body.

4. `plugins/cwf/skills/review/SKILL.md`
   - Slimmed heavy blocks into references:
     - Phase 2.3 slot-launch templates
     - Phase 3.2 external failure classifier/fallback template
     - Phase 4.2 synthesis markdown template
     - Error handling matrix and BDD acceptance checks

5. New review references
   - `plugins/cwf/skills/review/references/orchestration-and-fallbacks.md`
   - `plugins/cwf/skills/review/references/synthesis-and-gates.md`

6. File-map updates
   - `plugins/cwf/skills/refactor/README.md`
   - `plugins/cwf/skills/review/README.md`

## Metrics

- Previous full quick scan summary (before this follow-up):
  - `total_skills=13`, `warnings=4`, `errors=0`, `flagged_skills=3`
  - flagged: `gather`, `refactor`, `review`

- Current full quick scan summary (after changes):
  - `total_skills=13`, `warnings=0`, `errors=0`, `flagged_skills=0`

### Key size deltas

- `refactor/SKILL.md`: `511` lines -> `417` lines
- `review/SKILL.md`: `783` lines -> `480` lines

## Validation

- markdownlint: pass
- local links: pass
- quick-scan: pass (no flags)

Raw output:
- `quick-scan-after.json`
