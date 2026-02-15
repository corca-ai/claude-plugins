# Retro: S16 — V3 Exhaustive Analysis Handoff Design + Review + TOOL_ERROR Fix

> Session date: 2026-02-11
> Mode: deep

## 1. Context Worth Remembering

- **Gemini CLI `-o text` 모드 도구 제한**: Gemini CLI는 `-o text` 모드에서 `run_shell_command` 도구가 존재하지 않는다. 인터랙티브 모드에서만 사용 가능한 도구와 텍스트 출력 모드의 도구 세트가 다르다. 이는 향후 외부 CLI 호출 시 모드별 도구 가용성을 고려해야 함을 의미한다.
- **sub-agent 파일 미생성 패턴**: Expert β 역할의 sub-agent가 두 번 연속(review, retro) 파일을 쓰지 않는 현상이 관찰됨. 명시적 "CRITICAL: Output Persistence" 지시와 "Do NOT skip writing the file" 강조를 추가한 재시도에서 성공. Task agent의 파일 쓰기 신뢰성은 프롬프트의 강조 수준에 민감할 수 있다.
- **리뷰어 합의도 신호**: 6명 중 5명이 Phase 0 git 명령의 scope 불완전성을 독립적으로 지적 — 83% 합의도. 이 수준의 합의는 단일 체크리스트로도 포착 가능한 "Check 수준" 결함이었다는 역설적 신호.
- **프로토콜 문서 리뷰 시 전문가 매칭**: 명세 문서에는 Adzic(SbE) + Leveson(STPA)이 최적. 구현 코드에는 다른 조합이 필요. 문서 유형에 따라 전문가 프레임워크를 매칭하는 것이 발견 품질을 결정한다.

## 2. Collaboration Preferences

- 사용자는 타임아웃 등 실패의 **정확한 근본 원인**을 물었다. 표면적 증상("타임아웃") 보고가 아닌, 근인 분석(`-o text` 모드의 도구 세트 차이)까지 드릴다운하는 것을 선호한다.
- "바로 추가해주시고요"라는 요청은 진단-수정-커밋의 원자적 흐름을 한 세션 내에서 완결하는 선호를 보여준다. 세 가지 전제 조건(진단 완료, 원자적 범위, 사용자 관여)이 충족된 상태에서의 즉시 수정을 지지.
- 리뷰 결과를 `next-session.review.claude.md`라는 특정 파일명으로 저장하도록 지시 — 리뷰 산출물에 대한 명확한 네이밍 규칙을 가지고 있다.

### Suggested Agent-Guide Updates

- `AGENTS.md`에 "발견 시점 수정 3대 전제 조건(진단 완료, 원자적 범위, 사용자 관여)" 패턴을 명시적으로 추가하는 것을 고려. 이 패턴은 S15, S16에서 반복적으로 적용되었다.

## 3. Waste Reduction

### 120초 타임아웃 낭비 — Gemini CLI TOOL_ERROR

Gemini CLI가 120초간 타임아웃된 후에야 실패가 발견되었다. stderr에 `Tool "run_shell_command" not found`가 즉시 출력되었음에도, 기존 오류 분류 체계에 해당 패턴이 없어 120초를 소비했다.

**5 Whys 드릴다운**:
1. 왜 120초 낭비? → 기존 분류(CAPACITY/INTERNAL/AUTH)에 매칭되지 않아 타임아웃까지 대기
2. 왜 매칭 안 됨? → 도구 해석 실패라는 실패 모드가 분류 체계에 존재하지 않았음
3. 왜 존재하지 않았음? → 분류 체계가 **실제 실패 경험**에 의해서만 확장되는 구조
4. 왜 사전에 예측 안 함? → 외부 CLI의 모드별 도구 차이를 사전에 문서화/검증하는 절차 부재
5. **구조적 원인**: `cwf:review`의 외부 CLI 디스패치가 **open-loop** — 도구 가용성에 대한 사전 검증 없이 작업을 보내고 결과만 기다린다.

