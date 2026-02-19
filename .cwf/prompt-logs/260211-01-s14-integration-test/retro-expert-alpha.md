### Expert alpha: Gojko Adzic

**Framework**: Specification by Example — 구체적인 예제를 통한 협업적 사양 정의, 사양을 살아 있는 문서(living documentation)이자 실행 가능한 테스트로 유지하는 방법론.
**Source**: *Specification by Example: How Successful Teams Deliver the Right Software* (Manning, 2011, Jolt Award 2012), *Bridging the Communication Gap* (Neuri, 2009), 그리고 2020년 "SBE 10 Years" 회고 글 (gojko.net).
**Why this applies**: S14 세션의 핵심 통찰 — "SKILL.md가 곧 사양이자 구현이다" — 는 Specification by Example의 중심 개념인 "실행 가능한 사양(executable specification)"과 "살아 있는 문서(living documentation)"의 LLM 시대 버전이다. 또한 S33 프로토콜 검증에서 사용자가 강제한 "경험적 리플레이"는 Adzic이 말하는 "핵심 예제(key examples)를 통한 검증"과 정확히 일치한다.

---

#### 1. SKILL.md = Executable Specification: 10년간 풀지 못한 문제의 해법

Adzic는 *Specification by Example*에서 50개 이상의 프로젝트를 분석하며, 성공적인 팀이 공유하는 패턴을 추출했다. 그 핵심은 "사양과 테스트가 분리되지 않는 시스템"이다. 전통적 소프트웨어에서 사양서(문서)와 구현(코드)은 항상 동기화 문제를 겪는다. Adzic은 이 갭을 줄이기 위해 "구체적 예제로 사양을 작성하고, 그 예제를 자동화된 테스트로 실행하라"고 제안했다. 그러나 2020년 10년 회고에서 Adzic 자신이 인정했듯이, "living documentation"의 약속은 완전히 실현되지 못했다 — 설문 응답자의 57%가 Jira 같은 작업 추적 도구를 요구사항 저장소로 사용하고 있었고, 사양 파일이 버전 관리에서 주변화되었다.

그런데 S14에서 발견한 사실이 바로 이 문제에 대한 해답이다. LLM 스킬 시스템에서 SKILL.md는 "동기화가 깨질 수 없는 사양"이다. 왜냐하면 SKILL.md 자체가 런타임 행동을 직접 결정하기 때문이다. 전통적 소프트웨어에서는 사양→코드→실행이라는 변환 체인에서 불일치가 발생하지만, LLM 스킬에서는 사양=코드=실행이 동일하다. Adzic가 꿈꿨던 "사양이 곧 실행 가능한 테스트"가 별도의 자동화 프레임워크(FitNesse, Cucumber 등) 없이 자연적으로 달성된 것이다.

S14 팀이 Explore 에이전트 4개를 병렬 투입하여 SKILL.md를 라인 단위로 정적 검증한 방식은, Adzic의 프레임워크로 보면 "사양서 리뷰"와 "테스트 실행"이 동시에 일어난 것이다. 46/46 체크 통과와 compact-context.sh 버그 2개 발견이라는 결과는 이 접근법의 유효성을 입증한다. Adzic의 언어로 말하면, SKILL.md는 **진정한 의미의 living documentation** — 문서가 코드와 괴리될 수 없는 구조적 보장이 있는 사양이다.

단, 한 가지 주의할 점이 있다. Adzic는 *Specification by Example*에서 "예제가 없는 사양은 검증 불가능하다"고 경고한다. S14의 정적 검증은 cross-reference 정합성(28/28 체크)과 구조적 일관성을 검증했지만, "이 SKILL.md가 실제 사용자 시나리오에서 기대한 결과를 내는가"라는 행동적 검증은 포함하지 않았다. compact-context.sh의 버그가 정적 검증에서 발견된 것은 스크립트라는 결정론적 컴포넌트였기 때문이다. SKILL.md의 LLM 해석 결과가 올바른지는 여전히 예제 기반 실행 테스트가 필요하다 — 이것이 CDM 분석이 놓친 맹점이다.

---

#### 2. 경험적 리플레이 = Key Examples를 통한 검증

CDM 2에서 사용자가 강제한 "S33 Deming 시나리오 리플레이"는 Adzic의 프레임워크에서 **key example**의 역할과 정확히 동일하다. Adzic는 *Bridging the Communication Gap* (2009)에서 "specification workshop"을 제안한다 — 비즈니스 이해관계자, 개발자, 테스터가 함께 모여 구체적인 예제를 통해 사양의 모호함을 제거하는 세션이다. 핵심 원칙은 "추상적 규칙이 아니라 구체적 예제로 대화하라"는 것이다.

