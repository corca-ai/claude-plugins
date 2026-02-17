# Plan — Full Skill Refactor Run

## Context
This run executes a full cwf:run-style pre-deploy quality pass across all CWF skills with explicit artifact persistence and checkpoint commits.

The user constraints are:
- maximize practical sub-agent and external-agent usage,
- exclude Gemini,
- run refactor for each skill via `cwf:refactor --skill <name>`,
- persist intermediate outputs and commit progressively.

## Goal
Produce a gate-safe, review-backed refactor pass for all skills and complete run-closing artifacts (`review-code`, `refactor`, `retro`, `ship`) so deployment readiness can be evaluated deterministically.

## Steps
1. Finalize plan-stage artifacts and checkpoint matrix for deterministic verification.
2. Run `review-plan` with six reviewer slots (Security, UX/DX, Correctness, Architecture, Expert Alpha, Expert Beta), using external providers `codex` and `claude` only (no Gemini), and persist all slot outputs + synthesis.
3. Implement approved refactors in code/docs/scripts with commit boundaries:
   - `tidy` changes first,
   - `behavior-policy` changes second.
4. Run `review-code` with six reviewer slots (same provider policy: no Gemini), persist outputs + synthesis, and satisfy `review-code` gate requirements.
5. Execute refactor stage artifacts:
   - run `cwf:refactor --skill --holistic` once,
   - run `cwf:refactor --skill <name>` for all 13 CWF skills:
     `clarify`, `gather`, `handoff`, `hitl`, `impl`, `plan`, `refactor`, `retro`, `review`, `run`, `setup`, `ship`, `update`.
   - persist per-skill outputs and consolidated summary.
6. Run retro stage and persist `retro.md` (+ deep attachments if deep mode is used).
7. Run ship-stage documentation and persist `ship.md` with ambiguity resolution metadata.
8. Run final deterministic checks:
   - `check-session.sh --impl`
   - `check-run-gate-artifacts.sh --stage review-code --stage refactor --stage retro --stage ship --strict --record-lessons`
9. Run plugin lifecycle verification for CWF (`plugin-deploy` consistency flow) and create final checkpoint commit.

## Files to Create/Modify
- `.cwf/projects/260217-05-full-skill-refactor-run/plan.md`
- `.cwf/projects/260217-05-full-skill-refactor-run/plan-draft-agent-a.md`
- `.cwf/projects/260217-05-full-skill-refactor-run/plan-checkpoint-matrix.md`
- `.cwf/projects/260217-05-full-skill-refactor-run/review-*.md`
- `.cwf/projects/260217-05-full-skill-refactor-run/refactor-*.md`
- `.cwf/projects/260217-05-full-skill-refactor-run/retro*.md`
- `.cwf/projects/260217-05-full-skill-refactor-run/ship.md`
- `.cwf/projects/260217-05-full-skill-refactor-run/lessons.md`
- CWF skill/script files required by approved refactor findings.

## Success Criteria — Behavioral (BDD)
- Given plan review inputs, when six-slot `review-plan` runs with no Gemini providers, then six reviewer artifacts and `review-synthesis-plan.md` are persisted with completion sentinels.
- Given implementation changes, when six-slot `review-code` runs, then `review-synthesis-code.md` includes mandatory `session_log_*` fields and `review-code` stage gate passes.
- Given refactor stage execution, when holistic + all 13 per-skill refactor passes are completed, then per-skill outputs are persisted and refactor gate passes.
- Given retro and ship artifacts, when run-closing checks execute, then `retro` and `ship` gates pass and final run-wide gate check passes.

## Success Criteria — Qualitative
- Artifacts are resumable after compaction/restart without hidden conversational dependency.
- Commit history is checkpointed by stage and readable for rollback/audit.
- Deferred architecture debts are explicitly documented, not silently mixed into this run.

## Don't Touch
- Do not delete user-created files.
- Do not introduce Gemini as external reviewer.
- Do not bypass deterministic gates to force completion.

## Deferred Actions
- D1: run/review gate-ownership consolidation.
- D4: shared context-recovery registry/helper.
- D5: automated plan→handoff ready signal.

