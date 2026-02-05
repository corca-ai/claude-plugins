# Retro: Clarify v2 — Unified Requirement Clarification

> Session date: 2026-02-06

## 1. Context Worth Remembering

- **플러그인 통합 패턴 확립**: 3개 플러그인(clarify v1, deep-clarify, interview) → 1개 통합 플러그인 + `--light` 플래그. 이 패턴은 향후 유사한 통합(예: retro + 다른 분석 도구)에서 재사용 가능.
- **gather-context 의존성 탐지**: 시스템 프롬프트에서 `/gather-context` 존재 여부를 확인하는 런타임 탐지 패턴. 파일 시스템 체크보다 깔끔하지만, 사용자에게 어떤 경로가 활성화되었는지 알려주지 않는 한계가 있음.
- **Reference 파일 아키텍처**: 4개 전문 참조 파일(aggregation, advisory, research, questioning) + 얇은 오케스트레이터 SKILL.md = 309줄. deep-clarify에서 시작된 "sub-agent orchestration via SKILL.md" 패턴의 성숙한 형태.
- **deprecation 패턴**: marketplace.json에 `"deprecated": true` + description prefix "DEPRECATED — use X instead". web-search → gather-context에서 시작된 패턴을 deep-clarify/interview에도 적용.

## 2. Collaboration Preferences

세션 특징: 이전 세션에서 설계한 plan을 구현하는 "실행 세션". 유저가 plan 전문을 한 번에 전달하고 "Implement the following plan:"으로 지시. 결과적으로 질문 없이 9개 단계를 연속 완료.

**관찰**:
- 유저는 plan이 충분히 상세하면 별도 확인 없이 바로 실행하는 것을 선호. "Implement"라는 한 단어가 전권 위임의 의미.
- 유저가 "테스트 후 커밋하고, lesson / retro 남겨주세요"라고 3가지를 한 문장으로 요청 — 연쇄 작업을 명시적으로 나열하는 스타일.

### Suggested CLAUDE.md Updates

- ✅ Applied: Collaboration Style에 추가 — "Plan 실행 중 불일치 발견 시 lessons.md에 기록하고, 즉시 보고하며 의사결정을 물어봐라"

## 3. Prompting Habits

이 세션은 유저의 프롬프트가 2개뿐이었고 둘 다 명확했기에, 특별한 개선점 없음.

하나 관찰: plan의 "Implementation Steps" 테이블이 매우 구체적이어서 구현이 원활했음. 이전 세션의 plan 설계 품질이 이 세션의 효율에 직결됨.

## 4. Critical Decision Analysis (CDM)

### CDM 1: 소스 자료의 선택적 병합 전략

| Probe | Analysis |
|-------|----------|
| **Cues** | plan의 Source Material Mapping 테이블이 각 파일별 처리 방침을 지정 — "near-verbatim", "merged", "new compilation" |
| **Goals** | 최소 변경으로 검증된 콘텐츠 재사용 vs 새로운 통합 구조에 맞는 재작성 |
| **Options** | (1) 모든 파일을 처음부터 재작성 (2) 가능한 한 원본 유지 + 필요한 곳만 변경 (3) 기계적 합치기 |
| **Basis** | 옵션 2 채택. aggregation-guide.md와 advisory-guide.md는 deep-clarify에서 이미 검증된 콘텐츠이므로 거의 그대로 포팅. research-guide.md는 두 개를 Section 1/2로 병합. questioning-guide.md만 신규 편찬. |
| **Knowledge** | deep-clarify의 reference 파일들이 이미 role/context/methodology/constraints/output 패턴을 따르고 있어서 구조 변경이 불필요 |
| **Hypothesis** | 모든 파일을 재작성했다면 더 통일된 톤이 나왔겠지만, 시간 2-3배 소요 + 기존 검증된 내용의 의도치 않은 변형 리스크 |

**핵심 교훈**: 기존 콘텐츠의 "재사용 vs 재작성" 결정은 콘텐츠의 검증 수준으로 판단하라. 이미 실전에서 검증된 콘텐츠는 그대로 유지하고, 새로운 맥락이 필요한 부분만 새로 쓴다.

