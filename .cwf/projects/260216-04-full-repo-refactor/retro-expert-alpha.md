### Expert α: Martin Fowler

**Framework**: 리팩터링 패턴, 지식 중복의 Rule of Three, 공유 추상화, 진화적 설계 (Evolutionary Design)
**Source**: Refactoring: Improving the Design of Existing Code 2nd ed. (2018), Is Design Dead? (martinfowler.com), BeckDesignRules (martinfowler.com/bliki)
**Why this applies**: 이 세션은 13개 스킬과 7개 훅 그룹에 대한 전면 리팩터링 세션이었다. 리팩터링의 시기 판단, 추출 임계값, 그리고 "문서가 코드를 따라야 하는가 vs 코드가 문서를 따라야 하는가"라는 긴장이 세션 전반에 걸쳐 반복적으로 나타났으며, 이는 정확히 리팩터링 패턴과 진화적 설계의 분석 범위에 해당한다.

---

**Moment 1: CORCA003 린트 vs 컨벤션 문서 충돌 -- "코드 냄새"의 방향을 잘못 읽을 뻔한 순간**

CDM 1에서 13개 SKILL.md 전부가 single-line `"` 형식을 사용하는데 `skill-conventions.md`는 multi-line `|`을 요구하는 상황이 발견됐다. 세션에서는 "린트가 SSOT"라는 AUTO_EXISTING 원칙으로 빠르게 해결했고, 이 판단은 올바랐다.

나의 관점에서 보면 이것은 *Refactoring* 2판에서 강조하는 **Divergent Change vs Shotgun Surgery** 냄새의 변형이다. `skill-conventions.md`는 "한 곳을 바꿀 때 여러 곳을 따라 바꿔야 하는" Shotgun Surgery의 전형적 원천이 될 수 있었다. 만약 컨벤션 문서를 SSOT로 삼았다면, 앞으로 컨벤션을 고칠 때마다 13개 파일 + 린트 규칙을 동시에 수정해야 하는 상황이 영속화됐을 것이다.

그러나 여기서 CDM이 포착하지 못한 것이 하나 있다. Holistic Convention 분석(`refactor-holistic-convention.md:108-136`)에서 밝혀진 Universal Rules 준수율을 보면, Rule 2(cwf-state.yaml SSOT)는 11개 해당 스킬 중 2개만 포함, Rule 3(auto-init)은 0개, Rule 4(context-deficit resilience)는 1개만 포함하고 있다. 이것은 CORCA003과 동일한 패턴의 충돌이지만 **아직 린트 규칙이 존재하지 않는** 영역이다. 즉, CDM 1의 교훈("자동화 게이트가 문서를 이긴다")을 적용하면, 이 Universal Rules의 준수율 문제는 문서에 쓰는 것만으로는 해결되지 않는다는 결론에 도달한다. 현재 상태는 *Is Design Dead?*에서 경고하는 "BDUF(Big Design Up Front) 문서가 코드와 괴리되는 순간"과 구조적으로 동일하다. 컨벤션 문서에 5개 Universal Rule을 선언해놓고 실제로는 아무도 따르지 않는 상황은, 문서가 존재함으로써 오히려 "이미 해결된 문제"라는 착시를 만든다.

내가 이 시점에 있었다면, CORCA003의 해결을 "린트 규칙이 있으면 린트가 이긴다"에서 한 단계 더 나아가 **"린트 규칙이 없는 컨벤션 항목은 컨벤션이 아니라 소원(wish)"으로 재분류**하는 작업을 추가했을 것이다. *BeckDesignRules*의 네 번째 규칙 "Fewest Elements"의 관점에서, 자동 강제 수단이 없는 컨벤션 항목은 시스템의 요소 수만 늘리고 실제 행동을 바꾸지 못한다. 이 항목들은 `skill-conventions.md`에서 삭제하거나, "미구현 후보" 섹션으로 명시적으로 격하시키는 것이 정직한 설계다.

---

**Moment 2: Expert Roster 추출 -- Rule of Three의 정확한 적용, 그러나 추출의 "깊이"가 아쉬웠던 순간**

CDM 2에서 clarify, review, retro 3개 스킬의 expert roster 로직을 `expert-advisor-guide.md`의 Roster Maintenance 섹션으로 추출한 결정은 교과서적이었다. 나의 Rule of Three -- "처음 중복이 보이면 참고, 두 번째에 주의하고, 세 번째에 추출하라" -- 에 정확히 부합한다.

CDM 분석이 "개념 구현의 비대칭을 가시화하는 것이 추출의 가치"라고 기록한 것에 특히 동의한다. 이것은 *Refactoring* 2판에서 Extract Function의 동기를 "중복 제거"가 아니라 "의도와 구현의 분리"로 설명한 것과 같은 맥락이다. retro만 update하고 clarify/review는 read만 하는 비대칭이 세 개의 다른 파일에 산재해 있을 때는 보이지 않지만, 한 곳에 모아 Roster Maintenance 섹션으로 추출하면 이 비대칭이 즉시 가시화된다.

