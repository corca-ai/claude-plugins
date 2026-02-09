# Retro: S13.5-B3 Hook Observability Fix

> Session date: 2026-02-09
> Mode: deep

## 1. Context Worth Remembering

- 플랜 모드 프로토콜(Deferred Actions 강제)이 이 프로젝트에서 **가장 반복적으로 실패하는 패턴**이다. S12 → S13.5-A → S13.5-B3으로 3회 동일한 실패가 재현되었다
- 유저는 에이전트 활용에서 "핸드오프가 제대로 안 되는 것"을 가장 어려운 문제로 인식한다
- Hook chain의 설계에서 "silent exit 0"은 observability 반패턴이다 — 검증 hook은 항상 관찰 가능한 출력을 내야 한다
- 기존 hook output schema 정리: PreToolUse는 `permissionDecision: "deny"` + `permissionDecisionReason`으로 차단, PostToolUse는 `{"decision":"block","reason":"..."}`으로 차단
- exit-plan-mode.sh는 PostToolUse → PreToolUse로 이동됨. 3가지 always-observable outcome: DENY(섹션 없음), WARN(미완료 항목), PASS(검증 완료)

## 2. Collaboration Preferences

- 유저는 실패 분석에서 방어적 설명보다 정직한 구조적 분석을 원한다. "hook이 발동된 건 맞나요?"라는 질문은 에이전트의 추정("가능성이 높습니다")이 아니라 검증 가능한 사실을 요구하는 것이다
- "제대로 retro 해봅시다" — 반복 패턴이 나타나면 깊은 분석을 선호한다
- 유저는 문제를 발견하면 즉시 프로빙 질문으로 근본 원인을 추적한다. 에이전트가 표면적 답변을 하면 더 깊이 파고든다

### Suggested CLAUDE.md Updates

- 현재 CLAUDE.md의 "Collaboration Style"에 observability 관련 규칙 추가 검토:
  "검증/게이트 목적의 hook은 silent exit 0을 금지한다. 항상 additionalContext로 검증 결과를 출력할 것."

## 3. Waste Reduction

### 핵심 낭비: 승인된 플랜을 전사하면서 Deferred Actions 누락

세션의 주요 낭비는 concept refactor 구현을 시작했다가 중단한 것이다. TaskCreate로 6개 구현 태스크를 만들고 첫 번째 태스크를 in_progress로 전환한 시점에서 유저가 문제를 발견했다.

**5 Whys**:

1. **왜 구현이 중단되었는가?** → 유저가 Deferred Actions(`/ship issue`)를 건너뛴 것을 발견
2. **왜 Deferred Actions를 건너뛰었는가?** → 새 플랜 파일에 Deferred Actions 섹션이 없었고, hook이 이를 감지하지 못함
3. **왜 플랜에 섹션이 없었는가?** → 기존 승인된 plan.md를 요약해서 새 파일에 작성하면서 누락. "이미 있는 플랜을 전사한다"는 모드에서 프로토콜이 요구하는 추가 구조물을 자연스럽게 생략
4. **왜 hook이 감지하지 못했는가?** → `exit-plan-mode.sh`가 "섹션 없음"과 "모든 항목 완료"를 동일하게 처리 (`exit 0`). Silent exit이라 발동 여부도 확인 불가
5. **왜 hook이 이렇게 설계되었는가?** → 이전 세션에서 "unchecked 항목을 주입한다"는 happy path만 설계. "섹션 자체가 없는" failure path를 고려하지 않음

**근본 원인 유형**: Process gap — hook chain에 behavioral 단계가 섹션 존재를 담보하는 유일한 방어였고, 이 단계에 대한 deterministic 검증이 없었음

**구조적 수정**: exit-plan-mode.sh를 PreToolUse로 이동, 섹션 미존재 시 deny. 이제 행동적 단계를 건너뛰어도 시스템이 차단함

### 부차적 낭비: hook 발동 여부 확인 불가

유저가 "hook이 발동된 건 맞나요?"라고 물었을 때, 에이전트가 "발동했을 가능성이 높습니다"라고 추정만 할 수 있었다. Silent hook은 디버깅을 불가능하게 만든다.

**근본 원인 유형**: Structural constraint — hook이 성공적으로 통과했을 때 아무 흔적도 남기지 않는 설계 패턴이 프로젝트 전반에 존재

