# Retro: S33 — CDM Improvements + Auto-Chaining

> Session date: 2026-02-10
> Mode: deep

## 1. Context Worth Remembering

- CWF 프로젝트가 "harden" 단계에 진입했으며, S14(integration test + main merge)가 marketplace-v3 브랜치의 마지막 계획 세션이다.
- CDM을 매 retro에서 체계적으로 적용하는 패턴이 확립되었다. S32 retro의 CDM 결과가 S33의 구현 범위를 결정하는 "retro → next-session → impl" 피드백 루프가 작동하고 있다.
- 12개 skills가 단일 CWF 플러그인에 통합 완료. cwf:run(auto-chaining)이 마지막으로 추가된 skill이다.
- Decision journal + phase-aware compact recovery: 구현 단계에서 결정을 cwf-state.yaml에 기록하고, auto-compaction 시 plan.md + decision journal을 자동 재주입하는 메커니즘이 확립되었다.
- Error-type classification (CAPACITY/INTERNAL/AUTH)이 review에 추가되어 Gemini CLI 실패 시 104s 대기 대신 즉시 fallback하는 fail-fast 패턴이 적용되었다.

## 2. Collaboration Preferences

- 사용자의 "Do commit in proper units" 개입은 원칙 기반 교정(principle-based correction) 스타일. 세밀한 지시가 아니라 "proper units"라는 원칙을 제시하고 agent가 구체적 분해를 수행하도록 위임한다.
- Clarify에서 AskUserQuestion 2회로 핵심 결정만 확인하는 경량화를 수용. 이전 세션 retro의 구체성이 높을수록 clarify를 간소화할 수 있다는 heuristic이 작동한다.
- 두 선택지 모두에서 "more ambitious" 옵션 선택 경향: full cwf:run implementation, decision journal mechanism.

### Suggested CLAUDE.md Updates

없음. 현재 세션의 발견 사항은 SKILL.md 구조 변경(eval/state tier)으로 해결 가능하며, CLAUDE.md(doc tier)에 추가 규칙이 필요하지 않다.

## 3. Waste Reduction

### 커밋 전략 재발 (S32 CDM 2 → S33 CDM 3)

S32에서 "per-work-item commit" 교훈을 얻었지만, S33에서 사용자 개입 전까지 동일 문제가 재발했다. CDM 2(commit strategy branching)를 **코드화하는 바로 그 세션**에서 해당 문제가 재발한 self-referential irony.

**5 Whys drill-down**:
1. 왜 batched commit으로 향했나? → Plan에 commit 전략이 명시되지 않았다
2. 왜 plan에 commit 전략이 없었나? → Plan 템플릿에 해당 필수 섹션이 없다
3. 왜 템플릿에 없나? → S32 교훈이 "관행(convention)" 수준에서 기록되었지 "구조(structure)" 수준으로 승격되지 않았다
4. 왜 승격되지 않았나? → 관행 → 구조 승격 판단 기준이 없다
5. **근본 원인**: 교훈의 "반복 취약성" 평가 없이 일률적으로 lessons.md에 기록. 반복 취약한 관행 교훈은 즉시 구조로 승격해야 한다.

**유형**: Process gap → Plan 템플릿에 "Commit Strategy" 필수 섹션 추가 (Tier 2: State)

### check-session.sh 미실행

CLAUDE.md에 "run `scripts/check-session.sh --impl`" 규칙이 명시되어 있으나 실행하지 않았다.

**5 Whys drill-down**:
1. 왜 실행하지 않았나? → BDD 5/5 pass의 "completion illusion" — 모든 검증이 끝난 것처럼 느껴짐
2. 왜 BDD pass가 완료 착각을 만드나? → BDD가 구현 검증의 마지막 단계로 인식됨
3. 왜 check-session.sh가 BDD 이후에 인식되지 않나? → CLAUDE.md에만 기술되어 impl 워크플로우의 Phase가 아님
4. 왜 Phase가 아닌가? → check-session.sh가 S29에서 도입될 때 impl SKILL.md에 통합되지 않았다
5. **근본 원인**: 규칙의 위치가 실행력을 결정한다. CLAUDE.md(doc tier)의 규칙은 "알아야 할 것"이지 "실행해야 할 step"이 아니다.

**유형**: Process gap → impl SKILL.md 최종 Phase 또는 cwf:run gate로 이동 (Tier 1: Eval/Hook)

