# Iteration 1 구현 리뷰

## 구현 대상

- [scripts/check-marketplace-entry.sh](../../scripts/check-marketplace-entry.sh)
- [scripts/noninteractive-skill-smoke.sh](../../scripts/noninteractive-skill-smoke.sh)
- [scripts/tests/check-marketplace-entry-fixtures.sh](../../scripts/tests/check-marketplace-entry-fixtures.sh)
- [scripts/tests/noninteractive-skill-smoke-fixtures.sh](../../scripts/tests/noninteractive-skill-smoke-fixtures.sh)
- [docs/plugin-dev-cheatsheet.md](../../docs/plugin-dev-cheatsheet.md)

## 리뷰 기준 대비 결과

1. 조회 실패와 엔트리 누락 분리: 적용 완료
2. non-interactive smoke 정량 요약(`PASS|FAIL|TIMEOUT`): 적용 완료
3. 반복 검증 자동화(픽스처 테스트): 적용 완료
4. 릴리스 파이프라인 강제 연동: 미적용(메인 머지 후 이관)

## 실행 검증

### A. 픽스처 테스트

- 명령: `bash scripts/tests/check-marketplace-entry-fixtures.sh`
- 결과: PASS 12 / FAIL 0
- 확인 포인트:
  - FOUND(0), MISSING_ENTRY(4), INVALID_MARKETPLACE(3), LOOKUP_FAILED(2) 분기 검증

- 명령: `bash scripts/tests/noninteractive-skill-smoke-fixtures.sh`
- 결과: PASS 6 / FAIL 0
- 확인 포인트:
  - threshold 허용 시 gate pass
  - strict threshold 시 gate fail
  - `summary.tsv`에 `PASS|FAIL|TIMEOUT` 모두 기록

### B. 실제 레포 실행

- 명령: `bash scripts/check-marketplace-entry.sh --source . --plugin cwf --json`
- 결과: `FOUND` (exit 0)
- 로그: 터미널 출력(JSON)

- 명령: `bash scripts/noninteractive-skill-smoke.sh --plugin-dir plugins/cwf --workdir project/iter1/sandbox/user-repo-b --timeout 20 --max-failures 99 --max-timeouts 99 --output-dir project/iter1/artifacts/skill-smoke-260219-104649`
- 결과 요약: pass 2 / fail 0 / timeout 12
- 아티팩트: [project/iter1/artifacts/skill-smoke-260219-104649/summary.tsv](artifacts/skill-smoke-260219-104649/summary.tsv)

## 구현 중 수정된 결함

- 결함: `noninteractive-skill-smoke.sh`에서 Claude CLI `--print` prompt 인자 순서가 맞지 않아 전 케이스 즉시 실패
- 조치: prompt를 `--print "<prompt>"` 위치로 이동
- 검증: 픽스처 테스트 재통과 + 실제 스모크 실행에서 timeout/pass 분기 정상 관측

## 잔여 리스크

1. `retro`, `run`, `update` 등 장기 체인 스킬은 non-interactive에서 여전히 timeout 비율이 높다.
2. smoke 결과를 릴리스 차단 게이트로 강제하는 CI 연동은 아직 없다.

## 결론

- 이번 세션 범위의 구현/검증은 완료.
- 메인 머지 후 CI 게이트 연동을 붙이면 릴리스 전 자동 차단 체계가 완성된다.
