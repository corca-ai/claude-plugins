# Plan — concept-governance-yaml-unification

## Task
"Reorganize CWF around explicit concept governance, unify contract files to YAML, and refactor skills/hooks to compose registered concepts with deterministic concept gates. Backward compatibility is not required for this migration."

## Why This Work Exists (Philosophy and Intent)
- CWF claims concept-driven composition (Daniel Jackson framing), but enforcement is currently implicit and fragmented.
- When concept ownership is implicit, behavior drifts across skills and hooks, and reviewers cannot prove whether the system still follows its own design.
- This migration turns concepts into first-class executable contracts: each concept has principle docs, deterministic checks, and explicit composition registration.
- The goal is not cosmetic cleanup; the goal is to make architecture auditable and fail-closed when concept integrity is broken.

## Context Captured from Today
1. Expert usage must be treated as one concept with shared execution semantics, not skill-specific ad-hoc behavior.
2. Repo-level expert policy should live in a contract file (proposed `.cwf/expert-contract.yaml`), not embedded in one script.
3. `refactor --codebase --deep` keeps fixed-expert policy because it is valuable in refactoring context.
4. Contract/state split should be explicit:
   - contract = policy (repository-specific and editable)
   - state = runtime/live execution status
   - roster/history = persistent memory artifact, separate from live state
5. Contract format should be unified to YAML.
6. Breaking change is acceptable; version should move from `0.8.12` to `1.0.0`.

## Scope Summary
- Create a concept governance layer under `plugins/cwf/concepts`.
- Define concept registry + binding model for all skills/hooks.
- Enforce "every active skill/hook maps to >=1 concept" via deterministic gate.
- Require registered targets to reference concept docs and pass concept checks.
- Migrate contract artifacts from mixed JSON/YAML to YAML-only policy.
- Integrate Expert concept with shared contract + roster model.
- Recompose skill/hook docs and execution flow to align with concept gates.
- Reflect final architecture/policy changes in README docs before release (`README.md`, `README.ko.md`).

## Non-Goals
- Preserve old contract file paths or mixed-format readers.
- Maintain old behavior compatibility for external consumers.
- Maintain strict README locale parity at every intermediate commit during migration.

## Baseline Findings (Before Migration)
- Contract format is mixed:
  - `.cwf/codebase-contract.json`
  - `.cwf/docs-contract.yaml`
  - `.cwf/setup-contract.yaml` / `.cwf/gate-contract.yaml`
  - `plugins/cwf/contracts/*.json`
- Expert roster currently lives in `.cwf/cwf-state.yaml` while refactor deep uses `codebase-contract.json`, causing split policy semantics.
- No single "contract governance owner" document currently defines format/ownership/lifecycle globally.

## Target Architecture

### 1) Concept Package (`plugins/cwf/concepts/`)
- One concept = two files (same basename):
  - `<concept>.md` (principles, required behavior/state/actions, composition rules)
  - `<concept>.sh|py|mjs` (deterministic checker)
- Initial mandatory concepts:
  - `expert`
  - `contract`
  - `decision-point`
  - `tier-classification`
  - `agent-orchestration`
  - `handoff`
  - `provenance`

### 2) Registry and Binding (`plugins/cwf/concepts/registry.yaml`)
- `concepts`: concept metadata, checker path, severity mode.
- `bindings.skills`: skill-to-concept mapping.
- `bindings.hooks`: hook-to-concept mapping.
- `exclude`: non-composed files explicitly excluded with reason/owner.

### 3) Concept Gate (`plugins/cwf/scripts/check-concepts.sh`)
- Fail when a skill/hook is not registered and not excluded.
- Fail when a registered target maps to zero concepts.
- Fail when concept reference links are missing from the target doc.
- Run all bound concept checkers and aggregate fail/warn verdict.

### 4) Contract Model (YAML-Only)
- Canonical policy files in `.cwf/*.yaml`.
- No new `*contract*.json` artifacts after migration.
- Contract concept checker enforces YAML format and ownership rules.

### 5) Expert Model (Unified Concept)
- Policy: `.cwf/expert-contract.yaml`
- Roster memory: `.cwf/expert-roster.yaml`
- Runtime state: keep only live execution data in `.cwf/cwf-state.yaml`
- Shared expert execution path for `clarify`, `review`, `retro`, and `refactor --codebase --deep` with profile-based policy.

## Execution Plan

### Phase 1 — Governance Skeleton
1. Add `plugins/cwf/references/contract-governance.md` as the single owner for contract lifecycle and format policy.
2. Add `plugins/cwf/concepts/README.md` and `plugins/cwf/concepts/registry.yaml`.
3. Define naming/IO contract for concept checkers (inputs, outputs, exit codes).

### Phase 2 — Concept Artifacts
1. Author initial concept docs (`*.md`) from `references/essence-of-software/distillation.md`.
2. Implement initial checkers (`*.sh|py|mjs`) for each concept.
3. Add deterministic tests for concept checker runtime behavior.

