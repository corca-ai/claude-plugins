# S24 No-Go Remediation Implementation

Date: 2026-02-11
Session: S24

## Commit Units

1. `7f211b1` — self-containment script vendoring + skill convention structure remediation.
2. Current remediation unit — README/inventory/concept/provenance/evidence synchronization.

## Applied Changes

### Concern 1 (Refactor-Led Quality Audit)

- Convention blockers fixed:
  - `plugins/cwf/skills/run/SKILL.md`: added `## References`
  - `plugins/cwf/skills/ship/SKILL.md`: added `## Rules` and `## References`
  - `plugins/cwf/skills/refactor/SKILL.md`: reordered to `Rules -> References`
  - `plugins/cwf/skills/retro/SKILL.md`: renamed quick section to explicit `## Quick Start` and reordered `Rules -> References`
- Inventory and concept/provenance drift resolved:
  - `.claude-plugin/marketplace.json` updated to 12-skill description
  - `docs/architecture-patterns.md` updated to 12-skill inventory
  - `plugins/cwf/references/concept-map.md` updated to 12x6 with `review`/`run`/`ship` rows
  - All 7 provenance sidecars refreshed to `skill_count: 12`, `hook_count: 15`

### Concern 2 (README Framing/Boundary)

- Added minimal framing contract blocks to `README.md` and `README.ko.md`:
  - What CWF Is
  - What CWF Is Not
  - Assumptions
  - Key Decisions and Why
- Synchronized both READMEs to 12-skill inventory and explicit `run` discoverability.
- Removed Korean-only extra deleted-plugins chapter to restore structural equivalence.

### Concern 3 (Discoverability + Self-Containment)

- Added plugin-local script runtime under `plugins/cwf/scripts/` and `plugins/cwf/scripts/codex/`.
- Repointed skill/references script paths away from repo-root scripts in blocker scope plus external review path:
  - `setup`, `run`, `impl`, `handoff`, `plan`, `retro`, `review`
  - `plugins/cwf/references/plan-protocol.md`
- Updated Codex helper script behavior for plugin-local execution compatibility (`plugins/cwf/scripts/codex/sync-skills.sh`, `plugins/cwf/scripts/codex/install-wrapper.sh`).

## Validation Log

Executed:

```bash
bash plugins/cwf/skills/refactor/scripts/quick-scan.sh
bash scripts/provenance-check.sh --level warn
plugins/cwf/hooks/scripts/check-markdown.sh README.md README.ko.md docs/architecture-patterns.md AGENTS.md cwf-index.md
bash -n plugins/cwf/scripts/*.sh plugins/cwf/scripts/codex/*.sh
perl -c plugins/cwf/scripts/codex/redact-sensitive.pl
```

Observed:
- quick-scan errors: 0
- provenance freshness: 7/7 fresh (12 skills / 15 hooks)
- markdown checks: pass on touched docs
- plugin-local script syntax checks: pass (10/10)

## Residual Blocker Status (Post-Remediation)

| Concern | Pre-S24 | Post-S24 | Status |
|---|---|---|---|
| 1. Refactor-led quality audit blockers | FAIL | Blocking inconsistencies removed | RESOLVED |
| 2. README framing boundary/assumption/decision contract | FAIL | Framing contract + inventory sync applied in both READMEs | RESOLVED |
| 3. Discoverability + self-containment | FAIL | plugin-local script references and metadata sync completed | RESOLVED |

## Remaining Non-Blocking Advisories

- `gather`: unreferenced `scripts/csv-to-toon.sh`
- `review`: size guideline warning (>3000 words, >500 lines)
- `refactor`: provenance sidecar reference warnings in quick-scan
