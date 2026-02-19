# Retro: web-search 플러그인 추가 및 hook 디버깅

> Session date: 2026-01-30

## 1. Context Worth Remembering

- 사용자는 개인 작업 환경(`/Users/ted/codes/works/.claude/skills/`)에서 먼저 스킬을 개발하고, 검증 후 corca-plugins 마켓플레이스로 이관하는 워크플로우를 사용함
- Claude Code hooks에 대한 깊은 이해를 보유하고 있으며, 공식 문서를 직접 참조하여 에이전트의 잘못된 정보를 교정함
- hook 설정 시 `.claude/hooks.json`(플러그인 전용)과 `.claude/settings.json`(프로젝트 hook)의 차이를 구분해야 함 — 이 프로젝트에서 실제로 혼동이 발생했음

## 2. Collaboration Preferences

- 사용자는 에이전트가 프로토콜(CLAUDE.md, plan-and-lessons)을 명시적 리마인더 없이 자발적으로 따르기를 기대함 (CLAUDE.md: "The user expects protocols in CLAUDE.md to be followed without explicit reminders")
- 문제가 발생했을 때 단순 수정보다 **근본 원인 분석**을 중시함 — "왜 그랬을까요?", "이걸 왜 당신 스스로는 몰랐을까요?" 같은 질문으로 에이전트의 사고 과정을 점검함
- 에이전트가 2차 출처(claude-code-guide 에이전트)에 의존할 때 이를 지적하고 1차 출처(공식 문서) 확인을 요구함
- plan mode 진입/퇴출을 빠르게 전환하며 테스트하는 것에 거부감이 없음 — 실용적인 검증 우선

### Suggested CLAUDE.md Updates

- `## Collaboration Style` 섹션에 추가: `- When researching Claude Code features (hooks, settings, plugins), always verify against the official docs (https://code.claude.com/docs/en/) via WebFetch. Do not rely solely on claude-code-guide agent responses.`

## 3. Prompting Habits

- 사용자의 프롬프팅은 효과적이었음. 특히 직접 찾은 문서 snippet을 제시하며 방향을 교정하는 패턴이 인상적:
  - `"https://code.claude.com/docs/en/hooks.md 를 보니 settings.json 이 맞는 경로네요. type: prompt 를 쓰면 됩니다. 자세히 읽어보세요."` — URL과 핵심 포인트를 함께 주어 에이전트가 올바른 방향으로 학습하게 함
- 개선 가능한 점: 초기 요청 시 hook 관련 CLAUDE.md snippet을 함께 제공했는데, `.claude/hooks.json`의 현재 상태도 함께 언급했으면 hook 디버깅이 초반에 시작됐을 수 있음. 다만 이는 사용자가 hook 동작 여부 자체를 인지하지 못한 상태였으므로 자연스러운 흐름이었음

## 4. Learning Resources

- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks.md) — 이번 세션에서 직접 참조한 공식 문서. `type: prompt`, `additionalContext`, 설정 파일 위치 등 핵심 정보가 모두 여기 있음
- [Get started with Claude Code hooks](https://code.claude.com/docs/en/hooks-guide) — 실전 예제 중심의 가이드. hooks-guide와 hooks reference를 함께 읽으면 hook 설계에 필요한 전체 그림을 잡을 수 있음
- [claude-code-hooks-mastery (GitHub)](https://github.com/disler/claude-code-hooks-mastery) — hook 패턴 모음. `type: prompt` 활용 사례를 포함한 다양한 실전 예제
- [Claude Code: Best practices for agentic coding](https://www.anthropic.com/engineering/claude-code-best-practices) — Anthropic 엔지니어링 팀의 공식 best practices. hooks뿐 아니라 CLAUDE.md 설계, 에이전트 활용 전반에 대한 가이드

## 5. Relevant Skills

이번 세션에서 hook 디버깅에 상당한 시간이 소요됨. hook이 올바르게 설정되었는지 검증하는 도구가 있으면 도움이 될 수 있음. `npx skills find "claude code hooks"`로 검색한 결과 관련 스킬이 여러 개 존재하나, 대부분 hook 생성 도구이며 **hook 디버깅/검증** 전용 스킬은 발견되지 않음.

다만 이번 세션의 hook 문제는 설정 파일 위치를 잘못 알고 있었던 것이 근본 원인이므로, 도구보다는 **공식 문서 숙지**가 더 효과적인 해결책임. 별도의 스킬 갭은 식별되지 않음.
