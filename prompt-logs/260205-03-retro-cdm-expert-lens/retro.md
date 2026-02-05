# Retro: retro v1.6.0 — CDM + Expert Lens 구현

> Session date: 2026-02-05

## 1. Context Worth Remembering

- Claude Code 플러그인 스킬은 **소스 디렉토리가 아닌 플러그인 캐시 디렉토리**(`~/.claude/plugins/cache/{marketplace}/{plugin}/{version}/`)에서 로드됨. 소스 수정 후 `claude plugin update` 또는 `scripts/update-all.sh`를 실행해야 캐시가 갱신됨.
- 스킬 메타데이터(description, allowed-tools)와 SKILL.md 본문 모두 캐시 기반. 새 세션이 아니라 **캐시 업데이트가 핵심**.
- Hooks는 세션 시작 시 스냅샷(이미 알려진 사실), Skills도 캐시 기반 스냅샷(이번에 확인). 즉, 플러그인 시스템 전체가 세션 시작 시점의 캐시 상태에 의존.
- `Task` 도구를 통한 서브에이전트는 스킬의 `allowed-tools` 제한과 별개로 메인 대화에서 직접 호출하면 동작함. 스킬 시스템 외부에서의 수동 실행은 도구 제한을 우회.

## 2. Collaboration Preferences

- 사용자가 이전 세션(260205-02)의 retro에서 CDM 통합을 직접 제안 → retro 결과물이 다음 세션의 입력이 되는 순환 구조가 작동 중.
- "흐름이 끊기는 게 싫네요" — 완벽한 테스트보다 학습 연속성을 우선시. 불완전하더라도 시도하면서 배우는 접근을 선호.
- 개밥먹기(dogfooding)에 적극적: 도구를 만드는 세션에서 그 도구를 바로 테스트하려는 패턴.

### Suggested CLAUDE.md Updates

- 없음. 기존 "Dogfooding: new tools are tested in the session that creates them" (project-context.md)이 이미 이 패턴을 반영.

## 3. Prompting Habits

- 플랜에서 구현으로의 전환이 매끄러움 — "Implement the following plan:" + 전체 플랜 제공은 효과적인 패턴. 모호함 없이 바로 실행 가능.
- "cache update로 이 세션에서 바로 retro 테스트를 할 수 있나요?" — 가설을 질문 형태로 제시한 것이 좋았음. 이로 인해 캐시 동작에 대한 공동 탐구가 시작됨.

## 4. Critical Decision Analysis (CDM)

### CDM 1: CDM을 무조건적(unconditional) 섹션으로 결정

| Probe | Analysis |
|-------|----------|
| **Cues** | 이전 세션 retro에서 CDM이 디버깅 회고에 매우 효과적이었다는 실증 데이터. "적용 조건: 디버깅, 인시던트 대응, 어려운 기술적 결정"이라고 기록됨 |
| **Goals** | 모든 세션에서 의사결정 분석의 가치를 제공 vs 불필요한 섹션으로 retro를 부풀리지 않기 |
| **Options** | (A) 무조건적 — 모든 retro에 CDM 포함 (선택됨) / (B) 조건부 — 디버깅/인시던트 세션에만 |
| **Basis** | "모든 retro-worthy 세션에는 분석할 가치가 있는 의사결정이 있다"는 전제. 설계 세션, 구현 세션, 디버깅 세션 모두 판단의 순간이 존재 |
| **Experience** | CDM 원 논문에서 "non-routine events"로 제한한 것과 차이. 루틴한 세션에서는 CDM이 강제되면 trivial한 결정을 부풀릴 위험 |
| **Hypothesis** | 만약 조건부로 했다면, CDM이 가장 필요한 세션에서 "조건 미달"로 건너뛰는 false negative가 발생할 수 있음. 무조건적으로 두되 가이드에서 "trivial한 선택을 부풀리지 말 것"이라는 제약으로 보완 |

**핵심 교훈**: 분석 도구는 "적용 여부"보다 "적용 깊이"로 조절하는 것이 안전하다. 무조건 적용하되 가이드에서 품질 기준을 명시하면, 적용/미적용의 이진 판단을 피할 수 있다.

### CDM 2: Expert Lens를 병렬 서브에이전트로 실행하는 설계

