# Setup/Update Slim Refactor Plan

## Goal

Reduce `setup`/`update` SKILL body size by extracting command-heavy procedural content into skill-local references, while applying scope-safety findings from latest refactor reruns.

## Inputs

- `refactor-skill-setup.md`
- `refactor-skill-update.md`
- `refactor-holistic-convention.md`
- `refactor-holistic-workflow.md`

## Planned Changes

1. Extract setup Phase `2.4/2.5/2.6` operational details into `plugins/cwf/skills/setup/references/codex-scope-integration.md`.
2. Keep `plugins/cwf/skills/setup/SKILL.md` focused on routing/invariants and reference links.
3. Extract update Phase `0/3` detailed parsing and reconcile matrix into `plugins/cwf/skills/update/references/scope-reconcile.md`.
4. Apply finding fixes:
   - remove `eval` parsing patterns from setup/update scope-resolution instructions
   - add explicit no-fail-open rule on scope detection failure
   - add non-user -> user second-confirmation guard in update
   - reconcile wrapper when wrapper link exists even if status is inactive
   - add alias-bypass boundary note
5. Update skill-local README file maps to include new references.
6. Validate with markdownlint + local link check + provenance freshness + quick-scan deltas.

## Validation Targets

- Markdown lint errors: `0`
- Local link errors: `0`
- Provenance freshness: no stale files
- Setup quick-scan delta: reduced word/line count from previous rerun baseline
- Update quick-scan: no size warning
