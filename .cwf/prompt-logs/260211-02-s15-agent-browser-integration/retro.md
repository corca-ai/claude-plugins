# Retro: Agent-Browser Integration (S15)

> Session date: 2026-02-11
> Mode: deep

## 1. Context Worth Remembering

- agent-browser v0.9.2 (`/usr/local/bin/agent-browser`) — Vercel의 headless
  Chromium CLI. JS 렌더링, SPA, 리다이렉트 체인 처리 가능.
- WebFetch는 JS 사이트에서 부분 콘텐츠가 아닌 **완전히 빈 페이지** 반환
  (minified JS/CSS 번들만). deming.org에서 검증됨.
- Web Research Protocol SSOT: `plugins/cwf/references/agent-patterns.md` 159행+
  (2-tier: WebFetch 먼저 → agent-browser 폴백)
- deming.org = JS 렌더링 검증의 canonical test case
- Master plan S0-S14 로드맵 완료. marketplace-v3 → main 머지만 남음.
- 병렬 에이전트 작업 시 파일 수준 조율 메커니즘이 없음 — setup/SKILL.md
  충돌 경험.

## 2. Collaboration Preferences

- 유저가 `next-session.md`로 명확한 핸드오프 문서 제공 → 에이전트 자율 실행
  가능. 세션 초기 확인 단계(8 파일 읽기) 후 바로 실행에 돌입.