### 잘못된 파일 경로

compact-context.sh를 session-start-compact.sh로 잘못 추정하여 Glob이 필요했다. 낭비는 경미(1 turn)하나, next-session.md에 정확한 파일 경로가 있었으므로 확인 가능했던 one-off mistake.

## 4. Critical Decision Analysis (CDM)

**CDM 1: Lightweight clarify vs full cwf:clarify**

next-session.md의 높은 구체성(파일 경로 + 변경 내용 + BDD 기준)에 근거하여 AskUserQuestion 2회로 clarify를 마무리. Full cwf:clarify의 multi-agent overhead(10-15분 + context)를 회피하면서 핵심 결정(Part B: full impl, CDM 3: decision journal)을 정확히 확보했다. 완전 생략(Option 3)은 사용자의 "more ambitious" 선택을 놓쳤을 위험이 있었다.

**핵심 교훈**: Clarify 깊이는 입력의 구체성 수준에 반비례해야 한다. "Retro quality → clarify depth" 매핑 규칙을 cwf:clarify에 추가 가능.

**CDM 2: Gate extraction 선행 (Step 0)**

Ousterhout의 interface bloat 지적에 따라 CDM 1-4보다 먼저 gate extraction을 배치. Martin Fowler의 preparatory refactoring 패턴과 일치. 후속 CDM 작업의 diff 감소, 커밋 독립성 강화, review 용이성 — compound ROI를 달성.

**핵심 교훈**: 300줄+ 파일에 3개+ 변경 예정 시, preparatory refactoring을 Step 0으로 배치하면 후속 작업의 품질이 향상된다.

**CDM 3: 사용자 개입 — "커밋을 적절한 단위로 하라"**

S32 CDM 2와 동일 문제 재발. 교훈의 코드화(SKILL.md 편집)와 체화(현재 행동 변경) 사이의 구조적 gap. Plan에 commit 전략이 명시되지 않아 agent가 default batched commit으로 향했다.

**핵심 교훈**: 교훈을 코드에 기록하는 것과 현재 세션에서 실천하는 것은 별개 문제. Plan 템플릿에 "Commit Strategy" 필수 섹션 추가로 구조적 강제 필요.

**CDM 4: check-session.sh 미실행**

CLAUDE.md 규칙이지만 impl 워크플로우의 Phase가 아니어서 BDD 5/5 pass의 completion illusion 후 누락.

**핵심 교훈**: 규칙의 위치가 실행력을 결정한다. 문서 속 규칙은 잊히고, 워크플로우 속 step은 실행된다.

**종합 패턴**:
1. 적응적 프로세스 경량화는 근거가 명시적일 때만 안전
2. Teaching-Practicing Gap: SKILL.md 기록과 현재 행동 적용 사이에 한 세션의 시간 지연
3. Preparatory refactoring의 compound ROI
4. 관행(convention) 수준의 교훈은 재발 취약, 구조(structure) 수준의 교훈은 효과적

## 5. Expert Lens

### Expert alpha: W. Edwards Deming

**Framework**: System of Profound Knowledge — 시스템 사고, common cause vs special cause variation, 프로세스에 품질 내장
**Source**: *Out of the Crisis* (MIT Press, 1986), Point 3: "Cease dependence on inspection to achieve quality"; PDCA cycle
**Why this applies**: S33의 핵심 패턴 — 관행이 반복적으로 실패하고 구조로 승격해야 효과적 — 은 Deming의 "시스템을 바꿔야 결과가 바뀐다" 철학과 정확히 일치한다.

S33에서 가장 주목할 현상은 CDM 3의 self-referential irony이다: commit strategy branching을 코드화하는 바로 그 세션에서 commit strategy 문제가 재발했다. Deming의 variation 분류로 보면, 이것은 **common cause variation**이다. Agent가 "이번에 실수했다"가 아니라, plan 템플릿에 commit strategy 섹션이 없는 시스템 구조가 매 세션마다 동일한 실패를 생산하는 것이다. Common cause에 대한 올바른 대응은 개인을 교정하는 것이 아니라 시스템을 변경하는 것 — CDM 분석의 "plan 템플릿에 Commit Strategy 필수 섹션 추가" 권고가 바로 Deming식 해법이다.

