# Iteration 4 Master Scenarios

## Objective

Resolve the remaining non-interactive reliability risks and finalize merge-ready evidence.

## Working Rules

- Record per-scenario notes under `iter4/scenarios/`.
- If behavior diverges from intended contract, stop immediately and log evidence first.
- Re-run deterministic gates at iteration start and after each meaningful code change.

## Shared Environment

- Execution branch: `iter3/260219-01-pre-release-audit-pass2`
- Reference branch: `main`
- Canonical resume entry: [.cwf/projects/260219-01-pre-release-audit-pass2/next-iteration-entry.md](../next-iteration-entry.md)

## Scenario Table

| ID | Category | Goal | Status | Notes |
|---|---|---|---|---|
| I4-S00 | bootstrap | capture baseline checkpoint and gate evidence | PASS(BASELINE_CAPTURED) | [.cwf/projects/260219-01-pre-release-audit-pass2/iter4/scenarios/I4-S00.md](scenarios/I4-S00.md) |
| I4-G01 | gate | verify premerge deterministic gate remains PASS | PASS | [.cwf/projects/260219-01-pre-release-audit-pass2/iter4/scenarios/I4-G01.md](scenarios/I4-G01.md) |
| I4-G02 | gate | verify predeploy/public marketplace gate remains PASS | PASS | [.cwf/projects/260219-01-pre-release-audit-pass2/iter4/scenarios/I4-G02.md](scenarios/I4-G02.md) |
| I4-K46 | retro | remove `cwf:retro --light` direct timeout path | FAIL(TIMEOUT) | [.cwf/projects/260219-01-pre-release-audit-pass2/iter4/scenarios/I4-K46.md](scenarios/I4-K46.md) |
| I4-S10 | setup/full | eliminate intermittent `NO_OUTPUT` and force explicit output | PARTIAL(WAIT_INPUT+NO_OUTPUT_RECUR) | [.cwf/projects/260219-01-pre-release-audit-pass2/iter4/scenarios/I4-S10.md](scenarios/I4-S10.md) |
| I4-W20 | worktree/guard | add metadata-all-missing alert path evidence | PASS(FIXED_METADATA_ALERT) | [.cwf/projects/260219-01-pre-release-audit-pass2/iter4/scenarios/I4-W20.md](scenarios/I4-W20.md) |

## Initial Execution Order

1. `I4-S00` -> `I4-G01` -> `I4-G02`
2. `I4-K46` (highest risk)
3. `I4-S10`
4. `I4-W20`

## Execution Notes

- 2026-02-20: `I4-G01`, `I4-G02` baseline/post-fix gate 재검증 PASS.
- 2026-02-20: `I4-K46` direct run은 설치/로컬 plugin-dir 모두 `CLAUDE_EXIT=124` 재현.
- 2026-02-20: `I4-S10`는 WAIT_INPUT 출력 비율은 증가했지만 `NO_OUTPUT`가 반복 재발.
- 2026-02-20: `I4-W20`는 metadata-all-missing 경계 전용 `[WORKTREE ALERT]` 경로를 추가하고 재현 로그 PASS 확보.
