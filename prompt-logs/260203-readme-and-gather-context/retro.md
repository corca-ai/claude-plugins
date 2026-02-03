# Retro: README 보완 및 gather-context 자율 검색

> Session date: 2026-02-03

## 1. Context Worth Remembering

- **문서-코드 동기화 실패 사례**: 직전 세션에서 web-search에 PreToolUse hook을 추가했지만, README(EN/KO)의 개요 테이블 타입(`Skill` → `Skill + Hook`)과 hook 동작 설명이 누락됨. CLAUDE.md에 "After modifying code, update any affected documentation" 규칙이 명시되어 있었지만 지켜지지 않음.
- **Hook 기반 느슨한 결합 패턴**: gather-context가 `/web-search` 스킬을 직접 호출하는 대신, 빌트인 `WebSearch` 도구를 사용하도록 설계. web-search 플러그인이 설치되어 있으면 PreToolUse hook이 자동 리다이렉트하고, 미설치 시 빌트인이 그대로 동작. 스킬 간 직접 의존 없이 사용자 환경에 적응하는 패턴.
- **플러그인 업데이트 관리**: 코드를 수정한 후 마켓플레이스 업데이트와 전역 설치 플러그인 업데이트를 잊기 쉬움. web-search 1.1.0→1.2.1, retro 1.3.1→1.3.2 업데이트가 밀려 있었음.
- **API 키 위치 비일관성**: `TAVILY_API_KEY`가 `~/.claude/.env`가 아닌 `~/.zshrc`에만 설정되어 있어 스킬 실행 시 첫 시도 실패. 직전 세션에서 env var 로딩 패턴을 표준화했지만, 실제 사용자 환경은 아직 마이그레이션되지 않은 상태.

## 2. Collaboration Preferences

- 유저는 문제를 짚어준 뒤 에이전트가 전체 상태를 파악하고 구체적 gap을 리포트하기를 기대함. "리드미가 적절히 수정된 것 같지 않습니다" → 에이전트가 양쪽 README와 SKILL.md를 읽고 정확히 무엇이 빠졌는지 목록화.
- 유저가 설계 아이디어를 던지면서도 ("강결합이 마음에 걸린다") 에이전트의 의견을 묻는 패턴. 단순 동의가 아닌 기술적 근거와 함께 의견을 제시하는 것이 효과적이었음.
- 유저는 "retro 후 커밋합시다"처럼 작업 순서를 지정하고, 부가 작업("플러그인 업데이트")을 중간에 추가하는 흐름을 자연스럽게 사용함. 에이전트가 유연하게 수용하는 것이 중요.

### Suggested CLAUDE.md Updates

- **Before You Start** 또는 **Plan Mode** 섹션에 다음 체크리스트 항목 추가 고려:
  - `After committing plugin changes, update the marketplace and verify globally installed plugin versions are current.`
  - 이유: 두 세션 연속으로 플러그인 업데이트가 누락됨. 커밋/배포 워크플로우에 명시적 단계로 넣으면 방지 가능.

## 3. Prompting Habits

- **직전 세션의 문서 누락 원인 분석**: CLAUDE.md의 "Before You Start" 규칙이 있었음에도 불구하고 문서 업데이트가 빠진 이유는, 에이전트가 구현 완료 후 retro로 넘어가면서 "문서 업데이트" 단계를 건너뛴 것으로 보임. 유저가 이번 세션에서 "왜 지난 세션에서는 놓쳤을까요?"라고 물은 것은 프로세스 개선 기회.
  - **개선 방안**: plan.md에 "문서 업데이트" 항목을 명시적으로 포함하거나, retro에서 "문서 동기화 확인"을 체크리스트로 추가하면 누락 방지 가능.
- 이번 세션의 프롬프팅은 효율적이었음. 두 가지 우려를 한 메시지에 명확히 전달하고, 후속 메시지에서 구현 지시와 설계 질문을 자연스럽게 분리.

## 4. Learning Resources

- [Syncing documentation with code changes (GitHub Copilot Cookbook)](https://docs.github.com/copilot/copilot-chat-cookbook/documenting-code/syncing-documentation-with-code-changes) — AI 에이전트를 활용한 문서-코드 동기화 방법. 이번 세션의 핵심 문제와 직접 관련.
- [Event-Driven = Loosely Coupled? Not So Fast! (Enterprise Integration Patterns)](https://www.enterpriseintegrationpatterns.com/ramblings/eventdriven_coupling.html) — hook/event 기반 느슨한 결합의 실질적 결합도 분석. gather-context ↔ WebSearch ↔ web-search hook 패턴을 설계할 때 참고할 만한 관점.
- [Keeping Docs in Sync With Code (Docuwiz Blog)](https://blog.docuwiz.io/p/keeping-docs-in-sync-with-code) — docs-as-code 워크플로우에서 기술 문서가 코드와 동기화되지 않는 문제의 구조적 원인과 해법.

## 5. Relevant Skills

- **문서 동기화 검증 skill gap**: 코드 변경 후 관련 문서(README, SKILL.md 등)가 적절히 업데이트되었는지 자동 검증하는 스킬이 없음. `suggest-tidyings`가 코드 리팩토링 기회를 찾듯이, "문서-코드 drift"를 감지하는 스킬이 있으면 이번 같은 누락을 방지할 수 있음.
  - 예시: plugin.json 버전 변경 시 README의 해당 플러그인 섹션이 업데이트되었는지, hook 추가 시 개요 테이블 타입이 반영되었는지 등을 체크.
  - 필요하다면 `skill-creator`로 설계 가능.
