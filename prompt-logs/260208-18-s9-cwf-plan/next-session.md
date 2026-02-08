# S10 Handoff — Build cwf:impl

## Context Files to Read

1. `CLAUDE.md` — project rules and protocols
2. `docs/plugin-dev-cheatsheet.md` — plugin development patterns
3. `cwf-state.yaml` — session history and project state
4. `prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md` — overall architecture
5. `plugins/cwf/skills/plan/SKILL.md` — cwf:plan pattern (predecessor skill)
6. `plugins/cwf/skills/clarify/SKILL.md` — cwf:clarify pattern (agent team reference)
7. `prompt-logs/260208-18-s9-cwf-plan/lessons.md` — S9 lessons

## Task Scope

Build `cwf:impl` — an agent-assisted implementation skill that:

1. Takes a plan (from cwf:plan output) as input
2. Identifies domain experts needed for the task
3. Decomposes the plan into parallelizable work items
4. Spawns an agent team to implement
5. Integrates with `cwf:review --mode code` for verification

### Key Design Points (from master-plan.md)

- Domain expert identification: analyze the plan to determine what expertise is needed
- Plan decomposition: break steps into parallelizable and sequential work items
- Agent team implementation: spawn agents with appropriate types based on expertise
- Review integration: call `cwf:review --mode code` after implementation
- References behavioral criteria from cwf:plan (no access to holdout scenarios)

## Don't Touch

- `plugins/plan-and-lessons/` — keep intact until S14
- `plugins/cwf/hooks/` — hook definitions already correct
- `plugins/cwf/skills/clarify/` — clarify skill untouched
- `plugins/cwf/skills/plan/` — plan skill untouched (just created in S9)

## Lessons from Prior Sessions

- Skills should be tailored to their core purpose, not mechanically copied from other skills (S9)
- When referencing existing skills as patterns, adapt phase structure to match the skill's value proposition (S9)
- cwf:plan uses 2 sub-agents (research + codebase); cwf:impl will likely need more agents for parallel implementation

## Success Criteria

```gherkin
Given a plan.md exists from cwf:plan
When the user invokes cwf:impl
Then domain experts are identified from the plan content

Given cwf:impl has identified domain experts
When work items are decomposed
Then parallelizable items are identified and sequenced correctly

Given cwf:impl spawns an implementation team
When the team completes work
Then cwf:review --mode code is suggested for verification

Given cwf:impl references plan success criteria
When checking implementation completeness
Then behavioral (BDD) criteria from the plan are used as the contract
```

## Start Command

```text
Read the context files listed above, then implement cwf:impl following the
master-plan architecture. Use cwf:plan and cwf:clarify as structural references,
but design phases specific to implementation orchestration.
```
