# Retro: S13 Holistic Refactor

> Session date: 2026-02-08
> Mode: deep

## 1. Context Worth Remembering

- CWF v3 마이그레이션은 S0-S14 로드맵으로 진행 중이며, S13은 머지 전 quality gate 역할
- `plugins/cwf/` 하위에 9개 스킬과 14개 hook 스크립트가 존재. 10번째 스킬(review)은 아직 별도 플러그인으로 존재
- 유저는 린터 설정의 false negative을 false positive보다 더 우려함 — 규칙을 풀어주는 것보다 잡지 못하는 것을 걱정
- markdownlint는 55개 규칙 중 7개만 비활성화 (87% 활성). shellcheck은 전체 규칙 적용
- 유저는 반복 패턴을 발견하면 공유 레퍼런스로 추출하는 것이 당연하다고 봄 — holistic 분석 도구가 이를 자동 제안하길 기대

## 2. Collaboration Preferences

- 유저는 보고서 요약에서 "주요 마찰 규칙 7개 비활성화"를 "거의 모든 룰 해제"로 해석함 → 비율이나 전체 중 일부라는 맥락 제공이 중요
- 디자인 제안을 유저가 먼저 함 ("추출해서 바깥 레퍼런스에 넣어야 하지 않나") → 에이전트가 선제적으로 제안했어야 하는 케이스
- 유저는 마일스톤 완료 시점에 방향 확인을 함 — "다음 세션 의도 이해했나?" 형태로

### Suggested CLAUDE.md Updates

해당 없음. 기존 규칙으로 충분.

## 3. Waste Reduction

### 패턴 추출 제안의 누락

유저가 "동일 패턴이면 추출해야 하지 않나?"라고 물었을 때, holistic 분석을 이미 완료한 시점이었다. 분석 단계에서 이를 선제적으로 발견하고 제안했어야 했다.

**5 Whys**:
1. Why: 왜 선제적으로 제안하지 못했나? → holistic-criteria.md에 패턴 추출 항목이 없었음
2. Why: 왜 기준에 없었나? → 기존 criteria는 "좋은 패턴을 다른 스킬에 전파"에 집중, "반복 패턴을 추출"은 스코프 밖이었음
3. Why: 왜 스코프 밖이었나? → criteria 작성 시점(S11a)에는 스킬이 5개뿐이라 반복 패턴이 충분히 축적되지 않았음
4. **근본 원인**: 프로젝트가 성장하면서 새로운 분석 차원이 필요해졌으나, 분석 도구(holistic-criteria)가 그에 맞춰 진화하지 않았음

**해결**: holistic-criteria.md에 1c (패턴 추출 분석) 추가 — 이 세션에서 이미 적용함. **Process gap → FIXED**.

### 린터 규칙 보고의 프레이밍 오류

"7개 규칙 비활성화"로 보고했으나, 유저는 이를 "대부분 해제"로 인식. 전체 대비 비율(7/55 = 13% 해제)을 먼저 제시했어야 함.

**근본 원인**: 보고 시 절대 수치만 제시하고 비율/맥락을 빠뜨린 one-off 실수. 구조적 문제는 아님.

### 서브에이전트 미사용

cwf:refactor --holistic 스킬은 3개 병렬 서브에이전트를 지시하지만, 이미 모든 파일을 읽은 상태라 인라인 분석을 선택했다. 결과적으로 효율적이었으나 스킬 지시와 괴리가 있었음.

**근본 원인**: 서브에이전트 패턴은 "데이터를 아직 안 읽은 상태에서 병렬 수집+분석"에 최적화. 이미 데이터가 컨텍스트에 있으면 인라인이 나음. 스킬에 "이미 데이터가 컨텍스트에 있으면 인라인 분석 허용" 조건을 추가하면 해결. lessons.md에 기록 완료.

## 4. Critical Decision Analysis (CDM)

### CDM 1: 인라인 분석 vs 서브에이전트 (holistic 모드)

| Probe | Analysis |
|-------|----------|
| **Cues** | 9개 SKILL.md + 14개 hook 스크립트를 이미 전부 읽은 상태. 서브에이전트에 데이터를 넘기려면 요약을 만들어야 하고, 상세 정보가 손실됨 |
| **Goals** | (1) 스킬 지시 준수 vs (2) 분석 정확도 vs (3) 컨텍스트 효율 |
| **Options** | A: 스킬대로 3개 서브에이전트 실행. B: 인라인 분석. C: 부분만 서브에이전트 |
| **Basis** | 이미 읽은 30+ 파일의 세부 내용이 서브에이전트에 전달되면 요약 과정에서 손실됨. 인라인 분석이 더 정확한 결과를 낼 것으로 판단 |
| **Hypothesis** | 서브에이전트를 사용했다면 참조 경로 깊이 문제(F1)를 놓쳤을 가능성 있음. `../` vs `../../`의 차이는 전체 경로 컨텍스트가 있어야 탐지 가능 |
| **Aiding** | 스킬에 "이미 인벤토리가 컨텍스트에 있으면 인라인 분석 가능" 분기를 추가 |

