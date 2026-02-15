# Section 6: Learning Resources — S15 Agent-Browser Integration

S15 세션의 핵심 주제 3가지(멀티 에이전트 오케스트레이션, 브라우저 자동화 + AI 에이전트, 프롬프트 DRY 원칙)에
맞춰 고급 소프트웨어 엔지니어 수준의 학습 자료를 선정했다.

---

## 1. AI Agent Orchestration Patterns — Azure Architecture Center

**URL**: https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns

**핵심 내용**:
Microsoft Azure Architecture Center에서 발행한 멀티 에이전트 오케스트레이션 패턴 레퍼런스.
Sequential, Concurrent, Group Chat, Handoff, Magentic의 5가지 패턴을 각각의 적용 조건, 회피 조건,
실제 예시와 함께 상세히 다룬다. 특히 Concurrent 패턴에서 "각 에이전트가 독립적으로 동일 task를
병렬 처리한 뒤 결과를 aggregation하는 구조"를 설명하며, Magentic 패턴에서는 "사전에 solution path를
알 수 없는 open-ended 문제를 task ledger를 통해 동적으로 plan을 구성"하는 접근을 제시한다.
구현 고려사항(context window 관리, 보안 경계, observability, 공통 anti-pattern)도 포괄적으로 다루고 있다.

**이 세션 작업과의 연관성**:
S15에서 다룬 CWF 프레임워크는 11개 skill, 7개 hook에 걸쳐 sub-agent를 오케스트레이션하는 구조다.
이 문서의 Sequential(cwf의 gather -> plan -> impl 파이프라인)과 Concurrent(cwf:review의 4 parallel
reviewers) 패턴이 CWF의 설계 결정과 직접 대응한다. 특히 "Implementation considerations" 섹션의
context window 관리, graceful degradation, mutable state 공유 회피 원칙은 CWF의 agent-patterns.md에
이미 반영된 패턴들과 일치하며, 아직 반영되지 않은 checkpoint/retry 메커니즘에 대한 힌트를 제공한다.
또한 "Maker-Checker Loop"(Group Chat의 특수 형태)는 cwf:review의 producer-reviewer 구조를
formalize하는 데 참고할 수 있다.

---

## 2. AgentSpawn: Adaptive Multi-Agent Collaboration Through Dynamic Spawning

**URL**: https://arxiv.org/html/2602.07072v1

**핵심 내용**:
멀티 에이전트가 동일 코드베이스를 동시 편집할 때 발생하는 충돌을 3-tier로 해결하는 연구 논문이다.
(1) 자동 머지 15% — 같은 파일이지만 겹치지 않는 라인 수정, (2) 시맨틱 머지 73% — LLM이 양쪽
diff의 의도를 분석해 reconcile, (3) 에스컬레이션 12% — 해소 불가능한 충돌은 상위 에이전트로 위임.
Lock-free optimistic concurrency 방식으로, 충돌 감지 -> line-level 분석 -> 구조적 머지 순서로
처리한다. Adaptive 측면에서는 5가지 복잡도 메트릭(파일 상호의존성, cyclomatic complexity, 테스트
실패율, 메모리 사용량, 에이전트 불확실성)을 모니터링하여 임계값(delta=0.7) 초과 시 child agent를
동적으로 spawn한다. Memory slicing(42% 축소)으로 관련 컨텍스트만 전달하는 점도 주목할 만하다.

**이 세션 작업과의 연관성**:
S15에서 정확히 이 문제를 경험했다 — 다른 에이전트가 동일 코드베이스에서 동시 작업 중
setup/SKILL.md 파일 편집 충돌이 발생했다. 현재 CWF는 이에 대한 체계적 해결책이 없으며,
에이전트 간 파일 수준 coordination은 암묵적 규칙에 의존한다. AgentSpawn의 시맨틱 머지
접근(73% 자동 해소율)은 CWF에 충돌 감지/해소 레이어를 추가할 때의 실현 가능성을 보여준다.
특히 "lock-free optimistic concurrency"는 CWF의 병렬 에이전트 구조(4 parallel reviewers)와
잘 어울리며, pessimistic locking보다 throughput을 유지하면서 충돌을 사후 해소하는 전략이
30+ 세션의 누적 경험과 부합한다.

---

## 3. The Prompt Engine MCP Server: DRY Principle for AI Prompts

**URL**: https://skywork.ai/skypage/en/prompt-engine-mcp-server-ai-engineers/1980837856862343168

**핵심 내용**:
AI 프롬프트에 DRY 원칙을 적용하는 구체적 아키텍처를 제시하는 기술 문서다. 핵심 개념은
"Partials" — 언더스코어 접두사(_role_definition.tmpl)로 명명되는 재사용 가능한 템플릿
조각이다. `{{template "partial_name" .}}` 구문으로 메인 프롬프트에 include하며,
partial을 한 곳에서 수정하면 참조하는 모든 프롬프트에 자동 전파된다. MCP(Model Context
Protocol) 서버로 구현되어 있어 Claude Desktop, VS Code 등 MCP 클라이언트에서 바로
사용 가능하다. Go template 문법 기반의 조건 분기, 변수 바인딩도 지원한다.

**이 세션 작업과의 연관성**:
S15의 핵심 작업이 바로 이것이었다 — 4개 skill(clarify, plan, retro, review)에 인라인으로
중복된 web research 규칙을 agent-patterns.md의 "Web Research Protocol" 섹션 참조로
통합하는 protocol consolidation. lessons.md에 기록된 대로, 인라인 규칙은 S14에서
agent-patterns.md가 two-tier 전략으로 업데이트되었을 때 함께 갱신되지 않아 drift가
발생했다. Prompt Engine의 partial 패턴은 CWF가 현재 "참조 경로 포함" 방식으로 해결한
문제를 더 formalize된 template include 메커니즘으로 접근한다. CWF의 SKILL.md 파일들이
agent-patterns.md를 참조하는 현재 구조는 사실상 수동 partial과 동일한 패턴이며,
향후 template 엔진 도입 시 이 MCP 서버의 설계를 참고할 수 있다.

---

*Sources discovered via Tavily search, content fetched via WebFetch (Tier A).*

<!-- AGENT_COMPLETE -->
