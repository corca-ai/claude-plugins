# Expert Retro — Session S32-impl

### Expert Alpha: Frederick P. Brooks, Jr.

**Framework**: 개념적 무결성(Conceptual Integrity), "하나를 버릴 계획을 세워라(Plan to throw one away)", Second-System Effect, 본질적/우발적 복잡성 구분
**Source**: *The Mythical Man-Month: Essays on Software Engineering* (1975, 20th anniversary ed. 1995), "No Silver Bullet—Essence and Accident in Software Engineering" (1986), *The Design of Design* (2010)
**Why this applies**: S32-impl 세션은 4개 parallel agent를 통한 대규모 파이프라인 구현이다. Brooks가 평생 연구한 대규모 시스템 설계에서의 개념적 무결성 유지, 통신 오버헤드, 그리고 "계획과 현실의 괴리"가 이 세션의 핵심 문제와 정확히 겹친다.

---

#### 1. 개념적 무결성의 실패 — 9x 중복이 말해주는 것

Brooks는 *The Mythical Man-Month* 4장 "Aristocracy of Architecture"에서 이렇게 말했다: "개념적 무결성은 시스템 설계에서 가장 중요한 고려사항이다(Conceptual integrity is the most important consideration in system design)." 그는 대성당 건축을 비유로 들며, 여러 세대의 건축가가 참여하더라도 하나의 일관된 설계 비전이 관통해야 한다고 강조했다. 이를 위해 그는 "아키텍처는 소수의, 이상적으로는 한 사람의 머리에서 나와야 한다"고 주장했다.

S32-impl에서 벌어진 9x 중복은 바로 이 개념적 무결성이 붕괴된 전형적 사례다. 4개의 parallel agent가 독립적으로 작업하면서, context recovery라는 하나의 개념이 9개의 서로 다른 인스턴스로 분산되었다. Plan이 "동일 패턴 적용"이라고만 기술한 것은 Brooks가 경고한 "구현자에게 아키텍처를 맡기는 실수"와 같다. Brooks의 해법은 명확하다 — **아키텍트가 구현 전에 공유 개념을 하나의 명세(specification)로 확정하고, 구현자는 그 명세를 참조해야 한다.** `references/context-recovery-protocol.md`라는 공유 파일이 바로 이 명세 역할이었어야 한다.

이 세션의 parallel agent 구조는 Brooks가 *The Mythical Man-Month* 2장 "The Mythical Man-Month"에서 분석한 커뮤니케이션 오버헤드 문제의 변형이기도 하다. Brooks는 n명의 프로그래머 간 커뮤니케이션 경로가 n(n-1)/2로 증가한다고 지적했다. 4개 agent는 서로 통신하지 않으므로 경로는 0개 — 오버헤드가 없는 것처럼 보이지만, 실제로는 통신이 **불가능**한 것이다. 통신 오버헤드의 해법이 "통신을 없앤다"가 되어서는 안 된다. Brooks의 surgical team 모델에서 외과의(chief architect)는 팀원들에게 공유 비전을 주입한다. 이 세션에서 plan이 그 역할을 했어야 하지만, "동일 적용"이라는 추상적 지시는 비전 주입이 아니라 비전의 포기였다.

#### 2. "하나를 버릴 계획을 세워라" — Compact Recovery와 결정 유실

Brooks는 11장 "Plan to Throw One Away"에서 이렇게 선언했다: "어차피 그렇게 될 테니, 미리 계획해 두는 편이 낫다(You will do it — the only question is whether to plan in advance to build a throwaway, or to promise to deliver the throwaway to customers)." 그는 첫 번째 시스템은 반드시 폐기하게 되며, 그 과정에서 배운 것이 두 번째 시스템의 설계를 이끈다고 말했다.

CDM 3의 compact recovery 결정 유실 문제를 Brooks의 렌즈로 보면 흥미로운 해석이 나온다. cwf-state.yaml의 decisions 필드가 5개 고수준 항목만 보존한 것은, compact recovery 시스템 자체가 "첫 번째 시스템(plan to throw away)"이었다는 뜻이다. S29에서 설계된 이 메커니즘은 clarify/plan 단계 기준으로 만들어졌고, impl 단계의 높은 결정 밀도는 경험하지 못한 상태였다. Brooks가 말한 대로, 첫 번째 버전은 반드시 폐기하게 된다 — **문제는 이것이 "버릴 것"이라는 인식 없이 배포되었다는 점이다.**

