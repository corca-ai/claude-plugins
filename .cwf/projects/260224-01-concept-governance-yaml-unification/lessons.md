# Lessons — concept-governance-yaml-unification

### setup readiness 선행 검증

- **Expected**: `cwf:run`을 바로 시작할 수 있다.
- **Actual**: `.cwf/setup-contract.yaml` 누락으로 readiness 게이트에서 즉시 중단되었다.
- **Takeaway**: run 시작 전에 `check-setup-readiness.sh --summary`를 먼저 실행해 필수 계약 파일 존재를 확정해야 한다.

When `cwf:run` starts -> 먼저 setup readiness를 검사하고 누락을 즉시 보완한다.

### 이전 세션 초안 재사용 방식

- **Expected**: 기존 `plan.md`를 그대로 실행 입력으로 사용한다.
- **Actual**: 이전 세션 초안으로 보존하기 위해 `initial-plan.md`로 리네임하고, 현재 세션 실행계약용 `plan.md`를 재작성하는 방식이 더 명확했다.
- **Takeaway**: 과거 초안과 현재 실행계약을 분리하면 추적성과 리뷰 품질이 올라간다.

When previous-session draft is reused -> `initial-plan.md`와 현재 `plan.md`를 분리 유지한다.

### 계획 수립 시 evidence-first 적용

- **Expected**: 초기 계획 문서를 그대로 확장하면 충분하다.
- **Actual**: 실제 코드베이스 조사 결과(JSON 파서 결합, expert_roster 결합, concept gate 부재) 때문에 단계/커밋 경계를 다시 설계해야 했다.
- **Takeaway**: 큰 구조 마이그레이션은 `gather -> clarify` 근거를 반영해 단계 경계를 재정의해야 실행 리스크가 줄어든다.

When migration scope is structural -> 계획 단계에서 hotspot 스크립트와 게이트 의존성을 먼저 분해한다.


## Run Gate Violation — 2026-02-24T00:36:38Z
- **Owner**: `plugin`
- **Apply Layer**: `upstream`
- **Promotion Target**: `plugins/cwf/scripts/check-run-gate-artifacts.sh`
- **Due Release**: `next-release`
- Gate checker: `plugins/cwf/scripts/check-run-gate-artifacts.sh`
- Persistence gate: `HARD_FAIL`
- Recorded failures:
  - [review-code] synthesis missing required pattern: session_log_present: 
  - [review-code] synthesis missing required pattern: session_log_lines: 
  - [review-code] synthesis missing required pattern: session_log_turns: 
  - [review-code] synthesis missing required pattern: session_log_last_turn: 
  - [review-code] synthesis missing required pattern: session_log_cross_check: 
