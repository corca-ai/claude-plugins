# CDM Analysis: S16 — CWF v3 Gap Analysis Handoff Review + Gemini Error Classification Fix

**Session**: S16
**Date**: 2026-02-11
**Branch**: marketplace-v3
**Methodology**: Gary Klein's Critical Decision Method (CDM)

---

## Section 1: Session Overview

S16 was a dual-purpose session: (1) a `cwf:review` orchestration of the S17 handoff document (`next-session.md`) using 6 parallel reviewers, and (2) a reactive diagnosis-and-fix cycle when the Gemini CLI reviewer failed with a tool resolution error after 120 seconds. The session produced a Conditional Pass verdict with strong reviewer consensus on Phase 0 scope incompleteness, and a new `TOOL_ERROR` error classification category in SKILL.md.

---

## Section 2: Critical Decision Inventory

| # | Decision | Type | Impact |
|---|----------|------|--------|
| CDM 1 | Expert reviewer pair: Adzic + Leveson | Strategy choice | Shaped the quality and complementarity of expert review coverage |
| CDM 2 | Classify Gemini failure as new TOOL_ERROR category | Assumption-based / direction change | Created a new error taxonomy entry; changed the session's scope from pure review to review + fix |
| CDM 3 | Fix error classification in-session rather than deferring | Trade-off resolution | Invested session time in infrastructure fix vs. staying focused on review deliverable |

---

## Section 3: CDM Probe Analysis

### CDM 1: Expert Reviewer Pair Selection — Adzic (Specification by Example) + Leveson (STAMP/STPA)

| Probe | Analysis |
|-------|----------|
| **Cues** | The review target was a handoff protocol document (`next-session.md`) — not implementation code. The document defines a 6-phase analysis workflow with evidence hierarchies, completion criteria, and "Do Not Skip" constraints. These structural properties signaled that reviewers skilled in specification quality and control structure analysis would yield higher value than, say, performance or API design experts. |
| **Goals** | Two competing objectives: (1) maximize review finding diversity across the 6-reviewer ensemble, and (2) ensure expert frameworks actually fit the review target. The 14-expert roster includes specialists ranging from Kent Beck (TDD) to Gene Kim (DevOps) — most are implementation-oriented and would have poor framework fit for a protocol specification document. |
| **Options** | Alternative pairs considered (or that should have been): (a) Adzic + Leveson (chosen), (b) Adzic + Michael Nygard (Release It! — resilience patterns, relevant to the protocol's lack of degraded-mode handling), (c) Leveson + Hillel Wayne (formal methods — relevant to the protocol's unenforced constraints). Option (b) would have strengthened the architecture-adjacent perspective that was weakened by Gemini's failure. |
| **Basis** | Adzic's Specification by Example framework directly addresses the "telephone game" risk in abstract specifications — exactly the weakness of artifact format definitions without key examples. Leveson's STAMP/STPA treats protocols as control structures that can fail through open-loop feedback, stale process models, and unenforced constraints — exactly the structural risks in a 6-phase sequential pipeline. The two frameworks are complementary: Adzic catches specification ambiguity (what does "done" look like?), Leveson catches control structure gaps (what happens when a phase fails silently?). |
| **Knowledge** | The review skill's expert roster (`SKILL.md`) includes framework descriptions for each expert. Prior sessions (S15) used Fowler + Leveson, establishing that Leveson's STAMP lens is productive for protocol-type review targets. The Adzic selection was novel — this is likely the first time the SbE framework was applied in a CWF review. |
| **Experience** | A less experienced operator might have defaulted to "safe" generalist experts (e.g., Martin Fowler for architecture, Robert Martin for clean code) regardless of target type. The decision to match expert frameworks to the target document's nature — specification, not implementation — demonstrates pattern recognition about when to break from default choices. |
| **Hypothesis** | If Nygard had been selected instead of Adzic, the review would likely have produced stronger resilience/degraded-mode findings (which the Architecture fallback reviewer partially covered in S5-S6) but would have missed the "key example" and "existence-only completion criteria" concerns that were among the review's most actionable findings. The Adzic selection was likely the higher-value choice for this specific target. |
| **Tools** | The `cwf:review` skill's `--mode plan` with 6 parallel slots. Expert slots (alpha, beta) are configurable at invocation time. The roster file was the primary reference for selection. |

