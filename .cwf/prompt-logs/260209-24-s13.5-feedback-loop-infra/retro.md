# Retro: S13.5-A Self-Healing Provenance System

> Session date: 2026-02-09
> Mode: deep

## 1. Context Worth Remembering

- 유저는 "구현 → 리뷰 커밋 → 수정 커밋" 히스토리 패턴을 워크플로우 규칙으로 확립하고자 함. 커밋 히스토리가 자기설명적이어야 한다는 원칙
- 리뷰 결과는 conversation이 아닌 파일로 남아야 한다 — 각 리뷰어 개별 파일 + 합성 파일
- `marketplace-v3` 브랜치가 umbrella, 그 위에 워크스트림별 sub-branch 생성이 기대 패턴
- 유저는 워크플로우 자율화/자동화를 지속적으로 지향 — "이건 앞으로도 워크플로우에 반영할 규칙입니다"

## 2. Collaboration Preferences

- 유저가 규칙의 근거를 묻는 것은 "왜?"를 중시하는 사고방식 — Rule 5 조사를 요청한 것이 그 예. 규칙이 있으면 이유가 있어야 한다
- 유저는 발견한 문제를 즉시 시스템에 반영하길 원함 — "이번에 복구하기 쉬우면 그렇게 하고, 아니면 넘어갑시다. 앞으로는 그렇게 되면 됩니다"
- 리뷰 전 커밋, 리뷰 후 커밋 — 순서에 대한 명확한 기대가 있음

### Suggested CLAUDE.md Updates

- 없음 — 이번 세션 발견 사항은 주로 review/ship 스킬 수정 대상

## 3. Waste Reduction

### `.sh` 파일을 markdownlint에 넘긴 실수

markdownlint 검증 시 `scripts/provenance-check.sh`를 대상에 포함. 39개 "에러"가 모두 bash 주석을 markdown heading으로 오인한 것.

**5 Whys**:
1. 왜? → 수정한 파일 목록을 수동으로 나열할 때 `.sh` 파일을 포함
2. 왜? → lint 대상 결정이 "수정된 파일 중 markdown 파일"이라는 필터 없이 전체 수정 파일 목록을 사용
3. 왜? → lint 대상 선정에 결정론적 알고리즘이 없음 — 에이전트 재량에 의존
4. **근본 원인**: lint 대상을 확장자 기반으로 필터링하는 단계가 워크플로우에 없음

**해결 방향**: 수정 파일 대상으로 lint 돌릴 때, 확장자 필터를 결정론적으로 적용하는 helper (예: `git diff --name-only '*.md'` 패턴) 를 스크립트 또는 리뷰 스킬에 내장. 에이전트 지능은 "어떤 lint를 돌릴지" 판단에 쓰고, "어떤 파일에 돌릴지"는 알고리즘이 보조.

### 리뷰 커밋 시 handoff SKILL.md 되돌림

`git add`로 lessons.md를 staging할 때 다른 파일(handoff SKILL.md)이 이전 상태로 함께 커밋됨. 수정 사항이 사라진 것을 이후 Concern 수정 단계에서 발견.

**5 Whys**:
1. 왜? → `git add`가 의도하지 않은 파일 상태를 포함
2. 왜? → working tree에 아직 staging되지 않은 변경과 이미 커밋된 변경이 혼재
3. 왜? → 리뷰 파일 커밋 시 `git status`로 전체 상태를 확인하지 않음
4. **근본 원인**: 커밋 전 `git diff --cached --stat` 확인을 일관되게 하지 않음

### Sub-branch 생성 누락

핸드오프에 명시된 브랜치 워크플로우를 세션 시작 시 따르지 않음. 세션 중간에야 발견.

**5 Whys**: lessons.md에 이미 분석 완료 — 세션 시작 프로토콜에 "브랜치 확인" 단계 부재.

## 4. Critical Decision Analysis (CDM)

### CDM 1: Review 스킬 Rule 5를 즉시 수정하지 않고 deferred action으로 남긴 결정

