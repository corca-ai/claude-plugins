## Refactor Review: ship

### Summary
- Word count: 1,714 words; line count: 337 lines. Both metrics stay comfortably below the warning thresholds for size-based criteria.
- Resources: 2 templates (`issue-template.md`, `pr-template.md`) and both are actively referenced; no unused resources exist.
- Duplication: no templated content is duplicated inside the SKILL.md body (the templates are only named and consumed, not reproduced), and progressive disclosure rules are honored.

### Findings

#### [info] Structural and quality criteria already satisfied
**What**: The SKILL.md keeps the operational guidance focused on the decision workflows while relying on small reference templates, uses imperative language, describes its triggers, and integrates the `cwf:run` stage gate and `ship.md` persistence requirements.
**Where**: `plugins/cwf/skills/ship/SKILL.md`, `plugins/cwf/skills/ship/references/issue-template.md`, and `plugins/cwf/skills/ship/references/pr-template.md`.
**Suggestion**: Preserve the current structure and keep the templates in sync with GitHub expectations whenever the workflow changes.

### Suggested Actions
1. Continue documenting future shipping updates through the existing `SKILL.md` + `references/` split so the LU models draw from the concise workflow and the templates remain isolated (effort: small).

<!-- AGENT_COMPLETE -->
