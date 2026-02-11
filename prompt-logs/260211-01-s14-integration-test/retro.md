# Retro: S14 Integration Test + Agent-Browser Plan

> Session date: 2026-02-11
> Mode: deep

## 1. Context Worth Remembering

- **WebFetch 도구 한계**: WebFetch는 HTTP GET + HTML-to-markdown 도구로, 모던 JS 렌더링 사이트에서 9% 성공률을 기록했다. S33의 Web Research Protocol은 404 문제를 해결했지만 (0건), JS 렌더링, 403 차단, 리다이렉트 체인은 도구 자체의 한계다.
- **agent-browser 설치 완료**: Vercel의 headless Chromium CLI (v0.9.2)가 설치되었고, deming.org 렌더링 성공을 확인했다. 2-tier fetch 프로토콜: WebFetch (빠름) → agent-browser (JS 폴백).
- **compact-context.sh = 수동 YAML 파서**: yq 의존성 없이 bash로 작성된 파서. cwf-state.yaml에 새 list 필드 추가 시 파서도 반드시 병렬 업데이트 필요 — 자동 필드 탐색 없음.
- **정적 검증 = 통합 테스트**: LLM 스킬 시스템에서 SKILL.md는 사양이자 구현이다. Explore 에이전트 4개 병렬 투입으로 46/46 체크 통과 + compact-context.sh 버그 2개 발견.
- **v3-migration-decisions.md**: 24개 세션(S0-S33)의 20개 아키텍처 결정을 하나의 독립 참조 문서로 종합 완료.

## 2. Collaboration Preferences

- **경험적 검증 > 이론적 논증**: 에이전트가 이론적으로 "프로토콜이 유효하다"고 주장했을 때, 사용자는 실제 S33 실패 시나리오 리플레이를 강제했다. 결과적으로 이론으로는 보이지 않던 WebFetch JS 렌더링 한계가 발견되었다.
- **구체적 대안으로 빠른 방향 전환**: "실제로 지난 세션 참고해서 404 발생했던 사례들에 대해 다시 시켜보면 되지 않을까요?" — 추상적 논쟁을 구체적 행동으로 전환.
- **Research → Design 원칙 준수**: agent-browser를 제안하면서 먼저 GitHub 레포를 읽도록 요청. 기존 CLAUDE.md 규칙과 일치.
- **최소 의존성 선호**: MCP 서버 대신 agent-browser CLI 선택. Unix 철학: 작은 도구를 파이프로 연결.

### Suggested CLAUDE.md Updates

없음 — 기존 규칙이 관찰된 패턴을 충분히 커버한다.

## 3. Waste Reduction

### 3.1 아키텍처 논쟁 before 진단 (~4턴)

에이전트가 WebFetch 실패의 실제 데이터 패턴(JS 5건, 403 2건, redirect 3건)을 분류하기 전에 "sub-agent vs agent team" 아키텍처를 ~4턴 논쟁했다. 분류를 먼저 했다면 1턴 만에 "도구 한계 → 도구 교체"로 수렴 가능했다.

**5 Whys**:
1. 왜 아키텍처를 먼저 논쟁했나? → 에이전트가 이론적 추론(sub-agent는 스킬 접근 불가 → agent team은 cwf:gather 사용 가능)에서 출발
2. 왜 이론에서 출발했나? → 실패 데이터의 패턴 분류를 선행하지 않음
3. 왜 패턴 분류를 안 했나? → web research 실패에 대한 회귀 테스트 프로토콜 부재
4. 왜 프로토콜이 없었나? → S33에서 프로토콜을 만들었지만 검증 단계를 생략
5. **근본 원인**: 프로세스 갭 — 프로토콜/프로세스 변경 시 과거 실패 시나리오 리플레이가 필수 단계로 지정되어 있지 않음

