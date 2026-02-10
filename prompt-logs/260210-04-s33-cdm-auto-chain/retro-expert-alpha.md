### Expert alpha: W. Edwards Deming

**Framework**: System of Profound Knowledge — 시스템 사고, common cause vs special cause variation, 프로세스에 품질 내장
**Source**: *Out of the Crisis* (MIT Press, 1986), Point 3: "Cease dependence on inspection to achieve quality"; PDCA (Plan-Do-Check-Act) cycle
**Why this applies**: S33의 핵심 패턴 — 관행(convention)이 반복적으로 실패하고 구조(structure)로 승격해야 효과적 — 은 Deming의 "시스템을 바꿔야 결과가 바뀐다" 철학과 정확히 일치한다.

S33에서 가장 주목할 현상은 CDM 3의 self-referential irony이다: commit strategy branching을 코드화하는 바로 그 세션에서 commit strategy 문제가 재발했다. Deming의 variation 분류로 보면, 이것은 **common cause variation**이다. Agent가 "이번에 실수했다"가 아니라, plan 템플릿에 commit strategy 섹션이 없는 시스템 구조가 매 세션마다 동일한 실패를 생산하는 것이다. Common cause에 대한 올바른 대응은 개인을 교정하는 것이 아니라 시스템을 변경하는 것 — CDM 분석의 "plan 템플릿에 Commit Strategy 필수 섹션 추가" 권고가 바로 Deming식 해법이다.

check-session.sh 미실행(CDM 4)은 Deming의 Point 3 — "검사(inspection)에 의존하지 말고 품질을 프로세스에 내장하라" — 의 역설적 적용이다. check-session.sh 자체는 검사 도구이므로, Deming 관점에서 진정한 해결책은 check-session.sh를 실행하는 것이 아니라 check-session.sh가 발견하는 누락이 **구조적으로 발생할 수 없도록** 워크플로우를 설계하는 것이다. cwf:run에 자동 gate로 통합하면 검사가 프로세스의 일부가 되어, "기억해서 실행해야 하는 별도 행위"에서 "워크플로우가 자동으로 수행하는 내장 행위"로 전환된다. 이것이 Deming이 말하는 "build quality into the product in the first place"이다.

반면, CDM 1의 lightweight clarify 결정은 Deming의 PDCA 성숙도를 보여준다. S32의 retro(Check)가 높은 품질로 수행되었기 때문에 S33의 clarify(Plan)를 경량화할 수 있었다. 이전 사이클의 Check 품질이 다음 사이클의 Plan 효율성을 결정하는 이 패턴은 PDCA 순환이 세션 단위로 작동하고 있음을 보여준다. Deming은 이를 "지식의 심화(profound knowledge)"라고 부를 것이다 — 프로세스에 대한 이론(theory)이 축적되면서 불필요한 단계를 제거할 수 있게 되는 것이다.

**Recommendations**:
1. **Common cause를 special cause로 착각하지 말 것**: 동일 패턴이 2회 이상 발생하면 (commit strategy 재발처럼), 개인 행동 교정이 아닌 시스템 구조 변경으로 대응하라. Plan 템플릿의 필수 섹션 추가, cwf:run의 자동 gate가 시스템 변경이다.
2. **검사를 프로세스에 내장하라**: check-session.sh를 "기억해서 실행하는 것"에서 cwf:run의 retro 후 자동 실행 gate로 이동시켜라. 검사가 워크플로우의 필수 단계가 되면, 규칙 위반이 구조적으로 불가능해진다.

<!-- AGENT_COMPLETE -->
