# Concept Integrity Analysis (Holistic Axis 2)

> Date: 2026-02-16
> Skills analyzed: 12 (gather, clarify, plan, impl, retro, refactor, review, run, handoff, ship, setup, update)
> Concepts analyzed: 6 (Expert Advisor, Tier Classification, Agent Orchestration, Decision Point, Handoff, Provenance)

---

## 1. Per-Concept Implementation Consistency (2a)

### 1.1 Expert Advisor

**Composing skills**: clarify, retro, review

#### Required Behavior Check

| Requirement | clarify | retro | review |
|-------------|---------|-------|--------|
| Two domain experts with contrasting frameworks | YES | YES | YES |
| Experts evaluate independently | YES | YES | YES |
| Disagreements surface assumptions | YES (Phase 2.5 "constructive tension") | PARTIAL | PARTIAL |
| Agreements provide high-confidence signals | YES (Phase 3 classification) | NO | NO |

#### Required State Check

| Requirement | clarify | retro | review |
|-------------|---------|-------|--------|
| Expert roster (name, domain, framework, usage) | YES (reads `expert_roster` from `cwf-state.yaml`) | PARTIAL (reads deep-clarify experts, then independent; no roster read) | YES (reads `expert_roster` from `cwf-state.yaml`) |
| Expert pair assignment (alpha/beta, contrasting) | YES | YES | YES |
| Analysis output per expert | YES (persisted to `clarify-expert-alpha.md`, `clarify-expert-beta.md`) | YES (persisted to `retro-expert-alpha.md`, `retro-expert-beta.md`) | YES (persisted to `review-expert-alpha-{mode}.md`, `review-expert-beta-{mode}.md`) |

#### Required Actions Check

| Requirement | clarify | retro | review |
|-------------|---------|-------|--------|
| Select experts (match domain, ensure contrast) | YES (match against roster `domain` field, fill gaps independently) | PARTIAL (prefers deep-clarify experts, then independent; no explicit roster domain matching) | YES (match against roster `domain` field, fill gaps independently) |
| Launch parallel analysis | YES (parallel Task calls) | YES (Batch 2 parallel Task calls) | YES (Slots 5-6 parallel Task calls) |
| Synthesize tension | YES (Phase 3 integrates expert analysis into tier classification) | PARTIAL (orchestrator integrates into Section 5, but no explicit tension synthesis protocol) | PARTIAL (synthesis Phase 4 merges all reviewer outputs but has no explicit expert-tension step) |
| Update roster | NO (not mentioned in clarify) | YES (Step 7 "Expert Roster Maintenance" auto-updates) | NO (not mentioned in review) |

#### Findings

1. **INCONSISTENCY: Expert Roster Read** -- `retro` does NOT read `expert_roster` from `cwf-state.yaml` during expert selection. Its `expert-lens-guide.md` mentions "deep-clarify experts" as the primary source, then falls back to "independent selection." In contrast, `clarify` and `review` both explicitly read the roster and match by domain. This means retro experts are selected via a different path and may diverge from the shared roster.

2. **INCONSISTENCY: Expert Reference Guide** -- `clarify` and `review` both reference the shared `expert-advisor-guide.md` (`{CWF_PLUGIN_DIR}/references/expert-advisor-guide.md`). `retro` uses a skill-local `expert-lens-guide.md` instead. The shared guide itself acknowledges this at the bottom ("Retro Mode (future) -- Reserved for migration from expert-lens-guide.md"). The two guides have substantive differences:
   - `expert-advisor-guide.md` requires reading the roster and has `verified: true` skip logic for web search.
   - `expert-lens-guide.md` has no roster awareness and always requires web search.
   - Output format differences: `expert-advisor-guide.md` uses mode-specific formats (clarify format vs review format); `expert-lens-guide.md` uses its own retro-specific format with "Why this applies" field.

3. **INCONSISTENCY: Roster Update** -- Only `retro` performs expert roster maintenance (incrementing `usage_count`, adding new experts, gap analysis). Neither `clarify` nor `review` update the roster after using experts. This means the roster's `usage_count` only reflects retro usage, not clarify or review usage. This is an under-implementation of the "Update roster" required action in two of three composing skills.

