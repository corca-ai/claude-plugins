# Lessons: attention-hook v2.1.0

### 문제 1 원인 분석 — 중복 DM

- **Expected**: `track-user-input.sh`가 thread-ts 파일 유무로 부모 메시지 생성을 결정하므로 중복이 없을 것
- **Actual**: async 훅 두 인스턴스가 동시에 실행되면 둘 다 thread-ts가 없다고 판단하여 부모 메시지를 두 번 생성
- **Takeaway**: async 훅에서 "check-then-act" 패턴은 race condition에 취약. 원자적 잠금(mkdir)이 필요

When async 훅이 상태 파일을 체크하고 생성하는 패턴일 때 → mkdir 같은 원자적 잠금 사용

### 문제 2 원인 분석 — 400 API 에러

- **Expected**: sync Notification 훅이 빈 stdout으로 exit 0하면 아무 일도 안 일어남
- **Actual**: `attention.sh`의 빈 출력이 대화 히스토리에 빈 text content block으로 주입되어 API 에러 유발
- **Takeaway**: 슬랙 전송만 하는 훅은 반드시 async로. sync는 대화에 영향을 줄 수 있음

When 훅이 외부 서비스만 호출하고 Claude 동작에 영향을 줄 필요가 없을 때 → async 사용

### 설계 의도 확인

- **Expected**: 사용자가 모든 프롬프트를 DM에 기록하길 원하는 것으로 추측
- **Actual**: 세션당 쓰레드 부모 1회 + 사용자 응답 필요 시에만 알림 (idle, AskUserQuestion, plan mode)
- **Takeaway**: 사용자의 설계 의도를 먼저 확인. "알림"의 범위가 중요

### Plan mode 훅 접근법

- **Expected**: Plan mode 전용 훅 이벤트가 있을 것
- **Actual**: Claude Code에 plan mode 전용 훅은 없지만, `PreToolUse:EnterPlanMode`/`ExitPlanMode`로 매칭 가능
- **Takeaway**: system tool도 PreToolUse/PostToolUse로 매칭 가능. 전용 이벤트가 없어도 tool name matcher로 해결 가능

### 구현 — start-timer/cancel-timer 재사용성

- **Expected**: EnterPlanMode/ExitPlanMode용 별도 스크립트가 필요할 것
- **Actual**: `start-timer.sh`와 `cancel-timer.sh`는 tool name에 의존하지 않고 session_id 기반으로 동작. hooks.json에 matcher만 추가하면 됨
- **Takeaway**: 훅 스크립트를 tool-name-agnostic하게 설계하면 새로운 이벤트 추가 시 JSON 설정만으로 확장 가능

### 구현 — rebase 충돌 패턴

- **Expected**: `git push`가 바로 성공할 것
- **Actual**: 원격 브랜치와 로컬 커밋 해시가 달라서 (이전 세션에서 rebase/amend 발생) push rejected. `git rebase origin/branch` 후 push 성공
- **Takeaway**: 이전 세션 커밋이 있는 브랜치에서 작업할 때는 push 전에 `git fetch` + `git log HEAD..origin/branch`로 확인

---

## Session 2: Slack API 디버깅 (2026-02-04 오후)

### 디버그 로그 해석 실패 — ok= 의 의미

- **Expected**: `ok=` (빈 값)은 API 호출 자체가 안 되었거나 환경 변수 미로드를 의미
- **Actual**: `jq -r '.ok // empty'`는 `false`를 falsy로 처리하여 빈 문자열 반환. 즉 `ok=`는 API가 `"ok": false`를 응답했다는 뜻
- **Takeaway**: jq의 `// empty`(alternative operator)는 `false`와 `null` 모두 빈 값으로 바꿈. 디버그 로그에서 `ok=`가 보이면 API 인증/권한 실패를 먼저 의심해야 함

### 디버그 로그의 코드 경로 추론

- **Expected**: `SLACK_BOT_TOKEN`이 현재 셸에서 비어있으므로 hook에서도 로드 안 됐을 것
- **Actual**: `slack_send parent:` 디버그 로그가 남았다는 건 Web API 경로(SLACK_BOT_TOKEN 분기)를 탔다는 증거. 토큰은 로드됐지만 무효했던 것
- **Takeaway**: 디버그 로그가 어느 코드 경로에서 남는지 먼저 파악하면 문제 범위를 빠르게 좁힐 수 있음. 현재 셸 환경과 hook 실행 환경은 별개

### Slack 채널 ID 혼동 — 셀프 DM vs 봇 DM

- **Expected**: 사용자 자신의 DM 채널 ID(`D09E73V9XT8`)로 봇이 메시지 전송 가능
- **Actual**: 셀프 DM은 봇이 접근 불가. 봇과의 DM 채널(`D0ACQ6ZKG59`)을 사용해야 함
- **Takeaway**: Slack DM 채널 ID는 대화 쌍에 고유. 봇이 사용자에게 DM을 보내려면 봇-사용자 간 DM 채널 ID 필요

### Webhook fallback이 안 되는 구조적 문제

- **Expected**: 봇 토큰 실패 시 webhook으로 fallback
- **Actual**: `slack_send()`에서 봇 토큰 분기 진입 후 API 실패해도 `return 0`으로 종료. Webhook fallback에 도달하지 않음
- **Takeaway**: 이전에 webhook으로 동작했던 이유는 `.env`에 `SLACK_CHANNEL_ID`가 없어서 봇 토큰 분기 조건(`SLACK_BOT_TOKEN && SLACK_CHANNEL_ID`)이 false였기 때문

### 검증 없는 주장 — "토큰 동일 유지는 정상"

- **Expected**: Slack reinstall 후 토큰 동일 유지 여부를 확실히 알고 있음
- **Actual**: 확실하지 않은 정보를 단정적으로 발언. 사용자가 지적
- **Takeaway**: 확신이 없으면 "~일 수 있습니다" 또는 "확인이 필요합니다"로 표현. 추측을 사실처럼 말하지 않기

### Slack 봇 DM의 쓰레드 알림

- **Expected**: 쓰레드 댓글이 자동으로 알림을 생성
- **Actual**: 봇 DM의 쓰레드 댓글은 기본적으로 푸시 알림이 안 옴
- **Takeaway**: `reply_broadcast: true`를 추가하면 채널에도 표시되어 알림이 옴
