## Review Synthesis

### Verdict: Revise
Plan direction is valid, but implementation should not start until deterministic gating details are tightened.
Primary blockers were pack-order contract drift, non-executable cutoff enforcement, and missing replay/security constraints for decision persistence.

### Behavioral Criteria Verification
- [ ] Hook block/allow determinism criterion — needs explicit fixture matrix + early execution timing.
- [ ] Decision persistence across compaction/restart — needs schema, replay/supersede constraints, and E2E assertion.
- [ ] `>1200` routing criterion — needs executable routing regression check, not policy text only.
- [x] Runtime script dependency check criterion — deterministic checker path is clear.
- [x] README structure sync criterion — deterministic checker path is clear.
- [ ] Session-log cross-check criterion — currently confidence-note-only; requires deterministic rule shape.
- [ ] Shared-reference extraction criterion — requires measurable conformance threshold.

### Concerns (must address)
- **Correctness (critical)**: Pack order in plan diverged from handoff contract (`A→B→C`), currently `A→C→B`.
  - `.cwf/projects/260217-03-refactor-review-prevention-impl/next-session.md:57`
  - `.cwf/projects/260217-04-refactor-review-prevention-hardening/plan.md:82`
- **Security (high)**: `decision_journal` persistence lacks explicit confidentiality/integrity/replay constraints.
  - `.cwf/projects/260217-04-refactor-review-prevention-hardening/plan.md:85`
  - `.cwf/projects/260217-04-refactor-review-prevention-hardening/plan.md:146`
- **Expert Alpha/Beta (high)**: `>1200` cutoff requires compensating control and executable verification.
  - `.cwf/projects/260217-04-refactor-review-prevention-hardening/plan.md:58`
  - `.cwf/projects/260217-04-refactor-review-prevention-hardening/plan.md:149`
- **UX/DX/Correctness (moderate)**: deterministic gate matrix and rollback/resume contracts are underspecified.
  - `.cwf/projects/260217-04-refactor-review-prevention-hardening/plan.md:43`
  - `.cwf/projects/260217-04-refactor-review-prevention-hardening/plan.md:50`
- **Architecture (moderate)**: parser dedup introduces common-mode risk without explicit fail-closed parser error behavior.
  - `.cwf/projects/260217-04-refactor-review-prevention-hardening/plan.md:71`

### Suggestions (optional improvements)
- Add deterministic gate matrix (command, expected exit code, blocking condition).
- Add decision-journal schema (`decision_id`, `scope`, `supersedes`, `expires_at`) and replay guard tests.
- Add explicit fallback-diversity requirement when external reviewers are skipped.
- Add measurable conformance check for shared-reference extraction.

### Confidence Note
- Reviewer consensus was strict on deterministic testability and replay safety.
- External slots succeeded in real execution:
  - Slot 3 (codex): 88071ms
  - Slot 4 (gemini): 52563ms
- No external fallback was required in this review run.

### Reviewer Provenance
| Reviewer | Source | Tool | Duration |
|----------|--------|------|----------|
| Security | REAL_EXECUTION | claude-task | — |
| UX/DX | REAL_EXECUTION | claude-task | — |
| Correctness | REAL_EXECUTION | codex | 88071 |
| Architecture | REAL_EXECUTION | gemini | 52563 |
| Expert Alpha | REAL_EXECUTION | claude-task | — |
| Expert Beta | REAL_EXECUTION | claude-task | — |
