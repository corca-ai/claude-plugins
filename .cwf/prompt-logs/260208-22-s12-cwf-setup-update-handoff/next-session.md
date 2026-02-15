# S13 Handoff — Holistic Refactor on Entire CWF Plugin

## Context Files to Read

1. `CLAUDE.md` — project rules and protocols
2. `docs/plugin-dev-cheatsheet.md` — plugin development patterns
3. `cwf-state.yaml` — session history and project state
4. `prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md` — architecture decisions, session roadmap
5. `plugins/cwf/.claude-plugin/plugin.json` — current version (0.7.0)
6. `plugins/cwf/references/agent-patterns.md` — shared agent patterns
7. `plugins/cwf/references/plan-protocol.md` — plan and handoff format
8. All SKILL.md files in `plugins/cwf/skills/*/SKILL.md` — 9 skills to review
9. `plugins/cwf/hooks/hooks.json` + `plugins/cwf/hooks/scripts/` — all hook implementations
10. `prompt-logs/260208-22-s12-cwf-setup-update-handoff/lessons.md` — S12 learnings

## Task Scope

Run holistic refactor review on the entire CWF plugin. This is the quality gate before S14 integration testing and merge to main.

### What to Do

1. **Use `cwf:refactor --holistic`** on `plugins/cwf/` to identify cross-cutting issues across all 9 skills + hooks
2. **Cross-skill consistency**: Verify frontmatter format, allowed-tools alignment, Rules sections, reference links
3. **Hook-skill alignment**: Verify `cwf-hook-gate.sh` variables match `cwf:setup` output format
4. **Reference integrity**: Check all reference links in SKILL.md files resolve correctly
5. **Code fence specifiers**: All markdown files must have language specifiers on fences
6. **cwf-state.yaml schema**: Verify all skills that read/write cwf-state.yaml use compatible field names
7. **Agent pattern consistency**: Verify skills follow their declared pattern (Single/Adaptive/Team/Parallel)
8. **Script quality**: Review `scripts/install.sh`, `scripts/update-all.sh`, and all hook scripts for Bash 3.2 compatibility
9. **Linter strictness review**: Evaluate whether `lint_markdown` and `lint_shell` hook defaults are too aggressive for typical development workflows. Consider: (a) which markdownlint rules cause friction, (b) whether shellcheck runs on every Write/Edit are too noisy, (c) if default severity levels need adjustment. User expressed concern about unnecessary strictness.

### Key Design Points

- This is a review-and-fix session, not a feature session
- Fixes should be minimal and targeted — not redesigns
- The refactor skill itself should be used (dogfooding)
- Any issues found should be fixed in-session, not deferred
- Linter review should be data-driven: collect concrete examples of false positives or excessive warnings before adjusting rules

## Don't Touch

- `plugins/plan-and-lessons/` — keep intact until S14
- `prompt-logs/` — session history is read-only
- Architecture decisions in `master-plan.md` — not up for debate in S13

## Lessons from Prior Sessions

1. **Skill migration pattern** (S7-S11b): frontmatter with `Triggers:`, Rules section at bottom, reference link to `agent-patterns.md`
2. **cwf-state.yaml as SSOT** (S7-prep): all session history, hook config, tool availability tracked here
3. **Hook gate defaults** (S6a): hooks work without cwf:setup — config file is opt-out, not opt-in
4. **Dogfooding rule in CLAUDE.md** (S12): dynamic discovery via `skills/` directory, no hardcoded lists
5. **eval > state > doc persist hierarchy** (S11a): prefer automated checks over documentation rules
6. **impl → retro gap** (S12): check-session.sh --impl validates artifacts but doesn't prompt retro execution. "impl done" is not "session done" — retro is a separate stage
7. **Linter strictness concern** (S12): user raised concern about lint_markdown and lint_shell hooks being too aggressive. Need concrete data before adjusting
8. **Never Write over existing files** (S12): retro.md was destroyed by using Write instead of Edit. When appending to an existing file, always use Edit. Write replaces entire contents.

## Success Criteria

```gherkin
Given cwf:refactor --holistic is run on plugins/cwf/
When all 9 skills and hook scripts are analyzed
Then a review report is generated with specific file:line references

Given cross-skill inconsistencies are found
When fixes are applied
Then all SKILL.md frontmatter follows the same format
And allowed-tools lists match actual tool usage in each skill

Given cwf-hook-gate.sh expects HOOK_{GROUP}_ENABLED variables
When cwf:setup SKILL.md specifies the output format
Then variable names match exactly (case, underscore placement)

Given all markdown files in plugins/cwf/ are checked
When markdownlint is run
Then 0 errors are reported

Given all bash scripts are checked for Bash 3.2 compatibility
When no Bash 4+ features are used
Then scripts work on macOS default bash
```

## Dependencies

- Requires: S12 completed (all skills exist including setup/update/handoff)
- Blocks: S14 (integration test, merge to main)

## Dogfooding

Discover available CWF skills via the plugin's `skills/` directory or
the trigger list in skill descriptions. Use CWF skills for workflow stages
instead of manual execution.

## Start Command

```text
Read the context files listed above. Run cwf:refactor --holistic on plugins/cwf/
to identify cross-cutting issues. Fix all issues found. Run markdownlint on all
modified files. Verify with bash scripts/check-session.sh --impl.
```
