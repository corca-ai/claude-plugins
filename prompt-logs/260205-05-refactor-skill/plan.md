# Plan: refactor-skill (local skill)

## Goal

Create a local skill (`.claude/skills/refactor-skill/`) that reviews skills against skill-creator's Progressive Disclosure philosophy. Integrate with plugin-deploy for pre-deploy checks.

## Design

- `/refactor-skill <name>` — single skill deep review (read SKILL.md, compare against skill-creator principles, suggest refactorings)
- `/refactor-skill` (no args) — quick scan all plugins via bash script (word count, references ratio), report only flagged ones
- plugin-deploy integration — add word count threshold to check-consistency.sh, surface as a gap with suggestion to run `/refactor-skill`

## Steps

### 1. Create skill structure

```
.claude/skills/refactor-skill/
├── SKILL.md
├── scripts/
│   └── quick-scan.sh    # all-plugins structural scan
└── references/
    └── review-criteria.md  # skill-creator principles distilled into checklist
```

### 2. Write review-criteria.md

Distill skill-creator's philosophy into a concrete checklist:
- SKILL.md word count (<5k words body)
- Progressive Disclosure compliance (metadata → SKILL.md → references)
- Duplication check (same info in SKILL.md AND references?)
- Reference file sizes (>10k words → needs grep patterns in SKILL.md?)
- Unused resources (scripts/references/assets not referenced in SKILL.md)

Source: `~/.claude/plugins/marketplaces/` — Glob for `**/skill-creator**/SKILL.md`

### 3. Write quick-scan.sh

Script that scans all `plugins/*/skills/*/SKILL.md`:
- Word count per SKILL.md (flag if >3k words — warn, >5k — error)
- Count references/ files vs references in SKILL.md (flag unreferenced)
- Output JSON for machine consumption (consistent with check-consistency.sh pattern)

### 4. Write SKILL.md

- Single-target: read target SKILL.md + references/, apply review-criteria.md, produce actionable suggestions
- No-args: run quick-scan.sh, report flagged skills, suggest running single-target on each
- Imperative writing style per skill-creator convention

### 5. Integrate with plugin-deploy

Edit `.claude/skills/plugin-deploy/scripts/check-consistency.sh`:
- Add SKILL.md word count check for skill-type plugins
- New gap type: `skill_md_large` (>3k words → warning, >5k → error)
- Gap message suggests: "Consider running `/refactor-skill <name>`"

### 6. Test

- Run `/refactor-skill retro` — verify produces meaningful review
- Run `/refactor-skill` — verify quick-scan finds all plugins
- Run `/plugin-deploy retro --dry-run` — verify new gap type appears (or doesn't)

## Notes

- Local scope (`.claude/skills/`), not marketplace plugin — repo-specific
- skill-creator reference is read via Glob at `~/.claude/plugins/marketplaces/**/skill-creator**/SKILL.md`, not hardcoded path
- Quick-scan threshold (3k/5k) may need tuning after first real usage
