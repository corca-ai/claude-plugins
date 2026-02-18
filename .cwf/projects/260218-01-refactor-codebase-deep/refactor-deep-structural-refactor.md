# Structural Review — refactor (Criteria 1-4)

## Scope
- Target skill: `plugins/cwf/skills/refactor/SKILL.md`
- Resource directories reviewed: `plugins/cwf/skills/refactor/references`, `plugins/cwf/skills/refactor/scripts`, `plugins/cwf/skills/refactor/assets`

## Criterion 1 — SKILL.md Size
Status: **Warning**

- Word count: 2900 (within threshold)
- Line count: 616 (**warning**, threshold > 500)

Evidence:
- `plugins/cwf/skills/refactor/SKILL.md`

Recommendation:
- Keep routing and invariants in `SKILL.md`; move repetitive mode procedures to references where possible.

## Criterion 2 — Progressive Disclosure
Status: **Pass**

- Frontmatter contains only `name` and `description`.
- Detailed procedures are mostly delegated to scripts and references.
- No oversized (>10k words) reference files detected.

Evidence:
- `plugins/cwf/skills/refactor/SKILL.md`
- `plugins/cwf/skills/refactor/references/review-criteria.md`
- `plugins/cwf/skills/refactor/references/holistic-criteria.md`
- `plugins/cwf/skills/refactor/references/docs-criteria.md`

## Criterion 3 — Duplication
Status: **Warning**

Finding: Repeated session bootstrap snippets appear across multiple mode sections.

Evidence examples:
- `plugins/cwf/skills/refactor/SKILL.md:71`
- `plugins/cwf/skills/refactor/SKILL.md:126`
- `plugins/cwf/skills/refactor/SKILL.md:209`
- `plugins/cwf/skills/refactor/SKILL.md:270`
- `plugins/cwf/skills/refactor/SKILL.md:384`
- `plugins/cwf/skills/refactor/SKILL.md:490`

Recommendation:
- Extract one canonical snippet to a referenced block (or helper reference file), then reuse by pointer.

## Criterion 4 — Resource Health
Status: **Warning**

- Unused resource files: none detected (`scripts/` and `references/` files are referenced from `SKILL.md`).
- Large reference files (>10k words): none.
- Reference files over 100 lines without a top-level TOC block detected:
  - `plugins/cwf/skills/refactor/references/docs-criteria.md`
  - `plugins/cwf/skills/refactor/references/docs-review-flow.md`
  - `plugins/cwf/skills/refactor/references/holistic-criteria.md`
  - `plugins/cwf/skills/refactor/references/review-criteria.md`

Recommendation:
- Add compact "Contents" anchors near the top of each long reference file.

<!-- AGENT_COMPLETE -->
