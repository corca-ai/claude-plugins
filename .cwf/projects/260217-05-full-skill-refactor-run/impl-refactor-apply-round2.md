# Impl Refactor Apply — Round 2 (Post review-code)

Date: 2026-02-17
Session: `.cwf/projects/260217-05-full-skill-refactor-run`

## Trigger
`review-code` six-slot review surfaced blocking concerns on:
- gather generic URL safety precheck
- handoff missing-session edit branch completeness
- update pre/post baseline alias risk
- run provenance durability and gate enforcement
- concept-map provenance count mismatch

## Applied Fixes

1. `plugins/cwf/skills/gather/SKILL.md`
- Added mandatory URL safety precheck (scheme/host/IP class checks) before any fetch.
- Added explicit override confirmation branch and blocked-failure metadata contract.

2. `plugins/cwf/skills/handoff/SKILL.md`
- Completed `Edit fields first` branch with edit loop, validation, re-confirm, and cancel semantics.

3. `plugins/cwf/skills/update/SKILL.md`
- Added deterministic pre-update and post-update snapshots.
- Diff contract now compares stable roots (`old_diff_root` vs `new_diff_root`) to avoid cache-path aliasing.

4. `plugins/cwf/skills/run/SKILL.md`
- Made stage-provenance initialization resume-safe (no unconditional truncate).
- Clarified provenance row append for all stage outcomes, including early-stop paths.
- Hardened explore-worktrees cleanup to non-destructive defaults and explicit decisions when dirty/unmerged.

5. `plugins/cwf/scripts/check-run-gate-artifacts.sh`
- Added deterministic `run-stage-provenance.md` validation in ship stage (presence/header/schema/min row).

6. `plugins/cwf/references/concept-map.md`
- Aligned provenance banner hook count to current inventory (`18`).

## Review-Code Artifacts

Created:
- `review-security-code.md`
- `review-ux-dx-code.md`
- `review-correctness-code.md` (+ `.meta.txt`, `.stderr.log`)
- `review-architecture-code.md` (+ `.meta.txt`, `.stderr.log`)
- `review-expert-alpha-code.md`
- `review-expert-beta-code.md`
- `review-synthesis-code.md`

## Retro + Ship Artifacts

Created:
- `retro-cdm-analysis.md`
- `retro-learning-resources.md`
- `retro-expert-alpha.md`
- `retro-expert-beta.md`
- `retro.md`
- `ship.md`

## Validation

- `check-run-gate-artifacts.sh --stage review-code --strict` → pass
- `check-run-gate-artifacts.sh --stage review-code --stage refactor --stage retro --stage ship --strict` → pass
- `check-run-gate-artifacts.sh --stage ship --strict` → pass
- `check-consistency.sh cwf` → `gap_count: 0`
