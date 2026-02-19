# Lessons — full-skill-refactor-run

## 현재까지 확정된 운영 원칙
- 이번 세션은 `cwf:run` 단계 순서를 유지하고, 중간 산출물을 모두 세션 디렉토리에 파일로 남긴다.
- 외부 리뷰어 슬롯은 Gemini를 제외하고 `codex`/`claude`만 사용한다.
- `refactor` 단계에서는 `--holistic` 1회 + 전 스킬 `--skill <name>` 개별 실행을 모두 수행한다.

## 보류된 의사결정 부채
- D1: run/review gate 소유권 단일화
- D4: context-recovery 공용 manifest/helper
- D5: plan→handoff 자동 신호

## 진행 중 주의사항
- 결정적 gate를 우회하지 않는다.
- 사용자 생성 파일은 삭제하지 않는다.
- 리팩토링 범위가 계획과 달라질 경우 즉시 기록하고 사용자 결정을 먼저 받는다.
