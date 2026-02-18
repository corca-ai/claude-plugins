# Refactor Summary — Pre-release Audit

## Refactor Summary

Mode coverage:
- `cwf:refactor --codebase`
- `cwf:refactor --skill <all cwf skills, deep criteria-based pass>`
- `cwf:refactor --docs`
- Additional SoT/portability contract audit (README claims vs implementation)

## 1) Codebase Scan (`--codebase`)

Contract metadata:
- CONTRACT_STATUS: `existing`
- CONTRACT_PATH: `.cwf/codebase-contract.json`

Initial findings:
- 7 warnings
  - 1x large file (`configure-git-hooks.sh`)
  - 6x long-line warnings across contracts/scripts

Fixes applied:
- Wrapped/shortened all long-line cases in:
  - `plugins/cwf/contracts/authoring-contract.json`
  - `plugins/cwf/contracts/claims.json`
  - `plugins/cwf/hooks/scripts/check-links-local.sh`
  - `plugins/cwf/scripts/check-portability-fixtures.sh`
  - `plugins/cwf/scripts/check-run-gate-artifacts.sh`
  - `plugins/cwf/skills/setup/scripts/bootstrap-setup-contract.sh`
- Refactored `plugins/cwf/skills/setup/scripts/configure-git-hooks.sh` to template-rendering orchestration and moved hook payloads to:
  - `plugins/cwf/skills/setup/assets/githooks/pre-commit.template.sh`
  - `plugins/cwf/skills/setup/assets/githooks/pre-push.template.sh`

Re-scan result:
- errors: `0`
- warnings: `0`

## 2) Skill Deep Pass (`--skill` across all CWF skills)

Applied deep criteria (1-9) across `plugins/cwf/skills/*` with evidence-based fixes.

Findings fixed:
- Missing navigation TOCs on long guidance docs:
  - `plugins/cwf/references/context-recovery-protocol.md`
  - `plugins/cwf/references/expert-advisor-guide.md`
  - `plugins/cwf/references/plan-protocol.md`
  - `plugins/cwf/skills/setup/references/runtime-and-index-phases.md`
  - `plugins/cwf/skills/setup/references/codex-scope-integration.md`
  - `plugins/cwf/skills/update/references/scope-reconcile.md`
- Clarify research-guide wording mismatch (fallback vs default protocol):
  - `plugins/cwf/skills/clarify/references/research-guide.md`
  - `plugins/cwf/skills/clarify/SKILL.md`
- Setup assets unreferenced in SKILL.md:
  - `plugins/cwf/skills/setup/SKILL.md` now references githook templates explicitly.
- Run-stage completion gate mismatch when skipped stages exist:
  - `plugins/cwf/skills/run/SKILL.md` now specifies final gate validation only for run-closing stages that actually executed (derived from provenance), not hardcoded all stages.

Current deep-pass status:
- no remaining material finding in the reviewed criteria set.

## 3) Docs Review (`--docs`)

Deterministic tool pass:
- `markdownlint-cli2 "**/*.md"` -> pass
- `bash plugins/cwf/skills/refactor/scripts/check-links.sh --local --json` -> pass
- `node plugins/cwf/skills/refactor/scripts/doc-graph.mjs --json` -> pass
- `bash plugins/cwf/scripts/provenance-check.sh --level inform --json` -> all tracked provenance sidecars fresh

Docs-specific fix during pass:
- Corrected TOC fragment/heading mismatch in `plugins/cwf/skills/setup/references/runtime-and-index-phases.md`.

## 4) SoT + Portability Hardening

Detailed matrix: `sot-audit.md` in this session directory.

Key implementation fixes from SoT mismatch/risk findings:
- `plugins/cwf/hooks/scripts/workflow-gate.sh`
  - blocks protected actions while **any** run-closing gate is pending (`review-code`, `refactor`, `retro`, `ship`), not only `review-code`.
- `plugins/cwf/hooks/scripts/compact-context.sh`
  - added non-`jq` fallback JSON extraction/output path to preserve compact recovery behavior under dependency degradation.
- `plugins/cwf/scripts/next-prompt-dir.sh`
  - hardened project-root resolution with caller-cwd priority, explicit `CWF_PROJECT_ROOT` override, and compatibility fallback via script-location ancestry.
- `plugins/cwf/skills/setup/scripts/configure-git-hooks.sh`
  - added degraded-mode fallbacks when `sha256sum/shasum` or `perl` is unavailable, so hook rendering still proceeds instead of hard-failing.
- `plugins/cwf/skills/run/SKILL.md`
  - corrected final gate provenance parsing (`Gate Outcome` column index) so skipped closing stages are not force-validated.

## Verification Snapshot

Runtime checks executed:
- `bash plugins/cwf/scripts/check-portability-fixtures.sh` -> pass
- `bash plugins/cwf/skills/setup/scripts/check-setup-contract-runtime.sh` -> pass
- `bash plugins/cwf/skills/refactor/scripts/check-codebase-contract-runtime.sh` -> pass
- `bash -n` syntax checks on modified shell scripts/templates -> pass

Conclusion:
- Refactor/code/docs and SoT portability issues found in this audit were addressed and revalidated.
