# S25: Post-S24 Follow-up Tasks

## Context

S24 introduced 5 static analysis tools and 3 JSON schemas. The S24 retro identified structural fixes needed: hook integration, namespace separation, turn budget scaling, expert verified field, and script refactoring. This session executes those follow-up tasks and synchronizes documentation.

## Goal

Execute all S24 retro-driven structural fixes, update documentation to reflect S24+S25 changes, and create the next-session handoff.

## Steps

1. Add `check-links-local.sh` PostToolUse hook for async link checking on Write|Edit
2. Refactor `check-schemas.sh` from colon-delimited strings to positional args
3. Add mode-namespaced review output files (`review-{perspective}-{mode}.md`) to review SKILL.md
4. Add dynamic `max_turns` scaling to review and retro SKILL.md based on diff/document size
5. Add `verified: true` field to expert roster entries in cwf-state.yaml and expert-advisor-guide.md
6. Sync documentation: cwf-index.md, README.md, README.ko.md
7. Create session artifacts: lessons.md, next-session.md

## Success Criteria

### Behavioral (BDD)

```gherkin
Given a Write|Edit on a .md file outside prompt-logs/
When the check-links-local.sh hook fires
Then lychee runs on that single file and reports broken links async

Given check-schemas.sh with parallel array targets
When invoked with bash -n
Then syntax validation passes

Given a review invocation in a session that already ran review-plan
When review-code runs
Then output files use mode-suffixed names and don't collide

Given an expert with verified: true in cwf-state.yaml
When an expert sub-agent reads expert-advisor-guide.md
Then web identity verification is skipped and the source field is cited directly
```

### Qualitative

- Follow-up tasks address root causes identified in S24 retro (not symptoms)
- Documentation accurately reflects the current tool inventory

## Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `plugins/cwf/hooks/hooks.json` | Edit | Add check-links-local.sh hook entry |
| `plugins/cwf/hooks/scripts/check-links-local.sh` | Create | Async link checking hook |
| `scripts/check-links.sh` | Edit | Add --file flag for single-file mode |
| `scripts/check-schemas.sh` | Edit | Refactor to positional args |
| `plugins/cwf/skills/review/SKILL.md` | Edit | Mode namespace + max_turns scaling |
| `plugins/cwf/skills/retro/SKILL.md` | Edit | Increase max_turns for CDM/expert agents |
| `plugins/cwf/references/expert-advisor-guide.md` | Edit | Add verified field conditional |
| `cwf-state.yaml` | Edit | Add verified: true to all roster entries |
| `cwf-index.md` | Edit | Add S24 analysis scripts |
| `README.md` | Edit | Update lint_markdown hook description |
| `README.ko.md` | Edit | Update lint_markdown hook description |

## Don't Touch

- S24 analysis scripts (check-links.sh core logic, doc-graph.mjs, find-duplicates.py, doc-churn.sh)
- Existing hook scripts (check-markdown.sh, check-shell.sh)
