# Setup Slim Pass2 Plan

## Goal

Remove remaining quick-scan line warning for `setup` by extracting additional procedural blocks while preserving skill-level routing and invariants.

## Scope

- `plugins/cwf/skills/setup/SKILL.md`
- `plugins/cwf/skills/setup/README.md`
- new setup references for extracted Phase 2 detail

## Planned Actions

1. Move Phase 2 (`2.1`~`2.3.3`) command-heavy tool detection/dependency handling details to `references/tool-detection-and-deps.md`.
2. Keep Phase 2 in `SKILL.md` as summary + mandatory behaviors + reference link.
3. Keep previously extracted `2.7`~`2.10`, `3`~`5` details in `references/runtime-and-index-phases.md` and tighten Rules to invariant-only statements.
4. Update setup README file map for new reference.
5. Validate markdown lint, local link check, and quick-scan setup metrics.
