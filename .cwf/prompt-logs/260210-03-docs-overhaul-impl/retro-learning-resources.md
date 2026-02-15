# S32-impl Retro: Learning Resources

Session S32에서 경험한 3가지 핵심 주제에 대한 심화 학습 자료입니다.
Advanced practitioner 수준에 맞춰 선별했습니다.

---

## 1. Context Window Management in Long-Running AI Agent Sessions

S32에서 auto-compaction이 반복 발생하면서 이전 결정이 유실되고, agent가 이미 합의된 사항을 재질문하는 문제를 경험했습니다. `cwf-state.yaml`의 decisions 필드로 고수준 결정만 보존했지만, 세부 결정 보존 전략이 부족했습니다.

### Resource 1-1: Effective Context Engineering for AI Agents (Anthropic)

- **URL**: https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
- **핵심 내용**: Anthropic 공식 엔지니어링 블로그 글로, compaction을 "context window 한계에 도달한 대화를 요약하여 새 context window를 시작하는 것"으로 정의하고, 최소한의 성능 저하로 agent가 계속 동작할 수 있게 하는 high-fidelity distillation 패턴을 다룹니다. Sub-agent architecture를 통한 context isolation, file-based memory system (Sonnet 4.5 런칭과 함께 공개된 memory tool), 그리고 "가장 작은 high-signal token 집합을 찾는 것"이라는 원칙을 제시합니다.
- **S32 작업과의 관련성**: S32에서 겪은 핵심 문제 — compaction 후 결정 유실 — 에 대한 직접적인 해법을 제공합니다. 특히 file-based memory로의 전환(S32에서 `cwf-state.yaml`이 바로 이 역할)과 sub-agent를 통한 context isolation이 S32에서 이미 사용한 패턴이므로, 이 글을 통해 현재 접근법의 이론적 근거와 개선 방향을 확인할 수 있습니다.

### Resource 1-2: Escaping Context Amnesia — Practical Strategies for Long-Running AI Agents

- **URL**: https://hadijaveed.me/2025/11/26/escaping-context-amnesia-ai-agents/
- **핵심 내용**: Input Pruning, Placeholder Compression, Session Handoffs 등 실전 전략을 구체적인 구현 패턴과 함께 다룹니다. "Context Amnesia"라는 용어 자체가 S32에서 경험한 "agent가 이미 합의된 사항을 재질문하는" 현상을 정확히 지칭합니다. 단순한 요약이 아닌, 어떤 정보를 보존하고 어떤 것을 버릴지에 대한 의사결정 프레임워크를 제공합니다.
- **S32 작업과의 관련성**: `cwf-state.yaml`의 decisions 필드가 "고수준 결정만 보존"하는 현재 설계는 Session Handoffs 패턴의 일종인데, 이 글에서 다루는 Placeholder Compression 기법을 추가하면 세부 결정도 압축된 형태로 보존할 수 있습니다. "어느 순간부터 자꾸 내게 물어봐서"라는 문제에 대한 실질적 해결책을 찾을 수 있습니다.

### Resource 1-3: Two Experiments We Need to Run on AI Agent Compaction (Jason Liu)

- **URL**: https://jxnl.co/writing/2025/08/30/context-engineering-compaction/
- **핵심 내용**: Jason Liu(Instructor 라이브러리 저자)가 compaction의 본질적 한계를 실험적으로 검증하자고 제안하는 글입니다. "자동 요약이 실제로 얼마나 정보를 보존하는가"와 "compaction 횟수가 늘어날수록 정보 손실이 어떻게 누적되는가"라는 두 가지 실험을 설계합니다. Compaction을 단순한 기능이 아닌 측정 가능한 엔지니어링 문제로 프레이밍합니다.
- **S32 작업과의 관련성**: S32에서 "auto-compaction이 여러 차례 발생"하면서 결정이 유실된 것은 바로 이 누적 정보 손실 문제입니다. 이 글의 실험 프레임워크를 적용하면, cwf-state.yaml의 결정 보존 메커니즘이 compaction N회 후에도 충분히 작동하는지를 정량적으로 검증할 수 있습니다.

---

## 2. Multi-Agent Orchestration Patterns and File-Based Coordination

S32에서 4 parallel impl agents + 6 parallel reviewers를 운영하며, in-memory result에서 file persistence로 전환하고, sentinel marker(`<!-- AGENT_COMPLETE -->`) 기반 validation으로 context recovery를 구현했습니다.

### Resource 2-1: Claude Code Swarms (Addy Osmani)

