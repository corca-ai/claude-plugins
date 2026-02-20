# Next Iteration Single Entry (Iteration 5 Runtime Hardening)

Use this file as the only mention target when starting the next stabilization iteration.

## Single Mention Target

- [.cwf/projects/260219-01-pre-release-audit-pass2/next-iteration-entry-iter5-runtime-hardening.md](next-iteration-entry-iter5-runtime-hardening.md)

## Mandatory Context Load Order

1. [Initial request and operating philosophy](project/initial-req.md)
2. [Iteration 4 master scenarios](iter4/master-scenarios.md)
3. [Iteration 4 progress](iter4/progress.md)
4. [I4-K46 scenario](iter4/scenarios/I4-K46.md)
5. [I4-S10 scenario](iter4/scenarios/I4-S10.md)
6. [I4-W20 scenario](iter4/scenarios/I4-W20.md)
7. [Lessons](lessons.md)
8. [Overall progress report](overall-progress-report.md)
9. [Iteration 4 retro](iter4/retro.md)

## Runtime Residual Objective (Iteration 5)

Close the remaining runtime residuals while keeping `main=deploy` stability.

## Current Residual Risks Before Hardening Close

1. `K46`: historically unstable direct path; latest runtime-smoke checks show no timeout, but close condition must be confirmed repeatedly.
2. `S10`: intermittent `NO_OUTPUT` still reproduces under strict repeated runs.

## Additional Dogfooding Compatibility Risk (2026-02-20)

1. `next-prompt-dir --bootstrap` with `cwf-state.yaml` inline `sessions: []` creates the session directory but can skip session auto-registration.
2. Evidence:
   - codex log reference (`~/.codex/log/codex-tui.log`): line `508367` documents the same compatibility constraint observed in another repository.
   - local repro (this repo): with `sessions: []`, `DIR_CREATED=yes` but state remains unchanged (no appended session entry).
3. Impact:
   - `.cwf/projects/<session>` may exist, but session continuity checks that depend on `cwf-state.yaml` history can drift.
4. Scope clarification:
   - This is currently a registration compatibility gap, not a deterministic local reproduction of directory creation failure.

## New Persisted Runtime Gates (Added on 2026-02-20)

1. `scripts/runtime-residual-smoke.sh`
   - `--mode observe`: record-only signal (non-blocking)
   - `--mode strict`: fail when `K46 timeout > 0` or `S10 no_output > 0`
2. `scripts/tests/runtime-residual-smoke-fixtures.sh`
   - deterministic fixture coverage for observe/strict behavior
3. `scripts/premerge-cwf-gate.sh`
   - new option: `--runtime-residual-mode <off|observe|strict>`
   - default policy:
     - `premerge` -> `off`
     - `predeploy` -> `observe`

## Latest Runtime Smoke Evidence (2026-02-20)

1. Observe run (non-blocking) — PASS:
   - [.cwf/projects/260219-01-pre-release-audit-pass2/iter4/artifacts/runtime-residual-smoke/260220-172429/summary.tsv](iter4/artifacts/runtime-residual-smoke/260220-172429/summary.tsv)
   - signal: `K46 timeout=0`, `S10 no_output=0`, `S10 other=1`
2. Strict run — FAIL:
   - [.cwf/projects/260219-01-pre-release-audit-pass2/iter4/artifacts/runtime-residual-smoke/260220-173004/summary.tsv](iter4/artifacts/runtime-residual-smoke/260220-173004/summary.tsv)
   - signal: `K46 timeout=0`, `S10 no_output=2`

## Immediate Iteration Start Checklist

1. Re-validate deterministic local gate:
   - `bash scripts/premerge-cwf-gate.sh --mode premerge --plugin cwf`
2. Collect runtime baseline signal in observe mode:
   - `bash scripts/premerge-cwf-gate.sh --mode predeploy --plugin cwf --repo corca-ai/claude-plugins --ref main --runtime-residual-mode observe`
3. Implement runtime fixes for `K46` and `S10`.
4. Validate strict close condition:
   - `bash scripts/runtime-residual-smoke.sh --mode strict --plugin-dir plugins/cwf --workdir . --k46-timeout 120 --s10-timeout 120 --s10-runs 5`
   - optional integrated gate: `bash scripts/premerge-cwf-gate.sh --mode predeploy --plugin cwf --repo corca-ai/claude-plugins --ref main --runtime-residual-mode strict`
5. Close bootstrap compatibility gap (`sessions: []`):
   - update `plugins/cwf/scripts/next-prompt-dir.sh` to accept both block and inline-empty sessions forms
   - preserve backward compatibility and avoid duplicate session append
   - add fixture coverage to `scripts/tests/next-prompt-dir-fixtures.sh` for inline `sessions: []`
6. Update scenario evidence, lessons, and overall progress report.

## Baseline Checkpoint (2026-02-20)

- Active branch: `main`
- Deployment model: `main = deploy`
- Latest release version: `cwf 0.8.3`
- Deterministic checks:
  - `bash scripts/premerge-cwf-gate.sh --mode premerge --plugin cwf` PASS
  - `bash scripts/premerge-cwf-gate.sh --mode predeploy --plugin cwf --repo corca-ai/claude-plugins --ref main` PASS
  - `bash .claude/skills/plugin-deploy/scripts/check-consistency.sh cwf` => `gap_count: 0`

## Single-Mention Resume Contract

If a new session mentions only this file, treat it as a full resume trigger:

1. Load documents in the exact order above.
2. Assume this checkpoint as canonical unless newer evidence exists in linked artifacts.
3. Start from `K46` and `S10` runtime hardening immediately without extra bootstrap questions.
