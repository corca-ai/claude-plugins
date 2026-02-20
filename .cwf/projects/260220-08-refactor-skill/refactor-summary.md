## Refactor Summary

- Mode: `cwf:refactor --skill retro` (deep)
- Target: `plugins/cwf/skills/retro/SKILL.md`
- Provenance check: `review-criteria.provenance.yaml` is fresh (`skills=13`, `hooks=19`, delta `0/0`)

### Key Findings (Deep Review)

1. `SKILL.md` size warning (`>3000 words`, `>500 lines`) and progressive-disclosure overload.
2. Duplicate guidance between `SKILL.md` and:
   - `plugins/cwf/skills/retro/references/cdm-guide.md`
   - `plugins/cwf/skills/retro/references/expert-lens-guide.md`
3. Portability risk: artifact intake wording implied unconditional `AGENTS.md` / `CLAUDE.md` existence.

### Applied Refactor

1. Compressed non-interactive fallback and light fast-path narrative; removed repeated command blocks.
2. Shortened deep-mode agent instructions (A/B/C/D) while preserving output contracts and gate semantics.
3. Replaced duplicated CDM/Expert/Learning prose with reference-driven pointers.
4. Hardened artifact intake wording to require existence checks for AGENTS/adapter docs.

### Size Delta

- Before: `3409 words`, `501 lines`
- After: `2893 words`, `475 lines`

### Deep Artifacts

- `refactor-deep-structural-retro.md`
- `refactor-deep-quality-retro.md`

### Validation

- `npx --yes markdownlint-cli2 plugins/cwf/skills/retro/SKILL.md plugins/cwf/skills/retro/references/retro-gates-checklist.md`
- `bash plugins/cwf/scripts/check-shared-reference-conformance.sh`
- `bash .claude/skills/plugin-deploy/scripts/check-consistency.sh cwf`