- **URL**: https://addyosmani.com/blog/claude-code-agent-teams/
- **핵심 내용**: Google Chrome 팀의 Addy Osmani가 Claude Code agent teams의 아키텍처를 심층 분석한 글입니다. Conductor vs Orchestrator 패턴의 차이, 각 agent에게 narrow scope와 clean context를 부여하는 specialization 원칙, 그리고 "80% planning and review, 20% execution"이라는 비율론을 다룹니다. Subagent(결과만 반환) vs Agent Teams(상호 소통)의 트레이드오프도 명확하게 정리합니다.
- **S32 작업과의 관련성**: S32의 "4 impl + 6 reviewer" 구조가 바로 이 specialization 패턴입니다. 특히 "AGENTS.md와 persistent context를 통해 학습을 축적하는 compounding dynamic"이라는 관점은, CWF의 `cwf-state.yaml` + `lessons.md` 체계와 정확히 동일한 설계 철학입니다. File-based coordination에서 conflict 방지를 위해 "각 agent가 다른 파일 세트를 소유"해야 한다는 best practice도 S32에서 직접 적용 가능합니다.

### Resource 2-2: Learning Claude Code — From Context Engineering to Multi-Agent Workflows

- **URL**: https://medium.com/data-science-collective/learning-claude-code-from-context-engineering-to-multi-agent-workflows-4825e216403f
- **핵심 내용**: ML Engineer 관점에서 Claude Code의 context engineering과 multi-agent 패턴을 체계적으로 분석한 글입니다. 4가지 context 관리 전략(writing context의 3-tier memory hierarchy, intelligent retrieval, context compression, context isolation)을 정리하고, parallel agent 운영 시의 "orchestration tradeoff" — 코드 작성에서 "여러 구현 중 선택하기"로의 인지 부하 전환 — 을 솔직하게 다룹니다.
- **S32 작업과의 관련성**: S32에서 6명의 reviewer 결과를 1개의 synthesized verdict로 통합한 과정이 바로 이 "orchestration tradeoff"입니다. 또한 context isolation을 통해 "testing agent는 testing만, security reviewer는 security만 봐야 한다"는 원칙이 S32의 reviewer 역할 분리(internal/external CLI/domain expert)와 일치합니다. Git worktree 활용 패턴도 parallel impl agent 운영에 직접 적용할 수 있습니다.

### Resource 2-3: The Multi-Agent Playbook: 6 Agent Patterns for AI Developers

- **URL**: https://pub.towardsai.net/7-multi-agent-patterns-every-developer-needs-in-2026-and-how-to-pick-the-right-one-e8edcd99c96a
- **핵심 내용**: 2026년 기준 실전에서 검증된 6가지 multi-agent 패턴을 예제 코드와 함께 정리합니다. Sequential, Parallel, Hierarchical, Debate/Consensus, Pipeline, Self-organizing 패턴을 각각의 적용 시나리오와 함께 다루며, "어떤 패턴을 언제 선택할지"에 대한 의사결정 프레임워크를 제공합니다.
- **S32 작업과의 관련성**: S32의 review 구조(6명이 독립 리뷰 후 1개의 verdict로 합성)는 Debate/Consensus 패턴의 변형이고, impl 구조(4명이 독립 구현)는 Parallel 패턴입니다. 이 글의 패턴 분류 체계를 통해 CWF의 multi-agent 전략을 더 체계적으로 명명하고 문서화할 수 있습니다.

---

## 3. Code Review Automation with Multiple AI Models

S32에서 Codex CLI(GPT) + Gemini CLI + Claude Task agents를 동시 활용하여 6명의 reviewer가 1개의 synthesized verdict(Pass/Conditional Pass/Revise)를 생성했고, 실제로 3개의 moderate concern을 발견하여 multi-model review의 가치를 증명했습니다.

### Resource 3-1: Multi-MCP — Multi-Model Code Review and Analysis MCP Server

- **URL**: https://github.com/religa/multi_mcp
- **핵심 내용**: Claude Code CLI와 통합되는 MCP 서버로, OpenAI GPT, Anthropic Claude, Google Gemini을 병렬로 호출하여 code review와 analysis를 수행합니다. 핵심 설계: 3개 모델을 ~10초에 병렬 실행(순차 실행 시 ~30초 대비), asyncio 기반 non-blocking 아키텍처, conversation threading으로 multi-step review 시 context 유지. CLI 모델(Gemini CLI, Codex CLI, Claude CLI)을 API 모델과 함께 subprocess로 실행할 수 있는 하이브리드 아키텍처가 특징입니다.
- **S32 작업과의 관련성**: S32에서 수동으로 구성한 "Codex CLI + Gemini CLI + Claude Task" 조합을 MCP 서버로 자동화한 구현체입니다. 특히 Gemini `MODEL_CAPACITY_EXHAUSTED` 같은 graceful fallback 처리를 서버 레벨에서 해결하며, S32의 review pipeline을 재사용 가능한 인프라로 발전시킬 수 있는 직접적인 참고 구현입니다.

