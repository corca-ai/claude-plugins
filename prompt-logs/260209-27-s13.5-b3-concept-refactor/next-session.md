# Next Session: Post-Concept Refactor

## What happened this session

S13.5-B3 implementation session (3rd session in B3 sequence):

1. **`/ship issue`** — Created GitHub issue #17 for concept refactor work (deferred across 3 prior sessions, finally executed)
2. **6-step implementation** — All steps completed:
   - Created `concept-map.md` (6 generic concepts + 9×6 sync map + usage guide)
   - Created `concept-map.provenance.yaml`
   - Rewrote `holistic-criteria.md` (PP/BI/MC → Form/Meaning/Function)
   - Restructured `review-criteria.md` (merged 4+5, added criterion 8 Concept Integrity)
   - Updated `SKILL.md` (agent prompts, rules, references)
   - Updated provenance sidecars (last_reviewed: S13.5-B3, hook_count: 14)

## What changed this session

| File | Change |
|------|--------|
| `plugins/cwf/references/concept-map.md` | NEW: 6 concepts + 9×6 sync map + usage guide |
| `plugins/cwf/references/concept-map.provenance.yaml` | NEW: provenance sidecar |
| `plugins/cwf/skills/refactor/references/holistic-criteria.md` | REWRITE: Form/Meaning/Function 3 axes |
| `plugins/cwf/skills/refactor/references/review-criteria.md` | RESTRUCTURE: 8 criteria (merged 4+5, added 8) |
| `plugins/cwf/skills/refactor/SKILL.md` | EDIT: agent prompts, rules 3-4, references |
| `holistic-criteria.provenance.yaml` | EDIT: last_reviewed, designed_for, hook_count→14 |
| `review-criteria.provenance.yaml` | EDIT: last_reviewed, hook_count→14 |

## What needs to happen next

1. **PR creation** — `/ship pr` for `feat/concept-refactor-integration` → `marketplace-v3`
2. **Provenance housekeeping** — 5 STALE sidecars (hook_count 13→14) need updating: CLAUDE, project-context, expert-advisor-guide, skill-conventions, docs-criteria
3. **Validation run** — Run `refactor --holistic` and `refactor --skill clarify` with restructured frameworks to verify real-world behavior

## Context Files to Read

1. `plugins/cwf/references/concept-map.md` — NEW reference document
2. `plugins/cwf/skills/refactor/references/holistic-criteria.md` — restructured holistic framework
3. `plugins/cwf/skills/refactor/references/review-criteria.md` — restructured review criteria
4. `prompt-logs/260209-27-s13.5-b3-concept-refactor/lessons.md` — 17 lessons accumulated across 3 sessions

## Unresolved Items

- [ ] 5 STALE provenance sidecars (hook_count 13→14): CLAUDE, project-context, expert-advisor-guide, skill-conventions, docs-criteria
- [ ] Expert roster update: consider adding James Reason and Sidney Dekker (used in S13.5-B3 retro)
- [ ] Hook audit: scan all hook scripts for silent `exit 0` paths without observable output
- [ ] Validation: run restructured refactor modes on real skills to verify