**권장**: Tier 3 — project-context.md에 추가: "실패 데이터 패턴 분류가 솔루션 논쟁보다 먼저다: 알려진 문제에 대한 솔루션을 논의할 때, 실패 데이터를 유형별로 분류(bottom-up)한 후에 아키텍처를 논의하라. 실패의 다수가 같은 도구 한계에서 비롯되면, 아키텍처가 아니라 도구를 교체해야 한다."

### 3.2 npm install 권한 에러 (~1턴)

`sudo npm install -g agent-browser`가 도구 권한에 의해 차단됨. 사용자가 수동 설치.

- 일회성 제약 — 프로세스 변경 불필요.

### 3.3 비계획 작업으로 인한 컨텍스트 소비 (~60%)

Web research 검증 + agent-browser 통합 계획이 세션 컨텍스트의 ~60%를 소비, retro가 continuation 세션으로 밀림.

- 통합 테스트 세션은 본질적으로 발견 지향적이므로 예측 불가. 일회성.

## 4. Critical Decision Analysis (CDM)

### CDM 1: 정적 검증(Static Verification) vs E2E 테스트

| Probe | Analysis |
|-------|----------|
| **Cues** | cwf:run은 gather→retro 전체 파이프라인 실행. 세션 안에서 cwf:run을 돌리면 "세션 안의 세션"으로 컨텍스트 폭발. |
| **Goals** | (1) 24세션 누적 정합성 확인, (2) main 머지 전 신뢰 확보, (3) 컨텍스트 예산 내 완료. (3)이 E2E를 불가능하게 하는 제약. |
| **Options** | A. E2E cwf:run 실행 (재귀적 폭발). B. SKILL.md 정적 검증 (Explore 에이전트 4개 병렬). C. 개별 스킬 단위 테스트 (cross-cutting 불가). |
| **Basis** | "SKILL.md가 곧 구현체" — LLM 스킬에서 사양→코드→실행 변환 체인이 없으므로, SKILL.md 정적 검증 = 구현 검증. |
| **Situation Assessment** | 정확. 46/46 체크 통과 + compact-context.sh 버그 2개 발견으로 전략 유효성 입증. |
| **Hypothesis** | E2E 시도 시: 컨텍스트 50% 이상 소비, 나머지 항목 수행 불가. |

**Key lesson**: LLM 스킬 시스템에서 SKILL.md는 사양이자 구현. 정적 검증으로 cross-cutting 정합성을 확인하고, 실행 테스트는 결정론적 컴포넌트(파서, 스크립트)에 집중하라.

### CDM 2: 사용자의 경험적 리플레이 vs 에이전트의 이론적 반박

| Probe | Analysis |
|-------|----------|
| **Cues** | 사용자: "S33 Deming 시나리오를 실제로 다시 돌려보자." 에이전트: "에이전트 팀까지 동원하는 건 과도하다." |
| **Goals** | 사용자: 경험적 증거 확보. 에이전트: 컨텍스트 예산 절약. 사용자 목표가 우선. |
| **Analogues** | Deming PDCA: Plan(S33 프로토콜) → Do(S14 리플레이) → Check(9% 확인) → Act(agent-browser). 에이전트는 P→A로 뛰어넘으려 했고 사용자가 D→C를 강제. |
| **Situation Assessment** | 에이전트 부정확. "404가 핵심이고 프로토콜이 해결했다"고 판단했지만, 핵심 실패 모드는 JS 렌더링 불가(WebFetch 도구 한계). 리플레이 없이는 발견 불가. |
| **Time Pressure** | 컨텍스트 예산 압박이 "빨리 결론 내리기" 편향 유발. |

**Key lesson**: 프로토콜 변경의 효과를 이론으로만 판단하지 마라. 과거 실패 시나리오를 경험적으로 리플레이하면 이론으로는 보이지 않는 실패 모드가 드러난다.

### CDM 3: 에이전트 아키텍처 논쟁 vs 도구 한계 조사

