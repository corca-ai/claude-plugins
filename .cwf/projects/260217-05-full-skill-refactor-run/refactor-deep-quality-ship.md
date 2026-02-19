# Quality + Concept Review: ship

## Criterion 5: Writing Style
- Instructions favor imperative phrasing (e.g., “Create issue,” “Compose issue body,” “Stop immediately”). Supporting guidance stays close to actionable commands and avoids verbose exposition.
- Language alternates between Korean (for templates) and English (for commands), matching the skill’s requirement to write issue/PR bodies in the user’s language while keeping CLI output literal.

## Criterion 6: Degrees of Freedom
- Workflows are mostly low/medium freedom: each subcommand enumerates a deterministic checklist (`gh issue create`, `git checkout`, `gh pr create`) and only allows branching via clearly stated flags (`--draft`, `--issue`). This matches the fragile nature of repository shipping operations.
- The only higher-freedom guidance (“summarize the plan if `plan.md` exists”) is guarded with prompts to ask the user when artifacts are missing, providing an acceptable fallback.

## Criterion 7: Anthropic Compliance
- Folder/skill naming uses kebab-case (`ship`), frontmatter contains only `name`/`description`, and the description mentions what the skill does plus its trigger phrase.
- No hard-coded dependencies on other plugins beyond suggested gating (`cwf:run` stage gate). Output persistence and gate scripts are clearly documented, which helps composability and downstream automation.

## Criterion 8: Concept Integrity
- The concept map labels `ship` as a “sparse row” (infrastructure/operational skill) with no generic-concept obligations. The SKILL.md behavior matches that characterization: it orchestrates the GitHub lifecycle but does not claim Expert Advisor, Agent Orchestration, or Decision Point roles, so there are no missing or contradictory concept claims.

<!-- AGENT_COMPLETE -->
