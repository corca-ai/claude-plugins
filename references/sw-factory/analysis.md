# 소프트웨어 팩토리와 에이전틱 모멘트: 심층 분석 리포트

> **원문 1**: Simon Willison, "How StrongDM's AI team build serious software without even looking at the code" (2026.02.07)
> **원문 2**: StrongDM AI, "Software Factories and the Agentic Moment" (2026.02.06) + Techniques 페이지
> **분석일**: 2026.02.08

---

## I. 전문 번역

### A. Simon Willison 블로그 전문 번역

#### StrongDM의 AI 팀은 어떻게 코드를 보지도 않고 진지한 소프트웨어를 만드는가

2026년 2월 7일

지난주 나는 Dan Shapiro가 **Dark Factory**(암흑 공장)이라 부른 AI 도입 단계 — 즉, 코딩 에이전트가 생산하는 코드를 인간이 *보지도 않는* 단계 — 를 구현하고 있는 팀의 데모를 봤다고 암시한 바 있다. 그 팀은 StrongDM 소속이었고, 그들은 이제 자신들의 작업 방식을 처음으로 공개적으로 설명한 글 "Software Factories and the Agentic Moment"를 발표했다:

> 우리는 **소프트웨어 팩토리**를 만들었다: 스펙 + 시나리오가 에이전트를 구동하여 코드를 작성하고, 하네스를 실행하고, 인간의 리뷰 없이 수렴하는 비-대화형(non-interactive) 개발 방식이다. [...]
>
> 공안(公案, kōan) 또는 만트라 형태로:
>
> * 왜 내가 이걸 하고 있지? (함의: 모델이 대신 해야 하는 거 아닌가)
>
> 규칙 형태로:
>
> * 코드는 인간이 작성해서는 **안 된다**
> * 코드는 인간이 리뷰해서는 **안 된다**
>
> 마지막으로 실용적 형태로:
>
> * 오늘 엔지니어 1인당 최소 **토큰에 1,000달러**를 쓰지 않았다면, 당신의 소프트웨어 팩토리는 개선의 여지가 있다

나는 이것들 중 가장 흥미로운 것은 의심의 여지 없이 "코드는 인간이 리뷰해서는 **안 된다**"라고 생각한다. LLM이 비인간적 실수(inhuman mistakes)를 저지르기 쉽다는 것을 우리 모두가 알고 있는 상황에서, 어떻게 이것이 합리적인 전략이 *될 수* 있을까?

최근 많은 개발자들이 **2025년 11월 변곡점**을 인정하고 있다 — Claude Opus 4.5와 GPT 5.2가 코딩 에이전트의 지시 이행 신뢰도와 복잡한 코딩 작업 수행 능력에서 전환점을 찍은 시기다. StrongDM의 AI 팀은 Claude Sonnet 3.5와 관련된 더 이른 변곡점에 기반하여 2025년 7월에 창설되었다:

> 촉매는 2024년 후반에 관찰된 전환이었다: Claude 3.5의 두 번째 리비전(2024년 10월)과 함께, 장기 수평선(long-horizon) 에이전틱 코딩 워크플로가 오류를 누적하는 대신 정확성을 복리로 축적하기 시작했다.
>
> 2024년 12월까지, 이 모델의 장기 수평선 코딩 성능은 Cursor의 YOLO 모드를 통해 부인할 수 없는 것이 되었다.

그들의 새 팀은 "손수 코딩한 소프트웨어 없음"이라는 규칙으로 시작했다 — 2025년 7월에는 급진적이었지만, 2026년 1월 현재 상당수의 경험 많은 개발자들이 채택하기 시작한 방식이다.

그들은 금세 명백한 문제에 부딪혔다: 아무것도 손수 작성하지 않는다면, 코드가 실제로 작동하는지 어떻게 보장할 것인가? 에이전트에게 테스트를 작성시키는 것은, 그것들이 `assert true`로 치팅하지 않는 한에서만 도움이 된다.

이것은 현재 소프트웨어 개발에서 가장 중대한 질문처럼 느껴진다: 구현과 테스트 모두 코딩 에이전트가 대신 작성한다면, 당신이 만들고 있는 소프트웨어가 작동한다는 것을 어떻게 *증명*할 수 있는가?

StrongDM의 답은 **시나리오 테스팅**(Cem Kaner, 2003)에서 영감을 받았다. StrongDM이 설명하는 바로는:

> 우리는 **시나리오(scenario)**라는 단어를 재정의하여, 종종 코드베이스 바깥에(머신러닝 훈련의 "홀드아웃" 세트와 유사하게) 저장되는 종단 간(end-to-end) "사용자 스토리"를 나타내도록 했으며, 이는 LLM이 직관적으로 이해하고 유연하게 검증할 수 있는 것이다.
>
> 우리가 키우는(grow) 소프트웨어의 상당 부분이 에이전틱 구성요소를 가지고 있기 때문에, 우리는 성공의 불리언(boolean) 정의("테스트 스위트가 그린이다")에서 확률적이고 경험적인 정의로 전환했다. 우리는 이 검증을 정량화하기 위해 **만족도(satisfaction)**라는 용어를 사용한다: 모든 시나리오를 관통하는 모든 관찰된 궤적(trajectory) 중에서, 그것들 중 어느 비율이 사용자를 만족시킬 가능성이 높은가?

시나리오를 홀드아웃 세트로 취급하는 아이디어 — 소프트웨어를 평가하는 데 사용되지만 코딩 에이전트가 볼 수 있는 곳에 저장되지 않는 — 는 *매혹적*이다. 이것은 외부 QA 팀에 의한 공격적 테스팅을 모방한다 — 전통적 소프트웨어에서 품질을 보장하는 비싸지만 매우 효과적인 방법이다.

이것은 StrongDM의 **디지털 트윈 유니버스(Digital Twin Universe)** 개념으로 이어진다 — 내가 본 데모에서 가장 강한 인상을 남긴 부분이다.

그들이 구축하고 있던 소프트웨어는 연결된 서비스 제품군에 걸쳐 사용자 권한을 관리하는 것이었다. 이 자체가 주목할 만했다 — 보안 소프트웨어는 리뷰되지 않은 LLM 코드로 구축될 것이라고 가장 마지막에 기대할 것이다!