### Phase 3 — Expert and Contract Unification
1. Create `.cwf/expert-contract.yaml` and `.cwf/expert-roster.yaml` schema + bootstrap/update scripts.
2. Move expert roster logic out of `cwf-state.yaml` flows.
3. Migrate `codebase-contract.json` to `.cwf/codebase-contract.yaml`.
4. Convert portability/authoring contracts to YAML and update gate parser logic.

### Phase 4 — Skill/Hook Recomposure
1. Rebind all `plugins/cwf/skills/*/SKILL.md` and `plugins/cwf/hooks/hooks.json` entries to concepts.
2. Update each bound target to reference concept docs directly.
3. Ensure concept checkers are invoked for each bound target in deterministic gates.

### Phase 5 — Gate Wiring and Release
1. Wire `check-concepts.sh` into hook/post-run/premerge gates.
2. Run full deterministic suite (schemas, hooks, link checks, concept gates).
3. Bump plugin version `0.8.12 -> 1.0.0`.
4. Update README docs to faithfully reflect branch outcomes and new operating model (`README.md`, `README.ko.md`).
5. Record migration notes for reinstall-first workflow.

## Risk Management (Focus: JSON -> YAML Migration)

### Risk A: Parser/tooling breakage during migration
- Cause: many scripts currently assume JSON (`jq`, Python `json.load`).
- Mitigation:
  1. Introduce a shared YAML access layer first (single helper interface used by scripts).
  2. Promote `yq` from optional candidate to required setup dependency for this repo.
  3. Migrate one contract path at a time with runtime checks before broad rollout.

### Risk B: Silent policy drift after conversion
- Cause: schema/field mismatch when porting JSON contracts to YAML.
- Mitigation:
  1. Add schema parity tests before and after conversion.
  2. Add migration diff check that compares semantic keys, not text format.
  3. Fail closed on missing required keys.

### Risk C: Concept gate too strict/too noisy
- Cause: immediate full enforcement without scoped exclusions.
- Mitigation:
  1. Start with explicit `exclude` entries and reasons.
  2. Require owner + sunset criteria for each exclusion.
  3. Convert exclusions to bindings incrementally.

### Risk D: Expert unification weakens refactor deep fixed-expert value
- Cause: over-generalized expert selection path.
- Mitigation:
  1. Keep `refactor_codebase_deep` profile with fixed experts as mandatory.
  2. Add dedicated checker assertions for fixed slots.
  3. Validate deep outputs still include fixed+context rationale.

## Files Expected to Be Created or Reworked
- `plugins/cwf/concepts/README.md`
- `plugins/cwf/concepts/registry.yaml`
- `plugins/cwf/concepts/*.md`
- `plugins/cwf/concepts/*.sh` / `*.py` / `*.mjs`
- `plugins/cwf/scripts/check-concepts.sh`
- `plugins/cwf/references/contract-governance.md`
- `.cwf/expert-contract.yaml`
- `.cwf/expert-roster.yaml`
- `.cwf/codebase-contract.yaml` (replacing JSON)
- `plugins/cwf/contracts/*.yaml` (replacing JSON variants)
- Skill/hook docs and scripts touched by concept binding and contract parser updates

## Decision Log

| # | Decision Point | Resolution | Status |
|---|---|---|---|
| 1 | Backward compatibility required? | No. Reinstall-first migration accepted. | resolved |
| 2 | Contract format target | YAML-only across CWF contracts. | resolved |
| 3 | Expert policy ownership | Repo-local expert contract + separate roster memory file. | resolved |
| 4 | Refactor deep fixed experts | Keep fixed experts as profile-level mandatory policy. | resolved |
| 5 | Release impact | Breaking architecture update in major bump (`1.0.0`). | resolved |

## Success Criteria

```gherkin
Given concept registry and bindings are defined
When deterministic concept gate runs
Then every active skill/hook is either bound to >=1 concept or explicitly excluded with reason

Given contract migration is complete
When searching for contract artifacts
Then no active contract file remains in JSON format

Given expert concept unification is complete
When clarify/review/retro/refactor deep invoke expert workflows
Then selection/execution/roster updates follow one shared contract-driven path with profile-specific policy

Given refactor codebase deep profile
When expert selection is resolved
Then fixed experts remain mandatory and contextual experts are added deterministically

Given release preparation
When plugin metadata is updated
Then version is bumped from 0.8.12 to 1.0.0 and migration notes are documented

Given release documentation finalization
When concept/contract/expert migration work is complete
Then README.md and README.ko.md both describe the new model and constraints without stale legacy guidance
```

## Open Questions for Next Session Kickoff
1. Should concept checker outputs be normalized to one machine-readable format (`jsonl` vs `yaml`) for gate aggregation?
2. Do we want one global contract schema file for all contract types, or per-contract schema with shared meta-fields?
3. For exclusions, should expiration be date-based or release-based?
