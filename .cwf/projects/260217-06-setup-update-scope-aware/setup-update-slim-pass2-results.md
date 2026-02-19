# Setup Slim Pass2 Results

## Applied

- Added `plugins/cwf/skills/setup/references/tool-detection-and-deps.md`.
- Added `plugins/cwf/skills/setup/references/runtime-and-index-phases.md`.
- Slimmed `plugins/cwf/skills/setup/SKILL.md`:
  - Phase 2 details extracted to `tool-detection-and-deps.md`.
  - Phase `2.7`~`2.10` and Phase `3`/`4`/`5` details extracted to `runtime-and-index-phases.md`.
  - Rules trimmed to invariant-focused statements (reduced procedural duplication).
- Updated `plugins/cwf/skills/setup/README.md` file map for new references.

## Metric Delta (quick-scan)

- setup before pass2: `2612 words / 543 lines` (line warning)
- setup after pass2: `2341 words / 462 lines` (no warnings)

## Validation

- `npx --yes markdownlint-cli2` on changed setup docs: pass (0 errors)
- `bash plugins/cwf/skills/refactor/scripts/check-links.sh --local --json`: pass (`errors: 0`)
- `bash plugins/cwf/skills/refactor/scripts/quick-scan.sh` setup slice: `flag_count: 0`
