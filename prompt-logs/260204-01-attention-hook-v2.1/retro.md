# Retro: attention-hook v2.1.0 버그 수정 + Plan Mode 알림

> Session date: 2026-02-04

## 1. Context Worth Remembering

- **attention-hook 실사용 피드백**: 사용자가 직접 `--plugin-dir`로 테스트하면서 두 가지 버그를 발견 (중복 DM, 400 에러). 실사용 테스트 없이는 async race condition과 sync 훅의 빈 출력 문제를 발견하기 어려웠을 것
- **Claude Code sync 훅과 빈 출력**: 공식 문서에는 sync 훅의 빈 stdout이 "안전하게 무시된다"고 되어 있으나, 실제로는 Notification:idle_prompt의 sync 훅에서 빈 출력이 대화 히스토리를 오염시킬 수 있었음. 문서화되지 않은 엣지 케이스일 가능성
- **system tool의 PreToolUse 매칭**: `EnterPlanMode`, `ExitPlanMode`, `AskUserQuestion` 등 내부 system tool도 PreToolUse/PostToolUse 매처로 잡을 수 있음. 전용 훅 이벤트가 없어도 tool name matcher로 확장 가능

## 2. Collaboration Preferences

이 세션에서 사용자의 작업 스타일 관찰:

- **트랜스크립트 파일 기반 디버깅**: 이전 세션의 문제를 텍스트 파일로 캡처해서 새 세션에서 분석 요청. 컨텍스트 전달 방식이 효율적
- **원인 분석 정확도 요구**: 문제 1의 원인을 idle_prompt로 잘못 추정했을 때 즉시 교정 ("파악하신 바와 좀 다릅니다"). 추측보다 확인을 우선시
- **종합 워크플로우 지시**: "plan-and-lesson protocol + 커밋 + retro + push"를 한 문장으로 지시. 프로토콜을 이미 숙지하고 있어 세부 단계를 반복할 필요 없음

### Suggested CLAUDE.md Updates

- 현재 CLAUDE.md에 적절히 반영되어 있음. 추가 변경 불필요

## 3. Prompting Habits

- **효과적인 패턴**: 트랜스크립트 파일 + "@파일명" 참조로 맥락을 정확하게 전달. "읽고 맥락 파악해주세요"라는 명확한 지시
- **교정 시 구체적 피드백**: "2번째 요청을 하자마자 바로 DM이 새로 왔습니다" — 타이밍을 구체적으로 명시해서 원인 분석 범위를 좁힘. 이런 구체적 증거가 디버깅을 크게 도움
- **개선 여지**: 초기 요청에서 "이 브랜치에서 한 작업을 직접 테스트하려면" 부분이 약간 모호했으나, 이후 대화에서 자연스럽게 구체화됨

## 4. Learning Resources

- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks.md) — sync/async 동작, exit code별 처리, 모든 훅 이벤트 목록. attention-hook 개발의 1차 참조 문서
- [Claude Code Hooks Guide](https://code.claude.com/docs/en/hooks-guide.md) — 실전 예제와 troubleshooting 포함. Stop 훅 무한루프 등 알려진 이슈 문서화
- [Slack Web API: chat.postMessage](https://api.slack.com/methods/chat.postMessage) — thread_ts 파라미터를 이용한 스레딩, 응답의 ts 필드 활용 패턴

## 5. Relevant Skills

이 세션에서 특별한 스킬 갭은 발견되지 않았음. `plugin-deploy` 스킬이 있었지만 이 세션은 수동 커밋 흐름을 명시적으로 요청받아 사용하지 않음.

향후 고려사항: attention-hook을 `--plugin-dir`로 직접 테스트할 때 자동화된 검증 스킬이 있으면 유용할 수 있음 (예: "훅이 정상적으로 등록되었는지", "Slack 메시지가 실제 전송되는지" 검증). 하지만 현재 수동 테스트로 충분한 수준.
