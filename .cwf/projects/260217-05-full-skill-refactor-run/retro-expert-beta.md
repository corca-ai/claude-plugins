# Expert Beta (Retro)

## Observations
- The run artifact set improved architectural traceability: `run-stage-provenance.md` now records stage-level execution with explicit Stage/Skill separation (`impl -> cwf:impl`), which restores the orchestrator-versus-stage boundary.
- Deterministic governance moved in the right direction: code review synthesis confirms stage-close gates now validate provenance schema and minimum row count, reducing prose-only policy drift.
- Cross-skill concept consistency improved: concept-map provenance metadata was aligned with current hook inventory, and several skills now reference canonical guidance files instead of duplicating policy text.
- Remaining integrity gap: some provenance checks in refactor flow are still `inform`-only, so stale or semantically weak provenance can still pass without hard escalation.
- Pipeline composability risk remains: newly added interactive branches (notably around handoff/run edge cases) can stall unattended run-chain execution unless auto-mode behavior is explicitly bounded.
- Known architecture debts (`D1`, `D4`, `D5`) remain open and continue to fragment ownership, context recovery, and stage handoff signaling.

## Agreements / Risks
- Agreement: preserving deterministic gates as the final authority (not narrative guidance) is the correct architectural baseline and was reinforced in this run.
- Agreement: provenance must remain machine-checkable and stage-scoped to be audit-reliable; the current direction is correct.
- Agreement: cross-skill canonical references reduce concept drift and improve long-term maintainability.
- Risk: provenance integrity is not fully fail-closed until semantic validation (for example Stage->Skill mapping correctness and stale-reference thresholds) is enforced by deterministic checks.
- Risk: interactive recovery branches without explicit non-interactive fallback can create deadlocks in `cwf:run` automation contexts.
- Risk: deferred debts (`D1`, `D4`, `D5`) can reintroduce architecture drift by leaving gate ownership, context registry, and plan-to-handoff signaling partially implicit.

## Recommended Next Actions
1. Add a deterministic semantic validator for run provenance (Stage->Skill mapping, enum validity, timestamp/duration shape) and wire it into both stage-close and final run gate paths.
2. Upgrade refactor provenance checks from `inform` to threshold-based escalation (`warn`/`block`) so significant provenance drift cannot silently proceed.
3. Define and document explicit non-interactive behavior for new interactive branches (`--auto` or equivalent fallback contract) to keep unattended pipelines composable.
4. Execute D1/D4/D5 as one architecture hardening bundle, then bind each outcome to a deterministic gate or script check to prevent policy-only regression.
5. Add one lightweight architecture regression test that fails if concept-map provenance counters and runtime hook inventory diverge again.

<!-- AGENT_COMPLETE -->