| Probe | Analysis |
|-------|----------|
| **Cues** | deep-clarify의 alpha/beta Advisory 패턴이 이미 검증됨. 독립적 관점을 보장하려면 격리된 실행이 필요 |
| **Goals** | 독립적 전문가 관점 확보 vs 컨텍스트 전달 비용 최소화 |
| **Options** | (A) 메인 에이전트가 순차적으로 두 관점 작성 / (B) 병렬 서브에이전트 (선택됨) / (C) 단일 서브에이전트가 두 관점 모두 작성 |
| **Basis** | 메인 에이전트가 순차적으로 작성하면 첫 전문가의 분석이 두 번째에 앵커링 효과를 줌. 서브에이전트는 서로의 출력에 접근 불가 → 독립성 구조적으로 보장 |
| **Knowledge** | Kahneman의 *Noise* — 독립적 판단의 집계가 노이즈를 줄인다. 순차적 참조는 앵커링 유발 |
| **Aiding** | "독립성이 필요한 분석은 격리된 실행 환경에서" — deep-clarify에서 이미 검증된 휴리스틱 |
| **Tools** | Task 도구의 병렬 실행 기능. 각 서브에이전트에 WebSearch 접근 권한 필요 (전문가 검증용) |

**핵심 교훈**: 다중 관점 분석에서 독립성은 프롬프트 지시("서로 영향받지 마세요")가 아니라 실행 격리(별도 서브에이전트)로 보장해야 한다. 구조가 지시보다 강하다.

### CDM 3: 캐시 문제에도 불구하고 세션 내 테스트를 시도한 결정

| Probe | Analysis |
|-------|----------|
| **Cues** | 사용자: "cache update로 이 세션에서 바로 retro 테스트를 할 수 있나요?" → 가능성에 대한 탐색 의지 |
| **Goals** | 흐름 연속성 유지 vs 완전한 테스트 환경 확보 |
| **Options** | (A) 커밋 → update-all → 새 세션에서 테스트 / (B) 세션 내 수동 테스트 (선택됨) |
| **Basis** | 사용자의 "흐름이 끊기는 게 싫네요"라는 명시적 선호. 캐시 로딩 동작을 확인하는 것 자체가 학습 가치가 있다는 판단 |
| **Situation Assessment** | 올바른 평가. 스킬이 캐시에서 로드된다는 발견은 세션에서 가장 가치 있는 학습 중 하나. 완벽한 환경을 기다렸다면 이 발견이 지연됨 |
| **Hypothesis** | 만약 새 세션에서 테스트했다면, 캐시 로딩 메커니즘을 명시적으로 발견하지 못했을 수 있음. update-all이 캐시를 갱신한 후에는 "그냥 동작"하므로 내부 구조를 관찰할 기회가 없었을 것 |

**핵심 교훈**: 불완전한 환경에서의 테스트는 "테스트 실패"가 아니라 "시스템 동작 관찰 기회"가 될 수 있다. 실패 모드에서 더 많은 것을 배운다.

## 5. Expert Lens

### Expert alpha: Gary Klein

**Framework**: 자연주의적 의사결정(Naturalistic Decision Making) — 전문가들이 시간 압박, 불확실성, 높은 리스크 하에서 옵션 비교 없이 패턴 인식과 멘탈 시뮬레이션을 통해 의사결정하는 과정을 연구하는 접근법
**Source**: *Sources of Power: How People Make Decisions* (MIT Press, 1998); *Seeing What Others Don't: The Remarkable Ways We Gain Insights* (PublicAffairs, 2013)
**Why this applies**: CDM 자체가 이 세션에서 구현된 핵심 기능이며, 동시에 세션 내 의사결정 과정이 Klein의 RPD 모델로 분석할 수 있는 전형적 사례.

이 세션의 설계 결정들은 Klein이 RPD 모델 Variation 1(전형적 상황 인식)로 기술한 패턴을 보여준다. 설계자는 여러 대안을 체계적으로 비교·평가하는 대신, 첫 번째로 떠오른 적절한 방안을 멘탈 시뮬레이션으로 검증한 후 채택하는 패턴을 반복했다. "CDM을 무조건 포함"이라는 결정은 "회고에서 의사결정 분석이 항상 가치 있다"는 도메인 인식에서 즉각 도출되었고, "서브에이전트 vs 메인 에이전트" 결정에서는 멘탈 시뮬레이션을 통해 독립성 보장 방법을 예측한 후 선택했다. *Sources of Power*에서 소방대장들의 의사결정과 동일한 패턴 — 전문가는 옵션을 나열하고 비교하지 않으며, 상황을 인식하고 첫 번째 적합한 행동 방침을 시뮬레이션한다.

캐시 디렉토리 발견은 *Seeing What Others Don't*에서 분류한 인사이트의 **모순(contradiction) 경로**에 해당한다. 기대("소스를 수정하면 즉시 반영된다")와 현실("캐시에서 로드되므로 반영되지 않는다") 사이의 불일치를 감지하고, 이를 무시하지 않고 추적하여 시스템 아키텍처에 대한 새로운 이해에 도달했다. 점진적 테스트(incremental verification) 접근법이 이를 가능하게 했다.

**Recommendations**:
1. CDM 분석 가이드에 인지 탐침 프롬프트를 보강 — "이 결정에서 어떤 대안이 고려되었는가?", "어떤 경험/패턴이 이 선택을 이끌었는가?"를 대화 맥락에서 추출하도록 가이드하여, CDM의 반구조화 인터뷰를 자동 분석에 근사할 것
2. 인사이트 순간을 세 경로(연결, 모순, 창의적 절망)로 태깅하여 기록 — 인사이트 발생 조건의 재현성 향상

