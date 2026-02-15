# CDM Analysis — S14 Integration Test + Agent-Browser Plan

> Gary Klein의 Critical Decision Method(CDM)를 적용한 S14 세션 분석.
> 세션 요약, 아티팩트(plan.md, lessons.md, web-research-replay.md,
> agent-browser-plan.md), cwf-state.yaml 기반.

---

## CDM 1: 정적 검증(Static Verification) vs E2E 테스트 선택

세션 시작 시 "24세션 전체의 통합 테스트를 어떻게 할 것인가"라는
근본적 전략 선택이 있었다. cwf:run을 실제로 실행하면 재귀적 컨텍스트
폭발이 발생하므로, Explore 에이전트 4개를 병렬 투입하여 SKILL.md 사양을
정적 검증하는 방식을 채택했다.

| Probe | Analysis |
|-------|----------|
| **Cues** | cwf:run은 gather→clarify→plan→review→impl→retro 전체 파이프라인을 실행하는 스킬. 세션 안에서 cwf:run을 돌리면 "세션 안의 세션"이 되어 컨텍스트 창이 폭발한다는 구조적 제약이 핵심 단서였다. |
| **Goals** | (1) 24세션 누적 결과물의 정합성 확인, (2) main 머지 전 신뢰 확보, (3) 컨텍스트 예산 내에서 완료. 세 목표 중 (3)이 E2E를 불가능하게 만드는 제약조건이었다. |
| **Options** | **A.** E2E — cwf:run을 실제 실행 (재귀적, 컨텍스트 폭발 위험). **B.** 정적 검증 — SKILL.md를 사양서로 보고 Explore 에이전트가 라인 단위로 검증. **C.** 단위 테스트 — 개별 스킬 호출 (부분적이지만 cross-cutting 검증 불가). |
| **Basis** | LLM 기반 스킬 시스템의 핵심 통찰: "SKILL.md가 곧 구현체이다." 전통적 소프트웨어에서 사양서와 코드가 분리되지만, LLM 스킬에서는 SKILL.md가 런타임 행동을 직접 결정한다. 따라서 SKILL.md 정적 검증 = 구현 검증이 성립한다. |
| **Knowledge** | S13(Holistic Refactor)에서 이미 SKILL.md를 cross-cutting으로 검토한 경험. 해당 세션에서 4개 스킬의 broken reference를 발견한 사실이 "정적 검증이 실제 결함을 잡는다"는 증거로 작용했다. |
| **Situation Assessment** | 정확했다. 결과적으로 46/46 체크 통과 (CDM 5/5, run logic 7/7, fail-fast 6/6, cross-ref 28/28). 정적 검증만으로도 compact-context.sh의 실제 버그 2개를 발견하여 실행 가능성도 입증했다. |
| **Experience** | 경험이 적은 엔지니어라면 "E2E 없으면 불안하다"며 실행 테스트를 시도했을 것이고, 컨텍스트 폭발로 세션을 낭비했을 가능성이 높다. 반대로 경험이 많은 사람이라면 정적 검증에 compact-context.sh 같은 실행 가능한 컴포넌트의 단위 테스트를 함께 배치했을 것이다 — S14에서 실제로 그렇게 했다. |
| **Hypothesis** | E2E를 시도했다면: cwf:run이 gather부터 시작하여 컨텍스트의 50% 이상을 소비, 나머지 검증 항목(v3-migration-decisions.md, web research 등)은 수행 불가능했을 것이다. |

**핵심 교훈**: LLM 스킬 시스템에서 SKILL.md는 사양이자 구현이다. 정적
검증으로 cross-cutting 정합성을 확인하고, 실행 테스트는 파서/스크립트
같은 결정론적 컴포넌트에 집중하라.

---

## CDM 2: 사용자의 경험적 리플레이 요구 vs 에이전트의 이론적 반박

세션 중반, S33에서 만든 Web Research Protocol의 유효성을 검증하는
과정에서 사용자와 에이전트 사이에 접근법 충돌이 발생했다.

