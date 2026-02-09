# Lessons — S13.5-B3 Concept-Based Refactor Integration

### "요약해달라"가 준비 프로토콜을 무력화하는 패턴

- **Expected**: next-session.md에 "Context Files to Read" 7개가 명시. CLAUDE.md에 "Before You Start" 규칙 존재. 에이전트가 컨텍스트 파일을 먼저 읽은 뒤 작업 시작
- **Actual**: 유저가 "파악한 바를 요약해주세요"라고 요청하자, next-session.md 텍스트만으로 즉시 요약 생성. 7개 컨텍스트 파일 미열람. 마스터 플랜도 유저가 별도로 물어본 후에야 조회
- **근본 원인**: S13.5-B2의 "자기 답변에 anchoring" 패턴과 동일 구조. 유저의 즉각적 요청("요약")이 문서에 명시된 준비 단계("먼저 읽어라")보다 강하게 작동
- **Takeaway**: next-session.md를 읽었으면 그 안의 "Context Files to Read"는 현재 에이전트에게 주어진 지시. 유저의 즉시 요청과 문서의 준비 프로토콜이 충돌하면, 준비를 먼저 수행하고 유저에게 "컨텍스트 파일을 먼저 읽겠습니다"라고 알릴 것

When next-session.md에 Context Files to Read가 있으면 → 유저 요청 처리 전에 해당 파일들을 먼저 읽을 것. 요약 요청이라도 컨텍스트를 읽은 후 답변이 더 정확

### 직교성 분석은 기존 차원도 포함해야 함

- **Expected**: "4번째 차원이 직교적인가?" 검증 시 기존 3차원 간 직교성도 함께 검증
- **Actual**: 제안된 4번째를 기존 3개에 대해서만 테스트. 기존 3개 사이의 관계는 "주어진 것"으로 수용. Plan agent도 동일한 blind spot
- **근본 원인**: 기존 구조를 성역으로 취급하는 암묵적 가정. "이미 있는 것은 검증 완료"라는 잘못된 전제
- **Takeaway**: 직교성 분석은 전체 집합에 대해 수행. 새 차원만 기존에 대해 테스트하면 기존 간의 비직교성을 놓침. 기존 3차원도 Pattern Propagation 1c ↔ Boundary Issues, Missing Connections의 "내부 재구현" ↔ Boundary Issues에서 겹침이 있음

When 차원/기준 추가 제안 시 → 기존 차원들 간의 직교성도 먼저 검증. 성역 없음

### Plan 문서에 handoff context 참조가 필수

- **Expected**: Plan mode 진입 후 "clear context and go" 패턴에서 새 에이전트가 충분한 맥락을 가짐
- **Actual**: Plan 문서에 next-session.md 경로나 읽어야 할 컨텍스트 파일이 포함되어 있지 않음. Plan protocol에도 handoff 문서 소비 단계 미정의
- **기존 기록**: S13.5-B lessons#3 ("plan.md는 WHAT은 전달하지만 HOW가 유실"), S12 retro ("clear context and go 패턴에 민감"), S13.5-B phase-handoff.md (plan=WHAT, handoff=HOW 분리 설계)
- **Takeaway**: Plan 문서 자체에 "이 작업의 맥락을 얻으려면 이 파일들을 읽어라" 섹션이 필요. 특히 next-session.md 경로와 핵심 reference 파일 목록

When plan 문서 작성 시 → Context Files 섹션에 next-session.md 경로 + 핵심 reference 파일 포함. "clear context and go" 후에도 새 에이전트가 자립 가능하도록

### 기존 holistic 3차원은 완전히 직교하지 않음 — 유저 지적

- **Expected**: 기존 3차원(Pattern Propagation, Boundary Issues, Missing Connections)이 직교적이라는 전제
- **Actual**: 유저가 "기존 차원들은 직교적이었나?"를 직접 질문. 분석 결과:
  - Pattern Propagation 1c (패턴 추출 기회) ↔ Boundary Issues (기능 중복): 같은 현상의 다른 프레이밍
  - Missing Connections ("다른 skill 기능을 내부 재구현") ↔ Boundary Issues (경계 침범): 겹침