4. **INCONSISTENCY: Tension Synthesis** -- `clarify` has an explicit mechanism for using expert tension (disagreements feed into T3 classification; agreements provide high-confidence signals for T1/T2). `retro` and `review` integrate expert outputs during synthesis but have no explicit protocol for surfacing where experts agree vs disagree. The concept's core value proposition ("disagreements surface assumptions") is structurally embedded only in `clarify`.

---

### 1.2 Tier Classification

**Composing skills**: clarify

#### Required Behavior Check

| Requirement | clarify |
|-------------|---------|
| Each decision classified by evidence strength | YES (Phase 3) |
| T1 (codebase): agent decides | YES |
| T2 (published consensus): agent decides with citations | YES |
| T3 (conflicting/absent/subjective): queued for human | YES |

#### Required State Check

| Requirement | clarify |
|-------------|---------|
| Decision point list | YES (Phase 1) |
| Evidence map (codebase, web, expert per point) | YES (Phases 2, 2.5) |
| Tier assignment (T1/T2/T3 with rationale) | YES (Phase 3, table output) |

#### Required Actions Check

| Requirement | clarify |
|-------------|---------|
| Decompose into decision points | YES (Phase 1) |
| Gather evidence | YES (Phases 2, 2.5) |
| Classify tier | YES (Phase 3, referencing aggregation-guide.md) |
| Auto-decide T1/T2 | YES (Phase 3) |
| Queue T3 for human | YES (Phases 3.5, 4) |

#### Findings

5. **COMPLETE IMPLEMENTATION** -- `clarify` is the sole implementor of Tier Classification and implements all required behavior, state, and actions fully. The `aggregation-guide.md` reference codifies the classification rules precisely. The three-evidence-source model (codebase, web, expert) is explicitly documented. No issues found.

---

### 1.3 Agent Orchestration

**Composing skills**: gather, clarify, plan, impl, retro, refactor, review, run

#### Required Behavior Check

| Requirement | gather | clarify | plan | impl | retro | refactor | review | run |
|-------------|--------|---------|------|------|-------|----------|--------|-----|
| Assess complexity, spawn minimum agents | PARTIAL | YES | YES | YES | YES | YES | NO (always 6) | N/A |
| Each agent has distinct work | YES | YES | YES | YES | YES | YES | YES | N/A |
| Parallel execution in batches | YES | YES | YES | YES | YES (2 batches) | YES | YES (1 batch) | N/A |
| Outputs collected, verified, synthesized | YES | YES | YES | YES | YES | YES | YES | N/A |

#### Required State Check

| Requirement | gather | clarify | plan | impl | retro | refactor | review | run |
|-------------|--------|---------|------|------|-------|----------|--------|-----|
| Work item decomposition | PARTIAL | YES | YES | YES (Phase 2) | YES | YES | YES | N/A |
| Agent team composition | PARTIAL | YES | YES | YES (Phase 2.4) | YES | YES | YES | N/A |
| Batch execution plan | NO | YES | YES | YES (Phase 2.6) | YES (2 batches) | YES | YES (1 batch) | N/A |
| Provenance metadata | NO | YES | YES | PARTIAL | YES | YES | YES | N/A |

#### Required Actions Check

| Requirement | gather | clarify | plan | impl | retro | refactor | review | run |
|-------------|--------|---------|------|------|-------|----------|--------|-----|
| Decompose into work items | PARTIAL | YES | YES | YES | YES | YES | YES | N/A |
| Size team adaptively | YES (single for focused, agent for broad) | YES | YES | YES (Phase 2.4 table) | YES (mode-based) | YES (mode-based) | NO (always 6) | N/A |
| Launch parallel batch | YES (Task tool) | YES (Task tool) | YES (Task tool) | YES (Task tool) | YES (Task tool) | YES (Task tool) | YES (Task + Bash) | N/A |
| Collect and verify | YES | YES (context recovery) | YES (context recovery) | YES (Phase 3b.4) | YES (context recovery + gates) | YES (context recovery) | YES (context recovery + gates) | N/A |
| Synthesize outputs | YES | YES (Phase 3) | YES (Phase 3) | YES (Phase 4) | YES (Step 4-5) | YES (produce report) | YES (Phase 4) | N/A |

#### Findings

