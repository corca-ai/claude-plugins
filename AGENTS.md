# Agent Operating Guide

Compressed cross-runtime index for repository agents.

Keep stable invariants here; keep implementation detail in scoped docs.

## Read Routes

Minimum baseline before implementation work:

- [docs/project-context.md](docs/project-context.md) — project facts, long-lived heuristics, and process conventions
- [docs/architecture-patterns.md](docs/architecture-patterns.md) — implementation and integration patterns

Task-driven routes:

| File | Read when |
|---|---|
| [cwf-index.md](cwf-index.md) | You need a fast project map ("when to read what") |
| [docs/plugin-dev-cheatsheet.md](docs/plugin-dev-cheatsheet.md) | You are changing plugin, hook, script, test, or deploy workflows |
| [docs/documentation-guide.md](docs/documentation-guide.md) | You are writing/reviewing docs, [AGENTS.md](AGENTS.md), or runtime adapters |

## Operating Invariants

- Dogfooding: use CWF skills when the task matches triggers in skill definitions under [plugins/cwf/skills/](plugins/cwf/skills/) (or installed links under `~/.agents/skills/`).
- The user communicates in Korean. Respond in Korean for conversation and English for code/docs (unless explicitly requested otherwise).
- When executing a pre-designed plan, if implementation diverges, record the discrepancy in session lessons, report it immediately, and ask for a user decision before proceeding.
- Never delete user-created files without explicit confirmation. Prefer `mv` over `rm`.
- When the user proposes one option and meaningful alternatives exist, provide counterarguments and trade-offs explicitly.
- When the user provides external references/research, read them before forming design opinions.
- After modifying code, check whether [README.md](README.md) or [README.ko.md](README.ko.md) must be updated.
- Implementation completion is defined by passing [scripts/check-session.sh](scripts/check-session.sh) `--impl`.
- Prefer deterministic checks over behavioral reminders. Primary enforcement points: [plugins/cwf/hooks/hooks.json](plugins/cwf/hooks/hooks.json), [scripts/check-session.sh](scripts/check-session.sh), [plugins/cwf/hooks/scripts/check-markdown.sh](plugins/cwf/hooks/scripts/check-markdown.sh), [plugins/cwf/hooks/scripts/check-links-local.sh](plugins/cwf/hooks/scripts/check-links-local.sh), [scripts/check-links.sh](scripts/check-links.sh).

## Write Routes (Persist)

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

Korean docs live in [README.ko.md](README.ko.md) and [AI_NATIVE_PRODUCT_TEAM.ko.md](AI_NATIVE_PRODUCT_TEAM.ko.md).

## Managed CWF Index

<!-- CWF:INDEX:START -->
Run `cwf:setup --index --target agents` (or `--target both`) to refresh this block.
<!-- CWF:INDEX:END -->
