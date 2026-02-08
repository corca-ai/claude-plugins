# S11b Handoff — Migrate refactor → cwf:refactor

## Context Files to Read

1. `CLAUDE.md` — project rules and protocols
2. `docs/plugin-dev-cheatsheet.md` — plugin development patterns
3. `cwf-state.yaml` — session history and project state
4. `prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md` — overall architecture
5. `plugins/cwf/skills/impl/SKILL.md` — cwf:impl (pattern reference for agent orchestration)
6. `plugins/cwf/skills/retro/SKILL.md` — cwf:retro (just built in S11a, pattern reference for 2-batch sub-agents and persist hierarchy)
7. `plugins/cwf/references/agent-patterns.md` — shared agent patterns
8. Current refactor skill (latest cached version):
   - `~/.claude/plugins/cache/corca-plugins/refactor/1.1.2/skills/refactor/SKILL.md`
   - `~/.claude/plugins/cache/corca-plugins/refactor/1.1.2/skills/refactor/references/` (all reference files)

## Task Scope

Migrate refactor v1.1.2 into CWF as `cwf:refactor` with parallel sub-agent enhancement.

### What Changes

1. **Copy**: refactor SKILL.md + reference files into `plugins/cwf/skills/refactor/`
2. **Enhance**: Add parallel sub-agent execution for multi-mode review (per master-plan: "Parallel sub-agents per analysis section")
3. **Adapt**: Follow CWF skill conventions (frontmatter with Triggers, references path, rules)
4. **Persist hierarchy**: Apply eval > state > doc hierarchy in any persist/recommendation logic (S11a pattern)

### Key Design Points (from master-plan.md)

- refactor has 5 modes: quick scan, `--code`, `--skill`, `--skill --holistic`, `--docs`
- Several modes already use parallel sub-agents (e.g., `--code` with commit-based tidying)
- Review the current agent orchestration pattern and align with cwf:impl's agent patterns
- Maintain all 5 modes and backward compat

## Don't Touch

- `plugins/cwf/skills/plan/` — plan skill (S9)
- `plugins/cwf/skills/clarify/` — clarify skill (S8)
- `plugins/cwf/skills/gather/` — gather skill (S7)
- `plugins/cwf/skills/impl/` — impl skill (S10)
- `plugins/cwf/skills/retro/` — retro skill (S11a)
- `plugins/cwf/hooks/` — hook definitions
- `plugins/plan-and-lessons/` — keep intact until S14

## Lessons from S11a

- Skill migration pattern is now well-established (S7-S11a): frontmatter, directory structure, reference files
- 2-batch sub-agent design: batch dependencies emerge from reading reference file constraints carefully
- eval > state > doc persist hierarchy: ask "can a script catch this?" before suggesting doc rules
- For verbatim reference copies, `diff` verification confirms IDENTICAL
- When changes are distributed across entire file, Write + pattern-based verification (grep) is faster and safer than sequential Edit

## Success Criteria

```gherkin
Given cwf:refactor is invoked
When it runs in any of the 5 modes
Then the correct mode-specific workflow executes

Given cwf:refactor uses parallel sub-agents
When agents complete their analysis
Then results are integrated into the final output

Given refactor v1.1.2 behavior
When compared with cwf:refactor output
Then all existing functionality is preserved (no regression)
And all 5 modes are available
```

## Dependencies

- Requires: S10 completed (impl skill exists for pattern reference)
- Parallel with: S11a (retro migration — already completed)
- Blocks: S12 (setup/update/handoff need all skills)

## Start Command

```text
Read the context files listed above, then migrate refactor v1.1.2 into
plugins/cwf/skills/refactor/ with parallel sub-agent enhancement.
Copy and adapt — do not rewrite from scratch.
```