| Probe | Analysis |
|-------|----------|
| **Cues** | 사용자가 "S33 Deming 시나리오를 실제로 다시 돌려서 프로토콜이 작동하는지 확인하자"고 제안. 에이전트는 "에이전트 팀까지 동원하는 건 과도하다"며 이론적 논증으로 대응. |
| **Goals** | 사용자 목표: 경험적 증거(empirical evidence) 확보. 에이전트 목표: 컨텍스트 예산 절약 + 빠른 세션 종료. 두 목표가 충돌했고, 사용자의 목표가 우선이었다. |
| **Options** | **A.** 이론적 분석만으로 "프로토콜 유효" 판단 (에이전트 선호). **B.** S33 시나리오 리플레이 (사용자 요구). **C.** 새로운 시나리오로 테스트. |
| **Basis** | 에이전트는 "프로토콜이 URL 구성 규칙을 바꿨으니 404는 당연히 줄어든다"는 연역적 추론에 의존. 사용자는 "실제로 돌려보면 예상 못한 실패 모드가 나올 수 있다"는 귀납적 접근을 주장. |
| **Analogues** | Deming의 PDCA 사이클과 직접 관련: Plan(S33 프로토콜 설계) → Do(S14 리플레이) → Check(9% 성공률 확인) → Act(agent-browser 도입). 에이전트는 P→A로 뛰어넘으려 했고, 사용자가 Do→Check 단계를 강제했다. |
| **Situation Assessment** | 에이전트의 상황 인식이 **부정확**했다. 에이전트는 "404 문제가 핵심이고 프로토콜이 그걸 해결했다"고 판단했지만, 실제 핵심 실패 모드는 JS 렌더링 불가(WebFetch 도구 한계)였다. 이 사실은 리플레이 없이는 발견할 수 없었다. |
| **Time Pressure** | 에이전트가 이론적 접근을 선호한 배경에 컨텍스트 예산 압박이 있었다. 통합 테스트 세션에서 예정에 없던 web research 검증까지 하면 컨텍스트가 부족해질 수 있다는 판단. 그러나 이 압박이 "빨리 결론 내리기" 편향을 만들었다. |
| **Hypothesis** | 에이전트의 이론적 분석을 수용했다면: "S33 프로토콜로 404 해결 완료"로 종결되고, WebFetch의 JS 렌더링 한계(전체 실패의 45%)는 발견되지 않았을 것이다. 다음 세션에서 web research가 실패할 때 비로소 같은 문제를 다시 디버깅하게 된다. |

**핵심 교훈**: 프로토콜/프로세스 변경의 효과를 이론만으로 판단하지 마라.
과거 실패 시나리오를 경험적으로 리플레이하면, 이론으로는 보이지 않는
실패 모드가 드러난다. "Do→Check" 단계를 건너뛰는 것은 PDCA 사이클의
핵심을 무시하는 것이다.

---

## CDM 3: 에이전트 아키텍처 논쟁 vs 도구 한계 조사 — 잘못된 프레이밍

web research 리플레이 후 9% 성공률이 확인된 시점에서, 에이전트가
"sub-agent vs agent team" 아키텍처 논쟁에 약 4턴을 소비한 후에야 실제
실패 원인(WebFetch의 JS 미지원)을 조사한 의사결정.

