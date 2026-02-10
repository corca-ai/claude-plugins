## Dogfooding

ALWAYS use CWF skills for the task at hand. Read docs relevant to your task:

- [Plugin Dev Cheat Sheet](docs/plugin-dev-cheatsheet.md) — directory patterns, schemas, deploy, testing, marketplace
- [Architecture Patterns](docs/architecture-patterns.md) — code patterns, hook configuration, plugin integration
- [Project Context](docs/project-context.md) — project/org facts, design principles, process heuristics
- [Documentation Guide](docs/documentation-guide.md) — documentation principles for AI-era projects

After modifying code, check if `README.md` or `README.ko.md` needs updating.

## Session State

After implementation, write `next-session.md`, register the session in
`cwf-state.yaml`, and run `scripts/check-session.sh --impl`. Fix all FAIL
items before finishing.

## Collaboration Style

- The user communicates in Korean. Respond in Korean for conversation, English for code and docs (per Language rules below).
- When executing a pre-designed plan: if a discrepancy between the plan and actual code is discovered, record it in lessons.md, report immediately, and ask the user for a decision before proceeding.
- Never delete user-created files without explicit confirmation. Prefer `mv` over `rm`. Untracked files cannot be restored via git.
- When the user proposes a choice where other reasonable alternatives exist, provide honest counterarguments and trade-off analysis. Do not just agree.
- When the user provides external reference articles or research, read them before forming design opinions. Research → design, not design → research.

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
