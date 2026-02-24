## Requirement Clarification Summary

### Before (Original)
"Run `cwf:run` for `.cwf/projects/260224-01-concept-governance-yaml-unification/plan.md`, treat it as a draft, start from gather, continue through the pipeline, and actively request user decisions when needed."

### After (Clarified)
**Goal**: Execute a full CWF run for the concept-governance + YAML-unification migration, using the previous-session draft as seed input and producing an implementation-ready execution contract plus code changes in this branch.

**Reason**: Turn concept-driven architecture from implicit documentation into deterministic, gate-enforced runtime behavior with YAML-only contract governance.

**Scope**:
- Included:
  - Use existing draft as `initial-plan.md`
  - Run gather -> clarify -> plan -> review(plan) -> impl -> review(code) -> refactor -> retro -> ship workflow intent
  - Implement concept-governance scaffolding and YAML contract migration in repo code/docs
  - Update run/review/refactor-related deterministic gates as required by migrated contracts
  - Update `README.md` and `README.ko.md` before release
- Excluded:
  - Backward-compatibility shims for external consumers
  - Maintaining legacy JSON contract artifacts after migration completion

**Constraints**:
- Breaking change is acceptable (`1.0.0` target remains valid).
- `refactor --codebase --deep` fixed experts must remain mandatory.
- Deterministic gates are authoritative (no prose-only bypass).
- User-created files must not be deleted without explicit confirmation.

**Success Criteria**:
- Every active skill/hook is bound to >=1 concept or explicitly excluded with owner/reason.
- Contract governance is YAML-only at end-state; no active `*contract*.json` remains.
- Expert policy/roster/state split is explicit and operationally enforced.
- Release docs reflect the migrated architecture without stale legacy guidance.

### Decisions Made

| Question | Decision |
|---|---|
| How to treat the previous `plan.md`? | Preserve as `initial-plan.md`; regenerate `plan.md` during run planning stage. |
| Concept source of truth model | Add machine-readable registry under `plugins/cwf/concepts/registry.yaml`; keep `references/concept-map.md` as explanatory reference, not gate SSOT. |
| Migration execution style | Execute in phased cutover within one branch/run (skeleton -> concept artifacts -> contract/expert migration -> binding/wiring -> release updates). |
| Gate rollout order | Build concept gate early, switch to fail-closed enforcement after bindings and references are in place. |
| Expert policy split direction | Introduce `.cwf/expert-contract.yaml` + `.cwf/expert-roster.yaml`; keep runtime-only fields in `.cwf/cwf-state.yaml`. |
| Scope for this run | Continue full pipeline intent, raising user decisions only when a blocking architecture fork appears. |

