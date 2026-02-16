# Deep Review: clarify

**Skill**: `plugins/cwf/skills/clarify`
**Review type**: Combined STRUCTURAL + QUALITY
**Concepts composed**: Expert Advisor, Tier Classification, Agent Orchestration, Decision Point (4 of 6 -- densest row in the synchronization map)

---

## Criterion 1: SKILL.md Size

| Metric | Value | Threshold | Verdict |
|--------|-------|-----------|---------|
| Word count | 2,072 | 3,000 (warning) / 5,000 (error) | PASS |
| Line count | 448 | 500 (warning) | PASS |

**Assessment**: Comfortably within limits. Despite composing four concepts and containing two full modes (default + light), the skill stays lean. Sub-agent prompts contribute meaningful word count but are irreducible procedural content.

**Finding**: No issues.

---

## Criterion 2: Progressive Disclosure Compliance

### Metadata (frontmatter)

- `name`: "clarify" -- matches folder name. PASS.
- `description`: 291 characters. Contains what it does ("Unified requirement clarification..."), when to trigger ("cwf:clarify", "clarify this", "refine requirements"), and key capabilities (research-first vs --light). PASS.
- No extra frontmatter fields. PASS.
- No XML tags in frontmatter values. PASS.

### Body

- No "When to Use This Skill" section in body (trigger info is correctly in description). PASS.
- Sub-agent prompt blocks are in YAML code fences -- these are procedural workflow steps, not reference material. Acceptable in body.
- Tier classification definitions (lines 217-219) provide brief inline summaries with a pointer to `aggregation-guide.md` for full rules. Acceptable progressive disclosure.

### Bundled resources

All four reference files are loaded on demand via explicit read instructions in the workflow phases:
- `aggregation-guide.md` -- loaded in Phase 3
- `advisory-guide.md` -- loaded in Phase 3.5 sub-agent prompts
- `questioning-guide.md` -- loaded in Phases 4 and --light Phase 2
- `research-guide.md` -- listed in References section (fallback path)

External shared references loaded on demand:
- `../../references/expert-advisor-guide.md` -- loaded in Phase 2.5 sub-agent prompts
- `../../references/context-recovery-protocol.md` -- loaded in Phases 2, 2.5, 3.5
- `{CWF_PLUGIN_DIR}/references/agent-patterns.md` -- loaded in web researcher sub-agent prompt

**Finding**: No issues. Three-level hierarchy is well-maintained.

---

## Criterion 3: Duplication Check

### Tier classification (SKILL.md vs aggregation-guide.md)

SKILL.md lines 217-219 provide a 3-line summary of T1/T2/T3 classification. `aggregation-guide.md` provides full rules with detailed conditions, conflict handling, and output format. The SKILL.md version is a necessary inline summary for the orchestrator's workflow -- it tells the agent *what* to do at a glance, while the reference file tells *how* in detail.

**Verdict**: Acceptable summary/pointer pattern. Not duplication.

### Why-digging (SKILL.md vs questioning-guide.md)

SKILL.md references "Why-dig 2-3 times" (line 315) and "why-dig on surface-level answers" (line 388, 436). These are brief action references, not methodology. The full methodology lives in `questioning-guide.md`.

**Verdict**: Acceptable. Brief verb references, not duplicated content.

### Expert selection (SKILL.md vs expert-advisor-guide.md)

SKILL.md lines 146-149 describe expert selection in 4 numbered steps. `expert-advisor-guide.md` lines 22-28 describe the same process in 4 nearly identical numbered steps.

**Verdict**: MINOR DUPLICATION. The expert selection steps in SKILL.md (lines 146-149) closely mirror the "Expert Selection" section in `expert-advisor-guide.md` (lines 22-28). Since the sub-agent prompt already instructs "Read {CWF_PLUGIN_DIR}/references/expert-advisor-guide.md", the orchestrator could instead note "Select 2 experts per expert-advisor-guide.md selection rules" and omit the 4-step inline procedure. However, the orchestrator (not the sub-agent) performs expert selection, so having the steps inline is defensible -- the orchestrator does not read the guide itself; it tells the sub-agents to read it. Severity: low.

### Advisory side-assignment (SKILL.md vs advisory-guide.md)

SKILL.md does not duplicate side-assignment rules. It defers to "per the guide's side-assignment rules" in the sub-agent prompts. PASS.