### CDM 2: gather-context 탐지 메커니즘 선택

| Probe | Analysis |
|-------|----------|
| **Cues** | plan에서 "Detection: Check if `/gather-context` appears in available skills (system prompt)" 명시 |
| **Options** | (1) 파일 시스템 체크 (`ls ~/.claude/plugins/...`) (2) 시스템 프롬프트 검사 (3) 환경변수 체크 |
| **Basis** | 옵션 2 채택. 설치 방법에 무관하게 작동하고 (--plugin-dir, marketplace, 로컬 등), 파일 시스템 경로 하드코딩을 피할 수 있음 |
| **Goals** | 방어적 통합 (gather-context 없어도 동작) vs 깊은 통합 (gather-context 필수) |
| **Situation Assessment** | plan의 "Defensive cross-plugin integration" 원칙에 부합. 그러나 사용자에게 어떤 경로가 활성화되었는지 피드백하는 메커니즘은 빠져 있음 |
| **Aiding** | clarify 실행 시 "Research mode: gather-context (installed)" vs "Research mode: built-in tools (fallback)" 같은 한 줄 상태 표시가 있으면 디버깅에 도움 |

**핵심 교훈**: 런타임 경로 분기가 있을 때, 어떤 경로가 선택되었는지 사용자에게 한 줄로 알려주는 것이 디버깅과 신뢰 구축에 중요하다.

### CDM 3: 테스팅 범위 결정

| Probe | Analysis |
|-------|----------|
| **Cues** | `claude --print --plugin-dir`로 비대화형 테스트 실행. 프론트매터 파싱, 스킬 로딩, --light Phase 1 출력 확인 |
| **Options** | (1) `--print` 비대화형만 (2) `--resume` 대화형 테스트 (3) 전체 워크플로우 테스트 (연구 → 분류 → 질문) |
| **Basis** | 옵션 1 채택. 핵심 관심사(스킬이 로드되는가, 프론트매터가 유효한가, 참조 파일이 인식되는가)는 비대화형으로 충분히 검증 가능 |
| **Time Pressure** | 전체 워크플로우 테스트(4개 서브에이전트 + AskUserQuestion 루프)는 10분+ 소요. 단위 검증으로 투자 대비 효과 극대화 |
| **Hypothesis** | 전체 워크플로우 테스트 없이 커밋했으므로, 실제 사용 시 서브에이전트 프롬프트의 미세 조정이 필요할 수 있음 |

**핵심 교훈**: "스킬이 로드되는가"와 "워크플로우가 올바른가"는 별개의 검증 대상. 전자는 자동화 가능, 후자는 실사용으로만 검증 가능하므로, 배포 후 첫 실사용에서 집중 관찰 필요.

## 5. Expert Lens

### Expert Alpha: David Parnas

**Framework**: 정보 은닉(information hiding) 원칙에 기반한 모듈 설계 — 변경 가능한 결정을 모듈 경계 뒤에 격리
**Source**: *"On the Criteria to be Used in Decomposing Systems into Modules"* (1972)
**Why this applies**: 3개 플러그인을 1개로 통합하면서 "무엇을 감출 것인가?"가 핵심 설계 질문이었음

Parnas 관점에서 이 세션의 강점은 **통합의 "은닉 대상"을 올바르게 선택한 것**이다. 3개 플러그인의 서로 다른 내부 구조(알고리즘, 질문 메커니즘, 연구 도구)를 하나의 SKILL.md 뒤에 숨기고, `--light` 플래그로 구현의 "어떻게"를 사용자로부터 격리했다.

그러나 **gather-context 의존성이 은닉 불완전**하다. Path A/B라는 두 경로의 존재가 인터페이스 뒤에 완전히 숨겨지지 않았다. 변경 가능한 설계 결정(어느 의존성을 사용할지)이 사용자에게 노출될 수 있다.

4개 참조 파일 구조는 Parnas 원칙에 잘 부합한다. 각 파일이 하나의 설계 결정에 책임을 지는 명확한 모듈 경계다.

