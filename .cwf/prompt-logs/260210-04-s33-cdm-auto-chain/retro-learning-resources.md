# S33 Retro: Learning Resources

Post-session research for the three core topic areas from S33 (CDM Improvements + Auto-Chaining).

---

## 1. Workflow Orchestration / Auto-Chaining

The `cwf:run` skill chains 8 CWF stages as a state machine. These resources cover agent workflow orchestration, state machine patterns for LLM pipelines, and multi-stage autonomous agent architectures.

### Resource 1.1: Anthropic — Building Effective Agents

**URL:** https://www.anthropic.com/research/building-effective-agents

**Summary:** Anthropic's canonical guide identifies five workflow patterns (prompt chaining, routing, parallelization, orchestrator-workers, evaluator-optimizer) and distinguishes them from fully autonomous agents. The key principle is "add complexity only when it demonstrably improves outcomes." Prompt chaining with programmatic verification gates between stages maps directly to the `cwf:run` architecture. The evaluator-optimizer loop (generate then review) mirrors the impl-review cycle in CWF.

**Why it matters:** The `cwf:run` skill is essentially a prompt-chaining workflow with routing (user gates) and evaluation steps (review stages). Anthropic's taxonomy validates this architecture and provides a clear vocabulary for discussing where CWF sits on the workflow-to-agent spectrum. The emphasis on "ground truth from the environment at each step" reinforces the decision journal approach.

---

### Resource 1.2: LangGraph — Multi-Agent Workflows

**URL:** https://blog.langchain.com/langgraph-multi-agent-workflows

**Summary:** LangGraph formalizes multi-agent systems as directed graphs where agents are nodes and transitions are edges, explicitly drawing the connection that "a state machine can be viewed as a labeled, directed graph." The post describes three patterns: multi-agent collaboration (shared scratchpad), agent supervisor (dedicated router), and hierarchical teams (nested sub-agents). Each agent maintains independent state while the graph controls transitions.

**Why it matters:** CWF's stage-based pipeline is a linear state graph with conditional edges (user gates). LangGraph's formalization suggests potential evolution paths: branching (e.g., parallel review tracks), hierarchical composition (nesting CWF runs), and independent scratchpads per stage. The graph-as-state-machine mental model provides a rigorous way to reason about stage transitions and error recovery.

---

### Resource 1.3: CoALA — Cognitive Architectures for Language Agents

**URL:** https://arxiv.org/abs/2309.02427

**Summary:** This Princeton/DeepMind paper (Sumers, Yao, Narasimhan, Griffiths) proposes CoALA, a framework for language agents built on three pillars: modular memory components, a structured action space for interacting with memory and environments, and a generalized decision-making process. Drawing from cognitive science and symbolic AI, it provides a taxonomy that contextualizes contemporary LLM agents within AI's broader history and outlines paths toward general-purpose language agents.

**Why it matters:** CoALA's decomposition into memory/action/decision modules maps directly onto CWF's architecture: the decision journal is a memory module, CWF stages define the action space, and the gate mechanism is the decision process. The paper's formal framework can help identify which components of the CWF pipeline are underspecified (e.g., when should the agent consult long-term memory vs. rely on context?) and where architectural improvements would yield the most leverage.

---

## 2. Context Window Management / Decision Journals

The session implemented decision journals to persist critical decisions during auto-compaction. These resources cover context engineering, decision persistence, and context window optimization.

### Resource 2.1: Simon Willison — Context Engineering

**URL:** https://simonwillison.net/2025/Jun/27/context-engineering/

**Summary:** Willison synthesizes the emerging consensus (citing Tobi Lutke and Andrej Karpathy) that "context engineering" is replacing "prompt engineering" as the more accurate term for what practitioners actually do. Karpathy's framing is key: in production systems, context engineering is "the delicate balancing act of filling the context window with optimal information" including task descriptions, few-shot examples, RAG results, tool state, history, and compaction artifacts. The work is described as "highly non-trivial" — requiring both scientific rigor and intuitive understanding.

**Why it matters:** The decision journal is a context engineering mechanism — it ensures that compaction preserves the *right* information (granular decisions) rather than just summarizing broadly. Karpathy's list of context components (task descriptions, state, history, compaction) maps precisely to what CWF injects at different phases. This validates the phase-aware injection approach: different stages need different context compositions.

---

### Resource 2.2: Lilian Weng — LLM Powered Autonomous Agents

**URL:** https://lilianweng.github.io/posts/2023-06-23-agent/

**Summary:** This comprehensive survey from OpenAI maps human memory types to computational implementations: sensory memory as embeddings, short-term memory as in-context learning (limited by transformer window), and long-term memory as external vector stores with fast retrieval. The critical insight is that short-term memory IS the context window, making its management the central bottleneck. The post catalogs planning approaches (CoT, Tree of Thoughts, LLM+P) and identifies three systemic challenges: finite context windows restricting historical integration, planning brittleness over long horizons, and interface reliability issues.

**Why it matters:** The decision journal directly addresses the "finite context window restricting historical integration" problem identified here. By selectively persisting decisions to an external store and re-injecting them after compaction, CWF implements a form of the short-term-to-long-term memory transfer that Weng identifies as critical. The planning brittleness concern reinforces why user gates exist in `cwf:run` — human checkpoints compensate for autonomous planning failures.

---

