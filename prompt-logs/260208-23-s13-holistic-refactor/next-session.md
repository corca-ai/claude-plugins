# S14 Handoff — Master Plan Review + Integration & Merge

## Context Files to Read

1. `CLAUDE.md` — project rules and protocols
2. `docs/plugin-dev-cheatsheet.md` — plugin development patterns
3. `cwf-state.yaml` — session history and project state
4. `prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md` — architecture decisions, target inventory, session roadmap
5. `plugins/cwf/.claude-plugin/plugin.json` — current version (0.7.0)
6. `plugins/cwf/hooks/hooks.json` — hook definitions
7. `plugins/cwf/references/skill-conventions.md` — shared skill structure conventions
8. `prompt-logs/260208-23-s13-holistic-refactor/plan.md` — S13 review results
9. All `prompt-logs/*/lessons.md` and `prompt-logs/*/retro.md` — accumulated learnings (S11a-S13 highest priority)

## Task Scope

Two-phase session: (A) comprehensive review against master plan, then (B) integration and merge.

### Phase A: Master Plan Review (`cwf:review`)

Use `cwf:review --mode code` (or appropriate mode) to evaluate the entire CWF plugin
and marketplace structure against the master plan.

#### A1. Inventory Gap Analysis

Compare master-plan target inventory against actual implementation:

- **10 target skills** (master-plan "Skill & Hook Inventory"): which are in `plugins/cwf/skills/`? which are missing?
  - Expected: setup, update, gather, clarify, plan, impl, review, retro, refactor, handoff
  - Known gap: `cwf:review` is still at `plugins/review/` (separate plugin), not in CWF
- **7 hook groups** (master-plan "Infrastructure"): all present in hooks.json?
- **Cross-cutting components**: cwf-state.yaml, cwf-hooks-enabled.sh, hooks.json, plugin.json, skill-conventions.md, agent-patterns.md, plan-protocol.md
- Flag anything **extra** that wasn't in the master plan (scope creep)

#### A2. Lessons & Retro Audit

Scan all `lessons.md` and `retro.md` from S0-S13. For each:

- **Deferred Actions** (`- [ ]` items): have they been resolved or are they still open?
- **Takeaway rules** (`When X → do Y`): are they reflected in CLAUDE.md, skill-conventions.md, or skill Rules sections?
- **Weight by recency**: S11a-S13 items are highest priority (most recent, most likely to be unresolved)

Produce a checklist:

```text
| Session | Item | Status | Where Reflected |
|---------|------|--------|-----------------|
| S12 | ExitPlanMode hook for lessons.md | Open | Not implemented |
| S12 | impl → retro auto-chaining | Open | Not implemented |
| S13 | 3+ pattern → extract to reference | Done | skill-conventions.md |
```

#### A3. Structural Consistency

- marketplace.json ↔ plugin.json descriptions
- README plugin tables ↔ actual plugins
- cwf-state.yaml session entries ↔ actual prompt-logs/ directories
- All reference links in all SKILL.md files resolve

### Phase B: Integration & Merge

After review findings are addressed:

1. **Migrate cwf:review**: Copy `plugins/review/` skill into `plugins/cwf/skills/review/`.
   Adapt to CWF conventions (see `skill-conventions.md`).

2. **Deprecate old plugins**: Mark pre-CWF plugins as deprecated in their plugin.json.

3. **Update marketplace.json**: Add `cwf` entry, mark deprecated plugins.

4. **Update README.md and README.ko.md**: New plugin table, install commands,
   migration guide from individual plugins to cwf.

5. **Version bump**: `plugin.json` to `1.0.0` (major: breaking change).

6. **Merge to main**: Create PR from `marketplace-v3` → `main`.

### Key Design Points

- **Review before merge**: Phase A findings may require fixes before Phase B proceeds
- Phase A uses cwf:review as a dogfooding exercise (the tool reviews itself)
- Old plugins are deprecated, not removed (users may need to uninstall)
- `scripts/install.sh` and `scripts/update-all.sh` already handle cwf-only workflow

## Don't Touch

- `prompt-logs/` — session history is read-only (read for audit, don't modify)
- Architecture decisions in `master-plan.md` — not up for debate
- Non-CWF plugins (e.g., `plugin-deploy`, `claude-dashboard`)

## Lessons from Prior Sessions

1. **Reference link depth** (S13): From `skills/{name}/SKILL.md`, shared references are at `../../references/`. Copy from setup or handoff as template.
2. **Skill conventions** (S13): All skills must follow `skill-conventions.md` — frontmatter, Language, Rules, References sections.
3. **Pattern extraction** (S13): 3+ skills repeating same pattern → extract to shared reference.
4. **Never Write over existing files** (S12): Use Edit for appending. Write replaces entire contents.
5. **impl → retro gap** (S12): check-session.sh --impl validates artifacts but doesn't prompt retro. Still open.
6. **ExitPlanMode lessons.md check** (S12): No hook validates lessons.md exists before plan approval. Still open.
7. **Linter config is reasonable** (S13): 48/55 markdownlint rules active. shellcheck at default severity. Toggle via cwf:setup.
8. **eval > state > doc hierarchy** (S11a): Prefer automated checks over doc rules.

## Success Criteria

```gherkin
Given master plan defines 10 skills and 7 hook groups
When inventory gap analysis is run
Then each item is accounted for (present, migrated, or explicitly deferred)

Given S0-S13 have lessons.md and retro.md files
When deferred actions are audited
Then each is marked resolved, open, or intentionally deferred with reason

Given cwf:review is migrated into plugins/cwf/skills/review/
When markdownlint is run on the new SKILL.md
Then 0 errors reported and reference links resolve correctly

Given marketplace-v3 is merged to main
When update-all.sh is run on main
Then cwf plugin installs successfully
```

## Dependencies

- Requires: S13 completed (holistic refactor, all cross-cutting issues resolved)
- Blocks: Nothing (S14 is the final session)

## Dogfooding

Discover available CWF skills via the plugin's `skills/` directory or
the trigger list in skill descriptions. Use CWF skills for workflow stages
instead of manual execution.

## Start Command

```text
Read the context files listed above, especially master-plan.md and all
lessons.md/retro.md files from S0-S13. Run cwf:review to audit the CWF
plugin against the master plan. Produce the gap analysis and lessons audit
checklist. Fix issues found. Then proceed to Phase B: migrate cwf:review,
deprecate old plugins, update docs, version bump 1.0.0, merge to main.
```