**분류**: 프로세스 갭 (Tier 1 가능: pre-flight capability check 스크립트)
**수정 완료**: TOOL_ERROR fail-fast 패턴 추가 (검사 개선). 근본적 해결(사전 도구 검증)은 미래 세션 백로그.

### Expert β sub-agent 파일 미생성 재시도

Review와 Retro 양쪽에서 Expert β sub-agent가 파일을 쓰지 않아 각각 1회 재시도가 필요했다. 총 2회의 추가 라운드트립 소비.

**5 Whys 드릴다운**:
1. 왜 파일 미생성? → sub-agent가 분석을 완료했으나 Write 도구를 호출하지 않음
2. 왜 Write 미호출? → 프롬프트 마지막의 "Output Persistence" 지시가 충분히 강조되지 않았을 가능성
3. 왜 강조 불충분? → 다른 slot의 sub-agent들은 동일 형식으로 성공 — 확률적 변동
4. **구조적 원인**: sentinel marker 기반 검증(`<!-- AGENT_COMPLETE -->`)이 있으나, 파일 생성 자체의 실패에 대한 자동 재시도 메커니즘이 없다.

**분류**: 프로세스 갭 (Tier 1 가능: context recovery protocol에 auto-retry 로직 추가)
**현재 상태**: 수동 재시도로 해결. 자동 재시도는 향후 개선 사항.

## 4. Critical Decision Analysis (CDM)

### CDM 1: Expert Reviewer Pair Selection — Adzic (Specification by Example) + Leveson (STAMP/STPA)

| Probe | Analysis |
|-------|----------|
| **Cues** | 리뷰 대상이 handoff 프로토콜 명세 문서 — 구현 코드가 아님. 6-phase 분석 워크플로우, evidence hierarchy, completion criteria, "Do Not Skip" 제약 등 구조적 속성이 명세 품질 + 제어 구조 분석 전문가를 요구. |
| **Goals** | (1) 리뷰 발견의 다양성 극대화, (2) 전문가 프레임워크와 대상 문서 유형의 적합도 확보. 14명 전문가 로스터의 대부분은 구현 지향 — 프로토콜 명세에는 부적합. |
| **Options** | (a) Adzic + Leveson (선택), (b) Adzic + Nygard (Release It! — 복원력 패턴), (c) Leveson + Wayne (형식적 방법). Option (b)는 Gemini 실패로 약화된 아키텍처 관점을 보강했을 수 있으나, "key example" 발견을 놓쳤을 것. |
| **Basis** | Adzic: "telephone game" 위험(추상적 절차 → 해석 편차). Leveson: 프로토콜을 제어 구조로 분석(open-loop 탐지). 두 프레임워크가 상호보완적: Adzic는 명세 모호성, Leveson은 제어 구조 갭에 집중. |
| **Hypothesis** | Adzic 대신 Nygard 선택 시 resilience/degraded-mode 발견 강화 but "key example 부재"와 "existence-only 완료 기준" 발견 누락. 현재 선택이 이 대상에 대해 더 높은 가치. |

**Key lesson**: 전문가 선택은 평판이 아닌 프레임워크-대상 적합도로 결정해야 한다. 문서 유형(명세/구현/아키텍처/운영)을 먼저 분류하고, 해당 유형에 최적 프레임워크를 가진 전문가를 선택하라.

### CDM 2: TOOL_ERROR 범주 생성 — 기존 분류에 강제 편입하지 않은 결정

| Probe | Analysis |
|-------|----------|
| **Cues** | Gemini stderr: `Tool "run_shell_command" not found`. 기존 3개 범주(CAPACITY/INTERNAL/AUTH) 어디에도 정확히 맞지 않음. CAPACITY(용량 아님), INTERNAL(내부 오류 아님), AUTH(인증 아님). |
| **Goals** | (1) 현 세션의 confidence note 정확성, (2) 미래 세션의 120초 낭비 방지, (3) 분류 체계의 일관성 유지. |
| **Options** | (a) CAPACITY에 강제 편입 (표면 증상=타임아웃), (b) INTERNAL에 강제 편입, (c) 신규 TOOL_ERROR 범주 생성 (선택). |
| **Basis** | 복구 경로의 차이: TOOL_ERROR는 결정론적 실패 — 재시도 무의미 — 즉각 폴백이 유일한 올바른 대응. 증상 유사성(타임아웃)이 아닌 복구 전략 차이로 분류해야 한다. |

