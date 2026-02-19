# Retro: S25 Post-S24 Follow-up (Day 2)

> Session date: 2026-02-14
> Mode: deep

## 1. Context Worth Remembering

- 이번 세션은 단일 작업 수정이 아니라, 문서 체계/검증 체계/설치 UX를 함께 다루는 구조적 하드닝 세션이었다.
- 사용자 핵심 원칙은 일관됐다: `less is more`, `what/why > how`, 자동화 가능한 것은 문서 규칙이 아니라 결정론적 게이트로 승격.
- 실무 기준이 명확해졌다: `plugin -> repo` 링크 의존 금지, 문서 링크 일관성, lint/link/hook/git gate의 계층 분리.
- 운영 관점에서 중요한 변화는 `cwf:setup` 단일 진입 UX 강화였다. 사용자가 플래그를 기억하지 않아도 setup 단계에서 필요한 선택을 질문으로 유도하도록 방향이 확정됐다.
- 날짜 경계(260213 vs 260214) 혼선을 “예외 케이스”가 아니라 프로토콜 개선 대상으로 다뤘다.

## 2. Collaboration Preferences

- 사용자는 미세 구현 지시보다 거시 목표와 원칙 합의를 우선한다. 목표를 맞춘 뒤 실행 방법은 자율적으로 결정하길 기대한다.
- 즉시 수정보다 원인 분석을 먼저 요구한다. 특히 “왜 반복되었는가/왜 자동화로 못 막았는가”를 중요하게 본다.
- 강한 합리성 요구가 있다. 단순 동의보다 trade-off를 설명하고 반론 가능성을 열어둔 답변을 선호한다.
- 문서 품질 기준이 명확하다: 중복 제거, 역할 분리, 과한 how 지양, 링크/경로 일관성, 자동화-문서 경계 명시.

### Suggested Agent-Guide Updates

- 없음. 핵심 협업 성향은 이미 [AGENTS.md](../../../AGENTS.md)와 관련 문서에 대부분 반영되었고, 이번 세션에서는 보강/정렬 작업이 중심이었다.

## 3. Waste Reduction

이번 세션의 낭비는 “작업량”보다 “결정 지연”에서 크게 발생했다.

첫 번째 낭비는 동일 원칙(자동화 우선, 중복 제거)을 여러 라운드에서 반복 확인한 점이다. 증상은 AGENTS 중복 문구 재논의와 gate 배치 재논의였다. 5 Whys로 내려가면, 문서 수정 판단 기준이 초기에 체크리스트화되지 않았고(왜1), 자동화 가능/불가 분류를 즉시 적용하지 못했으며(왜2), 변경 단위를 문서 조각 단위로 다뤄 구조 단위로 묶지 못했고(왜3), 결과적으로 사용자 피드백이 설계 입력이 아니라 사후 보정으로 소비됐다(왜4), 근본적으로 “원칙-자동화-문서” 삼층 분류를 작업 시작 시 강제하는 관문이 없었다(왜5).

두 번째 낭비는 lint/게이트 적용 범위의 혼선이다. 증상은 “린트 에러 0” 판단 후 pre-push에서 추가 범위 에러가 다시 드러난 사건이었다. 5 Whys로 보면, 검사 스코프가 실행 맥락마다 달랐고(왜1), pre-push 대상 집합과 수동 검사 집합의 일치 검증이 없었으며(왜2), 훅 실행 테스트가 최종 단계에 밀렸고(왜3), 운영 기준 문서와 훅 스크립트 간 동기화 루프가 약했으며(왜4), 구조적으로 “로컬 확인=훅 확인”을 보장하는 합의된 실행 시퀀스가 없었다(왜5).

세 번째 낭비는 날짜 경계 의미론 혼선이다. 증상은 오늘이 260214인데 기존 260213 경로가 선택된 이유를 뒤늦게 확인한 점이었다. 5 Whys로 보면, retro 경로 우선순위가 live.dir 재사용 중심이었고(왜1), 날짜 rollover 시 사용자 선택 단계가 없었으며(왜2), `YYMMDD` 의미(생성일 vs 작업일)가 프로토콜에 충분히 명시되지 않았고(왜3), 경계 조건 테스트가 부재했으며(왜4), 결국 의미론 충돌이 운영 규칙으로 미리 흡수되지 못했다(왜5).

