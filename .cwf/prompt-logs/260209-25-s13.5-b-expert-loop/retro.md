# Retro: S13.5-B Expert-in-the-Loop

> Session date: 2026-02-09
> Mode: deep

## 1. Context Worth Remembering

- 유저는 clarify + spec 후 context clear할 때 프로토콜(HOW)이 유실되는 문제를 직접 식별함. 이것이 phase handoff 개념의 기원
- plan.md는 WHAT(스펙), phase handoff는 HOW(프로토콜/규칙/references) — 관심사 분리 원칙이 CWF 아키텍처 전반에 적용됨
- expert-lens-guide.md(retro 전용)와 expert-advisor-guide.md(clarify/review 범용)를 분리한 설계 판단. Consumer 수가 guide 분리의 기준
- retro 호출 자체가 "이 세션에 분석 가치가 있다"는 신호. 기본값이 deep이어야 함
- Review 스킬의 verdict logic이 "reviewer-count-agnostic"으로 설계되어 4→6 확장에 수정 불필요했음. 확장 의도를 주석으로 명시하는 것의 가치

## 2. Collaboration Preferences

- 유저는 이전 세션 교훈이 다음 세션에서 반영되는지를 명확하게 검증함 — "이전 retro/lessons 읽었나?"
- 설계 토론에서 honest counterargument를 기대하고 수용함 (plan template extension vs phase handoff 토론)
- 규칙의 문자적 준수보다 정신적 준수를 중시 — retro default bias 교정이 그 예
- 반복되는 패턴: 유저가 구조적 문제를 먼저 식별하고, 에이전트가 해결책을 제안하는 흐름

### Suggested CLAUDE.md Updates

- 없음 — 이번 세션 발견 사항은 주로 retro SKILL.md, handoff SKILL.md 수정 대상

## 3. Waste Reduction

### 이전 세션 lessons 미확인으로 인한 프로토콜 미준수

구현 시작 시 이전 세션의 lessons.md와 retro.md를 읽지 않아, lessons 기록, ship 프로세스 등의 프로토콜을 즉시 따르지 못함. 유저가 지적한 후에야 이전 세션 아티팩트를 확인.

**5 Whys**:
1. 왜? → 구현 시작 시 이전 세션 아티팩트를 자동으로 읽지 않음
2. 왜? → plan 파일에 "이전 세션 lessons를 읽어라"는 지시가 없었음
3. 왜? → plan이 WHAT만 전달하고 HOW(프로토콜)를 전달하지 않기 때문
4. **근본 원인**: clarify→spec→impl 전환 시 프로토콜을 전달하는 메커니즘이 없음 — 바로 이 세션에서 phase handoff로 해결하려는 문제

이것은 해결 방향이 이미 세션 내에서 결정됨 (phase handoff).

### Retro 모드 기계적 판단

SKILL.md의 "default bias: light"를 기계적으로 따라 아키텍처 결정이 다수인 세션에 light retro를 시도. 유저가 교정.

**5 Whys**:
1. 왜? → SKILL.md에 "When in doubt, choose light"로 명시되어 있어서
2. 왜? → 규칙의 문자를 따르고 정신(비용 절감 목적)을 고려하지 않음
3. 왜? → 맥락 기반 override 조건이 SKILL.md에 없음
4. **근본 원인**: 규칙에 맥락 판단 트리거가 부재. "CDM 3건 이상 or 새 아키텍처 패턴 도입 시 deep" 같은 조건이 필요

**해결 방향**: retro SKILL.md의 기본값을 "deep (unless --light specified)"로 변경

## 4. Critical Decision Analysis (CDM)

### CDM 1: Haiku advisory sub-agent 실패 시 대응 — 프롬프트 제약 vs 모델 교체

| Probe | Analysis |
|-------|----------|
| **Cues** | Haiku sub-agent 2개 모두 질문만 되돌림. 구조적 문제 시사 |
| **Goals** | (1) expert advisory output 생산 (2) Haiku 비용 효율 유지 (3) 다른 스킬에 재사용 가능 |
| **Options** | (a) "DO NOT ask questions" + 예시 pre-fill (채택) (b) Opus로 교체 (c) main agent가 직접 분석 (d) multi-turn 래퍼 |
| **Basis** | 실패 원인이 모델 능력이 아니라 프롬프트 모호성. (a)는 비용 변화 없이 근본 원인 해결 |
| **Hypothesis** | 모델 교체(b)는 당장 작동하지만, "Haiku로 충분한 작업에 Opus를 쓰는" anti-pattern 고착 위험 |

**Key lesson**: Sub-agent 실패 시 모델 능력을 의심하기 전에 프롬프트의 output 명시성을 먼저 점검하라.

