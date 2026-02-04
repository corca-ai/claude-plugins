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

When entering plan mode, follow the [Plan & Lessons Protocol](plugins/plan-and-lessons/protocol.md).
This is separate from the system plan file — create `prompt-logs/` directory with plan.md and lessons.md regardless of where the system stores its plan.

For non-trivial implementation tasks (new plugins, multi-file changes, architectural decisions), proactively use `EnterPlanMode` even when the user does not explicitly request it.

After implementing a plan, complete the full workflow without waiting for explicit reminders:
1. Mark plan.md as done (✅ on completed items)
2. Update lessons.md with implementation learnings
3. Run `/retro`
4. For plugin changes: test locally with `/plugin install <name>@corca-plugins` before committing
5. Commit and push
6. After committing plugin changes, run `bash scripts/update-all.sh` to update the marketplace and all installed plugins

## Collaboration Style

- The user communicates in Korean. Respond in Korean for conversation, English for code and docs (per Language rules below).
- The user expects protocols in CLAUDE.md to be followed without explicit reminders.
- Prefer short, precise feedback loops — ask for intent confirmation before large implementations.
- When researching Claude Code features (hooks, settings, plugins), always verify against the official docs (https://code.claude.com/docs/en/) via WebFetch. Do not rely solely on claude-code-guide agent responses.
- When testing hooks or infrastructure, verify incrementally — test one path first, then expand to others.
- When testing scripts, do not manually set up the environment (e.g., `source ~/.zshrc`) before running tests. Test in a clean environment to reproduce real-world conditions.
- When a custom skill overlaps with a built-in tool, prefer the custom skill. The web-search plugin enforces this automatically via PreToolUse hook (blocks WebSearch, redirects to `/web-search`). For other overlaps (e.g., `/gather-context` vs WebFetch), prefer the custom skill manually.
- When creating new skills or automation tools, first evaluate: marketplace plugin (`plugins/`, general-purpose, usable in any project) vs local skill (`.claude/skills/`, repo-specific). Prefer local skill unless the tool has clear cross-project utility.
- After large multi-file changes, consider running parallel sub-agent reviews before committing — give each agent a different review perspective (content integrity, missed opportunities, structural analysis) along with session lessons/retro as context.
- In design discussions, provide honest counterarguments and trade-off analysis. Do not just agree.

## Language

Write all documentation in English by default.
Korean versions live in:
- `README.ko.md`
- `AI_NATIVE_PRODUCT_TEAM.ko.md`
