# CDM Analysis — S15 Agent-Browser Integration

> Gary Klein의 Critical Decision Method(CDM)를 적용한 S15 세션 분석.
> 세션 요약, plan.md, lessons.md, cwf-state.yaml, agent-patterns.md Web
> Research Protocol, S14 agent-browser-plan.md 기반.

---

## CDM 1: 인라인 규칙 교체 vs 프로토콜 참조 — SSOT 통합 전략

S15의 가장 핵심적인 설계 판단. clarify와 plan의 sub-agent 프롬프트에
이미 인라인으로 작성된 web research 규칙을 발견했을 때, (a) 인라인 규칙을
agent-browser를 포함하도록 업데이트할 것인지, (b) 인라인 규칙을 삭제하고
agent-patterns.md의 Web Research Protocol에 대한 참조로 대체할 것인지의
선택이 있었다.

| Probe | Analysis |
|-------|----------|
| **Cues** | clarify SKILL.md와 plan SKILL.md에서 WebFetch-only 인라인 규칙을 발견. 이 규칙들은 S14에서 agent-patterns.md가 two-tier(WebFetch + agent-browser)로 업데이트되었음에도 불구하고 여전히 WebFetch 단독 사용을 지시하고 있었다. lessons.md 기록: "clarify and plan had inline web research rules duplicating (and outdating) the protocol." 이미 드리프트가 발생한 상태가 핵심 단서였다. |
| **Goals** | (1) 모든 sub-agent가 agent-browser 폴백을 사용할 수 있게 만들기, (2) 향후 프로토콜 업데이트 시 변경 지점을 1곳으로 제한, (3) 기존 sub-agent 동작에 regression 없음. 목표 (1)과 (2)는 둘 다 참조 방식을 선호하지만, (3)은 기존 인라인 규칙에 미세한 스킬별 커스터마이징이 있을 경우 위험 요소가 된다. |
| **Options** | **A.** 인라인 규칙을 agent-browser 포함하도록 업데이트 — 각 스킬이 자체 완결적이지만, 5개 파일에서 동일한 규칙을 반복하며 향후 드리프트 위험이 재발. **B.** 인라인 규칙을 삭제하고 shared protocol 참조로 교체 — SSOT를 강제하지만, sub-agent가 참조 파일을 실제로 읽을 수 있는지에 의존. **C.** 하이브리드 — 핵심 결정 흐름만 인라인으로 요약하고 상세 규칙은 참조 연결. |
| **Basis** | 옵션 B 선택의 근거: (1) 이미 드리프트가 발생한 증거가 있었다 — S14에서 agent-patterns.md를 업데이트했지만 인라인 규칙은 그대로 남아 WebFetch-only를 지시. 이는 옵션 A의 실패 모드를 실시간으로 보여준 것이다. (2) skill-conventions.md의 References 섹션이 이미 `../../references/agent-patterns.md` 패턴을 공식화하고 있어서, 참조 방식이 기존 아키텍처와 일관성을 유지한다. |
| **Knowledge** | architecture-patterns.md의 "Sub-agent orchestration via SKILL.md" 패턴: "reference guides in `references/` hold domain knowledge." 이 원칙이 이미 코드베이스에 확립되어 있었으므로, web research 규칙도 같은 패턴을 따르는 것이 자연스러웠다. 또한 S13(Holistic Refactor)에서 4/9 스킬에 broken reference가 발견된 경험 — 참조가 끊어지면 검증 도구(check-session.sh, refactor)가 탐지할 수 있지만, 인라인 규칙의 staleness는 탐지 메커니즘이 없다. |
| **Analogues** | DRY(Don't Repeat Yourself) 원칙의 전형적 적용. 그러나 단순한 코드 중복 제거가 아니라 "지식의 중복 제거" — 인라인 규칙은 동일한 도메인 지식(web research 방법론)을 5곳에 복제하는 것이다. Ousterhout의 "information leakage" 개념과도 관련: 프로토콜 상세가 각 SKILL.md에 새어나가면, 프로토콜을 변경할 때 모든 누출 지점을 찾아야 한다. |
| **Hypothesis** | 옵션 A(인라인 업데이트)를 선택했다면: S15에서는 즉시 작동하지만, 다음에 Web Research Protocol이 업데이트될 때(예: 새로운 tier 추가, 임계값 변경) 같은 드리프트가 재발한다. 인라인 규칙을 가진 스킬 수가 7개이므로 7곳을 동시에 업데이트해야 하고, 한 곳이라도 누락되면 비일관적 동작이 발생한다. |

**핵심 교훈**: 프로토콜이 이미 드리프트한 상태를 발견했을 때, 해당 프로토콜의
인라인 복사본을 수리하지 말고 참조로 교체하라. 드리프트 발생 자체가
"인라인 방식은 이 도메인에서 유지보수할 수 없다"는 경험적 증거이다.

---

## CDM 2: 전체 범위 업데이트 vs 최소 범위 업데이트 — 방어적 일관성

7개 web-researching sub-agent 전체를 업데이트할 것인지, JS 렌더링이 실제로
필요한 sub-agent만 업데이트할 것인지의 범위 결정. retro의 Expert alpha/beta나
review의 Expert alpha/beta는 "전문가 신원 확인"용이라 JS-rendered 사이트에
접근할 빈도가 낮지만, S15에서는 이들도 포함하여 전체 7개 sub-agent를
업데이트했다.

| Probe | Analysis |
|-------|----------|
| **Cues** | plan.md의 "Affected sub-agents" 테이블에 7개 sub-agent가 명시됨: clarify Web Researcher, plan Prior Art, retro Learning Resources, retro Expert alpha/beta, review Expert alpha/beta. S14 web-research-replay.md에서 Expert sub-agent가 deming.org 접근에 실패한 것이 직접적 트리거였지만, Learning Resources나 Prior Art도 동일한 실패 가능성을 내포하고 있었다. |
| **Goals** | (1) 모든 web research sub-agent의 일관된 동작 보장, (2) "이 sub-agent는 JS 사이트에 접근할까?"라는 예측 불가능한 판단 회피, (3) 변경의 원자성(atomic change) — 부분 업데이트는 "어떤 sub-agent가 새 프로토콜이고 어떤 것이 구 프로토콜인지" 추적해야 하는 인지 부하를 만든다. |
| **Options** | **A.** 전체 업데이트 (7/7 sub-agent) — 일관성 최대화, 불필요한 변경 포함 가능. **B.** 최소 업데이트 — JS 렌더링이 필요한 sub-agent만 (clarify, plan의 연구용 2개). **C.** 빈도 기반 — web research 빈도가 높은 sub-agent만 우선 업데이트, 나머지는 다음 세션에서. |
| **Basis** | 옵션 A 선택. lessons.md의 핵심 교훈: "retro and review had no protocol reference at all for their web-searching sub-agents." 프로토콜 참조가 아예 없는 sub-agent가 있다는 것은 이미 일관성이 깨진 상태였다. 부분 업데이트는 이 불일치를 고착시킨다. 또한 프로토콜 참조 추가는 저비용 변경(한 줄의 참조 문 추가)이므로 "불필요한 변경"의 비용이 극히 낮다. |
| **Situation Assessment** | 정확했다. sub-agent가 JS-rendered 사이트에 접근할지 여부는 런타임에서만 결정된다 — 사용자가 어떤 전문가를 지정하느냐, 해당 전문가의 공식 사이트가 JS 기반인지에 따라 달라진다. S14의 Deming 사례가 정확히 이 패턴: "전문가 신원 확인" 용도인데 deming.org가 JS-rendered여서 실패했다. 빈도가 낮다고 무시할 수 없는 이유. |
| **Experience** | 경험이 적은 엔지니어라면 "지금 깨진 것만 고치자"(최소 범위)를 선택했을 가능성이 높다. 경험이 많은 엔지니어는 "같은 범주의 모든 컴포넌트를 동시에 업데이트"하는 습관이 있다 — 이는 "shotgun surgery"의 반대인 "shotgun fix"로, 알려진 문제 패턴이 존재하는 모든 위치를 한 번에 수정하는 전략이다. |
| **Aiding** | grep 기반의 "프로토콜 참조 여부 감사(audit)" 스크립트가 있었다면 범위 결정이 더 체계적이었을 것이다. 예: `grep -L "Web Research Protocol" plugins/cwf/skills/*/SKILL.md`로 참조가 없는 스킬을 자동 탐지. S15에서는 8개 파일을 수동으로 읽어서 확인했다. |

**핵심 교훈**: 프로토콜 참조를 추가하는 변경은 저비용이므로, "이 컴포넌트에
필요한가?"를 판단하는 비용보다 "모든 해당 컴포넌트에 일괄 적용"하는 비용이
더 낮다. 특히 런타임 동작이 비결정적(사용자 입력에 의존)인 시스템에서는
"이 경로가 실행될까?"를 정적으로 예측할 수 없으므로, 방어적 일관성이 합리적이다.

---

## CDM 3: setup/SKILL.md 리버트 대응 — 병렬 작업 충돌 처리

setup/SKILL.md에 agent-browser 감지 로직을 추가했으나, 다른 에이전트/린터가
병렬로 해당 파일을 수정하여 S15의 변경이 리버트된 상황. 이에 대해
재편집(re-edit)이나 충돌 해결(conflict resolution) 대신, setup 변경을 커밋에서
제외하고 나머지 4개 스킬 변경만 커밋한 결정.

| Probe | Analysis |
|-------|----------|
| **Cues** | setup/SKILL.md 편집 후 커밋 시점에서 해당 파일이 이미 다른 내용으로 변경되어 있었다. 세션 요약: "setup/SKILL.md edit was reverted by another agent/linter working in parallel — excluded from commit." 병렬 작업 환경에서의 파일 충돌이 핵심 단서. |
| **Goals** | (1) S15 세션의 핵심 성과물(4개 스킬의 프로토콜 참조 업데이트)을 보존, (2) 충돌하는 파일로 인한 커밋 실패 방지, (3) setup 감지 로직의 최종 반영 보장. 목표 (1)과 (2)는 즉시 충족 가능하고, (3)은 지연 가능하다. |
| **Options** | **A.** 재편집(re-edit) — setup/SKILL.md를 다시 읽고, 병렬 변경을 통합한 뒤 agent-browser 감지를 추가. 정확하지만 시간 소모 + 2차 충돌 위험. **B.** 커밋에서 제외 — 4개 스킬 변경만 커밋하고 setup은 다음 세션에서 처리. 핵심 성과물 보존, setup은 지연. **C.** 블로킹 — 충돌이 해결될 때까지 전체 커밋을 보류. 가장 안전하지만 세션 성과물 전체가 위험에 처함. |
| **Basis** | 옵션 B 선택의 근거: (1) cwf-state.yaml에 이미 `agent_browser: available`이 S14에서 등록되어 있다 — setup의 감지 로직은 "보고서 표시" 기능이지 "기능 활성화"가 아니다. 따라서 누락의 실질적 영향이 낮다. (2) 4개 스킬의 프로토콜 참조는 S15의 핵심 가치이고, 이것이 병렬 충돌과 무관하게 안전하다. (3) 병렬 에이전트의 변경 내용을 파악하지 않고 재편집하면 다른 의도를 덮어쓸 수 있다. |
| **Time Pressure** | 세션 후반부에서 발생한 문제. 이미 regression 테스트(3/3 BDD)를 통과한 상태에서, 충돌 해결에 추가 시간을 투자하면 retro 단계가 압축된다. "핵심 커밋을 먼저 확보"하는 판단에 시간 압박이 영향을 미쳤다. |
| **Situation Assessment** | 대체로 정확했지만 한 가지 미묘한 점이 있다. setup의 agent-browser 감지는 새 환경에 CWF를 설치할 때 cwf:setup 실행 시 agent-browser 존재 여부를 보고하는 기능이다. cwf-state.yaml에 이미 `available`로 기록되어 있으므로 기존 환경에서는 영향이 없지만, 새 환경에서 cwf:setup을 실행하면 agent-browser가 감지 리스트에서 누락된다. 이 edge case는 "다음 세션"까지 열린 상태로 남는다. |
| **Hypothesis** | 옵션 A(재편집)를 선택했다면: 충돌이 단순한 경우(린터의 포맷 변경 등) 5분 내에 해결 가능했을 것이다. 하지만 병렬 에이전트가 구조적 변경을 했다면 합병(merge) 자체가 복잡해져서 오히려 regression을 유발할 수 있다. 불확실성이 높은 상황에서 "확실한 부분만 먼저 확보"는 합리적 전략이다. |

**핵심 교훈**: 병렬 작업 환경에서 파일 충돌이 발생하면, 충돌 파일의
기능적 중요도를 평가하라. 충돌 파일이 "보고 기능"(nice-to-have)이고 핵심
변경이 안전하다면, 핵심만 먼저 커밋하고 충돌 파일은 다음 원자적 단위에서
처리하는 것이 리스크를 최소화한다. "완벽한 커밋" 대신 "안전한 커밋"을
우선하라.

---

## 세션 전체 종합

### 낭비(Waste) 분석

S15는 비교적 효율적인 세션이었다. 8개 파일을 읽고 5개 파일을 편집한
뒤 regression 테스트까지 완료. 명확한 plan과 S14의 사전 작업이 효율성에
기여했다.

| 구간 | 소요 | 낭비 유형 | 원인 |
|------|------|----------|------|
| setup/SKILL.md 편집 + 리버트 대응 (CDM 3) | ~2턴 | 재작업 | 병렬 에이전트/린터와의 동기화 부재 |
| 8개 파일 수동 감사 (CDM 2) | ~3턴 | 수동 작업 | 프로토콜 참조 감사 스크립트 부재 |

**총 낭비**: ~5턴. 그러나 파일 감사는 "드리프트 발견"이라는 실질적
가치를 생산했으므로 순수 낭비는 setup 리버트의 ~2턴 정도.

### 재사용 가능한 휴리스틱 요약

| # | 휴리스틱 | 적용 조건 |
|---|---------|----------|
| H1 | 프로토콜 드리프트를 발견하면 인라인 규칙을 수리하지 말고 참조로 교체하라 | 같은 규칙이 3곳 이상에 복제된 경우 |
| H2 | 저비용 프로토콜 참조는 "필요한 곳만"이 아닌 "해당 범주 전체"에 적용하라 | 런타임 동작이 비결정적(사용자 입력 의존)인 시스템 |
| H3 | 병렬 충돌 시 기능적 중요도로 우선순위를 매기고, 핵심만 먼저 커밋하라 | 병렬 에이전트 환경에서 파일 충돌 발생 시 |

### 전문가 렌즈(Expert Lens)

- **Parnas (Information Hiding)**: CDM 1에서 인라인 규칙을 참조로 교체한
  것은 Parnas의 정보 은닉 원칙의 적용이다. Web Research Protocol의 상세
  구현(tier 구성, 임계값, fallback 로직)은 agent-patterns.md 뒤에 은닉되고,
  각 SKILL.md는 "Web Research Protocol을 따르라"는 인터페이스만 노출한다.
  프로토콜 변경 시 변경 전파 지점이 1곳으로 제한된다.

- **Deming (Common Cause Variation)**: CDM 2에서 "7개 sub-agent 전체
  업데이트"는 Deming의 공통 원인 변동(common cause variation) 대응
  전략과 일치한다. retro/review의 Expert sub-agent에서 아직 JS-rendered
  사이트 실패가 발생하지 않은 것은 "아직 발현되지 않은 공통 원인"이다.
  개별 실패를 기다렸다가 수정하는 것은 특수 원인(special cause) 대응이며,
  시스템 전체의 공통 원인을 제거하지 못한다. 일괄 적용이 공통 원인
  제거에 해당한다.

- **Cook (Latent Failures)**: CDM 3에서 setup/SKILL.md의 agent-browser 감지
  누락은 Cook의 잠재적 실패(latent failure) 개념에 해당한다. 현재
  환경에서는 cwf-state.yaml에 이미 기록되어 있어 실패가 표면화되지
  않지만, 새 환경에서 cwf:setup 실행 시 비로소 드러난다. S15는 이
  잠재적 실패를 인식하면서도 의도적으로 수용했다 — 핵심 커밋의 안전성을
  잠재적 실패의 조기 해결보다 우선시한 것이다. Cook의 프레임워크에서
  보면, 이는 합리적 판단이지만 반드시 후속 세션에서 해결해야 하는
  "열린 잠재적 실패"로 추적되어야 한다.

<!-- AGENT_COMPLETE -->
