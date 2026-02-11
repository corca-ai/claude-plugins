# S23 Refactor Evidence (Concerns 1-3)

Date: 2026-02-11
Branch: `marketplace-v3`
Scope baseline: audited **12 active skills** (user-approved expansion from planned 11)

## Execution Evidence

### 1) `cwf:refactor --docs` equivalent checks

Executed evidence checks:

```bash
# Structural docs checks
plugins/cwf/hooks/scripts/check-markdown.sh   # on AGENTS/README/docs set
# Link/path checks
# (local markdown links + image paths resolved)
# Inventory consistency checks
# (README skill tables vs filesystem vs marketplace metadata)
```

Observed results:
- Markdown lint gate: pass on `AGENTS.md`, `CLAUDE.md`, `README.md`, `README.ko.md`, `cwf-index.md`, and core `docs/*.md`.
- Link integrity (sampled entry docs): no missing local links found.
- Consistency drift found:
  - README states "compose across nine skills" and "eleven skills" (`README.md:11`, `README.md:13`) while filesystem has 12 skill dirs.
  - Skill table lists 11 skills and omits `run` (`README.md:50`, `README.md:51`; filesystem has `plugins/cwf/skills/run`).
  - Marketplace metadata still advertises 11 skills (`.claude-plugin/marketplace.json:15`).
  - Architecture doc still advertises 11 skills (`docs/architecture-patterns.md:35`).
  - Korean README diverges in conceptual mapping and lifecycle framing (`README.ko.md:53`, `README.ko.md:84`, `README.ko.md:347`).

Verdict for docs mode: **FAIL** (cross-document inventory and framing consistency blockers).

### 2) `cwf:refactor --holistic` equivalent checks

#### Convention Compliance (Form)

- Shared convention requires `Rules` before `References` and both sections present (`plugins/cwf/references/skill-conventions.md:65`, `plugins/cwf/references/skill-conventions.md:120`, `plugins/cwf/references/skill-conventions.md:184`).
- Violations:
  - `ship`: missing both `## Rules` and `## References` (`plugins/cwf/skills/ship/SKILL.md:288`).
  - `run`: missing `## References` (`plugins/cwf/skills/run/SKILL.md:205`).
  - `refactor`: `References` before `Rules` (`plugins/cwf/skills/refactor/SKILL.md:371`, `plugins/cwf/skills/refactor/SKILL.md:381`).
  - `retro`: `References` before `Rules`, no explicit Quick Start/Quick Reference heading (`plugins/cwf/skills/retro/SKILL.md:27`, `plugins/cwf/skills/retro/SKILL.md:325`, `plugins/cwf/skills/retro/SKILL.md:331`).

#### Concept Integrity (Meaning)

- Concept map declares itself as 9-skill artifact (`plugins/cwf/references/concept-map.md:3`, `plugins/cwf/references/concept-map.md:5`).
- Current system state is 12 skills.
- Missing concept rows for active skills: `review`, `run`, `ship`.
- Provenance gate confirms staleness: 7/7 provenance files stale against current 12 skills / 15 hooks.

#### Workflow Coherence (Function)

- Discoverability mismatch: `run` exists as executable skill but is absent from primary skill tables in README/README.ko.
- Self-containment risk: multiple skill workflows call repo-root scripts outside plugin root (`plugins/cwf/skills/setup/SKILL.md:193`, `plugins/cwf/skills/run/SKILL.md:162`, `plugins/cwf/skills/impl/SKILL.md:387`, `plugins/cwf/skills/handoff/SKILL.md:399`).

Verdict for holistic mode: **FAIL** (convention + concept-sync + self-containment blockers).

### 3) `cwf:refactor --skill <name>` coverage

Deep review coverage completed for all active skills (12):
- `clarify`, `gather`, `handoff`, `impl`, `plan`, `refactor`, `retro`, `review`, `run`, `setup`, `ship`, `update`

Per-skill findings and verdicts are recorded in:
- `prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/skill-coverage-matrix.md`

Coverage status: **12/12 audited**.

### 4) `cwf:refactor --code` equivalent checks

Target commits analyzed (non-`tidy:` recent 5):
- `9769edc` — 79 files changed
- `28990ba` — 1 file changed
- `a2ab31d` — 2 files changed
- `bf22b1b` — 9 files changed
- `d66e3f5` — 11 files changed