**Key lesson**: 서브에이전트 패턴의 가치는 데이터 수집 비용이 높을 때 극대화됨. 데이터가 이미 있으면 인라인이 우월.

### CDM 2: skill-conventions.md 추출 결정

| Probe | Analysis |
|-------|----------|
| **Cues** | 유저가 "동일 패턴이면 추출해야 하지 않나"라고 직접 제안. 9개 스킬 전부가 동일 구조를 따르는 것을 분석에서 이미 확인 |
| **Goals** | (1) DRY 원칙 vs (2) 스킬의 자기 완결성 vs (3) 새 스킬 작성 가이드 |
| **Options** | A: 규약만 문서화 (conventions reference). B: 스킬 내 공통 Rules를 실제로 include/import. C: 아무것도 안 함 |
| **Basis** | B는 Claude Code 스킬 시스템이 include를 지원하지 않아 불가. A가 유일한 실현 가능 옵션이면서 가이드 + 리뷰 체크리스트 역할도 수행 |
| **Knowledge** | SKILL.md는 세션 시작 시 독립적으로 로드됨. 런타임 공유는 불가하므로, conventions doc는 작성 시점과 리뷰 시점에만 참조됨 |
| **Aiding** | holistic-criteria 1c (패턴 추출)에 자동 탐지 기준을 추가하여 향후 유사 상황에서 에이전트가 선제 제안하도록 개선 |

**Key lesson**: 런타임 공유가 불가능한 환경에서도, "작성 시점 + 리뷰 시점" 가이드 문서는 일관성 유지에 효과적. 추출이 아닌 참조 표준화.

## 5. Expert Lens

### Expert Alpha: Kent Beck

