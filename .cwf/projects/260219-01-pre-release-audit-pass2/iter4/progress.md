# Iteration 4 Progress

## Summary

- Master scenarios: [.cwf/projects/260219-01-pre-release-audit-pass2/iter4/master-scenarios.md](master-scenarios.md)
- Current status: IN_PROGRESS
- Last updated: 2026-02-20

## Baseline Carried from Iteration 3

1. Deterministic gates are PASS in `iter3/260219-01-pre-release-audit-pass2`.
2. `I3-K46` remains `FAIL(TIMEOUT)` on direct run, but fast-path script exists.
3. `I3-S10` still has intermittent `NO_OUTPUT` in spot-check.
4. Primary `I3-W20` bypass is fixed, while metadata-all-missing boundary remains.
5. Sandbox gitlink boundaries for iter1/iter2 are normalized to tracked directories and nested `.git` backups are preserved.

## Current Results

1. `I4-S00/G01/G02` baseline and deterministic gates are PASS.
2. `I4-W20` metadata-all-missing boundary gained dedicated `[WORKTREE ALERT]` path and is now PASS(FIXED_METADATA_ALERT).
3. `I4-K46` direct run still times out (`CLAUDE_EXIT=124`) with no body output, including local `--plugin-dir` path.
4. `I4-S10` repeated runs still show intermittent `NO_OUTPUT` (1-byte logs), although explicit `WAIT_INPUT` outputs are more frequent.

## Artifacts Added (Iteration 4)

1. Gate logs:
   - `iter4/artifacts/I4-G01-premerge-20260220T071522Z.log`
   - `iter4/artifacts/I4-G02-predeploy-main-20260220T071535Z.log`
   - `iter4/artifacts/I4-G01-premerge-postfix-20260220T074414Z.log`
   - `iter4/artifacts/I4-G02-predeploy-main-postfix-20260220T074414Z.log`
2. Scenario logs:
   - `iter4/artifacts/I4-K46-retro-light-direct-20260220T071605Z.log`
   - `iter4/artifacts/I4-K46-retro-light-direct-fixed-20260220T073236Z.log`
   - `iter4/artifacts/I4-K46-retro-light-direct-fixed-localplugin-20260220T073928Z.log`
   - `iter4/artifacts/I4-S10-setup-full-repeated-20260220T071819Z.log`
   - `iter4/artifacts/I4-S10-setup-full-repeated-fixed-localplugin-valid-20260220T073542Z.log`
   - `iter4/artifacts/I4-W20-worktree-metadata-boundary-20260220T072839Z.log`
   - `iter4/artifacts/I4-W20-worktree-metadata-boundary-fixed-20260220T073219Z.log`

## Next Action

1. `K46`/`S10` 잔여 리스크를 known residual로 유지할지, runtime-layer 보강을 위해 추가 iteration을 열지 의사결정한다.
2. merge 전 최종 sanity check(`premerge`, `predeploy`, `check-consistency`)를 release tag 기준으로 1회 재실행한다.