### Resource 2.3: Microsoft AutoGen — Working Memory and Ledger System

**URL:** https://www.microsoft.com/en-us/research/blog/autogen-enabling-next-gen-llm-applications-via-multi-agent-conversation/

**Summary:** AutoGen's multi-agent architecture implements a structured working memory system (ledger) that categorizes information into four types: verified facts, items requiring lookup, computationally derived facts, and educated guesses (constrained speculation to reduce hallucination). Agents follow a progression loop: evaluate completion status, assess progress, delegate next steps, and adjust strategies when stalled. The actor model decouples message delivery from processing, improving modularity.

**Why it matters:** The ledger's four-category taxonomy is directly applicable to decision journal design. Currently, the journal captures decisions as flat entries. Categorizing them (verified decisions, pending investigations, derived constraints, working assumptions) would make post-compaction recovery more precise. The "evaluate completion, assess progress, delegate, adjust" loop also maps to CWF's stage transitions and could inform how the compact recovery hook prioritizes which decisions to re-inject.

---

## 3. Error-Type Classification for External Tool Integration

The session added fail-fast error classification (CAPACITY vs INTERNAL vs AUTH) for Gemini CLI, reducing wasted time from 104s to near-immediate fallback. These resources cover graceful degradation, error classification, and circuit breaker patterns.

### Resource 3.1: Microsoft Azure — Circuit Breaker Pattern

**URL:** https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker

**Summary:** The definitive reference for the circuit breaker state machine (Closed -> Open -> Half-Open). The key insight for AI tool integration is the differentiated error handling: HTTP 429 (rate limit) should trip the circuit immediately and honor `Retry-After`; 503 (unavailable) increments failure counters; 500 (server error) may need higher thresholds. The pattern explicitly advocates returning cached/default responses rather than exceptions when the circuit is open, and notes that modern implementations can use ML to dynamically adjust thresholds based on real-time traffic patterns.

**Why it matters:** CWF's CAPACITY/INTERNAL/AUTH classification maps directly onto this pattern's error differentiation. CAPACITY errors (rate limits) should trip immediately like 429s. AUTH errors are permanent failures requiring different handling than transient ones. The Half-Open state concept suggests an improvement: after a Gemini CAPACITY error, periodically probe with a lightweight request before fully re-enabling the integration, rather than using a fixed timeout.

---

### Resource 3.2: Google SRE Book — Handling Overload

**URL:** https://sre.google/sre-book/handling-overload/

**Summary:** Google's SRE approach classifies overload into localized (retry on different backend) vs. datacenter-wide (bubble errors up without retry). The fail-fast mechanism uses client-side throttling: clients track rejection ratios and when rejections exceed thresholds, "requests above the cap fail locally without even reaching the network." Request retry budgets enforce hard limits (max 3 attempts per request, max 10% of traffic as retries). The system implements four criticality tiers (CRITICAL_PLUS through SHEDDABLE) to determine which requests to shed first.

**Why it matters:** The 104s-to-immediate improvement in CWF is exactly the client-side throttling pattern described here — failing locally instead of waiting for network timeouts. Google's criticality tiers suggest extending the error classification: not all CWF operations have equal priority. A `cwf:ship` stage failure might be SHEDDABLE (retry later), while an `impl` stage Gemini call failure is CRITICAL (needs immediate fallback). The 10% retry budget concept prevents retry storms when an external model is struggling.

---

### Resource 3.3: Marc Brooker — Retries in Distributed Systems

**URL:** https://brooker.co.za/blog/2022/02/28/retries.html

**Summary:** AWS distinguished engineer Marc Brooker analyzes four retry strategies: no retries, fixed N retries, adaptive token bucket retries, and retry circuit breakers. The token bucket approach (deposit tokens on success, consume on retry) is identified as the most balanced — it "behaves like N retries when failure rates are low, and 'some percent retries' when the failure rate is higher." The critical insight: in serverless/ephemeral architectures with many short-lived clients, local failure rate estimates diverge from true system rates, causing premature circuit breaker triggers.

**Why it matters:** CWF sessions are exactly the "short-lived client" scenario Brooker warns about — each session has limited history to estimate Gemini's true failure rate. The token bucket approach fits well: accumulate "trust tokens" for Gemini during successful calls, spend them on retries when failures occur, and fall back to local-only when tokens are depleted. This is more nuanced than the current binary CAPACITY classification and would handle intermittent degradation (slow responses, partial failures) more gracefully.

---

## Cross-Cutting Themes

Three patterns emerge across all topic areas:

1. **State machine formalism pays off.** Whether it's circuit breaker states, agent workflow stages, or memory type transitions, explicitly modeling states and transitions makes systems more debuggable, testable, and evolvable. CWF already has this implicitly; making it explicit (e.g., a formal stage transition diagram with error edges) would help.

2. **Categorization over binary decisions.** Google's four criticality tiers, AutoGen's four memory types, and the CAPACITY/INTERNAL/AUTH classification all show that binary (success/failure, remember/forget) is insufficient. Richer taxonomies enable more nuanced behavior.

3. **Local knowledge is limited.** Both Brooker's retry analysis and Weng's context window discussion highlight the same fundamental constraint: any single session/client has an incomplete view. External persistence (decision journals, token budgets, failure history) bridges this gap.

<!-- AGENT_COMPLETE -->