| Probe | Analysis |
|-------|----------|
| **Cues** | 11개 URL 중 1개만 성공(9%). 실패 유형: JS-rendered empty (5건), 403 (2건), redirect chain (3건). 데이터가 이미 도구 한계를 가리키고 있었으나 에이전트는 분류 전 아키텍처 논의 시작. |
| **Goals** | 사용자: 근본 원인 파악(진단). 에이전트: 솔루션 제시(처방). 진단이 처방보다 먼저여야 한다. |
| **Aiding** | 5 Whys 적용 시 2번째 Why("왜 빈 페이지? → JS 미실행")에서 올바른 방향 도출. 아키텍처 논쟁 불필요. |
| **Knowledge** | "cwf:gather도 WebFetch를 사용한다" — 이 사실을 조기 인식했다면 1턴에서 종결 가능. |

**Key lesson**: 실패 데이터의 패턴을 먼저 분류하라(bottom-up). 다수가 같은 도구 한계에서 비롯되면 아키텍처가 아니라 도구를 교체해야 한다. 진단이 처방보다 먼저다.

### CDM 4: agent-browser CLI vs MCP 서버

| Probe | Analysis |
|-------|----------|
| **Cues** | 사용자가 agent-browser를 직접 제안. MCP는 이전 세션에서 설정 복잡도가 높았던 경험. |
| **Goals** | JS 렌더링 확보, sub-agent 사용 가능, 설치/유지보수 단순성, Bash 도구 통합. |
| **Basis** | CLI = sub-agent가 Bash 도구로 즉시 사용 가능. MCP = 클라이언트 설정 필요 + sub-agent MCP 접근 불확실. "가장 단순한 통합 경로." |
| **Analogues** | Unix 철학: "한 가지 일을 잘 하는 작은 도구를 파이프로 연결." YAGNI 원칙 적용. |

**Key lesson**: 도구 통합 시 sub-agent의 최소 설정 경로를 우선하라. CLI는 Bash 도구만 있으면 즉시 사용 가능.

## 5. Expert Lens

### Expert alpha: Gojko Adzic

**Framework**: Specification by Example — 구체적 예제를 통한 협업적 사양 정의, 살아 있는 문서(living documentation)이자 실행 가능한 테스트로 유지하는 방법론.
**Source**: *Specification by Example* (Manning, 2011, Jolt Award 2012), *Bridging the Communication Gap* (Neuri, 2009), 2020년 "SBE 10 Years" 회고 (gojko.net).
**Why this applies**: "SKILL.md가 곧 사양이자 구현이다"는 Specification by Example의 중심 개념인 "실행 가능한 사양"의 LLM 시대 버전이다. 사용자가 강제한 경험적 리플레이는 Adzic이 말하는 "핵심 예제(key examples)를 통한 검증"과 정확히 일치한다.

#### 1. SKILL.md = Executable Specification

Adzic가 2011년부터 추구한 "사양이 곧 실행 가능한 테스트"라는 이상이, LLM 스킬 시스템에서는 구조적으로 보장된다. 전통적 소프트웨어에서 사양서와 코드는 항상 동기화 문제를 겪지만, SKILL.md는 런타임 행동을 직접 결정하므로 "동기화가 깨질 수 없는 사양"이다. Adzic가 꿈꿨던 것이 별도의 자동화 프레임워크(FitNesse, Cucumber) 없이 자연적으로 달성되었다.

단, Adzic의 경고를 적용하면: "예제가 없는 사양은 검증 불가능하다." S14의 정적 검증은 구조적 정합성을 확인했지만, SKILL.md의 LLM 해석 결과가 올바른지는 예제 기반 실행 테스트가 여전히 필요하다.

#### 2. 경험적 리플레이 = Key Examples

에이전트의 이론적 접근은 Adzic의 언어로 "규칙만 있고 예제가 없는 사양." 사용자가 강제한 11개 URL 리플레이가 key examples 역할을 했다. 2020년 회고의 핵심 문구: "conversations are more important than capturing conversations is more important than automating conversations." 에이전트는 "자동화된 추론"으로 뛰어넘으려 했고 사용자는 "대화"(예제를 통한 공동 검증)를 요구했다.

