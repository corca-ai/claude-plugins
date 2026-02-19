## Correctness Review
### Concerns (blocking)
- **[C1]** Final closure can deterministically fail because `check-session.sh --impl` requires `next-session.md`, but the plan does not guarantee creating it.
  Evidence: `.cwf/projects/260217-05-full-skill-refactor-run/plan.md:39`, `.cwf/projects/260217-05-full-skill-refactor-run/plan.md:43`, `.cwf/projects/260217-05-full-skill-refactor-run/plan-checkpoint-matrix.md:154`, `.cwf/cwf-state.yaml:19`, `plugins/cwf/scripts/check-session.sh:546`.
  Severity: critical
- **[C2]** “No Gemini” policy is not enforceable for `review-code` and is weakly matched for `review-plan`; gate can pass while violating stated constraints.
  Evidence: `.cwf/projects/260217-05-full-skill-refactor-run/plan.md:23`, `.cwf/projects/260217-05-full-skill-refactor-run/plan-checkpoint-matrix.md:53`, `.cwf/projects/260217-05-full-skill-refactor-run/plan-checkpoint-matrix.md:38`, `plugins/cwf/scripts/check-run-gate-artifacts.sh:105`.
  Severity: critical
- **[C3]** All matrix checks resolve `session_dir` from live state at execution time; if live pointer drifts, verification can target the wrong directory (false pass/fail, broken persistence guarantees).
  Evidence: `.cwf/projects/260217-05-full-skill-refactor-run/plan-checkpoint-matrix.md:19`, `.cwf/projects/260217-05-full-skill-refactor-run/plan-checkpoint-matrix.md:55`, `.cwf/projects/260217-05-full-skill-refactor-run/plan-checkpoint-matrix.md:88`, `.cwf/projects/260217-05-full-skill-refactor-run/plan-checkpoint-matrix.md:153`.
  Severity: moderate
- **[C4]** Success criteria are partially untestable/contradictory: `review-synthesis-plan.md` sentinel is claimed but not checked, and “holistic completed” is claimed without deterministic proof artifact.
  Evidence: `.cwf/projects/260217-05-full-skill-refactor-run/plan.md:55`, `.cwf/projects/260217-05-full-skill-refactor-run/plan.md:57`, `.cwf/projects/260217-05-full-skill-refactor-run/plan-checkpoint-matrix.md:32`, `.cwf/projects/260217-05-full-skill-refactor-run/plan-checkpoint-matrix.md:95`.
  Severity: moderate

### Suggestions (non-blocking)
- **[S1]** Add freshness markers (run timestamp/session id) to per-skill refactor snapshots and verify them to prevent stale-file false positives.
- **[S2]** Add `check-session.sh --live` to final completion to explicitly validate compact-recovery readiness.
- **[S3]** Performance: execute per-skill refactor runs in isolated temp work dirs with bounded parallelism to reduce runtime while avoiding output-collision risk.

### Behavioral Criteria Assessment
- [x] Post-impl stage order respects `review-code -> refactor -> retro -> ship`.
- [ ] Final closure is deterministically reachable without implicit artifact generation.
- [ ] No-Gemini constraint is deterministically enforced in both review stages.
- [ ] Refactor completion criteria provide deterministic proof for holistic execution.
- [ ] `review-plan` sentinel requirement is fully covered by gate checks.

### Provenance
source: REAL_EXECUTION
tool: codex
reviewer: Correctness
duration_ms: —
command: codex exec --sandbox read-only -c model_reasoning_effort='high' -
[cwf:codex post-run] live session-state check
[cwf:codex post-run] post-run checks passed (3 checks)

<!-- AGENT_COMPLETE -->