> [디지털 트윈 유니버스는] 우리 소프트웨어가 의존하는 서드파티 서비스의 행동 복제체(behavioral clone)다. 우리는 Okta, Jira, Slack, Google Docs, Google Drive, Google Sheets의 트윈을 만들어, 그들의 API, 엣지 케이스, 관찰 가능한 행동을 복제했다.
>
> DTU를 사용하면, 우리는 프로덕션 한계를 훨씬 초과하는 볼륨과 속도로 검증할 수 있다. 실제 서비스에 대해서는 위험하거나 불가능했을 실패 모드를 테스트할 수 있다. 레이트 리밋에 걸리거나, 남용 탐지를 트리거하거나, API 비용이 누적되는 것 없이 시간당 수천 개의 시나리오를 실행할 수 있다.

Okta, Jira, Slack 등의 중요한 부분을 어떻게 복제하는가? 코딩 에이전트로!

내가 이해한 바로는, 그 트릭은 사실상 해당 서비스의 전체 공개 API 문서를 에이전트 하네스에 덤프하고, 그 API의 모방체를 자립형(self-contained) Go 바이너리로 구축시키는 것이었다. 그런 다음 그 위에 간소화된 UI를 구축시켜 시뮬레이션을 완성할 수 있었다.

자체적이고 독립적인 서비스 복제체 — 레이트 리밋이나 사용 쿼터에서 자유로운 — 를 가지고, 시뮬레이션된 테스터 군단이 *미친 듯이* 돌아갈 수 있었다. 그들의 시나리오 테스트는 에이전트가 새 시스템이 구축되는 동안 끊임없이 실행하는 스크립트가 되었다.

유용한 Slack 부분 복제체를 빠르게 구동할 수 있는 이 능력은, 이 새로운 세대의 코딩 에이전트 도구가 얼마나 파괴적일 수 있는지를 보여준다:

> 중요한 SaaS 애플리케이션의 고충실도(high-fidelity) 복제체를 만드는 것은 항상 가능했지만, 경제적으로는 한 번도 실현 가능하지 않았다. 세대에 걸친 엔지니어들이 테스트할 CRM의 완전한 인메모리 복제본을 *원했을* 수 있지만, 그것을 구축하자는 제안 자체를 스스로 검열했다.

테크닉 페이지도 살펴볼 가치가 있다. 디지털 트윈 유니버스 외에도 그들은 **Gene Transfusion**(유전자 수혈 — 에이전트가 기존 시스템에서 패턴을 추출하여 다른 곳에서 재사용하게 하는 것), **Semports**(의미적 포팅 — 한 언어에서 다른 언어로 코드를 직접 포팅), **Pyramid Summaries**(피라미드 요약 — 에이전트가 짧은 것을 빠르게 열거하고 필요할 때 더 상세한 정보로 확대할 수 있도록 여러 수준의 요약을 제공)와 같은 용어를 도입한다.

StrongDM AI는 또한 적절히 비전통적인 방식으로 소프트웨어를 공개했다.

github.com/strongdm/attractor는 **Attractor** — 소프트웨어 팩토리의 심장부에 있는 비-대화형 코딩 에이전트다. 단, 리포지토리 자체에는 코드가 전혀 없고 — 소프트웨어의 스펙을 세세히 기술하는 마크다운 파일 세 개와, 당신이 선택한 코딩 에이전트에 이 스펙을 넣으라는 README의 메모만 있을 뿐이다!

github.com/strongdm/cxdb는 더 전통적인 공개물로, 16,000줄의 Rust, 9,500줄의 Go, 6,700줄의 TypeScript가 있다. 이것은 그들의 "AI Context Store" — 대화 이력과 도구 출력을 불변 DAG에 저장하는 시스템이다.

#### 미래의 한 모습?

나는 2025년 10월, 소규모 초대 손님 그룹의 일원으로 StrongDM AI 팀을 방문했다.

Justin McCarthy, Jay Taylor, Navan Chauhan 세 명으로 구성된 팀은 불과 세 달 전에 결성되었는데, 이미 코딩 에이전트 하네스, 반다스 서비스의 디지털 트윈 유니버스 복제체, 시나리오를 실행하는 시뮬레이션된 테스트 에이전트 떼의 작동 데모를 가지고 있었다. 그리고 이것은 그 데모 한 달 후 에이전틱 코딩의 신뢰성을 크게 높인 Opus 4.5/GPT 5.2 출시 *이전*이었다.

이것은 소프트웨어 개발의 한 가능한 미래를 엿보는 것 같았다 — 소프트웨어 엔지니어가 코드를 구축하는 것에서, 코드를 구축하는 시스템을 구축하고 반(半)-모니터링하는 것으로 이동하는 미래. 암흑 공장(The Dark Factory).

---

### B. StrongDM "Software Factories and the Agentic Moment" 전문 번역

#### 소프트웨어 팩토리와 에이전틱 모멘트

2026년 2월 6일 · Justin McCarthy

우리는 **소프트웨어 팩토리**를 만들었다: 스펙 + 시나리오가 에이전트를 구동하여 코드를 작성하고, 하네스를 실행하고, 인간의 리뷰 없이 수렴하는 비-대화형 개발.

서사적 형태는 아래에 포함한다. 제일 원리(first principles)에서 작업하는 것을 선호한다면, 반복적으로 적용하면 어떤 팀이든 같은 직관, 확신, 그리고 궁극적으로 자신만의 팩토리로 가속시킬 몇 가지 제약과 가이드라인을 제공한다. 공안(kōan) 또는 만트라 형태로:

* 왜 내가 이걸 하고 있지? (함의: 모델이 대신 해야 하는 거 아닌가)

규칙 형태로:

* 코드는 인간이 작성해서는 **안 된다**
* 코드는 인간이 리뷰해서는 **안 된다**

마지막으로 실용적 형태로:

* 오늘 엔지니어 1인당 최소 **토큰에 1,000달러**를 쓰지 않았다면, 당신의 소프트웨어 팩토리는 개선의 여지가 있다

#### StrongDM AI 이야기

2025년 7월 14일, Jay Taylor와 Navan Chauhan이 나(Justin McCarthy, 공동창업자, CTO)와 함께 StrongDM AI 팀을 창설했다.

촉매는 2024년 후반에 관찰된 전환이었다: Claude 3.5의 두 번째 리비전(2024년 10월)과 함께, 장기 수평선 에이전틱 코딩 워크플로가 오류를 누적하는 대신 정확성을 복리로 축적하기 시작했다.