6. **INCONSISTENCY: Adaptive Sizing vs Fixed Count** -- The concept requires "spawns minimum agents needed," but `review` always launches exactly 6 reviewers regardless of change size. The SKILL.md explicitly states: "Always run ALL 6 reviewers -- deliberate naivete. Never skip a reviewer because the change 'looks simple.'" This is a conscious design choice referencing `agent-patterns.md`'s "Deliberate Naivete" principle. While philosophically justified, it is technically inconsistent with the concept's "minimum agents" requirement. This is an **intentional deviation** rather than a bug. The concept definition should either accommodate "deliberate naivete" as a valid sizing strategy or `review` should be flagged as not fully composing this sub-behavior.

7. **INCONSISTENCY: `gather` Orchestration is Minimal** -- `gather` uses a single sub-agent for `--local` mode only. For URL and search modes, it calls scripts directly (no sub-agents). There is no explicit decomposition, batch plan, or provenance metadata. The `agent-patterns.md` classifies gather as "Adaptive" (broad = parallel, specific = single), but the SKILL.md only shows single-agent usage. If gather never spawns multiple agents, it may be over-marked for Agent Orchestration in the sync map.

8. **INCONSISTENCY: `run` Orchestration Model** -- `run` is marked for Agent Orchestration but operates fundamentally differently from all other orchestrating skills. It invokes skills sequentially via the Skill tool (not Task tool sub-agents). It does not decompose work into parallel items, does not size a team, and does not collect/synthesize sub-agent outputs. `run` is a **pipeline orchestrator** (sequential skill chain), not an **agent orchestrator** (parallel sub-agent coordination). The sync map's "Agent Orchestration" mark conflates two distinct orchestration patterns.

9. **INCONSISTENCY: Provenance Metadata** -- `review` has the most rigorous provenance tracking (source, tool, duration_ms, command per output, rendered in the Reviewer Provenance table). `retro` tracks persistence gates (HARD_FAIL / SOFT_CONTINUE). `plan` and `clarify` use the context recovery protocol but have no explicit provenance output table. `impl` tracks file-to-work-item mapping but not tool/duration provenance. `gather` has no provenance tracking at all. The depth and format of provenance varies significantly across skills.

10. **INCONSISTENCY: Context Recovery Protocol** -- `clarify`, `plan`, `retro`, `refactor`, and `review` all use the context recovery protocol (checking for pre-existing agent output files, skipping re-execution if valid). `gather` and `impl` do not reference the context recovery protocol. `run` does not use it directly (it delegates to child skills). This is a consistency gap for skills marked with Agent Orchestration -- the recovery protocol should be uniformly applied or the concept definition should specify when it is optional.

---

### 1.4 Decision Point

**Composing skills**: clarify, plan

#### Required Behavior Check

| Requirement | clarify | plan |
|-------------|---------|------|
| Implicit choices decomposed into concrete questions | YES (Phase 1: "Decompose into concrete decision points") | YES (Phase 1: "Key decisions to make") |
| Each point subjected to evidence | YES (Phases 2, 2.5, 3) | YES (Phase 2: parallel research) |
| No ambiguity silently resolved | YES (T3 queued for human) | PARTIAL (decisions embedded in plan synthesis, no explicit tier classification) |

#### Required State Check

| Requirement | clarify | plan |
|-------------|---------|------|
| Decision point list (question, status) | YES (Phase 1 output) | PARTIAL (Phase 1 "Key Decisions" but not formalized as a tracked list with status) |
| Evidence per point | YES (codebase + web + expert per point) | YES (prior art + codebase per decision) |
| Resolution record (decision, decided-by, evidence) | YES (Phase 5 "All Decisions" table with Decided By column) | NO (plan does not track who decided each point or at what tier) |

#### Required Actions Check

| Requirement | clarify | plan |
|-------------|---------|------|
| Extract decision points | YES | YES |
| Attach evidence | YES | YES |
| Resolve points (auto or human) | YES (explicit T1/T2/T3) | PARTIAL (research informs plan, but no explicit routing to human for unresolvable questions) |
| Record resolution with provenance | YES | NO |

#### Findings

11. **INCONSISTENCY: Decision Resolution Tracking** -- `clarify` has a full decision-point lifecycle: extract -> evidence -> classify -> auto-decide or queue -> record with provenance. `plan` extracts decisions and gathers evidence but has no tier classification, no explicit auto-decide vs human-queue routing, and no resolution record table. Plan decisions are implicitly resolved during "Phase 3: Plan Drafting" without the structured accountability that clarify provides. If plan encounters a genuinely ambiguous decision, there is no protocol to escalate it to the user.

