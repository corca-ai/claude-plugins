# Plan: S18 — Execute Hardened S16 Gap-Analysis Protocol

## Context

S16 produced the baseline handoff for exhaustive v3 gap analysis. S17 hardened
that handoff protocol (scope freeze, full manifest, stable IDs, semantic gates).
This session executes the hardened protocol end-to-end against the frozen range.

## Goal

Produce omission-resistant analysis artifacts (Phase -1 to Phase 6) with
traceable IDs and semantic completion checks, without introducing feature
implementation changes.

## Scope

- Execute S16 hardened workflow over frozen range `42d2cd9..END_SHA`
- Build required artifacts:
  - scope-freeze.md
  - analysis-manifest.md (+ appendix)
  - coverage-matrix.md
  - user-utterances-index.md
  - gap-candidates.md
  - consistency-check.md
  - discussion-backlog.md
  - completion-check.md
  - summary.md
- Create session artifacts (plan.md, lessons.md, next-session.md)
- Register session in `cwf-state.yaml`

## Steps

1. Freeze scope (`START_SHA=42d2cd9`, `END_SHA=HEAD`) and write scope-freeze.md.
2. Build full bucket manifest and enforce Phase 0.5 completeness gate.
3. Create implementation coverage matrix from decisions, inventory, milestones.
4. Extract/redact user utterances with stable `UTT-*` IDs.
5. Mine and classify `GAP-*` candidates, then run bidirectional `CW-*` check.
6. Build `BL-*` discussion backlog and semantic completion gate.
7. Write summary and session artifacts; persist session state.

## Success Criteria

### Behavioral (BDD)

```gherkin
Given a frozen RANGE from scope-freeze.md
When analysis artifacts are generated
Then each required artifact references the same RANGE

Given unresolved or unknown GAP items
When discussion-backlog.md is created
Then every open GAP appears in at least one BL item

Given consistency-check.md with CW findings
When closure is verified
Then every CW maps to a valid GAP

Given user utterances are indexed
When redaction checks run
Then no live secret-like string remains in the output
```

### Qualitative

- Artifacts remain audit-friendly with stable IDs and explicit evidence paths.
- Uncertainty is preserved as `Unknown` instead of collapsed conclusions.
- Analysis remains execution-focused and avoids unrelated feature development.

## Files to Create/Modify

| File | Action | Purpose |
|---|---|---|
| prompt-logs/260211-05-s18-v3-gap-analysis-execution/* | Create | Phase -1~6 outputs and session artifacts |
| cwf-state.yaml | Edit | Register S18 and update live state |

## Don't Touch

- `plugins/cwf/**` implementation logic
- `docs/**` content (except reading for evidence)
- `README.md`, `README.ko.md`

## Deferred Actions

- [ ] Convert top-priority backlog items (BL-001/BL-002/BL-003) into an implementation plan session.