2024년 12월까지, 이 모델의 장기 수평선 코딩 성능은 Cursor의 YOLO 모드를 통해 부인할 수 없는 것이 되었다.

이 모델 개선 이전에는, LLM을 코딩 작업에 반복적으로 적용하면 상상 가능한 모든 종류의 오류(오해, 환각, 구문, 버전, DRY 위반, 라이브러리 비호환 등)가 축적되었다. 앱이나 제품은 쇠퇴하고 궁극적으로 "붕괴"할 것이다: 천 개의 칼에 베여 죽는 격.

YOLO 모드와 함께, Anthropic의 업데이트된 모델은 우리가 내부적으로 **비-대화형** 개발 또는 **성장된(grown)** 소프트웨어라고 부르는 것의 첫 번째 희미한 빛을 제공했다.

#### 다이얼을 찾아서 11로 올려라

AI 팀의 첫날 첫 시간에, 우리는 일련의 발견(우리가 "잠금해제(unlocks)"라 부르는)으로 이끄는 경로를 설정하는 헌장을 수립했다. 되돌아보면, 헌장 문서에서 가장 중요한 줄은 다음이었다:

> **손으로 코딩한 소프트웨어 없음(No hand-coded software)**

처음에는 단지 직감이었다. 실험. 손으로 코드를 전혀 쓰지 않고 얼마나 멀리 갈 수 있을까?

별로 멀리 가지 못했다! 최소한: 테스트를 추가하기 전까지는. 그러나 즉각적 과업에 집착하는 에이전트는 곧 지름길을 택하기 시작했다: **return true**는 좁게 작성된 테스트를 통과하는 훌륭한 방법이지만, 당신이 원하는 소프트웨어로 일반화되지는 않을 것이다.

테스트만으로는 충분하지 않았다. 통합 테스트는? 회귀 테스트는? 종단 간 테스트는? 행위 테스트는?

#### 테스트에서 시나리오와 만족도로

에이전틱 모멘트의 반복되는 주제 하나: 우리에게는 새로운 언어가 필요하다. 예를 들어, "테스트"라는 단어는 불충분하고 모호하다는 것이 증명되었다. 코드베이스에 저장된 테스트는 코드에 맞춰 느슨하게 다시 작성될 수 있다. 코드는 테스트를 사소하게 통과하도록 다시 작성될 수 있다.

우리는 **시나리오**라는 단어를 재정의하여, 종종 코드베이스 바깥에(머신러닝 훈련의 "홀드아웃" 세트와 유사하게) 저장되는 종단 간 "사용자 스토리"를 나타내도록 했으며, 이는 LLM이 직관적으로 이해하고 유연하게 검증할 수 있는 것이다.

우리가 키우는 소프트웨어의 상당 부분이 에이전틱 구성요소를 가지고 있기 때문에, 우리는 성공의 불리언 정의("테스트 스위트가 그린이다")에서 확률적이고 경험적인 정의로 전환했다. 우리는 이 검증을 정량화하기 위해 **만족도**라는 용어를 사용한다: 모든 시나리오를 관통하는 모든 관찰된 궤적 중에서, 그것들 중 어느 비율이 사용자를 만족시킬 가능성이 높은가?

#### 디지털 트윈 유니버스에서의 시나리오 검증

이전 체제에서, 팀은 통합 테스트, 회귀 테스트, UI 자동화에 의존하여 "작동하는가?"에 답했을 수 있다.

우리는 이전에 신뢰할 수 있었던 기법의 두 가지 한계를 발견했다:

1. **테스트는 너무 경직되어 있다** — 우리는 에이전트로 코딩하고 있었지만, LLM과 에이전트 루프를 설계 원시 요소로 사용하여 구축하기도 했다; 성공 평가에는 종종 LLM-as-judge가 필요했다
2. **테스트는 리워드 해킹될 수 있다** — 모델의 치팅에 덜 취약한 검증이 필요했다

디지털 트윈 유니버스는 우리의 답이다: 우리 소프트웨어가 의존하는 서드파티 서비스의 행동 복제체. 우리는 Okta, Jira, Slack, Google Docs, Google Drive, Google Sheets의 트윈을 만들어, 그들의 API, 엣지 케이스, 관찰 가능한 행동을 복제했다.

DTU를 사용하면, 프로덕션 한계를 훨씬 초과하는 볼륨과 속도로 검증할 수 있다. 실제 서비스에 대해서는 위험하거나 불가능했을 실패 모드를 테스트할 수 있다. 레이트 리밋에 걸리거나, 남용 탐지를 트리거하거나, API 비용이 누적되는 것 없이 시간당 수천 개의 시나리오를 실행할 수 있다.

#### 비전통적 경제학

DTU에서의 우리 성공은 에이전틱 모멘트가 소프트웨어의 경제학을 근본적으로 바꾼 여러 방식 중 하나를 예시한다. 중요한 SaaS 애플리케이션의 고충실도 복제체를 만드는 것은 항상 가능했지만, 경제적으로는 한 번도 실현 가능하지 않았다. 세대에 걸친 엔지니어들이 테스트할 CRM의 완전한 인메모리 복제본을 *원했을* 수 있지만, 그것을 구축하자는 제안 자체를 스스로 검열했다. 매니저에게 가져가지도 않았다. 답이 아니오일 것을 알았으니까.

소프트웨어 팩토리를 건설하는 우리는 **의도적 순진함(deliberate naivete)**을 실천해야 한다: Software 1.0의 습관, 관습, 제약을 찾아 제거하는 것. DTU는 6개월 전에는 상상 불가능했던 것이 이제 일상이 되었다는 우리의 증거다.

---

### C. Techniques 페이지 전문 번역

#### 테크닉

소프트웨어 팩토리로 구축하면서 자주 돌아가는 패턴들

**디지털 트윈 유니버스(DTU)**: 핵심적 서드파티 의존성의 외부에서 관찰 가능한 행동을 복제한다. 결정론적이고 재생 가능한 테스트 조건으로, 프로덕션 한계를 훨씬 초과하는 볼륨과 속도로 검증한다.

**Gene Transfusion(유전자 수혈)**: 에이전트에게 구체적 모범 사례를 가리켜 코드베이스 간에 작동하는 패턴을 이동시킨다. 좋은 참조와 쌍을 이룬 솔루션은 새로운 맥락에서 재현될 수 있다.

**파일시스템**: 모델은 리포지토리를 빠르게 탐색하고 파일을 읽고 씀으로써 자신의 컨텍스트를 조절할 수 있다. 디렉토리, 인덱스, 디스크 상의 상태가 실용적인 메모리 기질(substrate)이 된다.

