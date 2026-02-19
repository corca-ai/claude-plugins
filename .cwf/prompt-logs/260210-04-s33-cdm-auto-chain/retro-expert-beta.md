### Expert beta: Chris Argyris

**Framework**: Espoused theory vs theory-in-use, single-loop vs double-loop learning, defensive routines
**Source**: *Organizational Learning: A Theory of Action Perspective* (Argyris & Schön, Addison-Wesley, 1978); "Teaching Smart People How to Learn" (*Harvard Business Review*, 1991)
**Why this applies**: S33의 teaching-practicing gap — 교훈을 SKILL.md에 기록했지만 현재 세션에서 동일 문제 재발 — 은 Argyris의 "espoused theory와 theory-in-use 사이의 괴리"와 구조적으로 동일하다.

Argyris의 핵심 구분은 사람들이 **말하는 것(espoused theory)**과 **실제로 하는 것(theory-in-use)** 사이의 체계적 괴리이다. S33에서 이 패턴이 정확히 관찰된다: SKILL.md에 "commit boundary = change pattern"이라고 기록하는 것이 espoused theory이고, 실제 세션에서 batched commit으로 향하는 것이 theory-in-use이다. Argyris는 이 gap이 "개인의 의지 부족"이 아니라 **시스템의 구조적 특성**이라고 주장한다. SKILL.md를 편집하는 행위는 "다음 실행"의 입력을 변경하는 것이지, "현재 실행"의 행동 모델을 변경하는 것이 아니다.

CDM 4(check-session.sh 미실행)에서 BDD 5/5 pass 후 추가 검증을 생략한 것은 Argyris가 말하는 **single-loop learning**의 전형이다. Single-loop에서는 현재 프레임 안에서 행동을 교정한다 ("다음에는 check-session.sh를 기억하자"). **Double-loop learning**은 프레임 자체를 변경한다 — "왜 검증 스크립트가 '기억해야 할 것' 범주에 있는가? 이것을 '자동으로 실행되는 것' 범주로 이동시켜야 하지 않는가?" CDM 분석의 "규칙의 위치가 실행력을 결정한다"는 결론이 바로 double-loop — 규칙을 CLAUDE.md(espoused theory 영역)에서 impl SKILL.md 또는 cwf:run gate(theory-in-use 영역)로 이동시키는 것이다.

가장 흥미로운 관찰은 CWF 프로젝트 자체가 **double-loop learning 기계**를 만들고 있다는 점이다. CDM 분석 → 교훈 도출 → SKILL.md 구조 변경 → 다음 세션에서 구조가 행동을 강제 — 이 사이클이 Argyris가 설계하라고 권고한 "Model II" 조직 학습 패턴이다. Model II에서는 행동을 지배하는 변수(governing variables)를 변경 가능한 대상으로 취급하고, 실험과 검증을 통해 지속적으로 수정한다. CWF의 eval > state > doc 계층 구조가 바로 governing variables를 계층적으로 관리하는 시스템이다.

그러나 S33이 보여주듯, double-loop도 **한 세션의 지연(latency)**이 있다. 교훈을 구조에 기록하는 세션과 구조가 행동을 강제하는 세션 사이에 gap이 존재한다. 이 gap을 줄이는 방법은 Argyris 관점에서 명확하다: theory-in-use를 변경하는 즉시 현재 행동에도 적용하는 **실시간 반영 메커니즘**이 필요하다. Plan 템플릿에 "Commit Strategy" 필수 섹션을 추가하는 것은 이 지연을 0으로 만드는 것이 아니라, 다음 세션부터 자동 적용되게 하는 것이므로 여전히 한 세션의 지연이 있다. 현재 세션 내에서 즉시 적용하려면, plan 작성 시점에서 "SKILL.md의 최근 변경 내역"을 참조하여 관련 교훈을 plan에 자동 주입하는 메커니즘이 필요하다.

**Recommendations**:
1. **Espoused theory와 theory-in-use의 괴리를 구조적으로 제거하라**: CLAUDE.md에만 존재하는 규칙(espoused)을 cwf:run gate나 SKILL.md Phase로 이동(theory-in-use)시켜라. 규칙이 "행동을 강제하는 위치"에 있을 때만 실행된다.
2. **Double-loop의 latency를 줄여라**: Plan 작성 시 최근 세션에서 추가된 SKILL.md 변경 사항을 자동 참조하는 메커니즘을 고려하라. 이를 통해 "방금 기록한 교훈"이 "현재 세션의 plan"에 즉시 반영되어 teaching-practicing gap의 한 세션 지연을 줄일 수 있다.

<!-- AGENT_COMPLETE -->
