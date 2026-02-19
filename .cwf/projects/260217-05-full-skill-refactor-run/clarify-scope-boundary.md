# Scope Boundary for 260217-05 Full Skill Refactor Run

## In-scope refactors now (safe, high-value)
- Complete the **review-code gate artifacts** that check-run-gate-artifacts reported missing (review-security-code, review-ux-dx-code, review-correctness-code, review-architecture-code, review-expert-alpha-code, review-expert-beta-code, review-synthesis-code) and ensure each file ends with `<!-- AGENT_COMPLETE -->` so the gate can advance.
- Create the **refactor outputs** (summary/quick-scan/deep/tidy) demanded by the refactor gate and confirm the quick-scan report no longer flags missing artifacts.
- Author the **retro.md** and **ship.md** artifacts so their respective gates can close, keeping their content focused on lessons/next steps instead of broader strategy shifts.
- Address the unreferenced provenance files (`references/review-criteria.provenance.yaml`, `references/holistic-criteria.provenance.yaml`, `references/docs-criteria.provenance.yaml`) by either referencing them from skills in this run or explicitly documenting their retirement in a single summary file, which satisfies the quick-scan warning without touching unrelated docs.
- Keep the gating sequence (review-code → refactor → retro → ship) and `remaining_gates` metadata aligned with the cwf:run expectations in `session-state.yaml` while executing the above tasks.

## Out-of-scope refactors now (high-risk, defer)
- Rewriting entire high-volume skills (e.g., `plugins/cwf/skills/setup`, `review`, `retro`) to trim word/line counts; those warnings are known but touching entire skill prose risks regression and exceeds this run’s gate-focused window.
- Altering hooks, base runtime scripts, or pipeline controls that guard the refactor workflow (hooks described in session history and gather reports); preserving deletion guards and gate hooks is critical to avoid breaking the automation chain.
- Introducing new dependencies or refactoring the live-state management machinery (`cwf-live-state.sh`, hooks) during this run; those systems already enforce invariants and tweaking them mid-run invites instability.

## Acceptance constraints before ship
- Every gate artifact listed above must exist, contain `<!-- AGENT_COMPLETE -->`, and satisfy `check-run-gate-artifacts.sh` so `review-code`, `refactor`, `retro`, and `ship` can all pass.
- The quick-scan should stop flagging missing artifacts or unreferenced provenance files, or the resolution should be documented in the refactor artifact so the deterministic evidence report no longer reports failures for this session.
- `session-state.yaml` must advance `remaining_gates` only after each corresponding artifact is in place, ensuring the pipeline order from gather is respected before shipping.

## Explicit no-go criteria for this run
- Do not delete user-created files; prefer adding or modifying the necessary artifacts and use non-destructive moves when re-homing content—explicit approval is required before removing anything.
- Do not invent new gating expectations or skip the mandated review/refactor/retro/ship stages; focus on satisfying the existing run artifacts rather than extending the pipeline.
- Avoid touching unrelated directories (core plugins, external docs) beyond what is necessary to produce the listed artifacts and address their warnings; this run is scope-bound to the cwf run artifacts in the `.cwf/projects/260217-05-full-skill-refactor-run` tree.