요약하면, 낭비의 공통 원인은 “결정 기준의 늦은 명문화”였다. 이번 세션의 성과는 이 기준들을 setup/hook/lint/protocol로 앞단에 이동시킨 것이다.

## 4. Critical Decision Analysis (CDM)

### CDM 1: 과업 범위를 `S25 후속`에서 `저장소 전반 하드닝`으로 확장

| Probe | Analysis |
|-------|----------|
| **Cues** | 사용자 메시지 패턴이 반복적으로 `less-is-more`, `what/why over how`, `automation over prose`를 강조했고, AGENTS/문서/게이트 전 영역에서 동일 원칙 위반이 재발했다. |
| **Goals** | 단기 마감(후속 이슈 종료)과 장기 안정성(재발 방지) 사이 균형이 필요했다. |
| **Options** | 국소 수정만 수행, 일부 문서만 보강, 구조/게이트/설치 UX까지 동시 하드닝 중 선택. |
| **Basis** | 반복 피드백의 원인이 개별 문구가 아니라 구조 경계임이 명확해져 구조 하드닝을 선택했다. |
| **Situation Assessment** | 문제를 “문서 품질”이 아니라 “정책 전달 방식과 강제 방식의 불일치”로 재정의한 판단이 핵심이었다. |
| **Hypothesis** | 국소 수정만 했다면 다음 세션에서 동일 논점이 다시 열렸을 가능성이 높다. |
| **Time Pressure** | 즉시 비용은 증가했지만, 핑퐁 반복 비용을 크게 줄였다. |

**Key lesson**: 반복 피드백이 같은 원칙 위반을 가리키면 티켓 범위를 넘어 시스템 경계를 재정의해야 한다.

### CDM 2: AGENTS를 `불변 원칙 / 문서수정 전 읽기 / 문서 맵`으로 분리

| Probe | Analysis |
|-------|----------|
| **Cues** | 중복/저신호 문구를 여러 차례 제거하며 섹션 역할 혼선이 드러났다. |
| **Goals** | 항상 읽히는 진입 문서의 신호 밀도 확보와 탐색성 유지가 필요했다. |
| **Options** | 장문 유지, 단순 축약, 책임 경계 재구성 중 선택. |
| **Basis** | 단순 축약만으로는 재발을 막지 못해 역할 분리를 채택했다. |
| **Knowledge** | 사용자의 `what/why` 성향이 기준이 되어 절차 문구보다 역할 문구를 남겼다. |
| **Aiding** | Document Map과 before-editing 섹션 분리로 중복 점검 기준이 명확해졌다. |
| **Experience** | 숙련된 문서화는 규칙 총량이 아니라 경계 선명도를 높인다. |

**Key lesson**: 운영 문서 품질은 “얼마나 많이 적었는가”가 아니라 “어디까지가 누구 책임인가”로 평가해야 한다.

### CDM 3: prose 규칙을 결정론적 게이트로 승격

| Probe | Analysis |
|-------|----------|
| **Cues** | 자동화 가능한 항목이 문서에 남아 반복 충돌을 일으켰다. |
| **Goals** | 재발 방지, 로컬 즉시 피드백, 팀 일관성 동시 달성이 필요했다. |
| **Options** | 문서 보강만, CI 후단 검사, 훅+pre-commit+pre-push 3계층. |
| **Basis** | 3계층이 피드백 속도와 최종 보장을 함께 만족했다. |
| **Tools** | markdownlint custom rules, check-links, index coverage, git hooks, setup installer를 체인으로 연결했다. |
| **Situation Assessment** | 정책을 “기억할 문구”에서 “실행 시점 차단”으로 이동시킨 점이 핵심이다. |
| **Hypothesis** | CI-only면 왕복이 길어지고, prose-only면 재발이 지속됐을 것이다. |

**Key lesson**: 반복 위반 정책은 문서화가 아니라 실행 경로의 결정적 검증으로 구현해야 한다.

### CDM 4: 날짜 혼선을 롤오버 프로토콜 이슈로 승격