check-session.sh 미실행(CDM 4)은 Deming의 Point 3 — "검사에 의존하지 말고 품질을 프로세스에 내장하라" — 의 역설적 적용이다. check-session.sh 자체는 검사 도구이므로, Deming 관점에서 진정한 해결책은 check-session.sh를 실행하는 것이 아니라 check-session.sh가 발견하는 누락이 **구조적으로 발생할 수 없도록** 워크플로우를 설계하는 것이다. cwf:run에 자동 gate로 통합하면 검사가 프로세스의 일부가 되어, "기억해서 실행해야 하는 별도 행위"에서 "워크플로우가 자동으로 수행하는 내장 행위"로 전환된다.

CDM 1의 lightweight clarify 결정은 PDCA 성숙도를 보여준다. S32의 retro(Check)가 높은 품질로 수행되었기 때문에 S33의 clarify(Plan)를 경량화할 수 있었다. 이전 사이클의 Check 품질이 다음 사이클의 Plan 효율성을 결정하는 이 패턴은 PDCA 순환이 세션 단위로 작동하고 있음을 보여준다.

**Recommendations**:
1. **Common cause를 special cause로 착각하지 말 것**: 동일 패턴이 2회 이상 발생하면, 개인 행동 교정이 아닌 시스템 구조 변경으로 대응하라.
2. **검사를 프로세스에 내장하라**: check-session.sh를 cwf:run의 retro 후 자동 실행 gate로 이동시켜라.

### Expert beta: Chris Argyris

**Framework**: Espoused theory vs theory-in-use, single-loop vs double-loop learning, defensive routines
**Source**: *Organizational Learning: A Theory of Action Perspective* (Argyris & Schön, Addison-Wesley, 1978); "Teaching Smart People How to Learn" (*Harvard Business Review*, 1991)
**Why this applies**: S33의 teaching-practicing gap — 교훈을 SKILL.md에 기록했지만 현재 세션에서 동일 문제 재발 — 은 Argyris의 "espoused theory와 theory-in-use 사이의 괴리"와 구조적으로 동일하다.

Argyris의 핵심 구분은 사람들이 **말하는 것(espoused theory)**과 **실제로 하는 것(theory-in-use)** 사이의 체계적 괴리이다. S33에서 이 패턴이 정확히 관찰된다: SKILL.md에 "commit boundary = change pattern"이라고 기록하는 것이 espoused theory이고, 실제 세션에서 batched commit으로 향하는 것이 theory-in-use이다.

CDM 4(check-session.sh 미실행)에서 BDD 5/5 pass 후 추가 검증을 생략한 것은 **single-loop learning**의 전형이다. Single-loop에서는 현재 프레임 안에서 행동을 교정한다 ("다음에는 기억하자"). **Double-loop learning**은 프레임 자체를 변경한다 — "왜 검증이 '기억해야 할 것' 범주에 있는가? '자동으로 실행되는 것' 범주로 이동시켜야 하지 않는가?" CDM 분석의 결론이 바로 double-loop이다.

가장 흥미로운 관찰은 CWF 프로젝트 자체가 **double-loop learning 기계**를 만들고 있다는 점이다. CDM 분석 → 교훈 도출 → SKILL.md 구조 변경 → 다음 세션에서 구조가 행동을 강제 — 이 사이클이 Argyris의 Model II 조직 학습 패턴이다. eval > state > doc 계층이 governing variables를 관리하는 시스템이다.

그러나 S33이 보여주듯, double-loop도 한 세션의 latency가 있다. 교훈을 구조에 기록하는 세션과 구조가 행동을 강제하는 세션 사이에 gap이 존재한다.

**Recommendations**:
1. **Espoused theory와 theory-in-use의 괴리를 구조적으로 제거하라**: CLAUDE.md에만 존재하는 규칙(espoused)을 cwf:run gate나 SKILL.md Phase로 이동(theory-in-use)시켜라.
2. **Double-loop의 latency를 줄여라**: Plan 작성 시 최근 세션에서 추가된 SKILL.md 변경 사항을 자동 참조하는 메커니즘을 고려하라.

## 6. Learning Resources

### Workflow Orchestration / Auto-Chaining

**1.1 Anthropic — Building Effective Agents**
URL: https://www.anthropic.com/research/building-effective-agents
5가지 워크플로우 패턴(prompt chaining, routing, parallelization, orchestrator-workers, evaluator-optimizer) 분류. cwf:run은 prompt-chaining + routing(user gates) + evaluation(review stages) 조합이며, "add complexity only when it demonstrably improves outcomes" 원칙이 CWF 설계와 일치.