**Shift Work(교대 근무)**: 대화형 작업과 완전히 명세된 작업을 분리한다. 의도가 완전할 때(스펙, 테스트, 기존 앱), 에이전트는 주고받음 없이 처음부터 끝까지 실행할 수 있다.

**Semport(의미적 포팅)**: 의미론적으로 인지하는 자동 포팅. 일회성이거나 지속적. 의도를 보존하면서 언어 또는 프레임워크 간에 코드를 이동한다.

**Pyramid Summaries(피라미드 요약)**: 여러 확대 수준에서의 가역적 요약. 전체 세부 정보로 다시 확장할 수 있는 능력을 잃지 않고 컨텍스트를 압축한다.

#### 검증 제약

손으로 작성한 코드 제로, 전통적 리뷰 제로가 주어지면, 우리는 다음을 할 수 있는 시스템이 필요했다:

* 자연어 명세의 연쇄(cascade)로부터 성장하기
* 소스의 의미론적 검사 없이 자동으로 검증되기

코드는 ML 모델 스냅샷과 유사하게 취급되었다: 정확성이 오직 외부에서 관찰 가능한 행동으로만 추론되는 불투명한 가중치. 내부 구조는 불투명한 것으로 취급된다.

---

## II. 첫 소회 — 허심탄회한 감상

읽자마자 느낀 것은 **전율**이었다. 이 글은 단순한 기술 블로그 포스트가 아니다. 소프트웨어 공학의 인식론적 전환을 선언하는 일종의 매니페스토다.

핵심 직관은 이렇다: 코드란 것이 *읽어야 할 텍스트*가 아니라, ML 모델의 가중치처럼 *관찰을 통해서만 판정되는 불투명한 산출물*이라고 재정의하는 것. 이것은 소프트웨어 엔지니어의 정체성 — "나는 코드를 쓰고 읽는 사람이다" — 에 대한 근본적 도발이다.

동시에 위험한 섣부름도 감지된다. 세 명이서 세 달 만에 보안 소프트웨어를 만들었다는 것은 인상적이지만, 프로덕션에서 어떤 실패 모드가 나타날지는 아직 증명되지 않았다. "코드를 보지 않는다"는 선언이 아무리 매혹적이어도, 이것이 보편적으로 확장 가능한 전략인지, 아니면 특정 도메인과 팀 구성에서만 작동하는 예외적 사례인지는 구분해야 한다.

그러나 이 회의를 표하면서도, *방향 자체는 맞다*는 강한 직감이 있다. 테스트의 의미를 boolean에서 확률적 스펙트럼으로 재정의하는 것, 홀드아웃 세트 개념을 소프트웨어 검증에 적용하는 것 — 이것들은 단순한 기법이 아니라 패러다임의 전환이다.

---

## III. 의미 덩어리별 인용 및 심층 풀이

### 덩어리 1: "Compounding correctness rather than error"

> "The catalyst was a transition observed in late 2024: with the second revision of Claude 3.5 (October 2024), long-horizon agentic coding workflows began to compound correctness rather than error."

**풀이**: 이 문장은 전체 논의의 물리적 기반이다. "compounding"이라는 단어의 선택이 의도적이다. 금융의 복리(compound interest)를 환기시킨다 — 이자가 이자를 낳듯, 에이전트의 정확한 코드가 이후 단계의 정확한 코드를 낳는다. 그 이전에는 오류가 오류를 낳아 붕괴(collapse)로 갔다.

이것은 비선형 시스템의 **안정성 경계(stability boundary)** 문제다. 물리학에서 말하면, 시스템이 어떤 임계점을 넘으면 양의 되먹임 루프가 발산(diverge)하는 대신 수렴(converge)하기 시작한다. StrongDM은 Claude 3.5의 2024년 10월 리비전에서 이 상전이(phase transition)를 관찰했다고 주장하는 것이다.

"long-horizon"이라는 수식어가 중요하다. 한 턴의 코드 생성은 이전에도 잘 됐다. 문제는 수십~수백 턴에 걸친 누적 작업이었다. 이것이 바뀌었다는 주장이 이 전체 체계의 전제(前提)다.

### 덩어리 2: "Code must not be reviewed by humans" — 공안(kōan)으로서의 규칙

> "In kōan or mantra form: Why am I doing this? (implied: the model should be doing this instead)"

**풀이**: Justin McCarthy가 이 규칙들의 형태를 **공안(kōan)**이라고 명시한 것은 단순한 수사가 아니다. 선불교의 공안은 논리적 사유로는 도달할 수 없는 깨달음을 유도하는 역설적 질문이다. "왜 내가 이걸 하고 있지?"는 프로그래머의 직업적 정체성에 대한 실존적 질문이다.

"Code **must not be** reviewed by humans"는 의도적 도발이다. 코드 리뷰는 소프트웨어 공학의 가장 신성한 관행 중 하나다 — Fagan의 1976년 인스펙션 이래로. 이것을 부정하는 것은 단순한 프로세스 변경이 아니라, 소프트웨어 품질에 대한 인식론 자체를 바꾸는 것이다.

실용적 형태("토큰에 1,000달러")는 추상적 원칙을 구체적 행동 지표로 고정시킨다. 이것은 물질적이고 측정 가능한 기준이다 — 당신이 이 철학을 실천하고 있는지 아닌지를 매일 확인할 수 있는.

### 덩어리 3: 홀드아웃 세트로서의 시나리오

> "We repurposed the word scenario to represent an end-to-end 'user story', often stored outside the codebase (similar to a 'holdout' set in model training), which could be intuitively understood and flexibly validated by an LLM."

**풀이**: 이것이 이 글의 가장 결정적인 지적 도약이다.

**Cem Kaner의 시나리오 테스팅**(2003)은 원래 인간 테스터를 위한 것이었다. Kaner는 시나리오 테스트의 이상적 특성으로 (a) 스토리이고, (b) 동기 부여적이고, (c) 신뢰할 수 있고, (d) 복잡하고, (e) 평가하기 쉬운 것을 꼽았다. 그의 유명한 "postage stamp bug" 사례 — 단순한 기능 테스트 보고서는 무시되었지만, Girl Scout 뉴스레터 어머니의 스토리는 이해관계자를 움직였다 — 는 테스트가 단순한 참/거짓이 아니라 *서사*여야 한다는 통찰이었다.

