# Plan: Plugin Lifecycle Automation Skill

## Background

After every plugin add/modify, there is a multi-step manual workflow that is easy to forget:

1. Update plugin.json version
2. Update marketplace.json
3. Update README.md + README.ko.md
4. Check AI_NATIVE_PRODUCT_TEAM.md links (new plugins)
5. Test locally (`--plugin-dir` or `/plugin install`)
6. Commit and push
7. Inform users to `/plugin marketplace update` + `/plugin install`

Currently documented in docs/modifying-plugin.md and docs/adding-plugin.md, but the agent often forgets steps (e.g., marketplace update, README sync, local testing). A skill that guides or automates this workflow would prevent these omissions.

## Goal

Create a `/plugin-deploy` skill (working name) that automates the post-modification plugin lifecycle. The skill ensures no step is skipped and reduces the cognitive load on both agent and user.

## Success Criteria

```gherkin
Given a modified plugin in plugins/<name>/
When `/plugin-deploy <name>` is invoked
Then the skill checks all required files are consistent:
  - plugin.json version is bumped
  - marketplace.json entry matches plugin.json
  - README.md and README.ko.md mention the plugin
And reports any gaps before proceeding

Given all checks pass
When the skill continues
Then it runs local tests (hook stdin piping or skill invocation)
And installs locally via `/plugin install <name>@corca-plugins`
And verifies the installed version matches

Given a new plugin (not in marketplace.json)
When `/plugin-deploy <name>` is invoked
Then the skill detects it's new and adds the marketplace.json entry
And checks AI_NATIVE_PRODUCT_TEAM.md for relevant links
And adds README entries

Given `--dry-run` flag
When the skill runs
Then it reports what would be done without making changes
```

## Design

### Skill Type

This is a **hybrid skill**: instruction-based workflow with some script-assisted validation. SKILL.md orchestrates the flow, scripts handle deterministic checks.

### Commands

```
/plugin-deploy <name>           Full lifecycle for a modified plugin
/plugin-deploy <name> --new     Full lifecycle for a new plugin (includes marketplace entry creation)
/plugin-deploy <name> --dry-run Check only, no modifications
/plugin-deploy <name> --skip-test  Skip local testing step
```

### Workflow Steps

```
1. Validate plugin exists: plugins/<name>/ directory check
2. Detect new vs modified:
   - If not in marketplace.json → new plugin flow
   - If in marketplace.json → modified plugin flow
3. Version check:
   - Read plugin.json version
   - Compare with marketplace.json version
   - If same → prompt for version bump (patch/minor/major)
4. Consistency checks:
   - marketplace.json entry has correct fields
   - README.md mentions the plugin (table + detail section)
   - README.ko.md mentions the plugin
   - AI_NATIVE_PRODUCT_TEAM.md links (new plugins only)
5. Report gaps → agent fixes them
6. Local test:
   - Hook plugins: run stdin piping tests
   - Skill plugins: verify SKILL.md loads correctly
7. Local install: `/plugin install <name>@corca-plugins`
8. Version verification: installed version matches plugin.json
9. Summary: list all changes made, ready for commit
```

### File Structure

```
plugins/plugin-deploy/
├── .claude-plugin/
│   └── plugin.json
└── skills/
    └── plugin-deploy/
        ├── SKILL.md                    # Workflow orchestration
        ├── scripts/
        │   └── check-consistency.sh    # Validates marketplace.json, READMEs, versions
        └── references/
            └── checklist.md            # Detailed checklist for edge cases
```

### Script: check-consistency.sh

```bash
check-consistency.sh <plugin-name> [--new]

# Outputs JSON:
{
  "plugin_json_version": "1.0.0",
  "marketplace_version": "1.0.0",  // null if new
  "version_match": true,
  "readme_mentioned": true,
  "readme_ko_mentioned": true,
  "ai_native_mentioned": false,     // only checked if --new
  "gaps": [
    "marketplace.json version (0.9.0) does not match plugin.json (1.0.0)",
    "README.ko.md does not mention smart-read"
  ]
}
```

This follows the script delegation pattern (see plan-web-search-refactor.md) — deterministic checks in a script, judgment calls in SKILL.md.

### Relationship to skill-creator

skill-creator handles creating new skills from scratch. plugin-deploy handles the lifecycle after creation/modification. They are complementary:

- `skill-creator` → "I want to create a new skill"
- `/plugin-deploy` → "I've made changes, deploy them properly"

Could reference skill-creator's compression/optimization techniques for reviewing SKILL.md size during deployment.

## Open Questions (for implementation session)

1. **Skill name**: `plugin-deploy` vs `plugin-lifecycle` vs `deploy`?
2. **Commit automation**: Should the skill also handle git commit + push, or just prepare everything and let the user/agent commit? (Leaning toward: prepare only, since commit message needs judgment)
3. **Version bump strategy**: Auto-detect (new files = minor, modified files = patch) or always ask?
4. **Scope**: Should this also handle plugin removal/deprecation?

## Deferred Actions

- [ ] Consider integration with a CI/CD pipeline for marketplace validation
- [ ] Consider a `/plugin-status` command that just runs checks without deploying