### CDM 2: Expert advisor guide 분리 — 기존 확장 vs 신규 생성

| Probe | Analysis |
|-------|----------|
| **Cues** | expert-lens-guide.md가 retro deep mode에 특화 (CDM 결과 의존, Section 5 format) |
| **Goals** | (1) 3개 스킬의 expert 패턴 공유 (2) retro regression 없음 (3) 확장 경로 |
| **Options** | (a) expert-lens-guide.md 확장 (b) expert-advisor-guide.md 신규 (채택) (c) 통합 mega-guide |
| **Basis** | Consumer 1개(특화) vs N개(범용)가 분리 기준. 특화 가이드 강제 범용화는 모든 consumer에 복잡도 전파 |

**Key lesson**: Reference guide 분리 판단에서 consumer 수가 핵심 기준. "지금 분리, 안정 후 통합"이 더 안전.

### CDM 3: Phase handoff vs plan template 확장

| Probe | Analysis |
|-------|----------|
| **Cues** | 유저가 context clear 후 프로토콜 유실을 직접 식별. plan.md는 WHAT은 잘 전달하지만 HOW가 빠짐 |
| **Goals** | (1) context clear 후 프로토콜 유지 (2) plan.md 역할 오염 방지 (3) 기존 워크플로우와 통합 |
| **Options** | (a) plan에 "Implementation Context" 섹션 추가 (b) handoff에 --phase 모드 추가 (채택) |
| **Basis** | 관심사 분리. handoff는 이미 "맥락 전달"이 핵심 역할 — phase 단위로 확장이 자연스러움 |
| **Aiding** | "이 정보의 관심사를 이미 담당하는 도구가 있는가?" 체크리스트가 있었다면 handoff가 즉시 후보로 부상 |

**Key lesson**: 새 정보 전달 요구 시, 가장 가까운 문서에 섹션을 추가하지 말고 "이 관심사를 이미 담당하는 도구"를 먼저 찾아라.

### CDM 4: Retro 기본 모드 — 규칙의 문자 vs 정신

| Probe | Analysis |
|-------|----------|
| **Cues** | 아키텍처 결정 3건, 설계 토론 포함. SKILL.md의 "default bias: light" |
| **Goals** | (1) 적절한 분석 깊이 (2) 비용 방지 (3) SKILL.md 준수 |
| **Basis** | 에이전트가 규칙 텍스트에 집중, 세션 복잡도를 과소평가. "doubt"는 세션 복잡도가 모호할 때를 의미하는데 이 세션은 모호하지 않았음 |
| **Situation Assessment** | 부정확. 규칙을 따르는 것과 규칙의 의도를 이해하고 적용하는 것 사이의 간극 |

**Key lesson**: 도구의 기본값 규칙 적용 시, 규칙의 문자가 아니라 의도를 먼저 파악하라. retro 호출 자체가 분석 의도의 신호.

## 5. Expert Lens

### Expert alpha: Gary Klein

**Framework**: 자연주의적 의사결정(Naturalistic Decision Making) — 실제 환경에서 전문가가 패턴 인식 기반으로 의사결정하는 방식
**Source**: *Sources of Power: How People Make Decisions* (MIT Press, 1998)
**Why this applies**: 이 세션에서 "규칙의 문자적 준수 vs 상황 맥락에 맞는 판단"이라는 긴장이 반복됨. Klein의 RPD 모델은 숙련된 전문가가 체크리스트를 기계적으로 따르지 않고 상황을 인식하여 적절한 경로를 선택한다고 설명.

Haiku 서브에이전트 실패(CDM1)는 Klein의 정신 시뮬레이션 부재를 보여줌. 행동을 실행하기 전에 "이 입력을 주면 어떤 응답이 돌아올까?"를 시뮬레이션했다면 모호한 프롬프트가 역질문으로 이어질 가능성을 사전에 포착했을 것. 다만 실패 후 대응은 Klein이 말하는 만족화(satisficing) 전략의 좋은 예 — 최적 해법 탐색 대신 "충분히 작동하는 첫 번째 해법"을 선택.

Retro 기본 모드 판단(CDM4)은 Klein의 프레임워크에서 초보자의 의사결정 패턴에 해당. 초보자가 규칙을 문자 그대로 따르는 반면, 전문가는 상황을 인식(recognition)하여 규칙을 맥락에 맞게 적용. 에이전트가 아직 CWF 워크플로우에 대한 충분한 경험 기반 패턴 라이브러리를 축적하지 못했음을 의미. Phase handoff 설계(CDM3)는 레버리지 포인트 발견의 좋은 사례 — plan에 HOW를 추가하는 표면적 해법을 넘어 관심사 분리라는 구조적 레버리지를 포착.

