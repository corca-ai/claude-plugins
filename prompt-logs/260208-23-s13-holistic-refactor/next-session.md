# S14 Handoff — Integration Test & Merge to Main

## Context Files to Read

1. `CLAUDE.md` — project rules and protocols
2. `docs/plugin-dev-cheatsheet.md` — plugin development patterns
3. `cwf-state.yaml` — session history and project state
4. `prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md` — architecture decisions, session roadmap
5. `plugins/cwf/.claude-plugin/plugin.json` — current version (0.7.0)
6. `plugins/cwf/hooks/hooks.json` — hook definitions
7. `prompt-logs/260208-23-s13-holistic-refactor/plan.md` — S13 review results (all PASS)
8. `prompt-logs/260208-23-s13-holistic-refactor/lessons.md` — S13 learnings

## Task Scope

Final integration: migrate `cwf:review` into CWF plugin, deprecate old plugins,
run end-to-end workflow test, update all docs, and merge `marketplace-v3` to `main`.

### What to Do

1. **Migrate cwf:review**: Copy `plugins/review/` skill into `plugins/cwf/skills/review/`
   with SKILL.md, references, and scripts. Adapt to CWF patterns (Language declaration,
   Rules section, reference links using `../../references/`).

2. **End-to-end test**: Run the full CWF workflow in a test scenario:
   - `cwf:setup` → detect tools, generate hook config
   - `cwf:gather` → test URL and search modes
   - `cwf:clarify` → test with a sample requirement
   - `cwf:plan` → generate a plan
   - `cwf:review --mode plan` → review the plan
   - Verify all hooks fire correctly (lint, read guard, plan protocol)

3. **Deprecate old plugins**: Mark all pre-CWF plugins as deprecated:
   - `plugins/gather-context/`
   - `plugins/clarify/`
   - `plugins/plan-and-lessons/`
   - `plugins/retro/`
   - `plugins/refactor/`
   - `plugins/review/`
   - `plugins/attention-hook/`
   - `plugins/smart-read/`
   - `plugins/prompt-logger/`
   - `plugins/markdown-guard/`
   Update their `plugin.json` with deprecation notice.

4. **Update marketplace.json**: Add `cwf` entry, mark deprecated plugins.

5. **Update README.md and README.ko.md**: New plugin table, install commands,
   migration guide from individual plugins to cwf.

6. **Version bump**: Update `plugin.json` to `1.0.0` (major: breaking change
   from individual plugins to unified cwf).

7. **Convert `.claude/skills/`**: If any local dev skills exist, convert to
   plugin structure under `plugins/cwf/`.

8. **Merge to main**: Create PR from `marketplace-v3` → `main`.

### Key Design Points

- This is the breaking change described in master-plan Decision #2
- Old plugins are fully deprecated, not removed (users may need to uninstall)
- `scripts/install.sh` already handles legacy flags with deprecation warnings
- `scripts/update-all.sh` already handles the cwf-only workflow

## Don't Touch

- `prompt-logs/` — session history is read-only
- Architecture decisions in `master-plan.md` — not up for debate in S14
- Other non-CWF plugins (e.g., `plugin-deploy`, `claude-dashboard`)

## Lessons from Prior Sessions

1. **Reference link depth** (S13): From `skills/{name}/SKILL.md`, shared references are at `../../references/`. Copy from setup or handoff as template.
2. **Rules section required** (S13): Every skill must have `## Rules` before `## References`.
3. **Language declaration pattern** (S13): `**Language**: Write {artifact type} in English. Communicate with the user in their prompt language.`
4. **Never Write over existing files** (S12): Use Edit for appending to existing files.
5. **Dogfooding rule in CLAUDE.md** (S12): Dynamic discovery via `skills/` directory, no hardcoded lists.
6. **Linter config is reasonable** (S13): `.markdownlint.json` already disables friction rules. shellcheck runs at default severity. Toggle via cwf:setup.

## Success Criteria

```gherkin
Given cwf:review skill is migrated into plugins/cwf/skills/review/
When markdownlint is run on the new SKILL.md
Then 0 errors reported
And reference links resolve correctly

Given all old plugins are deprecated
When their plugin.json files are checked
Then each has a deprecation notice

Given marketplace.json is updated
When cwf entry is present
Then description, version, and keywords are correct
And deprecated plugins are marked

Given README.md is updated
When the plugin table is checked
Then cwf is listed as the primary plugin
And install commands reference cwf only

Given the full workflow is tested end-to-end
When cwf:setup, cwf:gather, cwf:clarify, cwf:plan, cwf:review are invoked
Then each produces expected output without errors

Given marketplace-v3 is merged to main
When update-all.sh is run on main
Then cwf plugin installs successfully
```

## Dependencies

- Requires: S13 completed (all cross-cutting issues resolved)
- Blocks: Nothing (S14 is the final session)

## Dogfooding

Discover available CWF skills via the plugin's `skills/` directory or
the trigger list in skill descriptions. Use CWF skills for workflow stages
instead of manual execution.

## Start Command

```text
Read the context files listed above. Migrate cwf:review into the CWF plugin.
Run end-to-end workflow test. Deprecate old plugins, update marketplace.json
and READMEs. Version bump to 1.0.0. Merge marketplace-v3 to main.
```