**Key lesson**: 복구 경로가 기존 범주와 다를 때 새 범주를 만들어라. 증상이 비슷해도 복구 경로가 다르면 별도 분류가 필요하다.

### CDM 3: 세션 내 즉시 수정 vs. 백로그 등록

| Probe | Analysis |
|-------|----------|
| **Cues** | 수정 범위: SKILL.md에 enum 1개, regex 2개, action 1개 (~5줄). 진단 완료: `-o text` 모드의 도구 세트 차이. 사용자가 명시적으로 근인 분석을 요청. |
| **Goals** | (1) 리뷰 합성 산출물 우선 배달, (2) 미래 120초 낭비 방지, (3) 세션 scope 규율 유지. |
| **Options** | (a) 즉시 수정 (선택), (b) lessons.md에만 기록, (c) 별도 브랜치에서 수정. |
| **Basis** | 세 가지 전제 조건 충족: 진단 완료(결정론적 실패 확인), 원자적 범위(5줄), 사용자 관여(명시적 요청). lessons.md 등록 시 교훈이 시간 지나며 우선순위 하락 위험("재고 위험"). |

**Key lesson**: 진단 완료 + 원자적 범위 + 사용자 관여 세 조건이 모두 충족될 때만 세션 내 즉시 수정하라. 하나라도 빠지면 백로그로.

### 메타 관찰: 리뷰 도구와 리뷰 대상의 동형 결함

CDM 분석의 가장 주목할 관찰은 **cwf:review가 S17 handoff에서 발견한 "open-loop 제어" 결함이 cwf:review 자체에도 동일하게 존재했다**는 점이다. Leveson의 STPA가 리뷰 대상에서 "Phase 0→1 전환이 open-loop"라고 지적한 바로 그 패턴이 cwf:review의 Gemini CLI 디스패치에서 재현되었다 — 도구 가용성 피드백 없이 작업을 전송. 리뷰 도구가 리뷰 대상과 동일한 결함 클래스를 공유할 때, 해당 결함은 리뷰에 의해 발견될 수 없다 (common-mode failure).

## 5. Expert Lens

### Expert alpha: Charles Perrow

**Framework**: 정상 사고 이론 (Normal Accident Theory) — 상호작용적 복잡성(interactive complexity)과 밀결합(tight coupling)이라는 두 차원으로 시스템 실패의 불가피성과 분류를 분석하는 프레임워크
**Source**: *Normal Accidents: Living with High-Risk Technologies* (Basic Books, 1984; Princeton University Press 개정판, 1999)
**Why this applies**: S16의 다중 모델 오케스트레이션에서 Gemini CLI의 도구 해석 실패와 오류 분류 체계 확장은 Perrow가 분석하는 영역 — 이질적 구성 요소의 밀결합 파이프라인에서 예상치 못한 상호작용 실패.

**CDM 2 — 구성 요소 실패 vs. 상호작용 실패**: CAPACITY/INTERNAL/AUTH는 모두 구성 요소 내부 실패(component failure). TOOL_ERROR는 구성 요소 간 상호작용 실패(interaction failure) — 호출자의 도구 가정과 피호출자의 실제 도구 목록 사이의 불일치. 다중 모델 시스템이 성숙할수록 상호작용 실패가 지배적이 될 것이며, 이것이 "정상 사고"의 본질이다.

**CDM 1 — 공통 모드 실패**: cwf:review가 리뷰 대상과 동일한 제어 구조 결함을 공유하는 것은 안전 시스템이 감시 대상과 동일한 복잡성 특성을 공유할 때 발생하는 common-mode failure. 해결: 리뷰 시스템과 피리뷰 시스템의 결합 특성을 달리 설계해야 한다.

