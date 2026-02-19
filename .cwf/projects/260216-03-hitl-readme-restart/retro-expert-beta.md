### Expert beta: Sidney Dekker

**Framework**: 복잡계 안전에서의 `drift into failure`와 New View(인간 오류를 개인 원인이 아니라 시스템 맥락의 신호로 해석)
**Source**: Griffith University Staff Directory (Professor Sidney Dekker) — https://app.griffith.edu.au/phonebook/phone-search.php?format=advanced&surname=Dekker ; Sidney Dekker, *Drift into Failure* (CRC Press, 2011) — https://www.routledge.com/Drift-into-Failure-From-Hunting-Broken-Components-to-Understanding-Complex/Dekker/p/book/9781409422211 ; Sidney Dekker, *The Field Guide to Understanding 'Human Error'* 3rd ed. (CRC Press, 2014) — https://www.routledge.com/The-Field-Guide-to-Understanding-Human-Error/Dekker/p/book/9781472439055 ; Dekker, “Safety after neoliberalism,” *Safety Science* 125 (2020), 104630 — https://doi.org/10.1016/j.ssci.2020.104630
**Why this applies**: 이번 세션의 핵심은 개인 실수 교정이 아니라 반복되는 실패 패턴(토큰 한계, 늦은 의존성 실패, 문서 전파 누락 위험)을 운영 설계로 바꾸는 일이었다. 아래 평가는 위 저작의 원칙을 세션 사건에 추론 적용한 것이다.

이 세션에서 가장 잘한 점은 의존성 누락을 “도구가 없어서 실패했다”는 개인/환경 탓으로 끝내지 않고, `질의→설치 시도→1회 재시도`라는 계약으로 재설계한 것이다. 이는 *The Field Guide to Understanding ‘Human Error’*가 말하는 Bad Apple 관점 탈피와 일치한다. 즉, 실패를 사람/단일 컴포넌트의 결함으로 닫지 않고, 목표 충돌과 자원 제약 속에서 실제 작업이 어떻게 이루어지는지(작업-as-done)를 프로세스에 반영했다.

토큰 한계 반복 후 세션 디렉토리를 분기한 결정도 `drift into failure` 관점에서 타당했다. *Drift into Failure*의 핵심처럼, 대형 실패는 대개 “합리적인 일상적 조정”이 누적되며 나타난다. 이 세션의 반복 `token_limit_reached`와 deep-contract 누락은 이미 약한 신호였고, 분기+포인터 전환+즉시 백필은 그 누적 드리프트를 조기 차단한 조치였다. 특히 README.ko SoT 고정 후 전파한 흐름은 맥락 붕괴를 막는 기준점 역할을 했다.

다만 개선점은 신호의 “조기 가시화”다. 이번에는 중요한 신호를 인지한 뒤 올바르게 대응했지만, 대응 시점이 뒤로 밀리며 재작업 비용이 이미 발생했다. Dekker의 복잡계 관점에서는 사후 통제보다 경계(boundary) 근처의 약신호를 운영 게이트로 끌어올려야 한다. 즉, 실패 후 설명보다 실패 전 조향이 필요하다.

**Recommendations**:
1. 세션 상태에 `drift signal register`를 추가해 `token_limit_reached`, `needs_follow_up`, 의존성 누락, deep-contract 미충족을 선행지표로 관리하고, 임계치별 강제 동작(예: 즉시 분기, 즉시 설치 질의, 즉시 백필)을 연결한다.
2. 규정 준수 중심 체크보다 “성공을 만들 수 있는 역량 확인” 중심 게이트를 강화한다: setup 시작 시 의존성 설치 의사 확인, 승인 시 즉시 설치/설정, 실행 1회 재시도, 그리고 README.ko SoT 전파 체크를 완료 조건으로 고정한다.
<!-- AGENT_COMPLETE -->
