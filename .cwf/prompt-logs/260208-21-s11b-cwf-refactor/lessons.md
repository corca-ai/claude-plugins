# Lessons — S11b: Migrate refactor → cwf:refactor

## Session Learnings

1. **check-session.sh FAIL 선별적 무시 금지**: FAIL이 나면 가능한 항목부터 해결. "세션 진행 중"은 retro.md에만 적용 가능. next-session.md는 구현 직후 작성 가능.

2. **"next" = 핸드오프 완성까지**: 유저가 "next"라고 하면 master plan에서 다음 세션을 확인하고, next-session.md를 작성하고, 그 내용을 보고하는 것까지가 범위.

3. **에이전트 수는 작업의 자연 경계에 맞출 것**: 숫자를 먼저 정하고 작업을 나누면 불균형. Deep Review는 structural(1–5) + quality(6–8)로 자연스러운 2분할, Holistic은 3차원으로 자연스러운 3분할.

4. **S7–S11b 마이그레이션 패턴 완전 안정화**: frontmatter(Triggers, Task first), verbatim copy + diff 검증, Rules 섹션, agent-patterns.md 참조 — 7회 반복으로 패턴 확립됨.

5. **구조적 해결 > 행동 규칙**: "다음엔 FAIL을 무시하지 말자"는 실패함. check-session.sh에 `--impl` 플래그를 추가하여 retro.md 없이도 next-session.md 누락을 명확히 잡도록 구조 변경. `project-context.md`의 "deterministic validation over behavioral instruction" 원칙 적용.
