### Expert beta: Nancy Leveson

**Framework**: 시스템 안전 공학, STAMP/STPA (Systems-Theoretic Accident Model and Processes) -- 사고를 구성요소 고장이 아닌 부적절한 제어(inadequate control)로 모델링하고, 시스템 전체의 제어 구조(control structure)를 분석하여 위험을 식별하는 방법론
**Source**: *Engineering a Safer World: Systems Thinking Applied to Safety* (MIT Press, 2011, ISBN 978-0-262-01662-9); MIT PSASS(Partnership for Systems Approaches to Safety and Security) 연구 -- Wikipedia 및 MIT PSASS 사이트(psas.scripts.mit.edu)에서 검증 완료. Leveson은 MIT 항공우주학과 교수로, STAMP/STPA 방법론을 개발했으며, 2020년 IEEE Medal for Environmental and Safety Technologies를 수상.
**Why this applies**: S15 세션에서 발생한 병렬 에이전트 간의 파일 충돌(setup/SKILL.md 되돌림)과, 인라인 규칙의 drift 문제는 전형적인 **제어 구조 부재** 문제입니다. STAMP 관점에서 이것은 구성요소 고장이 아니라 시스템 수준의 제어 결함 -- 즉 에이전트 간 조율 메커니즘(control action)의 부재와, 규칙 일관성을 유지하는 피드백 루프(feedback loop)의 부재에서 기인합니다.

#### 분석 1: 병렬 에이전트 충돌은 "제어 구조 결함"이다

CDM 3에서 기술된 setup/SKILL.md의 되돌림 사건을 STAMP 프레임워크로 분석합니다. 전통적 관점에서는 이것을 "병렬 작업 시 발생한 우연한 충돌"로 볼 수 있지만, STAMP의 핵심 원칙은 사고를 **우연이 아닌 시스템 제어 구조의 결함**으로 재정의하는 것입니다. *Engineering a Safer World* 2장에서 Leveson은 "사고는 구성요소 고장의 연쇄(chain of failures)가 아니라, 안전 제약(safety constraint)을 시행하는 제어 구조의 부적절한 작동에서 발생한다"고 명시합니다. 이 세션에서 제어 구조를 매핑하면: (1) 사용자가 최상위 제어자(controller), (2) 병렬 에이전트들이 제어 대상(controlled process), (3) 파일 시스템이 공유 자원입니다. 문제는 **에이전트 간 파일 수준 조율을 위한 제어 동작(control action)이 정의되지 않았다**는 것입니다. Leveson의 용어로 이것은 "UCA(Unsafe Control Action)" -- 구체적으로 "필요한 제어 동작이 제공되지 않음(control action not provided)" 유형에 해당합니다. 에이전트 A가 파일을 수정할 때 에이전트 B에게 해당 파일이 수정 중임을 알리는 제어 동작이 존재하지 않았습니다.

세션에서 이에 대한 대응(충돌된 파일 없이 "안전한 커밋" 수행)은 STAMP 관점에서 합리적인 **완화(mitigation)** 조치였지만, 근본 원인인 제어 구조 자체는 수정되지 않았습니다. Leveson의 STPA 4단계(인과 시나리오 식별)에 따르면, 이 UCA의 원인은 에이전트 간 피드백 채널의 부재입니다 -- 에이전트 B가 에이전트 A의 파일 수정 상태를 관찰할 수 있는 프로세스 모델(process model)이 없었습니다.

#### 분석 2: 인라인 규칙의 drift는 "피드백 루프 단절"이다

