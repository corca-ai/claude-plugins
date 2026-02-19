# Retro: WebSearch → /web-search Auto-Redirect Hook

> Session date: 2026-02-03

## 1. Context Worth Remembering

- **플러그인 간 도구 라우팅 문제**: built-in tool(WebSearch)과 커스텀 skill(/web-search)이 기능적으로 겹칠 때, Claude는 native tool을 선호하는 경향이 있음. `allowed-tools`는 프롬프트 텍스트일 뿐 시스템 레벨 enforcement가 아님.
- **PreToolUse hook의 `permissionDecision: "deny"` 패턴**: 도구 호출을 차단하고 deny reason으로 대안을 안내하면, Claude가 대안 경로로 재시도함. 공식 문서에서 확인된 패턴.
- **플러그인 자체 hook 번들링**: hook을 `~/.claude/settings.json`이 아닌 플러그인 내부 `hooks/hooks.json`에 배치하면, 플러그인 설치/제거에 따라 자동으로 활성화/비활성화됨. 설정 관리 부담 없음.

## 2. Collaboration Preferences

- 유저는 문제를 먼저 분석적으로 접근하고, 구현 방향을 함께 설계한 후 실행하는 흐름을 선호함. 이번 세션에서도 "이유를 분석하고 싶다" → 설계 논의 → plan mode → 구현 순서로 진행.
- 유저가 "다른 플러그인에서도 유사한 방법으로 변경 가능한지 검토해주세요"처럼 범위를 확장할 때, 단순히 코드만 검토하지 않고 적용 가능/불가 판단 근거까지 표로 정리하는 것이 효과적이었음.
- 유저는 핵심 설계 아이디어를 직접 제시함 ("web-search 플러그인에 hook이 같이 들어있게 하는 형식도 가능하려나요?"). 에이전트가 제시한 선택지 외의 방향을 열어두는 것이 중요.

### Suggested CLAUDE.md Updates

- **Collaboration Style** 항목에 다음 추가 고려:
  - `When a custom skill overlaps with a built-in tool, the web-search plugin now enforces this automatically via PreToolUse hook. No manual preference needed when the plugin is installed.`
  - 기존 35번째 줄 ("prefer the custom skill") 문구는 web-search에 대해서는 hook이 자동 처리하므로, gather-context 등 아직 hook이 없는 경우에만 해당됨을 명확히 할 수 있음.

## 3. Prompting Habits

- 이번 세션에서 유저의 프롬프팅은 명확하고 효율적이었음. 특별히 개선이 필요한 패턴 없음.
- 한 가지 관찰: "retro 하고 커밋해주세요"처럼 두 작업을 한 문장으로 요청하는 패턴은 잘 작동함. 순차적 의존성이 명확한 경우 이렇게 묶는 것이 효율적.

## 4. Learning Resources

- [Claude Code Hooks Reference](https://docs.anthropic.com/en/docs/claude-code/hooks) — 공식 문서. `permissionDecision`, exit code 2, matcher 패턴 등 hook의 모든 입출력 스펙이 정리되어 있음.
- [Beyond Function Calling: Claude Code's Plugin Architecture](https://thamizhelango.medium.com/beyond-function-calling-how-claude-codes-plugin-architecture-is-redefining-ai-development-tools-67ccec9b5954) — 플러그인 아키텍처의 설계 철학과 hook 이벤트 시스템 개요.
- [Intercept and control agent behavior with hooks (Agent SDK)](https://platform.claude.com/docs/en/agent-sdk/hooks) — Agent SDK에서의 hook 구현 패턴. `permissionDecision: "deny"` 패턴의 Python 구현 예시.
- [Configure Claude Code hooks to automate your workflow](https://www.gend.co/blog/configure-claude-code-hooks-automation) — PreToolUse hook 실전 예시. exit code 2와 JSON decision control의 차이점 설명.

## 5. Relevant Skills

이번 세션에서 skill gap은 발견되지 않았음. web-search, retro, plan-and-lessons 모두 정상적으로 활용됨. 특히 web-search가 retro 내부에서 호출되는 구조가 이번 hook 추가로 자동화됨.
