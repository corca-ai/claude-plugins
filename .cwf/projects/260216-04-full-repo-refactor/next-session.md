# Next Session — Post Full-Repo Refactor

> Source: 260216-04 retro persist proposals #4, #5
> Branch: marketplace-v3

## Deferred Proposals

### 1. Extraction Priority Reranking (Retro Proposal #4)

**Finding**: Expert α (Fowler) identified that extraction candidates should be prioritized by "변경 빈도 × 인스턴스 수" instead of conceptual importance alone.

**Action**: Rerank the 7 extraction candidates from `refactor-holistic-convention.md` using this metric:

| Priority | Pattern | Instances | Rationale |
|----------|---------|-----------|-----------|
| 1 | Sub-Agent Output Persistence Block | 25+ across 5 skills | Highest instance count, copied on every new skill |
| 2 | Web Research Protocol prompt fragment | 8+ across 4 skills | Already referenced in agent-patterns.md but not extracted as reusable block |
| 3 | Session directory resolution boilerplate | 7 skills | Identical bash blocks |
| 4-7 | Remaining patterns | See holistic-convention.md | Lower instance counts |

**Deliverable**: Extract Pattern 1 and Pattern 2 to shared references. Update all composing skills to reference instead of inline.

### 2. README Structure Sync Validation Script (Retro Proposal #5)

**Finding**: README.ko.md (SSOT) and README.md had structural misalignment (Design Intent + What It Does subsections) across all 13 skills, accumulated over multiple sessions.

**Action**: Create `check-readme-structure.sh` that:
1. Extracts section heading hierarchy from README.ko.md and README.md
2. Compares at the heading level (ignoring content)
3. Reports structural drift (missing/extra sections, order differences)
4. Exits non-zero on mismatch for CI/hook integration

**Integration point**: `cwf:refactor --docs` deterministic tool pass, or pre-commit hook.

**Pilot scope**: Compare only `## ` and `### ` level headings within skill sections. Ignore content and minor formatting.

## Context Files

- Retro: `.cwf/projects/260216-04-full-repo-refactor/retro.md`
- Holistic convention analysis: `.cwf/projects/260216-04-full-repo-refactor/refactor-holistic-convention.md`
- Lessons: `.cwf/projects/260216-04-full-repo-refactor/lessons.md`