CDM 1에서 기술된 인라인 웹 연구 규칙의 drift 현상은 STAMP의 제어 이론 관점에서 **피드백 루프 단절(feedback loop degradation)**의 전형적 사례입니다. *Engineering a Safer World* 4장에서 Leveson은 "안전 제약은 시간이 지남에 따라 침식된다(safety constraints erode over time)"고 설명하며, 이를 방지하려면 제어 구조에 지속적인 피드백이 필요하다고 강조합니다. 인라인 규칙은 본질적으로 **개방 루프(open-loop)** 제어입니다 -- 한 번 작성된 후 환경 변화(agent-browser 도입)를 감지하고 반영하는 메커니즘이 없습니다. 반면 agent-patterns.md의 공유 프로토콜을 참조하는 방식은 **폐쇄 루프(closed-loop)** 제어로의 전환입니다 -- SSOT(Single Source of Truth)를 업데이트하면 모든 참조자가 자동으로 최신 상태를 반영합니다.

CDM 2의 결정 -- 실패한 2개 에이전트만이 아니라 웹 연구를 수행하는 7개 에이전트 전체에 프로토콜 참조를 적용한 것 -- 은 STAMP 관점에서 매우 올바른 접근입니다. Leveson은 *Engineering a Safer World* 3장에서 "hazard analysis는 이미 발생한 사고뿐 아니라, 아직 발생하지 않은 위험한 상태(hazardous state)까지 식별해야 한다"고 강조합니다. 저빈도 에이전트가 아직 실패하지 않았다는 것은 안전하다는 의미가 아니라, **아직 위험한 조건에 노출되지 않았다**는 의미일 뿐입니다. 전체 카테고리에 제어를 적용한 것은 정확히 이 원칙을 실천한 것입니다.

#### 분석 3: "안전한 커밋" 전략의 시스템 안전 평가

CDM 3에서 setup/SKILL.md 충돌 시 재편집 대신 해당 파일 없이 커밋한 결정은, Leveson의 프레임워크에서 **설계 시간 안전 제약(design-time safety constraint)**과 **운영 시간 대응(operational response)**의 구분으로 분석할 수 있습니다. 운영 시간에 "안전한 커밋"을 선택한 것은 적절한 즉각 대응이었습니다. 그러나 STAMP은 항상 "왜 이 제어 동작이 필요했는가?"를 묻습니다. 답은: 설계 시간에 병렬 에이전트의 파일 접근을 조율하는 안전 제약이 부재했기 때문입니다. 운영 시간 대응이 아무리 효과적이어도, 설계 수준의 안전 제약 없이는 동일한 유형의 충돌이 반복될 수밖에 없습니다.

**권고사항**:

1. **병렬 에이전트 제어 구조 설계**: STPA를 적용하여 병렬 에이전트 실행의 제어 구조를 명시적으로 정의하십시오. 구체적으로: (a) 각 에이전트가 수정할 파일 범위를 사전에 선언하는 제어 동작, (b) 파일 충돌 시 에이전트 간 통신을 위한 피드백 채널, (c) 충돌 감지 시 자동 중단 또는 병합을 위한 안전 제약. 이는 *Engineering a Safer World* 8장의 "safety control structure"를 소프트웨어 에이전트 도메인에 적용하는 것입니다. 파일 잠금(lock) 같은 단순한 메커니즘이라도, 명시적 제어 구조가 없는 현재 상태보다 훨씬 안전합니다.

2. **인라인 규칙 drift 감지를 위한 폐쇄 루프 구축**: 현재 인라인 규칙에서 공유 프로토콜 참조로의 전환은 올바르지만, 한 단계 더 나아가 drift를 **능동적으로 감지**하는 피드백 메커니즘을 구축하십시오. 예를 들어: cwf:review 또는 cwf:retro 단계에서 각 스킬 프롬프트가 공유 프로토콜(agent-patterns.md)을 올바르게 참조하고 있는지 자동 검증하는 체크를 추가합니다. Leveson은 "안전 제약의 침식은 점진적이고 보이지 않는다"고 경고합니다 -- 따라서 수동 감사가 아닌 자동화된 피드백이 필요합니다. 이는 *Engineering a Safer World* 12장의 "leading indicators of safety" 개념의 적용입니다.

<!-- AGENT_COMPLETE -->
