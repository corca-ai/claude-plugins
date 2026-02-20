# Lessons — minimal-smoke-plan

### 적응적 크기 판단 게이트

- **Expected**: 모든 plan 세션에서 리서치 에이전트 2개를 실행
- **Actual**: 파일 2개뿐인 샌드박스 리포에서는 리서치가 불필요
- **Takeaway**: Adaptive sizing gate가 Phase 2를 건너뛸 수 있는 건 의도된 동작 — 사소한 리포에서 에이전트를 돌리는 것은 낭비

When 리포가 파일 2개 이하이고 작업이 자명할 때 → Phase 2 전체를 건너뛴다

## Run Gate Violation — 2026-02-19T06:21:59Z
- Gate checker: `plugins/cwf/scripts/check-run-gate-artifacts.sh`
- Persistence gate: `HARD_FAIL`
- Recorded failures:
  - [retro] retro.md missing '- Mode:' declaration
