## Before You Start

**IMPORTANT**: Before modifying ANY code, you MUST:
1. Read the [Plugin Dev Cheat Sheet](docs/plugin-dev-cheatsheet.md) — covers directory patterns, schemas, testing, and deploy workflow
2. Check if your changes affect `README.md` or `README.ko.md`

For deeper reference (only when the cheat sheet isn't enough):
- [Modifying/Testing/Deploying Plugins](docs/modifying-plugin.md)
- [Adding New Plugins](docs/adding-plugin.md)
- [Skills Guide](docs/skills-guide.md)
- [Marketplace Reference](docs/claude-marketplace.md)
- [Project Context](docs/project-context.md) — accumulated architecture patterns and conventions

Do NOT proceed with code changes until completing the above steps.

After modifying code, update any affected documentation.
Do NOT consider the task complete without updating related docs.

## Plan Mode

For non-trivial implementation tasks, proactively use `EnterPlanMode`.

After implementation, write `next-session.md`, register the session in `cwf-state.yaml`, and run `scripts/check-session.sh --impl`. Fix all FAIL items before finishing.

## Collaboration Style

- The user communicates in Korean. Respond in Korean for conversation, English for code and docs (per Language rules below).
- The user expects protocols in CLAUDE.md to be followed without explicit reminders.
- Prefer short, precise feedback loops — ask for intent confirmation before large implementations.
- When executing a pre-designed plan: if a discrepancy between the plan and actual code is discovered during implementation, record it in lessons.md, report immediately, and ask the user for a decision before proceeding.
- When researching Claude Code features (hooks, settings, plugins), always verify against the official docs (https://code.claude.com/docs/en/) via WebFetch. Do not rely solely on claude-code-guide agent responses.
- When testing hooks or infrastructure, verify incrementally — test one path first, then expand to others.
- When testing scripts, do not manually set up the environment (e.g., `source ~/.zshrc`) before running tests. Test in a clean environment to reproduce real-world conditions.
- When requirements are ambiguous or large in scope, use the clarification skill before analysis or implementation. Do not manually ask clarification questions when a clarification skill is available.
- Never delete user-created files without explicit confirmation. Prefer `mv` over `rm`. Untracked files cannot be restored via git.
- In design discussions, provide honest counterarguments and trade-off analysis. Do not just agree.
- When writing markdown (SKILL.md, references, READMEs), always include a language specifier on code fences (` ```bash `, ` ```text `, ` ```yaml `, etc.). Never use bare ` ``` `. See `.markdownlint.json` for enforced rules.

## Dogfooding

When a CWF skill exists for the task at hand, use it instead of doing it manually.
Discover available skills via the plugin's `skills/` directory or trigger list.

After completing each workflow stage, update lessons.md with learnings before
moving to the next stage.

## Language

Write all documentation in English by default.
Korean versions live in:
- `README.ko.md`
- `AI_NATIVE_PRODUCT_TEAM.ko.md`