### Expert beta: Daniel Kahneman

**Framework**: 인간 판단의 이중 프로세스 이론 — 빠르고 직관적인 System 1과 느리고 의도적인 System 2의 상호작용이 의사결정의 질을 결정한다.
**Source**: *Thinking, Fast and Slow* (2011); *Noise: A Flaw in Human Judgment* (2021, Sibony, Sunstein 공저)
**Why this applies**: 5개의 설계 결정을 연속으로 내리는 과정에서 System 1과 System 2 전환이 반복 관찰되며, planning fallacy의 사례도 발견됨.

가장 주목할 인지적 패턴은 **앵커링 효과**다. CDM을 무조건적 섹션으로 결정할 때 초기 제안이 앵커로 작용했다. 이 결정 자체는 합리적이었으나, 그 후 Expert Lens의 병렬 서브에이전트 패턴이라는 더 복잡한 결정도 같은 속도로 처리된 점은 WYSIATI(what you see is all there is) 편향의 징후다.

반면, **plan mode 프로토콜**은 *Noise*에서 제안한 **결정 위생(decision hygiene)** 원칙과 정확히 일치하는 구조를 보여준다. 판단을 독립적 단계로 분해하고 순차 수행 후 집계하라는 권고와 8개 파일의 구현을 개별 태스크로 분해·검증한 것이 대응된다. 그러나 테스팅 단계에서 **planning fallacy**(inside view)가 관찰됨 — 캐시 업데이트 없이 세션 내 테스트가 성공할 것이라는 낙관적 시나리오에 근거한 판단. 결과적으로 캐시 구조를 발견한 것은 가치 있었으나, outside view를 먼저 적용했다면 테스트 전략을 더 효율적으로 설계할 수 있었을 것.

Expert Lens의 설계 자체에서 흥미로운 점: alpha와 beta가 독립적으로 분석한 후 결과를 종합하는 패턴은 *Noise*의 다중 관점 집계 원리의 적절한 적용이다. 상호 참조 없이 독립적으로 실행되어야 노이즈 감소 효과가 유지된다.

**Recommendations**:
1. 세션 내 테스트 결정 전 reference class forecasting 질문을 명시적으로 던질 것 — "과거에 유사한 세션 내 테스트가 성공한 비율은?"
2. Expert Lens의 독립성을 구조적으로 보장할 것 — alpha와 beta 서브에이전트 간 컨텍스트 격리를 실행 순서로 명시

## 6. Learning Resources

- [CDM - Critical Decision Method (Gary Klein)](https://www.gary-klein.com/cdm) — CDM 방법론의 원 출처. CDM은 비일상적 상황에서의 전문가 의사결정을 회고적으로 분석하는 반구조화 인터뷰 기법으로, 단서(Cues), 지식(Knowledge), 유추(Analogues) 등 12가지 인지 탐침을 사용한다. 이번 세션에서 구현한 CDM 분석의 이론적 근거이며, 원 논문의 probe 설계 의도를 이해하면 가이드 개선에 도움.

- [Sounding the Alarm on System Noise (McKinsey, Kahneman & Sibony 인터뷰)](https://www.mckinsey.com/capabilities/strategy-and-corporate-finance/our-insights/sounding-the-alarm-on-system-noise) — Kahneman과 Sibony가 "노이즈"(판단의 원치 않는 변동성)와 "결정 위생" 개념을 설명하는 인터뷰. Expert Lens의 독립적 서브에이전트 설계가 노이즈 감소 원리에 기반하며, 이 인터뷰에서 "독립적 판단의 집계"와 "앵커링 방지"의 실전 적용 방법을 다룸.

- [Structured Plugin Skills result in inflation of skills into system prompt (GitHub Issue #14549)](https://github.com/anthropics/claude-code/issues/14549) — Claude Code의 스킬 로딩 메커니즘이 marketplace.json을 캐시 디렉토리에서 읽는 구조를 설명하는 버그 리포트. 이번 세션에서 발견한 "소스 수정이 캐시에 반영되지 않는" 동작의 기술적 배경을 이해하는 데 직접적으로 관련됨.

## 7. Relevant Skills

이 세션에서 새로운 스킬 갭은 식별되지 않음. retro v1.6.0 자체가 이전 세션의 retro에서 식별된 개선 사항(CDM 통합, Expert Lens)을 구현한 것이며, 이 순환이 의도대로 작동 중.

다만, 캐시 업데이트 → 테스트 → 배포 워크플로우가 반복되면서, `/plugin-deploy` 스킬이 이미 이 흐름을 자동화하고 있으므로 추가 도구는 불필요.