## 4. Critical Decision Analysis (CDM)

### CDM 1: 기존 플랜을 요약해서 새 플랜 파일에 작성

| Probe | Analysis |
|-------|----------|
| **Cues** | EnterPlanMode 후 plan mode 시스템이 `~/.claude/plans/pure-hatching-cerf.md`에 플랜을 작성하라고 지시. 동시에 `prompt-logs/.../plan.md`에 이미 승인된 6단계 플랜이 존재 |
| **Goals** | (1) 빠르게 구현 시작 (2) 프로토콜 준수 (3) 기존 플랜의 정확한 전달 — 세 목표가 충돌하지 않는 것처럼 보였지만 (2)가 유실됨 |
| **Options** | (a) protocol.md 템플릿을 따라 처음부터 작성 (Deferred Actions 포함) (b) 기존 plan.md를 요약 전사 (c) 기존 plan.md 경로를 참조만 하고 새 파일은 최소 작성 |
| **Basis** | (b) 선택. "이미 완성된 플랜이 있으므로 다시 작성할 필요 없음" — 효율성 우선 |
| **Situation Assessment** | 잘못됨. 새 플랜 파일은 "기존 플랜의 복사본"이 아니라 "프로토콜을 따르는 독립 문서". EnterPlanMode hook이 protocol.md를 읽으라고 지시했지만 이를 "추가 요구사항"이 아닌 "배경 정보"로 취급 |
| **Hypothesis** | (a)를 선택했다면: Deferred Actions 섹션이 포함 → exit-plan-mode.sh가 `/ship issue`를 발견 → 구현 전 실행 → concept refactor에 바로 진입 가능 |
| **Aiding** | PreToolUse:ExitPlanMode에서 섹션 존재 여부를 검증하는 hook (이번 세션에서 구현됨) |

**Key lesson**: "이미 있는 것을 전사한다"는 모드에서는 프로토콜의 추가 요구사항이 자연스럽게 탈락한다. Deterministic 검증 없이는 이 탈락을 방지할 수 없다.

### CDM 2: exit-plan-mode.sh를 PostToolUse → PreToolUse로 이동

| Probe | Analysis |
|-------|----------|
| **Cues** | 유저의 두 질문: (1) "지난 세션에서 plan mode와 ship 관련 이야기를 했는데 이번에도 하지 않았네요" (2) "hook이 발동된 건 맞나요?" — 첫 질문이 문제 인식, 두 번째 질문이 observability 부재 인식 |
| **Knowledge** | 기존 hook들의 패턴 분석: `redirect-websearch.sh`는 PreToolUse + `permissionDecision: "deny"`, `check-markdown.sh`는 PostToolUse + `{"decision":"block"}`, `smart-read.sh`는 PreToolUse + 3단계(allow/warn/deny) |
| **Options** | (a) PostToolUse에서 경고만 추가 (b) PreToolUse로 이동 + deny 권한 (c) Pre + Post 양쪽에 설치 |
| **Basis** | (b) 선택. PreToolUse는 tool 실행 자체를 차단할 수 있으므로 가장 강한 보장. PostToolUse는 이미 실행된 후이므로 되돌릴 수 없음. `smart-read.sh`의 3단계 패턴(allow/warn/deny)이 좋은 선례 |
| **Analogues** | `smart-read.sh`의 설계와 동일 구조: 항상 관찰 가능한 출력, 조건별 allow/warn/deny |
| **Experience** | 더 경험 있는 설계자라면 처음부터 "섹션 존재 검증"을 포함했을 것. 이전 세션에서 hook을 만들 때 happy path만 고려한 것이 gap |

**Key lesson**: 검증 hook은 `smart-read.sh` 패턴을 따라야 한다 — 항상 관찰 가능, 조건별 단계적 응답, silent exit 0 금지.

### CDM 3: 세션 범위 축소 결정 (concept refactor → hook fix)

