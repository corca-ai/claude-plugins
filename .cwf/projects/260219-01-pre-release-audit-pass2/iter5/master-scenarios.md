# Iteration 5 Master Scenarios

## Objective

Close runtime residuals (`K46`, `S10`) and the bootstrap registration compatibility gap (`sessions: []`) while preserving `main=deploy` stability.

## Working Rules

- Keep deterministic gates as pass/fail authority.
- Persist scenario evidence under `iter5/scenarios/` and `iter5/artifacts/`.
- Treat direct runtime variance as a wrapper-level mitigation target before phrasing-only tweaks.

## Shared Environment

- Execution branch: `main`
- Deployment model: `main = deploy`
- Resume entry: [.cwf/projects/260219-01-pre-release-audit-pass2/next-iteration-entry-iter5-runtime-hardening.md](../next-iteration-entry-iter5-runtime-hardening.md)

## Scenario Table

| ID | Category | Goal | Status | Notes |
|---|---|---|---|---|
| I5-G01 | gate | Re-validate deterministic premerge gate | PASS | [.cwf/projects/260219-01-pre-release-audit-pass2/iter5/scenarios/I5-G01.md](scenarios/I5-G01.md) |
| I5-R10 | runtime | Confirm pre-fix residual signal and close strict condition | PASS(CLOSED) | [.cwf/projects/260219-01-pre-release-audit-pass2/iter5/scenarios/I5-R10.md](scenarios/I5-R10.md) |
| I5-B20 | bootstrap | Fix `next-prompt-dir --bootstrap` inline `sessions: []` registration | PASS(FIXED_INLINE_SESSIONS) | [.cwf/projects/260219-01-pre-release-audit-pass2/iter5/scenarios/I5-B20.md](scenarios/I5-B20.md) |
| I5-G02 | gate | Validate integrated predeploy gate with runtime strict mode | PASS | [.cwf/projects/260219-01-pre-release-audit-pass2/iter5/scenarios/I5-G02.md](scenarios/I5-G02.md) |

## Execution Notes

- 2026-02-20: `runtime-residual-smoke` strict reached `K46 timeout=0` and `S10 no_output=0` after runtime wrapper hardening.
- 2026-02-20: `next-prompt-dir.sh` now appends session metadata for both block-style `sessions:` and inline-empty `sessions: []`.
- 2026-02-20: `premerge` and integrated `predeploy --runtime-residual-mode strict` both PASS.
