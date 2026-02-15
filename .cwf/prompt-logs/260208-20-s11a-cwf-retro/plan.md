# S11a Plan: Migrate retro → cwf:retro

## Context

Retro v2.0.2 is a standalone plugin at `~/.claude/plugins/cache/corca-plugins/retro/2.0.2/`. The CWF v3 consolidation (master-plan.md) requires migrating it into `plugins/cwf/skills/retro/` as `cwf:retro`. Beyond copy-and-adapt, two enhancements are required: (1) parallel sub-agent batching for deep mode analysis, and (2) persist step redesign from document-first to eval > state > doc hierarchy (S10 post-retro finding).

## Goal

Migrate retro v2.0.2 into CWF as `cwf:retro` with enhanced deep mode parallelism and persist step redesign.

## Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `plugins/cwf/skills/retro/SKILL.md` | Create (adapt from v2.0.2) | Main skill definition |
| `plugins/cwf/skills/retro/references/cdm-guide.md` | Create (copy verbatim) | CDM methodology |
| `plugins/cwf/skills/retro/references/expert-lens-guide.md` | Create (copy verbatim) | Expert Lens framework |

## Implementation Steps

1. Create directory structure (`plugins/cwf/skills/retro/` + `references/`)
2. Copy reference files verbatim from v2.0.2
3. Adapt SKILL.md with: updated frontmatter (add Grep, Triggers), cwf-state.yaml in Section 2, 2-batch parallel sub-agent design for deep mode, eval>state>doc persist hierarchy, agent-patterns.md reference, 3 new rules

## Success Criteria

- All 3 files exist with correct paths
- Frontmatter matches CWF convention (name, description with Triggers, allowed-tools)
- Reference files are verbatim copies (diff = identical)
- All 7 content sections present, output format unchanged
- Deep mode has 2-batch parallel sub-agent design
- Persist step has 3-tier hierarchy
- No bare code fences
