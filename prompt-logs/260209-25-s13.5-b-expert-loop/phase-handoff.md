# Phase Handoff: S13.5-B → Implementation (Phase Handoff Skill)

> Source phase: clarify + design discussion
> Target phase: implementation (handoff SKILL.md --phase mode)
> Written: 2026-02-09

## Context Files to Read

1. `CLAUDE.md` — project-level behavioral rules
2. `cwf-state.yaml` — current project state, expert_roster
3. `plugins/cwf/skills/handoff/SKILL.md` — handoff skill to extend with --phase mode
4. `plugins/cwf/references/plan-protocol.md` — plan document structure (plan-protocol.md Handoff Document section)
5. `plugins/cwf/skills/impl/SKILL.md` — Phase 1 (how impl loads plan) — this is the consumer of phase handoff
6. `prompt-logs/260209-25-s13.5-b-expert-loop/lessons.md` — session lessons so far
7. `prompt-logs/260209-25-s13.5-b-expert-loop/retro.md` — session retro (experts: Klein RPD, Argyris double-loop)

## Design Decision Summary

**Problem**: After clarify+spec, clearing context loses HOW (protocols, rules, must-read references). plan.md carries WHAT but not HOW.

**Solution**: Add `--phase` mode to handoff skill. Phase handoff produces a lightweight document focused on implementation context (HOW), separate from plan.md (WHAT).

**Key design choices**:
- plan = WHAT, phase handoff = HOW — separation of concerns
- Phase handoff is written BEFORE plan mode entry (clarify/gather already has all HOW context)
- Phase handoff consumed by impl Phase 1 alongside plan.md
- Handoff skill already handles session→session context transfer; --phase extends it to phase→phase

## Protocols to Follow

1. **Record lessons incrementally** — don't wait until end. Previous session lesson: "lessons 기록의 deadlock" (plan mode can't write lessons.md)
2. **Ship 전 git status로 untracked 파일 확인** — previous session lesson
3. **Verify against previous session lessons** — read and follow relevant items from S13.5-A lessons.md
4. **Retro default is deep** — just changed in this session
5. **All code fences must have language specifier** in markdown files

## Do NOT

- Do NOT modify plan-protocol.md — phase handoff is additive, not a plan protocol change
- Do NOT modify expert-advisor-guide.md or expert-lens-guide.md — those are done in this session
- Do NOT change the handoff skill's existing session handoff behavior — `--phase` is a new mode, existing behavior is unchanged
- Do NOT add phase handoff output to plan.md — keep WHAT and HOW separate

## Implementation Hints

- Handoff SKILL.md Phase 3 has 8 required sections for session handoff. Phase handoff needs a lighter structure: Context Files, Design Decisions, Protocols, Do NOT, Implementation Hints
- Phase handoff output should go to session directory: `prompt-logs/{session}/phase-handoff.md`
- impl SKILL.md Phase 1 currently reads only plan.md. Add a step to detect and read `phase-handoff.md` in the same directory
- clarify SKILL.md Phase 5 (Output) should offer to generate phase handoff when CWF plugin is loaded

## Success Criteria

```gherkin
Given a session with clarify+spec completed
When the user runs cwf:handoff --phase
Then a phase-handoff.md is generated with HOW context (protocols, rules, must-reads, do-nots)

Given phase-handoff.md exists in the session directory
When cwf:impl starts and reads plan.md
Then impl also reads phase-handoff.md and follows the protocols therein

Given the user runs cwf:handoff without --phase
Then the existing session handoff behavior is unchanged (next-session.md)
```
