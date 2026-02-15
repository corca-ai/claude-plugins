## Context Files to Read

1. [AGENTS.md](../../../AGENTS.md)
2. [README.md](../../../README.md)
3. [README.ko.md](../../../README.ko.md)
4. [plugins/cwf/skills/hitl/SKILL.md](../../../plugins/cwf/skills/hitl/SKILL.md)
5. [plugins/cwf/skills/setup/SKILL.md](../../../plugins/cwf/skills/setup/SKILL.md)
6. [docs/cwf-artifact-migration-plan.md](../../../docs/cwf-artifact-migration-plan.md)

## Task Scope

Continue README/README.ko review and finish remaining consistency and wording updates while preserving new path and setup policies.

### What to Build

- Complete the pending README review loop.
- Keep Korean wording natural and concise.
- Keep setup behavior discoverable from top-level docs.

### Key Design Points

- HITL state location is project-scoped.
- Legacy env names should not reappear in canonical docs.
- Archive prompt logs are historical, not active-quality-gate targets.

## Don't Touch

- Do not rewrite historical prompt-log archives except when explicitly requested.
- Do not revert unrelated staged or committed work.

## Success Criteria

```gherkin
Given README and README.ko pending review comments
When edits are applied and checks run
Then both files remain structurally aligned, readable, and policy-consistent.
```

## Execution Contract (Mention-Only Safe)

If the user provides only this file path, treat it as instruction to resume the README review task directly.

- Branch gate: avoid base branch direct implementation.
- Commit gate: commit by logical unit.
- Staging gate: include only intended files per commit.

## Start Command

```text
Resume README/README.ko review from this file and finish the remaining doc cleanup.
```
