# Iteration 1 Retro

## 목표 대비

- 달성
  - 신규 사용자 관점 시나리오 전수 검토(설치/setup/스킬/hook/run)
  - blocker/timeout 경로 문서화
  - 개선 스크립트 2종 + 테스트 + 가이드 반영
- 미달성
  - `cwf:plan`/`cwf:retro`를 non-interactive로 안정 종료하지 못함
  - CI release gate 강제 연동은 보류

## 잘된 점

1. 설치 blocker와 non-interactive timeout을 재현 가능한 아티팩트로 고정했다.
2. 수동 판단 의존도를 줄이는 스크립트형 검증 루틴을 확보했다.
3. 스모크 스크립트 자체 결함(prompt 인자 순서)을 같은 세션에서 발견/수정했다.

## 문제점

1. non-interactive 환경에서 다수 스킬이 사용자 선택 대기 상태에 빠진다.
2. 샌드박스에 설치된 스킬 인벤토리가 비어 refactor 효과 검증이 제한됐다.
3. 외부 교차검증(gemini) 가용성 변동이 커 회귀 파이프라인 신뢰도가 낮다.

## 레슨 (persist)

1. CLI 기반 smoke 도구는 "명령 성공 여부"뿐 아니라 "대기 상태(timeout)"를 1급 신호로 분리해야 한다.
2. `claude --print`는 옵션/프롬프트 인자 순서에 민감하므로 래퍼 스크립트에 고정 규칙을 둬야 한다.
3. 미배포 상태에서는 "지금 가능한 검증"과 "머지 후 가능한 게이트"를 문서에서 분리해 의사결정을 줄여야 한다.

## Iteration 2 액션

1. [scripts/noninteractive-skill-smoke.sh](../../scripts/noninteractive-skill-smoke.sh)에 `--include-local-skills` 대응 케이스 세트 추가
2. CI에 `check-marketplace-entry` + smoke job 연결(실패 시 릴리스 차단)
3. `retro`/`run` timeout 원인 추적용 provenance 수집 포인트 추가