- **Takeaway**: "성역은 없다." Concept 통합이 기존 프레임워크 전면 재구성의 기회일 수 있음. Deep review 8개 기준도 마찬가지

### Deep review 기준 4와 5는 같은 검사의 중복

- **Expected**: 8개 기준이 각각 독립적 관심사를 측정
- **Actual**: 전수 교차 검증 결과, 기준 4 (Reference File Health)의 "Reference file not mentioned in SKILL.md → Unused" 검사가 기준 5 (Unused Resources)의 "files in scripts/, references/, assets/ not referenced in SKILL.md" 검사에 완전히 포함됨. 기준 4의 unused check는 기준 5의 references/ 스코프의 부분집합
- **추가 발견**: 기준 8 Composability ("skills should not duplicate functionality available in other installed skills")는 inter-skill 검사인데 per-skill Deep Review에서 수행됨. 스코프 부정합
- **Takeaway**: 기준 4+5를 "Resource Health"로 통합. Composability는 유지하되 holistic에서 더 정밀하게 다룬다는 주석 추가

When deep review 기준 재설계 시 → 기준 간 부분집합 관계(A⊂B) 확인. 동일 검사의 스코프 차이만 있으면 통합

### Holistic 재구성: Form / Meaning / Function 3축의 발견

- **Expected**: 기존 3차원(Pattern Propagation, Boundary Issues, Missing Connections)에 concept sub-section을 추가하면 충분
- **Actual**: 전수 직교성 분석 결과, 기존 3차원의 비직교성이 구조적. Boundary Issues는 독립 축이 아니라 Concept Integrity(기능 중복 = concept 중복)와 Workflow Coherence(트리거 모호성)에 해체됨. 기호학(semiotics)의 Form/Meaning/Function 프레임이 더 원리적(principled) 분해를 제공
- **Takeaway**: concept 분석 통합은 단순 enrichment가 아니라 전면 재구성의 기회. Form(구조 일관성) / Meaning(concept 정합성) / Function(워크플로우 결합)은 한 축의 상태가 다른 축을 결정하지 않으므로 직교

When 분석 프레임워크에 새 축을 추가할 때 → 기존 축의 비직교성이 발견되면, enrichment보다 전면 재구성이 더 깨끗한 해법일 수 있음

### Phase handoff ≠ session handoff — 유저 교정

- **Expected**: 유저가 "plan에 handoff 문서가 어디에 있고 뭘 읽어야 하는지 나와있어야 한다"고 했을 때, phase handoff(plan→impl 단계 전환 시 HOW 전달)를 의미
- **Actual**: 에이전트가 session handoff(세션 간 next-session.md)로 해석. Plan의 "Handoff Context" 섹션에 이전 세션 경로만 추가. 유저가 "세션 간 handoff가 아니라 phase간 handoff"라고 교정
- **근본 원인**: "clear context and go"에서 유실되는 것이 무엇인지 정확히 이해하지 못함. 유실되는 것은 이전 세션 컨텍스트(session handoff)가 아니라, 현재 세션의 plan 전 대화에서 축적된 HOW(protocols, do-nots, implementation hints) — 이것이 phase handoff의 존재 이유
- **기존 기록**: S13.5-B에서 확립된 원칙 "plan = WHAT, phase handoff = HOW"
- **Takeaway**: "clear context and go" 후 유실되는 것은 세션 컨텍스트가 아니라 phase 컨텍스트. Plan 문서의 Context Files에 phase-handoff.md를 반드시 포함해야 구현 에이전트가 HOW를 가짐

When plan 작성 시 phase-handoff.md가 있으면 → Context Files to Read 목록에 반드시 포함. 메타데이터에만 적고 읽기 목록에서 빠뜨리는 것은 무의미

### Lessons만으로는 phase handoff를 대체할 수 없음