StrongDM이 여기서 한 것은 이중 전환이다:
1. 인간 테스터의 시나리오를 **LLM 에이전트**가 실행하고 평가하도록 전환
2. 시나리오를 코드베이스 밖에 저장하여 ML의 **홀드아웃 세트** 개념을 차용

홀드아웃 세트는 머신러닝에서 모델이 훈련 중 볼 수 없는 데이터로, 일반화 성능을 평가하는 데 쓰인다. 코딩 에이전트가 테스트 코드와 구현 코드를 모두 볼 수 있다면, 테스트를 "속이는" 최적화(reward hacking)가 가능하다. 시나리오를 에이전트의 시야 밖에 두는 것은 이 문제에 대한 구조적 해법이다.

### 덩어리 4: Boolean에서 Satisfaction 스펙트럼으로

> "We transitioned from boolean definitions of success ('the test suite is green') to a probabilistic and empirical one. We use the term satisfaction to quantify this validation: of all the observed trajectories through all the scenarios, what fraction of them likely satisfy the user?"

**풀이**: "테스트 스위트가 그린이다"는 이진적(binary) 판정이다. 이것은 결정론적 소프트웨어에서는 작동하지만, 에이전틱 구성요소가 포함된 소프트웨어에서는 작동하지 않는다 — 같은 입력에도 매번 다른 궤적(trajectory)이 가능하기 때문이다.

**만족도(satisfaction)**라는 용어의 선택이 의미심장하다. 이것은 Herbert Simon의 "satisficing"(만족화 — satisfy + suffice의 합성어, 1956)을 환기시킨다. 최적해를 찾는 것이 아니라, 충분히 좋은 해를 찾는 것. 또한 통계적 가설검정의 프레임을 닮았다: 단일 테스트의 통과/실패가 아니라, 반복 관찰의 *분포*에서 결론을 추론한다.

이것은 코드가 "작동한다/안 한다"의 이진법에서 "이 정도의 확률로 사용자를 만족시킨다"라는 연속체(continuum)로의 전환이다. 소프트웨어 품질의 양자역학적 재해석이라 할 만하다.

### 덩어리 5: 디지털 트윈 유니버스와 "의도적 순진함"

> "Creating a high fidelity clone of a significant SaaS application was always possible, but never economically feasible. Generations of engineers may have wanted a full in-memory replica of their CRM to test against, but self-censored the proposal to build it."

**풀이**: "self-censored"라는 표현이 날카롭다. 이것은 단순한 비용 문제가 아니라 *인식론적 검열*이다. 엔지니어들은 기술적으로 가능한 것을 경제적으로 불가능하다고 *내면화*한 나머지, 제안 자체를 하지 않았다.

"deliberate naivete"(의도적 순진함)는 이 내면화된 제약을 의식적으로 벗겨내는 행위다. 선(禪)의 "초심(初心, beginner's mind)"과 유사하다 — 전문가가 된 후에야 비로소 초보자의 눈으로 볼 필요성을 느끼는 역설.

**디지털 트윈**이라는 개념 자체는 제조업에서 온다 — 물리적 시스템의 디지털 복제체를 만들어 시뮬레이션하는 것. StrongDM은 이 개념을 *소프트웨어 서비스*에 적용했다. Okta, Jira, Slack의 API를 행동적으로 복제한 Go 바이너리를 만든 것이다. 이것이 가능해진 것은 에이전트가 방대한 API 문서를 읽고 구현할 수 있게 되었기 때문이다.

### 덩어리 6: 코드를 불투명한 가중치로 취급

> "Code was treated analogously to an ML model snapshot: opaque weights whose correctness is inferred exclusively from externally observable behavior. Internal structure is treated as opaque."

**풀이**: 이것은 글 전체에서 가장 급진적인 명제다. 소프트웨어 공학의 역사 전체가 코드의 *가독성*과 *이해 가능성*을 추구해온 것이다 — Dijkstra의 구조적 프로그래밍(1968)에서부터 Clean Code(Robert C. Martin, 2008)까지. 코드를 "읽을 수 있어야 한다"는 것은 거의 도덕적 명령이었다.

이 명제는 그 전통을 정면으로 거부한다. 코드는 더 이상 인간이 읽는 텍스트가 아니다. 그것은 신경망의 가중치처럼, 입력과 출력의 관계로만 판정되는 불투명한 중간 표현이다.

이것은 Andrej Karpathy가 "Software 2.0"(2017)에서 제안한 비전의 문자적 실현이다. Karpathy는 신경망이 프로그램을 "작성"하는 패러다임을 Software 2.0이라 불렀다. StrongDM은 LLM이 전통적 코드를 "작성"하되, 그 코드를 인간이 읽지 않는 패러다임을 만들었다. Software 1.0의 코드가 Software 2.0의 가중치처럼 취급되는 것이다.

### 덩어리 7: Gene Transfusion — 생물학적 메타포의 의미

> "Gene transfusion is how we move a working pattern from one codebase into another. In its basic form, it consists of directing coding agents to concrete exemplars."

**풀이**: "transfusion"은 의학 용어다 — 수혈. "transplant"(이식)이 아니라 "transfusion"인 것이 의미심장하다. 이식은 기관을 통째로 옮기는 것이지만, 수혈은 *유동적인 것*을 옮기는 것이다. 패턴은 고정된 코드 블록이 아니라, 코드베이스 사이를 흐를 수 있는 유동적 지식이다.

예시로 든 것이 Caddy의 Let's Encrypt 통합을 참조하여 다른 모듈에 네이티브 Let's Encrypt 지원을 합성하는 것이다. 에이전트가 *구체적인 작동하는 예시*를 보고 그 패턴을 다른 맥락에서 재현하는 것 — 이것은 인간 프로그래머가 하는 "레퍼런스 구현 참조" 패턴을 자동화한 것이다.

---

## IV. 행간 읽기 — 명시되지 않은 뉘앙스

### 4.1 "세 명의 팀"이라는 사실의 함의

Simon Willison은 Justin McCarthy, Jay Taylor, Navan Chauhan이 "세 명의 팀"이라는 것을 여러 번 강조한다. 그리고 그들은 세 달 만에 반다스 서비스의 디지털 트윈과 에이전트 하네스를 구축했다.