**Key lesson**: Expert reviewer selection should be framework-fit-driven, not reputation-driven. Match the expert's analytical framework to the review target's document type (specification vs. implementation vs. architecture) for maximum finding diversity.

---

### CDM 2: Classifying Gemini Failure as New TOOL_ERROR Category

| Probe | Analysis |
|-------|----------|
| **Cues** | Gemini CLI failed after 120s timeout. Stderr output: `Error executing tool run_shell_command: Tool "run_shell_command" not found. Did you mean one of: "search_file_content", "cli_help", "read_file"?` The error message contained two novel patterns not matching any existing classification: (1) `Tool.*not found` and (2) `Did you mean one of`. The existing error taxonomy in SKILL.md Phase 3.2 only covered CAPACITY (rate limit / quota), INTERNAL (provider internal error), and AUTH (authentication failure). |
| **Goals** | Competing objectives: (1) correctly classify the failure for the current session's confidence note, (2) improve the error taxonomy for future sessions, (3) minimize time spent on infrastructure vs. the primary review task. |
| **Options** | Three classification options were available: (a) Force-fit into CAPACITY (timeout-related, since the 120s elapsed), (b) Force-fit into INTERNAL (provider-side issue), (c) Create a new TOOL_ERROR category. Option (a) was superficially attractive because the observable symptom was a timeout, but the root cause was not capacity exhaustion — it was the CLI attempting to invoke a tool that does not exist in `-o text` mode. Option (b) was closer but still inaccurate — the error was not an internal provider malfunction but a tool resolution mismatch in the CLI's toolset configuration. |
| **Basis** | The decision to create TOOL_ERROR rather than force-fitting was driven by the error's distinct remediation path. CAPACITY errors trigger retry-with-backoff. INTERNAL errors trigger retry-then-fallback. But a tool resolution error will deterministically fail on every retry — the tool simply does not exist. The correct action is immediate fail-fast with fallback, identical to CAPACITY but for a fundamentally different reason. Collapsing distinct failure modes into a single category would make future debugging harder and could mask the 120s waste pattern. |
| **Situation Assessment** | The situation was correctly understood: Gemini CLI in `-o text` mode has a different toolset than in interactive mode. The `run_shell_command` tool exists in Gemini's interactive/agentic mode but not in the text-output mode used by the review skill. This is a static configuration mismatch, not a transient error. The 120s timeout was wasted because the existing error classification had no pattern to detect this failure mode early. |
| **Aiding** | A tool capability manifest — a pre-execution check that verifies the target CLI's available tools before dispatching work — would have prevented the 120s waste entirely. Currently, the review skill dispatches work to Gemini CLI and only discovers tool limitations when the CLI fails at runtime. A pre-flight capability check could have triggered immediate fallback. |
| **Hypothesis** | If TOOL_ERROR had not been created and the failure was classified as CAPACITY, future Gemini invocations with the same tool mismatch would continue to waste 120s per attempt before fallback. With TOOL_ERROR and its `Tool.*not found` pattern match, subsequent failures of this type can be detected from stderr within seconds rather than waiting for timeout. |
| **Time Pressure** | The primary session objective was the review synthesis. Spending time on error taxonomy was a deviation. However, the user explicitly asked for root cause analysis of the Gemini timeout, elevating this from an incidental observation to a directed investigation. Without the user's prompt, this failure might have been noted in the confidence note and forgotten. |

**Key lesson**: When a failure mode has a distinct remediation path from existing categories, it deserves its own classification — even if the observable symptom (timeout) superficially matches an existing category. Taxonomies should be organized by remediation strategy, not by symptom similarity.

---

### CDM 3: Fix Error Classification In-Session vs. Defer