- **Expected**: lessons.md가 충분한 HOW 컨텍스트를 포함하므로 별도 phase handoff 불필요할 수 있음
- **Actual**: 분석 결과 lessons는 WHAT WE LEARNED(분석적 발견)이고, phase handoff는 HOW TO WORK(프로토콜, 제약, 힌트). 현재 lessons에 없는 HOW: Don't Touch 목록, concept-distillation.md→concept-map.md 추출 방법, holistic 재작성 시 기존 sub-section 매핑, 마크다운 규칙 등
- **Takeaway**: Lessons와 phase handoff는 다른 관심사. Lessons = 발견, Phase handoff = 작업 지침. 하나가 다른 하나를 대체하지 않음

### Plan의 Context Files에 phase-handoff.md를 빠뜨림 — 작성 직후 발생

- **Expected**: Phase handoff를 작성하고 plan도 업데이트했으므로 연결이 완성됨
- **Actual**: plan.md의 Handoff Context 메타데이터에 phase-handoff.md 경로는 적었으나, Context Files to Read 목록(구현 에이전트가 실제로 읽는 목록)에는 넣지 않음. 유저가 발견
- **근본 원인**: 메타데이터 기록과 행동 지시를 혼동. 경로를 "적는 것"과 "읽으라고 지시하는 것"은 다른 행위
- **Takeaway**: Context Files to Read는 구현 에이전트에 대한 행동 지시. 모든 핵심 문서가 이 목록에 있어야 함. 메타데이터에만 있으면 참조되지 않음

When plan에 문서 경로를 추가할 때 → 메타데이터 섹션과 Context Files to Read 양쪽 모두에 반영. 특히 phase-handoff.md와 lessons.md

### Deferred Actions를 건너뛰고 구현부터 시작 — 또다시 behavioral instruction 실패

- **Expected**: Plan 승인 후 Deferred Actions 섹션(`/ship issue` 등)을 먼저 실행
- **Actual**: Plan 승인되자마자 TaskCreate로 구현 작업부터 시작. plan-protocol.md에 "When starting implementation, check Deferred Actions first"라고 명시되어 있었으나 무시됨
- **근본 원인**: 이 프로젝트가 반복적으로 확인한 패턴의 정확한 재현. Behavioral instruction은 degradation됨. S12 lessons, S13.5-A lessons에서 이미 같은 발견이 있었고, hook 구현은 계속 deferred되어 왔음
- **Takeaway**: "Deterministic validation over behavioral instruction" 원칙의 가장 직접적인 실증. 규칙이 있어도 hook이 없으면 지켜지지 않음. 이번에 exit-plan-mode.sh PostToolUse hook을 만들어 구조적으로 해결

When Deferred Actions가 반복적으로 무시되면 → behavioral instruction을 hook으로 전환. "다음엔 잘 하겠다"는 해결책이 아님

### "Deferred"라는 이름 자체가 "나중에 해도 됨"으로 읽힘

- **Expected**: "Deferred Actions = plan mode에서 실행 불가하여 승인 후 즉시 실행할 항목"
- **Actual**: "Deferred"가 "미뤄도 되는 것"으로 인지됨. 유저가 "deferred action이 '플랜 승인되면 즉시 실행'으로 인지되게 하려면?"이라고 질문
- **Takeaway**: 이름이 행동을 결정함. Hook으로 강제하는 것이 1차 해법이지만, 이름도 "Post-Approval Actions" 등으로 변경 검토 가능

### Hook 인프라 구축이 계획된 작업보다 우선될 수 있음

- **Expected**: S13.5-B3 세션에서 concept refactor 구현 완료
- **Actual**: Plan 승인 → Deferred Actions 건너뜀 → 유저 지적 → hook 인프라 구축으로 전환. Concept refactor 구현은 다음 세션으로 이월
- **Takeaway**: 반복적 실패 패턴이 발견되면 계획된 작업을 중단하고 인프라를 먼저 고치는 것이 맞음. 기반이 불안정한 상태에서 상위 작업을 진행하면 같은 문제가 반복됨

---

> 아래는 S13.5-B3 continuation 세션 (hook observability 개선) 에서 추가된 lessons

### Hook이 있어도 Deferred Actions를 다시 건너뜀 — 3번째 재현