S14에서 에이전트는 "S33 프로토콜이 URL 구성 규칙을 바꿨으니 404는 해결됐다"는 추상적 규칙으로 검증을 끝내려 했다. Adzic의 관점에서 이것은 "규칙만 있고 예제가 없는 사양" — 검증 불가능한 사양이다. 사용자가 강제한 리플레이는 11개의 구체적 URL이라는 key example을 통해 추상적 규칙을 검증한 것이다. 결과는 9% 성공률 — 규칙은 올바랐지만(404 해결), 규칙이 다루지 않는 실패 모드(JS 렌더링)가 예제를 통해 드러났다.

Adzic는 2020년 회고에서 중요한 관찰을 공유했다: "conversations are more important than capturing conversations is more important than automating conversations" (대화가 대화 기록보다 중요하고, 대화 기록이 대화 자동화보다 중요하다). S14에서 사용자와 에이전트 사이의 갈등 — 에이전트의 이론적 분석 vs 사용자의 경험적 리플레이 — 은 이 원칙의 위반이었다. 에이전트는 "자동화된 추론"(규칙에서 결론 도출)으로 뛰어넘으려 했지만, 사용자는 "대화"(예제를 통한 공동 검증)를 요구했다.

---

#### 3. Bottom-up 실패 분류와 Specification Workshop의 유사성

CDM 3에서 실패 데이터(5건 JS-rendered empty, 2건 403, 3건 redirect chain)가 이미 "도구 레벨 문제"를 가리키고 있었는데, 에이전트가 아키텍처 논쟁에 4턴을 소비한 것은 Adzic의 프레임워크에서 흥미로운 반면교사다.

Adzic의 specification workshop에서 가장 중요한 단계는 **"예제 분류(classifying examples)"**이다. 팀이 제시한 예제들을 유형별로 그룹화하면, 사양의 구조가 자연스럽게 드러난다. S14에서 11개 URL 실패를 유형별로 분류하는 것이 바로 이 과정이었다. 분류를 먼저 했다면 — JS-rendered가 5/11로 가장 큰 그룹 — 해결책의 방향이 "JS를 실행할 수 있는 도구"로 즉시 수렴했을 것이다.

에이전트가 분류 전에 아키텍처 논쟁을 시작한 것은, Adzic의 언어로 표현하면 "예제 없이 규칙을 논쟁한 것"이다. Sub-agent가 스킬에 접근할 수 있는가, agent team이 cwf:gather를 사용할 수 있는가 — 이런 논의는 추상적 규칙 레벨의 대화다. 11개 URL이라는 구체적 예제의 실패 유형을 먼저 분류했다면, 이 모든 아키텍처 논쟁이 무의미해진다는 것을 1턴 만에 알 수 있었다.

---

**Recommendations**:

1. **SKILL.md에 Key Examples 섹션을 추가하라.** 현재 SKILL.md는 "규칙"(LLM에 대한 지시문)만 포함한다. Adzic의 Specification by Example 원칙에 따라, 각 스킬의 기대 행동을 보여주는 구체적 입출력 예제를 SKILL.md 하단에 포함시키라. 예: `## Key Examples` 섹션에 "이 입력이 주어졌을 때, 이 출력이 기대된다"를 2-3개 명시. 이 예제들이 정적 검증의 행동적 차원을 보완하고, Adzic가 말한 "예제 없는 사양은 검증 불가능하다"는 약점을 해소한다. 더불어 이 예제들은 SKILL.md 변경 시 회귀 탐지의 기준선 역할을 한다.

2. **프로토콜 변경 후 "Replay Examples" 체크리스트를 의무화하라.** S14에서 사용자가 강제한 S33 리플레이가 WebFetch의 9% 성공률을 발견한 것은 우연이 아니다 — 구체적 예제를 통한 검증은 추상적 분석이 놓치는 실패 모드를 드러낸다. CWF 프로세스에 "프로토콜/프로세스 변경 → 기존 실패 시나리오 N개 리플레이 → 성공률 기록"을 필수 단계로 포함시키라. Adzic가 *Specification by Example*에서 강조한 "regression suite as living documentation"의 LLM 세션 버전이다. 리플레이 결과를 lessons.md에 기록하면, 향후 동일한 "이론으로 검증 완료" 편향을 구조적으로 방지할 수 있다.

<!-- AGENT_COMPLETE -->
