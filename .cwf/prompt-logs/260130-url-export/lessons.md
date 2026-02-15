# Lessons

### Plan mode 프로토콜 미준수

- **Expected**: CLAUDE.md에 Plan & Lessons Protocol이 명시되어 있으므로, non-trivial 구현 작업 시 plan mode로 진입하여 plan.md/lessons.md를 먼저 생성해야 한다.
- **Actual**: 사용자가 plan mode 진입을 명시적으로 요청하지 않았다는 이유로 바로 구현에 들어갔다.
- **Takeaway**: CLAUDE.md에 적힌 프로토콜은 사용자가 명시적으로 요청하지 않아도 스스로 따라야 한다. `EnterPlanMode` 도구를 적극적으로 사용할 것.

When non-trivial 구현 작업을 시작할 때 → CLAUDE.md에 plan mode 프로토콜이 있으면 `EnterPlanMode`를 먼저 호출한다.

### 사후 plan/lessons 작성

- **Expected**: plan.md는 구현 전에, lessons.md는 세션 중 점진적으로 작성한다.
- **Actual**: 구현 완료 후 사용자 피드백을 받고서야 사후적으로 작성했다.
- **Takeaway**: 사후 작성은 없는 것보다 낫지만, 프로토콜의 본래 의도(구현 전 계획 검증, 실시간 학습 기록)를 달성하지 못한다.

### plan.md 작성 언어

- **Expected**: plan.md는 에이전트를 위한 문서이므로 영어로 작성해야 한다 (CLAUDE.md Language 규칙 참조).
- **Actual**: 한국어로 작성했다. lessons.md는 사용자를 위한 문서이므로 한국어가 맞지만, plan.md는 다르다.
- **Takeaway**: plan.md = 에이전트용 → 영어. lessons.md = 사용자용 → 사용자 언어(한국어). retro.md = 사용자용 → 사용자 언어(한국어).

When plan.md를 작성할 때 → 영어로 작성한다 (에이전트가 주 독자).

### prompt-logs 디렉토리 혼동

- **Expected**: 이번 세션의 주제는 "url-export 스킬 생성"이므로 `prompt-logs/260130-url-export/`를 새로 만들어야 한다.
- **Actual**: 스펙 문서(`url-export.md`)가 `prompt-logs/260130-bring-notion2md/`에 있었기 때문에 그 디렉토리에 plan.md/lessons.md/retro.md를 넣었다.
- **Takeaway**: 입력 문서의 위치와 세션 아티팩트의 위치는 별개다. `{title}`은 항상 현재 세션의 주제를 반영해야 한다.

When prompt-logs 디렉토리를 결정할 때 → 참조 문서의 위치가 아니라 현재 세션의 주제로 `{title}`을 정한다.
