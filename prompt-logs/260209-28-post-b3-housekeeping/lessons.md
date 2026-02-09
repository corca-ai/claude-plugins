# Lessons — Post S13.5-B3 Housekeeping

### Hook audit 결과 (Reason 모델 기반 분석, S13.5-B3 retro 권고)

S13.5-B3에서 exit-plan-mode.sh 관찰성 문제를 수정하면서 전체 hook 스크립트에
대한 Reason의 Swiss cheese 모델 기반 감사를 수행.

| Risk | Scripts | Pattern |
|------|---------|---------|
| NONE | exit-plan-mode.sh, enter-plan-mode.sh, redirect-websearch.sh | Always emit JSON — 모든 경로에서 출력 보장 |
| LOW | check-shell/markdown.sh, smart-read.sh, attention.sh, start/cancel-timer.sh, track-user-input.sh | Silent skip on guard conditions — 가드 조건 불충족 시 무시 |
| MEDIUM | log-turn.sh (5 silent exits), heartbeat.sh (4 silent exits) | Async + multiple silent edge cases — 비동기 특성상 여러 무음 경로 |

- **Takeaway**: MEDIUM 리스크 스크립트들은 비동기 + 다중 silent exit 조합.
  당장 수정 불요하나, 향후 로깅 디버깅 시 이 경로들부터 확인할 것.

When silent hook failure 추적 필요 → log-turn.sh, heartbeat.sh 의 early-exit 경로 먼저 확인
