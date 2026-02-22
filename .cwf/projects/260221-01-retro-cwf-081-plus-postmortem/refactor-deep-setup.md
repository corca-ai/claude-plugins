## Refactor Review: setup

### Summary
- Word count: 2833
- Line count: 532
- Structural report: .cwf/projects/260221-01-retro-cwf-081-plus-postmortem/refactor-deep-structural-setup.md
- Quality report: .cwf/projects/260221-01-retro-cwf-081-plus-postmortem/refactor-deep-quality-setup.md

### Structural Review (Criteria 1-4)
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


### Quality + Concept Review (Criteria 5-9)
# Deep Quality Review: setup (Criteria 5-9)

- Criterion 5 (Writing Style) — Severity: n/a. No significant issue; the workflow text keeps imperative instructions (e.g., "Apply selected hook groups..." and "Run external tool checks...") and references the decision/check scripts in `plugins/cwf/skills/setup/SKILL.md:137-199`.
- Criterion 6 (Degrees of Freedom) — Severity: n/a. No significant issue; each phase ties to specific scripts/options (`bash {SKILL_DIR}/scripts/...`, bootstrap commands, gate profiles, etc.), so high-fragility operations stay low freedom and the instructions mention required prompts (phases 2.7-2.10, 3-5) per `plugins/cwf/skills/setup/SKILL.md:137-446`.
- Criterion 7 (Anthropic Compliance) — Severity: n/a. No significant issue; metadata uses only `name`/`description`, description includes when/trigger text, and folder/skill names match kebab-case triggers per `plugins/cwf/skills/setup/SKILL.md:1-62`.
- Criterion 8 (Concept Integrity) — Severity: n/a. No significant issue; the setup skill’s row in the concept map records no generic concepts, so claiming none is consistent with `plugins/cwf/references/concept-map.md:158-173`.
- Criterion 9 (Repository Independence and Portability) — Severity: n/a. No significant issue; scripts and config files operate via `{SKILL_DIR}` relative paths and fallback prompts (e.g., `bash {SKILL_DIR}/scripts/...`, `bootstrap-project-config.sh`, `scripts/bootstrap-gate-contract.sh`), so there are no hard-coded host repo paths beyond generic user/home resolution per `plugins/cwf/skills/setup/SKILL.md:137-446`.


<!-- AGENT_COMPLETE -->
