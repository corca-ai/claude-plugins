# CDM Analysis — Session S33 (CDM Improvements + Auto-Chaining)

Gary Klein의 Critical Decision Method를 적용하여 S33 세션의 핵심 결정 지점
4개를 분석한다. 각 결정에 대해 5-8개의 CDM 프로브를 세션 내 구체적 증거와 함께
적용한다.

---

## CDM 1: Lightweight clarify vs full cwf:clarify 워크플로우

S32-impl에서 full pipeline(clarify->plan->review->impl->review->commit)을
실행한 반면, S33에서는 2개의 AskUserQuestion 호출만으로 clarify 단계를
마무리했다. 전체 cwf:clarify multi-agent 워크플로우를 건너뛴 것이다.

| Probe | Analysis |
|-------|----------|
| **Cues** | next-session.md에 이미 4개 CDM + cwf:run + gate extraction이 구체적으로 기술되어 있었다. S32-impl retro가 4개 CDM의 근거, 대상 파일, 예상 변경 내용까지 제공했으므로 "무엇을 할지"는 명확했다. 불확실한 것은 "얼마나 할지" (Part B: design only vs full impl)와 "어떤 방식으로 할지" (CDM 3: 단순 plan.md auto-load vs decision journal)뿐이었다. |
| **Knowledge** | S32-impl에서 full cwf:clarify를 실행하면서 Explore agent 2개 + Expert agent를 spawn했는데, 그 세션에서는 scope가 넓고 모호했기 때문에 타당했다. 반면 S33의 scope는 이전 세션의 retro가 사실상 plan의 역할까지 수행하여 이미 좁혀진 상태였다. CWF의 clarify skill 자체가 "모호한 요구사항을 구체화"하는 도구이므로, 이미 구체적인 요구사항에 적용하면 overhead만 발생한다. |
| **Goals** | (a) 세션 시간 효율성 — 불필요한 multi-agent spawn 비용 회피, (b) 사용자 의도 정확 파악 — 2개 핵심 선택지에 대한 명시적 확인, (c) CWF 프로세스 일관성 — "항상 cwf:clarify부터 시작"이라는 원칙 준수. 목표 (a)와 (c)가 충돌했고, (a)가 선택되었다. |
| **Options** | (1) Full cwf:clarify (multi-agent): 2-3개 Explore agent + Expert advisor spawn, 결과 요약, 사용자 확인 — 예상 10-15분 소요, (2) **선택된 방식**: 2개 AskUserQuestion으로 핵심 결정만 확인 — 1-2분 소요, (3) Clarify 완전 생략 — next-session.md를 그대로 plan으로 사용하고 사용자 확인 없이 진행. |
| **Basis** | next-session.md의 구체성이 높아서 탐색(exploration)이 불필요했다. 남은 불확실성이 binary choice 2개로 축소되어 있었으므로, AskUserQuestion 2회가 최적의 정보 수집 방법이었다. Option 3(완전 생략)은 사용자가 "ambitious option"을 선택할 가능성을 간과하므로 위험했다 — 실제로 사용자는 두 질문 모두에서 더 야심찬 선택지를 골랐다. |
| **Experience** | 경험 많은 설계자라면 "이전 세션의 retro 품질"에 따라 clarify 깊이를 조절하는 heuristic을 갖고 있을 것이다. S32-impl retro가 CDM 분석과 함께 구체적 파일 경로, 코드 패턴까지 기술했기 때문에 lightweight clarify가 적절했다. 반면 경험이 적은 agent는 process를 기계적으로 따라 full clarify를 실행했을 것이다. |
| **Hypothesis** | Full cwf:clarify를 실행했다면: Explore agent가 이미 알려진 정보를 다시 탐색하고, Expert가 이미 retro에서 분석된 내용을 재발견하는 redundancy가 발생했을 것이다. 10-15분 + context 소비 대비 추가 정보 gain은 거의 0이었을 것이다. 반면 Option 3(완전 생략)을 택했다면: 사용자의 "full impl" 선택을 놓쳐서 scope가 축소된 결과물이 나왔을 것이다. |
| **Aiding** | Clarify 깊이 결정을 위한 heuristic을 cwf:clarify SKILL.md에 추가 가능: "prior session retro가 대상 파일, 변경 내용, BDD 기준까지 기술하고 있으면 → lightweight mode (AskUserQuestion only). Scope가 모호하거나 신규 도메인이면 → full multi-agent mode." 이 분기가 명시적이면 agent가 매번 판단할 필요 없이 조건에 따라 결정 가능하다. |

