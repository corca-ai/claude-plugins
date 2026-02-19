## Refactor Summary

Session: `pre-release-audit-pass2`

### Mode: `cwf:refactor --codebase`
- Contract: `.cwf/codebase-contract.json` (`existing`)
- Scan artifact: `.cwf/projects/260219-01-pre-release-audit-pass2/refactor-codebase-scan.json`
- Finding fixed:
  - `plugins/cwf/scripts/test-hook-exit-codes-suite-decision-journal.sh`: added `set -euo pipefail`
- Re-run result: `errors=0`, `warnings=0`

### Mode: `cwf:refactor --skill <all>` (deep batches)
- Artifacts:
  - `.cwf/projects/260219-01-pre-release-audit-pass2/refactor-deep-batch-a.md`
  - `.cwf/projects/260219-01-pre-release-audit-pass2/refactor-deep-batch-b.md`
  - `.cwf/projects/260219-01-pre-release-audit-pass2/refactor-deep-batch-c.md`
  - `.cwf/projects/260219-01-pre-release-audit-pass2/refactor-deep-batch-d.md`
  - `.cwf/projects/260219-01-pre-release-audit-pass2/refactor-deep-batch-e.md`
  - `.cwf/projects/260219-01-pre-release-audit-pass2/refactor-deep-batch-f.md`
  - `.cwf/projects/260219-01-pre-release-audit-pass2/refactor-deep-batch-g.md`
- Key fixes applied from deep findings:
  - `plugins/cwf/skills/hitl/SKILL.md`: intent-resync duplication reduced + first-run pointer-missing bootstrap path added.
  - `plugins/cwf/skills/review/SKILL.md`: Codex auth-aware preflight routing guidance added.
  - `plugins/cwf/skills/review/references/orchestration-and-fallbacks.md`: AUTH classifier expanded for faster fallback path.
  - `plugins/cwf/skills/setup/SKILL.md`: missing `check-configure-git-hooks-runtime.sh` reference added.
  - `plugins/cwf/skills/update/SKILL.md` and `plugins/cwf/skills/update/references/scope-reconcile.md`: cache root portability (`CWF_UPDATE_CACHE_ROOTS`, XDG, `/usr/local/share`) added.
  - `plugins/cwf/references/concept-map.md`: `run` concept map row aligned with actual sequential pipeline behavior.
- Deferred item:
  - compiled artifact in `plugins/cwf/skills/gather/scripts/__pycache__/` is still present (deletion/move policy decision pending).

### Mode: `cwf:refactor --docs`
- Contract: `.cwf/docs-contract.yaml`
- Deterministic checks:
  - `markdownlint`: pass
  - local link check: pass
  - `doc-graph`: pass (`broken_ref_count=0`)
- Fix applied:
  - `plugins/cwf/references/skill-conventions.md` example link corrected to valid relative path.

### Systemic audit fixes (SoT / repo-agnostic / contract-first / backcompat)
- `plugins/cwf/scripts/codex/sync-skills.sh`
  - removed `--cleanup-legacy` behavior and obsolete legacy layout branch.
  - simplified to current plugin-root layout only.
- `plugins/cwf/skills/setup/scripts/bootstrap-setup-contract.sh`
  - fallback path is now fail-safe (non-zero exit).
- `plugins/cwf/skills/refactor/scripts/bootstrap-codebase-contract.sh`
  - fallback path is now fail-safe (non-zero exit).
- Runtime checks updated for fail-safe semantics:
  - `plugins/cwf/skills/setup/scripts/check-setup-contract-runtime.sh`
  - `plugins/cwf/skills/refactor/scripts/check-codebase-contract-runtime.sh`
- setup flow decoupled from legacy env migration script:
  - `plugins/cwf/skills/setup/SKILL.md`
  - `plugins/cwf/skills/setup/references/runtime-and-index-phases.md`
  - `plugins/cwf/skills/setup/README.md`
- README-level manual migration prompt added (skill flow excluded):
  - `README.md`
  - `README.ko.md`

### Validation summary after fixes
- `bash plugins/cwf/scripts/check-growth-drift.sh --level warn` → pass
- `bash plugins/cwf/scripts/check-portability-contract.sh --contract auto --context manual` → pass
- `bash plugins/cwf/scripts/check-setup-contract-runtime.sh` → pass
- `bash plugins/cwf/skills/refactor/scripts/check-codebase-contract-runtime.sh` → pass
- `bash plugins/cwf/scripts/check-readme-structure.sh --strict` → pass
- `bash plugins/cwf/scripts/check-change-impact.sh --working` → pass
- `bash plugins/cwf/scripts/check-claim-test-mapping.sh` → pass
- `bash plugins/cwf/scripts/check-hook-sync.sh` → pass