그런데 `refactor-holistic-convention.md:297-424`의 구조 추출 후보 분석을 보면, 추출해야 할 패턴이 7개 더 남아 있다. 특히 Pattern 1(Sub-Agent Output Persistence Block)은 5개 스킬에 걸쳐 25회 이상 반복되고, Pattern 6(Web Research Protocol)은 4개 스킬의 서브에이전트 프롬프트에 거의 동일한 텍스트로 반복된다. 이들은 이미 Rule of Three를 한참 초과한 상태다. Expert Roster 추출에 집중하는 동안 이 더 광범위한 추출 기회들이 미뤄졌다.

내 관점에서 이것은 **Extract Function vs Inline Function의 우선순위 문제**다. Expert Roster 추출은 개념적 명확성 관점에서 높은 가치가 있었지만, 순수 중복 규모(25+ 인스턴스)로 보면 Pattern 1이 더 높은 ROI를 가진다. 리팩터링 세션에서 나는 항상 "변경 빈도 x 인스턴스 수"를 기준으로 추출 우선순위를 정하라고 조언한다. Sub-Agent Output Persistence Block은 새 스킬이 추가될 때마다 반드시 복사해야 하므로 변경 빈도가 높고, 현재 25+ 인스턴스이므로 앞으로의 불일치 위험도 가장 크다.

---

**Moment 3: Ship 하드코딩 8개 일괄 수정 -- 토큰 압력이 만들어낸 "일관된 리팩터링"의 아이러니**

CDM 3에서 ship 스킬의 8개 하드코딩 값을 한 번에 수정한 결정은 흥미로운 사례다. CDM 분석은 `token_limit_reached=true` 상황이 "한 번에 8개를 처리"하는 방향을 강화했다고 기록하고 있다.

*Refactoring* 2판에서 나는 "작은 단계로 리팩터링하되 각 단계마다 테스트를 돌려라"고 강조한다. 8개 값을 한 번에 바꾸는 것은 이 원칙에서 벗어나는 것처럼 보이지만, 실제로는 더 깊은 패턴이 작동하고 있다. 이 8개 값은 모두 **같은 냄새(Hardcoded Environment Assumption)의 인스턴스**였다. Language 선언, base branch, PR 템플릿 내 한국어 리터럴 -- 이들은 독립된 문제가 아니라 "ship 스킬이 특정 환경을 가정한다"는 하나의 설계 결함의 8가지 증상이다. 리팩터링에서 **같은 냄새의 모든 인스턴스를 한 번에 수정하는 것**은 오히려 권장되는 접근이다. 분할 처리는 중간 상태에서 "일부는 동적, 일부는 정적"이라는 새로운 불일치를 만든다.

여기서 CDM이 다루지 않은 구조적 관찰이 있다. `refactor-holistic-convention.md:82-94`의 Language 선언 분석을 보면, ship만이 아니라 review("Match the user's language for synthesis")와 plugin-deploy("Match the user's language.")도 표준 패턴에서 벗어나 있다. 이들은 ship처럼 하드코딩은 아니지만, "같은 컨벤션을 다른 방식으로 표현하는" 변형이다. *Refactoring* 2판의 **Rename Variable** 리팩터링이 겉보기에 사소해 보이지만 누적되면 개념적 일관성을 해치는 것과 동일한 패턴이다. Ship의 8개를 고친 시점에 review와 plugin-deploy의 Language 선언도 표준 패턴으로 정규화했다면, "Language 선언 정규화"라는 하나의 일관된 커밋이 됐을 것이다. 부분 수정은 "어디까지 고쳤고 어디가 남았는지"를 추적해야 하는 인지 부하를 남긴다.

---

**Recommendations**:

1. **"린트 없는 컨벤션"을 식별하고 명시적으로 격하시켜라.** `skill-conventions.md`의 5개 Universal Rule 중 자동 강제 수단(린트, 훅, 스크립트)이 없는 항목을 `## Aspirational (not enforced)` 섹션으로 이동하라. CDM 1의 교훈을 일반화하면, 자동 강제 수단이 없는 문서 규칙은 시간이 지나면 반드시 실제 관행과 괴리된다. 이 격하 작업 자체가 "어떤 항목에 린트를 만들어야 하는가"의 우선순위 목록이 된다. BeckDesignRules의 "Fewest Elements" 원칙에 따라, 행동을 바꾸지 못하는 규칙은 존재하지 않는 것보다 나쁘다 -- 해결됐다는 착시를 만들기 때문이다.

2. **추출 우선순위를 "변경 빈도 x 인스턴스 수"로 재정렬하라.** `refactor-holistic-convention.md`에서 식별된 7개 추출 후보를 이 기준으로 재순위화하면, Pattern 1(Sub-Agent Output Persistence Block, 5 스킬 25+ 인스턴스)과 Pattern 6(Web Research Protocol, 4 스킬 8+ 인스턴스)이 최상위로 올라온다. Expert Roster 추출은 개념 명확성 관점에서 이미 완료되었으므로, 다음 리팩터링 라운드에서는 순수 중복 규모가 큰 항목을 우선 처리하라. 새 스킬 추가 시 복사해야 하는 boilerplate가 줄어들수록 Shotgun Surgery 냄새가 줄어들고, 한 곳을 고치면 모든 스킬에 반영되는 진화적 설계가 가능해진다.

<!-- AGENT_COMPLETE -->
