# Retro: Plan Mode Hook 수정

> Session date: 2026-01-30

## 1. Context Worth Remembering

- 이 프로젝트(claude-plugins)는 Claude Code 플러그인/스킬/hook 생태계를 관리하는 저장소
- 사용자는 자신이 만든 도구를 직접 사용하는 개밥먹기(dogfooding) 방식으로 개발 중
- Claude Code hook 시스템의 핵심 구분:
  - `type: "prompt"` → 별도 LLM(Haiku)에 보내 ok/block 판단. 컨텍스트 주입 아님
  - `type: "command"` + `hookSpecificOutput.additionalContext` → assistant 컨텍스트에 텍스트 주입
- `/plan`, Shift+Tab은 CLI 내장 모드 토글로, `EnterPlanMode` 도구를 호출하지 않음. 따라서 `PreToolUse` hook 대상이 아님
- `UserPromptSubmit` hook도 `/plan`에 트리거되지 않음 (프롬프트 제출이 아닌 모드 토글이므로)

## 2. Collaboration Preferences

- **점진적 검증 선호**: hook 작동 여부를 테스트 마커(`HOOK_TEST_MARKER_7X9Q`)로 단계별 확인. "assistant 진입부터 확인하고, 그 다음 사용자 진입 테스트"라는 순서를 직접 제안
- **원인 이해 중시**: 단순히 "고쳤다"가 아니라 "왜 안 됐는지"를 알고 싶어함. `prompt` 타입이 왜 작동하지 않는지 공식 문서 근거를 요구
- **간결한 정리 선호**: plan mode를 여러 번 왔다갔다한 뒤 "플랜 모드 없이 그냥 정리해 주세요"라고 요청. 불필요한 형식보다 실용적 결과 우선
- **비용 의식**: Explore 에이전트의 토큰 사용량을 직접 관찰하고 "개선 가능한 신호"로 인식

### Suggested CLAUDE.md Updates

- Collaboration Style에 추가: `When testing hooks or infrastructure, verify incrementally — test one path first, then expand to others.`

## 3. Prompting Habits

**잘 된 점**:
- "plan mode에 들어가면 현재 설정된 hook이 잘 작동하는지 테스트하고 싶습니다" — 명확한 목표 설정
- "스스로 진입했을 때 보이는지부터 확인하고 싶습니다. 그래야 복제 후에도 테스트하니까요" — 테스트 범위를 좁히는 좋은 판단

**개선 가능한 점**:
- 초기 Explore 에이전트 호출 시 "hook 설정을 찾아라"가 너무 넓었음. 사용자도 인정한 부분. 대안: "`.claude/settings.json`의 hooks 섹션 구조를 확인하라. 스크립트 내용은 읽지 마라"
- 이건 사용자의 프롬프트가 아니라 assistant(제)의 Explore 에이전트 프롬프트 문제. 하지만 사용자가 직접 에이전트를 호출할 때도 동일한 원칙 적용 가능: **탐색 범위를 "무엇을 읽을지"가 아니라 "무엇을 읽지 말지"로 제한**

## 4. Learning Resources

- [Claude Code Hooks Reference (공식 문서)](https://code.claude.com/docs/en/hooks) — `prompt` vs `command` 타입, `additionalContext` 등 hook 시스템 전체 레퍼런스
- [Get Started with Claude Code Hooks (공식 가이드)](https://code.claude.com/docs/en/hooks-guide) — 실용적 예제 중심의 hook 입문 가이드
- [awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) — 커뮤니티가 관리하는 스킬, hook, 플러그인 모음. hook 패턴 참고용
- [Claude Code Best Practices (Anthropic)](https://www.anthropic.com/engineering/claude-code-best-practices) — Anthropic 공식 베스트 프랙티스. hook을 "deterministic must-do rules"로 정의하는 관점 참고

## 5. Relevant Skills

이번 세션에서 명확한 스킬 갭은 발견되지 않았음. hook 테스트는 본질적으로 일회성 디버깅 작업이라 반복 가능한 스킬로 만들 필요성이 낮음.

다만, 향후 hook이 많아지면 "hook 동작 검증"을 자동화하는 스킬이 유용할 수 있음:
- 설정된 모든 hook을 나열하고 각각의 트리거 조건과 예상 동작을 요약
- 테스트 마커를 자동 삽입/제거하는 워크플로우

필요 시 `skill-creator`로 제작 가능.
