# Analysis: Remove `{PLUGIN_ROOT}` Dependency from CWF Skills

## Problem

CWF skills reference shared files via `{PLUGIN_ROOT}/references/` or `../../references/`.
This prevents local-skill symlink development workflow because:

1. `{PLUGIN_ROOT}` is only defined for installed plugin skills, not local skills
2. `../../references/` resolves relative to the skill directory — breaks when skill is loaded from `.claude/skills/` via symlink (resolves to `.claude/references/` instead of `plugins/cwf/references/`)

Current workaround: manually copy source → installed cache. Not sustainable.

## Affected Skills (all CWF skills)

| Skill | Shared reference used | Path form |
|-------|----------------------|-----------|
| refactor | concept-map.md, skill-conventions.md | `{PLUGIN_ROOT}/references/` |
| clarify | expert-advisor-guide.md | `../../references/` |
| impl | agent-patterns.md | `{SKILL_DIR}/../../references/` |
| plan | plan-protocol.md | `{SKILL_DIR}/../../references/` |
| retro | agent-patterns.md | `../../references/` |
| handoff | plan-protocol.md, agent-patterns.md | `../../references/` |
| update | agent-patterns.md | `../../references/` |
| setup | agent-patterns.md | `../../references/` |

## Shared References (`plugins/cwf/references/`)

- `agent-patterns.md` — used by 6 skills
- `plan-protocol.md` — used by 2 skills
- `concept-map.md` — used by 1 skill (refactor)
- `skill-conventions.md` — used by 1 skill (refactor)
- `expert-advisor-guide.md` — used by 1 skill (clarify)

## Proposed Solution (Option C)

Symlink shared references INTO each skill's own `references/` directory:

```text
plugins/cwf/skills/refactor/references/
├── review-criteria.md          (existing, skill-specific)
├── holistic-criteria.md        (existing, skill-specific)
├── docs-criteria.md            (existing, skill-specific)
├── tidying-guide.md            (existing, skill-specific)
├── agent-patterns.md           → ../../references/agent-patterns.md (NEW symlink)
├── concept-map.md              → ../../references/concept-map.md (NEW symlink)
└── skill-conventions.md        → ../../references/skill-conventions.md (NEW symlink)
```

Then update all SKILL.md references:
- `{PLUGIN_ROOT}/references/X` → `{SKILL_DIR}/references/X`
- `../../references/X` → `references/X` (or `{SKILL_DIR}/references/X`)

## Benefits

1. Each skill is self-contained — can be loaded from any location
2. Local symlink development works: `.claude/skills/refactor/` → source
3. No `{PLUGIN_ROOT}` dependency — simpler mental model
4. Shared references remain single-source via symlinks within the repo
5. Marketplace packaging can flatten symlinks at build time if needed

## Risks

- Symlinks in git: need `.gitattributes` or build-time flatten
- Marketplace plugin cache may not preserve symlinks — needs testing
- More symlinks to maintain (but the pattern is mechanical)

## Scope

Estimated: touch 8 SKILL.md files + create ~15 symlinks. Mechanical refactoring — good candidate for codex delegation.

## Decision

Deferred to next session. Interim: use cache sync (manual copy or SessionStart script).