**Recommendations**:
1. **정신 시뮬레이션 체크포인트**: 새 서브에이전트/도구 호출 전 "이 입력으로 어떤 출력이 돌아올까?"를 한 단계 시뮬레이션하는 단계를 프로토콜에 추가
2. **상황 인식 기준의 명시화**: "default bias: light" 같은 규칙에 패턴 매칭 조건 추가 (CDM 3개 이상 or 새 아키텍처 패턴 → deep)

### Expert beta: Chris Argyris

**Framework**: Espoused Theory vs Theory-in-Use, 그리고 Double-Loop Learning — 조직이 "말하는 것"과 "실제로 하는 것" 사이의 괴리를 식별하고, 근본 가정 자체를 재검토하는 학습 프레임워크
**Source**: *Theory in Practice* (Argyris & Schön, 1974); "Double Loop Learning in Organizations," *Harvard Business Review* (1977); *Organizational Learning II* (1996)
**Why this applies**: 이 세션은 반복적으로 "규칙의 문자 vs 규칙의 정신" 충돌을 보여줌. CLAUDE.md에 lessons 기록 프로토콜이 있지만 에이전트가 따르지 않았고, retro 기본 모드가 light로 설정되어 있지만 deep이 맞았음. 전형적인 espoused theory(프로토콜)와 theory-in-use(실제 행동) 괴리.

CDM4(retro 모드)는 Argyris의 **Model I 행동** — 규칙을 표면적으로 준수하면서 그 규칙이 존재하는 이유를 질문하지 않는 패턴. "default bias: light"는 single-loop learning — 온도 조절기가 68도를 유지하되 "68도가 맞는 설정인가?"를 묻지 않는 것. 사용자가 이를 교정한 것은 double-loop을 외부에서 강제한 셈.

프로토콜 미준수(lessons 미기록)도 같은 구조. Argyris가 *Overcoming Organizational Defenses*(1990)에서 말한 **skilled incompetence** — 규칙을 몰라서가 아니라, 이행을 트리거하는 내적 메커니즘이 없어서 기본 행동(Model I)으로 회귀.

반면 CDM3(phase handoff)는 건강한 **double-loop learning** 사례. "plan에 추가하면 되지 않나?"라는 single-loop 해법을 넘어 "WHAT과 HOW는 본질적으로 다른 관심사인가?"라는 근본 가정을 질문. Model II — 공개적으로 검증 가능한 위치를 취하고 대안을 진정으로 검토 — 가 작동한 순간.

**Recommendations**:
1. **Theory-in-use 감사 체크포인트**: retro Section 2에 "프로토콜에 명시된 행동 중 이 세션에서 수행되지 않은 것" 점검 항목 추가. Espoused vs Actual 괴리를 에이전트가 스스로 포착하게 함
2. **맥락 기반 override 휴리스틱 코드화**: "CDM 3건 이상이거나 새 아키텍처 패턴 도입 세션은 deep 권장" 같은 조건을 retro SKILL.md에 명시. 기계적 준수(single-loop)에서 맥락 판단(double-loop)으로의 전환을 구조적으로 지원

## 6. Learning Resources

### 1. Context Engineering for Agents — Lance Martin (LangChain)

