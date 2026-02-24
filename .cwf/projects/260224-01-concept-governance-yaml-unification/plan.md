# Plan — concept-governance-yaml-unification

## Task
"Reorganize CWF around explicit concept governance, unify contract files to YAML, and refactor skills/hooks to compose registered concepts with deterministic concept gates. Backward compatibility is not required for this migration."

## Scope Summary
- **Goal**: Make concept governance executable and auditable via deterministic gates, while completing YAML-only contract governance.
- **Key Decisions**:
  - Registry-first concept governance under `plugins/cwf/concepts/`.
  - YAML-only contract end-state; JSON contract artifacts removed from active runtime.
  - Expert policy split into contract/roster/runtime-state model.
  - Fail-closed concept gate wired into deterministic checks.
- **Known Constraints**:
  - Breaking migration is acceptable (`1.0.0`).
  - `refactor --codebase --deep` fixed experts remain mandatory.
  - No user-created file deletion without explicit confirmation.

## Evidence Baseline
- Gather artifacts:
  - `gather.md`
  - `initial-plan.md`
- Clarify artifact:
  - `clarify-result.md`
- Codebase findings:
  - No `plugins/cwf/concepts/` package exists yet.
  - Runtime still depends on JSON contracts in `plugins/cwf/contracts/*.json` and `.cwf/codebase-contract.json`.
  - Multiple scripts are JSON-coupled (`check-portability-contract.sh`, `check-change-impact.sh`, `check-claim-test-mapping.sh`, refactor codebase contract scripts).
  - `expert_roster` is currently bound to `.cwf/cwf-state.yaml` and schema-enforced there.

## Evidence Gap List
- No blocking evidence gap remains for plan drafting.
- `PERSISTENCE_GATE=SKIP_NO_GAP`

## Architecture Direction

### Target State
1. Concept package exists at `plugins/cwf/concepts/` with:
   - concept docs (`*.md`)
   - concept checkers (`*.sh|*.py|*.mjs`)
   - machine registry (`registry.yaml`)
2. Deterministic concept gate exists at `plugins/cwf/scripts/check-concepts.sh`.
3. Active contracts are YAML-only.
4. Expert policy is split:
   - `.cwf/expert-contract.yaml` (policy)
   - `.cwf/expert-roster.yaml` (persistent memory)
   - `.cwf/cwf-state.yaml` (runtime/live execution only)
5. Skill/hook binding to concepts is explicit and checked.

### Migration Principle
- Execute as phased cutover in one branch:
  - Build scaffolding first.
  - Migrate contracts and parsers.
  - Rebind skills/hooks and enforce fail-closed gates.
  - Finalize release metadata/docs.

## Files to Create/Modify

### Create
- `plugins/cwf/concepts/README.md`
- `plugins/cwf/concepts/registry.yaml`
- `plugins/cwf/concepts/expert.md`
- `plugins/cwf/concepts/contract.md`
- `plugins/cwf/concepts/decision-point.md`
- `plugins/cwf/concepts/tier-classification.md`
- `plugins/cwf/concepts/agent-orchestration.md`
- `plugins/cwf/concepts/handoff.md`
- `plugins/cwf/concepts/provenance.md`
- `plugins/cwf/concepts/check-expert.sh`
- `plugins/cwf/concepts/check-contract.sh`
- `plugins/cwf/concepts/check-decision-point.sh`
- `plugins/cwf/concepts/check-tier-classification.sh`
- `plugins/cwf/concepts/check-agent-orchestration.sh`
- `plugins/cwf/concepts/check-handoff.sh`
- `plugins/cwf/concepts/check-provenance.sh`
- `plugins/cwf/scripts/check-concepts.sh`
- `plugins/cwf/references/contract-governance.md`
- `.cwf/expert-contract.yaml`
- `.cwf/expert-roster.yaml`
- `.cwf/codebase-contract.yaml`

### Modify
- `plugins/cwf/hooks/hooks.json`
- `plugins/cwf/scripts/check-portability-contract.sh`
- `plugins/cwf/scripts/check-change-impact.sh`
- `plugins/cwf/scripts/check-claim-test-mapping.sh`
- `plugins/cwf/skills/refactor/scripts/bootstrap-codebase-contract.sh`
- `plugins/cwf/skills/refactor/scripts/codebase-quick-scan.py`
- `plugins/cwf/skills/refactor/scripts/select-codebase-experts.sh`
- `plugins/cwf/skills/*/SKILL.md` (concept binding references where needed)
- `scripts/schemas/cwf-state.schema.json`
- `.cwf/cwf-state.yaml` (expert model path changes)
- `README.md`
- `README.ko.md`
- plugin metadata/version file(s) (for `1.0.0` bump)

### Decommission (post-migration)
- `.cwf/codebase-contract.json`
- `plugins/cwf/contracts/authoring-contract.json`
- `plugins/cwf/contracts/portable-contract.json`
- `plugins/cwf/contracts/claims.json`
- `plugins/cwf/contracts/change-impact.json`

## Implementation Steps

