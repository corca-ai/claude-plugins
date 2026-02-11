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
