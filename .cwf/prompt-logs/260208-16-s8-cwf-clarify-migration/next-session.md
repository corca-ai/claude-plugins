# Handoff: Next Session (S9 — Migrate plan-and-lessons → cwf:plan)

## Context

- Read: `cwf-state.yaml` (project state SSOT — session history, current stage, tool/hook status)
- Read: `prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md` (architecture, agent team strategy)
- Read: `prompt-logs/260208-16-s8-cwf-clarify-migration/lessons.md` (S8 migration learnings)
- Read: `prompt-logs/260208-15-s7-cwf-gather-migration/lessons.md` (S7 migration learnings — more complex migration)
- Branch: `marketplace-v3`

## Task

Migrate `plan-and-lessons` plugin into CWF as `cwf:plan`. This is unique — the source is a **hook** (EnterPlanMode → protocol injection), and the target is a **Skill + Hook**.

### What exists today

- `plugins/plan-and-lessons/hooks/scripts/enter-plan-mode.sh` — PreToolUse hook for EnterPlanMode
- `plugins/plan-and-lessons/protocol.md` — Plan & Lessons Protocol document
- `plugins/cwf/hooks/scripts/enter-plan-mode.sh` — **Already migrated in S6b** (hook part is done)
- `plugins/cwf/references/plan-protocol.md` — **Already exists** (protocol reference for CWF)

### What's new in S9

Per master plan: `cwf:plan` is a **new skill** (not just a hook migration). It adds:
- Agent team for plan drafting
- BDD-style success criteria format (behavioral + qualitative)
- Integration with `cwf:review --mode plan`

## Scope

1. **Create `plugins/cwf/skills/plan/SKILL.md`** — new skill definition
   - Agent team pattern for plan drafting (per master plan's agent team strategy)
   - BDD success criteria format (per S4.6 SW Factory decisions)
   - Calls `cwf:review --mode plan` after drafting
   - References existing `plugins/cwf/references/plan-protocol.md`

2. **Verify hook is already migrated** — `enter-plan-mode.sh` was copied in S6b
   - Confirm it references `plan-protocol.md` correctly
   - No additional hook work should be needed

3. **Version bump** — `plugin.json` 0.4.0 → 0.5.0

4. **Documentation updates**
   - CLAUDE.md: check for plan-and-lessons references
   - cwf-state.yaml: add S9 entry

## Key Design Decisions to Make

- How complex should the agent team be for plan drafting? Master plan says "Agent team" but doesn't detail the pattern.
- Should the skill handle both plan creation (new) and plan protocol enforcement (existing hook)?
- How does `cwf:plan` interact with the existing `EnterPlanMode` hook flow?

## Don't Touch

- `plugins/plan-and-lessons/` — keep intact until S14 deprecation
- `plugins/cwf/hooks/scripts/enter-plan-mode.sh` — already migrated in S6b
- Agent team enhancements beyond initial plan drafting capability

## Lessons from S7/S8

- Reference files using `{SKILL_DIR}/references/` resolve correctly after copy — no path changes needed
- Path A/B pattern: check for both cwf and legacy skill availability for transitional compatibility
- Add cross-references between related cwf skills (e.g., cwf:clarify → cwf:review --mode clarify)
- Verbatim copy + diff verify pattern works well for reference files

## Success Criteria

```gherkin
Given the CWF plugin is loaded
When the user invokes cwf:plan
Then an agent team assists with plan drafting using BDD success criteria

Given cwf:plan produces a plan
When the user wants review
Then cwf:review --mode plan can process the output

Given EnterPlanMode is triggered
When the plan-protocol hook fires
Then the Plan & Lessons Protocol is injected (existing S6b behavior preserved)
```

## After Completion

1. Create session dir: `prompt-logs/{YYMMDD}-{NN}-s9-cwf-plan/`
2. Write plan.md, lessons.md, next-session.md (S10 handoff)
3. Run `/retro`
4. Update `cwf-state.yaml` with S9 entry
5. Commit and push

## Start Command

```text
@prompt-logs/260208-16-s8-cwf-clarify-migration/next-session.md 시작합니다
```
