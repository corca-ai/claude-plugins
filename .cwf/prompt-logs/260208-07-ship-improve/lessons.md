# Lessons — S4.5: /ship Skill Improvement

## Implementation Learnings

- **Local skill은 deploy 불필요**: `.claude/skills/ship/`은 marketplace plugin이 아니므로 버전 관리, marketplace.json 동기화, `update-all.sh` 실행 등이 필요 없음. 변경 즉시 다음 세션에 반영됨.
- **템플릿 변수 일관성 검증**: 3-file 구조 (SKILL.md ↔ pr-template.md ↔ issue-template.md)에서 변수명 불일치가 발생하기 쉬움. 변경 후 Explore agent로 교차 검증하는 패턴이 효과적이었음.
- **MD058 blank-around-tables**: markdownlint가 테이블 전후 빈 줄을 요구함. 특히 indented context (리스트 안의 테이블)에서 놓치기 쉬움.

## Takeaways

- retro는 구현 완료 후 유저 요청 없이 자율 실행되어야 함 — CLAUDE.md 문구 강화 필요
- CWF 설계에서 post-implementation 자동화 (retro → commit → push → deploy) 를 스킬 레벨로 통합하는 방향 고려