| Probe | Analysis |
|-------|----------|
| **Cues** | After diagnosing the Gemini failure as a new error type, the decision point was: apply the fix to SKILL.md now, or record it in `lessons.md` and defer to a future session? The cues favoring immediate fix: (1) the fix was small and well-scoped (add one enum value, two regex patterns, one action rule), (2) the diagnosis was fresh and fully understood, (3) the session was already a "review + analysis" session with no implementation-only constraint. The cues favoring deferral: (1) the primary deliverable was the review synthesis, not skill infrastructure, (2) modifying SKILL.md during a review session could create scope creep. |
| **Goals** | (1) Deliver the review synthesis as the primary output. (2) Prevent future 120s waste on deterministic Gemini tool errors. (3) Keep session scope disciplined — the plan.md for S16 did not include SKILL.md modifications. |
| **Options** | (a) Fix now in SKILL.md, (b) Record in lessons.md only, defer fix, (c) Fix now but in a separate commit on a different branch to maintain session scope hygiene. |
| **Basis** | Option (a) was chosen. The fix was atomic (a few lines in one file), the diagnosis was complete, and the user had explicitly engaged with the root cause analysis — signaling that the fix was within session scope even if not in the original plan. Deferring (option b) risked the lesson being lost or deprioritized in future sessions, especially since `lessons.md` items are advisory, not mandatory. The separate-branch approach (option c) would have been excessive process overhead for a 5-line change. |
| **Knowledge** | The project's `AGENTS.md` states: "When executing a pre-designed plan, if actual code diverges from the plan, record the discrepancy in `lessons.md`, report it immediately, and ask for a user decision before proceeding." The user's explicit engagement with the root cause analysis served as implicit approval for the scope extension. |
| **Analogues** | This pattern — "small reactive fix during an otherwise unrelated session" — is common in the CWF project. S15's retro noted similar in-session fixes to hook scripts discovered during documentation review. The project has a pragmatic culture of "fix it when you see it" for small, well-understood changes, as opposed to strictly deferring everything outside plan scope. |
| **Experience** | A more process-rigid operator would have deferred the fix to maintain plan fidelity. A less disciplined operator might have expanded the fix scope (e.g., also adding retry logic, pre-flight tool checks, etc.). The chosen approach — minimal fix, in-session, well-documented — balanced pragmatism with discipline. |

**Key lesson**: Atomic, well-diagnosed fixes should be applied at the point of discovery when: (1) the diagnosis is complete, (2) the fix is small and self-contained, (3) the user has engaged with the problem. Deferring well-understood atomic fixes creates inventory risk — the lesson degrades over time while sitting in a backlog.

---

## Section 4: 종합 분석 및 교훈

### 세션 수준 패턴 분석

S16은 계획된 작업(리뷰 오케스트레이션)과 반응적 작업(Gemini 오류 진단 + 수정)이 공존한 세션이다. 이 두 작업 흐름의 상호작용에서 세 가지 구조적 패턴이 드러났다.

#### 패턴 1: 리뷰 대상의 성격이 전문가 선택의 가치를 결정한다

6명의 리뷰어 중 가장 높은 가치를 산출한 것은 Expert Alpha(Adzic)와 Expert Beta(Leveson)였다. Adzic는 "key example 부재"와 "existence-only 완료 기준"이라는 두 가지 high-severity 발견을, Leveson은 "open-loop corpus 검증"이라는 critical-severity 발견과 "inter-phase back-propagation 부재", "Do Not Skip 제약 미집행"이라는 두 가지 high-severity 발견을 보고했다. 반면 Security 리뷰어는 blocking concern이 전혀 없었다 — 이는 리뷰 대상이 읽기 전용 분석 프로토콜이기 때문에 당연한 결과다.

이 결과는 전문가 선택이 "누가 유명한가"가 아니라 "누구의 분석 프레임워크가 대상 문서 유형에 적합한가"에 의해 결정되어야 한다는 원칙을 확인해준다. 프로토콜 명세 문서에 TDD 전문가나 DevOps 전문가를 배치했다면, Adzic의 "telephone game" 분석이나 Leveson의 "제어 구조 결함" 분석은 등장하지 않았을 것이다.