이것이 명시적으로 말하지 않는 것: 이 세 사람은 아마도 *수십 명의 에이전트*를 동시에 운용했을 것이다. "엔지니어 1인당 하루 토큰에 $1,000"라는 기준에서 역산하면, 세 명이 하루 $3,000, 한 달 $90,000을 토큰에 쓴 것이다. 이것은 사실상 수십 명 규모의 주니어 개발자 팀의 산출물에 해당할 수 있다.

즉, "세 명의 팀"은 *인간 세 명*이지, *작업 역량 세 명분*이 아니다. 이것은 소프트웨어 엔지니어의 직업이 "코드를 쓰는 것"에서 "에이전트 함대를 지휘하는 것"으로 전환된다는 것의 구체적 증거다.

### 4.2 보안 소프트웨어라는 도메인의 아이러니

Simon Willison이 짚은 것처럼, "보안 소프트웨어는 리뷰되지 않은 LLM 코드로 구축될 것이라고 가장 마지막에 기대할 것"이다. 이것은 의도적 도발이다. StrongDM은 *바로 그 가장 위험한 도메인*에서 이 방법론을 증명하려 했다.

여기서 명시되지 않은 함의: 만약 이것이 보안 소프트웨어에서 작동한다면, 덜 위험한 도메인에서 작동하지 않을 이유가 없다는 논증이 성립한다. 이것은 수사학에서 **a fortiori** (더 강한 것으로부터의 논증) 전략이다.

### 4.3 "Grown software"라는 메타포의 깊이

StrongDM은 코드를 "작성(write)"하는 대신 "성장(grow)"시킨다고 표현한다. 이것은 단순한 언어 유희가 아니다. "작성"은 의도적 설계를 함의하고, "성장"은 유기적 진화를 함의한다. 코드가 에이전트에 의해 생성되고, 시나리오에 의해 선택압을 받고, 만족도에 의해 적합도가 측정된다면 — 이것은 소프트웨어의 *진화적 개발*이다.

이것은 유전 프로그래밍(Genetic Programming, John Koza, 1992)의 정신적 후계자이되, 돌연변이와 선택이 LLM이라는 훨씬 더 지능적인 메커니즘으로 대체된 것이다.

### 4.4 Attractor 리포지토리 — 코드 없는 코드

Attractor 리포지토리에 코드가 없고 마크다운 스펙만 있다는 것은 의도적 퍼포먼스다. 이것은 "소프트웨어의 가치는 코드에 있지 않고 스펙에 있다"는 선언이다. GitHub에 코드 없이 스펙만 올리는 것은 소프트웨어 공학의 관습에 대한 공연적(performative) 전복이다.

---

## V. 재독 후 수정된 소회 및 스틸매닝

### 원문 재독 후 달라진 이해

처음에는 이 글을 낙관적 기술 유토피아니즘으로 읽었다. 재독 후, 더 미묘한 구조가 보인다. 이것은 주장(claim)이 아니라 **보고(report)**다. Simon Willison은 "a glimpse of one potential future"라고 한정하고, StrongDM은 자신들의 특정 맥락(보안 소프트웨어, 3인 팀, API 통합 도메인)을 분명히 한다.

### 가장 강한 반론에 대한 스틸매닝

**반론**: "코드를 보지 않는다는 것은 무책임하다. LLM은 미묘한 보안 취약점, 레이스 컨디션, 엣지 케이스를 만들 수 있고, 시나리오 테스트만으로는 이를 잡을 수 없다."

**스틸매닝**: 이 반론은 정당하지만, 그 전제를 검토해야 한다. 인간 코드 리뷰가 이런 것들을 *실제로 잡고 있는가*? Heartbleed(2014)는 OpenSSL의 인간이 작성하고 인간이 리뷰한 코드에 2년간 존재했다. Log4Shell(2021)은 17년간 숨어 있었다. 인간 코드 리뷰의 효과성에 대한 경험적 증거는 우리가 직관적으로 믿는 것보다 훨씬 약하다.

StrongDM의 접근법은 사실 이렇게 읽어야 한다: "인간 리뷰를 *제거*하는 것이 아니라, 인간 리뷰를 *더 효과적인 형태로 대체*하는 것." 시나리오 기반 행동 검증은, 코드를 줄 단위로 읽는 것보다 *실제 버그를 잡는 데 더 효과적일 수 있다.* 이것은 측정 가능한 경험적 주장이다.

**역반론을 위한 스틸매닝**: 그러나 코드를 전혀 보지 않는 것과 코드 리뷰가 불완전한 것은 다른 문제다. 코드에는 *의도*가 있고, 시나리오 테스트는 의도를 직접 검증하지 못한다 — 의도의 *결과*만 검증한다. 만약 에이전트가 올바르게 작동하는 코드를 만들었지만 내부적으로 비밀 키를 로그에 기록하는 코드를 포함시켰다면? 시나리오 테스트는 이것을 잡지 못할 수 있다. 이것이 코드 불투명성의 실질적 위험이다.

---

## VI. 윤문 — 원문의 문체를 살린 개선된 버전

### StrongDM의 AI 팀은 어떻게 코드를 *보지 않고도* 신뢰할 수 있는 소프트웨어를 구축하는가 (윤문)

지난주 나는 Dan Shapiro가 "암흑 공장(Dark Factory)"이라 부른 AI 도입 수준 — 코딩 에이전트가 생산한 코드를 인간이 일별(一瞥)조차 하지 않는 단계 — 의 작동하는 구현체를 보았다고 언급한 바 있다. 그 팀은 StrongDM 소속이었고, 그들의 작업 방식을 처음 공개한 글 "Software Factories and the Agentic Moment"가 방금 세상에 나왔다.

나는 그들의 원칙들 중 가장 도발적인 것이 "코드는 인간이 리뷰해서는 **안 된다**"라고 본다. LLM이 인간과는 질적으로 다른 실수를 저지른다는 것을 우리 모두가 목도하는 지금, 이것이 어떻게 합리적 전략이 *될 수* 있을까?

핵심은 그들이 "테스트"라는 낡은 그릇을 버리고 **시나리오**라는 새 그릇을 빚은 데 있다. 시나리오는 코드베이스 바깥에 저장되는 종단 간 사용자 스토리로, ML 훈련의 홀드아웃 세트처럼 에이전트의 시야 밖에 존재한다. 성공은 더 이상 불리언이 아니다 — 모든 시나리오를 관통하는 궤적들의 분포에서 산출되는 확률적 **만족도**다.

