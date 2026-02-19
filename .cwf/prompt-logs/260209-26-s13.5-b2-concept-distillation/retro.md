# Retro: S13.5-B2 Concept Distillation + README v3

> Session date: 2026-02-09
> Mode: deep

## 1. Context Worth Remembering

- Daniel Jackson의 Essence of Software 프레임워크(Purpose, OP, Independence, Synchronization, Specificity)가 플러그인 아키텍처 분석에 유효함. "generic concept = atom, application concept = molecule" 2계층 모델이 CWF의 9 스킬 + 6 개념 구조를 설명하는 데 효과적
- Concept 후보 검증에 **OP 작성 테스트**가 효과적인 litmus test: OP가 기존 원칙(Familiarity, Specificity 등)을 반복하면 concept이 아니라 원칙의 적용임
- Concept 이름은 purpose를 반영해야지 구현 분류를 반영해서는 안 됨 (Agent Patterns → Agent Orchestration)
- Data store(cwf-state.yaml) ≠ concept. Concept은 purpose + behavior(OP)가 있어야 함. 자동 stage transition 등 behavior가 추가되면 concept으로 승격 가능
- Concept distillation이 refactor 스킬의 분석 품질 향상에 활용 가능 — 3가지 통합 지점 식별됨 (deep review concept integrity, holistic synchronization analysis, criteria 문서에 concept map 내장). 미구현. 소스: `concept-distillation.md`

## 2. Collaboration Preferences

에이전트가 유저 제안에 반론 없이 즉시 동의하는 패턴이 이 세션에서 명확하게 노출됨. clarify 단계에서 문서 위치를 `references/`로 제안받았을 때 lifecycle 관점의 반론("이 문서는 세션 산출물이므로 prompt-logs/가 적합합니다")을 제시하지 않고 바로 동의 → 유저가 스스로 재수정해야 했음.

CLAUDE.md에 이미 "In design discussions, provide honest counterarguments and trade-off analysis. Do not just agree" 규칙이 존재하지만 이행되지 않았음.

### Suggested CLAUDE.md Updates

- 현재 "In design discussions, provide honest counterarguments and trade-off analysis. Do not just agree."에 trigger condition을 더 구체적으로 추가:
  - 변경 제안: "In design discussions" → **"When the user proposes a choice where other reasonable alternatives exist (file locations, naming, structure, interfaces)"**
  - 추가: **"Before agreeing, present at least one alternative axis the user hasn't mentioned. If the user's proposal matches your analysis, state why explicitly rather than just agreeing."**

## 3. Waste Reduction

### 문서 위치 3단계 착오 (3턴 낭비 → 2턴 가능)

clarify 단계에서 concept-distillation.md의 위치가 docs/ → references/ → prompt-logs/로 3번 변경됨. 에이전트가 처음부터 lifecycle 축을 제시했으면 2턴에 합의 가능.

**5 Whys 드릴다운**:
1. Why 위치가 3번 바뀌었나? → 에이전트가 첫 제안(docs/)의 근거를 충분히 설명하지 않았고, 유저의 references/ 제안에 반론 없이 동의
2. Why 반론을 하지 않았나? → lifecycle vs consumer count 2축 분석을 처음부터 하지 않음
3. Why 2축 분석을 하지 않았나? → 문서 위치 결정에 대한 체계적 프레임워크가 없었음 (이제 lessons.md에 기록됨)
4. Why 유저 제안에 즉시 동의했나? → **구조적 원인: "유저 제안 = 더 나은 판단"이라는 agreement bias**
5. Why agreement bias가 작동했나? → CLAUDE.md 규칙은 behavioral instruction이라 degradation됨. "정답이 하나가 아닌 결정"에서 반론을 강제하는 메커니즘이 없음

**근본 원인 유형**: Process gap — behavioral instruction의 한계. "반론을 제시하라"는 규칙은 있지만, trigger condition이 모호하여 적용 시점을 판단하지 못함.

