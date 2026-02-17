## Section 6: Learning Resources

Resources calibrated to this session's work: shell-based hook systems with AWK/YAML manipulation, applied to AI agent safety with defense-in-depth design.

---

### Resource 1: Designing Modular Bash — Functions, Namespaces, and Library Patterns

**URL**: https://www.lost-in-it.com/posts/designing-modular-bash-functions-namespaces-library-patterns/

**Key takeaways**: This article presents a systematic approach to structuring bash code that scales. The core patterns are: (1) prefix-based namespacing (`lb_` for public API, `_lb_` for private helpers) to eliminate naming collisions when libraries are sourced together, (2) include guards using variable flags to prevent double-sourcing, and (3) configuration-by-convention where consumer scripts set variables like `LB_LOG_LEVEL` *before* sourcing the library, enabling customization without modifying library internals. The article also emphasizes `local` variable declarations in every function to prevent global namespace pollution.

**Why it matters**: The session's code review flagged ~90 lines of duplicated AWK-based YAML parsing logic across 3 files as a common-mode failure risk. This resource directly addresses the extraction of that shared logic into a sourced library with proper namespacing. The prefix convention (`cwf_yaml_` for public, `_cwf_yaml_` for internal) and include-guard pattern would eliminate the drift risk between independent parser copies. The HN discussion at https://news.ycombinator.com/item?id=33354286 adds a pragmatic counterpoint: shell's strength is embedding specialized languages (jq, awk) via pipelines rather than building complex variable-based abstractions. This aligns with the session's architecture where shell orchestrates AWK as the actual YAML processor — the library pattern should wrap AWK invocations, not replicate AWK logic in bash.

---

### Resource 2: yq — Portable Command-Line YAML Processor

**URL**: https://github.com/mikefarah/yq

**Key takeaways**: `yq` is a single Go binary (zero dependencies) that uses jq-like syntax for YAML manipulation. It supports in-place editing (`yq -i '.key = "value"' file.yaml`), environment variable interpolation via `strenv()`, multi-document YAML, and format conversion between YAML/JSON/XML/CSV. The expression language covers nested path access, array operations, `select()` filtering, and merge operations — covering every operation the session's custom AWK parsers currently perform (get, set, list-set, list-remove).

**Why it matters**: The session implemented pure-shell YAML state management using AWK because it avoided external dependencies. This was a valid constraint for a hook system that must be fast and self-contained. However, `yq` as a single static binary is comparable in deployment simplicity to requiring `awk` + `jq`. It would replace all three duplicated AWK parser implementations with one-liner expressions like `yq -i '.safety.protected-paths += ["new/path"]' state.yaml` (list-set) or `yq -i 'del(.safety.protected-paths[] | select(. == "old/path"))' state.yaml` (list-remove). The tradeoff is clear: custom AWK preserves zero-dependency purity but creates maintenance burden and drift risk; `yq` adds one binary but eliminates an entire class of parser bugs. For a safety-critical hook system, reducing parser complexity may itself be a safety improvement.

---

### Resource 3: Swiss Cheese Model for AI Safety — Multi-Layered Guardrails for FM-Based Agents

**URL**: https://arxiv.org/html/2408.02205v4 (Shamsujjoha et al., 2024, Data61/CSIRO)

**Key takeaways**: This paper applies the Swiss Cheese Model from industrial safety engineering to foundation-model-based agents. It identifies 14 quality attributes for guardrails (accuracy, safety, traceability, adaptability, etc.) and organizes them across three design dimensions: *quality attributes* (what to protect), *pipelines* (where to intercept — prompts, intermediate results, final outputs), and *artifacts* (what to guard — goals, plans, tools, memory, reasoning). The core insight matches the session's implementation: individual guardrail layers have gaps, but overlapping independent layers ensure that "gaps in one layer are often covered by another." The paper's systematic literature review of 32 papers provides a taxonomy of guardrail design options that goes well beyond ad-hoc rules.

**Why it matters**: The session's defense-in-depth implementation (automated prevention via hooks, guided detection via triage, cognitive mitigation via process rules, workflow enforcement via gates) maps directly onto this paper's multi-layered architecture. The paper provides formal vocabulary for what the session built intuitively: the `check-deletion-safety.sh` hook is a *tool artifact guardrail* operating at the *intermediate results pipeline* stage; the `workflow-gate.sh` is a *plan artifact guardrail* at the *prompt pipeline* stage. The Akira AI practical guide at https://www.akira.ai/blog/real-time-guardrails-agentic-systems complements this with implementation patterns: pre-tool policy checks (Allow/Deny/Needs-Approval trichotomy), drift detection for runtime surprises, graceful degradation to deterministic fallback modes, and HITL escalation with structured case files. Together, these resources provide both the theoretical framework and practical patterns for evolving the session's hook-based safety system into a more systematic guardrail architecture.

<!-- AGENT_COMPLETE -->
