# Plan: `/retro` Skill

## Goal

Create a `/retro` skill that performs a comprehensive end-of-session retrospective, producing `retro.md` alongside `plan.md` and `lessons.md` in the session's `prompt-logs/` directory.

## Files to Create

1. `plugins/retro/.claude-plugin/plugin.json` — plugin manifest
2. `plugins/retro/skills/retro/SKILL.md` — core skill file (~90 lines, instruction-only)

## Files to Modify

3. `.claude-plugin/marketplace.json` — add retro entry, bump version 1.4.0 → 1.5.0
4. `README.md` — add overview table entry + detailed section (Korean)
5. `AI_NATIVE_PRODUCT_TEAM.md` — add retro skill link in step 6 (회고)
6. `docs/plan-and-lessons.md` — add retro.md as companion artifact

## Success Criteria

```gherkin
Given a user at the end of a working session
When they invoke /retro
Then retro.md is created in the session's prompt-logs directory
And it contains 5 sections: context, collaboration, prompting, resources, skills
And it is written in the user's language

Given Section 2 contains CLAUDE.md update suggestions
When the retro is complete
Then the user is asked for approval before any CLAUDE.md changes are applied

Given a session that used the Plan & Lessons Protocol
When /retro runs
Then it reads existing plan.md and lessons.md to avoid duplication
And retro.md is saved in the same directory
```

## Deferred Actions

- [x] All items implemented in this session