**Overall duplication assessment**: One minor instance (expert selection steps). No significant duplication.

---

## Criterion 4: Resource Health

### File quality

| File | Words | Lines | Needs ToC? | Needs grep patterns? |
|------|-------|-------|------------|---------------------|
| research-guide.md | 538 | 103 | YES (>100 lines) | No (<10k words) |
| aggregation-guide.md | 453 | 84 | No | No |
| advisory-guide.md | 316 | 50 | No | No |
| questioning-guide.md | 863 | 147 | YES (>100 lines) | No (<10k words) |

**Finding F4-1** (warning): `research-guide.md` (103 lines) and `questioning-guide.md` (147 lines) exceed 100 lines but lack a table of contents. Both would benefit from a ToC header listing their sections.

### Unused resources

All files in `references/` are referenced in SKILL.md:
- `research-guide.md` -- line 444
- `aggregation-guide.md` -- lines 213, 445
- `advisory-guide.md` -- lines 261, 285, 446
- `questioning-guide.md` -- lines 305, 380, 447

No `scripts/` directory exists for this skill. No `assets/` directory exists. No unused resources.

### Deeply nested references

Reference files do not reference other reference files. One level deep from SKILL.md. PASS.

**Overall resource health**: One warning (missing ToC in 2 files). No errors.

---

## Criterion 5: Writing Style

- Imperative form used consistently: "Record the original requirement", "Decompose into concrete decision points", "Present the classification", "Read {SKILL_DIR}/references/...". PASS.
- No extraneous documentation files. PASS.
- Concise examples: output format templates use placeholder syntax (`{...}`) rather than verbose prose. PASS.
- No information the agent already knows being restated unnecessarily. PASS.

**Finding F5-1** (nit): The sentence "This state is what `cwf:impl` Phase 1.0 checks as a pre-condition" (lines 358, 424) appears twice verbatim -- once in default mode and once in --light mode. This is acceptable given the two modes are independent reading paths, but could be a single note in the Rules section to avoid repetition across modes.

**Overall writing style**: Clean. No issues beyond a minor repetition across modes.

---

## Criterion 6: Degrees of Freedom

| Component | Freedom Level | Appropriate? |
|-----------|--------------|--------------|
| Phase 0: live-state update | Low (specific script commands) | YES -- fragile state management, exact commands needed |
| Phase 1: Capture & Decompose | High (text guidance) | YES -- creative decomposition, context-dependent |
| Phase 2: Research sub-agents | Medium (parameterized prompts) | YES -- prompt templates with decision-point injection |
| Phase 2.5: Expert Analysis | Medium (parameterized prompts) | YES -- same pattern as Phase 2 |
| Phase 3: Classify & Decide | Medium (inline summary + reference) | YES -- rules in reference, orchestrator applies |
| Phase 3.5: Advisory | Medium (parameterized prompts) | YES -- consistent with other sub-agent phases |
| Phase 4: Persistent Questioning | High (methodology reference) | YES -- human interaction is inherently variable |
| Phase 5: Output | Low (specific template) | YES -- output format must be consistent for downstream consumers |
| Completion tracking | Low (specific script commands) | YES -- fragile state management |
| Mode Selection heuristic | High (text guidance) | YES -- judgment call, context-dependent |

**Finding**: No mismatches. Freedom levels are well-calibrated throughout. Fragile operations (state scripts, output format) are low-freedom. Creative operations (decomposition, questioning) are high-freedom. Sub-agent prompts are medium-freedom templates.

---

## Criterion 7: Anthropic Compliance

### Folder naming
- Skill folder: `clarify` (kebab-case, single word). PASS.

### SKILL.md metadata
- Frontmatter contains only `name` and `description`. PASS.
- No `allowed-tools` (not needed; skill uses standard tools). PASS.
- No XML tags in frontmatter. PASS.
- `name` ("clarify") matches folder name. PASS.

### Description quality
- Length: 291 characters (under 1,024 limit). PASS.
- Pattern: [What] "Unified requirement clarification to prevent downstream implementation churn" + [When] "Triggers: cwf:clarify, clarify this, refine requirements" + [Capabilities] "research-first with autonomous decision-making / --light: direct iterative Q&A". PASS.
- Differentiates from similar skills: distinguishes from `gather` (research-only) and `review` (post-hoc evaluation). PASS.

