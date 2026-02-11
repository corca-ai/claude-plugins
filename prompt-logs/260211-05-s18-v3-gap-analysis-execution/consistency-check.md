# Consistency Check

- RANGE: 42d2cd9..01293b3e2501153789e40699c09777ac6df64624

## Pass 1: Early -> Late

| finding_id | pass_origin | linked_gap_id | evidence_paths | why_other_pass_missed_it |
|---|---|---|---|---|
| CW-001 | early->late | GAP-001 | prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md; plugins/cwf/skills/review/SKILL.md | Late->early starts from current implementation, so future-intent placeholders in early plan docs are easy to underweight. |
| CW-002 | early->late | GAP-002 | prompt-logs/sessions/260209-0654-4892fa43.md; plugins/cwf/skills/review/SKILL.md | Late->early sees current base-branch heuristics as “working enough” unless historical umbrella-branch failures are replayed. |
| CW-003 | early->late | GAP-003 | prompt-logs/260209-26-s13.5-b2-concept-distillation/lessons.md; prompt-logs/260209-27-s13.5-b3-concept-refactor/session.md | Later concept refactor activity can be mistaken for full closure unless early “미구현” wording is checked line-by-line. |
| CW-004 | early->late | GAP-013 | prompt-logs/260209-27-s13.5-b3-concept-refactor/retro.md; docs/v3-migration-decisions.md | Starting late obscures that this was a repeated historical failure pattern rather than a one-off issue. |

## Pass 2: Late -> Early

| finding_id | pass_origin | linked_gap_id | evidence_paths | why_other_pass_missed_it |
|---|---|---|---|---|
| CW-005 | late->early | GAP-005 | plugins/cwf/skills/retro/SKILL.md; plugins/cwf/skills/handoff/SKILL.md; prompt-logs/sessions-codex/260211-1245-1b3ecb59.md | Early->late focuses on historical intent; it can miss present-tense ingestion omissions that are visible only in current skill contracts. |
| CW-006 | late->early | GAP-006 | prompt-logs/260211-03-s16-v3-gap-analysis-handoff/session.md; plugins/cwf/references/context-recovery-protocol.md | Early->late tends to see protocol introduction as closure and miss continued recurrence signals in recent sessions. |
| CW-007 | late->early | GAP-014 | scripts/check-session.sh; cwf-state.yaml; docs/v3-migration-decisions.md | Early->late tracks decision creation; it can miss enforcement granularity gaps in present scripts/state checks. |
| CW-008 | late->early | GAP-004 | docs/v3-migration-decisions.md; plugins/cwf/skills/review/SKILL.md | Early->late accepts philosophical decisions as “done” unless reverse pass asks for executable control hooks. |

## One-Way Closure Result

- Every `CW-*` maps to an existing `GAP-*`.
- No additional `GAP-*` creation was required in this pass.
