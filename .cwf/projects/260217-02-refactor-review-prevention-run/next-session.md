# Next Session

## Continue From
- Session: `260217-02-refactor-review-prevention-run`
- Branch: `feat/260217-run-review-prevention`
- Context carry-over: `cwf:setup` now owns installation attempts for deterministic runtime dependencies (including markdown/link tooling) so gates do not depend on ad-hoc environment state.

## Priority Follow-ups
1. Implement Proposal D (`check-script-deps.sh`) and wire into pre-push profile.
2. Implement Proposal F (session-log cross-check extension in `cwf:review --mode code`).
3. Implement Proposal H (README structure sync deterministic checker).
4. Implement Proposal I (extract repeated persistence/research blocks into shared references).
5. Run a focused linter-disable review and structural hardening pass.

## User Prompt To Run
`관찰하다보니 linter 가 disable되는 경우가 많이 보이는데 원인을 알고 싶고, 구조적 개선이 가능한지 궁금합니다.`

## Linter-Disable Review Plan
- Inventory all linter suppressions in CWF scripts/docs (`shellcheck disable`, markdownlint ignores, ad-hoc skip patterns).
- Classify each suppression:
  - justified by tooling limitation (for example sourced-file resolution, indirect variable usage),
  - compensating for avoidable design choices,
  - stale/obsolete.
- For each non-justified or stale suppression, propose structural fixes first (path normalization, helper extraction, explicit contracts) before adding/removing suppressions.
- Define acceptance criteria:
  - reduction in suppression count where safe,
  - no new false-negative risk in deterministic gates,
  - clean lint/test passes with updated rationale comments for remaining justified suppressions.
- Persist findings in:
  - `retro.md` under `Post-Retro Findings`,
  - `lessons.md` as a short operational rule,
  - implementation plan if cross-cutting refactor is required.

## Validation Checklist
- Re-run `check-growth-drift.sh --level warn`
- Re-run targeted hook tests for `workflow-gate.sh` and `check-deletion-safety.sh`
- Run `shellcheck -x` on modified scripts and verify suppressions are still necessary.
- If shipping, run `/ship` only after review-code/refactor/retro gates are confirmed complete.