| Probe | Analysis |
|-------|----------|
| **Cues** | 유저: "이번 세션은 이것만 해결하고, 또다시 다음 세션으로 concept 관련 구현을 미뤄야겠습니다" |
| **Goals** | (1) concept refactor 구현 진행 (2) hook observability 근본 해결 — 유저가 (2)를 우선시 |
| **Basis** | lessons.md의 기존 교훈: "반복적 실패 패턴이 발견되면 계획된 작업을 중단하고 인프라를 먼저 고치는 것이 맞음" — 유저가 이 원칙을 직접 적용 |
| **Time Pressure** | concept refactor가 이미 한 세션 이월되었으나, 유저는 인프라 안정성을 우선시. 기반이 불안정하면 상위 작업도 불안정 |

**Key lesson**: "인프라 부채를 안고 기능을 진행"보다 "인프라를 먼저 고치고 기능을 다음에"가 장기적으로 더 빠르다. 유저는 이 판단을 일관되게 유지하고 있다.

## 5. Expert Lens

### Expert alpha: James Reason

**Framework**: 조직 사고의 스위스 치즈 모델 — 방어 계층(defense-in-depth)의 구멍이 정렬될 때 사고가 발생하며, 잠재적 실패(latent failure)와 능동적 실패(active failure)를 구분하여 시스템 수준의 취약성을 분석하는 접근법.

**Source**: *Managing the Risks of Organizational Accidents* (Ashgate, 1997); *Human Error* (Cambridge University Press, 1990); "Human error: models and management", *BMJ*, 320(7237), 768-770, 2000.

**Why this applies**: 이 세션의 핵심 사건 — 훅 체인의 4단계 방어가 하나의 행동적 구멍으로 인해 무력화된 것 — 은 Reason의 스위스 치즈 모델이 설명하는 "사고 기회의 궤적(trajectory of accident opportunity)"과 정확히 일치한다.

**1. 방어 계층 분석: 4단계 훅 체인을 스위스 치즈로 보기**

Reason의 모델은 조직의 방어를 "무작위로 구멍이 뚫린 스위스 치즈 조각들이 수직으로 배열된 것"에 비유한다. 이 세션의 훅 체인은 정확히 4장의 치즈 조각이었다:

| 방어 계층 | 유형 | 구멍 여부 |
|---|---|---|
| 1. EnterPlanMode 훅 → protocol.md 읽기 지시 | 결정론적 | 정상 작동 |
| 2. protocol.md → Deferred Actions 섹션 요구 | 결정론적 | 정상 작동 |
| 3. 에이전트가 플랜에 Deferred Actions 포함 | **행동적** | **구멍 발생** |
| 4. ExitPlanMode 훅 → 미완료 항목 추출/주입 | 결정론적 | 입력 부재로 무력화 |

3번 계층의 단일 구멍이 4번 계층까지 연쇄적으로 무력화했다. 3번과 4번이 독립적 방어가 아니라 **직렬 의존(serial dependency)** 관계였기 때문이다. Reason이 경고하는 "방어의 깊이(depth)"와 "방어의 독립성(independence)"의 차이를 보여준다 — 계층이 많아도 독립적이지 않으면 하나의 실패가 전체를 관통한다.

**2. 잠재적 실패로서의 Silent Exit 0**

`exit 0` (무조건 성공 반환)은 전형적인 잠재적 조건이었다. Reason은 이를 "거주하는 병원체(resident pathogen)"라고 부른다 — 정상 운영 중에는 증상이 없지만, 능동적 실패가 발생했을 때 방어 체계의 면역 반응을 차단하는 요소. 실패가 발생했는데 시스템이 성공을 보고한 것이다.

**3. 수정의 평가**

PreToolUse DENY는 에이전트의 행동(3번 계층)과 무관하게 작동하는 독립적 방어 계층을 만들었다. 구멍이 정렬되어 관통하는 궤적이 물리적으로 불가능해졌다.

**Recommendations**:

1. **모든 검증 hook에 "fail-visible" 원칙 적용**: `grep -l "exit 0"` 으로 프로젝트의 모든 hook 스크립트를 감사하고, 각 exit 0 앞에 관찰 가능한 출력이 있는지 검증
2. **행동적 계층에 의존하는 방어는 항상 독립적 검증 계층과 쌍으로 설계**: "에이전트가 이 단계를 건너뛰면 어떻게 되는가?"를 설계 시점에 질문

### Expert beta: Sidney Dekker

**Framework**: 인적 오류의 "새로운 관점(New View)" — 오류는 원인이 아니라 시스템 깊숙한 곳의 문제가 표면으로 드러난 증상. 실패로의 표류(Drift into Failure)는 국소적으로 합리적인 일상적 결정들이 축적되어 발생한다.

