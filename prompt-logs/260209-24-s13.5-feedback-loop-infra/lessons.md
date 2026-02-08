# Lessons — S13.5 Feedback Loop Infrastructure

### AskUserQuestion 응답이 prompt-logger에 기록되지 않음

- **Expected**: clarify 과정에서의 질문 옵션과 유저 답변이 세션 로그에 남을 것
- **Actual**: prompt-logger는 tool invocation의 name+input 일부만 기록. tool result(유저 응답)는 파싱하지 않음
- **Takeaway**: 중요한 설계 결정은 clarify 산출물 파일에 별도 기록 필수. prompt-logger에 tool result 로깅 추가는 워크스트림 D 후보

When 설계 결정이 AskUserQuestion으로 이루어질 때 → clarify 산출물에 모든 결정과 근거를 명시적으로 기록

### Count는 결과적 현상 — staleness의 근본 신호가 아닐 수 있음

- **Expected**: skill_count/hook_count 변화로 staleness를 충분히 감지할 수 있을 것
- **Actual**: 유저가 "숫자가 안 늘어나고 스킬 역할이 확대될 수도 있다"고 지적. S13에서도 근본 원인은 count가 아니라 "새로운 분석 차원이 필요해진 것"
- **Takeaway**: count는 자동 감지 가능한 proxy이고, designed_for scope 선언 + 에이전트 비결정론적 판단이 보완 역할. Hybrid 접근이 건강함

When staleness 신호 설계 → 결정론적 proxy(count) + 비결정론적 판단(agent scope eval) 조합

### Self-healing의 audience 결정 — 취약성 노출은 건강함

- **Expected**: developer-only vs dual-audience 사이에서 결정 필요
- **Actual**: 유저가 "적절한 수준의 취약성을 드러내는 건 건강하다, 생태계 구성에도 도움"이라고 판단
- **Takeaway**: 내부 도구라도 투명성이 기여자 생태계를 키운다. Meadows의 정보 흐름 레버리지와 일치

### ExitPlanMode에 lessons 검증 hook 부재 — 핸드오프 맥락 유실의 실례

- **Expected**: plan mode 종료 시 lessons.md 존재 여부를 검증하는 hook이 있을 것. 이전 세션 어딘가에서 "ExitPlanMode 시 lesson 작성하게 하자"는 논의가 있었음
- **Actual**: ExitPlanMode에는 timer hook만 걸려있음. lessons.md 생성은 protocol 텍스트 주입에 의존 (behavioral instruction). 이전 세션의 논의가 next-session.md 핸드오프에 반영되지 않아 맥락이 유실됨
- **Takeaway**: 핸드오프 문서(next-session.md)는 "다음에 뭘 할지"는 잘 전달하지만 "세션 중 나온 아이디어/합의 중 아직 미구현인 것"은 누락되기 쉬움. 이것이 바로 이번 세션의 주제인 self-healing 피드백 루프 부재 문제의 또 다른 사례 — 핸드오프 문서 자체에도 provenance가 필요할 수 있음

**구조적 원인 분석**:
1. 핸드오프 문서는 "완성된 결정"을 전달하도록 설계됨. "진행 중인 아이디어"는 구조적으로 빠지기 쉬움
2. retro에서 나온 아이디어 → lessons에 기록 → 하지만 다음 세션의 next-session.md에 반영되려면 retro 작성자가 명시적으로 옮겨야 함
3. 이 "옮기기"에 피드백 루프가 없음 — 누락을 감지할 수 없음
4. project-context.md의 "Deterministic validation over behavioral instruction" 원칙이 정확히 적용되는 케이스

**해결 방향** (구현은 별도 세션):
- 단기: ExitPlanMode PostToolUse hook에 lessons.md 존재 검증 추가
- 중기: retro/handoff 스킬이 이전 세션 lessons.md를 읽어서 "미구현 아이디어" 목록을 자동 생성
- 장기: 핸드오프 문서에 provenance (이전 세션의 미해결 항목 수, 전달 완결성 점수)

When 핸드오프 문서 작성 시 → "미구현 아이디어/합의" 섹션을 명시적으로 포함. 세션 중 나온 아이디어는 즉시 deferred actions에 기록