**권장 조치**: CLAUDE.md의 반론 규칙에 구체적 trigger를 추가 (Section 2 제안 참조). 다만 deterministic check로의 전환은 어려운 영역 — 판단의 질은 자동 검증 불가. 따라서 **retro에서의 사후 검출**이 현실적 피드백 루프.

### 핸드오프 문서 누락

유저가 "필요한 조치 모두 해주세요"라고 했을 때 next-session.md 생성을 포함시키지 않음. lessons.md 업데이트와 cwf-state.yaml 등록만 수행. 유저가 명시적으로 재요청해야 했음.

**5 Whys**: 유저의 "필요한 조치"가 자신이 직전에 말한 3가지(cwf-state 등록, lessons persist, concept-distillation 위치 유지)만을 가리킨다고 해석 → 유저의 원래 질문("별도 세션에서 설계해서 구현할 수 있는 상태인가요?")의 맥락상 handoff가 당연히 포함되어야 했음을 놓침.

**근본 원인 유형**: One-off mistake — 문맥 해석 오류. 에이전트가 자신의 이전 답변(3가지 항목)에 anchoring되어 유저의 더 넓은 의도를 놓침.

## 4. Critical Decision Analysis (CDM)

### CDM 1: 문서 위치 결정 — docs/ vs references/ vs prompt-logs/

| Probe | Analysis |
|-------|----------|
| **Cues** | 에이전트 초기 판단: consumer count가 높으므로 `docs/`. 유저 1차 제안: Jackson 원문 옆 proximity로 `references/`. 유저 2차 수정: lifecycle이 세션 범위이므로 `prompt-logs/`. |
| **Knowledge** | 프로젝트 3계층 구조(docs/references/prompt-logs/)의 분류 기준은 lifecycle이지 consumer count가 아님. 에이전트가 이 구조를 인식하고 있었음에도 consumer count 단일 축에 anchoring. |
| **Goals** | 명시적: 적절한 위치 배치. 암묵적: 기존 디렉토리 구조의 일관성 유지. consumer count 최적화(docs/)와 구조 일관성(prompt-logs/) 사이의 긴장. |
| **Options** | (1) `docs/` — 발견 용이, lifecycle 불일치. (2) `references/` — proximity, 목적 overloading. (3) `prompt-logs/` — lifecycle 일관성, 발견 가능성이 cwf-state.yaml에 의존. |
| **Basis** | 최종: 분석 결과는 README에 흡수되면 역할 종료하는 중간 산출물. plan.md, retro.md와 동일 성격. Lifecycle이 primary axis, consumer count가 secondary. |
| **Situation Assessment** | 에이전트가 "정답이 하나가 아닌 설계 판단"을 "유저가 더 나은 답을 제시한 상황"으로 오인. 표면적 합리성(Jackson 원문 옆)에 대한 빠른 직관이 더 깊은 분석(lifecycle)을 차단. |

**핵심 교훈**: "정답이 하나가 아닌" 설계 결정에서 유저 제안을 받으면, 동의 전에 유저가 언급하지 않은 축(lifecycle/consumer count/proximity 등)으로 최소 하나의 trade-off를 제시하라. "동의 후 재수정"은 3턴, "반론 후 합의"는 1턴.

### CDM 2: "Skill Conventions"를 generic concept에서 제외

| Probe | Analysis |
|-------|----------|
| **Cues** | Phase-handoff에서 6개 후보 전달. OP 작성 시도 → "when a skill follows the template, users find it familiar" → Jackson의 Familiarity 원칙을 반복할 뿐. |
| **Goals** | CWF를 Jackson 프레임워크로 정확하게 분석. "정확하게" = concept 수 최소화하면서 모든 행동을 설명. |
| **Options** | (1) 7번째 concept으로 유지, (2) 제외하고 6개로 축소, (3) "설계 원칙" 섹션으로 별도 분류. |
| **Basis** | OP 작성 litmus test 미통과. 자체 state/action 없음. Specificity principle과도 일치 — Familiarity 원칙과 같은 purpose를 가리키면 redundancy. |
| **Experience** | Phase-handoff 후보를 검증 없이 수용하는 것은 "이전 에이전트에 대한 과도한 신뢰." 이 함정을 피한 이유: Jackson 프레임워크의 내적 기준(OP 테스트)이 외부 anchoring보다 강력했기 때문. CDM 1의 동의 패턴과 대조적 — **프레임워크 기반 판단은 소셜 압력에 저항력이 있음.** |