| Probe | Analysis |
|-------|----------|
| **Cues** | 실제 날짜와 세션 디렉토리 prefix가 불일치해 사용자 혼선이 발생했다. |
| **Goals** | 세션 연속성 유지와 날짜 의미 명확화(생성일/작업일 구분)가 모두 필요했다. |
| **Options** | 건별 수동 대응, 관례 공유, 프로토콜 명문화 중 선택. |
| **Basis** | 재발 가능성이 높은 경계 조건이어서 프로토콜/질의 단계 추가로 대응했다. |
| **Situation Assessment** | 파일명 문제가 아니라 운영 의미론 결손으로 판단한 점이 타당했다. |
| **Tools** | retro 경로 결정 단계와 plan-protocol/project-context 문서 규칙을 동기화했다. |
| **Experience** | 경계 조건은 예외 처리보다 규칙 승격이 장기 비용이 낮다. |

**Key lesson**: 날짜/단계 경계에서의 혼선은 즉시 예외 처리로 닫지 말고, 프로토콜과 검증 규칙으로 올려야 한다.

## 5. Expert Lens

### Expert alpha: Donella Meadows

**Framework**: 시스템 구조(피드백 루프, 정보 흐름, 규칙, 목적)의 레버리지 포인트를 조정해 행동을 바꾼다.

**Source**: *Leverage Points* (1999), *Thinking in Systems* (2008).

**Why this applies**: 이번 세션은 파라미터(문구) 수정에서 규칙/목표 수준 개입(게이트/설치 경로)으로 이동했다.

이번 세션은 시스템 목적을 “문서 서술 충실도”에서 “재발 방지 가능한 운영”으로 재정의했다는 점에서 고레버리지 개입이었다. AGENTS 구조 재정렬과 deterministic gate 강화는 시스템 행동을 바꾸는 규칙 수준 개입이다.

반복 핑퐁은 피드백 루프 지연을 보여줬다. 동일 원칙 위반이 누적된 후에야 구조를 바꾼 것은, 교정의지 부족이 아니라 교정 위치가 낮았기 때문이다.

날짜 롤오버 혼선을 프로토콜 이슈로 승격한 판단은 경계조건을 시스템 규칙으로 흡수한 사례다. 다음 단계는 경계조건을 사전 검증 목록으로 옮겨 지연을 더 줄이는 것이다.

**Recommendations**:
1. 동일 피드백이 2회 반복되면 파라미터 수정 중단 후 `rule/flow/purpose` 재분류 단계를 강제한다.
2. 날짜 경계·게이트 배치·책임 경계를 setup/check에서 기본 검증 항목으로 올려 운영 지연을 줄인다.

### Expert beta: Kent Beck

**Framework**: 작은 안전한 단계와 빠른 피드백으로 변경 비용을 관리한다(Tidy First, coupling/cohesion).

**Source**: *Extreme Programming Explained*, *Tidy First?*, *Implementation Patterns*.

**Why this applies**: 이번 세션은 기능 추가보다 구조적 정리와 품질 게이트 확립이 중심이었고, 이는 전형적인 변경 경제성 문제였다.

AGENTS/문서 정리를 반복적으로 수행해 신호 밀도를 높인 선택은 Tidy First 관점에서 합리적이었다. 즉시 성과보다 이후 변경의 마찰을 낮추는 투자를 했다.

또한 규칙을 lint/hook/pre-push 체계로 옮긴 것은 “빠르고 신뢰 가능한 피드백”이라는 XP 원칙에 부합한다. 사람의 기억 대신 실행 가능한 검증으로 바꾼 점이 핵심이다.

개선점은 변경 경계 분리다. 정리 변경(tidy)과 정책/행동 변경을 더 엄격히 분리하면 회귀 원인 추적 비용이 더 낮아진다.

**Recommendations**:
1. 하드닝 작업을 `tidy commit`과 `behavior/policy commit`으로 분리해 변경 경제성을 높인다.
2. 경계 조건(날짜/타임존/롤오버)에 fixture 기반 테스트를 도입해 문서 규칙을 실행 규칙으로 완결한다.

## 6. Learning Resources