**CDM 3 — 밀결합의 버퍼**: `lessons.md`는 소결합을 위한 버퍼. 세 가지 전제 조건은 밀결합을 안전하게 허용하는 조건들이며, 각각 밀결합 위험(전파, 비가시적 상호작용, 모델-상태 괴리)을 완화한다.

**Recommendations**:
1. 오류 분류 체계를 "구성 요소 실패"와 "상호작용 실패"의 두 층위로 재구조화. 새 실패 모드 발생 시 "구성 요소 고장인가, 인터페이스 문제인가?"라는 첫 질문이 분류를 안내.
2. cwf:review의 외부 CLI 디스패치에 "독립 채널 검증" 원칙 적용 — 검증 메커니즘이 디스패치 메커니즘과 동일한 실패 모드를 공유하지 않도록 설계.

### Expert beta: W. Edwards Deming

**Framework**: 시스템적 사고, 공통 원인 변동 vs 특수 원인 변동, PDCA 사이클, 프로세스에 품질 내재화
**Source**: *Out of the Crisis* (MIT Press, 1982/1986); *The New Economics for Industry, Government, Education* (MIT Press, 1993/2000)
**Why this applies**: 검사에 의존한 사후 결함 발견 대신 프로세스 자체에 품질을 내재화해야 한다는 원칙. 공통 원인/특수 원인 혼동이 시스템 개선을 방해하는 메커니즘.

**CDM 2 — 공통 원인 vs. 특수 원인**: Gemini TOOL_ERROR는 표면적으로 특수 원인(특정 CLI의 특정 모드)이지만, 근본적으로 공통 원인(사전 도구 가용성 검증 부재)의 한 발현. stderr 패턴 매칭 추가는 "더 빠른 검사"이지, 결함이 발생할 수 없는 프로세스 설계가 아니다. Point 3: "대량 검사에 의존하지 말라."

**CDM 1 — Check vs. Study**: 5/6 리뷰어의 Phase 0 scope 합의(83%)는 "Check" 수준 발견 — 단일 체크리스트로도 포착 가능했던 결함에 5명의 리소스 투입. 반면 Adzic의 "key example 부재"와 Leveson의 "open-loop 검증"은 "Study" 수준 발견 — 프로세스가 왜 이 결함을 생성하는지에 대한 구조적 통찰. 리뷰의 목표를 "결함 발견"에서 "프로세스 학습"으로 재정의해야 한다.

**CDM 3 — 지식의 이론**: 진단 완료 = 이론 형성(예측 가능한 설명), 원자적 범위 = 이론의 검증 가능한 적용, 사용자 관여 = 사회적 검증. S16의 미니 PDCA(Plan→Do→Study→Act)는 건전하게 실행됨.

**Recommendations**:
1. 오류 분류에 "공통 원인/특수 원인" 차원 추가. 공통 원인 분류 시 개별 복구가 아닌 시스템 수준 프로세스 재설계를 트리거.
2. 리뷰 디스패치 전 자동화된 사전 검증으로 "Check" 수준 결함 제거 → 전문가의 시간을 "Study" 수준 발견에 집중.

## 6. Learning Resources

### 리소스 1: MAST — Why Do Multi-Agent LLM Systems Fail?

**Cemri et al. (UC Berkeley), NeurIPS 2025 Spotlight**

- 논문: <https://arxiv.org/abs/2503.13657>
- GitHub: <https://github.com/multi-agent-systems-failure-taxonomy/MAST>

7개 MAS 프레임워크의 1,642개 실행 트레이스 분석으로 14가지 실패 모드를 3개 카테고리로 분류한 실증 기반 taxonomy. 41%~86.7% 실패율을 보이며, 대부분이 LLM 한계가 아닌 시스템 설계 결함에서 기인. CWF의 외부 CLI 에러 분류 체계가 ad hoc으로 성장 중인 현 시점에서 MAST의 3-카테고리 14-모드 프레임워크가 참조 모델.