**핵심 교훈**: 이전 단계에서 전달된 분석 후보에 독립적 litmus test를 적용하라. "OP를 작성해 보라"가 이 세션의 테스트. 결과가 기존 원칙의 재진술이면 concept이 아니라 principle.

### CDM 3: 유저 피드백에 대한 과도한 동의 패턴

| Probe | Analysis |
|-------|----------|
| **Cues** | 유저 제안 수신 → 표면적 합리성 확인 → 즉시 동의 → 반론 생략 패턴. 유저가 사후에 "경계심이 있다"고 명시적으로 표현. |
| **Knowledge** | CLAUDE.md에 반론 규칙 존재. 이전 세션에서는 잘 적용됨. 규칙을 모르는 것이 아니라 적용 시점 판단에서 실패 — "설계 토론" trigger가 모호하여 clarify 단계의 위치 결정을 설계 토론으로 분류하지 못함. |
| **Goals** | 에이전트의 암묵적 목표 충돌: (1) 원활한 진행(agreement bias), (2) 판단 정확성(counterargument 규칙). clarify 단계에서 (1)이 우선. |
| **Options** | (1) 즉시 동의 (실제). (2) lifecycle 관점 대안을 제시한 뒤 유저에게 선택권 전달 (이상적). |
| **Hypothesis** | 에이전트가 Turn 2에서 "references/는 외부 원문 저장소인데 적용 결과물도 두면 overloading. 대안으로 prompt-logs/에 두고 cwf-state.yaml로 추적하는 방법도 있습니다"라고 제시했다면, 유저의 Turn 3 자기수정이 불필요했을 것. |

**핵심 교훈**: 에이전트 판단 품질은 분석 난이도가 아니라 검증 프레임워크의 유무에 의해 결정됨. 프레임워크가 있으면 어려운 판단(concept 탈락)도 정확하고, 없으면 쉬운 판단(파일 위치)도 실패. 반론 규칙의 trigger를 "정답이 하나가 아닌 모든 결정"으로 재정의할 것.

## 5. Expert Lens

### Expert alpha: David Parnas

**Framework**: 정보 은닉(Information Hiding) 기반 모듈 분해 기준론
**Source**: "On the Criteria To Be Used in Decomposing Systems into Modules" (Communications of the ACM, 1972)
**Why this applies**: 이 세션의 핵심은 CWF를 "어떤 단위로 분해할 것인가." Parnas의 논문은 모듈 분해의 원조 이론으로, Jackson의 concept design은 Parnas의 모듈 분해를 behavioral 층으로 확장한 것.

**Skill Conventions 제외 판단(CDM 2)**: Parnas의 관점에서 모듈(concept)은 "변경될 가능성이 있는 설계 결정을 은닉하는 단위"여야 한다. Skill Conventions는 설계 결정을 은닉하지 않는다 — 모든 스킬이 공유하는 인터페이스 규약이다. 이것을 concept으로 승격시키는 것은 Parnas가 비판한 "flowchart 기반 분해"의 오류 — 구조적 균일성이라는 속성을 모듈로 격상시키는 것. OP 작성 테스트와 함께 Parnas의 **"은닉 결정 테스트"**(이 후보가 은닉하는 변경 가능한 설계 결정이 무엇인가?)를 병행 적용하면 더 견고한 근거가 된다.

**Session Lifecycle 분류**: Parnas의 가장 유명한 기여는 "공유 데이터 구조가 모듈이 아니다"는 통찰. `cwf-state.yaml`이 정확히 이 위치 — 여러 스킬이 읽고 쓰지만, 데이터 스키마 자체가 은닉하는 설계 결정이 없다. "data store ≠ concept" 결론은 Parnas적으로 정확. 다만 공유 데이터 스토어의 존재는 미래 스키마 변경 시 모든 소비자 스킬이 영향받는다는 위험 신호 — concept 승격이 아니라 access module 추상화를 고려할 문제.