### Step 0 — Shared Governance Skeleton
- Add concept package scaffold (`README`, `registry.yaml`, initial concept docs/checker stubs).
- Add `contract-governance.md` as single ownership spec.
- Define checker I/O contract and severity model in `registry.yaml`.

### Step 1 — Deterministic Concept Gate
- Implement `check-concepts.sh`:
  - target discovery for skills/hooks
  - binding validation (bound or excluded)
  - concept link/reference checks
  - checker execution and aggregate verdict
- Add deterministic exit codes and concise summary output.

### Step 2 — YAML Contract Migration Core
- Introduce YAML equivalents for active contract artifacts.
- Update parsers/checkers to consume YAML.
- Remove active JSON read-path dependency from portability/change-impact/claim checks.

### Step 3 — Expert Model Unification
- Add `.cwf/expert-contract.yaml` + `.cwf/expert-roster.yaml`.
- Refactor expert read/write paths in clarify/review/retro and refactor deep integration points.
- Update cwf-state schema/state semantics so runtime state excludes persistent policy memory.

### Step 4 — Skill/Hook Binding and Gate Wiring
- Bind all active skills/hooks in `registry.yaml`.
- Add required concept references in SKILL/hook docs.
- Wire `check-concepts.sh` into deterministic gate execution paths.

### Step 5 — Release Closure
- Remove retired JSON contract artifacts.
- Run deterministic suite:
  - schema checks
  - link checks
  - portability/claim/change-impact checks
  - concept gate
- Bump version to `1.0.0`.
- Update `README.md` and `README.ko.md` to migrated model.

## Commit Strategy
- Default: **one commit per step** (`Step 0` to `Step 5`).
- If a step becomes too large, split by coherent change pattern:
  - `contracts+parsers`
  - `expert-model`
  - `bindings+gates`
  - `docs+release`
- No monolithic end-of-session commit.

## Validation Plan
1. Run deterministic scripts after each step where possible.
2. Run `cwf:review --mode code` after implementation milestones.
3. Ensure no active contract JSON remains before release closure.
4. Verify concept gate blocks unbound skills/hooks.
5. Verify refactor deep still enforces fixed experts.

## Decision Log

| # | Decision Point | Evidence / Source (artifact or URL + confidence) | Alternatives Considered | Resolution | Status | Resolved By | Resolved At (UTC) |
|---|----------------|---------------------------------------------------|-------------------------|------------|--------|-------------|-------------------|
| 1 | Draft handling | `clarify-result.md` (high) | Keep as `plan.md` vs rename seed | Preserve prior draft as `initial-plan.md`, regenerate `plan.md` | resolved | user + agent | 2026-02-24T00:00:00Z |
| 2 | Concept registry authority | `gather.md` + existing `concept-map.md` usage (high) | docs-only map vs machine registry-only | Machine registry in `plugins/cwf/concepts/registry.yaml`; `concept-map.md` remains reference narrative | resolved | agent | 2026-02-24T00:00:00Z |
| 3 | Migration sequencing | `gather.md` hotspot coupling findings (high) | one-shot rewrite vs phased cutover | Phased cutover in one branch/run | resolved | agent | 2026-02-24T00:00:00Z |
| 4 | Expert model split and refactor deep integration | `gather.md` + refactor scripts/contract evidence (high) | keep split policy vs unify all into one file | Introduce expert contract+roster, preserve fixed-expert profile semantics in refactor deep | resolved | user plan + agent | 2026-02-24T00:00:00Z |
| 5 | Exclusion sunset policy in concept registry | `initial-plan.md` open questions (medium) | date-based vs release-based | release-based sunset metadata in registry excludes | resolved | user | 2026-02-24T02:02:18Z |
| 6 | Concept checker aggregate output standard | `review-synthesis-plan.md` suggestion (medium) | JSONL vs YAML | Standardize checker aggregate format as JSONL (`registry governance`) | resolved | user | 2026-02-24T02:02:18Z |

## Success Criteria

### Behavioral (BDD)

```gherkin
Given concept registry and bindings are defined
When deterministic concept gate runs
Then every active skill/hook is either bound to >=1 concept or explicitly excluded with reason and owner

Given contract migration is complete
When repository contract checks run
Then all active contracts are YAML and no active contract JSON remains

Given expert model unification is complete
When clarify/review/retro/refactor-deep resolve experts
Then policy and roster data come from dedicated expert contract/roster artifacts and runtime state carries only live execution status

Given release closure
When final verification suite runs
Then version is 1.0.0 and README.md/README.ko.md describe only the migrated architecture
```

### Qualitative
- Deterministic gates are fail-closed and explain failure cause in one screen.
- Concept ownership is auditable by file-level bindings.
- Migration is understandable to maintainers without session memory.
- Documentation reflects runtime truth (no stale legacy guidance).

## Deferred Actions
- [x] Decide exclusion sunset policy default (`release-based` vs `date-based`) before ship stage.
- [x] Confirm whether concept checker aggregate output should standardize on JSONL or YAML before ship stage.
