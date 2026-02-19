# Clarify — Refactor Review Prevention Run

## Clarified Scope
- Implement now (P0/P1): `A`, `B`, `C`, `E+G`.
- Defer (P2+): `D`, `F`, `H`, `I`.

## Clarified Decisions
1. Workflow enforcement must be deterministic and compaction-immune.
2. `remaining_gates` must be stored as YAML list (not comma-separated scalar).
3. UserPromptSubmit hook should both:
   - warn on active pipeline status each turn
   - fail-closed block forbidden prompt intents while required gates remain
4. Add explicit override mechanism via `live.pipeline_override_reason`.
5. Deletion safety is fail-closed on analysis errors.

## Out of Scope
- Session-log cross-check mode in `cwf:review`.
- New static script dependency graph checker.
- README structure sync checker and pattern extraction wave.
