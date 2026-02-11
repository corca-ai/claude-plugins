# Next Session: S19 — Resolve Top Open Gaps from S18

## Context

S18 executed the hardened S16 protocol and produced 15 GAP items:
5 Unresolved, 2 Unknown, 7 Resolved, 1 Superseded.
Highest-impact open items are BL-001, BL-002, BL-003.

## Context Files to Read First

1. `prompt-logs/260211-05-s18-v3-gap-analysis-execution/gap-decisions.md` (SSOT for decisions DEC-001~DEC-007)
2. `prompt-logs/260211-05-s18-v3-gap-analysis-execution/summary.md` (latest counts/status)
3. `prompt-logs/260211-05-s18-v3-gap-analysis-execution/discussion-backlog.md` (BL mapping)

## Execution Contract (Mention-Only Safe)

If the user mentions only this file, treat that as an instruction to run the CWF pipeline.

- Required mode: `cwf:run` orchestration
- Required stage order: `clarify -> plan -> review(plan) -> impl -> review(code) -> retro`
- Skip policy: do not skip pre-impl gates; do not jump directly into impl
- Decision policy: DEC-001~DEC-007 are binding constraints unless the user explicitly overrides them
- Validation policy: run `scripts/check-session.sh --impl` before completion

## Task

Convert the top unresolved backlog items into concrete implementation changes
with deterministic tests:

1. BL-001 / GAP-001: implement `cwf:review --scenarios` properly before v3 merge
   (decision fixed; no defer-to-v4 path).
2. BL-002 / GAP-002: add umbrella-safe base branch selection (`--base` or
   equivalent deterministic branch policy).
3. BL-003 / GAP-005: include `sessions-codex/*.md` in retro/handoff source
   discovery contracts.

Decision anchors already fixed:
- `DEC-001` (GAP-001): implement before v3 merge (no defer).
- `DEC-002` (GAP-002): upstream-aware default + `--base` override.
- `DEC-003` (GAP-003): keep `Unknown` until dedicated closure trace finalizes class.
- `DEC-004` (GAP-004): keep policy-level guidance; no extra hard gate before v3 merge.
- `DEC-005` (GAP-005): unify runtime logs under `sessions/` with `.codex/.claude` suffix + legacy compatibility read.
- `DEC-006` (GAP-006): hybrid sub-agent persistence gating (hard for critical, soft for non-critical).
- `DEC-007` (GAP-014): minimal semantic extension of `check-session.sh` first (option 2).

## Success Criteria

- Each selected gap is moved to Resolved or Superseded with explicit evidence.
- Updated skills include BDD-style acceptance checks for new behavior.
- `check-session.sh --impl` passes and session state is registered.

## Start Command

```text
@prompt-logs/260211-05-s18-v3-gap-analysis-execution/next-session.md 시작합니다
```
