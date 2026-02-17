# Cross-Plugin Analysis

> Date: 2026-02-17
> Scope: rerun after `6665d30` (`setup/update` scope-aware implementation)
> Inputs: `.cwf/projects/260217-06-setup-update-scope-aware/refactor-holistic-{convention,concept,workflow}.md`

## Plugin Map (focused)

| Plugin/Skill | Type | Focus |
|---|---|---|
| `setup` | skill | scope-aware codex integration and install-time safety |
| `update` | skill | scope-aware reconciliation after plugin update |
| `run` | skill | stage gating and completion contract coherence |
| `ship` | skill + gate script consumer | merge/closure policy and artifact contract |

## 1. Convention Compliance (Form)

- Scope-aware contract across `setup`/`update` is substantially aligned.
- Remaining convention gaps:
  1. user-global mutation confirmation policy is asymmetric (`setup` has stronger second guard than `update`).
  2. missing-dependency interactive handling is richer in `setup` than `update`.
  3. `setup` document size remains significantly above deep-review thresholds, increasing drift risk.

## 2. Concept Integrity (Meaning)

- Scope-aware behavior is implemented but concept-map representation is weak for this capability class.
- Current map treats `setup`/`update` as concept-empty operational rows despite shared safety/authority behavior.
- Provenance freshness is good (13 skills, 18 hooks), but concept ownership for scope authority is under-specified.

## 3. Workflow Coherence (Function)

High-impact coherence findings:
1. `run --skip ship` vs completion-time ship gate requirement can conflict in strict closure semantics.
2. `setup/update` scope detection currently has fail-open fallback tendencies toward `user` in error paths.

Medium findings:
1. Update restart boundary is advisory only; downstream run/ship do not enforce a restart handshake.
2. `blocking_decisions_pending` final sync can diverge from ambiguity-debt truth if forced false at completion.

Low finding:
1. Ship invocation naming (`/ship` vs `cwf:ship`) can be normalized for routing clarity.

## Prioritized Actions

| Priority | Action | Effort | Impact | Affected |
|---|---|---|---|---|
| P1 | Align `update` user-global mutation guard with `setup` second-confirmation semantics | S | High | `setup`, `update` |
| P1 | Replace scope-detection fail-open fallback with explicit confirmation on detection failure | M | High | `setup`, `update` |
| P1 | Resolve `run --skip ship`/final ship gate contradiction with explicit skip-contract artifact or conditional gate execution | M | High | `run`, `ship`, `check-run-gate-artifacts.sh` |
| P2 | Add update→run/ship restart handshake signal and enforcement | M | Medium | `update`, `run`, `ship` |
| P2 | Add lightweight concept-map treatment for scope authority behavior | M | Medium | `concept-map`, `setup`, `update` |
| P3 | Reduce setup SKILL size by extracting operational detail to references | M | Medium | `setup` |

## Related Deep Skill Reruns

- `.cwf/projects/260217-06-setup-update-scope-aware/refactor-skill-setup.md`
- `.cwf/projects/260217-06-setup-update-scope-aware/refactor-skill-update.md`
