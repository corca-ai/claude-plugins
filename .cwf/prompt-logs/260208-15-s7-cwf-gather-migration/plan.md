# S7: Migrate gather-context → cwf:gather

## Steps

- [x] 1. Create CWF skill directory structure (`plugins/cwf/skills/gather/{scripts,references}`)
- [x] 2. Copy 8 scripts (verbatim, chmod +x)
- [x] 3. Copy 6 reference files (verbatim)
- [x] 4. Create adapted SKILL.md (`name: gather`, all `/gather-context` → `cwf:gather`)
- [x] 5. Activate WebSearch redirect hook (replace stub with deny JSON)
- [x] 6. Version bump `plugin.json` 0.2.0 → 0.3.0
- [x] 7. Documentation updates (CLAUDE.md, plan-protocol.md)
- [x] 8. Post-implementation (cwf-state.yaml, retro, commit, push, update-all)

## Success Criteria

```gherkin
Given the CWF plugin is loaded
When the agent attempts to use the built-in WebSearch tool
Then the hook denies it with a message directing to cwf:gather --search

Given the CWF plugin is loaded
When the user invokes cwf:gather --search "test query"
Then search.sh executes and returns formatted Tavily results

Given g-export.sh is in the new location
When it resolves SCRIPT_DIR via BASH_SOURCE
Then it correctly resolves to plugins/cwf/skills/gather/scripts/
```

## Test Results

1. ✅ Hook deny: outputs correct JSON with `permissionDecision: "deny"`
2. ✅ Gate disabled: `HOOK_WEBSEARCH_REDIRECT_ENABLED=false` → silent exit 0
3. ✅ All 8 scripts have executable permissions
4. ✅ g-export.sh SCRIPT_DIR resolves to `plugins/cwf/skills/gather/scripts`

## Deferred Actions

- [ ] None
