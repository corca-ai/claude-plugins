# Agent Operating Guide

Compressed cross-runtime index for repository agents.

Keep stable invariants here; keep implementation detail in scoped docs.

## Operating Invariants

- Prioritize task-level goals over local optimizations. Choose execution details autonomously.
- Use CWF skills when the task matches triggers under [plugins/cwf/skills/](plugins/cwf/skills/) (or installed links under `~/.agents/skills/`).
- The user communicates in Korean. Respond in Korean for conversation and English for code/docs (unless explicitly requested otherwise).
- If implementation diverges from a pre-designed plan, record the discrepancy in session lessons, report it immediately, and ask for a user decision before proceeding.
- Never delete user-created files without explicit confirmation. Prefer `mv` over `rm`.
- When the user proposes one option and meaningful alternatives exist, provide counterarguments and trade-offs explicitly.
- When the user provides external references/research, read them before forming design opinions.
- After modifying code, check whether [README.md](README.md) or [README.ko.md](README.ko.md) must be updated.

## Routing Matrix

| Asset | Read when | Write when persisting findings |
|---|---|---|
| [docs/project-context.md](docs/project-context.md) | Baseline before implementation (project facts, long-lived heuristics) | Project/org fact, process convention |
| [docs/architecture-patterns.md](docs/architecture-patterns.md) | Baseline before implementation (implementation and integration patterns) | Code pattern, hook/integration pattern |
| [docs/plugin-dev-cheatsheet.md](docs/plugin-dev-cheatsheet.md) | Changing plugin, hook, script, test, or deploy workflows | Script gotcha, build/test tip |
| [docs/documentation-guide.md](docs/documentation-guide.md) | Writing/reviewing docs, [AGENTS.md](AGENTS.md), or runtime adapters | Documentation principle |
| [cwf-index.md](cwf-index.md) | You need a fast project map ("when to read what") | N/A |
| [CLAUDE.md](CLAUDE.md) | Runtime-specific behavior is relevant | Runtime-specific behavior rule |
| [README.md](README.md), [README.ko.md](README.ko.md), [AI_NATIVE_PRODUCT_TEAM.ko.md](AI_NATIVE_PRODUCT_TEAM.ko.md) | User-facing content and language sync is relevant | User-facing docs updates |

## Deterministic Gates

- Implementation completion gate: [scripts/check-session.sh](scripts/check-session.sh) `--impl`.
- Prefer deterministic checks over behavioral reminders: [plugins/cwf/hooks/hooks.json](plugins/cwf/hooks/hooks.json), [plugins/cwf/hooks/scripts/check-markdown.sh](plugins/cwf/hooks/scripts/check-markdown.sh), [plugins/cwf/hooks/scripts/check-links-local.sh](plugins/cwf/hooks/scripts/check-links-local.sh), [scripts/check-links.sh](scripts/check-links.sh).

## Managed CWF Index

Automation anchor for [cwf:setup](plugins/cwf/skills/setup/SKILL.md) index sync into [AGENTS.md](AGENTS.md).

<!-- CWF:INDEX:START -->
Run `cwf:setup --index --target agents` (or `--target both`) to refresh this block.
<!-- CWF:INDEX:END -->
