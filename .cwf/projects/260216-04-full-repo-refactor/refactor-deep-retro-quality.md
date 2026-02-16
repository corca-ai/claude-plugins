# Deep Review: retro -- Quality + Concept (Criteria 5-8)

> Skill: `plugins/cwf/skills/retro/SKILL.md`
> Size: 3151 words, 415 lines
> Claimed concepts: Expert Advisor, Agent Orchestration
> Reviewer: quality + concept axes

---

## Criterion 5: Writing Style

### Imperative form

The skill consistently uses imperative/infinitive form throughout. "Run", "Read", "Draft", "Write", "Scan", "Filter", "Identify", "Analyze" -- all procedural steps follow the correct pattern. No instances of "You should" or passive voice in workflow instructions.

**Verdict: PASS**

### Conciseness

The skill is well-structured but has some areas of verbosity:

1. **Section 7 (Relevant Tools)** at lines 204-241 is the longest single section (~38 lines of body text). The three-step structure (Inventory / Gap analysis / Action path) is well-organized, but the "Action path by category" sub-section includes detailed discovery instructions (`/find-skills`, `/skill-creator`, prerequisite check) that read more like a reference guide than a concise procedural step. This material could move to `references/` since it applies to any skill that recommends tool gaps.

2. **Batch agent prompts** (lines 117-136) are verbose by necessity -- they embed full sub-agent instructions inline. This is justified because Task tool prompts must be self-contained (sub-agents cannot read the parent's SKILL.md). The prompts correctly include output persistence instructions and sentinel markers. No action needed.

3. **Persist Findings (Step 7)** at lines 267-310 is detailed but justified -- the eval > state > doc hierarchy is the skill's core differentiator and requires precise instructions to avoid the common failure mode of defaulting to doc-level persistence.

### Only include information the agent doesn't already know

One minor flag:

- Lines 349-366 (Output Format, Light mode template) and lines 369-387 (Deep mode template) repeat the section headings that are already described in detail in the body. This is acceptable as a format template (quick reference for assembly), not a duplication concern.

### Extraneous documentation

No extraneous files. The skill has exactly two reference files (`cdm-guide.md`, `expert-lens-guide.md`), both directly consumed by sub-agent prompts. No README, no installation guide.

**Verdict: PASS with minor note** -- Section 7 Step 3 "Action path by category" is borderline verbose for SKILL.md body; consider extracting to a reference if it grows further.

---

## Criterion 6: Degrees of Freedom

### Freedom-fragility alignment

| Area | Freedom Level | Justified? |
|------|--------------|------------|
| Mode selection (Step 3) | Medium (rules + judgment) | Yes -- clear rules for `--deep`/`--light` flags, but session-weight assessment requires judgment. Appropriate. |
| Output directory (Step 1) | Low (specific resolution order) | Yes -- directory resolution is fragile (wrong dir = artifacts land in wrong place). The 6-step resolution order with explicit edge cases (date rollover) is appropriate. |
| Evidence collection (Step 2) | Low (specific script) | Yes -- `retro-collect-evidence.sh` is deterministic. Correct to use a script. |
| Section content (Sections 1-7) | High (text guidance) | Yes -- analytical sections require contextual judgment. Free-form analysis with structural guidelines is the right approach. |
| Sub-agent prompts (Batch 1-2) | Low (specific prompt templates) | Yes -- sub-agent prompts must be precise to ensure correct output format and persistence. The inline prompt templates with sentinel markers are appropriate. |
| Persistence (Step 7) | Medium (tiered framework + judgment) | Yes -- the eval > state > doc hierarchy provides structure, but applying it to specific findings requires judgment. The per-section persist actions table bridges this well. |
| Expert roster maintenance | Low (specific procedure) | Yes -- roster updates are mechanical (increment count, add entry). Correct to specify exact procedure. |
| Live state update (Step 0) | Low (specific script) | Yes -- deterministic state transition. |
| Gate behavior (persistence gates) | Low (specific rules) | Yes -- hard fail vs soft continue is a fragile decision with clear rules. |

### Mismatches detected

**One potential mismatch:**

- **Section 3 (Waste Reduction)** describes a "Root cause drill-down (5 Whys)" methodology at high freedom (prose guidance only). The 5 Whys methodology has a specific structure (sequential "why" questions reaching a root cause classification). The current guidance describes the output categories (one-off mistake, knowledge gap, process gap, structural constraint) but not the intermediate steps. This is borderline -- the 5 Whys technique is well-known enough that an agent can execute it from the description, but a brief pseudocode or example in `references/` would reduce variance in output quality.

**Verdict: PASS** -- Freedom levels are well-calibrated across the skill. The 5 Whys gap is minor.

---

## Criterion 7: Anthropic Compliance

### Folder naming

- Plugin folder: `cwf` -- kebab-case (single word, valid). PASS.
- Skill folder: `retro` -- kebab-case (single word, valid). PASS.

### SKILL.md metadata

Frontmatter contains:
```yaml
name: retro
description: "Comprehensive session retrospective..."
```

- Only `name` and `description` present. No `allowed-tools`. PASS.
- No XML tags in frontmatter values. PASS.
- `name: retro` matches folder name `retro/`. PASS.

### Description quality

The description is:
> "Comprehensive session retrospective that turns one session's outcomes into persistent improvements. Adaptive depth: deep by default, with light mode via --light (and tiny-session auto-light). Triggers: \"cwf:retro\", \"retro\", \"retrospective\", \"\ud68c\uace0\""

Analysis:
- Length: ~220 characters. Well under 1024 limit. PASS.
- Pattern compliance:
  - **What it does**: "Comprehensive session retrospective that turns one session's outcomes into persistent improvements." PASS.
  - **When to use it**: "Triggers: cwf:retro, retro, retrospective, \ud68c\uace0." PASS.
  - **Key capabilities**: "Adaptive depth: deep by default, with light mode via --light (and tiny-session auto-light)." PASS.
- Trigger phrases included. PASS.
- Differentiation: The description distinguishes retro from other skills by emphasizing "persistent improvements" (not just analysis) and adaptive depth. Adequate.

**Verdict: PASS**

### Composability

1. **No duplication with other skills**: The retro skill's CDM analysis and expert lens are unique to this skill. The agent orchestration pattern is shared via `agent-patterns.md` reference (correct reuse, not duplication).

2. **Cross-skill references use defensive checks**:
   - Line 236: `command -v find-skills` -- explicit availability check before use. PASS.
   - Line 240: "If `find-skills` ... or `skill-creator` ... are not installed, recommend installing" -- defensive. PASS.
   - References to `cwf-state.yaml`, `plan.md`, `lessons.md` all use "if it exists" guards. PASS.

3. **Output format consumable by other skills**: `retro.md` uses structured markdown with consistent section numbering. The run-chain invocation mode (`--from-run`) produces compact output suitable for pipeline consumption. PASS.

4. **No hard dependencies**: References to `/find-skills` and `/skill-creator` are conditional suggestions, not hard requirements. The `--from-run` flag is documented as an internal context flag, not a hard coupling. PASS.

**Verdict: PASS**

---

## Criterion 8: Concept Integrity

### Synchronization map row

From `concept-map.md`:

| Skill | Expert Advisor | Tier Classification | Agent Orchestration | Decision Point | Handoff | Provenance |
|-------|:-:|:-:|:-:|:-:|:-:|:-:|
| retro | x | | x | | | |

Claimed concepts: **Expert Advisor** and **Agent Orchestration**.

---

### 8.1 Expert Advisor

#### Required Behavior

> Two domain experts with contrasting analytical frameworks evaluate independently. Disagreements surface assumptions a single perspective would miss. Agreements provide high-confidence signals.

**Implementation in retro**: Section 5 (Expert Lens) launches Expert alpha and Expert beta as parallel sub-agents (Batch 2, lines 133-136). The `expert-lens-guide.md` explicitly requires "contrasting analytical frameworks" (line 18 of guide: "select 2 well-known experts with contrasting analytical frameworks"). The guide's "Side Assignment" section explicitly states experts do NOT represent strengths vs improvements but different methodological lenses.

However, the SKILL.md does not explicitly instruct the orchestrator to **synthesize tension** between the two expert outputs. Step 4 (Deep Mode Path) says "integrate both results into Section 5" (line 138, line 192), but "integrate" is weaker than "synthesize tension" -- it could mean simply concatenating the two expert sections without surfacing agreements and disagreements.

**Gap: Synthesis of tension is implicit, not explicit.** The concept requires "Disagreements surface assumptions a single perspective would miss; Agreements provide high-confidence signals." The SKILL.md should instruct the orchestrator to add a brief synthesis paragraph after integrating both expert outputs, noting where the experts agree (high-confidence signals) and where they disagree (blind spots surfaced).

**Severity: Minor.** The expert-lens-guide's instruction to use "contrasting frameworks" means disagreements will naturally emerge in the output. But the orchestrator integration step should be explicit about synthesizing them.

#### Required State

> Expert roster (name, domain, framework, usage history), Expert pair assignment (alpha/beta, contrasting frameworks), Analysis output per expert.

- **Expert roster**: Maintained in `cwf-state.yaml` `expert_roster:` section. Step 7 (Persist Findings) includes "Expert Roster Maintenance" (lines 294-310) with full CRUD operations (increment usage_count, add new experts, gap analysis). PASS.
- **Expert pair assignment**: Alpha/beta assignment is handled by the sub-agent prompts ("You are Expert alpha" / "You are Expert beta") and the expert-lens-guide's selection priority and side assignment rules. PASS.
- **Analysis output per expert**: Persisted to `{session_dir}/retro-expert-alpha.md` and `{session_dir}/retro-expert-beta.md`. PASS.

#### Required Actions

| Action | Present? | Evidence |
|--------|----------|----------|
| Select experts (match domain, ensure contrast) | Yes | expert-lens-guide.md selection priority + deep-clarify reuse (lines 188-191) |
| Launch parallel analysis (independent evaluation) | Yes | Batch 2 launches alpha and beta in parallel Task calls (line 133) |
| Synthesize tension (surface agreements and disagreements) | Partial | "Integrate both results" (line 138) -- but no explicit tension synthesis instruction |
| Update roster (track usage, propose additions) | Yes | Expert Roster Maintenance procedure (lines 294-310) |

**Verdict: MINOR GAP** -- Tension synthesis action is present conceptually but not explicitly instructed in the orchestrator's integration step.

---

### 8.2 Agent Orchestration

#### Required Behavior

> Orchestrator assesses complexity and spawns minimum agents needed. Each agent has distinct, non-overlapping work. Parallel execution in batches (respecting dependencies). Outputs are collected, verified, and synthesized.

**Implementation in retro**:

- **Complexity assessment**: Mode selection (Step 3) determines whether sub-agents are spawned at all. Light mode = no sub-agents (inline analysis). Deep mode = 4 sub-agents in 2 batches. This is adaptive sizing: the orchestrator does not always spawn agents. PASS.
- **Distinct, non-overlapping work**: Each agent has a clearly different task: CDM Analysis, Learning Resources, Expert alpha, Expert beta. No overlap. PASS.
- **Parallel execution in batches**: Batch 1 (CDM + Learning Resources) runs in parallel, then Batch 2 (Expert alpha + beta) runs in parallel after Batch 1 completes. The dependency is explicit: "Expert Lens requires CDM results" (line 145). PASS.
- **Outputs collected, verified, synthesized**: Each agent writes to a named file with `<!-- AGENT_COMPLETE -->` sentinel. The orchestrator reads files after each batch, applies gate behavior (hard fail for CDM, soft continue for others), and integrates results. PASS.

#### Required State

| State Element | Present? | Evidence |
|--------------|----------|----------|
| Work item decomposition | Yes | 4 agents with explicit assignments (lines 103-108) |
| Agent team composition | Yes | 2 batches, 2 agents each, with rationale (line 145) |
| Batch execution plan | Yes | Batch 1 (independent: CDM + Learning), Batch 2 (dependent: experts needing CDM) |
| Provenance metadata | Partial | Sentinel markers track completion but no `source`/`tool`/`duration` metadata per agent-patterns.md |

**Gap: Provenance metadata is incomplete.** The `agent-patterns.md` reference (lines 95-101) specifies provenance tracking with `source`, `tool`, `timestamp`, `duration_ms`, and `command` fields. The retro skill tracks completion (sentinel markers) and gate status (`PERSISTENCE_GATE=HARD_FAIL` / `SOFT_CONTINUE`) but does not instruct sub-agents to include standard provenance metadata in their output files.

**Severity: Minor.** The retro skill's sub-agents are all internal Task tool agents (no external CLIs), so the provenance tracking is less critical than in `review` (which uses external CLIs). The gate behavior and sentinel markers provide adequate verification. However, for consistency with the Agent Orchestration concept's required state, provenance metadata should be included.

#### Required Actions

| Action | Present? | Evidence |
|--------|----------|----------|
| Decompose into work items | Yes | 7 sections decomposed, 4 delegated to sub-agents |
| Size team adaptively | Yes | Light mode = 0 agents, Deep mode = 4 agents in 2 batches |
| Launch parallel batch | Yes | "launch in a single message with 2 parallel Task calls" (lines 117, 133) |
| Collect and verify results | Yes | Read output files, sentinel check, bounded retry = 1 (line 115) |
| Synthesize outputs | Yes | "integrate all results into retro.md" (line 138) |

**Verdict: PASS with minor gap** on provenance metadata.

---

### 8.3 Unclaimed Concepts Check

Does retro exhibit behavior matching concepts it does not claim?

| Concept | Exhibited? | Analysis |
|---------|-----------|----------|
| Tier Classification | No | Retro does not classify decisions by evidence strength (T1/T2/T3). The eval > state > doc hierarchy in Step 7 is a *persistence* routing mechanism, not an evidence-based decision classification. Different concept. |
| Decision Point | Borderline | CDM analysis (Section 4) identifies "critical decision moments" and analyzes them with probes. This is retrospective analysis of past decisions, not the Decision Point concept's forward-looking decomposition of ambiguity into questions requiring evidence. Different purpose. |
| Handoff | No | Retro does not generate handoff documents. It produces `retro.md` as a session artifact but does not carry context to the next session (that is the handoff skill's job). |
| Provenance | No | Retro does not check staleness of reference documents before applying them. The CDM guide and expert-lens guide are used without provenance checks. This is arguably acceptable -- these guides are methodology references, not system-state-dependent documents. If they were to become stale, a provenance check would be appropriate, but currently the guides encode stable methodologies (Klein's CDM, expert analysis patterns) that do not depend on system state. |

**Verdict: No unclaimed concept gaps detected.** The eval > state > doc hierarchy and CDM analysis are distinct from Tier Classification and Decision Point respectively.

---

## Summary of Findings

| Criterion | Verdict | Issues |
|-----------|---------|--------|
| 5. Writing Style | PASS (minor note) | Section 7 Step 3 "Action path" is borderline verbose for body; monitor if it grows |
| 6. Degrees of Freedom | PASS | Freedom levels well-calibrated; 5 Whys could benefit from a brief example in references |
| 7. Anthropic Compliance | PASS | All checks clear: folder naming, metadata, description quality, composability |
| 8. Concept Integrity | PASS (2 minor gaps) | (a) Expert Advisor tension synthesis not explicitly instructed in integration step; (b) Agent Orchestration provenance metadata incomplete vs agent-patterns.md spec |

### Recommended Actions (prioritized)

1. **Add explicit tension synthesis instruction** (Criterion 8, Expert Advisor): After "integrate both results into Section 5" in Step 4 Deep Mode Path, add: "After integrating both expert analyses, add a brief synthesis paragraph surfacing key agreements (high-confidence signals) and disagreements (blind spots revealed by contrasting frameworks)."

2. **Consider provenance metadata for sub-agent outputs** (Criterion 8, Agent Orchestration): Instruct each sub-agent prompt to include minimal provenance (`tool: claude-task`, `timestamp`) in their output file header. Lower priority since all agents are internal Task tool agents.

3. **Monitor Section 7 verbosity** (Criterion 5): If the "Action path by category" sub-section grows, extract to `references/tool-gap-action-paths.md`.

<!-- AGENT_COMPLETE -->
