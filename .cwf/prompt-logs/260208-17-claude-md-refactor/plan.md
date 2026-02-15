# CLAUDE.md Refactoring + Automated Session Eval

## Context

CLAUDE.md has accumulated CWF migration-specific rules that over-fit to the current project phase (S0-S14). This causes two problems: (1) rules that should be temporary are treated as permanent, making CLAUDE.md noisy; (2) critical workflow steps like handoff creation live in scattered locations, causing repeated omissions. The "structural fix over instruction fix" principle from project-context.md applies here — rather than adding more rules to CLAUDE.md, we restructure where information lives and add automated checks.

Three workstreams:
1. **Slim CLAUDE.md** — move CWF-specific and duplicated content out
2. **Automated session completion check** — cwf-state.yaml artifacts + check script
3. **Plan-and-lessons protocol update** — add handoff document section

## Steps

- [x] ✅ Refactor CLAUDE.md (remove CWF-specific lines, simplify workflow, remove duplicates)
- [x] ✅ Update project-context.md (add "Current Project Phase" section)
- [x] ✅ Extend cwf-state.yaml (add session_defaults, backfill artifacts per session)
- [x] ✅ Create scripts/check-session.sh (session completion validator)
- [x] ✅ Update plan-and-lessons protocol.md (add Handoff Document section)
- [x] ✅ Create session directory with plan.md and lessons.md

## Success Criteria

```gherkin
Given cwf-state.yaml has artifact definitions for session S8
When scripts/check-session.sh S8 is run
Then it reports pass for plan.md, lessons.md, retro.md, next-session.md

Given cwf-state.yaml has artifact definitions for a session missing retro.md
When scripts/check-session.sh is run for that session
Then it reports fail for retro.md with a clear error message

Given the refactored CLAUDE.md
When an agent reads it at session start
Then no CWF-migration-specific tool names or workflow details are present

Given the plan-and-lessons protocol
When an agent creates session artifacts for a milestone session
Then next-session.md is listed as an expected artifact
```

## Deferred Actions

- [ ] Future: parse BDD success criteria from plan.md for automated eval (beyond file-existence)
- [ ] Future: integrate check-session.sh into pre-commit hook or retro skill