**핵심 교훈**: Clarify 깊이는 **입력의 구체성 수준에 반비례**해야 한다. 이전
세션 retro가 파일 경로 + 변경 내용 + BDD 기준까지 제공하면 AskUserQuestion
2-3회로 충분하다. **"Retro quality → clarify depth" 매핑 규칙**을 cwf:clarify에
추가하면 process overhead를 줄이면서 중요한 결정은 놓치지 않을 수 있다.

---

## CDM 2: Gate extraction 선행 (Step 0) vs CDM 순서대로 진행

Plan에서 Step 0으로 gate extraction을 CDM 1-4보다 먼저 배치했다. 이는 plan
작성 시점의 의도적 순서 결정이었고, 결과적으로 high-ROI로 판명되었다.

| Probe | Analysis |
|-------|----------|
| **Cues** | S32-impl retro에서 Ousterhout가 impl/SKILL.md의 "interface bloat"을 지적했다. 300줄 이상의 SKILL.md에 CDM 2 (cross-cutting assessment)와 CDM 3 (decision journal)을 추가하면 파일이 더 비대해질 것이 예상되었다. Gate extraction은 CDM과 직접 관련은 없지만, impl/SKILL.md의 편집 표면(edit surface)을 줄여 후속 CDM 작업의 품질을 높이는 인프라 작업이었다. |
| **Knowledge** | Lessons에 기록된 대로: "The extraction forced a clean separation of 'what' (SKILL.md pointer) from 'how' (reference file), which made subsequent CDM 2 and CDM 3 additions to impl/SKILL.md cleaner." 이 결과를 plan 시점에서 예측할 수 있었는지가 핵심이다. Ousterhout의 "deep module" 관점 — interface(SKILL.md)를 좁히고 implementation(reference)을 깊게 — 이 이미 S32 retro에서 적용된 경험이 있었으므로, plan 작성자가 이를 의식적으로 활용한 것이다. |
| **Goals** | (a) CDM 개선의 코드 품질 — 깔끔한 파일에 추가하면 결과도 깔끔, (b) 구현 속도 — Step 0 추가는 작업량 증가, (c) 커밋 독립성 — gate extraction이 별도 커밋으로 분리 가능하여 rollback이 용이. |
| **Options** | (1) **선택된 방식**: Step 0으로 gate extraction 선행 → CDM 1-4 → cwf:run, (2) CDM 1-4 먼저 → 마지막에 gate extraction — 이 경우 CDM 작업이 bloated 파일에서 진행됨, (3) Gate extraction을 CDM 2와 동시에 interleave — 한 커밋에서 extraction + CDM 2를 동시 수행, (4) Gate extraction 생략 — CDM만 수행하고 extraction은 다음 세션으로 defer. |
| **Basis** | Option 1이 선택된 구체적 이유: (a) extraction은 기능 변경 없는 순수 refactor이므로 독립 커밋으로 분리 가능, (b) 후속 CDM 작업의 diff가 작아져서 review가 쉬워짐, (c) S32 retro에서 Ousterhout가 명시적으로 권고한 항목이므로 가장 확실한 ROI. 실제 결과: `cb36c76 refactor(impl): extract Branch, Clarify, Commit gates to shared reference`가 독립 커밋으로 깔끔하게 분리되었다. |
| **Analogues** | 소프트웨어 엔지니어링의 "preparatory refactoring" 패턴 (Martin Fowler: "When you find you have to add a feature to a program, and the program's code is not structured in a convenient way to add the feature, first refactor the program to make it easy to add the feature, then add the feature.")과 정확히 일치한다. Gate extraction이 preparatory refactoring이고 CDM additions이 feature add이다. |
| **Aiding** | Impl SKILL.md에 "Preparatory Refactoring Check" 추가 가능: "대상 파일이 300줄 이상이고 여러 feature를 추가할 예정이면, 먼저 extractable 블록을 reference로 분리하라." 이 체크가 Phase 2 (Analyze & Decompose)에 있었다면 자연스럽게 Step 0가 도출되었을 것이다. |

**핵심 교훈**: 여러 변경을 하나의 파일에 적용할 때, **preparatory refactoring을
Step 0으로 배치**하면 후속 작업의 diff가 작아지고, 각 커밋의 독립성이 높아지며,
편집 중 실수가 줄어든다. **"대상 파일 300줄+ AND 3개 이상 변경 예정 → 먼저
extractable 블록 분리"** 규칙을 plan 단계에서 적용해야 한다.

---

## CDM 3: 사용자 개입 — "커밋을 적절한 단위로 하라"