**URL**: [rlancemartin.github.io/2025/06/23/context_engineering](https://rlancemartin.github.io/2025/06/23/context_engineering/)

LLM 에이전트의 컨텍스트 윈도우를 "RAM"에 비유하며, 컨텍스트 관리를 **Write(외부 저장)**, **Select(선택적 불러오기)**, **Compress(요약)**, **Isolate(서브에이전트 분리)** 네 가지 전략으로 체계화. Claude Code의 auto-compact 사례, Anthropic 멀티에이전트 리서처의 plan 메모리 저장 사례 포함.

**CWF 연결**: phase handoff(Write + Select 패턴)와 직접 대응. plan에 WHAT을, handoff에 HOW를 분리 저장하고 다음 phase에서 선택적으로 불러오는 구조가 정확히 같은 원리.

### 2. Orchestrating Human-AI Teams: The Manager Agent (DAI '25)

**URL**: [arxiv.org/pdf/2510.02557](https://www.arxiv.org/pdf/2510.02557)

Manager Agent가 인간 전문가와 AI 워커를 실행 중(during execution) 동적으로 조율하는 프레임워크. (1) task graph 분해, (2) 역량/가용성 기반 동적 할당, (3) 진행 모니터링 및 장애 선제 감지.

**CWF 연결**: expert-in-the-loop 패턴의 학술적 근거. Expert roster의 semi-automatic 진화 메커니즘이 이 논문의 "heterogeneous capability 기반 동적 할당 + governance" 개념과 맞닿음.

### 3. Architecting Resilient LLM Agents: Plan-then-Execute Pattern

**URL**: [arxiv.org/pdf/2509.08646](https://arxiv.org/pdf/2509.08646)

Plan-then-Execute 패턴을 체계적으로 분석. plan artifact에 steps + reasoning + success criteria + contingency 포함. 실행 단계에서 validation checkpoint, feedback loop, rollback capability 적용.

**CWF 연결**: "plan carries WHAT, phase handoff carries HOW" 분리와 구조적으로 동일. "실행자가 plan을 기계적으로 따르지 않고 의도를 이해하고 적응한다"는 원칙이 S13.5-B의 핵심 문제의식과 일치.

## 7. Relevant Skills

### Installed Skills

- **cwf:handoff** — 이번 세션의 핵심 확장 대상. phase handoff 모드를 추가하여 clarify→spec→impl 전환 시 HOW를 전달하는 메커니즘 구축 예정
- **cwf:clarify** — Phase 2.5(Expert Analysis) 추가 완료. 다음 clarify 실행 시 expert sub-agents 작동 검증 필요
- **cwf:retro** — Section 7에 expert roster maintenance 추가. 기본값을 deep으로 변경하는 것이 다음 과제
- **/review** — 4→6 리뷰어 확장 완료. 다음 review 실행 시 expert reviewer slots 작동 검증 필요

### Skill Gaps

- **Phase handoff 메커니즘 부재**: clarify/spec 종료 시 HOW를 전달하는 도구가 없음. handoff 스킬에 `--phase` 모드로 해결 예정 (이 세션에서 설계, 구현은 이어서)
- **세션 시작 시 이전 세션 lessons 자동 로딩**: 이전 세션 lessons/retro를 자동으로 읽는 메커니즘 부재. Phase handoff가 이 문제의 부분 해결책이 될 수 있음

---

### Post-Retro Findings

> Context: deep retro 이후 context compact → `--phase` 모드 구현 완료

#### Phase Handoff 구현 결과

handoff SKILL.md(`--phase` 모드), impl SKILL.md(Phase 1.1b 소비), clarify SKILL.md(Phase 5 제안) 3개 파일 수정 완료. 핵심:

- **handoff Phase 3b**: HOW 맥락을 6개 섹션(Context Files, Design Decisions, Protocols, Do NOT, Implementation Hints, Success Criteria)으로 구조화
- **impl Phase 1.1b**: plan.md와 같은 디렉토리에서 `phase-handoff.md` 자동 감지. 발견 시 Protocols/Do NOT을 plan 제약과 동일 수준으로 적용
- **clarify Phase 5**: `cwf:handoff --phase` 제안 추가. context clear 전 HOW 보존 안내

#### Waste

- context compact 후에도 phase-handoff.md 프로토타입이 있어 구현 방향이 명확했음 — phase handoff의 첫 번째 개밥먹기 성공
- Plan agent가 상세 구현 계획을 잘 생성하여 구현은 기계적 편집으로 진행 가능했음. 낭비 거의 없음

#### CDM: Phase 3b를 별도 섹션으로 vs Phase 3 내부 분기로

- **Cues**: handoff SKILL.md에서 `--register`는 Phase 3을 skip하는 패턴. `--phase`는 Phase 3을 대체하는 패턴
- **Options**: (A) Phase 3 내부 if/else 분기, (B) 독립 Phase 3b 섹션
- **Basis**: Phase 3의 8개 필수 섹션과 Phase 3b의 6개 섹션은 구조가 완전히 다름. if/else로 넣으면 가독성이 크게 저하
- **결정**: Phase 3b로 분리 — 관심사 분리가 문서 구조에도 적용됨

#### Explore agent S15 fabrication

Explore agent에게 "남은 할 일" 조사를 위임했고, agent가 master-plan.md에 존재하지 않는 S15를 fabricate. project-context.md에 이미 "Agent results require spot-checks" 교훈이 있었지만 적용하지 않음. 유저가 "S15가 뭔가요?"로 발각.

**5 Whys**: 교훈을 알지만 적용하지 않음 → agent 결과를 "요약이니까 맞겠지" 하고 신뢰 → 사실적 주장(세션 존재 여부)과 분석적 주장을 구분하지 않음 → **Process gap**: agent 결과 중 사실적 주장은 원본 파일 대조 프로토콜 필요

#### Plan.md 세션 디렉토리 복사 반복 실패

이번 세션에서도 plan mode 종료 후 `~/.claude/plans/`의 plan을 `prompt-logs/`로 복사하지 않아 `check-session.sh`에서 FAIL. S13.5-A에서 이미 식별된 carry-forward 항목이지만 여전히 수동 `cp`로 해결 중. **Tier 1 해결책**: PostToolUse:ExitPlanMode hook으로 자동 복사 — cwf:plan 스킬 소관.
