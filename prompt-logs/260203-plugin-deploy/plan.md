# Plan: Implement plugin-deploy Skill

## Background

Implementing the plugin-deploy skill from the spec at `prompt-logs/260203-smart-read-hook/plan-plugin-automation-skill.md`.

## Resolved Open Questions

1. **Skill name**: `plugin-deploy` — clear, action-oriented
2. **Commit automation**: Prepare only — skill prepares everything, agent/user commits with judgment
3. **Version bump strategy**: Always ask — prompt for patch/minor/major
4. **Scope**: No removal/deprecation — add/modify only
5. **Location**: Local skill (`.claude/skills/`) not marketplace plugin — too repo-specific

## Implementation Steps

- [x] Create plugin dev cheat sheet (`docs/plugin-dev-cheatsheet.md`)
- [x] Update CLAUDE.md to reference cheat sheet (token efficiency)
- [x] Create skill directory structure (`.claude/skills/plugin-deploy/`)
- [x] Write `check-consistency.sh` — deterministic validation script
- [x] Write `SKILL.md` — workflow orchestration
- [x] Write `references/checklist.md` — edge case reference
- [x] Test locally (all plugin types + error cases pass)
- [ ] Run `/retro`
- [ ] Commit and push

~~Removed steps (not needed for local skill):~~
- ~~Write `plugin.json`~~
- ~~Add to `marketplace.json`~~
- ~~Update `README.md` and `README.ko.md`~~
- ~~Check `AI_NATIVE_PRODUCT_TEAM.md`~~

## Success Criteria

```gherkin
Given a modified plugin in plugins/<name>/
When `/plugin-deploy <name>` is invoked
Then the skill runs check-consistency.sh and reports gaps
And guides the agent to fix any issues
And prepares everything for commit

Given a new plugin (not in marketplace.json)
When `/plugin-deploy <name>` is invoked
Then it detects the new plugin and includes marketplace entry creation
And checks AI_NATIVE_PRODUCT_TEAM.md and READMEs

Given `--dry-run` flag
When the skill runs
Then it reports what would be done without making changes
```

## Deferred Actions

- [ ] Consider integration with CI/CD pipeline for marketplace validation
- [ ] Consider a `/plugin-status` command that just runs checks without deploying
