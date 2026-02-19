# Clarify Result — Deferred-Inclusive Hardening Scope

## Scope Lock (User-directed)

This session includes both:

1. Post-merge hardening packs (A/B/C)
2. All deferred/carry-forward items from
   `.cwf/projects/260217-03-refactor-review-prevention-impl/next-session.md`

## Included Work Items

- Pack A: linter-disable structural reduction
- Pack B: hook exit-code integration tests
- Pack C: compaction-immune AskUserQuestion decision persistence
- Proposal D: script dependency graph automation in pre-push
- Proposal F: session log cross-check integration in `cwf:review --mode code`
- Proposal H: README structure sync deterministic checker
- Proposal I: shared reference extraction for repeated patterns
- Add `deletion_safety` + `workflow_gate` to `cwf:setup` hook group selection
- Proposal C structural fix: triage output format carries original recommendation inline
- Consolidate duplicated YAML parsing in `workflow-gate.sh` via shared helper usage
- Hook path-based filtering improvements to reduce false triggers on `/tmp` prompt artifacts
- Review policy hardening: `>1200` prompt direct external-CLI skip + fallback provenance

## Constraints

- Keep prevention hooks in place; do not remove:
  - `plugins/cwf/hooks/scripts/check-deletion-safety.sh`
  - `plugins/cwf/hooks/scripts/workflow-gate.sh`
- Do not weaken deterministic gates in `plugins/cwf/scripts/check-growth-drift.sh`.
- Do not rewrite historical evidence under:
  - `.cwf/projects/260217-02-refactor-review-prevention-run/`
  - `.cwf/projects/260217-03-refactor-review-prevention-impl/merge-preserved/`

## Branch/Commit Contract

- Branch: feature branch (not `marketplace-v3` direct implementation)
- Commit in meaningful units (per pack/proposal cluster)
- Stage only intended files per commit

## Open Questions

None blocking. Proceed with plan review, then implementation.