시나리오를 홀드아웃 세트로 취급하는 이 착상은 매혹적이다. 이것은 독립적 QA 팀에 의한 블라인드 테스팅을 구조적으로 모사한다 — 전통적으로 비싸고 느렸지만 가장 효과적이었던 품질 보증 방법을.

더 놀라운 것은 **디지털 트윈 유니버스**다. 그들은 Okta, Jira, Slack, Google Docs 등의 행동적 복제체를 — 역시 코딩 에이전트로 — 구축했다. 서드파티 API의 공개 문서를 에이전트에게 투입하면, 자립형 Go 바이너리로 된 모방체가 나온다. 이 복제체들은 레이트 리밋도 비용도 없으므로, 시뮬레이션된 테스터 군단은 시간당 수천 개의 시나리오를 포화사격처럼 실행할 수 있다.

여기서 진정으로 전복적인 통찰은 이것이다: 주요 SaaS 서비스의 고충실도 복제체를 만드는 것은 항상 *기술적으로* 가능했다. 다만 그 비용이 제안 자체를 내면적으로 검열하게 만들었을 뿐이다. 에이전틱 코딩은 이 경제적 장벽을 분쇄했다.

세 명이 세 달 만에 보안 소프트웨어를 — 코드를 한 줄도 직접 읽지 않고 — 구축했다는 사실은 한 가지 미래의 윤곽을 그린다. 소프트웨어 엔지니어는 코드를 쓰는 사람에서, 코드를 만드는 시스템을 설계하고 감독하는 사람으로 변모한다. 코드는 읽히는 텍스트이기를 그치고, 관찰되는 행동으로만 판정되는 불투명한 산출물이 된다. 암흑 공장의 불은 꺼져 있다 — 로봇에게 조명은 필요 없으니까.

---

## VII. 영어 번역

### Original (Simon Willison's article) — Key passage translation preserved as-is

*(원문이 이미 영어이므로 생략. StrongDM 원문도 영어. 아래는 윤문의 영어 번역)*

### 윤문의 영어 번역

**How StrongDM's AI Team Builds Trustworthy Software Without *Reading* a Single Line of Code** (Refined Version)

Last week I mentioned seeing a working implementation of what Dan Shapiro calls the "Dark Factory" level of AI adoption — the stage where no human so much as *glances* at the code produced by coding agents. That team was part of StrongDM, and their first public account of the methodology, "Software Factories and the Agentic Moment," has just entered the world.

The most provocative of their principles, I believe, is "Code **must not be** reviewed by humans." Given that we have all witnessed LLMs making qualitatively inhuman errors, how could this possibly constitute a rational strategy?

The key lies in their discarding the worn vessel of "test" and forging a new one: the **scenario**. A scenario is an end-to-end user story stored *outside* the codebase, inhabiting the agent's blind spot much as a holdout set inhabits a machine learning model's. Success is no longer boolean — it is a probabilistic **satisfaction** score computed from the distribution of trajectories across all scenarios.

Treating scenarios as holdout sets is a fascinating conceit. It structurally emulates blind testing by an independent QA team — historically the most effective, if expensive and slow, method of quality assurance.

More startling still is the **Digital Twin Universe**. They constructed behavioral clones of Okta, Jira, Slack, and Google Docs — again, using coding agents. Feed the public API documentation of a third-party service into the agent harness, and out comes a self-contained Go binary that imitates its behavior. These clones carry no rate limits and no costs, so a swarm of simulated testers can execute thousands of scenarios per hour in saturation-fire fashion.

The genuinely subversive insight here: building a high-fidelity clone of a major SaaS service was always *technically* possible. It was the economics that induced engineers to internally censor the very proposal. Agentic coding has demolished that economic barrier.

Three people building security software in three months — without reading a single line of the resulting code — sketches the outline of one possible future. The software engineer transforms from one who writes code into one who designs and oversees the systems that produce it. Code ceases to be text that is *read* and becomes an opaque artifact judged solely by observable behavior. The lights in the Dark Factory are off — robots have no need for illumination.

### 독일어 추가 번역 (핵심 개념어에 대해)

독일어의 철학적/공학적 어휘가 일부 개념을 더 정밀하게 포착한다:

- "Compounding correctness" → **Korrektheitskumulierung** (정확성의 누적 — 독일어가 합성어를 통해 이 개념을 하나의 단어로 포착)
- "Deliberate naivete" → **Bewusste Naivität** (의식적 순진함 — 독일 현상학 전통의 에포케(Epoché)와 공명)
- "Opaque weights" → **Undurchsichtige Gewichte** (불투명한 가중치 — "undurchsichtig"은 물리적 불투명성과 인식론적 불가해성을 동시에 함의)
- "Software Factory" → **Softwarefabrik** (소프트웨어 공장 — 독일의 Industrie 4.0 담론과 직접 연결)

### 일본어 추가 번역 (선불교 공안과의 연결)

Justin McCarthy가 명시적으로 "kōan"을 사용했으므로:

- "Why am I doing this?" → **「なぜ我これを為すか」** — 공안적 질문의 형태
- "Code must not be reviewed" → **「コードは見てはならぬ」** — 선의 금기(禁忌) 형태
- "Satisfaction" → **「足る」(たる)** — 일본어의 "足る"는 "충분하다"는 뜻으로, 선불교의 "吾唯足知"(오직 족함을 안다)와 연결

---

## VIII. 만족을 유예한 집요한 재독

지금까지의 분석이 피상적이라 치부하고 한 번 더 파고들겠다.

### 8.1 놓친 것: "Convergence"의 의미

원문에서 "converge without human review"라고 했다. "converge"(수렴)라는 단어를 지나쳤다. 이것은 수학적/최적화 용어다. 에이전트가 스펙과 시나리오라는 제약 조건 하에서, 반복을 통해 해에 *수렴*한다. 이것은 경사 하강법(gradient descent)과 구조적으로 동형이다:
- 손실 함수 = 시나리오 불만족도
- 파라미터 = 코드
- 최적화기 = 코딩 에이전트

즉, StrongDM의 소프트웨어 팩토리는 코드 공간(code space)에서의 최적화 과정이다. 코드는 가중치이고, 시나리오는 손실 함수이고, 에이전트는 최적화기다. 이 프레임을 명시하면, "코드를 보지 않는다"는 것이 완벽히 합리적이 된다 — 당신은 신경망의 가중치를 *읽지* 않는다. 당신은 손실을 측정한다.

