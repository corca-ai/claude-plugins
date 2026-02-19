# Structural Review: ship

## Criterion 1: SKILL.md Size
- Word count: 1,714 (well below the 3,000-word warning and 5,000-word error thresholds).
- Line count: 337 (< 500), so no size warning is needed.

## Criterion 2: Progressive Disclosure
- The frontmatter description covers what the skill does and when to trigger it. The body focuses on workflows and keeps ancillary resources in `references/`.
- No “When to use this skill” section or excessive API dumps appear inline, so progressive disclosure is respected.

## Criterion 3: Duplication Check
- The issue/pr template texts exist only in `references/` and are referenced by filename in the SKILL instructions (lines 1xx and 3xx). There is no verbatim duplication.

## Criterion 4: Resource Health
- Both references are under 100 lines and describe templates only, so no TOC is required. No nested reference dependencies exist.
- The files are referenced explicitly by the SKILL, meaning there are no unused resources.

<!-- AGENT_COMPLETE -->
