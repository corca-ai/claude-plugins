# Retro: prompt-logger 플러그인

> Session date: 2026-02-04

## 1. Context Worth Remembering

- **Claude Code JSONL 트랜스크립트 구조**: `type: "user"` (content는 string 또는 array), `type: "assistant"` (content는 항상 array로 text/tool_use/thinking 블록 포함), `isMeta: true`는 시스템 주입 엔트리, `isSnapshotUpdate` 타입도 존재. `message.usage`에 `input_tokens`, `output_tokens`, `cache_creation_input_tokens` 등 포함.
- **Stop/SessionEnd 훅 입력**: 둘 다 `session_id`, `transcript_path`, `cwd`, `permission_mode`, `hook_event_name` 제공. SessionEnd는 추가로 `reason` 필드 (`clear`, `logout`, `prompt_input_exit` 등).
- **prompt-logger 아키텍처**: `/tmp/` 디렉토리에 세션 해시 기반 상태 파일(offset, turn_num)을 유지하여 증분 처리. `mkdir` 기반 원자적 락으로 Stop/SessionEnd 동시 실행 방지.

## 2. Collaboration Preferences

- 이전 세션에서 플랜이 이미 상세하게 작성되어 있었고, 유저가 "Implement the following plan"으로 전달함. 이 패턴에서는 플랜을 그대로 따르되, 구현 중 발견한 문제(예: `date -j` stdout 누출)를 즉시 수정하는 방식이 효과적이었음.
- 유저가 "retro 후 커밋합니다"처럼 여러 단계를 한 문장으로 지시하는 패턴 — 순서대로 실행하면 됨.

### Suggested CLAUDE.md Updates

(없음 — 현재 CLAUDE.md가 이 워크플로우를 잘 반영하고 있음)

## 3. Prompting Habits

- 이번 세션은 프롬프팅 측면에서 효율적이었음. 상세한 플랜을 미리 작성하고 구현만 위임하는 패턴은 컨텍스트 낭비 없이 빠르게 진행됨.
- 한 가지 관찰: 플랜에 포함된 코드 스니펫(jq turn grouping 등)이 구현 시 그대로 사용되기보다 참고용으로 활용됨. 플랜의 코드 스니펫은 "의도 전달용"으로 충분하며 정확한 구문보다 로직 흐름을 기술하는 게 더 효율적.

## 4. Learning Resources

- [Automate Your AI Workflows with Claude Code Hooks | GitButler](https://blog.gitbutler.com/automate-your-ai-workflows-with-claude-code-hooks) — Stop 훅으로 자동 커밋하는 실전 예제. prompt-logger와 유사한 패턴으로 트랜스크립트를 파싱하여 커밋 메시지 생성.
- [Claude Code Hooks: A Practical Guide | DataCamp](https://www.datacamp.com/tutorial/claude-code-hooks) — 훅 이벤트 타입별 실전 활용 가이드. PostToolUse, Notification 등 다양한 이벤트 조합 사례.
- [Feature: Auto-export session logs on /exit #4329](https://github.com/anthropics/claude-code/issues/4329) — Claude Code 측에서 세션 로그 자동 export 기능에 대한 논의. prompt-logger가 해결하는 것과 동일한 문제를 다룸.

## 5. Relevant Skills

- **prompt-logger + retro 연계 가능성**: prompt-logger가 생성하는 `prompt-logs/sessions/` 파일을 retro 스킬이 자동으로 참조하면, `/export` 없이도 세션 회고가 가능해짐. 현재는 retro가 트랜스크립트를 직접 읽지만, prompt-logger 출력을 보조 입력으로 활용하면 토큰 절약 가능.
- 현재 prompt-logger는 순수 훅이므로 별도 스킬 갭은 없음.
