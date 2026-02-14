# Agent Operating Guide

Compressed cross-runtime index for repository agents. Keep stable invariants here; keep implementation detail in scoped docs.

## Operating Invariants

- Prioritize task-level goals over local optimizations. Choose execution details autonomously.
- Use CWF skills when the task matches triggers under [plugins/cwf/skills/](plugins/cwf/skills/) (or installed links under `~/.agents/skills/`).
- The user communicates in Korean. Respond in Korean for conversation and English for code/docs (unless explicitly requested otherwise).
- If implementation diverges from a pre-designed plan, record the discrepancy in session lessons, report it immediately, and ask for a user decision before proceeding.
- Never delete user-created files without explicit confirmation. Prefer `mv` over `rm`.
- When the user proposes one option and meaningful alternatives exist, provide counterarguments and trade-offs explicitly.
- When the user provides external references/research, read them before forming design opinions.

## Document Roles

- [docs/project-context.md](docs/project-context.md): Project facts, long-lived heuristics, and process conventions.
- [docs/architecture-patterns.md](docs/architecture-patterns.md): Implementation and integration patterns.
- [docs/plugin-dev-cheatsheet.md](docs/plugin-dev-cheatsheet.md): Operational reference for plugin/hook/script build-test-deploy workflows.
- [docs/documentation-guide.md](docs/documentation-guide.md): Documentation design principles and scope boundaries.
- [cwf-index.md](cwf-index.md): Project map of where information lives.
- [CLAUDE.md](CLAUDE.md): Claude runtime adapter only.
- [README.md](README.md), [README.ko.md](README.ko.md), [AI_NATIVE_PRODUCT_TEAM.md](AI_NATIVE_PRODUCT_TEAM.md), [AI_NATIVE_PRODUCT_TEAM.ko.md](AI_NATIVE_PRODUCT_TEAM.ko.md): User-facing product and usage documentation.

## Deterministic Gates

- Deterministic checks are authoritative; behavioral reminders are secondary. Operational details live in [plugins/cwf/hooks/hooks.json](plugins/cwf/hooks/hooks.json), [docs/plugin-dev-cheatsheet.md](docs/plugin-dev-cheatsheet.md), and [scripts/check-session.sh](scripts/check-session.sh).

## Managed CWF Index

Automation anchor for [cwf:setup](plugins/cwf/skills/setup/SKILL.md) index sync into [AGENTS.md](AGENTS.md).

<!-- CWF:INDEX:START -->
Run `cwf:setup --index --target agents` (or `--target both`) to refresh this block.
<!-- CWF:INDEX:END -->
