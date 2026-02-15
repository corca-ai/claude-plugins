### Plan & Lessons 프로토콜 미이행

- **Expected**: plan mode 진입 시 CLAUDE.md의 지시에 따라 `prompt-logs/{YYMMDD}-{title}/plan.md`와 `lessons.md`를 생성해야 함
- **Actual**: 시스템 plan 파일(`~/.claude/plans/`)에만 계획을 작성하고, prompt-logs 디렉토리에는 아무것도 생성하지 않음
- **Takeaway**: CLAUDE.md에 "This is separate from the system plan file"이라고 명시되어 있음. 시스템 plan 파일과 프로젝트의 plan-and-lessons 프로토콜은 별개이며, plan mode 진입 시 양쪽 모두 수행해야 함

When plan mode에 진입할 때 → 시스템 plan 파일 작성과 별도로, CLAUDE.md의 Plan & Lessons Protocol에 따라 `prompt-logs/` 디렉토리에 plan.md + lessons.md를 반드시 생성할 것

### PostToolUse hook의 echo는 모델에 전달되지 않음

- **Expected**: `.claude/hooks.json`의 PostToolUse hook에서 `echo`로 출력한 메시지가 모델 컨텍스트에 주입되어 에이전트가 지시를 따를 것
- **Actual**: PostToolUse hook의 단순 echo(exit 0)는 verbose mode에서 사용자에게만 보임. 모델 컨텍스트에는 전달되지 않음
- **Takeaway**: PostToolUse hook에서 모델이 읽게 하려면 JSON 형식으로 `{"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": "..."}}` 를 stdout에 출력해야 함. `UserPromptSubmit`과 `SessionStart`만 plain text stdout이 자동으로 컨텍스트에 추가됨

When PostToolUse hook으로 모델에 지시를 전달할 때 → 단순 echo가 아닌 JSON additionalContext 형식을 사용할 것

### Hook 설정의 올바른 위치와 방식

- **Expected**: `.claude/hooks.json`에 hook을 설정하면 프로젝트 hook으로 동작할 것
- **Actual**: `.claude/hooks.json`은 **플러그인 전용** 형식. 프로젝트 hook은 `.claude/settings.json`의 `"hooks"` 키 안에 설정해야 함. hooks.json에 넣은 hook은 아예 로드되지 않았음
- **Takeaway**: 프로젝트 hook → `.claude/settings.json` (커밋) 또는 `.claude/settings.local.json` (로컬). `type: prompt`를 사용하면 Haiku가 컨텍스트를 평가하고 `{"ok": false, "reason": "..."}` 형태로 Claude에게 자동 피드백. JSON echo 포맷을 직접 구성할 필요 없음

When 프로젝트 hook을 설정할 때 → `.claude/settings.json`에 설정하고, 단순 알림이면 `type: prompt` 사용을 우선 고려할 것

### claude-code-guide 에이전트의 정보를 검증 없이 신뢰

- **Expected**: 에이전트가 정확한 정보를 제공할 것
- **Actual**: "type: prompt는 Stop과 SubagentStop만 지원"이라고 했지만 실제로는 모든 hook event에서 사용 가능. hooks.json 위치도 부정확
- **Takeaway**: 에이전트 응답은 2차 출처. 중요한 기술적 사실은 WebFetch로 공식 문서를 직접 확인해야 함

When 에이전트가 기술적 제약 사항을 알려줄 때 → 공식 문서(1차 출처)로 반드시 교차 검증할 것
