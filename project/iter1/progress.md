# Iteration 1 Progress

## 요약

- 기준 문서: [project/iter1/master-scenarios.md](master-scenarios.md)
- 총 시나리오: 38
- 결과 집계
  - PASS: 18
  - PASS(권한우회 조건): 1
  - PARTIAL: 5
  - PARTIAL(deadlock): 1
  - FAIL(timeout): 8
  - FAIL(deadlock): 1
  - FAIL(BLOCKER): 2
  - SKIP: 1
  - DONE: 1

## 핵심 진전

1. setup 하위 분기 중 env, git-hooks, repo-index, codex sync/wrapper는 재현 및 산출물 확인 완료
2. hooks 시나리오(H30~H37) 전부 PASS
3. skill 트리거 중 plan, refactor, ship, update는 로드/응답 확인
4. cwf:run/hitl/retro 등 체인형 스킬은 non-interactive timeout으로 안정 실행 실패

## 주요 결함(우선순위)

1. 설치 Blocker
   - 증상: claude plugin install cwf@corca-plugins 실패 (Plugin "cwf" not found)
   - 영향: 신규 유저 기본 설치 경로 차단
   - 관련 시나리오: I1-S01, I1-S03
2. non-interactive deadlock/timeout
   - 증상: claude print 경로에서 일부 스킬이 질문 단계 또는 장기 체인에서 종료 불능
   - 영향: headless 자동 점검 어려움
   - 관련 시나리오: I1-S10, I1-S19, I1-K41, I1-K43, I1-K44, I1-K46, I1-K47, I1-K49, I1-K51, I1-R60
3. Gemini 교차검증 불안정
   - 증상: gemini print 다수 케이스에서 model capacity 429 또는 timeout
   - 영향: 외부 교차검증 신뢰도 저하

## 경로 변경(계획 대비)

- 원래 규칙상 설치 실패 시 S10+ 스킵 예정이었으나, 검증 지속을 위해 plugin-dir 우회 경로를 허용해 진행
- 편차는 마스터 규칙 섹션 및 시나리오 문서에 명시

## Iteration 2 우선순위 제안

1. marketplace 설치 blocker 원인 확정(원격 marketplace 인덱스/릴리즈 동기화)
2. headless 지원 정책 결정
   - A: 스킬에서 non-interactive fallback 명시 지원
   - B: interactive-only 공식 선언 후 테스트 하네스 분리
3. cwf:run timeout 원인 분해(stage provenance 강제 기록)

## 개선 사이클 진행(Plan→Review→Impl→Review→Refactor→Retro)

- Plan 대체/리뷰
  - `cwf:plan` non-interactive deadlock으로 수동 계획 문서로 대체
  - 통합 계획: [project/iter1/plan-review.md](plan-review.md)
- 구현
  - 신규 스크립트
    - [scripts/check-marketplace-entry.sh](../../scripts/check-marketplace-entry.sh)
    - [scripts/noninteractive-skill-smoke.sh](../../scripts/noninteractive-skill-smoke.sh)
  - 신규 테스트
    - [scripts/tests/check-marketplace-entry-fixtures.sh](../../scripts/tests/check-marketplace-entry-fixtures.sh)
    - [scripts/tests/noninteractive-skill-smoke-fixtures.sh](../../scripts/tests/noninteractive-skill-smoke-fixtures.sh)
  - 문서 업데이트
    - [docs/plugin-dev-cheatsheet.md](../../docs/plugin-dev-cheatsheet.md)
- 구현 리뷰
  - [project/iter1/implementation-review.md](implementation-review.md)
  - 핵심 결과: 픽스처 테스트 전부 PASS, 실제 smoke(14 케이스) `pass 2 / timeout 12`
- refactor/retro
  - refactor 기록: [project/iter1/refactor.md](refactor.md) (PASS, 단 스캔 대상 0)
  - retro 기록: [project/iter1/retro.md](retro.md) (`cwf:retro` non-interactive timeout 포함)