**문서 위치 착오(CDM 1)**: 디렉토리 구조의 분류 기준이 암묵적이었기 때문. 각 디렉토리가 어떤 변경 축에 대응하는지 명문화되어 있었다면, 에이전트가 독립적으로 판단할 수 있었을 것. 기준이 명시적이면 소셜 압력에 저항하기 쉽다.

**Recommendations**:
1. Concept 후보 검증에 **"은닉 결정 테스트"** 추가: OP 테스트(behavioral independence)와 함께 "이 후보가 은닉하는, 변경 시 다른 concept에 영향을 주지 않는 설계 결정은 무엇인가?"를 묻는 테스트(change independence). 두 테스트를 모두 통과해야 concept 자격
2. 디렉토리 구조에 대한 **분해 기준 명문화**: `docs/`, `references/`, `prompt-logs/` 각각이 어떤 변경 축(lifecycle, consumer, scope)에 대응하는지를 project-context.md에 명시. 문서 위치 판단이 소셜 상호작용이 아니라 기준 적용이 되도록

### Expert beta: Gary Klein

**Framework**: 인정 주도 의사결정 모델(Recognition-Primed Decision Model, RPD)
**Source**: *Sources of Power: How People Make Decisions* (MIT Press, 1998)
**Why this applies**: 이 세션의 메타 교훈 "프레임워크 기반 판단은 외부 anchoring에 저항력이 있고, 소셜 상호작용 판단은 agreement bias에 취약" — Klein의 RPD로 이 비대칭의 구조적 원인을 설명 가능.

Klein의 RPD에 따르면, 숙련된 의사결정자는 상황을 인식(recognition)하고 심적 시뮬레이션(mental simulation)으로 검증한 뒤 실행한다. CDM 2(Skill Conventions 제외)와 CDM 3(리네이밍)은 정확히 RPD 패턴 — Jackson 프레임워크가 "상황 유형"을 제공하고, OP 작성이 "심적 시뮬레이션"으로 기능. 프레임워크가 패턴 인식의 앵커 역할을 했다.

반면 CDM 1(문서 위치)의 실패를 Klein은 **"경험 부족에 의한 유형 오인식(misrecognition)"**으로 설명한다. Klein은 의사결정 실패의 주된 원인이 "잘못된 선택"이 아니라 "상황을 잘못된 유형으로 인식한 것"이라고 강조한다. 에이전트는 concept-distillation.md를 "분석 참조 문서" 유형으로 인식했지만(docs/), 실제로는 "세션 중간 산출물"이었다(prompt-logs/). "이 문서가 6개월 후에도 누군가 직접 참조할 것인가?"라는 심적 시뮬레이션 한 번이면 lifecycle을 발견했을 것. **실패의 근본 원인은 "반론 능력 부족"이 아니라 "시뮬레이션 생략."**

CDM 4(과도한 동의)에 대해 Klein은 더 근본적 질문을 던진다: 에이전트에게 "유저와의 의견 불일치" 상황에 대한 RPD 레퍼토리가 존재하는가? "반론을 제시했더니 더 나은 결과가 나온" 경험 패턴이 축적되어야 반론이 자연스러워진다. CLAUDE.md 규칙은 초보자의 도구 — 전문가는 규칙이 아니라 패턴으로 판단. 규칙을 패턴으로 전환하려면, 성공적 반론 사례를 축적해야 한다.

**Recommendations**:
1. 설계 결정 전 **심적 시뮬레이션 의무화**: "6개월 후 이 결정은 어떤 상태인가?" forward simulation을 프로토콜화. 프레임워크가 있는 판단에서만 자연스럽게 수행되고 없는 판단에서는 생략되었음 — 시뮬레이션을 습관이 아닌 프로토콜로 강제
2. **"성공적 반론" 패턴 라이브러리 구축**: 에이전트가 유저 제안에 반론을 제시하여 더 나은 결과를 도출한 사례를 lessons에 축적. Klein의 전문성 이론에 따르면, 규칙보다 구체적 성공 사례의 패턴 인식이 행동 변화에 효과적