12. **PARTIAL GAP: plan Ambiguity Handling** -- The concept requires "no ambiguity silently resolved by assumption." `plan` has no equivalent of clarify's T3 queue. If a plan decision lacks evidence, it would be resolved silently during synthesis. The "Cross-Cutting Pattern Gate" and "Preparatory Refactoring Check" are procedural, not decision-point-driven. This is a structural gap in plan's composition of the Decision Point concept.

---

### 1.5 Handoff

**Composing skills**: impl, handoff

#### Required Behavior Check

| Requirement | impl | handoff |
|-------------|------|---------|
| Session handoffs carry scope/lessons/unresolved | N/A (impl does not generate session handoffs) | YES (next-session.md with 9 sections) |
| Phase handoffs carry HOW context | YES (reads phase-handoff.md in Phase 1.1b) | YES (generates phase-handoff.md in Phase 3b) |
| Plan carries WHAT, handoff carries HOW | YES (loads plan.md + phase-handoff.md separately) | YES (explicit "Phase handoff captures HOW, not WHAT" rule) |

#### Required State Check

| Requirement | impl | handoff |
|-------------|------|---------|
| Session artifacts (plan, lessons, retro, phase-handoff) | YES (reads plan.md, lessons.md, phase-handoff.md) | YES (reads all session artifacts) |
| Unresolved items | NO (impl does not manage unresolved items) | YES (Phase 4b: three sources of unresolved items) |
| Project state (cwf-state.yaml) | PARTIAL (uses live-state but does not read session history) | YES (reads workflow, sessions, session_defaults) |

#### Required Actions Check

| Requirement | impl | handoff |
|-------------|------|---------|
| Scan artifacts for context | YES (Phase 1 loads plan + phase-handoff) | YES (Phase 1.3) |
| Propagate unresolved items | NO | YES (Phase 4b) |
| Generate handoff document | NO (impl consumes, does not generate) | YES (Phases 3, 3b) |
| Register session in state | NO | YES (Phase 4) |

#### Findings

13. **CORRECT ASYMMETRY** -- `impl` is a **consumer** of handoff artifacts while `handoff` is a **producer**. This is an appropriate asymmetric composition of the Handoff concept. `impl` correctly loads `phase-handoff.md` when present (Phase 1.1b) and treats its protocols/prohibitions as binding constraints. `handoff` correctly generates both session and phase handoff documents with full state registration.

14. **MINOR GAP: impl Does Not Propagate Lessons as Unresolved** -- When `impl` discovers learnings during execution (Phase 3a step 6, Phase 3b.3.7), it writes them to `lessons.md` but does not mark any as unresolved for propagation. The concept requires "propagate unresolved items," but this action is only relevant for the producing side (handoff), not the consuming side (impl). No corrective action needed.

---

### 1.6 Provenance

**Composing skills**: refactor

#### Required Behavior Check

| Requirement | refactor |
|-------------|----------|
| Reference documents encode assumptions about system state | PARTIAL (holistic mode reads concept-map.md which has a `Provenance:` comment noting "reviewed at 12 skills, 15 hooks (S24)") |
| Agent checks before applying | NO (no explicit staleness check is performed before applying review/holistic criteria) |
| Significant changes flagged | NO (no delta computation or flagging behavior in the SKILL.md) |

#### Required State Check

| Requirement | refactor |
|-------------|----------|
| Provenance metadata per reference | PARTIAL (concept-map.md has a provenance comment, but criteria files may not) |
| Current system state | YES (quick-scan builds inventory of current skills/hooks) |
| Staleness delta | NO (no delta computed between provenance metadata and current state) |

#### Required Actions Check

| Requirement | refactor |
|-------------|----------|
| Attach provenance to reference documents | NO (refactor does not attach or update provenance metadata) |
| Check provenance against current state | NO (no explicit check protocol) |
| Flag significant deltas | NO |
| Trigger update when staleness exceeds threshold | NO |

#### Findings