- 병렬 에이전트 작업 중임을 선제적으로 고지 ("다른 에이전트 작업 중이니
  적절히 해주시고요") — 에이전트가 파일 충돌 시 대응 전략을 수립할 수 있게 함.
- sudo 필요 시 호출해달라는 제약을 사전 공유 — 설치 작업에 대한 불필요한
  시도를 방지.
- retro 호출이 간결 ("retro 합시다") — CWF 스킬 사용에 익숙하며 불필요한
  부연 불필요.

### Suggested Agent-Guide Updates

없음. 현재 AGENTS.md의 Collaboration Style 섹션이 이 패턴을 이미 반영.

## 3. Waste Reduction

### setup/SKILL.md 편집 후 리버트 (~2턴 낭비)

setup/SKILL.md에 agent-browser 감지 로직을 추가하는 2회 Edit 수행 후, 다른
에이전트/린터에 의해 되돌려짐. 커밋에서 제외하여 핵심 변경은 보존했으나
편집 자체는 순수 낭비.

**5 Whys**:
1. Why 편집이 리버트? → 다른 에이전트가 같은 파일을 동시 수정
2. Why 동시 수정 발생? → 파일 수준 조율 메커니즘 부재
3. Why 조율 메커니즘이 없는가? → CWF의 병렬 에이전트 패턴이 "독립 파일"
   가정에 기반 — 파일 겹침 시나리오를 설계하지 않음
4. Why 설계하지 않았는가? → 지금까지 병렬 에이전트가 주로 리뷰(읽기 전용)
   용도였고, 쓰기 병렬은 드문 케이스였음
5. 근본 원인: **구조적 제약** — 병렬 쓰기 에이전트 간 파일 접근 제어
   프로토콜이 agent-patterns.md에 없음

**분류**: 구조적 제약 (process gap)
**권장**: agent-patterns.md에 병렬 에이전트 파일 소유권 프로토콜 추가 고려.
단, 현재 발생 빈도가 낮으므로 즉시 구현보다는 기록으로 남겨두는 것이 적절.

### 8개 파일 수동 감사 (~3턴)

4개 스킬의 sub-agent 프롬프트에서 Web Research Protocol 참조 여부를 수동으로
확인. 실질적 가치(드리프트 발견)를 생산했으므로 순수 낭비는 아니지만,
`grep -L "Web Research Protocol" plugins/cwf/skills/*/SKILL.md` 같은 자동
탐지가 가능했다면 더 효율적이었을 것.

**분류**: 도구 부재 (one-off — 빈도가 낮으므로 스크립트화 불필요)

## 4. Critical Decision Analysis (CDM)

### CDM 1: 인라인 규칙 교체 vs 프로토콜 참조 — SSOT 통합 전략

clarify와 plan의 sub-agent 프롬프트에 이미 인라인으로 작성된 web research
규칙을 발견했을 때, 인라인 규칙을 업데이트할 것인지 삭제하고
agent-patterns.md 참조로 대체할 것인지의 선택.

| Probe | Analysis |
|-------|----------|
| **Cues** | clarify/plan SKILL.md에서 WebFetch-only 인라인 규칙 발견. S14에서 agent-patterns.md가 two-tier로 업데이트되었음에도 인라인 규칙은 여전히 WebFetch 단독 사용을 지시 — 이미 드리프트 발생 |
| **Goals** | (1) 모든 sub-agent가 agent-browser 폴백 사용 가능, (2) 향후 프로토콜 업데이트 시 변경 지점 1곳으로 제한, (3) 기존 동작 regression 없음 |
| **Options** | A. 인라인 규칙을 agent-browser 포함하도록 업데이트 — 자체 완결적이지만 드리프트 재발. B. 인라인 삭제 → shared protocol 참조 — SSOT 강제. C. 하이브리드 — 요약만 인라인, 상세는 참조 |
| **Basis** | B 선택. 드리프트가 이미 발생한 증거가 있었으므로 인라인 방식의 실패 모드가 실시간으로 확인됨. skill-conventions.md의 References 패턴과 일관성 유지 |
| **Hypothesis** | A(인라인 업데이트) 선택 시: S15에서는 작동하지만 다음 프로토콜 업데이트 때 7곳 동시 업데이트 필요, 누락 시 비일관적 동작 재발 |

**핵심 교훈**: 프로토콜 드리프트를 발견하면 인라인 규칙을 수리하지 말고
참조로 교체하라. 드리프트 발생 자체가 "인라인 방식은 유지보수 불가능"이라는
경험적 증거이다.

### CDM 2: 전체 범위 업데이트 vs 최소 범위 업데이트 — 방어적 일관성

7개 web-researching sub-agent 전체를 업데이트할 것인지, 실패한 2개만 수정할
것인지의 범위 결정.

| Probe | Analysis |
|-------|----------|
| **Cues** | retro/review의 Expert sub-agent는 "전문가 신원 확인"용이라 JS-rendered 사이트 접근 빈도 낮음. 그러나 S14의 Deming 사례에서 정확히 이 패턴으로 실패 |
| **Goals** | (1) 일관된 동작 보장, (2) "이 sub-agent는 JS 사이트 접근할까?" 예측 회피, (3) 부분 업데이트의 인지 부하 방지 |
| **Options** | A. 전체 업데이트 7/7. B. 실패한 2개만. C. 빈도 기반 우선순위 |
| **Basis** | A 선택. 프로토콜 참조 추가는 저비용(한 줄). sub-agent 런타임 동작은 비결정적(사용자 입력 의존). 부분 업데이트는 불일치를 고착 |
| **Situation Assessment** | 정확. sub-agent가 JS 사이트에 접근할지는 전문가 선택과 해당 사이트 기술 스택에 의존 — 정적 예측 불가 |

**핵심 교훈**: 저비용 프로토콜 참조는 "필요한 곳만"이 아닌 "해당 범주
전체"에 적용하라. 비결정적 시스템에서 정적 예측은 불가능하다.

### CDM 3: setup/SKILL.md 리버트 대응 — 병렬 충돌 처리

| Probe | Analysis |
|-------|----------|
| **Cues** | setup/SKILL.md 편집 후 다른 에이전트에 의해 리버트됨 |
| **Goals** | (1) 핵심 성과물 4개 스킬 변경 보존, (2) 충돌 파일로 인한 커밋 실패 방지 |
| **Options** | A. 재편집 — 병렬 변경 통합 후 agent-browser 감지 추가. B. 커밋에서 제외 — 핵심만 커밋, setup은 다음 세션. C. 전체 커밋 보류 |
| **Basis** | B 선택. cwf-state.yaml에 이미 `agent_browser: available`이 S14에서 등록됨. setup 감지는 "보고 기능"이지 "기능 활성화"가 아님. 기능적 영향 낮음 |
| **Time Pressure** | regression 테스트 통과 후 retro 단계로 넘어가야 하는 시점. 충돌 해결에 추가 투자 시 retro 압축 |

**핵심 교훈**: 병렬 충돌 시 기능적 중요도로 우선순위를 매기고, "안전한
커밋"을 "완벽한 커밋"보다 우선하라.

## 5. Expert Lens

### Expert alpha: Martin Fowler

**Framework**: 리팩터링 패턴, 지식 중복 제거(Rule of Three), 공유 추상화,
진화적 설계
**Source**: *Refactoring: Improving the Design of Existing Code* 2nd ed. (2018);
"Is Design Dead?" (martinfowler.com); "BeckDesignRules" (martinfowler.com/bliki)
**Why this applies**: S15의 핵심 결정은 인라인 규칙을 공유 프로토콜 참조로
교체하는 것 — 정확히 중복 제거와 공유 추상화 추출이라는 리팩터링 영역.

CDM 1의 인라인 규칙 교체는 **Duplicated Code** 코드 스멜에 대한 **Extract
Function**의 구조적 확장이다. 7개 sub-agent가 각자 웹 리서치 규칙을 인라인으로
보유 → 전형적 중복. *Refactoring* 2판에서 중복 코드는 가장 먼저 다루는 코드
스멜이며, 드리프트가 이미 관찰 가능한 증거로 존재했으므로 공유 추상화 추출은
단순한 개선이 아닌 필수적 리팩터링이었다.

CDM 2의 7개 전체 업데이트는 Rule of Three의 **역방향 적용** — 이미 추상화가
존재하는 상태에서 적용 범위 결정. 저빈도 에이전트를 미루는 것은 **Shotgun
Surgery** 스멜을 방치하는 것. 변경 비용이 낮을 때 전체 카테고리 일괄 적용이
진화적 설계 원칙에 부합.

CDM 3의 "안전한 커밋 우선"은 "Is Design Dead?"의 변경 비용 곡선 평탄화 원칙
적용. 작고 되돌리기 쉬운 커밋이 완벽한 커밋보다 낫다.

**Recommendations**:
1. 파일 소유권 프로토콜을 agent-patterns.md에 추가 — 병렬 에이전트 Shotgun
   Surgery 방지
2. 인라인 규칙이 남아있는 다른 영역을 `grep`으로 체계적 탐지 → 공유 참조
   전환

### Expert beta: Nancy Leveson

**Framework**: STAMP/STPA — 사고를 구성요소 고장이 아닌 부적절한
제어(inadequate control)로 모델링, 시스템 전체의 제어 구조 분석
**Source**: *Engineering a Safer World: Systems Thinking Applied to Safety*
(MIT Press, 2011)
**Why this applies**: 병렬 에이전트 파일 충돌과 인라인 규칙 drift는 전형적인
제어 구조 부재 문제.

**병렬 에이전트 충돌 = 제어 구조 결함**: setup/SKILL.md 되돌림을 STAMP으로
분석하면, 이것은 우연한 충돌이 아닌 시스템 제어 구조의 결함이다. 에이전트 간
파일 수준 조율을 위한 제어 동작(control action)이 정의되지 않음 —
"UCA(Unsafe Control Action): 필요한 제어 동작이 제공되지 않음" 유형에 해당.
"안전한 커밋"은 합리적 완화 조치이지만 근본 원인인 제어 구조는 수정되지 않음.

**인라인 규칙 drift = 피드백 루프 단절**: 인라인 규칙은 본질적으로 개방
루프(open-loop) 제어 — 작성 후 환경 변화를 감지/반영하는 메커니즘 부재.
공유 프로토콜 참조는 폐쇄 루프(closed-loop)로의 전환. CDM 2의 7개 전체
업데이트는 "아직 발생하지 않은 위험한 상태까지 식별해야 한다"는 STPA
원칙의 실천.

**Recommendations**:
1. 병렬 에이전트 제어 구조 설계 — 파일 범위 사전 선언, 충돌 감지 시 피드백
   채널, 안전 제약 정의
2. drift 감지를 위한 폐쇄 루프 구축 — cwf:review 또는 cwf:retro에서 공유
   프로토콜 참조 자동 검증 체크 추가

## 6. Learning Resources

### 1. AI Agent Orchestration Patterns — Azure Architecture Center

**URL**: https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns

Microsoft의 멀티 에이전트 오케스트레이션 패턴 레퍼런스. Sequential,
Concurrent, Group Chat, Handoff, Magentic의 5가지 패턴을 적용 조건/회피
조건/예시와 함께 체계적 정리. CWF의 파이프라인(Sequential)과 4 parallel
reviewers(Concurrent), producer-reviewer 루프(Maker-Checker)에 직접 대응.
checkpoint/retry 메커니즘에 대한 힌트 제공.

### 2. AgentSpawn: Adaptive Multi-Agent Collaboration Through Dynamic Spawning

**URL**: https://arxiv.org/html/2602.07072v1

멀티 에이전트 동시 파일 편집 충돌을 3-tier로 해결하는 연구 논문. 자동 머지
15%, 시맨틱 머지 73%, 에스컬레이션 12%. S15에서 경험한 setup/SKILL.md 충돌
문제에 대한 체계적 해법. Lock-free optimistic concurrency 접근이 CWF 병렬
에이전트 구조와 적합.

### 3. The Prompt Engine MCP Server: DRY Principle for AI Prompts

**URL**: https://skywork.ai/skypage/en/prompt-engine-mcp-server-ai-engineers/1980837856862343168

프롬프트에 DRY 원칙을 적용하는 "Partials" 템플릿 메커니즘. S15의 핵심
작업(인라인 web research 규칙을 agent-patterns.md 참조로 통합)과 동일한
문제를 MCP 서버 기반 template include로 formalize. CWF의 현재 "참조 경로
포함" 방식은 사실상 수동 partial과 동일한 패턴.

## 7. Relevant Skills

### Installed Skills

| Skill | 이 세션과의 관련성 |
|-------|-------------------|
| `cwf:setup` | 직접 수정 대상. agent-browser 감지 로직 추가 (병렬 충돌로 리버트됨) |
| `cwf:retro` | 현재 실행 중 |
| `cwf:refactor --holistic` | 향후 인라인 규칙 잔존 여부를 cross-skill 감사할 때 활용 가능 |
| `plugin-deploy` | 머지 후 marketplace 배포 시 사용 |

### Skill Gaps

추가 스킬 갭 식별 없음. 이 세션은 수동 편집 + 검증이 핵심이었고, 기존 CWF
스킬 세트로 충분히 커버됨.