## 1) Diátaxis: A systematic framework for technical documentation authoring
- URL: https://diataxis.fr/
- 핵심 요약: Diátaxis는 문서를 `Tutorial`, `How-to`, `Reference`, `Explanation` 네 가지 목적 기반 타입으로 분리해, 중복과 혼선을 줄이는 구조를 제시합니다. 특히 "한 문서, 한 목적" 원칙을 강제해 AGENTS/가이드 문서가 점점 비대해지는 문제를 예방하는 데 효과적입니다. 결과적으로 문서 품질 개선을 사람의 기억에 의존하지 않고 정보 구조 자체로 유도합니다.
- 이 레포에 바로 유용한 이유: 이번 세션에서 합의한 "less-is-more"와 "자동화 가능한 규칙은 prose가 아니라 gate로" 원칙을 문서 IA 수준에서 고정할 수 있습니다. 예를 들어 AGENTS.md는 운영 불변식(Explanation/Reference) 중심으로 유지하고, 실행 절차는 How-to 문서로 분리하는 리팩터링 기준으로 바로 쓸 수 있습니다.

## 2) pre-commit (Official Documentation)
- URL: https://pre-commit.com/
- 핵심 요약: pre-commit은 Git hook 실행을 언어/런타임 독립적으로 표준화하고, hook 버전 고정(rev pinning)으로 팀 전체의 검사 결과를 결정적으로 맞춰줍니다. `pre-commit`, `pre-push` 등 stage별 실행 정책을 선언적으로 관리해 "로컬 통과 = CI 통과"에 가까운 흐름을 만들 수 있습니다. 또한 신규 기여자도 한 번의 설치로 동일한 품질 게이트를 즉시 적용할 수 있습니다.
- 이 레포에 바로 유용한 이유: 현재 논의된 markdown/link/session 게이트를 hook 계층으로 분리 운영할 때, 수동 스크립트 호출 대신 단일 manifest 기반으로 유지보수 복잡도를 낮출 수 있습니다. `cwf:setup`에서 필수 선택을 받은 뒤 pre-commit 설치까지 연결하면 온보딩 편차를 줄이고 재현성을 높일 수 있습니다.

## 3) Anthropic Engineering — Building effective agents
- URL: https://www.anthropic.com/engineering/building-effective-agents
- 핵심 요약: 이 글은 에이전트 시스템을 설계할 때 가장 단순한 패턴에서 시작해 필요할 때만 복잡도를 올리라는 실전 원칙을 제시합니다. 또한 prompt chaining, routing, parallelization 같은 워크플로 패턴과 각 단계 사이의 명시적 검증(check) 지점을 강조해, 실패를 조기에 차단하는 구조를 설명합니다. 도구 인터페이스를 명확히 정의하고 관측 가능성을 확보하는 것이 운영 신뢰성의 핵심이라는 점도 구체적으로 다룹니다.
- 이 레포에 바로 유용한 이유: `cwf:setup` 단일 진입 설계와 훅 게이트 계층화를 진행할 때, "복잡도 점진 증가"와 "단계별 평가 게이트" 원칙을 바로 적용할 수 있습니다. 즉, 초기에는 최소 필수 질문+필수 게이트만 두고, 실제 실패 패턴 데이터가 쌓일 때 고급 훅/검증을 추가하는 운영 전략으로 연결됩니다.

## 7. Relevant Skills

### Installed Skills

이번 세션과 직접적으로 맞닿는 설치 스킬/플러그인:
- `cwf:setup`, `cwf:refactor`, `cwf:retro`, `cwf:review`: 문서 규칙/게이트/회고 루프를 다루는 핵심 축.
- `.claude/skills/plugin-deploy`: 로컬 운영 자동화와 품질 체크 정합에 유용.
- 공식 마켓플레이스 계열 중 `claude-md-improver`, `hook-development`, `writing-rules`, `plugin-structure`는 이번 주제(문서 구조/훅 정책/플러그인 경계)에 직접적 참고 가치가 큼.

### Skill Gaps

- 즉시 신규 스킬 생성이 필요한 공백은 크지 않다.
- 다만 운영 편의를 위해 다음 중 하나는 후보:
  - `cwf:quality-gates`(가칭): hook + pre-commit + pre-push 상태 점검/설치/검증을 일괄 실행하는 경량 오퍼레이션 스킬.
  - 또는 현재 `cwf:setup`에 동일 기능을 유지하되, `--audit-gates` 모드를 추가해 상태 리포트 전용 경로 제공.

