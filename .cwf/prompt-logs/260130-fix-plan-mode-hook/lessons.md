# Lessons

### prompt 타입 hook은 컨텍스트 주입이 아니다

- **Expected**: `type: "prompt"` hook이 assistant에게 텍스트를 주입할 것
- **Actual**: prompt 타입은 별도 LLM(Haiku)에 보내서 ok/block 판단만 함. 컨텍스트 주입 아님
- **Takeaway**: 컨텍스트 주입이 목적이면 `type: "command"` + `additionalContext` JSON 출력 사용

When hook으로 assistant에 지시를 주입하고 싶을 때 → `type: "command"` + `hookSpecificOutput.additionalContext` JSON

### /plan은 EnterPlanMode 도구를 호출하지 않는다

- **Expected**: `/plan`이나 Shift+Tab이 `EnterPlanMode` 도구를 트리거할 것
- **Actual**: 사용자 직접 진입은 CLI 모드 토글이라 도구 호출 없음. `UserPromptSubmit`도 트리거되지 않음
- **Takeaway**: `PreToolUse` → `EnterPlanMode` hook은 assistant 자발적 진입만 커버. 사용자 진입은 CLAUDE.md에 의존

### Explore 에이전트 범위 제어

- **Expected**: hook 설정 파일 구조만 파악하면 충분
- **Actual**: "hook 설정을 찾아라" 지시에 에이전트가 관련 스크립트 내용(~400줄)까지 전부 읽음
- **Takeaway**: Explore 에이전트에 "구조만 확인, 내용은 읽지 마라" 같은 범위 제한을 명시해야 토큰 절약 가능

When Explore 에이전트 호출 시 → 읽기 범위를 명시적으로 제한 (파일 목록만 vs 내용까지)

### 개밥먹기 세션의 plan-and-lessons 프로토콜 적용

- **Expected**: 프로토콜대로 plan mode 진입 시 즉시 plan.md 생성
- **Actual**: hook 테스트가 목적이라 plan mode를 여러 번 왔다갔다하면서 프로토콜 적용이 애매해짐
- **Takeaway**: 탐색/디버깅 세션에서는 프로토콜을 사후적으로 기록하는 것도 허용 가능

### 공식 문서 확인의 중요성

- **Expected**: hook 동작을 추측으로 이해 가능
- **Actual**: 공식 문서(code.claude.com/docs/en/hooks) 확인 후 `prompt` 타입의 실제 동작을 정확히 파악
- **Takeaway**: Claude Code 기능은 반드시 공식 문서로 검증. 추측이나 claude-code-guide 에이전트만으로는 불충분
