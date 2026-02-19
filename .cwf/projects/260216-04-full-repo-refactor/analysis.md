# Cross-Plugin Analysis

> Date: 2026-02-16
> Plugins analyzed: 13 skills, 7 hook groups, 1 local skill (plugin-deploy)
> Modes completed: Quick Scan, Holistic (3 axes), Deep Review (all 13 skills), Code Tidying (5 commits), Docs Review

## Plugin Map

| Skill | Words | Lines | Concepts Composed | Key Flags |
|-------|-------|-------|-------------------|-----------|
| setup | 3685 | 850 | — | word/line warning |
| gather | 1900 | 397 | Agent Orchestration | unreferenced csv-to-toon.sh |
| clarify | 2072 | 448 | Expert Advisor, Tier Class., Agent Orch., Decision Point | — |
| plan | 1589 | 332 | Agent Orchestration, Decision Point | — |
| impl | 2640 | 595 | Agent Orchestration, Handoff | — |
| review | 4058 | 702 | Expert Advisor, Agent Orchestration | word/line warning |
| hitl | 1235 | 209 | — | — |
| retro | 3151 | 620 | Expert Advisor, Agent Orchestration | word warning |
| ship | 1495 | 304 | — | — |
| run | 1118 | 210 | Agent Orchestration | — |
| handoff | 2072 | 415 | Handoff | — |
| refactor | 2210 | 433 | Agent Orchestration, Provenance | — |
| update | 386 | 112 | — | — |

## 1. Convention Compliance (Form)

### Critical: Frontmatter Format (ALL 13 skills)

Every skill uses single-line `"` description instead of multi-line `|` with `Triggers:` line as required by `skill-conventions.md`. All 13 skills also lack the `allowed-tools` field.

### Structural Deviations

| Skill | Issue | Severity |
|-------|-------|----------|
| ship | Uses `## Commands` instead of `## Quick Start` | LOW |
| plugin-deploy | Missing `## Rules` and `## References` sections | MODERATE |
| gather | Uses `Trigger on:` instead of `Triggers:` | LOW |

### Adoption-Worthy Patterns

- **clarify**: Exemplary concept composition (4 concepts, well-calibrated freedom levels)
- **review**: Mode-namespaced output files prevent filename collisions
- **retro**: Expert roster maintenance auto-updates in cwf-state.yaml

### Extraction Candidates

- **Context recovery protocol**: Referenced by 5 skills — already extracted to shared reference
- **Sub-agent output sentinel** (`<!-- AGENT_COMPLETE -->`): Used by 6 skills — could formalize in agent-patterns.md
- **Live-state update pattern**: 7 skills repeat the same `cwf-live-state.sh` resolution block

## 2. Concept Integrity (Meaning)

### Expert Advisor (clarify, retro, review)

| Check | clarify | retro | review |
|-------|---------|-------|--------|
| Roster read | YES | **NO** | YES |
| Shared guide | YES (`expert-advisor-guide.md`) | **NO** (uses local `expert-lens-guide.md`) | YES |
| Roster update | NO | YES | NO |
| Tension synthesis | YES | PARTIAL | PARTIAL |

**Key gap**: retro uses a different expert selection path (skill-local guide without roster awareness). Only retro updates the roster, so usage counts reflect only retro usage.

### Tier Classification (clarify only)

Fully implemented. All required behavior, state, and actions present.

### Agent Orchestration (6 skills)

| Skill | Adaptive sizing | Provenance metadata | Parallel execution |
|-------|----------------|--------------------|--------------------|
| clarify | YES (mode selection) | PARTIAL | YES |
| plan | **NO** (always 2 agents) | NO | YES |
| impl | YES (complexity-based) | NO | YES |
| review | YES (mode-specific) | YES (meta.txt files) | YES |
| retro | YES (adaptive depth) | NO | YES |
| refactor | YES (mode-based) | NO | YES |

**Key gap**: plan always spawns 2 agents regardless of task complexity.

### Decision Point (clarify, plan)

- clarify: Full T1/T2/T3 classification with evidence mapping
- plan: **No formal decision log** — decisions embedded implicitly in plan steps without traceability

### Handoff (impl, handoff)

Correct asymmetric composition: impl consumes, handoff produces. Working as designed.

### Provenance (refactor)

Under-implemented: refactor does not check staleness of its own reference documents against current system state. `provenance-check.sh` exists but is not invoked during refactor execution.

## 3. Workflow Coherence (Function)

### Data Flow Issues

| ID | Severity | Issue |
|----|----------|-------|
| F-1 | MODERATE | Review synthesis is ephemeral — no persisted synthesis file for downstream consumers |
| F-2 | LOW | HITL artifacts orphaned from main pipeline (by design) |
| F-3 | LOW | gather → clarify output path is implicit (no file-based discovery contract) |
| F-4 | LOW | clarify → plan: partial implicit path (clarify_result_file in live-state, but plan does not explicitly consume it) |

### Trigger Clarity Issues