### Resource 3-2: AI-Powered Development Cycle with Claude Code (nakamasato, November 2025)

- **URL**: https://nakamasato.medium.com/ai-powered-development-cycle-with-claude-code-november-2025-snapshot-cc5255902ff2
- **핵심 내용**: Plan → Implement → Review 사이클에서 multi-AI review를 체계적으로 통합하는 방법론을 다룹니다. 핵심 인사이트: "여러 AI가 비슷한 제안을 하면 대부분 수정할 가치가 있다"는 multi-model consensus 원칙, ChatGPT Plus의 무제한 리뷰($20/month)와 `/gemini review`(무료)를 활용한 비용 최적화, 그리고 AI 리뷰와 자동화 도구(lint, CI)의 역할 분담 — AI는 설계 리뷰와 로직 검증, 자동화 도구는 포맷과 기본 검사 — 을 명확히 구분합니다.
- **S32 작업과의 관련성**: S32에서 "review가 실제로 3개 moderate concern을 발견하여 가치 증명"한 것이 바로 이 multi-model consensus의 실증입니다. 또한 "AI review point를 자동화할 수 없는 것으로 좁히면 AI review accuracy가 자연스럽게 향상된다"는 원칙은, CWF의 review pipeline에서 lint/CI와 AI review의 경계를 설계할 때 직접 적용할 수 있는 가이드라인입니다.

### Resource 3-3: RovoDev Code Reviewer System (Emergent Mind)

- **URL**: https://www.emergentmind.com/topics/rovodev-code-reviewer
- **핵심 내용**: 코드 리뷰 자동화 연구의 최신 landscape를 종합 정리한 페이지입니다. 특히 Atlassian의 실전 데이터가 인상적입니다: Claude 3.5 Sonnet + GPT-4o-mini + actionability filter로 구성된 zero-shot LLM pipeline에서, 자동 생성된 코멘트의 38.7%가 실제 코드 변경을 유발했고, PR cycle time이 31% 단축되었으며, human review 부담이 35.6% 감소했습니다 (Tantithamthavorn et al., 2026년 1월). RAG(Retrieval-Augmented Generation) 기반의 과거 리뷰 pair 참조(RARe), graph-based reviewer assignment 등 다양한 접근법도 정리되어 있습니다.
- **S32 작업과의 관련성**: S32의 6-reviewer → 1-verdict 구조를 정량적으로 평가할 수 있는 벤치마크를 제공합니다. Atlassian의 "38.7% actionability rate"를 기준으로 CWF review pipeline의 효과를 측정할 수 있고, "actionability filter"라는 개념을 도입하면 reviewer 출력에서 실행 가능한 제안만 필터링하여 verdict 품질을 높일 수 있습니다.

---

## Summary Table

| Topic | Resource | Type | 핵심 가치 |
|-------|----------|------|-----------|
| Context Window | Anthropic Context Engineering | 공식 엔지니어링 블로그 | Compaction + file memory + sub-agent isolation 설계 원칙 |
| Context Window | Escaping Context Amnesia | 실전 전략 글 | Input Pruning, Placeholder Compression 구체적 구현 |
| Context Window | Compaction Experiments (Jason Liu) | 실험 설계 | Compaction 누적 손실의 정량적 검증 프레임워크 |
| Multi-Agent | Claude Code Swarms (Addy Osmani) | 아키텍처 분석 | Specialization, file ownership, compounding context |
| Multi-Agent | Context Engineering to Multi-Agent | 체계적 분석 | Orchestration tradeoff, 4-tier context 관리 |
| Multi-Agent | Multi-Agent Playbook | 패턴 카탈로그 | 6가지 패턴의 선택 기준과 적용 시나리오 |
| Code Review | Multi-MCP Server | 구현 참고 | Multi-model parallel review의 MCP 기반 자동화 |
| Code Review | AI-Powered Dev Cycle | 방법론 | Multi-model consensus 원칙, AI vs CI 역할 분담 |
| Code Review | RovoDev Code Reviewer | 연구 종합 | Atlassian 정량 데이터, actionability filter 개념 |

<!-- AGENT_COMPLETE -->
