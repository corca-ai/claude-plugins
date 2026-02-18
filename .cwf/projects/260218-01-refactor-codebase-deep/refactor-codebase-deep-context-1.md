# Deep Refactor Review (Context Expert: David Parnas)

Identity confirmation: `David Parnas` is present in `.cwf/projects/260218-01-refactor-codebase-deep/refactor-codebase-experts.json` under `selected`.

## Top 3 concerns (blocking risks)

1. `plugins/cwf/scripts/cwf-live-state.sh` is a monolithic state module (1095 lines, scan error), which strongly suggests multiple design decisions are hidden in one place. This raises ripple-effect risk: one change can unintentionally alter unrelated behaviors.
2. Core workflow control appears split across several large scripts with likely implicit coupling, which weakens replaceability of individual modules and makes regression-localization hard.
   - `plugins/cwf/scripts/check-run-gate-artifacts.sh`
   - `plugins/cwf/scripts/check-session.sh`
   - `plugins/cwf/scripts/check-growth-drift.sh`
   - `plugins/cwf/scripts/codex/post-run-checks.sh`
   - `plugins/cwf/scripts/codex/sync-session-logs.sh`
   - `plugins/cwf/hooks/scripts/log-turn.sh`
3. Architecture signals are being masked by noisy scan targets and dense lines, reducing review precision and maintainability where interfaces should be explicit.
   - `scripts/package-lock.json` (747 lines flagged)
   - `plugins/cwf/hooks/scripts/redirect-websearch.sh` (283-char line)
   - `plugins/cwf/hooks/scripts/workflow-gate.sh` (multiple long lines)

## Top 3 suggestions (high leverage)

1. Refactor `plugins/cwf/scripts/cwf-live-state.sh` by information-hiding secrets, not by utility type. Start with distinct modules for: state-path resolution, read API, write/update API, and lock/concurrency handling.
2. Define one small, stable gate interface and move shared workflow decisions behind it, then make large scripts thin adapters.
   - First migration targets: `plugins/cwf/scripts/check-run-gate-artifacts.sh` and `plugins/cwf/scripts/check-session.sh`.
3. Tighten scan fidelity so architectural issues are visible early: exclude generated lockfiles from structural size checks and enforce shorter command construction patterns in hook scripts (`plugins/cwf/hooks/scripts/redirect-websearch.sh`, `plugins/cwf/hooks/scripts/workflow-gate.sh`).

## Prioritized first action

Create and adopt a minimal read-only state interface extracted from `plugins/cwf/scripts/cwf-live-state.sh` (no behavior change), then migrate exactly one consumer (`plugins/cwf/scripts/check-session.sh`) to prove boundary correctness before broader decomposition.
<!-- AGENT_COMPLETE -->