더 나아가, 이 세션의 사용자 피드백 "어느 순간부터 자꾸 내게 물어봐서"는 Brooks가 경고한 본질적 복잡성의 발현이다. "No Silver Bullet"에서 Brooks는 소프트웨어의 본질적 복잡성(essential complexity)과 우발적 복잡성(accidental complexity)을 구분했다. Compaction 후 결정 유실은 우발적 복잡성처럼 보이지만, 실은 **AI agent 세션의 본질적 복잡성** — 유한한 context window에서 무한히 증가하는 결정을 관리해야 한다는 본질적 모순 — 에서 비롯된다. 이것은 도구를 바꿔 해결할 문제가 아니라, 결정의 외부화(externalization)라는 아키텍처 수준의 해법이 필요하다.

#### 3. Second-System Effect의 그림자 — Plan의 과신

Brooks가 5장 "The Second-System Effect"에서 경고한 것은 이렇다: 첫 번째 시스템을 성공적으로 만든 설계자가 두 번째 시스템에서는 "첫 번째에서 못 넣은 기능을 모두 넣으려는" 유혹에 빠진다는 것이다. S32-impl에서 이 효과의 변형이 보인다. Plan이 11개의 정교한 step과 per-work-item commit 전략, 6명의 reviewer를 갖춘 이중 review까지 설계한 것은 이전 세션(S31 등)에서의 학습을 과도하게 반영한 결과로 읽힌다.

실제로 CDM 2가 보여주듯, plan의 per-work-item commit 전략은 cross-cutting 변경의 현실 앞에서 무너졌다. Brooks의 관점에서 이것은 전형적인 second-system 징후다 — **이전 경험에서 배운 교훈을 기계적으로 적용하면서, 현재 문제의 고유한 특성을 간과하는 것.** 93파일 monolithic diff의 트라우마가 "fine-grained commits"라는 교조적 규칙으로 굳어진 것이다.

그러나 동시에 인정해야 할 점이 있다. 이 세션에서 **잘 작동한 것** 역시 Brooks의 프레임워크로 설명 가능하다. 전체 파이프라인(clarify->plan->review->impl->review->fix->refactor)의 단계적 구조는 Brooks가 주장한 "설계와 구현의 명확한 분리"를 따르고 있으며, context recovery protocol이라는 공유 개념의 추출 자체(비록 뒤늦게 이루어졌지만)는 개념적 무결성을 회복하려는 올바른 움직임이었다.

---

#### 관통 분석: 설계 시점 가정의 무효화

CDM 분석이 도출한 관통 패턴 — "설계 시점 가정이 실행 시점에서 무효화되는 구조적 문제" — 은 Brooks의 핵심 통찰과 깊이 공명한다. Brooks는 *The Design of Design* (2010)에서 이렇게 정리했다: 설계는 모델 구축의 과정이며, 모든 모델은 현실의 단순화(simplification)이다. Plan이 work item 단위로 세상을 모델링하면서 cross-cutting 의존성을 생략한 것, compact recovery가 고수준 결정으로 세상을 모델링하면서 세부 결정의 밀도를 생략한 것 — 모두 같은 구조적 실패다.

Brooks라면 이렇게 말할 것이다: **"모델이 현실과 다르다는 것은 놀라운 일이 아니다. 놀라운 것은 모델이 현실과 다를 때 모델을 고치지 않는 것이다."** 이 세션에서 plan의 commit 전략이 현실과 괴리되었을 때 plan을 수정하지 않고 단일 커밋으로 pragmatic하게 대응한 것은, 단기적으로는 합리적이었으나 장기적으로는 **plan의 신뢰성을 훼손**한다. Plan이 따를 필요 없는 문서가 되면, plan 단계 자체의 존재 가치가 위협받는다.

---

**Recommendations**:

1. **Plan 단계에서 "공유 명세 우선" 원칙 도입**: Brooks의 아키텍트-구현자 분리 원칙에 따라, plan이 cross-cutting 패턴을 식별하면 반드시 공유 참조 파일의 생성을 Step 0으로 명시해야 한다. "동일 적용"이라는 지시는 금지어로 간주하고, 대신 구체적 파일 경로와 참조 방식을 명시하라. 이것이 parallel agent 구조에서 개념적 무결성을 유지하는 유일한 방법이다.

2. **Compact recovery를 "버릴 첫 번째 시스템"으로 공식 인정하고 재설계**: 현재의 5개 고수준 decisions 필드는 clarify/plan 단계에서만 유효하다. Brooks의 "plan to throw one away" 원칙에 따라, impl 단계용 recovery 전략을 별도로 설계하라. 구체적으로는 phase별 decisions 해상도를 분화하거나, impl 진행 중 발생하는 세부 결정을 즉시 외부 파일에 기록하는 "결정 저널(decision journal)" 메커니즘을 도입하라. 이것은 AI agent 세션의 **본질적 복잡성**(유한 context에서 무한 결정 관리)에 대한 구조적 응답이다.

<!-- AGENT_COMPLETE -->