**재사용 가능한 휴리스틱**: 리뷰 대상 문서의 유형을 먼저 분류하라 — 명세(specification), 구현(implementation), 아키텍처(architecture), 운영(operations). 그 다음 해당 유형에 가장 강한 분석 프레임워크를 가진 전문가를 선택하라.

#### 패턴 2: 오류 분류 체계는 실패 경험을 통해서만 완전해진다

SKILL.md의 기존 오류 분류는 CAPACITY, INTERNAL, AUTH 세 가지였다. 이 분류 체계는 Gemini CLI가 존재하지 않는 도구(`run_shell_command`)를 호출하여 120초간 타임아웃된 실패 모드를 포착하지 못했다. 이 실패는 기존 세 범주 어디에도 깔끔하게 맞지 않았다:

- CAPACITY가 아니다 — 용량 초과가 아니라 도구 자체가 존재하지 않는다.
- INTERNAL이 아니다 — 제공자의 내부 오류가 아니라 CLI 모드별 도구 세트 구성 차이다.
- AUTH가 아니다 — 인증 문제가 아니다.

핵심 통찰은 **오류 분류 체계를 증상 유사성이 아닌 복구 전략의 동일성**으로 조직해야 한다는 것이다. TOOL_ERROR의 복구 전략은 CAPACITY와 동일하다(즉각 폴백) — 하지만 원인이 완전히 다르기 때문에 별도 범주가 필요하다. 재시도는 무의미하다(도구가 존재하지 않으므로 결정론적으로 실패한다). 이 구분이 없으면 동일 실패가 반복될 때마다 120초가 낭비된다.

**재사용 가능한 휴리스틱**: 실패 모드의 복구 경로(retry vs. fail-fast vs. escalate)가 기존 범주와 다를 때, 새 범주를 만들어라. 증상이 비슷해 보여도 복구 경로가 다르면 별도 분류가 필요하다.

#### 패턴 3: "발견 시점 수정" vs. "백로그 등록" 판단 기준

세션 중 발견된 문제를 즉시 수정할지 아니면 `lessons.md`에 기록하고 미래 세션으로 미룰지는 반복적으로 등장하는 판단 포인트다. S16에서 즉시 수정을 선택한 조건은 세 가지였다:

1. **진단 완료**: 근본 원인이 완전히 이해되었다 (Gemini `-o text` 모드의 도구 세트에 `run_shell_command`가 없음).
2. **수정 범위 원자적**: SKILL.md에 enum 하나, 정규식 패턴 두 개, 액션 규칙 하나 추가 — 총 5줄 이내.
3. **사용자 관여**: 사용자가 타임아웃 원인을 명시적으로 질문하여 범위 확장을 암묵적으로 승인.

이 세 조건이 모두 충족되지 않으면 미루는 것이 더 안전하다. 특히 진단이 불완전한 상태에서 수정하면 부분적 해결이 되어 나중에 더 찾기 어려운 잔여 버그를 남길 수 있다.

**재사용 가능한 휴리스틱**: 세 가지 조건(진단 완료, 원자적 범위, 사용자 관여)이 모두 충족될 때만 세션 중 즉시 수정하라. 하나라도 빠지면 `lessons.md`에 기록하고 미루라.

### 리뷰어 합의도 분석

6명의 리뷰어 중 5명이 독립적으로 **Phase 0 git 명령의 scope 불완전성**을 지적했다는 사실은 주목할 만하다. 이 수준의 합의도(83%)는 해당 결함이 문서를 읽는 거의 모든 분석자에게 명백하다는 것을 의미한다. 동시에, 이는 원본 문서 작성 과정에서 자기 검증(self-review) 단계가 부재했음을 시사한다 — 다중 리뷰어를 투입하기 전에 단일 체크리스트("Hard Scope Anchor의 모든 경로가 Phase 0 명령에 포함되는가?")만으로도 이 결함을 사전에 포착할 수 있었을 것이다.

