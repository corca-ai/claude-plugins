# Lessons — pre-release-audit-pass2

### v3 우선 정책 확정

- **Expected**: 기존 하위호환을 가능한 한 유지하면서 점진 개선
- **Actual**: 사용자 의도가 명확히 v3 완성도 우선(미배포 v3 기준 하위호환 불필요)
- **Takeaway**: pre-release major 전환에서는 기술부채를 남기는 호환 레이어보다 명확한 계약/동작을 우선한다

When pre-1.0 대격변 구간이라면 -> compatibility shim 추가보다 제거/단순화를 기본값으로 둔다.

### 의사결정 게이트 방식

- **Expected**: 대부분 자율 처리
- **Actual**: 아키텍처/정책 트레이드오프가 있으면 사용자와 합의 후 진행이 필요
- **Takeaway**: 자동 수정과 사용자 의사결정 경계를 계획 단계에서 명시해야 재작업이 줄어든다

When 선택지 간 장단점이 명확히 갈리는 구조적 변경이면 -> 즉시 옵션/트레이드오프를 제시하고 중단한다.

### 서브에이전트 활용 기준

- **Expected**: 일부 탐색만 병렬화
- **Actual**: 사용자가 토큰 비용보다 검토 품질을 우선하므로 병렬 분석 최대화가 요구됨
- **Takeaway**: 분석 단계(코드/클레임/외부 prior-art)를 분리해 병렬 수집 후 합성하는 방식이 적합하다

When 점검 범위가 코드+문서+운영계약까지 걸치면 -> 탐색 서브에이전트를 도메인별로 분리해 동시에 실행한다.

## Run Gate Violation — 2026-02-18T22:43:23Z
- Gate checker: `plugins/cwf/scripts/check-run-gate-artifacts.sh`
- Persistence gate: `HARD_FAIL`
- Recorded failures:
  - [refactor] refactor-summary.md missing heading: ## Refactor Summary

## Run Gate Violation — 2026-02-18T23:51:22Z
- Gate checker: `plugins/cwf/scripts/check-run-gate-artifacts.sh`
- Persistence gate: `HARD_FAIL`
- Recorded failures:
  - [retro] retro.md missing '- Mode:' declaration

## Iteration 2 Lesson — Smoke False PASS Hardening (2026-02-19)

- **Expected**: `WAIT_INPUT` 패턴만 보강하면 non-interactive false PASS가 충분히 줄어든다.
- **Actual**: 질문형 문구가 스킬/상황마다 다양하고, 빈 출력(`exit 0`) 케이스도 존재해 추가 누락이 발생했다.
- **Takeaway**: smoke 분류는 `WAIT_INPUT` + `NO_OUTPUT`를 fail-closed 기본값으로 두고, 신규 문구는 픽스처부터 추가해야 한다.

When non-interactive smoke reports unexpected PASS with incomplete behavior -> first add fixture and classifier rule, then rerun gate before concluding.

## Iteration 2 Lesson — UserPromptSubmit Contract Drift (2026-02-20)

- **Expected**: `workflow-gate`를 UserPromptSubmit 스펙에 맞춰 수정해도 로컬 deterministic gate는 함께 유지된다.
- **Actual**: 런타임 계약(allow payload, block exit code)은 바뀌었지만 테스트/스모크 assertion은 이전 계약에 머물러 회귀 실패가 발생했다.
- **Takeaway**: 훅 계약을 변경할 때는 `hook script + hook tests + premerge smoke`를 하나의 변경 단위로 동기화해야 한다.

When UserPromptSubmit 계약을 수정하면 -> 아래 3개를 같은 커밋에서 재검증한다.

1. `bash plugins/cwf/scripts/test-hook-exit-codes.sh --suite workflow-gate`
2. `bash scripts/hook-core-smoke.sh`
3. `bash scripts/premerge-cwf-gate.sh --mode premerge --plugin cwf`

## Iteration 2 Lesson — Release Metadata Drift (2026-02-20)

- **Expected**: 버전 변경 시 `plugin.json`과 `.claude-plugin/marketplace.json`이 항상 동기화된다.
- **Actual**: `plugin.json`만 증가하고 marketplace 버전은 유지되어 `cwf:update` 체감과 릴리스 메타데이터가 어긋날 수 있는 상태가 생겼다.
- **Takeaway**: 배포 전에는 `plugin-deploy` 또는 동등한 consistency 체크를 필수 게이트로 실행해야 한다.

When 릴리스 버전을 변경하면 -> `bash .claude/skills/plugin-deploy/scripts/check-consistency.sh cwf` 결과 `gap_count: 0`을 확인한다.

## Iteration 3 Lesson — Guard Fail-Closed for Missing session_id (2026-02-20)

- **Expected**: `session_id`가 비어도 compact guard가 session-map/live 정보를 활용해 우회 없이 동작한다.
- **Actual**: `track-user-input --guard-only`가 `session_id` 공백에서 조기 종료되어 worktree mismatch block을 놓쳤다.
- **Takeaway**: guard 모드에서는 `session_id`가 없어도 최소한 `session-map`/`live.worktree_root`를 근거로 fail-closed 판단을 해야 한다.

When guard-only 입력에서 `session_id`가 비어 있으면 -> 즉시 통과하지 말고 `session-map` 존재 여부와 live worktree mismatch를 확인해 block 여부를 결정한다.

## Iteration 3 Lesson — Retro Light Deterministic Fast-Path (2026-02-20)

- **Expected**: `cwf:retro --light`가 non-interactive에서도 짧은 시간 내 종료하고 `retro.md`를 남긴다.
- **Actual**: 직접 실행은 timeout이 지속되었지만, deterministic script 경로(`retro-light-fastpath.sh`)는 즉시 `retro.md`를 생성하고 gate를 통과했다.
- **Takeaway**: long-context 분석형 스킬에는 non-interactive fallback 스크립트를 먼저 실행하는 경로를 항상 마련해야 한다.

When `--light` 모드가 non-interactive timeout을 반복하면 -> 분석 단계 전 deterministic fast-path 스크립트로 `retro.md`를 먼저 생성하고 gate를 통과시킨다.

## Iteration 3 Lesson — Setup Non-Interactive Fail-Fast Output (2026-02-20)

- **Expected**: `cwf:setup` 계열은 non-interactive에서도 최소한 분기 이유(`WAIT_INPUT`)를 명시하고 종료한다.
- **Actual**: `cwf:setup` full에서 빈 출력 종료(`NO_OUTPUT`)가 간헐적으로 발생해 원인 추적이 어려웠다.
- **Takeaway**: setup 스킬은 AskUserQuestion 불가 시 phase-id 포함 표준 `WAIT_INPUT` 포맷을 강제해 분류/운영 가시성을 확보해야 한다.

When setup run ends non-interactively with `exit 0` -> require explicit `WAIT_INPUT: setup requires user selection at phase <id>` output and `Please reply with your choice.` trailer.

### 보강 메모

- direct 재실행에서는 `WAIT_INPUT`이 나와도, smoke spot-check에서 `setup-full`이 간헐적으로 `NO_OUTPUT`로 재발할 수 있다.
- 다음 iteration에서는 `setup-full` 경로의 첫 출력 보장(최소 1줄 상태 라인) 여부를 deterministic check로 추가 검토한다.