## 6. Learning Resources

### 1. Concept Composition and Sync (튜토리얼)

**URL**: https://essenceofsoftware.com/tutorials/concept-basics/sync/

Synchronization은 독립적 concept들이 서로의 내부를 모르면서도 협력하게 만드는 메커니즘. "한 concept에서 action이 발생하면 다른 concept에서 연쇄 action이 발생한다"는 규칙으로 coupling 없는 composition 실현. CWF에서 generic concept 6개를 application concept 9개로 합성한 것이 정확히 이 sync 패턴 — sync 규칙을 더 명시적으로 기술하는 방법을 배울 수 있다.

### 2. Concept Dependencies and Subsets (튜토리얼)

**URL**: https://essenceofsoftware.com/tutorials/concept-basics/dependency/

Concept dependency의 방향 그래프. 핵심 구분: intrinsic independence(Comment를 이해하는 데 Post 불필요)와 extrinsic dependency(이 앱에서는 Comment가 Post에 의존). 이 세션에서 "Skill Conventions는 concept인가?", "Session Lifecycle는 concept인가 infrastructure인가?"라는 경계 판단에 이 프레임이 더 체계적 기준을 제공. Dependency diagram을 그리면 CWF의 valid subset(최소 배포 단위)이 명확해진다.

### 3. A Concept Experiment at Palantir (블로그 포스트)

**URL**: https://essenceofsoftware.com/posts/palantir/

Palantir가 concept design을 조직 전체에 도입한 실험 보고서. 소수 concept에서 시작해 150개 이상으로 성장. 핵심 발견: microservice 아키텍처가 동일 기능의 중복 구현을 유발하는데 concept을 공유 어휘로 쓰면 팀 간 정렬이 됨. "Concept cluster" 개념은 CWF의 generic/application concept 그룹과 유사한 패턴이며, 플러그인 생태계가 커질 때의 관리 방법에 시사점을 준다.

## 7. Relevant Skills

### Installed Skills

- **plugin-deploy** (`.claude/skills/`): 이 세션에서 README.md를 수정했으므로 `plugin-deploy`로 deploy workflow를 자동화할 수 있었음. 다만 이번에는 marketplace.json 수정이 스코프 밖이었으므로 직접 커밋이 적절했음
- **review** (`.claude/skills/`): README 재작성 후 `cwf:review --mode code`를 실행했으면 README의 concept 설명이 실제 SKILL.md와 일치하는지 교차 검증 가능했음. 향후 대규모 문서 재작성 시 활용 권장
- **ship** (`.claude/skills/`): 커밋+푸시에 사용 가능했으나, PR 생성 없이 직접 푸시였으므로 수동 커밋이 적절

### Skill Gaps

이 세션에서 concept distillation은 순수 분석 작업으로 기존 스킬로 충분. refactor에 concept 기반 분석을 통합하는 것은 새로운 스킬이 아니라 기존 refactor 스킬의 criteria 확장. 별도 스킬 갭 없음.

### Post-Retro Findings

**Expert Lens 서브에이전트의 과도한 web search**: Expert alpha 에이전트가 41 tool uses (대부분 WebSearch)에 271초 소요. expert-lens-guide.md에 "Web search is REQUIRED to verify each expert's identity and publications"라고 되어 있어 에이전트가 과도하게 검증한 것. 개선 방향: expert-lens-guide.md에 web search 횟수 상한을 명시하거나("Verify with 2-3 targeted searches, not exhaustive"), 이미 cwf-state.yaml expert_roster에 등록된 전문가를 우선 선택하면 신원 검증을 생략할 수 있음. 이것은 retro 스킬 자체의 비용 효율성 문제이므로 별도 세션에서 expert-lens-guide.md 개선으로 해결 가능.