사용자가 중간에 "Do commit in proper units"라고 개입한 것은, agent가 변경 사항을
한꺼번에 커밋하려 했거나 커밋 전략이 불명확했음을 시사한다. S32-impl에서 CDM 2가
바로 이 문제 — single commit vs per-work-item — 였다는 점에서, **동일 문제가
한 세션 만에 재발**한 것이다.

| Probe | Analysis |
|-------|----------|
| **Cues** | 사용자의 직접 개입: "Do commit in proper units." 이 개입 시점은 여러 CDM 수정이 완료된 후 커밋 직전이었을 것이다. Agent는 S33 plan의 Step 0-6을 순차 실행하면서 중간 커밋 없이 진행하고 있었다. S32-impl CDM 2에서 정확히 동일한 패턴 — plan에서 fine-grained commit을 명시했으나 실제로는 single commit으로 귀결 — 이 발생했었다. |
| **Knowledge** | S32-impl CDM 2의 핵심 교훈: "Commit 경계는 work item이 아니라 **변경 패턴** 기준으로 결정해야 한다." 그리고 S33의 CDM 2(impl commit strategy branching)가 바로 이 교훈을 코드화한 것이었다. 아이러니하게도, CDM 2를 구현하는 세션에서 CDM 2가 가리킨 문제가 재발했다. 이는 **교훈의 코드화와 교훈의 체화(internalization) 사이의 gap**을 보여준다. |
| **Goals** | (a) 각 변경의 reviewable한 독립 커밋 — git history의 의미적 명확성, (b) 구현 속도 — 중간 커밋은 작업 흐름을 끊음, (c) S32 CDM 2 교훈의 실천 — 자기 세션의 CDM이 자기 작업에 적용되는 self-referential 일관성. 사용자 개입 전까지 목표 (b)가 우선시되어 (a)와 (c)가 희생되고 있었다. |
| **Options** | (1) 사용자 개입 없이 단일 커밋으로 진행 (agent의 default trajectory), (2) **실제 결과**: 사용자 개입 후 7개 커밋으로 분리 — `cb36c76`(gate extraction) → `fba6549`(CDM 1) → `a586de4`(CDM 2) → `7feaba9`(CDM 3) → `3bc3480`(CDM 4) → `ce26f75`(cwf:run) → `f6696de`(artifacts), (3) Plan에서 커밋 경계를 명시적으로 지정 — Step마다 "이 Step 완료 후 커밋" 표기. |
| **Basis** | Agent가 단일 커밋으로 향하고 있던 이유: S33 plan.md에 commit 전략이 명시되지 않았다. Plan은 Steps 0-6의 구현 내용을 기술했지만, "각 Step 후 커밋하라"는 지시가 없었다. 이는 S32 CDM 2에서 지적한 바로 그 gap — plan이 commit 경계를 명시하지 않으면 agent는 default로 batched commit을 선택 — 이 반복된 것이다. |
| **Situation Assessment** | 이 결정의 가장 주목할 점은 **self-referential irony**이다. CDM 2 ("impl commit strategy branching")를 구현하는 바로 그 세션에서, 그 CDM이 해결하려는 문제가 재발했다. 새로 추가된 Phase 2.6 "Cross-Cutting Assessment"는 impl SKILL.md에 기록되었지만, 현재 세션의 agent 행동에는 즉시 적용되지 않았다. SKILL.md를 편집한다고 agent의 행동이 바뀌는 것이 아니라, SKILL.md를 **참조하면서 실행할 때** 행동이 바뀐다. |
| **Hypothesis** | Plan에 "Step별 커밋" 지시가 있었다면, 사용자 개입 없이도 7개 커밋이 자연스럽게 만들어졌을 것이다. 또는 cwf:run이 이미 존재하여 각 stage 후 자동 커밋 gate가 있었다면 — 하지만 cwf:run은 이 세션에서 만들고 있는 중이었으므로 circular dependency이다. |
| **Aiding** | Plan 템플릿에 "Commit Strategy" 섹션을 필수 항목으로 추가: "각 Step의 커밋 경계를 명시하라. 명시되지 않은 경우 Step당 1커밋을 기본으로 한다." 이 기본값이 있으면 agent가 별도 지시 없이도 적절한 단위로 커밋한다. |

**핵심 교훈**: **교훈을 코드에 기록하는 것과 현재 세션에서 실천하는 것은 별개
문제**이다. CDM을 구현하는 세션에서 해당 CDM의 문제가 재발한 것은, 교훈이 "미래
실행"에는 반영되지만 "현재 실행"에는 즉시 적용되지 않는 구조적 gap을 보여준다.
**Plan 템플릿에 "Commit Strategy" 필수 섹션**을 추가하여, 매 세션의 plan이
커밋 경계를 명시하도록 강제해야 한다.

