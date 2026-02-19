# Iteration 3 추천안

## 목표

- non-interactive 경계의 안정 종료율을 올리고, `run/retro` timeout 원인을 단계 단위로 좁힌다.

## 우선순위

1. `run/retro` timeout 우선 해소
   - `cwf:run`, `cwf:retro --light`에 최소 provenance flush를 timeout 이전에 강제
   - stage 진입/탈출 로그를 항상 남기도록 fail-safe 경로 추가
2. setup full/env의 non-interactive 정책 명확화
   - 질문 필요 분기는 명시적 `WAIT_INPUT` 응답으로 즉시 종료
   - 자동 선택 가능한 분기는 deterministic default로 닫기
3. smoke 스크립트 정확도 유지
   - 신규 질문형 문구가 생기면 픽스처 먼저 추가
   - `NO_OUTPUT` 발생 케이스는 스킬 측 출력 보장 보완

## 판정 기준

- `predeploy` PASS 유지 (`FOUND`)
- 14케이스 smoke에서 `TIMEOUT` 7 미만
- `run`, `retro` 중 최소 1개는 timeout 없이 명시적 종료(`PASS` 또는 `FAIL/WAIT_INPUT`)로 귀결