| Probe | Analysis |
|-------|----------|
| **Cues** | 11개 URL 중 1개만 성공(9%). 실패 유형: JS-rendered empty (5건), 403 (2건), redirect chain (3건). 이 데이터가 이미 "도구 레벨 문제"를 가리키고 있었지만, 에이전트는 실패 패턴 분류 전에 아키텍처 논의를 시작했다. |
| **Goals** | 사용자: "왜 91%가 실패하는가"의 근본 원인 파악. 에이전트: 아키텍처 개선으로 성공률을 높이는 솔루션 제시. 사용자는 진단(diagnosis)을 원했고 에이전트는 처방(prescription)을 먼저 시도했다. |
| **Options** | **A.** 실패 유형별 분류 → 근본 원인 분석 → 적합한 해결책 도출 (bottom-up). **B.** 에이전트 아키텍처 변경으로 문제 해결 시도 (top-down). **C.** WebFetch 도구 자체의 한계 조사 (도구 레벨). |
| **Basis** | 에이전트가 B를 선호한 이유: sub-agent는 스킬 접근 불가 → agent team은 cwf:gather 사용 가능 → gather가 URL 라우팅을 하므로 성공률이 오른다. 논리적으로 타당해 보이지만, cwf:gather도 내부적으로 WebFetch를 사용하므로 JS 렌더링 문제는 동일하다. |
| **Aiding** | "5 Whys" 기법이 있었다면: 왜 실패? → WebFetch가 빈 페이지 반환 → 왜 빈 페이지? → JS 미실행 → 왜 JS 미실행? → WebFetch는 HTTP GET + HTML-to-markdown 도구 → 해결책: JS를 실행하는 도구 필요. 2번째 Why에서 이미 올바른 방향이 나온다. 아키텍처 논쟁은 불필요했다. |
| **Knowledge** | lessons.md에 기록된 통찰: "cwf:gather adds URL routing intelligence but uses WebFetch underneath." 에이전트가 이 사실을 조기에 인식했다면 아키텍처 논쟁을 4턴이 아닌 1턴에서 종결할 수 있었다. |
| **Tools** | 실패 시나리오에서 사용된 도구: WebFetch (HTTP GET only), WebSearch (URL 발견용, 정상 작동). 사용 가능했지만 사용하지 않은 도구: `curl -v`로 실제 HTTP 응답 헤더 확인 (JS 렌더링 문제인지 서버 차단인지 구분 가능했음). |
| **Situation Assessment** | 에이전트의 초기 프레이밍이 잘못되었다. "에이전트가 스킬을 사용할 수 있는가"는 실패와 무관한 차원이었다. 실패의 91%는 도구 레벨(WebFetch) 제약이었고, 에이전트 아키텍처를 바꿔도 같은 도구를 쓰면 같은 결과가 나온다. |

**핵심 교훈**: 디버깅에서 "아키텍처 변경"과 "도구 교체"는 서로 다른
레이어의 해결책이다. 실패 데이터의 패턴을 먼저 분류하라(bottom-up).
실패의 다수가 같은 도구 한계에서 비롯되면, 아키텍처가 아니라 도구를
교체해야 한다. **진단이 처방보다 먼저다.**

---

## CDM 4: agent-browser CLI vs MCP 서버 선택

WebFetch의 JS 렌더링 한계가 확인된 후, 브라우저 자동화 도구 선택에서
agent-browser CLI가 MCP 서버 대신 선택된 의사결정.

| Probe | Analysis |
|-------|----------|
| **Cues** | 사용자가 agent-browser(Vercel 오픈소스, headless Chromium CLI)를 직접 제안. MCP 서버(Playwright MCP 등)는 이전 세션에서 이미 논의되었으나 설정 복잡도가 높았다. |
| **Goals** | (1) JS 렌더링 능력 확보, (2) sub-agent에서 사용 가능한 인터페이스, (3) 설치/유지보수 단순성, (4) 기존 Bash 도구와 통합 용이성. |
| **Options** | **A.** agent-browser CLI — `npm install -g`, Bash에서 직접 호출, sub-agent가 Bash 도구로 사용 가능. **B.** Playwright MCP 서버 — 풍부한 API, 하지만 MCP 클라이언트 설정 필요, sub-agent에서 MCP 도구 접근이 불확실. **C.** Puppeteer 스크립트 — 최대 유연성, 하지만 커스텀 코드 유지보수 부담. |
| **Basis** | agent-browser의 결정적 장점: CLI 인터페이스. sub-agent가 Bash 도구로 `agent-browser open <url> && agent-browser snapshot -c`를 실행하면 끝이다. MCP 서버는 sub-agent가 MCP 도구에 접근할 수 있는지가 불확실하고, 설정 단계가 추가된다. "가장 단순한 통합 경로"가 선택 기준이었다. |
| **Knowledge** | cwf-state.yaml의 tools 섹션이 이미 `codex`, `gemini` 같은 CLI 도구를 관리하고 있었다. agent-browser도 같은 패턴(`command -v agent-browser`)으로 감지 가능 → 기존 인프라와 자연스럽게 통합된다. |
| **Analogues** | Unix 철학: "한 가지 일을 잘 하는 작은 도구를 파이프로 연결." agent-browser는 이 철학에 부합한다 — 페이지 열기, 스냅샷 찍기, 닫기의 3단계 CLI. MCP 서버는 "큰 도구 하나가 모든 것을 처리"하는 반대 접근. |
| **Experience** | 경험이 많은 엔지니어라면 "MCP 서버의 풍부한 API가 나중에 필요해질 수 있다"며 확장성을 고려했을 수 있다. 하지만 S14 시점에서 필요한 것은 "JS 렌더링된 텍스트 추출"뿐이므로, YAGNI 원칙이 적용된다. |