15. **SIGNIFICANT UNDER-IMPLEMENTATION** -- `refactor` is the sole implementor of Provenance, but its implementation is almost entirely absent from the SKILL.md. The concept requires active staleness detection before applying criteria documents, but refactor simply reads and applies its criteria files without checking whether the system has changed since those criteria were written. The only provenance artifact is a comment at the top of `concept-map.md` (`<!-- Provenance: reviewed at 12 skills, 15 hooks (S24). -->`), which is a passive annotation rather than an active check mechanism.

    The Provenance concept as defined requires:
    - Attaching provenance metadata (system state snapshot) to reference documents
    - Checking that metadata against current state before applying the document
    - Flagging deltas
    - Triggering updates when staleness exceeds a threshold

    None of these actions are implemented in refactor's SKILL.md workflow. The concept is **claimed in the sync map but not behaviorally implemented**.

---

## 2. Under-Synchronization Detection (2b)

Scanning for skills that exhibit concept-like behavior but are not marked as composing the concept.

### 2.1 Expert Advisor Under-Synchronization

| Skill | Exhibits expert-like behavior? | Marked? | Finding |
|--------|-------------------------------|---------|---------|
| plan | No -- uses researchers, not named experts | Not marked | Correct |
| impl | No | Not marked | Correct |
| refactor (deep review) | Agent B evaluates "Concept Integrity" using concept-map.md -- analytical but not expert-identity-based | Not marked | Correct (perspective-based, not expert-identity-based) |

**No under-synchronization detected for Expert Advisor.**

### 2.2 Tier Classification Under-Synchronization

| Skill | Routes decisions to different authorities? | Marked? | Finding |
|--------|------------------------------------------|---------|---------|
| plan | Identifies "key decisions" but does not classify them by evidence strength or route to human | Not marked | **POTENTIAL UNDER-SYNC** |
| impl | Has decision journal but decisions are all agent-level; no tier routing | Not marked | Correct |
| review | Determines verdict (Pass/Conditional Pass/Revise) based on severity -- this is verdict classification, not decision-tier routing | Not marked | Correct |

