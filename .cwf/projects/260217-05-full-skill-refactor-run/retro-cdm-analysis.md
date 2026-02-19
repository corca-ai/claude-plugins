# Retro CDM Analysis

## Critical Decision Moments

### CDM-1: Make `next-session.md` optional for impl closure
- Situation: Plan review raised a critical correctness risk: `check-session.sh --impl` could fail deterministically if `next-session.md` was not created, even when all target run stages (`review-code`, `refactor`, `retro`, `ship`) were complete.
- Competing options:
  - Keep `next-session.md` mandatory and force explicit generation in this run.
  - Remove hard dependency for this run and treat handoff as follow-up/non-blocking when not explicitly required by scope.
- Decision: Remove `next-session.md` as an impl hard requirement for final closure in this run context.
- Why it mattered: It decoupled run completion from a cross-session artifact that was not part of the immediate pre-deploy acceptance criteria.
- Observed effect: Plan synthesis moved from `Revise` to `Conditional Pass`, and implementation proceeded under deterministic stage gates.

### CDM-2: Require skill-suffixed refactor outputs
- Situation: Full-skill refactor required holistic + 13 per-skill runs. Unsuffixed/common filenames risked overwrite collisions and weak traceability.
- Competing options:
  - Reuse a small set of generic refactor artifact names.
  - Persist per-skill outputs as `refactor-skill-<name>.md` (+ deep variants when present).
- Decision: Enforce per-skill suffixed artifacts and verify presence for all expected skills.
- Why it mattered: It created a one-to-one mapping between executed skill passes and persisted evidence, reducing ambiguity during gate checks and audits.
- Observed effect: Refactor stage checks could validate explicit coverage across the skill set rather than inferring from aggregate logs.

### CDM-3: Shift to contract-driven gates
- Situation: Review rounds identified policy drift risks (provider restriction enforcement, artifact rules, and stage checks spread across prose).
- Competing options:
  - Keep policy hardcoded in plan prose and reviewer expectations.
  - Move policy to explicit gate contract fields (`provider_gemini_mode`, coverage mode, expected skill list) and enforce via deterministic scripts.
- Decision: Adopt contract-driven gate policy with strict/soft behavior encoded in contract files and script execution.
- Why it mattered: It separated policy from narrative text and made pass/fail behavior machine-checkable.
- Observed effect: Prior blocking concerns were closed by either direct fixes or deterministic enforcement paths, enabling a convergent review outcome.

### CDM-4: Treat `review-code` blockers as release blockers and close in-run
- Situation: Code review surfaced blocking defects across security, correctness, provenance, and lifecycle safety (URL safety precheck, provenance consistency, missing branch semantics, update baseline aliasing).
- Competing options:
  - Defer blockers to follow-up debt and continue pipeline.
  - Fix blockers immediately or convert each to deterministic gate enforcement before advancing.
- Decision: Resolve blockers in-run (or convert to enforceable gate checks) before considering code review complete.
- Why it mattered: It prevented “pass by prose” and reduced regression probability in post-impl stages.
- Observed effect: `review-synthesis-code.md` recorded no remaining blocking concerns and verified mandatory behavior criteria.

## Decision Probes

### Probe Set A: Sensemaking quality
- CDM-1: Strong signal-to-decision chain. The team identified a deterministic failure mode early and narrowed scope to run-critical artifacts.
- CDM-2: Strong artifact-level reasoning. The decision recognized collision risk as an evidence-integrity problem, not just naming style.
- CDM-3: High governance maturity. Policy was externalized from prose into contracts, enabling consistent behavior across tools/environments.
- CDM-4: High safety discipline. Blocking findings were treated as operational constraints, not advisory comments.

### Probe Set B: Uncertainty handling
- CDM-1 uncertainty: Could optional handoff reduce continuity? Mitigated by recording deferred debt (D4/D5) and explicit follow-up framing.
- CDM-2 uncertainty: Suffixed files prove coverage but not freshness/uniqueness across reruns. Residual risk was acknowledged; timestamp/sequence suffix was suggested as next hardening.
- CDM-3 uncertainty: Contract flexibility (`warn` vs `fail`) may mask weak environments if tuned too loosely. Risk was managed by explicit policy field visibility.
- CDM-4 uncertainty: Some slot artifacts still reflected earlier blocking narratives. Synthesis-level closure depended on final deterministic verification rather than slot prose alone.

### Probe Set C: Trade-off quality
- CDM-1 traded strict cross-session completeness for deterministic in-scope closure. This was appropriate because handoff automation was explicitly out of current run scope.
- CDM-2 traded naming simplicity for auditability and reproducibility. The trade favored long-term maintainability.
- CDM-3 traded rigid single-policy behavior for configurable policy contracts. This improved portability while preserving deterministic checks.
- CDM-4 traded speed for safety by requiring blocker closure before progression. This increased cycle time but reduced latent deployment risk.

### Probe Set D: Coupling and downstream effects
- CDM-1 reduced coupling between impl closure and handoff artifact generation.
- CDM-2 reduced coupling between parallel/refired refactor runs and artifact integrity.
- CDM-3 reduced coupling between reviewer interpretation and gate outcomes by centralizing policy in contracts.
- CDM-4 reduced coupling between narrative review outputs and actual release readiness by enforcing deterministic closure.

## Counterfactuals

### If CDM-1 had gone the other way (mandatory `next-session.md`)
- Likely outcome: Final closure could fail for scope-extrinsic reasons; implementation quality would be blocked by handoff artifact timing.
- Secondary impact: Teams might generate placeholder handoff documents only to satisfy gate mechanics, degrading artifact quality.

### If CDM-2 had gone the other way (no skill suffixing)
- Likely outcome: Refactor artifacts would be overwritten across skill runs or reruns, creating false confidence in coverage.
- Secondary impact: Root-cause analysis would become slower because provenance from skill run to artifact would be ambiguous.

### If CDM-3 had gone the other way (prose/hardcoded policy)
- Likely outcome: Provider enforcement and stage expectations would drift between review text and scripts.
- Secondary impact: Pass/fail outcomes would become environment-dependent and harder to audit.

### If CDM-4 had gone the other way (defer code blockers)
- Likely outcome: Known defects (safety checks, provenance invariants, branch handling gaps) would move into later stages and surface as harder-to-debug failures.
- Secondary impact: Retro/ship gate confidence would be inflated by unresolved technical contradictions.

## Transferable Lessons

1. Separate scope closure from cross-session continuity artifacts unless continuity is explicitly in-scope and gate-owned.
2. For multi-entity workflows, namespace artifacts by execution unit (`<stage>-<unit>`) first; add run-unique suffixes when reruns are common.
3. Encode policy in contracts consumed by deterministic scripts; keep prose as rationale, not as enforcement.
4. A blocker is only “closed” when fixed in code/spec or converted into a deterministic gate with clear pass/fail semantics.
5. Use deferred-debt registers for architecture improvements, but keep release gates focused on currently enforceable invariants.
6. Preserve evidence integrity: provenance artifacts should be append-safe, schema-validated, and mapped to actual invoked stage skills.

<!-- AGENT_COMPLETE -->
