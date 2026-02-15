# Retro: gather-context 마이그레이션

> Session date: 2026-01-30

## 1. Context Worth Remembering

- **TAVILY_API_KEY 미설정**: `web-search` 스킬이 설치되어 있지만 `TAVILY_API_KEY`가 환경에 설정되어 있지 않아 실제 사용 불가. `~/.claude/.env` 또는 `~/.zshrc`에 설정 필요.
- **Dogfooding 의식**: 유저는 자신이 만든 도구를 실제 워크플로우에서 사용하는 것을 중시함. retro 작성 시 빌트인 WebSearch 대신 `/web-search` 스킬을 쓰지 않은 것을 즉시 지적.
- **메타 관찰 습관**: 유저는 작업 중 도구의 동작 방식 자체에 대해 질문하고 개선점을 찾는 패턴이 있음 (훅 발동 확인, 스킬 미사용 지적 등). 단순히 결과물만이 아닌 프로세스 품질에 관심.

## 2. Collaboration Preferences

**의사결정 패턴**: 유저는 문제를 구조화된 형태로 제시하며 ("원래는 이 구조가 좋다고 생각했는데...") 여러 고려사항을 나열한 뒤 "함께 논의해봅시다"로 협업을 시작함. 방향이 정해지면 "좋습니다"로 간결하게 승인하고, "자율적으로, 적절한 단위로 커밋하면서"처럼 명확한 제약조건과 함께 위임.

**프로토콜 준수 기대**: CLAUDE.md에 명시된 프로토콜(plan-and-lessons 등)이 리마인더 없이 따라지기를 기대. 이번 세션에서 훅 미발동 + 프로토콜 미준수를 즉시 포착하고 지적.

**도구 사용에 대한 관찰**: 빌트인 도구와 커스텀 스킬이 겹칠 때, 커스텀 스킬 우선 사용을 기대함 (dogfooding). "web-search skill은 왜 사용하지 않았을까요?"라는 질문이 이를 잘 보여줌.

### Suggested CLAUDE.md Updates

- `## Collaboration Style` 섹션에 추가: "When a custom skill (e.g., `/web-search`, `/gather-context`) overlaps with a built-in tool (e.g., WebSearch, WebFetch), prefer the custom skill. This supports dogfooding and ensures the skill is tested in real workflows."
- `## Plan Mode` 섹션에 추가: "On entering plan mode, proactively read `.claude/settings.json` to check for registered hooks and follow their intent, regardless of whether the hook execution was observed."

## 3. Prompting Habits

**잘 된 점**:
- 초기 프롬프트가 구조적이고 효과적이었음. 현재 구조의 문제점, 대안 방향, 열린 질문을 한 메시지에 담아 논의의 출발점을 명확히 제공.
- "함께 논의해봅시다"로 일방적 지시가 아닌 협업 톤을 설정한 것이 좋은 결과를 냄 — Claude 측에서 옵션 A/B/C를 제시하고 trade-off를 분석하는 구조적 응답을 이끌어냄.
- 위임 시 "자율적으로, 적절한 단위로 커밋하면서"라는 짧은 제약조건이 명확하고 효율적.

**더 나아질 수 있는 점**:
- 훅 발동 확인 질문("Was the hook correctly triggered? can u check?")에서, 구체적으로 무엇을 확인해야 하는지 힌트를 주면 더 빨랐을 수 있음. 예: "settings.json의 PreToolUse 훅이 실제로 발동됐는지 확인해봐" → Claude가 바로 settings.json을 읽고 상황을 파악.
  - 다만 이 경우 유저의 의도는 "Claude가 스스로 알아채야 한다"는 프로토콜 준수 테스트였을 수 있어, 의도적인 모호함이었을 가능성도 있음.

## 4. Learning Resources

- [Claude Code Hooks Reference (공식 문서)](https://code.claude.com/docs/en/hooks) — `type: "prompt"` 훅의 동작 방식, PreToolUse의 allow/deny/ask 제어, 디버깅 방법(`claude --debug`, `/hooks`) 등. 훅 발동 확인 문제의 직접적 참고.
- [claude-code-hooks-multi-agent-observability](https://github.com/disler/claude-code-hooks-multi-agent-observability) — `send_event.py`로 훅 이벤트를 실시간 추적하는 오픈소스. 훅 발동 여부를 로그로 확인하는 패턴 참고.
- [Claude Code Plugins README (공식)](https://github.com/anthropics/claude-code/blob/main/plugins/README.md) — 플러그인 구조, 배포, 업데이트 전략의 공식 가이드.

## 5. Relevant Skills

이 세션에서 명확한 스킬 갭은 없었음. 다만 두 가지 관찰:

1. **훅 디버깅 도구**: `type: "prompt"` 훅의 발동 여부를 확인할 수 있는 메커니즘이 부족. `type: "command"`로 로그를 남기는 래퍼 훅이나, 훅 발동 이력을 기록하는 경량 스크립트가 있으면 유용할 것. 별도 세션에서 `skill-creator`로 제작 고려.
2. **TAVILY_API_KEY 미설정**: `web-search` 스킬이 설치되어 있지만 API 키가 없어 동작 불가. 환경 설정 후 dogfooding 가능.
