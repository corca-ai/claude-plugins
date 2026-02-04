# Retro: attention-hook v2.0 — Slack Threading + Heartbeat

> Session date: 2026-02-03

## 1. Context Worth Remembering

- **attention-hook 아키텍처**: v2.0부터 모든 스크립트가 `slack-send.sh`를 공유 유틸리티로 source하는 구조. Web API(chat.postMessage)를 우선 사용하고, SLACK_WEBHOOK_URL만 있으면 레거시 웹훅으로 폴백.
- **세션 격리 패턴**: `session_id`의 SHA-256 해시 첫 12자를 사용해 `/tmp/claude-attention-{hash}-*` 형태의 상태 파일로 세션 간 격리. 동시 세션에서 상태 충돌 방지.
- **Claude Code 훅 입력 공통 필드**: 모든 훅 타입에 `session_id`, `transcript_path`, `cwd`가 공통 포함됨. `UserPromptSubmit`에는 추가로 `prompt` 필드 존재.
- **async 훅**: `"async": true` 설정 시 논블로킹으로 실행되며, 결정(decision)을 반환할 수 없음. heartbeat처럼 매 tool call마다 빠르게 체크하는 용도에 적합.
- **parse-transcript.sh 패턴**: `if [[ "${BASH_SOURCE[0]}" == "${0}" ]]` 가드로 source 시에는 함수만 export하고, 직접 실행 시에만 main 로직 수행. 테스트에서 함수 단위 검증 가능.

## 2. Collaboration Preferences

- 이번 세션은 이전 세션에서 완성된 상세한 구현 계획(plan.md)을 바로 실행하는 방식으로 진행됨. 계획이 충분히 상세했기 때문에 추가 확인 없이 순차적으로 구현할 수 있었음.
- 사용자는 구현 완료 후 "retro 후 커밋, 푸시해주세요"라는 한 문장으로 나머지 워크플로우를 지시 — CLAUDE.md에 정의된 post-implementation 워크플로우(retro → commit → push)를 한 번에 트리거하는 패턴.

### Suggested CLAUDE.md Updates

- 없음. 현재 CLAUDE.md의 "After implementing a plan" 워크플로우가 이번 세션의 흐름과 정확히 일치.

## 3. Prompting Habits

- **효율적**: "Implement the following plan:" + 전체 plan 붙여넣기 방식은 매우 효과적. 별도 clarification 없이 바로 구현에 착수할 수 있었음.
- **개선 포인트 없음**: 이번 세션은 계획-실행 패턴의 이상적인 사례. 계획이 구체적이었고, 실행 지시가 명확했음.

## 4. Learning Resources

- [Slack Web API: chat.postMessage](https://api.slack.com/methods/chat.postMessage) — Bot token 기반 메시지 전송과 스레딩(`thread_ts`) 동작 방식의 공식 레퍼런스
- [Claude Code Hooks Documentation](https://docs.anthropic.com/en/docs/claude-code/hooks) — `async` 훅, `UserPromptSubmit` 등 훅 타입별 입력 스키마의 공식 문서
- [Advanced Bash-Scripting Guide: Process Substitution](https://tldp.org/LDP/abs/html/process-sub.html) — `nohup` + background process 패턴, `source` vs direct execution 차이 등 이번 세션에서 활용된 bash 패턴 참고

## 5. Relevant Skills

이번 세션에서 특별한 스킬 갭은 식별되지 않았음. 구현은 기존 bash 스크립트 패턴을 확장하는 작업이었고, plan-and-lessons + retro 워크플로우가 잘 동작함.