반면, Leveson의 "open-loop corpus 검증"과 Adzic의 "key example 부재"는 다른 리뷰어가 거의 포착하지 못한 전문가 고유 발견이었다. 이는 전문가 리뷰의 가치가 "모두가 보는 것을 확인해주는 것"이 아니라 "일반 리뷰어가 보지 못하는 구조적 결함을 드러내는 것"에 있음을 보여준다.

### Gemini 실패에서 배운 도구 가용성 교훈

Gemini CLI의 실패는 단순한 타임아웃이 아니라 **도구 가용성에 대한 런타임 가정 실패**였다. 현재 `cwf:review` 스킬은 Gemini CLI에 작업을 디스패치한 후, CLI가 내부적으로 어떤 도구를 사용할 수 있는지 사전에 확인하지 않는다. 이는 Leveson이 S17 handoff 문서에서 지적한 것과 정확히 같은 패턴이다 — **open-loop 제어: 컨트롤러가 명령을 보내지만 제어 대상의 실제 상태(도구 가용성)에 대한 피드백을 받지 않는다.**

이 관찰은 재귀적으로 흥미롭다: Leveson의 STPA 프레임워크가 리뷰 대상(S17 handoff)에서 발견한 제어 구조 결함이 리뷰 시스템 자체(cwf:review 스킬의 Gemini 디스패치)에도 동일하게 존재했다. 리뷰 도구가 리뷰 대상과 같은 종류의 결함을 가지고 있었다는 사실은 향후 스킬 인프라 개선 시 참고할 만한 메타 교훈이다.

### 의사결정 품질 평가

| 결정 | 품질 | 근거 |
|------|------|------|
| Expert 쌍 선택 (Adzic + Leveson) | **높음** | 프레임워크-대상 적합도가 높았고, 실제 발견 품질이 이를 입증. Expert Alpha와 Beta의 발견이 상호보완적 — Adzic는 명세 모호성, Leveson은 제어 구조 결함에 집중. |
| TOOL_ERROR 신규 범주 생성 | **높음** | 기존 범주로의 강제 분류를 거부하고 복구 경로 차이를 정확히 식별. 향후 동일 실패 발생 시 120초 낭비를 방지하는 구체적 가치. |
| 세션 내 즉시 수정 | **높음** | 세 가지 전제 조건(진단 완료, 원자적 범위, 사용자 관여)이 모두 충족된 상태에서의 판단. 수정 자체는 5줄 이내로 범위 관리가 적절. |

세 가지 핵심 결정 모두 적절했다. S16에서 의사결정 품질을 저하시킨 요인은 특별히 관찰되지 않았다. 다만, Gemini 실패가 없었다면 TOOL_ERROR 범주는 발견되지 않았을 것이며, 이는 **장애가 시스템 관찰 가능성을 개선하는 유일한 경로**인 현재 구조의 한계를 보여준다. 사전 도구 가용성 검증(pre-flight tool capability check)을 도입하면 이 의존성을 끊을 수 있다.

---

## Section 5: Actionable Recommendations

| # | Recommendation | Source Decision | Priority |
|---|---------------|-----------------|----------|
| 1 | Add pre-flight tool capability check to `cwf:review` skill's external CLI dispatch — verify available tools before sending work | CDM 2 (TOOL_ERROR diagnosis) | High |
| 2 | Document expert-target framework fit heuristic in the review skill's expert selection guidance | CDM 1 (Expert pair selection) | Medium |
| 3 | Codify the "three conditions for in-session fix" (diagnosis complete, atomic scope, user engagement) in `AGENTS.md` or `docs/project-context.md` | CDM 3 (In-session fix) | Low |
| 4 | Add self-review checklist for handoff documents: "Do all scope anchor paths appear in Phase 0 collection commands?" | Reviewer consensus finding | Medium |

---

*Analysis performed using Gary Klein's Critical Decision Method (CDM). Probes selected based on session characteristics: strategy choices (CDM 1), direction change triggered by new information (CDM 2), and trade-off resolution (CDM 3).*

<!-- AGENT_COMPLETE -->
