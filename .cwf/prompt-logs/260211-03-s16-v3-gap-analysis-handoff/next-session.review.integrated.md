# Integrated Review: `next-session.md` (Codex + Claude)

## Sources

- `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.review.codex.md`
- `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.review.claude.md`
- Target: `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md`

## Final Verdict

**Revise**

Rationale:
- Both reviews report multiple `critical` concerns.
- Review skill rule says any `critical/security` concern => `Revise`.

## Consensus Concerns (high agreement)

### 1) [critical] Scope declaration vs manifest intake mismatch

Hard Scope declares `42d2cd9..HEAD` with non-`prompt-logs` inputs (`cwf-state.yaml`, `docs/v3-migration-decisions.md`, `plugins/cwf/**`), but Phase 0 manifest command only enumerates `prompt-logs/**`.

- Evidence:
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:27`
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:32`
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:35`
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:77`
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:190`

### 2) [critical] Mutable `HEAD` undermines reproducibility

`42d2cd9..HEAD` has no freeze step. If commits arrive during analysis, phase inputs can diverge.

- Evidence:
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:27`

### 3) [moderate] Completion checks are existence-heavy, content-light

Current criteria verify artifact presence but weakly enforce content integrity and cross-artifact closure.

- Evidence:
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:186`
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:195`
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:196`

## Complementary Concerns (valuable, not universal)

### A) [security] Verbatim utterance extraction without mandatory redaction

Potential secret/PII re-exposure in derived artifacts.

- Evidence:
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:112`
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:120`

### B) [moderate] Milestone label drift vs `cwf-state.yaml`

Milestone labels in Phase 1 may not align with currently used session IDs.

- Evidence:
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:94`
  - `cwf-state.yaml:184`
  - `cwf-state.yaml:224`
  - `cwf-state.yaml:232`

### C) [moderate] Traceability between mined gaps and backlog is not enforced

No required stable key/backlink to guarantee every unresolved/unknown candidate survives into discussion backlog.

- Evidence:
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:164`
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:171`
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:195`

## Integrated Fix Plan (priority order)

1. Add `Scope Freeze` step at session start:
   - `END_SHA=$(git rev-parse HEAD)` and use `42d2cd9..$END_SHA` everywhere.
2. Replace Phase 0 intake with full-scope manifest:
   - Enumerate all declared include buckets, not only `prompt-logs/**`.
3. Add traceability contract:
   - Introduce stable IDs (for example `GAP-###`) propagated from candidates to backlog.
4. Upgrade completion checks to semantic checks:
   - Require unresolved/unknown closure mapping and minimum evidence fields.
5. Add redaction rule for utterance extraction:
   - Mask secrets/tokens and allow short verbatim only when necessary.
6. Align milestone vocabulary with `cwf-state.yaml` IDs or define translation mapping.

## Behavioral Criteria Re-check (integrated)

- [ ] Self-contained autonomous execution in a new session
- [ ] Omission-resistant scope anchored to `42d2cd9..HEAD`
- [ ] End-to-end coverage with guaranteed closure (mapping/mining/gap/backlog)
- [x] Concrete artifact list exists
- [x] Analysis-first constraint exists

## Confidence Note

- Strong agreement on scope-control defect (most reviewers converged).
- Main reviewer disagreement was verdict label (`Conditional Pass` vs `Revise`), resolved by explicit rule precedence (`critical` present => `Revise`).
