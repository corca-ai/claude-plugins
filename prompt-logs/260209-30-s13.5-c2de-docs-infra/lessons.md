# Lessons — S13.5 C2/D/E

## Clarify Phase

### 1. 계획-현실 불일치: Slack threading 이미 구현됨

- Expected: D 워크스트림에서 Slack threading 구현 필요
- Actual: `track-user-input.sh`(parent) + `attention.sh`(thread reply) + `slack-send.sh`(`thread_ts` 관리)로 이미 완전 구현
- Real need: `reply_broadcast: true` 하드코딩이 채널을 노이지하게 만드는 문제 → 환경변수화
- Takeaway: plan document는 현재 상태가 아님 (S29 교훈 재확인). 구현 전 코드 분석 필수

### 2. catch-all 문서의 progressive disclosure 실패

- project-context.md가 architecture patterns, shell troubleshooting, hook config, project facts를 모두 담고 있었음
- CLAUDE.md에서 "언제 읽어라"를 지정해도, 한 파일이 모든 trigger를 충족하면 결국 "always read" 또는 "never read"가 됨
- 참고자료 3개가 같은 결론을 지지:
  - Vercel: always-loaded 파일은 compressed index여야 함 (80% 축소, 100% pass rate)
  - g15e: 전문화된 retrieval target으로 분리 (architecture.md, coding.md 등)
  - HumanLayer: CLAUDE.md <300줄, pointers > copies
- Takeaway: 문서가 catch-all이 되면 progressive disclosure의 이점이 사라짐. 각 문서의 scope가 겹치지 않아야 trigger condition이 의미를 가짐

### 3. 읽기 자율 vs 쓰기 명시: persist routing의 비대칭

- g15e: "readers are sufficiently intelligent — prescriptive directive 대신 agent 자율 판단"
- 이 원칙은 읽기에는 맞지만, 쓰기(retro persist)에는 적용 불가
- "어디를 읽을까"는 task context에서 추론 가능하지만, "어디에 쓸까"는 operational instruction 필요
- 해결: CLAUDE.md에 persist routing 테이블 추가 (읽기 라우팅은 제거, scope description만)
- Takeaway: 읽기와 쓰기의 agent autonomy 수준은 다르다. 읽기는 scope description으로 충분, 쓰기는 명시적 지시 필요

### 4. Shared module 추출은 legacy 제거 시 자연 해소

- slack-send.sh(260줄) cwf↔attention-hook 100% 중복, log-turn.sh(485줄) cwf↔prompt-logger 99% 중복
- 그러나 이 중복은 cwf에 migration된 코드 vs legacy 플러그인 간 문제
- S14에서 legacy 플러그인 deprecate/제거 시 자연 해소 → 지금 추출하면 이중 작업
- Takeaway: 중복 제거의 타이밍도 설계 결정. "지금 깨끗이" vs "머지 때 한 번에"의 trade-off에서 후자가 나을 때가 있음

### 5. AskUserQuestion 로깅 gap은 워크스트림 경계를 넘어 전파됨

- S13.5-A에서 발견된 gap (tool result 미기록)이 "D 후보"로 deferred
- D 스코프 논의 중 사용자가 직접 재기 → 즉시 E에 포함
- Takeaway: deferred item이 다음 세션 스코프에 명시적으로 포함되지 않으면 유실 위험. next-session.md의 "Unresolved Items" 섹션을 스코프 확정 시 반드시 점검할 것
