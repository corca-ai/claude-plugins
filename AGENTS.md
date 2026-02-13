# Agent Operating Guide

Shared operating guide for all coding agents in this repository (Codex, Claude Code, and compatible runtimes).

## Progressive Disclosure

Start with:

- [cwf-index.md](cwf-index.md) — project map ("when to read what")
- [docs/project-context.md](docs/project-context.md) — project/org facts and long-lived heuristics
- [docs/architecture-patterns.md](docs/architecture-patterns.md) — implementation and integration patterns
- [docs/plugin-dev-cheatsheet.md](docs/plugin-dev-cheatsheet.md) — practical plugin development/testing/deploy workflows
- [docs/documentation-guide.md](docs/documentation-guide.md) — documentation quality and scope rules

Read only what is relevant to the current task.

## Dogfooding

ALWAYS use CWF skills for the task at hand.

Discover available CWF skills by reading `plugins/cwf/skills/*/SKILL.md`
(or installed links under `~/.agents/skills/*`) and checking each skill's
trigger section.

After modifying code, check whether [README.md](README.md) or [README.ko.md](README.ko.md) must be updated.

## Session State

After implementation:

1. Write `next-session.md`.
2. Register the session in `cwf-state.yaml`.
3. Run `scripts/check-session.sh --impl`.
4. Fix all FAIL items before finishing.

## Collaboration Style

- The user communicates in Korean. Respond in Korean for conversation and English for code/docs (unless explicitly requested otherwise).
- When executing a pre-designed plan, if actual code diverges from the plan, record the discrepancy in `lessons.md`, report it immediately, and ask for a user decision before proceeding.
- Never delete user-created files without explicit confirmation. Prefer `mv` over `rm`.
- When the user proposes one option and meaningful alternatives exist, provide counterarguments and trade-offs explicitly.
- When the user provides external references/research, read them before forming design opinions.

## Persist Routing

When graduating findings from lessons/retro into permanent docs:

| Finding type | Target |
|---|---|
| Project/org fact, process convention | [docs/project-context.md](docs/project-context.md) |
| Code pattern, hook/integration pattern | [docs/architecture-patterns.md](docs/architecture-patterns.md) |
| Script gotcha, build/test tip | [docs/plugin-dev-cheatsheet.md](docs/plugin-dev-cheatsheet.md) |
| Runtime-specific behavior rule | Runtime adapter file ([CLAUDE.md](CLAUDE.md), or future runtime adapters) |
| Documentation principle | [docs/documentation-guide.md](docs/documentation-guide.md) |

## Language

Write documentation in English by default.

Korean docs live in:

- [README.ko.md](README.ko.md)
- [AI_NATIVE_PRODUCT_TEAM.ko.md](AI_NATIVE_PRODUCT_TEAM.ko.md)

## Managed CWF Index

<!-- CWF:INDEX:START -->
Run `cwf:setup --index --target agents` (or `--target both`) to refresh this block.
<!-- CWF:INDEX:END -->
