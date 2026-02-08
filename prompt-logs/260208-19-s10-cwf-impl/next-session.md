# S11a Handoff — Migrate retro → cwf:retro

## Context Files to Read

1. `CLAUDE.md` — project rules and protocols
2. `docs/plugin-dev-cheatsheet.md` — plugin development patterns
3. `cwf-state.yaml` — session history and project state
4. `prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md` — overall architecture
5. `plugins/cwf/skills/impl/SKILL.md` — cwf:impl (just built in S10, pattern reference)
6. `plugins/cwf/references/agent-patterns.md` — shared agent patterns
7. Current retro skill (latest cached version):
   - `~/.claude/plugins/cache/corca-plugins/retro/2.0.2/skills/retro/SKILL.md`
   - `~/.claude/plugins/cache/corca-plugins/retro/2.0.2/skills/retro/references/cdm-guide.md`
   - `~/.claude/plugins/cache/corca-plugins/retro/2.0.2/skills/retro/references/expert-lens-guide.md`

## Task Scope

Migrate retro v2.0.2 into CWF as `cwf:retro` with parallel sub-agent enhancement.

### What Changes

1. **Copy**: retro SKILL.md + 2 reference files into `plugins/cwf/skills/retro/`
2. **Enhance**: Add parallel sub-agent execution for analysis sections (per master-plan: "Parallel sub-agents per analysis section")
3. **Integrate**: Ensure cwf:retro references `cwf-state.yaml` for session tracking
4. **Adapt**: Follow CWF skill conventions (frontmatter, references path, rules)

### Key Design Points (from master-plan.md)

- retro uses **parallel sub-agents** pattern (not adaptive, not 4-reviewer)
- Sections that can run in parallel: CDM analysis, Expert Lens, Learning Resources
- Deep mode already launches Expert α/β in parallel — extend pattern to other sections
- Maintain backward compat with light/deep mode selection

## Don't Touch

- `plugins/cwf/skills/plan/` — plan skill (S9)
- `plugins/cwf/skills/clarify/` — clarify skill (S8)
- `plugins/cwf/skills/gather/` — gather skill (S7)
- `plugins/cwf/skills/impl/` — impl skill (S10)
- `plugins/cwf/hooks/` — hook definitions
- `plugins/plan-and-lessons/` — keep intact until S14

## Lessons from Prior Sessions

- Skills should be tailored to their core purpose, not mechanically copied (S9)
- Phase 3a/3b split pattern: one skill, two execution paths based on complexity (S10)
- Orchestration skills that spawn file-writing agents need `mode: bypassPermissions` (S10)
- Nested code fences in templates need 4-backtick pattern (S10)
- One reference file is right when content is closely related (S10); retro already has 2 references which is appropriate
- **Deterministic validation > behavioral instruction**: prefer scripts/checks over adding rules to docs. check-session.sh + session_defaults catches missing artifacts; "remember to do X" doesn't. (S10)

## Success Criteria

```gherkin
Given cwf:retro is invoked
When it runs in light mode
Then sections 1-4 and 7 are produced without sub-agents for analysis

Given cwf:retro is invoked with --deep
When parallel sub-agents are available
Then CDM, Expert Lens, and Learning Resources run in parallel

Given cwf:retro completes
When persist findings step runs
Then cwf-state.yaml session history is consulted for context

Given retro v2.0.2 behavior
When compared with cwf:retro output
Then all existing functionality is preserved (no regression)
```

## Dependencies

- Requires: S10 completed (impl skill exists)
- Blocks: S12 (setup/update/handoff need all skills)
- Parallel with: S11b (refactor migration can run concurrently)

## Start Command

```text
Read the context files listed above, then migrate retro v2.0.2 into
plugins/cwf/skills/retro/ with parallel sub-agent enhancement.
Copy and adapt — do not rewrite from scratch.
```