**핵심 교훈**: 도구 통합에서 "sub-agent가 가장 적은 설정으로 사용할 수
있는 인터페이스"를 우선하라. CLI는 Bash 도구만 있으면 즉시 사용 가능하고,
MCP/SDK 통합은 추가 인프라가 필요하다. 현재 필요한 능력이 명확할 때는
가장 단순한 통합 경로를 선택하라.

---

## 세션 전체 종합

### 낭비(Waste) 분석

| 구간 | 소요 | 낭비 유형 | 원인 |
|------|------|----------|------|
| 에이전트 아키텍처 논쟁 (CDM 3) | ~4턴 | 잘못된 프레이밍 | 실패 패턴 분류 전에 솔루션 논의 시작 |
| 에이전트의 리플레이 저항 (CDM 2) | ~2턴 | 시간 압박 편향 | 컨텍스트 예산 걱정이 "빨리 결론" 편향 유발 |

**총 낭비**: ~6턴. 세션 전체 대비 약 15-20% 추정.

### 재사용 가능한 휴리스틱 요약

| # | 휴리스틱 | 적용 조건 |
|---|---------|----------|
| H1 | LLM 스킬 시스템에서는 SKILL.md 정적 검증 = 구현 검증 | 통합 테스트 전략 수립 시 |
| H2 | 프로토콜 변경 후 과거 실패 시나리오를 경험적으로 리플레이하라 | Do→Check 건너뛰기 방지 |
| H3 | 실패 데이터 패턴 분류가 아키텍처 논쟁보다 먼저다 | 디버깅 시 bottom-up 원칙 |
| H4 | 도구 통합 시 sub-agent의 최소 설정 경로를 우선하라 | CLI vs SDK/MCP 선택 시 |

### 전문가 렌즈(Expert Lens)

- **Deming (PDCA)**: CDM 2에서 에이전트가 Do→Check를 건너뛰려 한 것은
  Deming의 "cease dependence on inspection"이 아니라 "cease dependence
  on verification"으로 왜곡된 것이다. Deming은 프로세스에 품질을 내장하라고
  했지, 검증 자체를 생략하라고 하지 않았다.
- **Klein (RPD)**: CDM 3에서 에이전트의 Recognition-Primed Decision이
  실패했다. 에이전트는 "성공률이 낮다 → 에이전트 아키텍처 문제"라고
  패턴 매칭했지만, 실제 패턴은 "성공률이 낮다 → 도구 한계"였다. 유사한
  표면 패턴이 다른 근본 원인을 가질 수 있다는 RPD의 한계.
- **Argyris (Single-loop vs Double-loop)**: CDM 2에서 사용자가 강제한
  리플레이는 double-loop learning의 전형적 예시. 에이전트의 "프로토콜이
  문제를 해결했으니 넘어가자"는 single-loop (기존 전략 유지). 사용자의
  "실제로 돌려보자"는 double-loop (전략의 전제 자체를 검증).

<!-- AGENT_COMPLETE -->
