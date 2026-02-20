# Next Iteration Single Entry

Use this file as the only mention target when starting the next pre-release iteration.

## Single Mention Target

- [.cwf/projects/260219-01-pre-release-audit-pass2/next-iteration-entry.md](next-iteration-entry.md)

## Mandatory Context Load Order

1. [Initial request and operating philosophy](../../../project/initial-req.md)
2. [Iteration 2 master scenarios](iter2/master-scenarios.md)
3. [Iteration 2 progress](iter2/progress.md)
4. [Iteration 3 recommendations](iter2/iter3-recommendations.md)
5. [Lessons](lessons.md)
6. [Overall progress report](overall-progress-report.md)

## Current Known Risks Before Main Merge

1. `cwf:retro --light` still times out in non-interactive single-run.
2. `cwf:run` with explicit task still times out in non-interactive single-run.
3. setup 계열은 non-interactive에서 질문형 종료/timeout 변동성이 있다.
4. smoke 분류는 `WAIT_INPUT/NO_OUTPUT`까지 보강했지만 문구 기반 휴리스틱 유지가 필요하다.

## Immediate Iteration Start Checklist

1. Re-validate deterministic local gate: `bash scripts/premerge-cwf-gate.sh --mode premerge --plugin cwf`.
2. Re-check public gate on latest main: `bash scripts/premerge-cwf-gate.sh --mode predeploy --plugin cwf --repo corca-ai/claude-plugins --ref main`.
3. Restart scenario loop from `iter2` master and create `iter3/scenarios` scratchpads.
4. If behavior diverges from intent, stop that branch immediately and record in both scenario file and master.
5. Finish iteration with plan -> review -> impl -> review -> refactor -> retro artifacts, then update overall progress report.

## Pause Checkpoint (2026-02-20)

- Branch baseline: `main`
- Already merged on main:
  - `6d530cf` `fix(cwf): align UserPromptSubmit hooks with Claude Code hook spec`
  - `c6db3d8` `test(cwf): sync UserPromptSubmit gate assertions with hook spec`
  - `e3fbeb1` `chore(gate): enforce plugin consistency in premerge checks`
- Deterministic checks status at checkpoint:
  - `bash plugins/cwf/scripts/test-hook-exit-codes.sh --suite workflow-gate` PASS
  - `bash scripts/hook-core-smoke.sh` PASS
  - `bash scripts/premerge-cwf-gate.sh --mode premerge --plugin cwf` PASS
- Remaining Iteration 2 focus:
  1. Re-run unresolved scenarios in `iter2/master-scenarios.md` (especially `I2-K46`, `I2-R60`, `I2-W20`, setup variability cases).
  2. Keep scenario-by-scenario evidence logs under `iter2/artifacts/` and update `iter2/progress.md`.

## Single-Mention Resume Contract

If a new session mentions only this file, treat it as a full resume trigger:

1. Load documents in the exact order above.
2. Assume the checkpoint state in this file as canonical unless newer evidence is found in linked artifacts.
3. Continue Iteration 2 from unresolved scenarios without asking for additional bootstrap context.

## Operator Note

If only one document is mentioned, treat this file as the canonical launch contract and follow its linked documents in order.