16. **POTENTIAL UNDER-SYNCHRONIZATION: plan + Tier Classification** -- `plan` identifies "key decisions" in Phase 1 and gathers evidence in Phase 2, but has no classification step. When a plan decision is ambiguous or evidence conflicts, there is no protocol to route it to the human as T3. This is exactly the scenario Tier Classification is designed for. Currently, plan silently resolves all decisions during synthesis (Phase 3). Adding Tier Classification to plan would strengthen the Decision Point implementation (finding #11) and prevent silent assumption resolution.

### 2.3 Agent Orchestration Under-Synchronization

| Skill | Parallelizes work via sub-agents? | Marked? | Finding |
|--------|----------------------------------|---------|---------|
| handoff | No sub-agents, single-context inline | Not marked | Correct |
| ship | No sub-agents, sequential `gh` commands | Not marked | Correct |
| setup | No sub-agents, sequential interactive | Not marked | Correct |
| update | No sub-agents | Not marked | Correct |

**No under-synchronization detected for Agent Orchestration.**

### 2.4 Decision Point Under-Synchronization

| Skill | Decomposes ambiguity into explicit questions? | Marked? | Finding |
|--------|----------------------------------------------|---------|---------|
| impl | Has "decision journal" tracking design choices and trade-offs | Not marked | **POTENTIAL UNDER-SYNC** |
| review | Identifies concerns but does not decompose into decision points | Not marked | Correct |
| retro | CDM analysis probes critical decision moments | Not marked | **POTENTIAL UNDER-SYNC** |

17. **POTENTIAL UNDER-SYNCHRONIZATION: impl + Decision Point** -- `impl` maintains a `decision_journal` in live-state that records design choices, deviations, and trade-offs (Phase 0 "Decision Journal"). This is structurally similar to the Decision Point concept's "resolution record." However, impl's journal is append-only during execution and lacks the upfront decomposition and evidence-gathering phases. The overlap is behavioral but incomplete -- impl records decisions post-hoc rather than decomposing ambiguity proactively. This is arguably a different pattern (decision logging vs decision routing) and may not warrant a sync mark.

18. **POTENTIAL UNDER-SYNCHRONIZATION: retro + Decision Point** -- `retro` Section 4 (CDM) explicitly "identifies 2-4 critical decision moments from the session" and applies analytical probes. This is retrospective decision analysis, not proactive decision decomposition. The purpose differs: Decision Point prevents silent assumption resolution; CDM analyzes decisions already made. The overlap in terminology (both use "decision") does not indicate concept composition. No sync mark warranted.

### 2.5 Handoff Under-Synchronization

| Skill | Preserves context across boundaries? | Marked? | Finding |
|--------|-------------------------------------|---------|---------|
| retro | Produces `retro.md` and persists findings to project-level docs (Step 7) | Not marked | Correct (persistence is not the same as handoff generation) |
| run | Tracks pipeline state and could generate completion summary | Not marked | Correct (pipeline reporting, not handoff) |
| plan | Writes `plan.md` and `lessons.md` as session artifacts | Not marked | Correct (artifact creation, not handoff generation) |

**No under-synchronization detected for Handoff.**

### 2.6 Provenance Under-Synchronization

| Skill | Checks reference staleness before applying? | Marked? | Finding |
|--------|---------------------------------------------|---------|---------|
| review | Uses `prompts.md`, `external-review.md`, `expert-advisor-guide.md` as reference criteria | Not marked | **POTENTIAL UNDER-SYNC** |
| retro | Uses `cdm-guide.md`, `expert-lens-guide.md` as reference criteria | Not marked | **POTENTIAL UNDER-SYNC** |
| clarify | Uses `aggregation-guide.md`, `questioning-guide.md`, `advisory-guide.md` as reference criteria | Not marked | **POTENTIAL UNDER-SYNC** |

19. **SYSTEMIC UNDER-SYNCHRONIZATION: Provenance is Under-Applied** -- Multiple skills rely on reference documents (guides, criteria, templates) that encode assumptions about the system. None of them check whether those references are stale before applying them. This is not unique to refactor -- it is a system-wide gap. However, since the Provenance concept is already under-implemented even in its sole composing skill (finding #15), adding marks to other skills would only amplify the gap. The correct remediation is to first implement Provenance properly in refactor, then consider extending it to skills with high-value reference dependencies.

---

## 3. Over-Synchronization / Concept Overloading Detection (2c)

### 3.1 Concept Serving Two Distinct Purposes Within One Skill

| Skill | Concept | Purpose 1 | Purpose 2 | Overloaded? |
|-------|---------|-----------|-----------|-------------|
| clarify | Agent Orchestration | Research sub-agents (Phase 2: codebase + web) | Expert sub-agents (Phase 2.5: alpha + beta) + Advisory sub-agents (Phase 3.5) | NO -- same pattern (parallel Task calls with output persistence) applied to 3 distinct batches. Each batch serves one purpose. |
| clarify | Decision Point | Decompose requirement into questions | Route questions by evidence tier | NO -- these are two actions of the same concept, not two purposes. |
| impl | Agent Orchestration | Phase 2 decomposition + sizing | Phase 3b parallel execution | NO -- planning and executing are sequential phases of the same orchestration. |
| review | Agent Orchestration | 4 core reviewers (Security, UX/DX, Correctness, Architecture) | 2 expert reviewers (alpha, beta) | BORDERLINE -- experts serve a different analytical purpose (framework-grounded analysis) than core reviewers (domain-specific review). However, all 6 are launched in one batch with the same execution pattern. Not overloaded in practice. |

**No concept overloading detected.**

### 3.2 Skill Using One Concept for Another Concept's Purpose

| Skill | Apparent Concept | Actually Serving | Misuse? |
|-------|-----------------|------------------|---------|
| run | Agent Orchestration | Pipeline sequencing (not parallel sub-agent coordination) | YES (finding #8) -- `run` uses the Agent Orchestration mark but implements sequential skill invocation, which is a fundamentally different pattern. |
| gather | Agent Orchestration | Single sub-agent delegation (--local mode only) | BORDERLINE -- a single sub-agent call is the minimal case of orchestration. The `agent-patterns.md` classifies this as "Adaptive," which is valid. |

20. **OVER-SYNCHRONIZATION: run + Agent Orchestration** -- As noted in finding #8, `run` does not spawn parallel sub-agents or decompose work into parallelizable items. It sequentially invokes skills via the Skill tool. This is pipeline orchestration, not agent orchestration. The sync map mark overstates `run`'s composition of the Agent Orchestration concept. Either the concept definition should be broadened to include sequential orchestration patterns, or `run`'s mark should be removed and a separate "Pipeline Orchestration" concept considered.

---

## 4. Prioritized Findings Summary

| # | Severity | Finding | Affected Concept | Affected Skills | Recommended Action |
|---|----------|---------|-----------------|----------------|-------------------|
| 15 | HIGH | Provenance is claimed but not behaviorally implemented | Provenance | refactor | Implement active staleness checking in refactor, or remove the sync mark until implementation exists |
| 1 | HIGH | Expert roster not read during retro expert selection | Expert Advisor | retro | Migrate retro to use `expert-advisor-guide.md` and read roster (as noted in the guide's "Retro Mode (future)" section) |
| 2 | HIGH | Two divergent expert guides (`expert-advisor-guide.md` vs `expert-lens-guide.md`) | Expert Advisor | retro | Complete the planned migration to unify expert-lens-guide.md into expert-advisor-guide.md |
| 3 | MEDIUM | Roster update only happens in retro, not in clarify or review | Expert Advisor | clarify, review | Add roster maintenance (usage_count increment, new expert addition) to clarify and review post-expert phases |
| 8 | MEDIUM | `run` is marked Agent Orchestration but uses sequential skill invocation | Agent Orchestration | run | Either remove the sync mark or define a "Pipeline Orchestration" sub-pattern |
| 11 | MEDIUM | plan lacks decision resolution tracking and tier classification | Decision Point | plan | Add lightweight tier classification to plan or document why plan decisions need not be tier-routed |
| 7 | MEDIUM | gather has minimal orchestration (single sub-agent only) | Agent Orchestration | gather | Verify whether gather ever spawns multiple agents; if not, consider downgrading the sync mark to reflect actual behavior |
| 9 | LOW | Provenance metadata depth varies widely across orchestrating skills | Agent Orchestration | gather, plan, clarify, impl | Define a minimum provenance metadata standard in agent-patterns.md |
| 4 | LOW | Expert tension synthesis exists only in clarify, not in retro or review | Expert Advisor | retro, review | Add explicit tension synthesis step to retro and review expert integration |
| 10 | LOW | Context recovery protocol not used uniformly across orchestrating skills | Agent Orchestration | gather, impl | Document when context recovery is optional vs required |
| 16 | LOW | plan could benefit from Tier Classification for ambiguous decisions | Tier Classification | plan | Consider adding to sync map after implementing in plan |
| 19 | INFO | Provenance is under-applied system-wide (multiple skills use reference docs without staleness checks) | Provenance | clarify, retro, review | Address after Provenance is properly implemented in refactor |
| 6 | INFO | review's "always 6" violates "minimum agents" but is justified by Deliberate Naivete | Agent Orchestration | review | Document as an intentional deviation in concept-map.md or agent-patterns.md |
| 13 | INFO | impl/handoff asymmetry (consumer vs producer) is correct | Handoff | impl, handoff | No action needed |

---

## 5. Structural Observations

### 5.1 Concept Maturity Spectrum

The six concepts are at very different maturity levels:

1. **Tier Classification** (MATURE) -- Single implementor (clarify), fully and rigorously implemented with dedicated reference (aggregation-guide.md). No consistency issues possible since there is only one implementation.

2. **Handoff** (MATURE) -- Two implementors with correct asymmetric roles (producer/consumer). Well-defined with dedicated protocol (plan-protocol.md).

3. **Decision Point** (DEVELOPING) -- Two implementors, but plan's implementation is significantly weaker than clarify's. The concept would benefit from a shared lightweight protocol that plan could adopt.

4. **Agent Orchestration** (WIDESPREAD but INCONSISTENT) -- Eight implementors with varying depth. The concept is too broad -- it conflates parallel sub-agent work (clarify, plan, impl, retro, refactor, review) with sequential pipeline orchestration (run) and minimal single-agent delegation (gather). A sub-taxonomy would improve clarity.

5. **Expert Advisor** (ACTIVE MIGRATION) -- Three implementors, with a known migration in progress (retro -> shared guide). The core behavioral protocol is well-defined but unevenly applied (roster management only in retro, tension synthesis only in clarify).

6. **Provenance** (NASCENT) -- Single implementor with near-zero behavioral implementation. The concept definition is clear, but the gap between definition and implementation is the largest of any concept.

### 5.2 Cross-Cutting Recommendation

The concept-map.md's provenance comment (`<!-- Provenance: reviewed at 12 skills, 15 hooks (S24). -->`) is itself an example of the Provenance concept, but ironically demonstrates the implementation gap: the comment exists but no skill actually reads or checks it. Implementing Provenance properly in refactor would be the single highest-leverage improvement, as it would catch drift in all other concepts' reference documents.

<!-- AGENT_COMPLETE -->
