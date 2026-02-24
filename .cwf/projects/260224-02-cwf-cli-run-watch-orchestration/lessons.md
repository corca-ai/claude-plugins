# Lessons — cwf-cli-run-watch-orchestration

- Initialized by `next-prompt-dir --bootstrap`
- Add concrete learnings during planning and implementation

### cwf:review 실행 경로 편차

- **Expected**: `claude -p`로 `cwf:review --mode plan`을 직접 호출해 리뷰 산출물을 생성한다.
- **Actual**: 플러그인 로드 경로에서 리뷰 호출이 장시간 대기 상태에 머물러 산출물이 생성되지 않아, `cwf:review` 계약(6슬롯 병렬 리뷰 + synthesis 파일 생성)을 수동 오케스트레이션으로 대체했다.
- **Takeaway**: CI/로컬에서 `cwf:review` 비대화형 호출의 안정 경로(입력 방식, timeout, provider fallback)를 먼저 표준화한 뒤 자동화에 연결해야 한다.

When `cwf:review` non-interactive 호출이 무응답 상태로 지속되면 → 6슬롯 병렬 리뷰 fallback을 수행하고 편차를 `lessons.md`에 기록한다.
