# Gather — concept-governance-yaml-unification

## Objective
Validate the previous-session draft (`initial-plan.md`) against the current repository state before clarify/plan refinement.

## Input Draft
- Source: `initial-plan.md` (renamed from previous `plan.md`)
- Intent: concept governance layer + YAML contract unification + expert model unification + run-gate integration.

## Baseline Findings (Current Repository)

### 1) Concept Governance Infrastructure
- `plugins/cwf/concepts/` does not exist.
- `plugins/cwf/scripts/check-concepts.sh` does not exist.
- No machine-readable concept binding registry file (for skills/hooks) exists in runtime paths.
- Existing conceptual map exists as documentation:
  - `plugins/cwf/references/concept-map.md`
  - Used in refactor conceptual reviews, but not wired as deterministic gate input.

### 2) Contract Format Reality (JSON + YAML mixed)
- Active JSON contracts still exist:
  - `.cwf/codebase-contract.json`
  - `plugins/cwf/contracts/authoring-contract.json`
  - `plugins/cwf/contracts/portable-contract.json`
  - `plugins/cwf/contracts/claims.json`
  - `plugins/cwf/contracts/change-impact.json`
- Active YAML contracts also exist:
  - `.cwf/docs-contract.yaml`
  - `.cwf/gate-contract.yaml`
  - `.cwf/setup-contract.yaml` (created in this run during setup readiness fix)

### 3) JSON-Coupled Parsers/Flows (Migration Hotspots)
- Portability gate parser (`jq` + JSON schema expectations):
  - `plugins/cwf/scripts/check-portability-contract.sh`
- Change-impact gate parser (JSON rules):
  - `plugins/cwf/scripts/check-change-impact.sh`
- Claim mapping validator (JSON claims):
  - `plugins/cwf/scripts/check-claim-test-mapping.sh`
- Refactor deep-review contract producer/consumers:
  - `plugins/cwf/skills/refactor/scripts/bootstrap-codebase-contract.sh`
  - `plugins/cwf/skills/refactor/scripts/codebase-quick-scan.py`
  - `plugins/cwf/skills/refactor/scripts/select-codebase-experts.sh`

### 4) Expert Model Reality
- Expert roster currently lives in `.cwf/cwf-state.yaml` under `expert_roster`.
- Multiple skills directly assume roster location and update semantics there:
  - `plugins/cwf/references/expert-advisor-guide.md`
  - `plugins/cwf/skills/clarify/SKILL.md`
  - `plugins/cwf/skills/review/SKILL.md`
  - `plugins/cwf/skills/retro/SKILL.md`
- Schema currently enforces roster in cwf-state:
  - `scripts/schemas/cwf-state.schema.json`
- Refactor deep review has separate expert policy path via `codebase-contract.json` (`deep_review.*`) -> policy split currently exists.

### 5) Run/Session State Preparation
- Setup readiness failed at start due to missing setup contract; fixed by creating:
  - `.cwf/setup-contract.yaml`
- Readiness now passes (`check-setup-readiness.sh --summary`: `ready=yes`).

## Gap Summary vs Draft Plan
- Draft target architecture is not partially implemented in runtime gates yet.
- Required migration is structural (concept registry/checkers + parser migrations + expert storage split) and touches cross-skill contracts.
- High-coupling zones: refactor deep-review contract flow, portability/change-impact gates, expert roster read/write path.

## Clarify Inputs (Decision Candidates)
1. Concept source-of-truth location:
- Keep `references/concept-map.md` as human map and add separate machine registry, or fully move to registry-first model.

2. JSON -> YAML migration strategy:
- One-shot breaking cutover vs staged parser bridge (still breaking externally, but staged internally for safer run).

3. Expert policy split contract:
- How `refactor` deep fixed/context experts integrate with new `.cwf/expert-contract.yaml`.

4. Gate sequence priority:
- Whether to implement concept gate first (fail-closed) before contract-format migration, or vice versa.

## Files Reviewed in Gather
- `.cwf/projects/260224-01-concept-governance-yaml-unification/initial-plan.md`
- `.cwf/cwf-state.yaml`
- `plugins/cwf/references/concept-map.md`
- `plugins/cwf/contracts/*.json`
- `plugins/cwf/scripts/check-portability-contract.sh`
- `plugins/cwf/scripts/check-change-impact.sh`
- `plugins/cwf/scripts/check-claim-test-mapping.sh`
- `plugins/cwf/skills/refactor/scripts/bootstrap-codebase-contract.sh`
- `plugins/cwf/skills/refactor/scripts/codebase-quick-scan.py`
- `plugins/cwf/skills/refactor/scripts/select-codebase-experts.sh`
- `scripts/schemas/cwf-state.schema.json`

