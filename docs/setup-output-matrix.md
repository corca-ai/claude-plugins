# Setup Output Matrix

User-facing document outputs produced by `cwf:setup` flags.

## Flag-to-Output Matrix

| Invocation | Generated/Updated docs | Notes |
|---|---|---|
| `cwf:setup` | Always: [cwf-index.md](../cwf-index.md) | Full setup always refreshes capability index. |
| `cwf:setup` | Optional (prompted): [repo-index.md](../repo-index.md) and/or managed block in [AGENTS.md](../AGENTS.md) | User is asked whether to generate repository index and where to write it (`file`, `agents`, `both`). |
| `cwf:setup --cap-index` | [cwf-index.md](../cwf-index.md) | Capability index only. |
| `cwf:setup --repo-index` | [repo-index.md](../repo-index.md) | Repository index only, default target is `file`. |
| `cwf:setup --repo-index --target file` | [repo-index.md](../repo-index.md) | File output only. |
| `cwf:setup --repo-index --target agents` | Managed block in [AGENTS.md](../AGENTS.md) | `CWF:INDEX:START/END` block only. |
| `cwf:setup --repo-index --target both` | [repo-index.md](../repo-index.md) and managed block in [AGENTS.md](../AGENTS.md) | File + AGENTS block output. |
| `cwf:setup --hooks` / `--tools` / `--codex` / `--codex-wrapper` | None | Operational setup modes; no index documents generated unless index flags are also used. |

## Scope Notes

- In this repository (where [plugins/cwf](../plugins/cwf) exists), [cwf-index.md](../cwf-index.md) includes CWF skill and reference coverage.
- In external repositories without [plugins/cwf](../plugins/cwf), capability output can be minimal while repository index remains useful.
- Repository index coverage honors root-level [.cwf-index-ignore](../.cwf-index-ignore).
- Capability index coverage honors root-level [.cwf-cap-index-ignore](../.cwf-cap-index-ignore).
