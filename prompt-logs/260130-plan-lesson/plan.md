# Plan: Add Plan & Lessons Protocol

## Goal

Add a protocol to CLAUDE.md that ensures every plan-mode session produces persistent artifacts:
- `plan.md` with success criteria (BDD-style acceptance tests) and deferred actions
- `lessons.md` with learnings accumulated throughout the session

## Files to Create/Modify

1. **Create** `docs/plan-and-lessons.md` — detailed protocol
2. **Edit** `CLAUDE.md` — add link to the new doc
3. **Create** `prompt-logs/260130-plan-lesson/plan.md` — this file (dogfooding)
4. **Create** `prompt-logs/260130-plan-lesson/lessons.md` — session learnings

## Success Criteria

```gherkin
Given a session that enters plan mode
When Claude creates a plan
Then a plan.md file exists under prompt-logs/{YYMMDD}-{title}/
And it contains a "Success Criteria" section with BDD-style acceptance tests
And it contains a "Deferred Actions" section

Given a user request during plan mode that cannot be acted on immediately
When Claude records it
Then it appears as a checklist item in plan.md's Deferred Actions section

Given an ongoing session with user interaction
When Claude learns something from ping-pong or implementation
Then it is recorded in lessons.md in the same directory as plan.md
And each entry has at minimum: what was expected, what actually happened, takeaway
```

## Deferred Actions

- [x] `/retro` skill creation — deferred to a separate session
