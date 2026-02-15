# Retro: attention-hook Slack API 디버깅

> Session date: 2026-02-04 (Session 2 — 오후)

이전 세션에서 attention-hook v2.1.0의 쓰레딩 기능을 구현/배포. 이번 세션에서는 `--plugin-dir`로 실사용 테스트 중 Slack 알림이 안 오는 문제를 디버깅. 여러 겹의 설정 문제가 겹쳐 있었고, Claude의 디버깅 접근이 비효율적이었음.

## 1. Context Worth Remembering

- **Slack DM 채널 ID 구분**: 사용자 셀프 DM(예: `D09E73V9XT8`)과 봇-사용자 간 DM(예: `D0ACQ6ZKG59`)은 별개 채널. 봇은 셀프 DM에 접근 불가. `chat.postMessage`로 DM을 보내려면 봇과의 DM 채널 ID 필요
- **Slack 봇 DM 필수 스코프**: `chat:write`만으로는 DM 전송 불가. `im:write` 스코프도 필요
- **Slack 쓰레드 알림**: 봇 DM의 쓰레드 댓글은 기본적으로 푸시 알림 미발생. `reply_broadcast: true` 추가로 해결
- **jq `// empty` 동작**: `jq -r '.ok // empty'`는 `false`를 falsy로 처리하여 빈 문자열 반환. 디버그 로그의 `ok=`는 `"ok": false`를 의미하며 API 인증/권한 실패 신호
- **webhook fallback 구조적 문제**: `slack_send()`에서 봇 토큰 분기 진입 후 API 실패해도 `return 0`. Webhook fallback에 도달 불가. 이전에 webhook이 동작했던 이유는 `.env`에 `SLACK_CHANNEL_ID`가 없어서 봇 토큰 분기 조건 자체가 false였기 때문

## 2. Collaboration Preferences

이번 세션에서 Claude의 디버깅이 비효율적이었던 핵심 원인들:

- **디버그 로그의 코드 경로 추론 실패**: `slack_send parent:` 로그가 남았다 = Web API 경로를 탔다 = 토큰은 로드됐다. 이 추론을 못 하고 "토큰이 로드 안 됐다"는 잘못된 방향으로 조사. **로그가 어느 코드 경로에서 생성되는지 먼저 파악해야 함**
- **현재 셸 환경 ≠ hook 실행 환경**: `echo $SLACK_BOT_TOKEN`이 비어있다고 hook에서도 비어있다고 단정. Hook은 `~/.claude/.env`를 자체 로드하므로 별개 환경
- **확신 없는 정보를 단정적으로 발언**: "Slack reinstall해도 토큰이 동일하게 유지되는 건 정상" — 확실하지 않은 정보였음. 사용자 지적 후 인정
- **"이전 동작" 정보 활용 실패**: "이전에는 웹훅으로 DM이 왔었다" → 이건 SLACK_CHANNEL_ID 미설정으로 webhook fallback이 동작했다는 핵심 단서. 놓침

### Suggested CLAUDE.md Updates

변경 불필요. 위 내용은 일반적인 디버깅 역량 문제이며 CLAUDE.md의 규칙으로 해결할 성격이 아님.

## 3. Prompting Habits

- **효과적인 패턴**: 스크린샷으로 Slack UI 상태를 직접 공유 — 채널 ID, 에러 메시지 확인이 즉시 가능. 봇 DM 채널 ID를 직접 알려줘서 해결이 빨라짐
- **효과적인 패턴**: 실수에 대한 직접적 피드백 ("이번 세션에서 당신이 실수가 많네요") — Claude가 방어적으로 반응하지 않고 개선에 집중할 수 있게 함
- **개선 가능한 패턴**: 초반 "테스트 1. 바로 응답해주세요"에서 구체적으로 무엇이 안 되는지(Slack 알림 미수신)를 먼저 말했으면 더 빨리 디버깅 방향을 잡았을 것. 다만 테스트 자체가 목적이었으므로 이 맥락에서는 자연스러운 흐름

## 4. Learning Resources

- [Slack chat.postMessage Reference](https://docs.slack.dev/reference/methods/chat.postMessage) — `reply_broadcast`, `thread_ts` 파라미터와 에러 코드 목록 (`not_authed`, `channel_not_found` 등)
- [Slack Authentication & Tokens](https://docs.slack.dev/authentication/tokens) — 토큰 종류, `not_authed` 에러 원인, reinstall 시 토큰 동작
- [Slack OAuth Scopes Reference](https://docs.slack.dev/reference/scopes) — `im:write` vs `chat:write` 스코프 차이. DM 전송에 필요한 스코프 확인

## 5. Relevant Skills

이번 세션에서 반복된 패턴: `curl` → 에러 → 설정 변경 → 재테스트 루프가 5회 이상 반복.

**잠재적 개선**: attention-hook에 `--diagnose` 모드를 추가하면 초기 설정 시 유용:
```bash
./slack-send.sh --diagnose
# → Token valid: yes (auth.test ok)
# → Channel accessible: yes/no
# → Required scopes: chat:write ✓, im:write ✓
# → Test message: sent ok
```

다만 초기 설정 시 한 번만 필요하므로, README에 수동 진단 curl 명령어를 Troubleshooting 섹션으로 문서화하는 게 더 실용적. 현재는 구현 불필요.