#### 3. Bottom-up 실패 분류 = 예제 분류

Specification workshop의 핵심 단계인 "예제 분류"가 S14에서 재현되었다. 11개 URL 실패를 유형별로 분류하면 사양의 구조(JS-rendered가 5/11로 최대 그룹)가 드러나고 해결 방향이 즉시 수렴한다. 에이전트가 분류 전에 아키텍처를 논쟁한 것은 "예제 없이 규칙을 논쟁한 것."

**Recommendations**:
1. SKILL.md에 Key Examples 섹션(구체적 입출력 예제 2-3개)을 추가하여 정적 검증의 행동적 차원을 보완하라.
2. 프로토콜 변경 후 "Replay Examples" 체크리스트를 의무화하라 — 기존 실패 시나리오 N개 리플레이 → 성공률 기록.

### Expert beta: Richard Cook

**Framework**: 복잡 시스템 실패의 본질 — 실패는 단일 원인이 아니라 다중 잠재 결함의 상호작용이며, 운영자가 표상의 선(line of representation) 위에서 안전을 능동적으로 생산한다는 관점.
**Source**: *How Complex Systems Fail* (1998/2000, 18 principles), "Above the Line, Below the Line" (ACM Queue, 2020), Cook & Rasmussen "Going Solid" (BMJ Quality & Safety, 2005).
**Why this applies**: S33 프로토콜이 가시적 실패(404)를 수정했지만 비가시적 실패(JS 렌더링)를 은폐했고, 자동화(에이전트)가 놓친 것을 운영자(사용자)가 발견했다.

#### 1. 단일 근본 원인 귀속의 오류

Cook의 원칙 #7: "사고의 고립된 '원인'이란 없다." S33에서 404가 가장 가시적인 실패였고 프로토콜로 해결됐지만, 이것은 전체 실패 공간의 한 조각이었다. 리플레이가 드러낸 실상: 404는 0건이지만 성공률은 9%. 실패의 실제 구성은 JS 렌더링 불가(45%), 403(18%), 리다이렉트(27%). 원칙 #14: "새 기술이 익숙한 문제를 제거하면, 전례 없는 새 실패 모드를 도입한다."

#### 2. 표상의 선(Line of Representation)

에이전트는 WebFetch의 반환 결과만 볼 수 있고, 내부 작동(HTTP GET only, no JS)에 대한 표상이 없었다. 잘못된 정신 모델("URL → 콘텐츠") → 잘못된 진단(아키텍처 문제) → 4턴 낭비. 사용자는 경험적 리플레이로 표상을 갱신 — Cook의 원칙 #17 "운영자의 능동적 안전 생산."

#### 3. Going Solid — compact-context.sh의 경고 신호

손으로 작성한 YAML 파서가 필드 증가에 따라 느슨한 결합에서 긴밀한 결합으로 전환되는 초기 징후. `current_list` 상태가 여러 핸들러 간 암묵적 의존성을 생성. "Going solid"의 초기 단계: 한 곳의 변경(새 필드)이 예상치 못한 곳(다른 필드 파싱)에 영향.

**Recommendations**:
1. 도구별 "Known Limitations" 문서 도입 — 에이전트의 정신 모델 정확도 향상.
2. compact-context.sh 파서를 표준 도구(yq)로 교체하거나, 새 필드 추가 시 자동 검증 테스트 도입.

## 6. Learning Resources

### 6.1 Spec-Driven Development: Unpacking one of 2025's New Engineering Practices (ThoughtWorks)

**URL**: https://www.thoughtworks.com/en-us/insights/blog/agile-engineering-practices/spec-driven-development-unpacking-2025-new-engineering-practices