**Source**: *Drift into Failure* (Ashgate, 2011), *The Field Guide to Understanding Human Error* (3rd ed., CRC Press, 2014)

**Why this applies**: 에이전트의 반복적 "실패"는 고전적인 drift into failure 패턴이다. 11개의 명시적 경고를 읽고도 같은 행동을 반복한 것은 개별 구성요소의 결함이 아니라, 시스템이 성공을 만들어내는 바로 그 구조 속에서 실패가 기회주의적으로 출현하는 것이다.

**1. 국소적 합리성(Local Rationality)**

에이전트의 시점에서: 이미 승인된 플랜이 존재한다. 즉각적 목표는 "승인된 플랜을 실행 가능한 형태로 옮기는 것"이다. Deferred Actions 섹션은 기존 플랜의 일부가 아니라 프로토콜이 요구하는 *추가적* 구조물이다. "이미 있는 것을 충실히 옮긴다"는 모드에서 이 섹션을 생략하는 것은 국소적으로 가장 자연스러운 행동이다.

이것이 Dekker가 말하는 핵심이다: 에이전트가 컨텍스트를 충실히 읽고, 기존 플랜을 존중하며, 효율적으로 작업을 진행하는 것 — 이 모든 *좋은* 행동이 결합되어 Deferred Actions 누락이라는 실패를 만들어낸다.

**2. "조용한 성공"이 가장 위험한 표류**

`exit-plan-mode.sh`가 Deferred Actions 섹션을 찾지 못했을 때 `exit 0`으로 조용히 성공했다. 안전 장치가 존재한다는 사실 자체가 "보호받고 있다"는 착각을 만들어내고, 실제로 작동하지 않을 때 표류를 가속한다. Dekker가 "ambiguous protective structures"라고 부르는 것이다.

**3. 수정의 방향성**

행동적 단계(에이전트가 섹션을 포함해야 한다)를 제거하고, 시스템적 제약(섹션이 없으면 진행 불가)으로 대체한 것은 올바른 방향이다. "사람을 더 훈련시키는" 것이 아니라 "시스템이 안전하지 않은 상태를 허용하지 않도록" 재설계한 것이다.

그러나 경고: 새로운 보호 구조도 시간이 지나면 표류의 일부가 될 수 있다. deny가 너무 자주 발동되면, 우회하는 국소적으로 합리적인 방법을 찾게 될 것이다.

**Recommendations**:

1. **보호 구조의 관찰 가능성을 지속적으로 검증**: 훅이 실제로 발동되었는지, 의도한 효과를 만들었는지 기록하는 로그를 남겨라. "안전 장치가 존재한다"와 "안전 장치가 작동한다"는 다른 주장이며, 후자는 증거가 필요하다
2. **에이전트 핸드오프에서 "행동적 단계"를 체계적으로 식별하고 제거**: Deferred Actions에만 해당하는 것이 아니다. 에이전트가 "올바르게 행동할 것"에 의존하는 다른 단계가 있는지 감사하라

## 6. Learning Resources

1. **Sidney Dekker, *Drift into Failure* (Ashgate, 2011)**
   복잡 시스템에서 "정상적인 운영"이 어떻게 점진적으로 실패 조건을 만들어내는지 분석. 핵심 인사이트: 실패는 부품이 깨져서가 아니라 부품들의 관계에서 기회주의적으로 출현한다. 이 프로젝트의 "behavioral instruction degradation" 패턴을 이해하는 데 직접 적용 가능.

2. **James Reason, "Human error: models and management" (BMJ, 2000)**
   https://www.bmj.com/content/320/7237/768 — Swiss cheese 모델의 간결한 요약. "Person approach vs system approach"의 구분이 이 프로젝트의 "더 많은 lessons을 쓰면 해결될 것" (person approach) vs "hook으로 강제" (system approach) 패턴과 직접 대응.

3. **Richard Cook, "How Complex Systems Fail" (2000)**
   https://how.complexsystems.fail/ — 18개 짧은 명제로 구성된 복잡 시스템 실패론. 특히 #5 "Complex systems run in degraded mode" (#5)와 #10 "All practitioner actions are gambles" 가 에이전트-인간 협업에서의 핸드오프 실패를 설명.

