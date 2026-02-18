## Refactor Review: refactor

### Summary
- Word count: 2900 (ok)
- Line count: 616 (**warning**)
- Resources: 21 total (10 references, 11 scripts), unreferenced: 0
- Duplication: detected (repeated session bootstrap snippets)
- Portability risks: detected (quick-scan scope coupling)

### Findings

#### [warning] SKILL.md line-count overflow
**What**: SKILL.md exceeds the 500-line threshold.
**Where**: `plugins/cwf/skills/refactor/SKILL.md`
**Suggestion**: move repeated mode boilerplate to references and keep SKILL.md as routing + invariants.

#### [warning] Repeated bootstrap blocks across modes
**What**: The same live-session bootstrap snippet is repeated in many mode sections.
**Where**: `plugins/cwf/skills/refactor/SKILL.md:71`, `plugins/cwf/skills/refactor/SKILL.md:126`, `plugins/cwf/skills/refactor/SKILL.md:209`, `plugins/cwf/skills/refactor/SKILL.md:270`, `plugins/cwf/skills/refactor/SKILL.md:384`, `plugins/cwf/skills/refactor/SKILL.md:490`
**Suggestion**: extract one canonical snippet and reference it.

#### [warning] Long reference files lack top-level TOC blocks
**What**: Reference files over 100 lines do not expose quick anchor navigation near top.
**Where**: `plugins/cwf/skills/refactor/references/docs-criteria.md`, `plugins/cwf/skills/refactor/references/docs-review-flow.md`, `plugins/cwf/skills/refactor/references/holistic-criteria.md`, `plugins/cwf/skills/refactor/references/review-criteria.md`
**Suggestion**: add short "Contents" sections with anchor links.

#### [warning] Quick-scan mode portability coupling
**What**: Quick-scan script assumes marketplace layout and plugin metadata paths.
**Where**: `plugins/cwf/skills/refactor/scripts/quick-scan.sh:216`, `plugins/cwf/skills/refactor/scripts/quick-scan.sh:122`
**Suggestion**: use contract-driven scope globs or explicitly gate marketplace-only behavior.

### Suggested Actions
1. Split repetitive session bootstrap and gate snippets into a shared reference block (effort: medium)
2. Add compact TOCs to long reference files (effort: small)
3. Introduce optional local-skill scan globs in quick-scan contract/script (effort: medium)