### Composability
- Output format (Phase 5 summary template) is structured and consumable by downstream skills (`plan`, `impl`). PASS.
- Cross-skill references use defensive patterns: "when CWF plugin is loaded" guards the follow-up suggestions (lines 360, 426). PASS.
- No hard dependencies: suggests `cwf:review --mode clarify` and `cwf:handoff --phase` as optional follow-ups. PASS.
- `research-guide.md` is explicitly labeled as a "fallback" when `cwf:gather` is unavailable -- defensive check. PASS.

**Finding**: No compliance issues.

---

## Criterion 8: Concept Integrity

Clarify composes 4 concepts: Expert Advisor, Tier Classification, Agent Orchestration, Decision Point. This is the densest row in the synchronization map.

### 8.1 Expert Advisor

**Required behavior**: Two domain experts with contrasting analytical frameworks evaluate independently; disagreements surface assumptions; agreements provide high-confidence signals.

| Check | What to verify | Status |
|-------|---------------|--------|
| Expert roster | Read `expert_roster` from `cwf-state.yaml` | PRESENT (line 146) |
| Expert pair with contrast | Select 2 experts with contrasting frameworks | PRESENT (lines 148-149) |
| Independent evaluation | Sub-agents run in parallel with separate prompts | PRESENT (lines 151-207) |
| Contrasting frameworks | "contrasting frameworks -- different analytical lenses" | PRESENT (line 148) |
| Synthesize tension | Expert analysis feeds into tier classification | PRESENT (lines 215-221) |
| Update roster | Track usage, propose additions | NOT PRESENT |

**Finding F8-1** (gap): The "Update roster" action from the Expert Advisor concept is not implemented. After expert analysis completes, there is no step to update `expert_roster` in `cwf-state.yaml` with usage history or propose new experts. The `expert-advisor-guide.md` shared reference also does not include roster update instructions. This action is defined in the concept but missing from all implementing skills. Severity: low (roster update may be deferred to a separate maintenance workflow, but the concept explicitly requires it).

### 8.2 Tier Classification

**Required behavior**: Each decision point classified by evidence strength; T1 autonomous with codebase evidence; T2 autonomous with published consensus; T3 queued for human.

| Check | What to verify | Status |
|-------|---------------|--------|
| Classification per point | For each decision point, classify T1/T2/T3 | PRESENT (Phase 3, lines 213-240) |
| Evidence strength rules | Full rules in aggregation-guide.md | PRESENT (line 213 loads the guide) |
| T1 autonomous decision | Decide with file path citations | PRESENT (lines 217, 229-230) |
| T2 autonomous decision | Decide with source citations | PRESENT (lines 218, 231) |
| T3 queued for human | Queue with advisory context | PRESENT (lines 219, 233-238, Phase 3.5/4) |
| Evidence map | Codebase, web, expert evidence per point | PRESENT (lines 215-216: three sources) |
| Tier assignment with rationale | Classification table includes evidence column | PRESENT (output template lines 228-238) |

**Finding**: Full implementation. All required behavior, state, and actions are present. The three evidence sources (codebase, web, expert) align perfectly with the concept's evidence map requirement.

### 8.3 Agent Orchestration

**Required behavior**: Orchestrator assesses complexity, spawns minimum agents, parallel execution in batches, outputs collected and synthesized.

| Check | What to verify | Status |
|-------|---------------|--------|
| Complexity assessment | Mode selection heuristic (lines 23-35) | PRESENT |
| Minimum agents | Skip phases when not needed (zero T3 skips 3.5/4) | PRESENT (line 240) |
| Non-overlapping work | Each sub-agent has distinct role (codebase/web/expert-a/expert-b/advisor-a/advisor-b) | PRESENT |
| Parallel execution | "Launch simultaneously using Task tool" | PRESENT (lines 81, 142, 251) |
| Batch structure | Phase 2 pair -> Phase 2.5 pair -> Phase 3 -> Phase 3.5 pair -> Phase 4 | PRESENT (sequential phases with parallel pairs) |
| Output collection | "Read output files from session dir (not in-memory Task return values)" | PRESENT (lines 131, 207, 301) |
| Context recovery | Validate and reuse existing outputs | PRESENT (lines 76-80, 136-142, 246-251) |
| Provenance metadata | Source, tool, duration per output | PARTIAL |