**권장사항**:
1. gather-context 의존성을 더 깊게 은닉하라 — 사용자에게는 단일 인터페이스만 제공하고, 내부 도구 선택은 자동으로
2. 참조 파일의 "제공자-소비자" 계약을 명시적으로 정의하여, 향후 참조 파일 추가/변경이 SKILL.md를 수정하지 않아도 되도록

### Expert Beta: Karl Weick + David Snowden

**Framework (Weick)**: 의미형성(sensemaking) — 사후적이고, 행동 중심적이며, 사회적 맥락 속에서 일어남
**Source**: *"Making Sense of the Organization"* (2009), *"The Social Psychology of Organizing"* (1979)
**Framework (Snowden)**: Cynefin — 복잡성 영역(Simple/Complicated/Complex/Chaotic)에서의 적응적 의사결정
**Source**: *"A Leader's Framework for Decision Making"* (HBR 2007)
**Why this applies**: 세션이 문제를 "Complicated"(분해 가능, 계획 → 실행)로 프레이밍했지만, 실제는 "Complex"에 가까움

**Weick 분석**: 이전 세션에서 plan이 완성되고, 이번 세션에서 "실패 없이 순행"한 것은 효율적이지만, **구현 중 피드백 루프와 재해석 기회**가 부족했을 수 있다. 또한 gather-context 의존성의 시간 축 변동(나중에 설치/언설치)이 사용자에게 **의미 불일치**를 만들 수 있다.

**Snowden 분석**: 문제를 "Complicated"로 분류하고 계획 → 실행했지만, gather-context 통합의 예측 불가능성과 3개 플러그인 사용자의 기대값 변화는 "Complex" 영역에 해당. 따라서 배포 후 **적응적 피드백 루프**가 필수.

**권장사항**:
1. 배포 후 첫 1-2주간 빠른 피드백 루프 설정 (실사용 관찰, 버그 리포트)
2. 참조 파일 간 의미 관계를 설명하는 메타-가이드 추가 고려
3. 실패 모드 시나리오 사전 작성: "gather-context 비활성화 후 clarify 동작", "기존 clarify v1 사용자의 --light 발견 경로", "interview 사용자의 통합 questioning 만족도"

## 6. Learning Resources

- **David Parnas, "On the Criteria to be Used in Decomposing Systems into Modules" (1972)**: 모듈화의 고전. 이 세션에서 수행한 "3개 → 1개 통합"이 정보 은닉 관점에서 얼마나 잘 되었는지 자가 평가하는 데 유용. 특히 "변경 가능한 결정"을 식별하고 모듈 경계 뒤에 격리하는 기준이 명확함.

- **Sam Newman, "Monolith to Microservices" (2019)**: 분산 → 통합 또는 그 반대의 의사결정을 다룸. 이번 세션은 "마이크로플러그인 → 모놀리식 플러그인" 방향이었는데, Newman의 "seam" 개념이 향후 리팩토링이나 재분리 결정에 도움.

- **Karl Weick, "Managing the Unexpected" (3rd ed., 2015)**: High Reliability Organizations에서의 의미형성. 이 세션처럼 "순탄한 실행"이 오히려 미래의 취약점을 감출 수 있다는 통찰. 플러그인 시스템같은 인프라 변경 시 특히 관련 있음.

## 7. Relevant Skills

스킬 갭 미발견. 이 세션의 워크플로우(plan 실행 → 테스트 → 커밋 → lessons → retro)는 기존 도구체인(plan-and-lessons, retro, plugin-deploy)으로 완전히 커버됨.

한 가지 관찰: `/plugin-deploy` 스킬을 이번에 사용하지 않았음 (유저가 수동으로 "테스트 후 커밋" 요청). CLAUDE.md의 워크플로우에서는 step 4로 `/plugin-deploy`가 명시되어 있으나, plan 구현 세션에서는 유저가 직접 순서를 지정하는 경우가 많아 자연스럽게 건너뛰어짐. 이는 문제라기보다 유연성.
