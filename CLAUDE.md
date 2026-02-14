# Claude Runtime Adapter

Shared agent rules and workflow guidance live in [AGENTS.md](AGENTS.md).

Read first:

1. [AGENTS.md](AGENTS.md)
2. [cwf-index.md](cwf-index.md) (generated project map)

This file is intentionally Claude-specific:

- CWF hook runtime is Claude-native ([plugins/cwf/hooks/hooks.json](plugins/cwf/hooks/hooks.json), `${CLAUDE_PLUGIN_ROOT}`).
- Hook toggles are loaded from `~/.claude/cwf-hooks-enabled.sh`.
- Hook/integration env vars load from process env or shell profiles, with `~/.claude/.env` as legacy fallback.
