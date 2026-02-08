# S9 Plan — Migrate plan-and-lessons → cwf:plan

## Context

Session S9 in the CWF v3 migration. The `plan-and-lessons` plugin's hook part
was already migrated to CWF in S6b (`enter-plan-mode.sh` + `plan-protocol.md`).
This session creates the **new** `cwf:plan` skill — an agent-assisted plan
drafting workflow with BDD success criteria and `cwf:review --mode plan`
integration.

## Scope

### 1. Create `plugins/cwf/skills/plan/SKILL.md`

New skill definition following the cwf:clarify pattern. Key design:

**Agent Team (2 parallel research agents + main synthesizer)**:

| Agent | Type | Purpose |
|-------|------|---------|
| Prior Art Researcher | general-purpose | Web search for frameworks, patterns, prior art |
| Codebase Analyst | Explore | Analyze existing code, patterns, dependencies, constraints |
| Main agent (synthesizer) | — | Synthesize research into structured plan |

**Phases**:

1. **Parse & Scope** — capture task description, identify what needs planning
2. **Parallel Research** — launch 2 sub-agents simultaneously
3. **Plan Drafting** — synthesize research into plan following plan-protocol.md
4. **Write Artifacts** — create plan.md + lessons.md in prompt-logs dir
5. **Review Offer** — suggest `cwf:review --mode plan`

### 2. Sync `plan-protocol.md` — add missing Handoff Document section

### 3. Version bump — `plugin.json` 0.4.0 → 0.5.0

### 4. Session artifacts

## Success Criteria

```gherkin
Given the CWF plugin is loaded
When the user invokes cwf:plan with a task description
Then an agent team (2 researchers + synthesizer) assists with plan drafting

Given cwf:plan drafts a plan
When the plan includes success criteria
Then criteria are in two-layer format (BDD behavioral + qualitative)

Given cwf:plan completes a plan
When the user wants review
Then the skill suggests cwf:review --mode plan

Given EnterPlanMode is triggered
When the plan-protocol hook fires
Then the Plan & Lessons Protocol is injected (existing S6b behavior preserved)

Given plan-protocol.md in CWF
When compared to the original protocol.md
Then the Handoff Document section is present
```

## Files to Create/Modify

| File | Action |
|------|--------|
| `plugins/cwf/skills/plan/SKILL.md` | ✅ Create |
| `plugins/cwf/references/plan-protocol.md` | ✅ Edit — add Handoff Document section |
| `plugins/cwf/.claude-plugin/plugin.json` | ✅ Edit — version 0.4.0 → 0.5.0 |
| `cwf-state.yaml` | ✅ Edit — add S9 session entry |
| `prompt-logs/260208-18-s9-cwf-plan/plan.md` | ✅ Create |
| `prompt-logs/260208-18-s9-cwf-plan/lessons.md` | ✅ Create |
| `prompt-logs/260208-18-s9-cwf-plan/next-session.md` | ✅ Create |

## Don't Touch

- `plugins/plan-and-lessons/` — keep intact until S14
- `plugins/cwf/hooks/scripts/enter-plan-mode.sh` — already correct from S6b
- `plugins/cwf/hooks/hooks.json` — hook definitions already correct
- `.claude/skills/review/SKILL.md` — review skill untouched

## Deferred Actions

- [ ] None identified