| Probe | Analysis |
|-------|----------|
| **Cues** | 유저가 "리뷰 결과가 무조건 파일로 남는다고 생각했습니다" — 기대와 실제의 괴리 발견 |
| **Goals** | Rule 5 근거 조사 vs 즉시 수정 vs 현재 세션 스코프 유지 |
| **Options** | (1) Rule 5 즉시 수정 + 리뷰 스킬 업데이트 (2) 이번 세션만 파일로 남기고 수정은 deferred (3) 무시하고 conversation 출력 |
| **Basis** | 유저가 "이번 리뷰는 파일로 남기고, Rule 5 수정은 deferred"로 명시적 판단. 현재 세션 스코프(provenance 시스템) 유지 우선 |
| **Aiding** | deferred action 목록이 lessons.md에 명시적으로 기록되어 있어서 유실 방지 장치가 작동 |

**Key lesson**: 발견된 문제의 즉시 수정 vs deferred 판단에서, 현재 세션 스코프와 수정 범위의 비례성이 기준이 됨. 작은 수정이면 즉시, 스킬 전체 수정이면 deferred.

### CDM 2: 리뷰 결과를 "합성 1파일"에서 "개별 4파일 + 합성"으로 확장한 결정

| Probe | Analysis |
|-------|----------|
| **Cues** | 유저: "각 리뷰어의 리뷰가 개별 파일이 아닌 것 같은데" — 암묵적 기대 표면화 |
| **Goals** | 리뷰 추적성 (누가 뭘 말했는지) vs 파일 수 최소화 |
| **Options** | (1) 합성만 유지 (2) 개별 파일 추가 (3) 개별만, 합성 없음 |
| **Basis** | 합성은 verdict와 우선순위를 제공하고, 개별은 원본 추적성을 제공 — 둘 다 필요. 복구가 쉬운 상황이어서 즉시 적용 |
| **Hypothesis** | 합성만 남겼다면 — 나중에 "Security 리뷰어가 정확히 뭐라고 했지?" 질문에 답할 수 없었을 것 |
| **Aiding** | review 스킬에 "개별 리뷰어 파일 저장" 규칙이 있었다면 처음부터 올바르게 작동 |

**Key lesson**: 리뷰 산출물은 합성(verdict) + 개별(provenance/원본) 양쪽 모두 필요. 합성만으로는 추적성이 부족하고, 개별만으로는 우선순위 판단이 어려움.

### CDM 3: "구현 → 리뷰 → 수정"을 별도 커밋으로 쌓기로 한 결정

| Probe | Analysis |
|-------|----------|
| **Cues** | 유저: "커밋 히스토리만 봐도 무슨 일이 일어났었는지 알 수 있게" |
| **Goals** | git history 가독성 vs 커밋 수 최소화 |
| **Options** | (1) squash merge (깔끔하지만 이력 유실) (2) 단계별 커밋 (이력 보존) (3) amend (위험) |
| **Basis** | 유저가 이력 보존을 명시적으로 요구. "앞으로도 워크플로우에 반영할 규칙" |
| **Analogues** | provenance 시스템 자체가 "맥락 유실 방지" — 커밋 히스토리도 같은 원칙 적용 |

**Key lesson**: `impl → review → fix` 커밋 패턴은 self-documenting history의 최소 단위. 워크플로우 규칙으로 성문화 대상.

## 5. Expert Lens

### Expert alpha: Donella Meadows

**Framework**: 시스템의 구조가 행동을 결정한다 — 피드백 루프, 레버리지 포인트, 정보 흐름 구조를 통해 시스템 행동을 분석하는 시스템 사고(Systems Thinking)
**Source**: *Thinking in Systems: A Primer* (2008), "Leverage Points: Places to Intervene in a System" (1999)
**Why this applies**: 이 세션의 핵심 문제 — "문서가 시스템 성장에 따라 진부해진다" — 는 본질적으로 **정보 피드백 루프의 부재** 문제이다. Meadows의 12가지 레버리지 포인트 프레임워크는 provenance 시스템이 정확히 어느 수준의 개입인지, 그리고 더 효과적인 개입 지점이 있는지를 구조적으로 드러낸다.

