# Clarify Result: S19 Resolve Top Open Gaps

## Original Requirement
"Resolve BL-001, BL-002, BL-003 from S18 using the bound decisions DEC-001..DEC-007, in cwf:run stage order without skipping pre-impl gates."

## Decision Points
1. How should `cwf:review --scenarios <path>` behave when the file is missing or malformed?
2. How should `cwf:review` choose the diff base by default, and how should `--base <branch>` override it?
3. Which runtime log locations must retro/handoff consider during migration (`sessions` vs `sessions-codex`)?

## Agent Decisions (T1/T2)

| # | Tier | Decision | Evidence |
|---|------|----------|----------|
| 1 | T1 | `--scenarios` must be executable, not advisory. Missing/invalid input must fail explicitly; valid input must be reflected in synthesis/provenance. | `prompt-logs/260211-05-s18-v3-gap-analysis-execution/gap-decisions.md` (DEC-001 DoD) |
| 2 | T1 | Base policy is dual: upstream-aware default + deterministic `--base` override; invalid override must be explicit. | `prompt-logs/260211-05-s18-v3-gap-analysis-execution/gap-decisions.md` (DEC-002 DoD) |
| 3 | T1 | Runtime logs migrate to `prompt-logs/sessions/` with runtime suffixes and temporary compatibility reads from legacy paths. | `prompt-logs/260211-05-s18-v3-gap-analysis-execution/gap-decisions.md` (DEC-005 DoD) |

## Requires Human Decision (T3)
None. The required decisions are already fixed by DEC-001/002/005.
