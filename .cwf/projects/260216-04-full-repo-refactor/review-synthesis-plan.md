## Review Synthesis

### Verdict: Revise

The prevention proposal demonstrates strong incident analysis (Sections 1-5) but the proposed solutions (Section 6) have structural gaps that 5 of 6 reviewers converged on independently. Two critical issues require revision before implementation.

### Concerns (must address)

- **Cross-reviewer consensus [critical]: Proposal E+G is advisory-only — no fail-closed gate.**
  Security, Correctness, Architecture, and Expert Alpha all identified that the workflow-gate hook *informs* but does not *block*. The hook outputs a reminder, but the agent can still proceed with direct edits. For the system's core value ("compaction-immune workflow enforcement"), at least one hard gate is needed — e.g., a pre-commit hook that exits non-zero if `remaining_gates` includes `review-code` and no review artifact exists.
  - Correctness [C1]: "fail-closed 경로가 없습니다"
  - Architecture [critical]: "purely prescriptive hook might prevent progress" (needs bypass mechanism too)
  - Expert Alpha [C2]: "prevention-only with no recovery layer"

- **Cross-reviewer consensus [critical]: Proposal A must be a deterministic gate, not prose.**
  UX/DX, Expert Alpha, and Expert Beta all flagged that calling A a "safety gate" while implementing it as prose text in SKILL.md contradicts the document's own analysis that prose is compaction-vulnerable. A should be a hook script or integrated into Proposal D's infrastructure.
  - UX/DX [C3]: "prose is not a deterministic gate — contradicts AGENTS.md invariant"
  - Expert Alpha [C1]: "internally inconsistent with the document's own analysis"
  - Expert Beta [C2]: "Proposal A is undervalued — the only mechanism at the actual decision point"

- **UX/DX [critical]: Hook event type must be resolved.**
  Proposal E leaves the hook placement ambiguous between `UserPromptSubmit` and `Notification`. Only `UserPromptSubmit` fires before the agent acts, providing the correct timing for a safety gate. This must be resolved definitively.

- **Security [moderate]: YAML injection risk in `user_directive` field.**
  The `cwf-live-state.sh` scalar upsert function only escapes backslashes and double quotes. Arbitrary user text in `user_directive` could corrupt YAML via colons, newlines, or brackets. Needs sanitization or type constraint.

- **UX/DX [moderate]: `workflow` field name collision.**
  `cwf-state.yaml` already has a root-level `workflow:` key. Adding `live.workflow` creates semantic ambiguity. Use a distinct key name (e.g., `active_pipeline` or `run_chain`).

- **UX/DX [moderate]: `remaining_gates` representation mismatch.**
  Storing as comma-separated string conflicts with existing YAML list convention for multi-value fields (`key_files`, `decisions`). Needs consistent representation.

- **Correctness [moderate]: Proposal A's grep scope too narrow.**
  Searching only `*.sh/*.md/*.mjs` misses yaml, json, python, hook config, and dynamically constructed paths. A false "safe to delete" is worse than no check.

- **Expert Beta [moderate]: Proposal C undervalued at P2.**
  The 5 Whys stops short of analyzing why the triage artifact's structure made deletion the "obvious" action. C addresses the actual decision-point distortion and should be elevated to P1.

### Suggestions (optional improvements)

- **Expert Alpha**: Reframe priority matrix by defense layers (prevention / detection / recovery) — reveals empty recovery layer
- **Expert Beta**: Add pre-mortem step to impl for high-risk actions (deletions, renames)
- **Correctness**: Add `session_id`, `state_version`, `updated_at` to state updates for CAS-style stale-write prevention
- **Architecture**: Add `override_reason` / `manual_mode` field for legitimate gate bypass with user consent
- **Architecture**: Generate `plan-summary.json` at plan phase for machine-readable cross-reference in Proposal F
- **UX/DX**: Add BDD acceptance checks for all 7 proposals (follows established project convention)
- **UX/DX**: Specify implementation order within P0 tier (A→B→E+G ascending effort)
- **Security**: Implement Proposals A and B as deterministic hooks rather than prose rules for compaction immunity
- **Correctness**: Proposal B should classify caller types (runtime / build / test / docs / stale) before deciding action

### Confidence Note

- **Strong cross-reviewer convergence** on the two critical issues (E+G advisory gap, A as prose). 5 of 6 reviewers independently flagged these, increasing confidence in the verdict.
- **Expert disagreement on E+G primacy**: Expert Alpha (Reason) views E+G as creating a single point of reliance, while Expert Beta (Klein) views E+G as overweighted because the actual protection comes from the downstream review-code gate, not the notification mechanism itself. Both perspectives suggest E+G is necessary but insufficient — a hard gate and direct decision-point intervention (A as hook) are both needed.
- No success criteria found — review based on general best practices only.
- Base: N/A (plan mode, not code mode).
- All 6 reviewers produced valid output; no fallbacks needed.

### Reviewer Provenance

| Reviewer | Source | Tool | Duration |
|----------|--------|------|----------|
| Security | REAL_EXECUTION | claude-task | — |
| UX/DX | REAL_EXECUTION | claude-task | — |
| Correctness | REAL_EXECUTION | codex | 68681ms |
| Architecture | REAL_EXECUTION | gemini | 89031ms |
| Expert Alpha (James Reason) | REAL_EXECUTION | claude-task | — |
| Expert Beta (Gary Klein) | REAL_EXECUTION | claude-task | — |