### Plan mode의 구조적 쓰기 제약 — lessons 기록의 deadlock

- **Expected**: plan review 중 핑퐁에서 나오는 학습을 즉시 lessons.md에 기록할 수 있을 것
- **Actual**: plan mode는 plan 파일만 쓰기 허용. lessons.md에 기록하려면 plan mode를 나가야 하는데, 나가면 plan review가 중단됨
- **Takeaway**: plan mode의 "단일 파일 쓰기 제한"이 lessons 기록과 구조적으로 충돌. 이건 plan mode 설계의 한계

**연쇄 발견**:
- EnterPlanMode PreToolUse에서 lessons.md 존재 강제 → plan mode 진입 전에 만들게 할 수 있음 (해결 가능)
- 하지만 plan review 중 새로 나오는 학습은 기록 불가 (해결 불가, 구조적 한계)
- ExitPlanMode PostToolUse에서 검증하려 해도, plan mode 안에서는 못 만드므로 deadlock

**실현 가능한 해결책**:
1. Plan 파일 자체에 `## In-Review Learnings` 섹션을 두고, plan mode 종료 후 lessons.md로 마이그레이션 — 현실적이지만 수동
2. Plan mode의 허용 파일을 plan 파일 + lessons.md 2개로 확장 — Claude Code의 plan mode 설정 변경이 필요한지 확인 필요
3. Plan review 중 중요한 핑퐁이 나올 때만 plan mode를 잠시 종료, lesson 기록, 재진입 — 가능하지만 어색함

When plan review 중 학습 발생 → plan 파일의 Deferred Actions에 임시 기록, plan mode 종료 후 lessons.md로 이동

### Review 스킬 Rule 5 "Output to conversation" — 근거 없는 디폴트가 규칙이 된 케이스

- **Expected**: review 결과가 파일로 남아 커밋 히스토리에서 추적 가능할 것
- **Actual**: Rule 5 "review results are communication, not state"에 의해 conversation에만 출력. 세션 종료 시 유실
- **Investigation**: S5a 초기 커밋에서 이미 포함. S5a/S5b lessons 어디에도 결정 근거 없음. 의도적 설계가 아니라 디폴트가 규칙으로 굳어진 것
- **Takeaway**: 리뷰 결과는 state다 — 특정 커밋에 대한 평가이며 나중에 참조해야 함. provenance 시스템이 해결하려는 "맥락 유실" 문제와 동일 패턴

When 스킬 규칙 작성 → 근거가 명확하지 않은 규칙은 "rationale: {근거}" 주석 추가. 근거 없는 디폴트가 규칙으로 굳어지는 것을 방지

**Deferred action**: Review 스킬 Rule 5를 "리뷰 결과를 세션 디렉토리에 파일로 저장, 커밋 위에 쌓기"로 변경

### Review 스킬 base branch 감지 — umbrella branch 패턴 미지원

- **Expected**: review가 `marketplace-v3` → `s13.5-feedback-loop-infra` 관계를 인식하고 올바른 diff 생성
- **Actual**: base branch 감지가 main → master → remote default만 시도. umbrella branch 패턴을 전혀 고려하지 않음
- **Takeaway**: ship 스킬의 브랜치 워크플로우와 review 스킬의 base branch 감지가 정합하지 않음

**Deferred action**: Review 스킬에 `--base <branch>` 플래그 추가, 또는 git upstream tracking 정보 활용

### 핸드오프 브랜치 워크플로우 미준수 — sub-branch 생성 누락

- **Expected**: 핸드오프 지시대로 sub-branch(예: `s13.5-a-provenance`)를 만들어 작업
- **Actual**: umbrella branch 위에서 바로 작업 시작. 세션 중간에 발견하여 뒤늦게 sub-branch 생성
- **Takeaway**: 핸드오프의 브랜치 워크플로우 섹션이 세션 시작 시 체크리스트로 기능하지 않음. 세션 시작 프로토콜에 "브랜치 확인" 단계가 필요

When 세션 시작 → 핸드오프 문서의 브랜치 워크플로우 섹션을 명시적으로 확인하고 실행
