# Clarify Result

## Task Interpretation
Deliver a pre-deploy full-skill refactor run with maximum practical sub-agent/external-agent usage, excluding Gemini, while preserving deterministic run gates and producing persisted artifacts with commit checkpoints.

## Scope Decision
This run is **gate-safe refactor + targeted quality fixes**, not a full architecture rewrite of all SKILL.md files.

## Decisions

| Decision ID | Decision | Blocking | Reversible | This Run Action |
|---|---|---|---|---|
| D1 | Review gate contract ownership (`run` vs `review`) | no | yes | Defer redesign; keep existing behavior and enforce current deterministic outputs. |
| D2 | `/ship merge` should enforce ship-stage gate | no | yes | Apply now (align ship instructions and artifact contract). |
| D3 | Structured unresolved-item metadata for handoff continuity | no | yes | Apply minimal contract now (template-level structured section in clarify/plan outputs). |
| D4 | Shared context-recovery manifest/helper | no | yes | Defer implementation; keep existing references and document follow-up debt. |
| D5 | Plan→handoff ready signal automation | no | yes | Defer implementation; preserve manual/explicit handoff flow for this run. |

## Accepted Constraints
- No Gemini usage in external review slots.
- No destructive file deletion.
- No new gate categories; satisfy existing `review-code -> refactor -> retro -> ship` contracts.
- Keep changes focused on CWF skills/scripts and current run artifacts.

## Refactor Execution Contract
1. Run `cwf:refactor --skill --holistic` once for cross-skill analysis.
2. Run `cwf:refactor --skill <name>` for **all** CWF skills individually (13/13), not only flagged skills.
3. Persist each per-skill refactor output as stage artifacts in this session.

## Deferred Decision Debt (Non-blocking)
1. D1 full gate-ownership consolidation.
2. D4 context-recovery shared registry/helper.
3. D5 plan-to-handoff automation handshake.

These are recorded as non-blocking debt for a follow-up session.
