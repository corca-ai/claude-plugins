# Structural Review Results — setup skill (Criteria 1-4)

## Criterion 1: SKILL.md Size
- Severity: Warning — `plugins/cwf/skills/setup/SKILL.md` spans 532 lines, which exceeds the 500-line warning threshold from the review criteria and invites maintenance/scroll fatigue each time the skill loads. Keeping the skill leaner (or breaking strictly narrative sections into references) would reduce cognitive load for callers.

## Criterion 2: Progressive Disclosure Compliance
- No significant issue.

## Criterion 3: Duplication Check
- Severity: Medium — The phase-by-phase guidance for 2.7‑2.10 now exists twice: once verbatim in `plugins/cwf/skills/setup/SKILL.md` lines 320‑380 and again in `plugins/cwf/skills/setup/references/runtime-and-index-phases.md` lines 17‑200. Having full procedural text in both files increases the chance they drift apart; keep the longer checklist solely in the reference (with a single pointer in SKILL) so updates stay centralized.

## Criterion 4: Resource Health
- Severity: Medium — Both `plugins/cwf/skills/setup/references/setup-contract.md` and `.../tool-detection-and-deps.md` exceed 100 lines but do not start with a table of contents, contrary to the “File quality” expectation; adding a short contents list at the top keeps navigation consistent with the other long references.
- Severity: Minor — `plugins/cwf/skills/setup/scripts/migrate-env-vars.sh` is not referenced from SKILL.md or any bundled reference, so the intent of keeping it in this skill set is unclear; either document its role or remove it to avoid carrying dead artifacts.

<!-- AGENT_COMPLETE -->
