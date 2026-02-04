# Retro: prompt-logger 플러그인 구현 + 아키텍처 디자인

> Session date: 2026-02-04

## 1. Context Worth Remembering

- **Claude Code JSONL 트랜스크립트 구조**: `type: "user"` (content는 string 또는 array), `type: "assistant"` (content는 항상 array로 text/tool_use/thinking 블록 포함), `isMeta: true`는 시스템 주입 엔트리, `isSnapshotUpdate` 타입도 존재. `message.usage`에 `input_tokens`, `output_tokens`, `cache_creation_input_tokens` 등 포함.
- **Stop/SessionEnd 훅 입력**: 둘 다 `session_id`, `transcript_path`, `cwd`, `permission_mode`, `hook_event_name` 제공. SessionEnd는 추가로 `reason` 필드.
- **SessionEnd 훅의 한계**: 세션이 끝난 후 발동하므로 모델을 활용할 수 없음. `type: "command"`(bash)만 가능. 모델 기반 의사결정이 필요한 작업(예: 세션 제목 생성)은 SessionEnd에서 처리 불가.
- **플러그인 간 방어적 연동 패턴**: prompt-logger(훅) → retro(스킬) 연동 시, retro가 `prompt-logs/sessions/` 디렉토리 존재를 조건부 체크하는 방식으로 커플링 없이 연동. prompt-logger 미설치 유저에게 영향 없음.
- **update-all.sh는 remote에서 pull**: 로컬 커밋만으로는 새 플러그인이 marketplace에 반영되지 않음. 반드시 push 후 실행.

## 2. Collaboration Preferences

- 유저가 구현 중 에이전트의 실수를 포착하는 패턴이 이번 세션에서 두드러졌음:
  - "update-all은 push 전에 동작 안 하는 거 아닌가요?" → 워크플로우 순서 오류 포착
  - "적절한 위치와 이름을 어떻게 정확히 찾을 수 있는지 잘 모르겠습니다" → 구현의 약점을 정확히 짚음
  - "retro는 있는데 prompt-logger는 없는 유저에 대한 고려입니다" → 커플링 문제 제기
  - "async하게 살짝 늦게 기록될 수도 있으니" → 엣지 케이스 지적
- 이러한 피드백이 설계를 반복적으로 개선시켰음. 에이전트가 유저의 질문을 기다리지 않고 이런 엣지 케이스를 선제적으로 고려했어야 함.

### Suggested CLAUDE.md Updates

- 플러그인 간 연동 시 "방어적 연동" 원칙 추가: 플러그인 A가 플러그인 B의 출력을 참조할 때, B가 설치되지 않은 환경에서도 A가 정상 동작해야 함 (존재 여부 조건부 체크)

## 3. Prompting Habits

- **"Implement the following plan"** 패턴이 매우 효과적이었음. 별도 세션에서 플랜을 상세히 작성하고 구현 세션에 넘기는 방식은 컨텍스트를 효율적으로 사용.
- **디자인 토론에서의 날카로운 질문**: 유저가 구현 결과물을 바로 수용하지 않고 근본적인 질문("제가 원하는 건 세션 기록이 적절한 prompt-logs/에 옮겨지는 거였는데, 이게 현재 프로토콜에서 동작할 수 있나요?")을 던져서 설계가 개선됨. 이 패턴은 "구현 → 검증 → 수정" 루프를 건강하게 유지함.
- **"제가 말하지 않았어도 그 순서대로 진행했을까요?"** — 에이전트의 암묵적 가정을 검증하는 질문. 이런 질문이 없었으면 잘못된 순서로 진행했을 것. 에이전트에게 단순히 "맞다"고 대답하기보다 사실을 고백하게 만드는 효과적인 프롬프팅.

## 4. Learning Resources

- [Building a TUI to index and search coding agent sessions](https://stanislas.blog/2026/01/tui-index-search-coding-agent-sessions/) — Claude JSONL 세션을 인덱싱하고 검색하는 TUI 구현기. prompt-logger의 출력을 더 풍부하게 활용하는 방향에 참고.
- [Automate Your AI Workflows with Claude Code Hooks | GitButler](https://blog.gitbutler.com/automate-your-ai-workflows-with-claude-code-hooks) — Stop 훅으로 트랜스크립트를 파싱하여 자동 커밋하는 실전 예제. prompt-logger와 동일한 패턴.
- [Feature: Auto-export session logs on /exit #4329](https://github.com/anthropics/claude-code/issues/4329) — Claude Code에서 세션 로그 자동 export 논의. prompt-logger가 해결하는 것과 동일한 문제.
- [claude-mem: Multi-session context persistence](https://www.reddit.com/r/ClaudeCode/comments/1odoo3k/i_built_a_context_management_plugin_and_it/) — 훅 기반 세션 간 컨텍스트 유지 플러그인. prompt-logger와 유사한 아키텍처로 참고 가치 있음.

## 5. Relevant Skills

- **retro v1.5.0에서 prompt-logger 연동 구현 완료**: "Link Session Log" 단계가 추가되어, retro 실행 시 자동으로 `sessions/`에서 현재 세션 로그를 찾아 retro 출력 디렉토리에 심링크. prompt-logger 미설치 시 스킵.
- **향후 고려**: prompt-logger의 세션 로그를 retro의 보조 입력으로 활용하면 트랜스크립트 전체를 읽지 않고도 턴 요약을 참조 가능. 토큰 절약 효과가 있을 수 있으나, 현재로서는 불필요.
