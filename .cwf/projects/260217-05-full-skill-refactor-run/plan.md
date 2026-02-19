# Plan — Full Skill Refactor Run

## Context
This run executes a full cwf:run-style pre-deploy quality pass across all CWF skills with explicit artifact persistence and checkpoint commits.

The user constraints are:
- maximize practical sub-agent and external-agent usage,
- keep external-review provider policy flexible by contract (no hard vendor lock),
- run refactor for each skill via `cwf:refactor --skill <name>`,
- persist intermediate outputs and commit progressively.

## Goal
Produce a gate-safe, review-backed refactor pass for all skills and complete run-closing artifacts (`review-code`, `refactor`, `retro`, `ship`) so deployment readiness can be evaluated deterministically.

## Steps
1. Finalize plan-stage artifacts and checkpoint matrix for deterministic verification.
2. Run `review-plan` with six reviewer slots (Security, UX/DX, Correctness, Architecture, Expert Alpha, Expert Beta), and persist all slot outputs + synthesis.
   - Immediately run stage-local strict verification from `plan-checkpoint-matrix.md` (fail-fast).
   - Apply provider policy through gate contract (`provider_gemini_mode`), not hard-coded vendor denial.
3. Implement approved refactors in code/docs/scripts with commit boundaries:
   - `tidy` changes first,
   - `behavior-policy` changes second.
4. Run `review-code` with six reviewer slots, persist outputs + synthesis, and satisfy `review-code` gate requirements under contract policy.
5. Execute refactor stage artifacts:
   - run `cwf:refactor --skill --holistic` once,
   - run `cwf:refactor --skill <name>` for all 13 CWF skills:
     `clarify`, `gather`, `handoff`, `hitl`, `impl`, `plan`, `refactor`, `retro`, `review`, `run`, `setup`, `ship`, `update`.
   - after each run, snapshot outputs into per-skill files to prevent overwrite collisions:
     - `refactor-skill-<name>.md`
     - `refactor-skill-<name>-deep-structural.md` (if generated)
     - `refactor-skill-<name>-deep-quality.md` (if generated)
   - persist consolidated summary and run stage-local strict verification from `plan-checkpoint-matrix.md`.
6. Run retro stage and persist `retro.md` (+ deep attachments if deep mode is used).
   - run stage-local strict verification immediately after artifact write.
7. Run ship-stage documentation and persist `ship.md` with ambiguity resolution metadata.
   - run stage-local strict verification immediately after artifact write.
8. Run plugin lifecycle verification for CWF (`plugin-deploy` consistency flow).
9. Run final deterministic checks (after plugin lifecycle verification):
   - `check-session.sh --impl`
   - `check-run-gate-artifacts.sh --stage review-code --stage refactor --stage retro --stage ship --strict --record-lessons`
10. Create final checkpoint commit.

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
- Given plan review inputs, when six-slot `review-plan` runs, then six reviewer artifacts and `review-synthesis-plan.md` are persisted with completion sentinels.
- Given implementation changes, when six-slot `review-code` runs, then `review-synthesis-code.md` includes mandatory `session_log_*` fields and `review-code` stage gate passes.
- Given refactor stage execution, when holistic + all 13 per-skill refactor passes are completed, then 13 `refactor-skill-<name>.md` files exist and refactor gate plus per-skill completeness check both pass.
- Given retro and ship artifacts, when run-closing checks execute, then `retro` and `ship` gates pass and final run-wide gate check passes.

## Success Criteria — Qualitative
- Artifacts are resumable after compaction/restart without hidden conversational dependency.
- Commit history is checkpointed by stage and readable for rollback/audit.
- Deferred architecture debts are explicitly documented, not silently mixed into this run.

## Don't Touch
- Do not delete user-created files.
- Do not bypass deterministic gates to force completion.

## Deferred Actions
- D1: run/review gate-ownership consolidation.
- D4: shared context-recovery registry/helper.
- D5: automated plan→handoff ready signal.