이 세션에서 가장 주목할 만한 것은 **정보 흐름 구조(leverage point #6)** 에 대한 개입이다. Meadows는 "의사결정자가 가지고 있지 않은 정보에는 반응할 수 없고, 부정확한 정보에는 정확하게 반응할 수 없으며, 늦게 도착하는 정보에는 적시에 반응할 수 없다"고 강조했다. `.provenance.yaml` 사이드카 파일과 `provenance-check.sh` 스크립트는 정확히 이 문제를 해결한다 — 문서의 진부함이라는 **숨겨진 정보를 의사결정 시점에 가시화**하는 것이다. 3단계 응답 체계(inform/warn/stop)는 Meadows의 **부정적 피드백 루프(leverage point #8)** 설계와 일치한다 — 이탈이 작을 때는 약한 교정, 클 때는 강한 교정이 작동하는 자기 교정 메커니즘이다.

그러나 Meadows의 시선으로 보면, 이 시스템에는 구조적 한계가 있다. count 기반 프록시는 Meadows가 말하는 **"상수, 파라미터, 숫자"(leverage point #12, 가장 약한 개입)** 수준이다. 세션에서도 인식했듯이 "count는 결과적 현상이고, 실제 진부함 신호는 scope expansion"이다. 진짜 레버리지는 count라는 숫자가 아니라, **어떤 정보가 누구에게 언제 도달하는가**라는 정보 흐름의 구조에 있다. 하이브리드 접근(결정론적 count + 비결정론적 agent 평가)은 이 한계를 부분적으로 보완하지만, agent 평가 부분은 아직 자동화된 피드백 루프에 통합되지 않았다. Meadows가 "Dancing with Systems"에서 강조한 **"시스템의 지혜에 귀 기울이라"** 는 원칙에 따르면, 각 skill/hook이 자신의 "영향 범위"를 선언하는 자기조직화(leverage point #4) 메커니즘이, 외부에서 count를 세는 것보다 더 높은 레버리지 포인트에 해당한다.

Rule 5 문제("output to conversation"이 근거 없이 규칙으로 굳어진 것)는 Meadows의 시스템 아키타입 중 **"부담 전가(Shifting the Burden)"** 와 유사하다. 임시 해결책(대화 출력)이 근본 해결책(파일 출력)을 대체하면서 의존성을 만들었고, 시간이 지나면서 원래 왜 그렇게 했는지의 맥락이 사라졌다. "Deterministic validation over behavioral instruction"이라는 교훈은 Meadows 프레임워크에서 **시스템 규칙(leverage point #5)** 이 **파라미터(leverage point #12)** 보다 효과적이라는 원리와 정확히 대응한다.

**Recommendations**:
1. **역방향 피드백 루프 추가**: 현재는 "check 시점에 진부함을 감지"하는 단방향이다. Meadows의 leverage point #6 원칙에 따라, 새 skill/hook이 추가되는 커밋 시점에 pre-commit hook이 관련 `.provenance.yaml`의 staleness를 자동 평가하여 변화 발생 시점에 즉시 정보를 전달하라.
2. **자기조직화 구조로 진화**: count 기반 프록시(leverage point #12)에서 벗어나, 각 skill의 메타데이터에 `affects: [criteria/analysis.md, CLAUDE.md#testing]` 필드를 두어 영향 관계가 시스템 성장 시 자동으로 갱신되는 자기조직화(leverage point #4) 구조를 지향하라.

### Expert beta: David Woods

**Framework**: Graceful extensibility — 적응적 시스템이 포화 위험을 관리하고, 설계 경계를 넘어 성능을 확장하며, 취약성을 감지하는 방식을 지배하는 기본 법칙
**Source**: Woods, D. D. (2018). "The theory of graceful extensibility: basic rules that govern adaptive systems." *Environment Systems and Decisions*, 38(4), 433-457.
**Why this applies**: 이 세션은 에이전트 생태계의 brittleness를 사전 감지하는 provenance 시스템을 구축했다. 이것은 정확히 Woods의 S3("모든 유닛은 적응 능력의 포화 위험을 가진다")와 S10("자신의 적응 능력에 대한 모델은 실제 능력과 불일치할 수 있다")이 다루는 문제 공간이다.

**S3(포화 위험 관리)의 성공적 구현과 한계.** 3-level response(inform/warn/stop)는 Woods의 S3 — "모든 유닛은 적응 능력의 포화를 위험으로 관리해야 하며, 적응 능력을 수정하거나 확장할 수단이 필요하다" — 를 구조적으로 반영한다. `inform`은 정상 작동, `warn`은 포화 접근 신호, `stop`은 포화 도달 시 정지다. 그러나 리뷰에서 드러난 것처럼 `--level stop`과 `warn`의 실질적 행동 차이가 없다. Woods의 S7("포화에 접근할 때의 성능은 포화로부터 먼 상태의 성능과 다르다")이 요구하는 것은 바로 이 구분된 대응 모드(base vs extended adaptive capacity)다. `stop`이 `warn`과 행동적으로 같다면, 시스템은 단일 적응 모드만 가진 것이며, 이는 brittleness의 한 형태다.

**S10(mis-calibration)과 hybrid staleness 설계의 정합성.** 이 세션에서 가장 인상적인 설계 판단은 결정론적 count proxy + 비결정론적 agent scope evaluation의 hybrid 접근이다. 유저가 "숫자가 안 늘어나고 스킬 역할이 확대될 수도 있다"고 지적했을 때, 이는 Woods의 S10 — "자기 적응 능력에 대한 모델이 실제 능력과 정확히 일치하는 데는 한계가 있으며, mis-calibration은 예외가 아니라 상수" — 을 실증하는 순간이었다. `designed_for` 필드와 에이전트 판단을 보완층으로 넣은 것은 S9("어떤 관측 지점이든 동시에 드러내면서도 가리는 속성이 있다")에 대한 올바른 대응이다. 다만, `skill_count`가 없는 `.provenance.yaml`이 FRESH로 통과하는 문제(리뷰에서 수정됨)는 S10의 mis-calibration이 실현된 사례였다 — "측정할 수 없으면 정상"이라는 암묵적 가정이 brittleness가 조용히 축적되는 경로다.

**S4(상호의존)와 세션의 waste 패턴.** Review 스킬이 base branch를 잘못 감지하고, lint 대상에 `.sh`를 포함하고, `git add`가 handoff를 되돌린 세 사례는 S4가 설명하는 현상이다 — "어떤 단일 유닛도 포화 위험을 혼자 관리할 만큼 충분한 적응 행동 범위를 가질 수 없다." 에이전트가 혼자서 review, lint, git staging을 모두 관장할 때 발생한 실수들이다. 유저가 이를 감지하고 즉시 시스템에 반영한 패턴은 S5 — 이웃 유닛이 다른 유닛의 적응 능력을 확장하거나 제약하는 메커니즘 — 의 건강한 작동이다.

**Recommendations**:
1. **`stop` level에 실질적 차별화된 행동을 부여할 것 (S7 적용)**: `warn`은 사용자에게 알리고 계속 진행을 허용하지만, `stop`은 사용자 확인 없이는 스킬 실행을 차단해야 한다. 현재 둘이 동일하면, 3-level이라는 설계 의도가 실제로는 2-level로 퇴화한 것이며, 이는 mis-calibration(S10)을 영속화한다.
2. **Missing field를 STALE로 처리하는 fail-safe 디폴트 적용 (S10 적용)**: "모를 때는 안전한 쪽으로 가정"이어야 한다. `skill_count`가 없는 provenance 파일을 FRESH로 통과시키는 것은 측정 불가능성을 정상으로 취급하는 것이며, brittleness가 조용히 축적되는 경로다. (리뷰 후 수정 완료)

## 6. Learning Resources

### 1. Donella Meadows — "Leverage Points: Places to Intervene in a System" (1999)

**URL**: [donellameadows.org/archives/leverage-points-places-to-intervene-in-a-system](https://donellameadows.org/archives/leverage-points-places-to-intervene-in-a-system/)

시스템에 개입할 수 있는 12가지 지점을 효과가 낮은 것(파라미터 조정)에서 높은 것(패러다임 전환)까지 제시. 핵심: 사람들이 관심의 95%를 파라미터(숫자 조정)에 쏟지만, 진짜 변화는 정보 흐름 구조(#6), 시스템 규칙(#5), 자기조직화 능력(#4)에서 일어남. "빠진 피드백 루프를 복원하는 것이 물리적 인프라를 바꾸는 것보다 훨씬 저렴하고 효과적."

**이 세션과의 관련성**: provenance 시스템의 설계 수준을 평가하는 프레임워크. count proxy가 leverage point #12(파라미터)인 반면, 정보 흐름 구조 변경(#6)이나 자기조직화(#4)로 진화할 수 있는 방향을 제시한다.

### 2. David Woods — "The Theory of Graceful Extensibility" (2018)

**URL**: [doi.org/10.1007/s10669-018-9710-4](https://link.springer.com/article/10.1007/s10669-018-9710-4)

적응적 시스템의 10가지 기본 법칙(theorems). 핵심 개념: brittleness(설계 범위 내에서는 견고하지만 범위를 넘으면 갑자기 무너지는 것)와 graceful extensibility(범위를 넘어서도 점진적으로 적응하는 능력). S10 "mis-calibration은 예외가 아니라 상수" — 시스템이 자기 능력을 과대평가하는 것은 항상 발생한다.

**이 세션과의 관련성**: 이미 project-context.md에서 인용 중. provenance 시스템은 에이전트가 "자기 도구의 한계를 인식"하게 하는 메커니즘 — Woods의 boundary awareness 원칙의 구현체다.

### 3. W3C PROV — Provenance 데이터 모델

**URL**: [w3.org/TR/prov-overview](https://www.w3.org/TR/prov-overview/)

데이터 출처와 변환 이력을 추적하는 표준 모델. Entity(추적 대상), Activity(변환 처리), Agent(관여 주체)의 삼각 구조. "provenance란 데이터의 생산에 관여한 엔티티, 활동, 사람에 관한 정보로, 품질과 신뢰성을 평가하는 데 사용."

**이 세션과의 관련성**: `.provenance.yaml`의 설계를 공식 provenance 모델과 대조하면, 현재 스키마가 주로 Entity 속성(target, written_session)에 집중하고 Activity와 Agent 관계는 암묵적인 것을 확인할 수 있다. 향후 확장 시 PROV의 파생(derivation) 개념이 문서 간 의존성 추적에 유용할 수 있다.

## 7. Relevant Skills

### Installed Skills

- **cwf:refactor** — provenance check가 holistic mode에 통합됨. 다음 holistic 실행 시 자동으로 staleness 감지가 작동하는지 확인 필요
- **cwf:handoff** — Phase 4b (Unresolved Items)가 추가됨. 다음 핸드오프 실행 시 deferred actions 추출이 작동하는지 dogfooding 필요
- **/review** — 이번 세션에서 발견된 3개 deferred action (Rule 5 파일 저장, base branch 감지, 개별 리뷰어 파일)이 다음 세션에서 수정 대상

### Skill Gaps

- **Lint 대상 결정론적 필터링**: 수정 파일 기반으로 lint 돌릴 때 확장자 필터를 자동 적용하는 메커니즘이 없음. review 스킬 또는 별도 helper script에 `git diff --name-only -- '*.md'` 패턴을 내장하면 `.sh` → markdownlint 같은 실수 방지
- **세션 시작 프로토콜**: 핸드오프 문서의 브랜치 워크플로우, 컨텍스트 파일 읽기 등을 체크리스트로 강제하는 메커니즘 부재. cwf:impl이나 별도 `cwf:start` 스킬에 세션 시작 체크리스트를 넣는 것이 구조적 해결

### Post-Retro Findings

Deep retro 이후 토론에서 추가된 발견:

1. **Deep retro sub-agent 위임 확대**: sections 3-4(CDM, Waste)를 sub-agent에 위임하면 메인 에이전트의 역할이 "session facts 추출 + 합성"으로 축소. 컨텍스트 부담 감소로 deep retro를 항상 할 수 있게 됨
2. **Light → deep 재분석 원칙**: light retro가 존재해도 deep은 sections 1-4를 재활용하지 않고 처음부터 독립 분석해야 함. 기존 분석 위에 덧붙이는 것은 "신선한 뷰"를 제공하지 않음
3. **Structured session summary 보존**: retro 시작 시 session summary를 파일로 저장하면 compact 후에도 sub-agent 입력이 보존됨. Prompt-logger 확장보다 비용 효율적
4. **중간 산출물 파일 보존 패턴**: "수집 → sub-agent 위임" 구조의 모든 multi-phase 스킬(retro, review, refactor, clarify, impl)에 적용 가능. S13.6 CWF protocol 설계의 핵심 설계 포인트
5. **Plan mode → session plan.md deadlock**: EnterPlanMode hook이 plan-protocol을 주입하지만, plan mode의 쓰기 제약으로 `prompt-logs/` 경로에 plan.md를 생성할 수 없음
6. **Retro session symlink 팀 런 미대응**: prompt-logger는 다중 로그 준비 완료이나, retro/handoff 등 소비 측이 단일 symlink만 생성
