## Before You Start

**IMPORTANT**: Before modifying ANY code, you MUST:
1. Read the [Plugin Dev Cheat Sheet](docs/plugin-dev-cheatsheet.md) — directory patterns, schemas, deploy workflow, script guidelines
2. Check if your changes affect `README.md` or `README.ko.md`

Read what's relevant to your current task:
- [Architecture Patterns](docs/architecture-patterns.md) — code patterns, hook configuration, plugin integration
- [Project Context](docs/project-context.md) — project/org facts, design principles, process conventions
- [Documentation Guide](docs/documentation-guide.md) — documentation principles for AI-era projects
- [Modifying/Testing/Deploying Plugins](docs/modifying-plugin.md)
- [Adding New Plugins](docs/adding-plugin.md)
- [Skills Guide](docs/skills-guide.md)
- [Marketplace Reference](docs/claude-marketplace.md)

Do NOT proceed with code changes until completing the above steps.
After modifying code, update any affected documentation.

## Session State

When starting a new task or switching context, update the `live` section
in `cwf-state.yaml` (session_id, dir, branch, phase, task, key_files).
CWF skills update this automatically at phase transitions.

After implementation, write `next-session.md`, register the session in
`cwf-state.yaml`, and run `scripts/check-session.sh --impl`. Fix all FAIL
items before finishing.

## Collaboration Style

- The user communicates in Korean. Respond in Korean for conversation, English for code and docs (per Language rules below).
- Prefer short, precise feedback loops — ask for intent confirmation before large implementations.
- When executing a pre-designed plan: if a discrepancy between the plan and actual code is discovered during implementation, record it in lessons.md, report immediately, and ask the user for a decision before proceeding.
- When researching Claude Code features (hooks, settings, plugins), always verify against the official docs (https://code.claude.com/docs/en/) via WebFetch. Do not rely solely on claude-code-guide agent responses.
- When testing scripts, do not manually set up the environment (e.g., `source ~/.zshrc`) before running tests. Test in a clean environment to reproduce real-world conditions.
- Never delete user-created files without explicit confirmation. Prefer `mv` over `rm`. Untracked files cannot be restored via git.
- When the user proposes a choice where other reasonable alternatives exist (file locations, naming, structure, interfaces), provide honest counterarguments and trade-off analysis. Before agreeing, present at least one alternative axis the user hasn't mentioned. Do not just agree.
- When the user provides external reference articles or research, read them before forming design opinions. Research → design, not design → research.

## Dogfooding

When a CWF skill exists for the task at hand, use it instead of doing it manually.
Discover available skills via the plugin's `skills/` directory or trigger list.

After completing each workflow stage, update lessons.md with learnings before
moving to the next stage.

## Persist Routing

When graduating findings from lessons/retro to permanent docs:

| Finding type | Target |
|---|---|
| Project/org fact, process convention | docs/project-context.md |
| Code pattern, hook/integration pattern | docs/architecture-patterns.md |
| Script gotcha, build/test tip | docs/plugin-dev-cheatsheet.md |
| Claude behavior rule | this file (CLAUDE.md) |
| Documentation principle | docs/documentation-guide.md |

## Language

Write all documentation in English by default.
Korean versions live in:
- `README.ko.md`
- `AI_NATIVE_PRODUCT_TEAM.ko.md`