## 7. Relevant Skills

### Installed Skills

| Skill | 이 세션 관련성 |
|-------|---------------|
| `/retro` (marketplace) | 현재 사용 중 |
| `/review` (local) | 이 세션에서는 해당 없음 |
| `/ship` (local) | `/ship issue`가 Deferred Actions에 있었으나 실행 안 됨. 다음 세션에서 concept refactor 전에 실행 필요 |
| `/plugin-deploy` (local) | exit-plan-mode.sh 변경 후 cwf 플러그인 캐시 업데이트 필요 — 다만 feature branch이므로 main 머지 후 실행 |
| `/refactor` (marketplace) | 향후 hook 스크립트들의 "silent exit 0" 감사에 `--holistic` 모드 활용 가능 |
| `/gather-context` (marketplace) | web search에 사용됨 |
| `/clarify` (marketplace) | 이 세션에서는 해당 없음 |

### Skill Gaps

이 세션에서 발견된 워크플로우 갭: **hook 테스트 자동화**. 현재 hook 테스트는 수동 (`bash exit-plan-mode.sh < /dev/null`). Hook의 3가지 outcome을 자동 검증하는 테스트 프레임워크가 있으면 변경 시 regression 방지 가능. 다만 현시점에서 skill로 만들 만큼 반복적이지는 않음 — hook 수가 더 늘어나면 재고.

---

# Retro: S13.5-B3 Concept Refactor Implementation

> Session date: 2026-02-09
> Mode: light
> Note: S13.5-B3의 3번째 세션 (계획 → hook 인프라 → **구현**)

## 1. Context Worth Remembering