| ID | Severity | Issue |
|----|----------|-------|
| F-7 | LOW | "clarify" vs "review --mode clarify" naming overlap (different purposes, OK) |
| F-8 | MODERATE | `cwf:review --human` alias declared by hitl but not routed by review skill |
| F-9 | LOW | refactor trigger "review skill" ambiguous with `/review` |

## 4. Deep Review Skill-Level Findings

### Size Warnings (3 skills)

- **review** (4058w, 702L): Extract mode-specific prompt templates to references
- **setup** (3685w, 850L): Extract hook installer and git hook template to references
- **retro** (3151w, 620L): Monitor growth; consider extracting action-path categories

### Resource Issues

- **gather**: Unreferenced `csv-to-toon.sh` in scripts, `__pycache__` tracked in git
- **refactor**: 3 unreferenced provenance YAML files in references

### Key Per-Skill Findings

| Skill | Key Issue | Severity |
|-------|-----------|----------|
| ship | Hardcoded Korean language policy and `marketplace-v3` base branch | WARNING |
| update | Hardcoded `corca-plugins` publisher path in cache lookup | WARNING |
| handoff | Execution Contract duplicated between SKILL.md and plan-protocol.md | MINOR |
| plan | Lessons template and language rule duplicated 3x internally | MINOR |
| impl | References non-existent `check-session.sh` and `plan-protocol.md` at wrong path | WARNING |

## 5. Code Tidying Opportunities (5 commits)

| Commit | File | Technique | Safety |
|--------|------|-----------|--------|
| 226cdd1 | check-growth-drift.sh | Extract `resolve_path` helper | Mechanical, 8 call sites |
| 226cdd1 | check-growth-drift.sh | Explaining variable (PATH_DRIFT_BUDGET) | Zero-risk rename |
| 504ecf8 | quick-scan.sh | Normalize symmetries (`-f` flag handling) | Whitespace + logic alignment |
| 3580a49 | quick-scan.sh | Python idiom (Path.read_text) | Standard library, same behavior |
| 557b51d | pre-commit + configure-git-hooks.sh | Fix indentation (mapfile at col 0) | Whitespace-only |
| 557b51d | check-links-local.sh | Explaining variable (DRY path string) | printf format, identical output |
| 557b51d | provenance-check.sh | Extract `append_reason` helper | Mechanical, 6 call sites |

## 6. Docs Review Findings

| Priority | Action | Impact |
|----------|--------|--------|
| P0 | Fix marketplace.json: 12→13 skills, add hitl | Marketplace listing accuracy |
| P1 | Align README.md per-skill structure with README.ko.md SSOT | Documentation consistency |
| P2 | Add marketplace.json ↔ README validation script | Prevent future drift |

## Prioritized Actions

| # | Priority | Action | Effort | Impact | Affected |
|---|----------|--------|--------|--------|----------|
| 1 | P0 | Fix marketplace.json skill count and add hitl | Small | Critical — marketplace accuracy | marketplace.json |
| 2 | P0 | Convert all 13 skill descriptions to multi-line `\|` format with `Triggers:` | Medium | Convention compliance | All 13 SKILL.md |
| 3 | P1 | Migrate retro to shared expert-advisor-guide.md (from local expert-lens-guide.md) | Medium | Concept integrity — Expert Advisor consistency | retro SKILL.md, expert-lens-guide.md |
| 4 | P1 | Add roster read/update to clarify and review (Expert Advisor completeness) | Small | Concept integrity | clarify, review SKILL.md |
| 5 | P1 | Persist review synthesis to file (F-1 fix) | Small | Workflow coherence — context-deficit resilience | review SKILL.md |
| 6 | P1 | Add `--human` routing in review skill → hitl (F-8 fix) | Small | Trigger clarity | review SKILL.md |
| 7 | P1 | Align README.md structure with README.ko.md SSOT | Medium | Documentation consistency | README.md |
| 8 | P2 | Extract setup hook installer/git hook template to references | Medium | Size reduction (setup: 850→~465 lines) |  setup SKILL.md |
| 9 | P2 | Add adaptive sizing gate to plan skill | Small | Agent Orchestration consistency | plan SKILL.md |
| 10 | P2 | Add Decision Log section to plan template | Small | Decision Point concept compliance | plan SKILL.md, plan-protocol.md |
| 11 | P2 | Fix ship hardcoded Korean + marketplace-v3 defaults | Small | Portability | ship SKILL.md |
| 12 | P2 | Fix update hardcoded publisher cache path | Small | Portability | update SKILL.md |
| 13 | P2 | Rename ship `## Commands` → `## Quick Start` | Small | Convention compliance | ship SKILL.md |
| 14 | P2 | Add Rules/References to plugin-deploy | Small | Convention compliance | plugin-deploy SKILL.md |
| 15 | P3 | Apply code tidying (7 opportunities across 5 scripts) | Medium | Code quality | Shell scripts |
| 16 | P3 | Remove gather unreferenced csv-to-toon.sh / __pycache__ | Small | Resource health | gather scripts |
| 17 | P3 | Remove refactor unreferenced provenance YAML files | Small | Resource health | refactor references |

<!-- AGENT_COMPLETE -->
