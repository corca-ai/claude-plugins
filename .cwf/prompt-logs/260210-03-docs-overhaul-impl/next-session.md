# Next Session: S33 — CDM Improvements + Auto-Chaining Protocol

## Context

- Read: `cwf-state.yaml` (session history, live state, expert roster)
- Read: `prompt-logs/260210-03-docs-overhaul-impl/retro.md` (CDM 1-4 findings)
- Read: `prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md` (S13.6 scope, architecture decisions)
- Read: `docs/project-context.md` (3 new heuristics from S32-impl retro)
- Branch: `marketplace-v3`

## Task

Implement 4 CDM-driven improvements from S32-impl retro + design S13.6 auto-chaining protocol.

## Scope

### Part A: CDM Improvements (incremental, can be done directly)

1. **CDM 1 — Plan template cross-cutting check** (`plugins/cwf/skills/plan/SKILL.md`)
   - Add a gate in plan drafting: "When identical logic applies to 3+ targets, specify a shared reference file as Step 0"
   - Prohibit "동일 적용" / "apply the same pattern" as plan instructions
   - Reference: `docs/project-context.md` "Cross-cutting pattern → shared reference first" heuristic

2. **CDM 2 — Impl commit strategy branching** (`plugins/cwf/skills/impl/SKILL.md`)
   - Add cross-cutting assessment before commit strategy selection
   - When changes are cross-cutting: commit boundary = change pattern (not work item)
   - When changes are modular: per-work-item commits (current behavior)

3. **CDM 3 — Phase-aware compact recovery** (`plugins/cwf/hooks/scripts/session-start-compact.sh`)
   - Detect current phase from `cwf-state.yaml` `live.phase`
   - When phase = `impl`: inject plan.md content (from `live.key_files`) into recovery context
   - When phase = `clarify`/`plan`: current 5-decision recovery is sufficient
   - Consider: decision journal mechanism for impl-phase granular decisions

4. **CDM 4 — Review fail-fast for CAPACITY errors** (`plugins/cwf/skills/review/SKILL.md`)
   - Phase 3.2: parse stderr for error type keywords before exit code classification
   - `MODEL_CAPACITY_EXHAUSTED` / 429 → fail-fast (no retry, immediate fallback)
   - `INTERNAL_ERROR` / 500 → 1 retry then fallback
   - `AUTHENTICATION` / 401 → abort immediately with setup hint
   - Add `--timeout 30s` or `--max-retries 0` to Gemini CLI invocation if supported

### Part B: S13.6 Auto-Chaining Protocol Design

5. **Auto-chaining protocol** — Design how `cwf` invocation chains the full cycle:
   - `cwf:gather` → `cwf:clarify` → `cwf:plan` → `cwf:review --mode plan` → `cwf:impl` → `cwf:review --mode code` → `cwf:retro` → `cwf:ship`
   - Leverage `cwf-state.yaml` `workflow.stages` with `auto: true/false` (Decision #19)
   - Define: transition conditions between stages, user approval gates, rollback on review failure
   - Consider: single entry point (`cwf:run`?) vs enhancing existing skills with `--chain` flag

### Part C: Expert Recommendations (from retro)

6. **Ousterhout — Gate extraction** (`plugins/cwf/skills/impl/SKILL.md`)
   - Extract Branch Gate, Clarify Gate, Commit Gate to `references/impl-gates.md`
   - impl/SKILL.md references gates as 1-2 line pointers
   - Narrows interface, improves compaction resistance

## Don't Touch

- `plugins/cwf/references/context-recovery-protocol.md` — stable, just created in S32-impl
- `plugins/cwf/skills/gather/` — no CDM findings affect gather
- `README.md` / `README.ko.md` — update only if new user-facing features are added

## Success Criteria — Behavioral (BDD)

- Given a plan with identical logic for 4+ targets, When cwf:plan drafts, Then a shared reference file is specified as Step 0
- Given cross-cutting changes across 5 files, When impl determines commit strategy, Then commits are organized by change pattern (not work item)
- Given phase=impl and auto-compaction occurs, When compact recovery fires, Then plan.md content is included in recovery context
- Given Gemini CLI returns MODEL_CAPACITY_EXHAUSTED, When review Phase 3.2 processes the error, Then fallback is triggered within 15 seconds (not 104s)
- Given a full task from scratch, When cwf auto-chain is invoked, Then stages execute in order with user gates at clarify→plan and plan→impl transitions

## Success Criteria — Qualitative

- CDM improvements are minimal, surgical changes — not over-engineered
- Auto-chaining design respects Decision #19 (autonomous post-impl, human-gated pre-impl)
- Gate extraction reduces impl/SKILL.md line count while preserving all functionality

## Dependencies

- Requires: S32-impl completed (L1-L3+L9 implementation)
- Blocks: S14 (integration test + main merge)

## After Completion

1. Write plan.md, lessons.md, retro.md in session dir
2. Write next-session.md for S14
3. Update `cwf-state.yaml`: add S33 session entry
4. Update master-plan.md S33 row to "(done)"

## Start Command

```text
@prompt-logs/260210-03-docs-overhaul-impl/next-session.md 시작합니다
```