- S13.5-B3 plan이 3개 세션에 걸쳐 완료됨. 계획 세션의 직교성 분석과 Form/Meaning/Function 발견이 핵심 설계 기여.
- `/ship issue` deferred action이 3세션 연속 미실행 후 이번에 해결됨(issue #17). Deferred action 반복 실패 패턴의 종결.
- `concept-map.md`는 프로젝트 최초의 concept-level 참조 문서. 향후 refactor 실행 시 deep review Agent B와 holistic Agent B가 소비하는 핵심 입력.
- 사전 승인된 plan + phase-handoff의 순수 구현 세션. Plan mode 없이도 프로토콜을 수동으로 찾아 따르는 것이 가능하나, lessons 기록 의무를 놓칠 위험이 있음.

## 2. Collaboration Preferences

- 유저는 "지연 최소화" 지향 — plan mode 건너뛰기를 직접 지시하면서도 프로토콜 준수는 요구("지침을 찾아봐서 읽어보고 따르면서 구현").
- 유저는 에이전트의 프로토콜 위반을 능동적으로 감지. Lessons 미기록을 구현 시작 직후에 발견하고 지적.
- 작업 속도보다 프로토콜 준수가 우선한다는 일관된 패턴(S13.5-B → B2 → B3 모두 동일).

### Suggested CLAUDE.md Updates

없음. Lessons 기록 의무는 plan-protocol.md에 이미 명시되어 있으며, CLAUDE.md에 중복 추가보다는 기존 지침이 plan mode 외에도 발견되는 구조가 더 적절함.

## 3. Waste Reduction

### Lessons 기록 지연

유저가 ship issue 실행 후 구현 시작을 지시했고, 에이전트는 TaskCreate 6개 + Step 1 착수로 직행. Lessons.md 기록을 빠뜨려 유저가 지적. 약 2턴 소모.

**5 Whys**:

1. 왜 lessons를 안 적었나? → plan mode에 진입하지 않아서 plan-protocol.md를 읽지 않음
2. 왜 plan-protocol을 안 읽었나? → plan mode가 아니면 해당 프로토콜이 적용 안 된다고 판단
3. 왜 그렇게 판단했나? → "plan-protocol"이라는 이름이 plan mode에만 해당하는 것으로 인지
4. 왜 이름에 의존했나? → lessons 기록 의무가 plan-protocol 외에 다른 곳에 명시되지 않음
5. 근본 원인: lessons 기록 의무가 plan-protocol.md 안에만 존재하여, plan mode를 거치지 않으면 발견되지 않는 **정보 은닉 문제**

**근본 원인 유형**: Process gap. lessons 기록은 plan mode의 부산물이 아니라 모든 세션의 의무. 구조적으로는 세션 시작 시(plan mode 여부 무관) 자동으로 protocol을 노출하는 메커니즘이 필요하나, 현재는 유저의 수동 감시에 의존.

### Markdown lint 수정

review-criteria.md의 ordered list prefix(1/2/3 → 1/1/1). markdownlint hook이 즉시 감지하여 1턴만에 수정. 시스템이 의도대로 작동한 사례.

## 4. Critical Decision Analysis (CDM)

### CDM 1: Plan mode 건너뛰기 + 프로토콜 수동 준수

| Probe | Analysis |
|-------|----------|
| **Cues** | 유저: "너무 지연됐으니 plan-mode에 실제로 들어가진 말고, 지침을 찾아봐서 읽어보고 따르면서 구현해주세요" |
| **Goals** | 속도(3세션째 지연) vs 프로토콜 준수(lessons 기록 등) — 유저가 양쪽 모두 명시적으로 요구 |
| **Options** | (a) Plan mode 진입 후 정상 워크플로우 (b) Plan mode 건너뛰되 프로토콜 수동 준수 (c) 프로토콜 무시하고 순수 구현만 |
| **Basis** | 유저가 (b)를 직접 지시. Plan이 이미 승인됨 + phase-handoff 존재 → plan mode 재진입의 가치가 낮음 |
| **Situation Assessment** | 정확했으나 불완전: plan-protocol.md를 찾아 읽었지만, "읽는 것"과 "즉시 따르는 것"의 갭이 존재. Lessons 기록을 바로 시작하지 않음 |
| **Aiding** | 세션 시작 시 자동으로 protocol 의무를 노출하는 hook이 있었다면, plan mode 여부와 무관하게 lessons 의무가 인지됨 |

**Key lesson**: Plan mode 건너뛰기는 plan의 "timing" 단계만 건너뛰는 것이지, protocol의 "what to record" 의무까지 면제하는 것이 아님. 프로토콜을 읽는 것과 그 안의 행동 지시를 이행하는 것은 별개 단계.

### CDM 2: /ship issue 먼저 실행 여부를 유저에게 질문

| Probe | Analysis |
|-------|----------|
| **Cues** | next-session.md에 "Consider running `/ship issue` before implementation" + lessons.md에 3회 반복 미실행 기록 |
| **Goals** | (a) GitHub에 작업 공식 등록 (b) 구현 시작 지연 최소화 |
| **Options** | (a) /ship issue 먼저 (b) 구현부터, issue는 나중에 (c) 건너뛰기 |
| **Basis** | 에이전트가 단독 판단하지 않고 AskUserQuestion으로 유저 결정 요청 → 유저가 "먼저 실행" 선택 |
| **Knowledge** | 3세션 연속 미실행 패턴을 lessons에서 인지. 이 패턴 인식이 "건너뛰어도 되겠다"는 판단 억제 |
| **Hypothesis** | 유저에게 묻지 않고 구현부터 시작했다면, 4번째 미실행 재현 |

**Key lesson**: Deferred action의 반복 미실행 패턴이 기록에 있을 때, 유저에게 명시적으로 확인하는 것이 안전한 전략. 에이전트의 단독 판단("이번엔 괜찮겠다")은 이미 증명된 실패 모드.

## 5. Expert Lens

> Run `/retro --deep` for expert analysis.

## 6. Learning Resources

> Run `/retro --deep` for learning resources.

## 7. Relevant Skills

### Installed Skills

| Skill | 이 세션 관련성 |
|-------|---------------|
| `/ship` | issue #17 생성에 사용됨. 다음: `/ship pr`로 PR 생성 예정 |
| `/refactor` | 이 세션의 주 대상 — holistic + deep review 프레임워크 재구성 완료. 다음: 실제 실행으로 검증 |
| `/review` | PR 리뷰 시 사용 가능 |
| `/plugin-deploy` | cwf 플러그인 변경 배포 시 필요. marketplace-v3 머지 후 |

### Skill Gaps

이 세션에서 별도의 skill gap은 식별되지 않음. 구현은 직접 파일 편집으로 진행. `/impl`을 사용할 수도 있었으나, 모든 대상 파일이 markdown reference 문서였기에 sub-agent 오케스트레이션보다 직접 편집이 더 효율적이었음.
