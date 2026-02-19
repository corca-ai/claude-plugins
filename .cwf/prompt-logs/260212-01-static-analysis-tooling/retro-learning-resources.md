## Section 6: Learning Resources

Resources calibrated to S24's technical areas -- MinHash/LSH threshold tuning, JSON Schema evolution patterns, and parallel agent orchestration reliability.

---

### 1. Locality Sensitive Hashing (LSH): The Illustrated Guide -- Pinecone

**URL**: https://www.pinecone.io/learn/series/faiss/locality-sensitive-hashing/

**Key takeaways**: This guide walks through the full three-step LSH pipeline -- k-shingling, MinHash signature generation, and banding -- with NumPy implementations and visual diagrams. The critical section for your work is the **S-curve analysis**: it shows how adjusting the number of bands `b` and rows `r` per band shifts the probability-similarity threshold curve, giving you a precise mental model for why your 0.5-to-0.7 threshold change in `find-duplicates.py` had the effect it did. The guide tests on a 4,500-sentence dataset, so the scale is comparable to a documentation corpus.

**Why it matters for your work**: You chose datasketch's `MinHashLSH(threshold=0.7)` for near-duplicate markdown detection, but the relationship between `threshold`, `num_perm`, and false-positive/false-negative rates is non-obvious. This guide provides the mathematical intuition (the S-curve) that explains exactly how banding parameters interact, so future threshold adjustments for your shingle-size and permutation-count choices can be principled rather than empirical. It also covers the tradeoff between hash computation cost and recall quality -- relevant if the doc corpus grows.

---

### 2. Evolving JSON Schemas (Creek Service, Part II) -- Andy Sherpa

**URL**: https://www.creekservice.org/articles/2024/01/09/json-schema-evolution-part-2.html

**Key takeaways**: The article introduces the **producer/consumer schema split** -- producing schemas use `additionalProperties: false` (closed content model, strict output shape) while consuming schemas use `additionalProperties: true` (open content model, tolerant of unknown fields). This maps directly onto the pattern you used in S24: `additionalProperties: true` with `required` fields creates a consuming schema that validates known structure while permitting evolution. The article formalizes three compatibility modes (backward, forward, full) and defines safe evolution rules: adding/removing optional properties is fully compatible; changing required properties or types is not.

**Why it matters for your work**: Your three schemas (`hooks.schema.json`, `cwf-state.schema.json`, `cwf-index.schema.json`) use `additionalProperties: true` + `required` -- effectively the "consuming schema" pattern from this article. The producer/consumer distinction gives you a vocabulary for explaining why this design is correct: your schemas are *consumers* of configuration data that will evolve as new hooks and state fields are added. The article also covers `patternProperties` interaction with `additionalProperties`, which is exactly what your hook-event-name regex pattern relies on. Part I of the series critiques common anti-patterns that break evolution -- worth reading to know what to avoid.

---

### 3. Multi-Agent System Reliability: Failure Patterns, Root Causes, and Production Validation Strategies -- Maxim AI

**URL**: https://www.getmaxim.ai/articles/multi-agent-system-reliability-failure-patterns-root-causes-and-production-validation-strategies/

**Key takeaways**: This article categorizes multi-agent failures into four classes: state synchronization failures (stale propagation, conflicting updates), communication protocol breakdowns (message ordering, timeout ambiguity), coordination overhead saturation (handoff latency accumulation, context reconstruction cost), and resource contention (API rate limits, connection pool exhaustion). The most directly applicable insight is that **coordination overhead grows quadratically with agent count** -- beyond a threshold, parallelization costs more than it saves. The article recommends adversarial scenario testing (injecting failures and timing perturbations) and distributed tracing to diagnose causal chains.

**Why it matters for your work**: In S24, 4 of 6 review agents exhausted turn budgets, and external CLIs (Codex, Gemini) had reliability issues. This article gives you a taxonomy for those failures: turn-budget exhaustion maps to "coordination overhead saturation," and CLI timeouts map to "communication protocol breakdowns with ambiguous retry semantics." The production validation strategies -- especially adversarial testing and cost-benefit analysis of token consumption across architectures -- are directly applicable to improving the `cwf:review` multi-agent pattern. The quadratic coordination cost insight also validates `agent-patterns.md`'s existing guidance: "A 2-agent team doing real work beats a 5-agent team where 3 wait."

**Supplementary reading**: For the classic distributed systems resilience patterns (circuit breaker, timeout, retry with exponential backoff, load shedding) that underpin these agent-level concerns, see Gergely Orosz's summary of Roberto Vitillo's *Understanding Distributed Systems* at https://blog.pragmaticengineer.com/resiliency-in-distributed-systems/. The circuit breaker state machine (closed/open/half-open) maps well onto the graceful degradation pattern already in your `agent-patterns.md` -- detect unavailable CLI, fallback to Task agent, track with provenance metadata.

<!-- AGENT_COMPLETE -->
