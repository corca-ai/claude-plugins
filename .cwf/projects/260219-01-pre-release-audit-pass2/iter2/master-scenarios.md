# Iteration 2 마스터 시나리오

## 목적

`main` 머지 이후(71684a9) 기준으로 설치 경로 복구 여부와 non-interactive 체인 안정성을 재검증한다.

## 진행 규칙

- 시나리오별 기록은 [.cwf/projects/260219-01-pre-release-audit-pass2/iter2/scenarios](scenarios) 하위 파일에 남긴다.
- 의도와 다르게 동작하는 경로는 즉시 중단하고 증거 로그만 남긴다.
- Iteration 1에서 이미 충분히 검증된 hook 세부 분기는 gate 스크립트 결과로 대체 검증한다.

## 공통 환경

- 실행 브랜치: `iter2/260219-01-pre-release-audit-pass2`
- 기준 커밋: `71684a9` (`main` == `origin/main`)
- 샌드박스: [.cwf/projects/260219-01-pre-release-audit-pass2/iter2/sandbox](sandbox)

## 시나리오 목록

| ID | 분류 | 목표 | 상태 | 기록 파일 |
|---|---|---|---|---|
| I2-S00 | 준비 | 기준 상태/버전 캡처 | DONE | [.cwf/projects/260219-01-pre-release-audit-pass2/iter2/scenarios/I2-S00.md](scenarios/I2-S00.md) |
| I2-S01 | 설치 | marketplace 재등록 + project scope 설치 재검증 | PASS | [.cwf/projects/260219-01-pre-release-audit-pass2/iter2/scenarios/I2-S01.md](scenarios/I2-S01.md) |
| I2-S03 | 설치 | local scope 설치 분기 재검증 | PASS | [.cwf/projects/260219-01-pre-release-audit-pass2/iter2/scenarios/I2-S03.md](scenarios/I2-S03.md) |
| I2-S10 | setup/full | `cwf:setup` full non-interactive 동작 확인 | PARTIAL(WAIT_INPUT) | [.cwf/projects/260219-01-pre-release-audit-pass2/iter2/scenarios/I2-S10.md](scenarios/I2-S10.md) |
| I2-S15 | setup/env | `cwf:setup --env` 단독 분기 재검증 | FAIL(TIMEOUT) | [.cwf/projects/260219-01-pre-release-audit-pass2/iter2/scenarios/I2-S15.md](scenarios/I2-S15.md) |
| I2-G01 | 게이트 | premerge deterministic gate | PASS | [.cwf/projects/260219-01-pre-release-audit-pass2/iter2/scenarios/I2-G01.md](scenarios/I2-G01.md) |
| I2-G02 | 게이트 | predeploy + public marketplace 확인 | PASS | [.cwf/projects/260219-01-pre-release-audit-pass2/iter2/scenarios/I2-G02.md](scenarios/I2-G02.md) |
| I2-K60 | 스모크 | 14케이스 baseline 스모크(패치 전) | DONE | [.cwf/projects/260219-01-pre-release-audit-pass2/iter2/scenarios/I2-K60.md](scenarios/I2-K60.md) |
| I2-F70 | 개선 | WAIT_INPUT/NO_OUTPUT 분류기 보강 + 픽스처 | PASS | [.cwf/projects/260219-01-pre-release-audit-pass2/iter2/scenarios/I2-F70.md](scenarios/I2-F70.md) |
| I2-K61 | 스모크 | 14케이스 final 스모크 + 최신 분류기 기준 재집계 | DONE | [.cwf/projects/260219-01-pre-release-audit-pass2/iter2/scenarios/I2-K61.md](scenarios/I2-K61.md) |
| I2-K46 | 스모크 | `cwf:retro --light` 단건 확인 | FAIL(TIMEOUT) | [.cwf/projects/260219-01-pre-release-audit-pass2/iter2/scenarios/I2-K46.md](scenarios/I2-K46.md) |
| I2-R60 | run/e2e | `cwf:run` task 포함 단건 실행 | FAIL(TIMEOUT) | [.cwf/projects/260219-01-pre-release-audit-pass2/iter2/scenarios/I2-R60.md](scenarios/I2-R60.md) |
| I2-W20 | worktree/compact | compact 이후 worktree 고정 및 `session_id` 누락 우회 점검 | FAIL(GAP) | [.cwf/projects/260219-01-pre-release-audit-pass2/iter2/scenarios/I2-W20.md](scenarios/I2-W20.md) |

## 진행 로그

- 2026-02-19: main 머지 후 Iteration 2 브랜치 생성(`iter2/260219-01-pre-release-audit-pass2`)
- 2026-02-19: 설치 blocker 해소 재확인(project/local scope PASS)
- 2026-02-19: non-interactive 분류기 `WAIT_INPUT`/`NO_OUTPUT` 강화 및 픽스처 확장
- 2026-02-19: final 스모크/게이트 재실행 및 Iteration 2 문서화 완료
- 2026-02-20: compact 이후 worktree drift 재점검(I2-W20)에서 `session_id` 공백 시 guard 우회 가능성 확인
