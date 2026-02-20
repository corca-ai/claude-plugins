# Iteration 3 마스터 시나리오

## 목적

`main` 최신 기준에서 Iteration 2 잔여 리스크를 재검증하고, non-interactive timeout 원인을 단계 단위로 좁힌다.

## 진행 규칙

- 시나리오별 기록은 [.cwf/projects/260219-01-pre-release-audit-pass2/iter3/scenarios](scenarios) 하위 파일에 남긴다.
- 의도와 다르게 동작하는 경로는 즉시 중단하고 증거 로그만 남긴다.
- deterministic gate(premerge/predeploy)는 매 시작 시점과 주요 코드 변경 직후 재실행한다.

## 공통 환경

- 실행 브랜치: `iter3/260219-01-pre-release-audit-pass2`
- 기준 브랜치: `main`
- 샌드박스: [.cwf/projects/260219-01-pre-release-audit-pass2/iter2/sandbox](../iter2/sandbox)

## 시나리오 목록

| ID | 분류 | 목표 | 상태 | 기록 파일 |
|---|---|---|---|---|
| I3-S00 | 준비 | baseline/게이트 기준 상태 캡처 | DONE | [.cwf/projects/260219-01-pre-release-audit-pass2/iter3/scenarios/I3-S00.md](scenarios/I3-S00.md) |
| I3-G01 | 게이트 | premerge deterministic gate 재검증 | PASS | [.cwf/projects/260219-01-pre-release-audit-pass2/iter3/scenarios/I3-G01.md](scenarios/I3-G01.md) |
| I3-G02 | 게이트 | predeploy + public marketplace(main) 재검증 | PASS | [.cwf/projects/260219-01-pre-release-audit-pass2/iter3/scenarios/I3-G02.md](scenarios/I3-G02.md) |
| I3-K46 | 스모크 | `cwf:retro --light` timeout 재확인 및 출력 관찰 | FAIL(TIMEOUT) | [.cwf/projects/260219-01-pre-release-audit-pass2/iter3/scenarios/I3-K46.md](scenarios/I3-K46.md) |
| I3-R60 | run/e2e | task 포함 `cwf:run` 단건 재검증 | PASS | [.cwf/projects/260219-01-pre-release-audit-pass2/iter3/scenarios/I3-R60.md](scenarios/I3-R60.md) |
| I3-S10 | setup/full | `cwf:setup` full non-interactive 결과 재확인 | PARTIAL(WAIT_INPUT) | [.cwf/projects/260219-01-pre-release-audit-pass2/iter3/scenarios/I3-S10.md](scenarios/I3-S10.md) |
| I3-S15 | setup/env | `cwf:setup --env` non-interactive 결과 재확인 | PARTIAL(WAIT_INPUT) | [.cwf/projects/260219-01-pre-release-audit-pass2/iter3/scenarios/I3-S15.md](scenarios/I3-S15.md) |
| I3-W20 | worktree/compact | `session_id` 공백 guard 우회 가능성 재현 및 보강점 확인 | PASS(FIXED_PRIMARY_GAP) | [.cwf/projects/260219-01-pre-release-audit-pass2/iter3/scenarios/I3-W20.md](scenarios/I3-W20.md) |

## 진행 로그

- 2026-02-20: Iteration 3 브랜치 생성(`iter3/260219-01-pre-release-audit-pass2`)
- 2026-02-20: 시작 게이트(premerge/predeploy main) PASS 재확인
- 2026-02-20: `I3-K46` 재실행 결과 `FAIL(TIMEOUT)` 재현
- 2026-02-20: `I3-R60` 재실행 결과 `PASS` (timeout 없이 명시적 종료)
- 2026-02-20: `I3-S10` 재실행 결과 `PARTIAL(WAIT_INPUT)` (phase 1 선택 대기)
- 2026-02-20: `I3-S15` 재실행 결과 `PARTIAL(WAIT_INPUT)` (timeout 대신 질문형 종료)
- 2026-02-20: setup 2케이스 spot-check에서 `setup-full` `NO_OUTPUT` 1회 재발(변동성 잔여)
- 2026-02-20: `I3-W20` 보강 후 `PASS(FIXED_PRIMARY_GAP)` 전환(`session_id` 공백 + binding 존재 시 fail-closed)
- 2026-02-20: `I3-K46` timeout은 지속되나 light fast-path(`retro-light-fastpath.sh`) + retro gate PASS 경로 확보