**Framework**: 구조적 변경(tidying)을 행동적 변경보다 먼저, 작게, 되돌릴 수 있는 단위로 수행하는 경험적 소프트웨어 설계(Empirical Software Design)
**Source**: *Tidy First? A Personal Exercise in Empirical Software Design* (O'Reilly, 2023), *Extreme Programming Explained* 2nd ed. (Addison-Wesley, 2004), Kent Beck의 Substack 시리즈 "Software Design: Tidy First?" — 특히 "Structure & Behavior"와 "Theory" 포스트
**Why this applies**: S13 세션은 본질적으로 9개 스킬과 14개 훅 스크립트에 대한 **구조적 정리(tidying)** 세션이었다. 깨진 참조 경로 수정, 누락된 Rules 섹션 추가, skill-conventions.md 추출 — 이 모든 작업이 Beck이 말하는 "행동 변경 이전의 구조 변경"에 정확히 해당한다.

**1. "Tidy First?" — 구조 변경과 행동 변경의 분리가 정확하게 작동한 지점**

이 세션에서 가장 인상적인 것은 S14 통합 테스트(행동 변경) 전에 S13에서 구조 정리를 별도 세션으로 분리한 아키텍처적 판단이다. Beck은 *Tidy First?*에서 "구조적 변경은 되돌릴 수 있고, 행동적 변경은 되돌릴 수 없다"고 명확히 구분한다. 깨진 참조 경로(`../` vs `../../`)를 S14에서 통합 테스트 도중 발견했다면, 구조 문제와 행동 문제가 뒤섞여 디버깅 비용이 급증했을 것이다. Beck의 공식 — `cost(software) ≈ cost(change) ≈ cost(big changes) ≈ coupling` (Constantine's Equivalence, *Tidy First?* Theory 장) — 으로 보면, 4/9 스킬의 깨진 참조 경로는 **coupling 비용의 직접적 징후**였고, 이를 먼저 정리한 것은 올바른 순서였다.

그러나 한 가지 아쉬운 점이 있다. *Tidy First?*의 핵심 원칙 중 하나는 "tidying을 작은 단위로, 자주, 각 행동 변경 직전에" 하는 것이다. 이 세션은 9개 스킬을 한꺼번에 정리하는 "일괄 정리(batch tidying)"를 수행했다. Beck이라면 각 스킬을 개별 커밋으로 정리하고, 각각을 독립적으로 검증 가능한 상태로 유지했을 것이다.

**2. 패턴 추출 실패 — "Once and Only Once" 원칙의 늦은 적용**

사용자가 skill-conventions.md 추출을 제안해야 했다는 사실은 Beck의 Simple Design 4규칙 관점에서 주목할 만하다. Beck은 *Extreme Programming Explained*에서 simple design의 네 가지 규칙을 우선순위 순으로 제시한다: (1) 모든 테스트 통과, (2) 의도를 드러냄, (3) 중복 제거, (4) 최소 요소. 9개 스킬이 동일한 구조적 패턴을 공유하고 있었다면 이것은 **중복**이다. 에이전트가 9개 SKILL.md를 모두 컨텍스트에 읽어놓고도 이 패턴을 자발적으로 감지하지 못한 것은, 분석 기준에 중복 탐지 차원이 없었기 때문이다.

더 흥미로운 것은 **도구의 진화 문제**다. holistic-criteria.md가 5개 스킬 시점에 작성되었고 9개 스킬에서는 새로운 분석 차원이 필요했다는 사실은, Beck의 3X 프레임워크(Explore → Expand → Extract)와 직접 연결된다. 5개 스킬은 Explore 단계였고, 9개 스킬은 Extract 단계로 진입하는 시점이다. holistic-criteria.md 자체가 Extract 단계에 맞게 진화하지 않았다는 것은 도구가 제품 단계를 따라가지 못한 것이다.

**Recommendations**:
1. **Tidying을 일괄이 아닌 개별 커밋 단위로 분리하라.** 각 finding을 별도 tidying 단위로 처리하면 (a) 각 변경이 독립적으로 되돌릴 수 있고, (b) 문제 발생 시 원인을 즉시 특정할 수 있다.
2. **세션 시작 시 도구의 단계 적합성(stage fitness) 점검을 추가하라.** `cwf:refactor --holistic`의 첫 단계에 "현재 스킬 수 vs criteria 작성 시 스킬 수 비교 → 차이가 크면 criteria 업데이트를 선행 작업으로 추가"하는 자동 점검 로직을 넣어라.

### Expert Beta: Don Norman

**Framework**: 인간 중심 디자인 — 어포던스, 시그니파이어, 개념 모델, 실행/평가의 간극(Gulf of Execution/Evaluation)을 통해 도구와 사용자 사이의 상호작용 실패를 진단하는 프레임워크
**Source**: *The Design of Everyday Things* (Revised and Expanded Edition, 2013), Don Norman. 특히 Ch.1 "The Psychopathology of Everyday Things", Ch.3 "Knowledge in the Head and in the World", Ch.5 "Human Error? No, Bad Design"
**Why this applies**: holistic-criteria가 패턴 추출을 유도하지 못한 것, 린터 보고서가 오해를 유발한 것, 스킬 템플릿이 런타임 공유 불가라는 제약을 드러내지 못한 것 — 모두 **도구가 사용자에게 올바른 행동을 시그널하지 못한 실패**다. Norman의 프레임워크는 이것을 사용자의 실수가 아닌 도구 설계의 결함으로 진단한다.

**1. holistic-criteria.md의 시그니파이어 부재 — "실행의 간극"**

Norman은 "실행의 간극(Gulf of Execution)"을 "사용자의 의도와 시스템이 허용하는 행동 사이의 격차"로 정의한다. holistic-criteria.md는 분석 차원을 나열함으로써 에이전트에게 "무엇을 분석해야 하는가"의 **어포던스**를 제공한다. 그러나 "반복 패턴이 발견되면 추출하라"는 차원이 없었기 때문에, 에이전트는 9개 스킬에서 동일 패턴을 관찰하고도 추출이라는 행동으로 연결하지 못했다.

Norman의 용어로, 이 도구에는 **시그니파이어가 없었다**. "어포던스는 가능한 상호작용을 결정하지만, 시그니파이어가 없으면 사용자는 그 가능성을 발견할 수 없다." 사용자가 직접 "동일 패턴이면 추출해야 하지 않나?"라고 개입한 것은, 디자인 실패를 사용자의 외부 지식으로 보상한 순간이다.

**2. 린터 보고서의 "7 rules disabled" — 개념 모델 불일치**

Norman은 **개념 모델**을 "사용자가 시스템의 작동 방식을 이해하기 위해 형성하는 단순화된 설명"으로 정의한다. "7 rules disabled"라는 보고에는 전체 맥락(55개 중 7개)이 포함되지 않았기 때문에, 사용자는 **머릿속 지식**만으로 해석해야 했고, 최악의 경우를 가정했다. Norman식 해법은 명확하다: 보고 형식 자체가 "7/55 disabled (13%)" 같은 **맥락 포함 시그니파이어**를 제공해야 한다.

**3. skill-conventions.md — 물리적 제약의 문화적 제약 보상**

Norman은 제약을 네 가지로 분류한다: 물리적, 문화적, 의미적, 논리적. SKILL.md가 런타임에 독립 로딩된다는 것은 **물리적 제약**이다. 이 제약 앞에서 skill-conventions.md를 "작성/리뷰 시점 참조 문서"로 만든 것은, "물리적 제약이 변경 불가능할 때 문화적 제약으로 보상하라"는 Norman의 원리와 일치한다. 다만, 문화적 제약은 학습되어야 하므로 취약하다. 새 스킬 작성자가 이 문서를 **발견할 수 있어야** 한다 — "존재하지만 발견되지 않는 어포던스"가 되지 않도록 스킬 생성 워크플로우에 명시적 참조가 필요하다.

**Recommendations**:
1. **holistic-criteria.md에 "메타 차원" 시그니파이어 추가**: "분석 대상이 N개 이상일 때 자동으로 활성화되는 차원" 섹션을 도입하라. 체크리스트가 규모에 따라 스스로 확장하면, 실행의 간극이 줄어든다.
2. **모든 정량적 보고에 "분모 포함" 규칙 강제**: 린터, 테스트, 커버리지 등 수치 보고 시 반드시 "X/Y (Z%)" 형식을 사용하라. 이것은 Norman이 말하는 "세상 속 지식(knowledge in the world)"을 극대화하는 설계다.

## 6. Learning Resources

### 1. 성장하는 시스템에서의 패턴 추출

**[The Wrong Abstraction](https://sandimetz.com/blog/2016/1/20/the-wrong-abstraction)** — Sandi Metz

"Duplication is far cheaper than the wrong abstraction." 중복 코드를 보자마자 추출하고 싶은 충동은 자연스럽지만, 잘못된 추상화가 자리잡으면 이후 개발자들이 파라미터와 조건문을 계속 추가하면서 추상화가 퇴화한다. 5개 스킬에서 추출하지 않은 것은 오히려 올바른 순서였을 수 있다 — 9개까지 성장한 지금이야말로 패턴이 충분히 드러난 시점이므로 적기. 향후 "지금 추출할 것인가, 한 번 더 기다릴 것인가"의 판단 프레임워크로 활용 가능.

### 2. 도구/체크리스트 진화

**[Fitness Functions for Your Architecture](https://www.infoq.com/articles/fitness-functions-architecture/)** — InfoQ (Neal Ford / Building Evolutionary Architectures)

Fitness function은 아키텍처 특성에 대한 "객관적 무결성 평가"로, 시스템이 진화할 때 중요한 속성이 유지되는지를 자동 검증한다. 핵심은 fitness function **자체**도 시스템과 함께 진화해야 한다는 점. holistic-criteria가 5개 스킬 기준으로 설계되어 9개 스킬에서 새 차원을 놓친 것은 전형적 사례. 검증 기준을 코드처럼 버전 관리하고, 시스템이 특정 임계치를 넘을 때 기준 자체를 리뷰하는 트리거 메커니즘 적용을 고려할 수 있다.

### 3. 기술 보고에서의 프레이밍 효과

**[The Framing of Decisions and the Psychology of Choice](https://sites.stat.columbia.edu/gelman/surveys.course/TverskyKahneman1981.pdf)** — Amos Tversky & Daniel Kahneman (Science, 1981)

프레이밍 효과의 원본 논문. 동일한 사실이라도 제시 방식에 따라 판단이 완전히 달라진다. 특히 denominator neglect(분모 무시) 현상 — 사람은 절대값("7개 규칙 비활성화")에 강하게 반응하지만, 비율("7/55, 87% 활성")이 제시되면 전혀 다른 해석을 한다. 기술 보고에서 절대값만 제시하면 심각도가 과대 평가되고, 비율과 전체 맥락을 함께 제시하면 올바른 판단이 가능해진다.

## 7. Relevant Skills

### Installed Skills

| 스킬 | 적용 가능성 |
|------|------------|
| cwf:refactor (marketplace) | 이 세션의 메인 도구. --holistic 모드 사용 |
| cwf:review (local) | 유저가 다음 세션에서 사용 예정. 이 세션에서도 마스터 플랜 대비 검증에 사용할 수 있었음 |
| plugin-deploy (local) | 버전 범프가 필요한 경우 사용 가능했으나, 이 세션은 코드 수정이라 불필요 |

### Skill Gaps

이 세션에서 "참조 경로 검증"이 수동으로 grep 기반으로 이루어졌다. markdownlint는 파일 내부 문법만 검사하고 파일 간 링크 유효성은 검사하지 않음. **link checker** (markdown 파일 간 상대 경로 검증 도구)가 있으면 F1 같은 이슈를 자동 탐지 가능. `remark-validate-links`나 `markdown-link-check` 같은 도구를 PostToolUse hook이나 CI에 통합하는 것을 고려할 수 있음.

---

> Deep retro 완료. Kent Beck(구조적 정리)과 Don Norman(인간 중심 디자인) 렌즈로 분석.