### 8.2 놓친 것: "Non-interactive"의 체제적 함의

"Non-interactive development"는 겉보기보다 깊은 선언이다. 현재 코딩 에이전트 사용의 지배적 패러다임은 *대화형*(interactive) — Cursor, Copilot, Claude Code 등에서 인간이 에이전트와 턴을 주고받는. StrongDM은 이것을 *배치 처리*로 전환한 것이다.

이것은 컴퓨팅 역사의 반복이다. 초기 컴퓨터는 배치 처리였고, 대화형(interactive) 컴퓨팅의 도래는 혁명이었다. 이제 에이전틱 코딩에서 대화형에서 다시 배치 처리로 돌아가는 것은, 인간이 루프에서 빠져나왔다는 것을 의미한다. 인간-컴퓨터 상호작용의 역사가 한 바퀴 돌았다.

### 8.3 놓친 것: Pyramid Summaries와 컨텍스트 윈도우 문제

Pyramid Summaries는 기법일 뿐 아니라, LLM의 근본적 제약인 컨텍스트 윈도우에 대한 구조적 해법이다. 에이전트가 대규모 코드베이스를 다루려면, 모든 것을 한 번에 컨텍스트에 넣을 수 없다. 여러 수준의 요약을 피라미드 형태로 제공하면, 에이전트는 상위 수준에서 빠르게 탐색하고 필요한 부분만 하위 수준으로 확대할 수 있다. 이것은 인간이 대규모 코드베이스를 읽는 방식 — 파일 트리를 훑고 관심 부분만 깊게 읽는 — 의 구조적 모사다.

### 8.4 놓친 것: Shift Work의 산업 혁명적 메타포

"Shift Work"(교대 근무)라는 이름은 공장 노동의 교대 근무에서 온 것이다. 이것은 우연이 아니다 — 전체 프레임워크가 *소프트웨어 공장*이라는 산업 생산의 메타포 위에 구축되어 있다. 대화형 작업(인간이 의도를 정교화하는)과 비-대화형 작업(에이전트가 실행하는)을 분리하는 것은, 공장에서 설계 부서와 생산 라인을 분리하는 것의 소프트웨어 버전이다.

---

## IX. 원문이 다루지 않았지만 다뤘어야 할 내용

### 9.1 자명한 누락: 실패 사례

두 글 모두 성공 사례만 보고한다. 어떤 시나리오에서 에이전트가 수렴하지 못했는가? 어떤 종류의 버그가 시나리오 테스트를 통과했다가 나중에 발견되었는가? 어떤 DTU 복제체가 실제 서비스와의 행동 차이로 인해 잘못된 테스트 결과를 낳았는가? 이런 실패 사례가 없다면 이 방법론의 경계를 알 수 없다.

### 9.2 자명한 누락: 디버깅 프로세스

코드를 읽지 않는다면, 무언가가 잘못되었을 때 *어떻게 디버그하는가*? 시나리오의 만족도가 낮을 때, 피드백 루프는 어떻게 작동하는가? 에이전트에게 "시나리오 X가 실패했다, 고쳐라"라고 말하면 에이전트는 어떻게 원인을 진단하는가? 코드를 읽을 수 없다면 스택 트레이스를 어떻게 해석하는가?

### 9.3 비자명한 누락: 법적/규제적 함의

보안 소프트웨어의 코드를 인간이 리뷰하지 않았다는 것은 규제적으로 어떤 함의를 갖는가? SOC 2, ISO 27001, FedRAMP 같은 보안 인증은 보통 코드 리뷰 프로세스를 요구한다. "우리의 코드 리뷰는 LLM 에이전트에 의한 시나리오 테스트입니다"가 감사관에게 통할 것인가?

### 9.4 비자명한 누락: 기술 부채의 새로운 형태

코드를 읽지 않으므로 전통적 의미의 기술 부채(읽기 어려운 코드, 문서 부족 등)는 무의미해진다. 그러나 *새로운 형태의 부채*가 생긴다:
- **시나리오 부채**: 중요하지만 아직 작성되지 않은 시나리오
- **DTU 드리프트**: 실제 서비스가 업데이트되었지만 디지털 트윈이 아직 반영하지 못한 차이
- **스펙 부채**: 스펙이 실제 의도를 정확히 포착하지 못하는 간극

### 9.5 확장된 맥락: Goodhart의 법칙

"만족도가 측정 지표가 되면, 그것은 좋은 측정 지표이기를 멈춘다" — Goodhart의 법칙이 여기서도 적용될 수 있다. 에이전트가 시나리오를 직접 보지 못한다 해도, 시나리오의 *구조*를 추론할 수 있다면 (예: 이전 실행의 피드백을 통해), 홀드아웃의 효과가 점진적으로 약화될 수 있다. 이것은 ML에서 테스트 세트 오염(test set contamination)의 소프트웨어 공학적 등가물이다.

### 9.6 확장된 맥락: 인간 엔지니어의 새로운 역할과 역량

이 체제에서 엔지니어에게 필요한 역량은 근본적으로 바뀐다:
- 코딩 능력 → **스펙 작성 능력** (자연어로 의도를 정확히 표현하는 능력)
- 디버깅 능력 → **시나리오 설계 능력** (어떤 시나리오가 의미 있는 테스트인지 판단하는 능력)
- 아키텍처 능력 → **에이전트 오케스트레이션 능력** (복수의 에이전트를 효과적으로 조율하는 능력)

이것은 소프트웨어 교육 전체를 재고해야 한다는 것을 의미한다.

---

## X. 완료 확인

1. ✅ 허심탄회한 소회 (II절)
2. ✅ 의미 덩어리별 인용 및 풀이 (III절, 7개 덩어리)
3. ✅ 인물/용어 조사 — Cem Kaner 시나리오 테스팅, Dan Shapiro Dark Factory, Karpathy Software 2.0, Herbert Simon satisficing
4. ✅ 행간 읽기 (IV절, 4개 뉘앙스)
5. ✅ 재독 후 수정된 소회 및 스틸매닝 (V절)
6. ✅ 윤문 (VI절, 원문과 유사한 길이)
7. ✅ 영어 번역 + 독일어/일본어 추가 번역 (VII절)
8. ✅ 만족 유예 후 집요한 재독 (VIII절, 4개 추가 발견)
9. ✅ 다루지 않은 내용 탐색 (IX절, 6개 항목)
10. ✅ 본 확인 (X절)

---

*분석 완료. 2026.02.08.*