---

## CDM 4: check-session.sh 미실행 — CLAUDE.md 규칙 위반

CLAUDE.md에 "run scripts/check-session.sh --impl. Fix all FAIL items before
finishing."이 명시되어 있음에도 실행하지 않았다. 이는 intent-result gap의 전형적
사례로, 규칙의 존재와 규칙의 실행 사이의 gap이다.

| Probe | Analysis |
|-------|----------|
| **Cues** | CLAUDE.md의 "Session State" 섹션에 명시적 지시: "After implementation, write `next-session.md`, register the session in `cwf-state.yaml`, and run `scripts/check-session.sh --impl`. Fix all FAIL items before finishing." 세션 요약에서 "check-session.sh was not run"이라고 기록된 것으로 보아, 이 누락은 세션 종료 후 발견되었다. |
| **Knowledge** | check-session.sh는 S29에서 도입된 세션 완결성 검증 스크립트로, plan.md/lessons.md/next-session.md 존재, cwf-state.yaml 업데이트 여부 등을 자동 점검한다. S32-impl에서도 이 스크립트 관련 논의가 있었으며, cwf-state.yaml의 live 섹션이 올바르게 갱신되었는지 확인하는 역할을 한다. |
| **Goals** | (a) 세션 완결성 보장 — 모든 artifact가 생성되고 state가 갱신되었는지 확인, (b) 세션 종료 속도 — check-session.sh 실행 + FAIL 수정은 추가 시간 소요, (c) CLAUDE.md 규칙 준수 — 프로젝트의 메타 규칙 체계 무결성. |
| **Options** | (1) 구현 완료 후 즉시 check-session.sh 실행 (CLAUDE.md 지시대로), (2) **실제 발생한 것**: 미실행 — 세션 종료 시점에서 누락, (3) cwf:run에 자동 check-session.sh 실행을 포함하여 human/agent 의존성 제거. |
| **Basis** | 미실행의 가장 가능성 높은 원인: (a) 7개 커밋을 순차 생성하면서 BDD verification(5/5 pass)까지 완료하고 나니, "모든 것이 끝났다"는 인지적 완료 착각(completion illusion)이 발생, (b) CLAUDE.md의 해당 규칙이 "Session State" 섹션에 있어서 구현 중에는 참조하지 않고, 세션 종료 checklist로도 작동하지 않았을 가능성, (c) BDD 5/5 pass가 강력한 "done" 신호를 주어, 추가 검증 단계가 심리적으로 불필요하게 느껴졌을 가능성. |
| **Analogues** | 항공 산업의 "checklist discipline" 문제와 정확히 동일하다. 파일럿이 경험이 많을수록 체크리스트를 생략하는 경향이 있으며, 이를 방지하기 위해 "forced function" (체크리스트를 완료하지 않으면 다음 단계로 진행 불가)을 도입한다. BDD pass = 이륙 허가로 느꼈지만, check-session.sh = 도어 클로즈 확인이 누락된 것이다. |
| **Time Pressure** | 7개 커밋 + BDD verification을 모두 완료한 세션 후반부에서, 추가 검증 스크립트 실행은 "거의 다 끝났는데 하나 더?"라는 피로감을 유발할 수 있다. 하지만 check-session.sh는 실행 시간이 수 초에 불과하므로, 실제 시간 압박이 아니라 인지적 피로(cognitive fatigue)가 원인이다. |
| **Aiding** | 두 가지 해결책: (a) cwf:run의 retro 단계 후에 check-session.sh 자동 실행을 내장 — forced function으로 작동, (b) impl SKILL.md의 마지막 Phase에 "Run check-session.sh --impl" 단계를 추가하여 agent가 구현 workflow의 일부로 실행하도록 강제. 현재 CLAUDE.md에만 기술되어 있어 "참조해야 할 문서"이지 "따라야 할 workflow step"이 아닌 것이 문제. |
| **Hypothesis** | check-session.sh를 실행했다면: next-session.md 존재 확인, cwf-state.yaml live 섹션 점검 등에서 잠재적 누락을 즉시 발견했을 것이다. 실제로 S33의 artifacts에 `next-session.md`는 포함되어 있으나, retro.md는 포함되지 않은 것으로 보이며(`artifacts: [plan.md, lessons.md]`), 이는 check-session.sh가 발견했을 누락이다. |

