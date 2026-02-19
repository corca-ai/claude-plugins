# Lessons: `/retro` Skill

## 핑퐁에서 배운 것

### Plan & Lessons Protocol은 시스템 plan mode와 별개로 실행해야 한다

- **예상**: EnterPlanMode 도구를 호출하면 Plan & Lessons Protocol도 자동으로 따를 것
- **실제**: 시스템의 plan mode는 자체 plan file 경로(`~/.claude/plans/...`)를 지정하고, Claude는 그 경로에만 plan을 작성함. CLAUDE.md에 있는 프로젝트 프로토콜(`prompt-logs/` 디렉토리 생성, plan.md, lessons.md)은 별도로 수행하지 않음
- **시사점**: 시스템 지시와 프로젝트 지시가 같은 관심사(plan)를 다르게 다룰 때, 프로젝트 지시를 놓칠 수 있다. CLAUDE.md의 Plan Mode 섹션이 이 충돌을 더 명시적으로 다뤄야 할 수 있음

시스템 plan file에 쓰는 것과 `prompt-logs/` 프로토콜을 따르는 것 → 둘 다 해야 함

### Language 지시는 별도 섹션으로 분리해야 눈에 띈다

- **예상**: step 4 안에 "Write in the user's language." 한 줄이면 충분할 것
- **실제**: 유저가 이 지시가 충분한지 의문을 제기함. workflow step에 묻혀 있으면 놓치기 쉬움
- **시사점**: `plan-and-lessons.md`가 이미 별도 `### Language` 섹션 패턴을 쓰고 있음. 같은 패턴을 따르는 게 신뢰성이 높다

중요한 지시는 workflow step에 끼우지 말고 → 별도 섹션으로 분리

### Retro의 산출물은 retro.md만이 아니다

- **예상**: retro.md를 쓰고 CLAUDE.md 업데이트를 제안하면 완료
- **실제**: 유저는 Section 1(Context)을 별도 영속 문서에, Section 2(Collaboration Style)를 CLAUDE.md에 반영하길 원함. retro.md는 세션별 기록이고, 진짜 가치는 프로젝트 레벨 문서에 영속화하는 것
- **시사점**: 스킬의 Step 5를 "Offer CLAUDE.md Updates"에서 "Persist Findings"로 확장해야 함

세션별 산출물(retro.md) 작성 후 → 프로젝트 레벨 영속화(context doc, CLAUDE.md)를 별도 단계로
