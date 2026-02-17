# Lessons — refactor-review-prevention-hardening

## Protocol Discrepancy — Plan Review External Slots

- **Expected (Protocol)**: In review mode, launch all 6 slots in one pass and include external slots (Codex/Gemini routing) as first-class reviewers.
- **Actual**: Internal Task reviewers were launched first; external Codex/Gemini slots were executed only after user challenge.
- **Impact**: Review flow deviated from protocol order and required user correction; no data loss, but trust and process fidelity were degraded.
- **Root Cause**: Execution shortcut (speed-first) over strict phase fidelity.
- **Immediate Correction**: External slots were run and included in plan-review artifacts.
- **Pending Decision**: Keep protocol strict (fail on out-of-order launch) or revise protocol to allow two-phase launch with explicit preconditions.

## Guardrail Going Forward

- Before any review run, execute a preflight checklist:
  1. `mode` confirmed
  2. 6-slot launch plan confirmed (internal/external/experts)
  3. external-provider availability check logged
  4. one-pass parallel launch decision recorded