**핵심 교훈**: **규칙의 위치가 규칙의 실행력을 결정한다.** CLAUDE.md에 기술된
규칙은 "알아야 할 것"이지 "실행해야 할 step"이 아니다. Check-session.sh 실행을
**impl SKILL.md의 최종 Phase 또는 cwf:run의 자동 gate**로 이동시켜야 한다.
문서 속 규칙은 잊히고, 워크플로우 속 step은 실행된다.

---

## 종합 패턴

4개 결정을 관통하는 구조적 패턴이 보인다:

### 1. 적응적 프로세스 경량화의 가치와 위험

CDM 1 (lightweight clarify)은 성공적인 프로세스 경량화 사례다. 이전 retro의
품질이 높았기 때문에 full clarify가 불필요했고, 2개 질문으로 핵심 결정을
확보했다. 반면 CDM 4 (check-session.sh 미실행)는 실패한 프로세스 경량화 — agent가
"BDD pass로 충분하다"고 판단하여 최종 검증을 생략한 것이다. 둘의 차이점: CDM 1은
**명시적 판단 근거**(next-session.md의 구체성)가 있었고, CDM 4는 **암묵적 판단
근거**(BDD pass의 완료감)에 의존했다. 프로세스 경량화는 근거가 명시적일 때만
안전하다.

### 2. 교훈의 시간 지연 (Teaching-Practicing Gap)

CDM 3에서 가장 주목할 패턴: CDM 2(commit strategy branching)를 코드로 작성하는
바로 그 세션에서 CDM 2의 문제가 재발했다. 교훈을 SKILL.md에 기록하는 행위와
교훈을 현재 행동에 적용하는 행위 사이에는 **한 세션의 시간 지연**이 존재한다.
SKILL.md는 "다음 실행"에서 참조되는 것이지 "현재 편집"에서 자동 적용되는 것이
아니다. 이 gap을 줄이려면 plan 자체에 교훈이 반영된 구조 — 예를 들어 plan
템플릿의 필수 섹션으로 "Commit Strategy" 포함 — 가 필요하다.

### 3. Preparatory refactoring의 compound ROI

CDM 2 (gate extraction 선행)는 단순한 코드 정리가 아니라, 후속 4개 CDM 작업의
품질을 높이고, 7개 커밋의 독립성을 강화하고, review를 쉽게 만든 compound effect를
가졌다. Fowler의 preparatory refactoring은 이론적으로 알려져 있지만, 실제
세션에서 "먼저 정리하고 나중에 추가"를 선택하는 것은 직관에 반한다 — 당장의
진행이 늦어지기 때문이다. Step 0으로 명시적으로 배치한 것이 이 직관적 저항을
극복한 핵심이었다.

### 4. S32와 S33의 intent-result gap 비교

S32-impl에서 발견된 4개 intent-result gap 중 2개가 S33에서 재발했다:
- **Commit strategy gap**: Plan에 commit 전략 미명시 → 사용자 개입 필요
  (S32 CDM 2 → S33 CDM 3)
- **Process compliance gap**: CLAUDE.md 규칙 존재하나 실행 안 됨
  (S32의 다중 compaction 중 결정 유실 → S33의 check-session.sh 미실행)

반복되지 않은 것: cross-cutting 패턴 중복(CDM 1)은 plan에 gate가 추가되어
구조적으로 방지되었고, Gemini fail-fast(CDM 4)도 review SKILL.md에 반영되었다.
이는 **SKILL.md 수준의 구조적 수정은 효과적이지만, 관행(convention) 수준의
교훈은 반복 취약**하다는 것을 시사한다. Commit 전략과 check-session.sh 실행은
관행이었기 때문에 재발했다. 관행을 구조로 승격(plan 템플릿 필수 섹션, cwf:run
자동 gate)시키는 것이 근본 해결이다.

### 실행 항목

| # | 항목 | 대상 파일 | 근거 |
|---|------|----------|------|
| 1 | Clarify depth heuristic 추가 — retro 구체성에 따른 lightweight/full 분기 | `plugins/cwf/skills/clarify/SKILL.md` | CDM 1 |
| 2 | Plan 템플릿에 "Commit Strategy" 필수 섹션 추가 | `plugins/cwf/skills/plan/SKILL.md` | CDM 3 |
| 3 | Preparatory refactoring check 추가 — 300줄+ 파일에 3개+ 변경 시 | `plugins/cwf/skills/plan/SKILL.md` | CDM 2 |
| 4 | check-session.sh를 impl SKILL.md 최종 Phase 또는 cwf:run gate로 이동 | `plugins/cwf/skills/impl/SKILL.md` 또는 `plugins/cwf/skills/run/SKILL.md` | CDM 4 |

<!-- AGENT_COMPLETE -->