### 리소스 2: STPA Handbook — Systems-Theoretic Process Analysis

**Nancy Leveson & John Thomas (MIT)**

- PDF: <http://www.flighttestsafety.org/images/STPA_Handbook.pdf>
- 배경: Leveson, *Engineering a Safer World*, MIT Press, 2012

STAMP 모델 기반 위험 분석 방법론의 실무 가이드(188p). 4단계 절차: 손실/위험 식별 → 제어 구조 다이어그램 → UCA 식별 → 인과 시나리오 생성. S16에서 Expert Beta(Leveson)가 handoff 프로토콜의 Type 2 UCA(전제 조건 미검증)와 Type 3 UCA(stale process model)를 식별한 것이 이 방법론의 적용. STPA의 4단계를 `cwf:review`의 명시적 체크리스트로 코드화 가능.

### 리소스 3: Taxonomy of Failure Modes in Agentic AI Systems

**Microsoft AI Red Team (Pete Bryan, Ram Shankar Siva Kumar et al.), 2025**

- 블로그: <https://www.microsoft.com/en-us/security/blog/2025/04/24/new-whitepaper-outlines-the-taxonomy-of-failure-modes-in-ai-agents/>
- 백서 PDF: <https://cdn-dynmedia-1.microsoft.com/is/content/microsoftcorp/microsoft/final/en-us/microsoft-brand/documents/Taxonomy-of-Failure-Mode-in-Agentic-AI-Systems-Whitepaper.pdf>

Safety vs Security × Novel vs Existing 두 축 분류. "Function compromise", "Incorrect permissions", "Excessive agency" 등 도구 관련 실패 모드가 명시. MAST가 실패 *진단*에 초점이라면, 이 백서는 실패 *방어* 설계에 초점 — 상호 보완적.

### 리소스 간 관계

```text
STPA Handbook (Leveson)          MAST (Berkeley)          MS Taxonomy (Red Team)
  제어 구조 + UCA 분석               실패 모드 진단              실패 모드 방어
  프로토콜 설계 시점                  실행 후 분석 시점            설계 + 운영 시점
         │                              │                          │
         └──── CWF에서의 적용 ───────────┴──────────────────────────┘
               │
               ├─ cwf:review → STPA 체크리스트 (open-loop 탐지)
               ├─ 에러 분류 → MAST 3-category 14-mode 참조
               └─ 방어 설계 → MS taxonomy 완화 전략 참조
```

## 7. Relevant Skills

### Installed Skills

**Local skills**:
- `.claude/skills/plugin-deploy/SKILL.md` — 플러그인 배포 자동화. 이번 세션에서 SKILL.md를 수정하고 커밋했지만, marketplace 배포가 필요하지 않아 직접 사용하지 않음. 향후 TOOL_ERROR 수정을 포함한 cwf 플러그인 릴리즈 시 활용.

**CWF skills used this session**:
- `cwf:review` — 핵심 사용. 6명 병렬 리뷰어 오케스트레이션, Gemini 폴백, 합성 verdict 산출.
- `cwf:retro` — 현재 실행 중. deep 모드 4 sub-agent 분석.

**CWF skills that could have helped**:
- `cwf:refactor --mode quick` — TOOL_ERROR 수정 후 review SKILL.md 전체에 대한 quick scan으로 다른 누락된 에러 패턴을 사전 발견할 수 있었을 것. 하지만 수정 범위가 원자적이어서 실질적 가치는 제한적.

### Skill Gaps

이번 세션에서 식별된 워크플로우 갭:
- **pre-flight CLI capability check**: 외부 CLI에 작업 디스패치 전 도구 가용성을 검증하는 메커니즘. 현재 별도 스킬이 아닌 `cwf:review` 스킬 내부 절차로 추가하는 것이 적절. 별도 스킬 불필요.
- **sub-agent 파일 생성 auto-retry**: context recovery protocol에 auto-retry 로직을 추가하는 것. 별도 스킬보다 기존 프로토콜 확장이 적절.

추가적인 스킬 갭은 식별되지 않았다.