S14의 "명세가 곧 구현" 통찰과 직접 연결. SDD는 "잘 작성된 소프트웨어 명세를 프롬프트로 사용하여 AI 에이전트가 코드를 생성하는 패러다임"으로 정의된다. Waterfall과의 차이는 human-in-the-loop 피드백 루프이며, "spec drift와 hallucination은 본질적으로 피할 수 없으므로 결정론적 CI/CD가 여전히 필수"라는 현실적 조언을 담고 있다. CWF의 SKILL.md 정적 검증이 업계 맥락에서 어디에 위치하는지 파악하는 데 유용하다.

### 6.2 Playwright MCP: A Modern Guide to Test Automation (Testomat.io)

**URL**: https://testomat.io/blog/playwright-mcp-modern-test-automation-from-zero-to-hero/

LLM이 스크린샷 대신 접근성 트리(accessibility tree) 스냅샷으로 웹 페이지와 상호작용하는 패러다임. 스크린샷 vs 접근성 트리 트레이드오프를 명확히 정리. agent-browser 통합의 핵심 참고 아키텍처로, CWF 웹 수집 도구 설계에서 반복적으로 마주칠 의사결정 지점.

### 6.3 Claiming Architecture: ADRs at Change-Time (Entrofi)

**URL**: https://www.entrofi.net/claiming-architectural-reality-part-1-adrs-at-change-time/

Pre-commit hook에 ADR 인식을 통합하여, 아키텍처 결정 기록을 개발 플로우의 능동적 참여자로 전환. v3-migration-decisions.md 종합 작업의 자연스러운 다음 단계로, CWF hook 시스템과의 통합 가능성을 시사한다.

### 보충 자료

| 자료 | URL | 요약 |
|------|-----|------|
| JetBrains: Spec-Driven Approach | https://blog.jetbrains.com/junie/2025/10/how-to-use-a-spec-driven-approach-for-coding-with-ai/ | Requirements.md → Plan.md → Tasks.md 3단계 실전 가이드 |
| Dennis Adolfi: AI-Generated ADRs | https://adolfi.dev/blog/ai-generated-adr/ | Claude Code로 ADR 자동 생성 사례 |
| Zyte: Best Headless Browsers (2026) | https://www.zyte.com/learn/best-headless-browsers-for-web-scraping/ | Playwright vs Puppeteer vs Selenium 비교 |

## 7. Relevant Skills

### Installed Skills

**CWF 스킬 (11개)**: cwf:gather, cwf:clarify, cwf:plan, cwf:review, cwf:impl, cwf:retro, cwf:refactor, cwf:run, cwf:setup, cwf:handoff, cwf:ship

**로컬 스킬 (1개)**: plugin-deploy

**외부 플러그인**: claude-dashboard (update, check-usage, setup)

**S14에서의 스킬 활용 분석**:

- **cwf:setup**: agent-browser 감지 로직 추가가 필요하다. 현재 tools 섹션에 `agent_browser: available`을 수동으로 추가했지만, cwf:setup의 외부 도구 감지(Phase 2)에 `command -v agent-browser` 체크를 추가하면 자동화된다. → agent-browser 통합 세션에서 구현 예정.
- **cwf:gather**: 내부적으로 WebFetch를 사용하므로 같은 JS 렌더링 한계를 공유한다. 2-tier fetch 프로토콜을 cwf:gather에도 적용해야 한다. → agent-browser 통합 세션 범위.
- **cwf:run**: 정적 검증으로 로직 7/7 체크를 통과했으나, 실제 실행 테스트는 별도 세션이 필요하다.

### Skill Gaps

**회귀 테스트 리플레이 스킬**: S14에서 가장 가치 있었던 작업은 S33 실패 시나리오의 수동 리플레이였다. 이를 자동화하는 스킬("과거 실패 시나리오 N개를 리플레이하고 성공률을 보고하는" 스킬)은 현재 존재하지 않는다. 다만, 이것은 범용 회귀 테스트보다 특정 도구(WebFetch/agent-browser) 검증에 가까우므로, 별도 스킬 대신 cwf:gather의 자체 검증 모드로 구현하는 것이 적절하다.

추가 스킬 갭은 현재 식별되지 않음.