**1.2 LangGraph — Multi-Agent Workflows**
URL: https://blog.langchain.com/langgraph-multi-agent-workflows
State machine을 labeled directed graph로 형식화. CWF의 선형 stage pipeline에 branching, hierarchical composition, independent scratchpads 같은 진화 경로를 시사.

**1.3 CoALA — Cognitive Architectures for Language Agents**
URL: https://arxiv.org/abs/2309.02427
Memory/action/decision 모듈 분해가 CWF에 직접 매핑: decision journal = memory module, CWF stages = action space, gate mechanism = decision process.

### Context Window Management / Decision Journals

**2.1 Simon Willison — Context Engineering**
URL: https://simonwillison.net/2025/Jun/27/context-engineering/
"Context engineering"이 "prompt engineering"을 대체하는 더 정확한 용어. Decision journal은 compaction이 올바른 정보를 보존하도록 하는 context engineering 메커니즘.

**2.2 Lilian Weng — LLM Powered Autonomous Agents**
URL: https://lilianweng.github.io/posts/2023-06-23-agent/
Short-term memory = context window. Decision journal이 "finite context window restricting historical integration" 문제를 직접 해결. User gates는 planning brittleness에 대한 human checkpoint.

**2.3 Microsoft AutoGen — Working Memory and Ledger System**
URL: https://www.microsoft.com/en-us/research/blog/autogen-enabling-next-gen-llm-applications-via-multi-agent-conversation/
4가지 정보 유형 분류(verified facts, items requiring lookup, derived facts, educated guesses). Decision journal의 flat 구조를 이 분류로 확장하면 post-compaction recovery의 정밀도 향상 가능.

### Error-Type Classification

**3.1 Microsoft Azure — Circuit Breaker Pattern**
URL: https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
Closed → Open → Half-Open 상태 머신. CAPACITY/INTERNAL/AUTH 분류가 circuit breaker의 error differentiation과 직접 매핑.

**3.2 Google SRE Book — Handling Overload**
URL: https://sre.google/sre-book/handling-overload/
Client-side throttling: 104s → 즉시 fallback 개선이 이 패턴의 정확한 구현. Criticality tiers 개념이 CWF 단계별 에러 중요도 분류에 적용 가능.

**3.3 Marc Brooker — Retries in Distributed Systems**
URL: https://brooker.co.za/blog/2022/02/28/retries.html
Token bucket retry 전략. CWF 세션이 "short-lived client"이므로 local failure rate 추정이 부정확할 수 있음을 경고. Trust token 축적 패턴 적용 가능.

## 7. Relevant Skills

### Installed Skills

CWF 12개 skills + plugin-deploy 1개가 설치되어 있다.

**이 세션에서 활용된 skills**:
- `cwf:impl` — 7개 커밋의 순차 구현 수행 (직접 실행, not via cwf:run)
- `cwf:retro` — 현재 실행 중인 deep retro
- `cwf:plan` — plan.md 작성 (lightweight mode)

**활용할 수 있었으나 사용하지 않은 skills**:
- `cwf:review` — CDM 구현 후 코드 리뷰를 실행했으면 markdownlint 이슈(review/SKILL.md의 MD029)를 commit 전에 발견할 수 있었다. 다만 7개 커밋 각각에 review를 실행하는 것은 overhead가 크므로, 최종 커밋 후 1회 실행이 적절했을 것이다.
- `cwf:run` — 이 세션에서 cwf:run을 구현했으므로 circular dependency. 다음 세션(S14)에서 첫 실전 사용 예정.
- `cwf:refactor --commit` — gate extraction(Step 0)에서 commit-based tidying을 활용할 수 있었으나, 수동 refactor가 더 정밀했다.

### Skill Gaps

- **check-session integration**: check-session.sh 실행이 cwf:run이나 impl에 자동 통합되면 CDM 4 문제가 구조적으로 해결된다. 별도 skill이 아닌 cwf:run gate로 추가하는 것이 적절.
- 추가적인 skill gap은 식별되지 않았다. CWF 12개 skills가 현재 워크플로우의 모든 단계를 커버하고 있으며, cwf:run이 추가됨으로써 파이프라인 자동화까지 완성되었다.