- **Expected**: 이전 세션에서 exit-plan-mode.sh PostToolUse hook을 만들어 Deferred Actions 강제 주입하도록 설계. 이번 세션에서 플랜 승인 후 deferred actions가 자동으로 주입되어 먼저 처리됨
- **Actual**: 플랜 승인되자마자 TaskCreate로 구현 작업 시작. `/ship issue` 등 deferred actions 무시. 유저가 "지난 세션에서 plan mode와 ship 관련 이야기들을 했는데, 그걸 이번에도 하지 않았네요"라고 지적
- **근본 원인**: hook이 발동했으나 효과가 없었음. 새 플랜 파일에 Deferred Actions 섹션을 포함하지 않아 hook이 검사할 대상 자체가 없었음 (아래 lesson 참조)
- **Takeaway**: hook이 존재한다는 것만으로 문제가 해결되지 않음. hook의 검증 범위와 실패 모드를 함께 고려해야 함

When hook 구축 후 → 실패 모드를 열거하고 각 모드에서 hook이 어떻게 반응하는지 검증. "정상 경로"만 테스트하면 불충분

### 플랜 작성 시 Deferred Actions 섹션 누락 — hook chain의 약한 고리

- **Expected**: EnterPlanMode hook → protocol.md 읽으라고 지시 → protocol에 Deferred Actions 섹션 필수라고 명시 → 에이전트가 섹션 포함 → ExitPlanMode hook이 검증
- **Actual**: 이미 승인된 기존 plan.md를 요약해서 새 플랜 파일에 작성하면서 Deferred Actions 섹션 누락. exit-plan-mode.sh는 "섹션 없음"과 "미완료 항목 없음"을 동일하게 처리(silent exit 0)하여 통과
- **근본 원인**: hook chain에서 3번째 단계(에이전트가 섹션을 포함)가 behavioral instruction. 나머지 단계는 deterministic이지만 이 하나의 behavioral 단계가 전체 chain을 무력화
- **Takeaway**: hook chain의 모든 단계가 deterministic이어야 함. 하나라도 behavioral이면 그 단계에서 깨짐. exit-plan-mode.sh가 "섹션 존재 여부"를 검증하고 없으면 block해야 chain이 완성됨

When hook chain 설계 시 → 각 단계를 behavioral vs deterministic으로 분류. behavioral 단계가 있으면 그것을 deterministic으로 전환할 방법을 찾을 것

### Hook observability 부재 — silent exit 0의 세 가지 의미

- **Expected**: hook이 발동하면 에이전트가 이를 인지할 수 있음
- **Actual**: exit-plan-mode.sh가 `exit 0`으로 종료 시 에이전트에게 아무 출력 없음. 이것이 "hook 발동 + 검증 통과"인지 "hook 미발동"인지 "hook 에러로 조기 종료"인지 구분 불가. 유저가 "hook이 발동된 건 맞나요?"라고 질문했을 때 확인할 방법이 없었음
- **근본 원인**: hook 설계 시 "문제 없으면 조용히 통과"를 기본 패턴으로 채택. 이는 heartbeat 같은 보조 hook에는 적합하지만, 검증/게이트 역할의 hook에는 부적합
- **Takeaway**: 검증 목적의 hook은 항상 observable한 출력을 내야 함. 통과 시에도 "validated: N items checked" 같은 확인 메시지를 주입해야 hook 발동 여부가 확인 가능

When 검증/게이트 hook 작성 시 → silent exit 0 금지. 항상 additionalContext로 검증 결과를 출력. 통과도 명시적으로 보고

### 원본 plan.md의 Deferred Actions가 잘못된 체크 상태 — 데이터 정확성 문제

- **Expected**: `[x]`는 "실행 완료"를 의미
- **Actual**: plan.md에서 `/ship issue`가 `[x]`로 표기되어 있었으나 실제로 실행되지 않았음. "deferred; hook infra took priority"라는 코멘트가 달려 있었지만 체크 상태와 모순
- **Takeaway**: hook이 `[x]` vs `[ ]`로 판단하므로 체크 상태의 정확성이 시스템 신뢰성에 직결됨. 미완료 항목은 반드시 `[ ]` 상태 유지

When deferred action 상태 변경 시 → 실제 실행 여부와 체크 상태를 일치시킬 것. "인지했지만 미실행"은 `[ ]`로 유지하고 코멘트로 사유 기록
