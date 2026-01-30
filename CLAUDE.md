## Before You Start

**IMPORTANT**: Before modifying ANY code, you MUST:
1. Read `README.md` — check if your changes affect documented content
2. For plugin work, also read:
   - [Modifying/Testing/Deploying Plugins](docs/modifying-plugin.md)
   - [Adding New Plugins](docs/adding-plugin.md)
   - [Skills Guide](docs/skills-guide.md) — skill structure, env var conventions, design principles

Do NOT proceed with code changes until completing the above steps.

After modifying code, update any affected documentation.
Do NOT consider the task complete without updating related docs.

## Plan Mode

When entering plan mode, follow the [Plan & Lessons Protocol](docs/plan-and-lessons.md).
This is separate from the system plan file — create `prompt-logs/` directory with plan.md and lessons.md regardless of where the system stores its plan.

For non-trivial implementation tasks (new plugins, multi-file changes, architectural decisions), proactively use `EnterPlanMode` even when the user does not explicitly request it.

On entering plan mode, proactively read `.claude/settings.json` to check for registered hooks and follow their intent, regardless of whether the hook execution was observed.

## Collaboration Style

- The user communicates in Korean. Respond in Korean for conversation, English for code and docs (per Language rules below).
- The user expects protocols in CLAUDE.md to be followed without explicit reminders.
- Prefer short, precise feedback loops — ask for intent confirmation before large implementations.
- When researching Claude Code features (hooks, settings, plugins), always verify against the official docs (https://code.claude.com/docs/en/) via WebFetch. Do not rely solely on claude-code-guide agent responses.
- When testing hooks or infrastructure, verify incrementally — test one path first, then expand to others.
- When a custom skill (e.g., `/web-search`, `/gather-context`) overlaps with a built-in tool (e.g., WebSearch, WebFetch), prefer the custom skill. This supports dogfooding and ensures the skill is tested in real workflows.

## Language

Write all documentation in English, except for:
- `README.md`
- `AI_NATIVE_PRODUCT_TEAM.md`
