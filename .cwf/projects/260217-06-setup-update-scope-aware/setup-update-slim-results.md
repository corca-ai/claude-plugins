# Setup/Update Slim Refactor Results

## Applied

- Created `plugins/cwf/skills/setup/references/codex-scope-integration.md`.
- Created `plugins/cwf/skills/update/references/scope-reconcile.md`.
- Slimmed `plugins/cwf/skills/setup/SKILL.md` by moving detailed Phase `2.4/2.5/2.6` prompts/commands/reporting into setup reference.
- Slimmed `plugins/cwf/skills/update/SKILL.md` by moving detailed Phase `0/3` scope-resolution/reconcile commands into update reference.
- Updated `plugins/cwf/skills/setup/README.md` and `plugins/cwf/skills/update/README.md` file maps for new references.

## Refactor Finding Mapping

1. `setup` oversized SKILL: reduced by extraction to references (still warning-level, but materially lower).
2. `eval` scope parsing: removed from setup/update SKILL guidance; replaced with explicit safe parser references.
3. fail-open scope fallback: setup/update now require explicit scope selection when detection fails/returns none.
4. update wrapper stale-link gap: reconcile rule now runs on `wrapper_link_present=true` or `wrapper_active=true`.
5. update user-global mutation asymmetry: added non-user -> user second-confirmation guard in Phase 0 safety contract.
6. alias boundary ambiguity: setup/update now document absolute-path alias/function bypass cases.

## Verification

- Markdown lint:
  - `npx --yes markdownlint-cli2 ...` -> pass (0 errors)
- Link check:
  - `bash plugins/cwf/skills/refactor/scripts/check-links.sh --local --json` -> pass (`errors: 0`)
- Provenance:
  - `bash plugins/cwf/scripts/provenance-check.sh --level inform --json` -> fresh `7/7`
- Quick scan (target skills):
  - setup -> `3874w / 887L` (previous rerun baseline: `4475w / 1078L`)
  - update -> `1148w / 276L` (warning cleared)
- Refactor stage gate:
  - strict check pass with known coverage warning (session intentionally reran subset skills)