**Finding F8-2** (gap): Provenance metadata is partially implemented. Sub-agent output files include `<!-- AGENT_COMPLETE -->` sentinels for validation, but the concept requires explicit provenance metadata (source, tool, duration) per output. The expert-advisor-guide.md review mode includes a `Provenance` section with source/tool/expert/framework fields (lines 79-84), but the clarify mode output format in the same guide (lines 42-56) does not include provenance fields. The orchestrator does not collect or record provenance metadata from sub-agent outputs. Severity: medium (provenance is a cross-cutting concern that appears under-implemented in clarify mode specifically).

### 8.4 Decision Point

**Required behavior**: Implicit choices decomposed into concrete questions; each point subjected to evidence gathering; no ambiguity silently resolved.

| Check | What to verify | Status |
|-------|---------------|--------|
| Extract decision points | Phase 1: Decompose into concrete decision points | PRESENT (lines 57-58) |
| Frame as questions | "Frame as questions, not categories" | PRESENT (line 59) |
| Attach evidence | Phase 2 research + Phase 2.5 experts per point | PRESENT |
| Resolve with provenance | Output table includes "Decided By" and "Evidence" | PRESENT (Phase 5, lines 340-346) |
| No silent assumption | T3 items queued for human, not auto-decided | PRESENT (Rule 3, line 434) |
| Decision point list state | Questions with open/resolved status | PARTIAL |

**Finding F8-3** (gap): The concept requires a decision point list with explicit `status: open/resolved` tracking. The SKILL.md tracks decision points implicitly through the phase progression (Phase 1 creates them, Phase 3 classifies them, Phase 4 resolves T3 items), but there is no explicit state object tracking which points are open vs. resolved. The Phase 5 output table serves as the final resolution record, but intermediate status is not explicitly managed. Severity: low (the phase structure implicitly maintains status, and the final output satisfies the resolution record requirement).

### Unclaimed concepts check

Does clarify exhibit behavior matching a concept it does not claim?

- **Handoff**: Clarify suggests `cwf:handoff --phase` as a follow-up (line 362) but does not implement handoff behavior itself. Not a missing sync.
- **Provenance**: Clarify does not check staleness of its own reference documents. No provenance behavior observed. Not a missing sync.

No unclaimed concepts detected.

---

## Summary of Findings

| ID | Criterion | Severity | Finding |
|----|-----------|----------|---------|
| F4-1 | Resource Health | warning | `research-guide.md` (103 lines) and `questioning-guide.md` (147 lines) exceed 100 lines but lack a table of contents |
| F5-1 | Writing Style | nit | "This state is what cwf:impl Phase 1.0 checks as a pre-condition" repeated in both modes |
| F8-1 | Concept Integrity (Expert Advisor) | low | "Update roster" action missing -- no step to update expert_roster usage history after analysis |
| F8-2 | Concept Integrity (Agent Orchestration) | medium | Provenance metadata (source, tool, duration) not collected from sub-agent outputs in clarify mode |
| F8-3 | Concept Integrity (Decision Point) | low | No explicit open/resolved status tracking for decision points during intermediate phases |

### Overall Assessment

Clarify is the most structurally complex skill in the CWF system, composing four generic concepts into a coherent multi-phase workflow with up to six parallel sub-agents. Despite this complexity, the skill is well-organized:

- **Size**: Well within limits at 2,072 words / 448 lines.
- **Progressive disclosure**: Exemplary. Four reference files are loaded on demand, sub-agent prompts reference shared guides, and the body contains only procedural workflow.
- **Duplication**: Minimal. One minor instance (expert selection steps) is defensible given the orchestrator/sub-agent boundary.
- **Freedom calibration**: Excellent throughout -- fragile operations are scripted, creative operations are guided.
- **Anthropic compliance**: Full compliance across all checks.
- **Concept integrity**: Strong implementation of all four composed concepts. The gaps identified (roster updates, provenance metadata, explicit status tracking) are minor and largely reflect cross-cutting concerns that may warrant system-level rather than per-skill solutions.

No errors. Two warnings. Three low/medium concept gaps. The skill is production-ready with minor improvement opportunities.

<!-- AGENT_COMPLETE -->