Tidy-first opportunities observed:
- External reviewer slot command blocks are duplicated between slot3/slot4 in review skill (`plugins/cwf/skills/review/SKILL.md:293`, `plugins/cwf/skills/review/SKILL.md:340`) and can be extracted to shared prompt/template variables.
- Mixed commits include large prompt-log/doc payloads alongside behavior changes, reducing review clarity; split-by-change-pattern remains advisable for future hardening work.

Verdict for code mode: **WARN** (no critical runtime break detected, but maintainability tidy debt exists).

## Quick Summary

| Mode | Coverage | Verdict |
|---|---:|---|
| `--docs` | core docs + link/lint/inventory checks | FAIL |
| `--holistic` | form/meaning/function | FAIL |
| `--skill <name>` | 12/12 skills | FAIL (aggregate) |
| `--code` | recent 5 commits | WARN |

Aggregate Concern 1 status: **FAIL** (blocking inconsistencies remain before Step 4).

## S24 Remediation Update (Post-Blocker Pass)

Date: 2026-02-11
Branch: `marketplace-v3`

### Re-check Commands

```bash
bash plugins/cwf/skills/refactor/scripts/quick-scan.sh
bash scripts/provenance-check.sh --level warn
plugins/cwf/hooks/scripts/check-markdown.sh README.md README.ko.md docs/architecture-patterns.md AGENTS.md cwf-index.md
```

### Delta Findings

#### Docs / Inventory Consistency

Resolved:
- README framing contract added (`README.md:7`, `README.md:9`, `README.md:15`, `README.md:21`, `README.md:27`).
- README skill inventory synchronized to 12 and includes `run` (`README.md:81`, `README.md:83`, `README.md:247`; `README.ko.md:81`, `README.ko.md:83`, `README.ko.md:248`).
- Marketplace metadata updated to 12-skill description (`.claude-plugin/marketplace.json:15`).
- Architecture doc updated to 12-skill inventory (`docs/architecture-patterns.md:35`).

#### Convention Compliance

Resolved prior blockers:
- `run` now includes `## References` (`plugins/cwf/skills/run/SKILL.md:207`).
- `ship` now includes `## Rules` + `## References` (`plugins/cwf/skills/ship/SKILL.md:290`, `plugins/cwf/skills/ship/SKILL.md:299`).
- `refactor` section order corrected (`plugins/cwf/skills/refactor/SKILL.md:371`, `plugins/cwf/skills/refactor/SKILL.md:382`).
- `retro` now has explicit quick section and corrected order (`plugins/cwf/skills/retro/SKILL.md:27`, `plugins/cwf/skills/retro/SKILL.md:325`, `plugins/cwf/skills/retro/SKILL.md:342`).

#### Concept/Provenance Synchronization

Resolved:
- Concept map updated from 9-skill-era to 12x6 coverage including `review`, `run`, `ship` (`plugins/cwf/references/concept-map.md:5`, `plugins/cwf/references/concept-map.md:168`, `plugins/cwf/references/concept-map.md:169`, `plugins/cwf/references/concept-map.md:171`).
- Provenance freshness now 7/7 fresh against 12 skills / 15 hooks (`scripts/provenance-check.sh --level warn` output).

#### Self-Containment Boundary

Resolved for blocker scope and external-review path:
- Plugin-local scripts added under `plugins/cwf/scripts/*` and skill references repointed from repo-root script paths.
- Evidence paths:
  - `plugins/cwf/skills/setup/SKILL.md:193`
  - `plugins/cwf/skills/run/SKILL.md:40`
  - `plugins/cwf/skills/impl/SKILL.md:387`
  - `plugins/cwf/skills/handoff/SKILL.md:401`
  - `plugins/cwf/skills/plan/SKILL.md:270`
  - `plugins/cwf/skills/retro/SKILL.md:49`
  - `plugins/cwf/skills/review/SKILL.md:293`

### Residual Non-Blocking Advisories

- `gather` still has unreferenced `scripts/csv-to-toon.sh` (quick-scan warning).
- `review` remains over size guideline (>3000 words, >500 lines) (quick-scan warning).
- `refactor` still flags unreferenced provenance sidecars (maintainability warning, not functional blocker).

## S24 Quick Summary

| Mode | Coverage | Verdict |
|---|---:|---|
| `--docs` | README/README.ko + marketplace + architecture + markdown checks | PASS |
| `--holistic` | convention + concept/provenance + self-containment | PASS |
| `--skill <name>` | 12/12 skills re-checked | PASS with warnings |
| `--code` | advisories-only maintainability notes | WARN |

Aggregate Concern 1 status after S24 remediation: **PASS (blockers resolved)**.
