# S12 Plan — cwf:setup + cwf:update + cwf:handoff

## Context

S12 builds the final infrastructure pieces (3 new skills + 2 script rewrites) before S13 holistic refactor. All workflow-stage skills (gather, clarify, plan, impl, retro, refactor) are complete. S12 adds the missing infra skills (setup, update, handoff) and simplifies the install/update scripts for single-plugin architecture.

## Goal

Create 3 new CWF skills (`cwf:setup`, `cwf:update`, `cwf:handoff`), rewrite 2 scripts (`install.sh`, `update-all.sh`) for single-plugin architecture, bump version to 0.7.0, and add lessons checkpoint rule.

## Scope

### Included

1. `scripts/install.sh` — single-plugin installer with deprecation warnings for old flags
2. `scripts/update-all.sh` — cwf-specific updater
3. `cwf:setup` SKILL.md — hook selection, tool detection, index.md generation
4. `cwf:update` SKILL.md — version check and update
5. `cwf:handoff` SKILL.md — auto-generate next-session.md from cwf-state.yaml
6. `plugin.json` version bump 0.6.0 → 0.7.0
7. CLAUDE.md lessons checkpoint rule
8. `cwf-state.yaml` schema: add `stage_checkpoints` field

### Excluded

- Existing workflow skills (gather, clarify, plan, impl, retro, refactor)
- Hook implementations
- cwf:retro dogfooding eval (deferred to S13)

## Steps

1. Rewrite `scripts/install.sh` (~60 lines)
2. Rewrite `scripts/update-all.sh` (~55 lines)
3. Create `plugins/cwf/skills/setup/SKILL.md` (~170 lines)
4. Create `plugins/cwf/skills/update/SKILL.md` (~100 lines)
5. Create `plugins/cwf/skills/handoff/SKILL.md` (~180 lines)
6. Bump `plugin.json` version to 0.7.0
7. Add lessons checkpoint rule to CLAUDE.md
8. Register S12 in cwf-state.yaml, write next-session.md

## Success Criteria

### Behavioral (BDD)

```gherkin
Given cwf:setup is invoked
When the user selects hook preferences
Then ~/.claude/cwf-hooks-enabled.sh is created with correct HOOK_*_ENABLED vars
And cwf-state.yaml hooks section mirrors the selections

Given cwf:update is invoked
When a newer CWF version exists
Then the plugin is updated and changelog is shown

Given cwf:handoff is invoked after a session
When cwf-state.yaml has session history
Then next-session.md is generated with all 8 sections

Given scripts/install.sh is run with old flags
Then a deprecation warning is shown and cwf plugin is installed

Given scripts/install.sh is run without flags
Then cwf plugin is installed from marketplace
```

### Qualitative

- SKILL.md files follow established CWF skill conventions (frontmatter, phases, rules, references)
- Scripts are Bash 3.2 compatible
- No modifications to Don't Touch files

## Don't Touch

- `plugins/cwf/skills/{gather,clarify,plan,impl,retro,refactor}/`
- `plugins/cwf/hooks/`
- `plugins/plan-and-lessons/`

## Deferred Actions

- [ ] cwf:retro dogfooding eval → S13
- [ ] ExitPlanMode PreToolUse hook: lessons.md existence validation
