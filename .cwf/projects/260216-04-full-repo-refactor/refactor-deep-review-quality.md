# Deep Review: `review` Skill -- Quality + Concept (Criteria 5-8)

**Target**: `/home/hwidong/codes/claude-plugins/plugins/cwf/skills/review/SKILL.md`
**Word count**: 4058 words | **Line count**: 702 lines
**Reference files reviewed**: `references/prompts.md`, `references/external-review.md`
**Scripts directory**: empty (no scripts bundled)
**Concept map row**: Expert Advisor, Agent Orchestration

---

## Criterion 5: Writing Style

**Rating**: Mostly compliant, with several notable deviations.

### Imperative/infinitive compliance

The skill generally uses imperative form well in procedural sections:

- "Parse mode flag" (Phase 1.1)
- "Detect review target" (Phase 1.2)
- "Extract behavioral/qualitative criteria" (Phase 1.3)
- "Launch all 6 in ONE message" (Phase 2.3)
- "Read all results from session directory" (Phase 3.1)

However, several passages slip into descriptive or explanatory prose where imperative would be tighter:

| Location | Current (descriptive) | Suggested (imperative) |
|----------|----------------------|----------------------|
| Phase 2.0 heading | "Resolve session directory and context recovery" | "Resolve session directory" (the "and context recovery" is redundant -- the steps make it clear) |
| Phase 3.2, error classification intro | "When an external CLI exits non-zero, parse stderr **immediately** for error type keywords. This prevents wasting time on retries that cannot succeed." | "Parse stderr **immediately** when an external CLI exits non-zero. Error-type classification avoids futile retries." |
| Phase 1.2, code mode step 1 | "Resolve base strategy:" followed by nested conditionals | The nesting is fine, but the leading colon signals a passive list rather than an action sequence. Consider starting with "Determine base branch:" |

### Filler / extraneous documentation

Several passages contain information the agent already knows or provide justification where only instruction is needed:

1. **Lines 36-37** (fallback latency note): "If both external CLIs fail, the skill incurs a two-round-trip penalty -- first the CLI attempts run (up to 120s timeout each), then fallback Task agents are launched sequentially. Error-type classification (Phase 3.2) enables fail-fast for CAPACITY errors, reducing wasted time." This entire paragraph is explanatory rationale, not procedural. It tells the agent *why* fallback is slow, but the agent does not need this to execute the workflow. Move to a design note or remove.

2. **Lines 304-305**: "For `--mode code`, use `model_reasoning_effort='xhigh'` instead. Single quotes around config values avoid double-quote conflicts in the Bash wrapper." The second sentence explains *why* single quotes are used. The agent does not need this rationale -- it follows the template. This is duplicated in `external-review.md` line 127 as well.

3. **Lines 341-342**: "Uses stdin redirection (`< prompt.md`) instead of `-p "$(cat ...)"` to prevent shell injection from review target content containing `$()` or backticks." Same pattern -- justification, not instruction. Already stated in `external-review.md` line 136.

4. **Phase 4, Section 2 header comment** (line 543): "Output to the conversation (do NOT write to a file unless the user asks)" -- This is a rule restated at the point of use. It is already Rule 5 (line 651). Prefer a single canonical location.

### Finding summary

- **3 filler/rationale paragraphs** that could be trimmed or moved to a design-notes section
- **1 duplicated rule** restated inline instead of referencing the Rules section
- Imperative form is mostly clean; a few heading-level phrases are descriptive rather than action-oriented

---

## Criterion 6: Degrees of Freedom

**Rating**: Well-calibrated overall, with one notable mismatch.

### Freedom-level assessment by phase

| Phase | Freedom Level | Assessment |
|-------|--------------|------------|
| Phase 1.1 (parse flags) | Low (specific flags) | Correct -- exact flag names, defaults, types. No ambiguity. |
| Phase 1.2 (detect target) | Low (ordered fallback) | Correct -- deterministic try-in-order strategy with explicit git commands. |
| Phase 1.3 (extract criteria) | Medium (pattern guidance) | Correct -- provides patterns to look for (Given/When/Then, checkboxes) but allows judgment on what qualifies. |
| Phase 1.4 (holdout scenarios) | Low (strict validation) | Correct -- explicit error on missing/invalid, no silent bypass. |
| Phase 1.5 (turn budget) | Low (table-driven) | Correct -- concrete thresholds with exact values. |
| Phase 2.1 (prepare prompts) | Low (template) | Correct -- exact prompt structure with placeholders. |
| Phase 2.2 (detect providers) | Low (script) | Correct -- exact bash command, deterministic parsing. |
| Phase 2.3 (launch reviewers) | Low (specific templates) | Correct -- exact Task/Bash invocations with all parameters specified. |
| Phase 3.1 (collect outputs) | Low (file-based) | Correct -- exact file paths, deterministic validation. |
| Phase 3.2 (handle failures) | Low (decision table) | Correct -- enumerated error types with exact pattern matching and prescribed actions. |
| Phase 4 (synthesize) | Medium (template + judgment) | Correct -- verdict rules are table-driven, but synthesis prose requires judgment. |

### Mismatch: Expert selection (Phase 2.3, Slot 5-6)

The expert selection process (line 375) is described in **high-freedom prose**: "Analyze the review target for domain keywords; match against each roster entry's `domain` field. Select 2 experts with contrasting frameworks." This is a fragile operation that determines which experts run, yet the instructions leave significant ambiguity:

- What constitutes a "domain keyword" match? Substring? Semantic similarity?
- How is "contrasting" defined operationally? The concept map requires "contrasting analytical frameworks," but the skill provides no criteria for what makes two frameworks "contrasting" versus merely "different."
- The fallback "If roster has < 2 matches, fill via independent selection" is high-freedom -- the agent must invent experts from scratch with no constraint beyond "contrasting."

This should be **medium freedom** at minimum: provide a matching heuristic (e.g., "match if any roster `domain` keyword appears in the diff's file paths or content") and a contrast criterion (e.g., "select experts from different `domain` values" or "select experts whose `framework` descriptions emphasize different qualities").

### Finding summary

- **11 of 12 phases** are well-calibrated to their fragility
- **1 mismatch**: Expert selection is high-freedom prose for a decision that should be medium-freedom with a concrete matching/contrast heuristic

---

## Criterion 7: Anthropic Compliance

### Folder naming

- Skill folder: `review` -- kebab-case, compliant.

### SKILL.md metadata (frontmatter)

```yaml
name: review
description: "Universal review with narrative verdicts..."
```

- Contains only `name` and `description` -- compliant.
- No `allowed-tools` field is present. The skill uses Task, Bash, and file I/O tools. Since `allowed-tools` is optional and omission means "all tools allowed," this is technically compliant. However, given that the skill explicitly depends on Task and Bash, declaring `allowed-tools` would be a best practice for clarity.
- No XML tags in frontmatter values -- compliant.
- `name: review` matches the skill folder name `review` -- compliant.

### Description quality

The description is:

> "Universal review with narrative verdicts for consistent quality gates before and after implementation. 6 parallel reviewers: 2 internal (Security, UX/DX) via Task + 2 external slots via available providers (Codex/Gemini CLI, Claude Task fallback) + 2 domain experts via Task. Graceful fallback when CLIs are unavailable. Modes: --mode clarify/plan/code. Triggers: "/review""

**Character count**: ~378 characters -- well under 1024 limit. Compliant.

**Pattern check** ([What] + [When] + [Key capabilities]):
- [What]: "Universal review with narrative verdicts for consistent quality gates" -- present.
- [When]: "Triggers: "/review"" -- present but minimal. The description says "before and after implementation" which is useful context, but it could be more explicit about trigger scenarios (e.g., "Use after /plan to validate specs, or after /impl to validate code changes").
- [Key capabilities]: "6 parallel reviewers..." -- present and detailed.

**Differentiation**: The description does not explicitly differentiate from `retro` (which also uses parallel reviewers and Expert Advisor). A reader might wonder when to use `/review` vs `/retro`. Consider adding a brief differentiator (e.g., "prospective quality gate" vs retro's "retrospective analysis").

### Composability

- **Cross-skill references**: The skill references `cwf:plan` and `cwf:impl` in Quick Reference (line 24-25) using suggestion form ("Recommended linkage") -- compliant with "prefer suggestions."
- **Cross-skill references**: Phase 3.2 references `cwf:setup --tools` (line 474) defensively as a user interaction ("Ask whether to install now") -- compliant.
- **Output format**: The synthesis format is rendered to the conversation as markdown -- consumable by other skills if they read conversation context.
- **No hard dependencies**: External CLIs (Codex, Gemini) are optional with graceful fallback -- compliant.

### Code fences in SKILL.md

The skill contains numerous code fences with Bash commands and Task invocation templates. These are appropriate for the low-freedom operations they describe (exact CLI commands, exact prompt templates). The code fences serve as executable templates, not as documentation -- they are the canonical specification of how to invoke each tool.

One concern: the Bash commands in Phase 2.3 (lines 302, 310, 347) are long single-line commands embedded in code fences. While these are necessary for low-freedom specification, they are difficult to read and verify. The `external-review.md` reference file already contains the CLI invocation templates -- the SKILL.md could reference those templates instead of inlining the full commands, reducing body size and duplication.

### Finding summary

- Folder naming, metadata structure, description length: all compliant
- Missing `allowed-tools` (optional but recommended)
- Description trigger/when-to-use phrasing is minimal
- No explicit differentiation from `retro` in the description
- Long inline Bash commands duplicate content from `external-review.md` (relates to Criterion 3 / duplication, noted here for Anthropic compliance context)

---

## Criterion 8: Concept Integrity

The synchronization map row for `review`:

| Expert Advisor | Tier Classification | Agent Orchestration | Decision Point | Handoff | Provenance |
|:-:|:-:|:-:|:-:|:-:|:-:|
| x | | x | | | |

Two concepts claimed: **Expert Advisor** and **Agent Orchestration**.

### 8.1 Expert Advisor

**Required Behavior**: Two domain experts with contrasting analytical frameworks evaluate independently. Disagreements surface assumptions a single perspective would miss. Agreements provide high-confidence signals.

| Check | Verdict | Evidence |
|-------|---------|----------|
| Two experts with contrasting frameworks | PASS | Slots 5-6 are Expert alpha and Expert beta. Line 375: "Select 2 experts with contrasting frameworks." Expert selection reads `expert_roster` from `cwf-state.yaml`, matches domain keywords, and ensures contrast. |
| Independent evaluation | PASS | Experts are launched as separate Task agents in parallel (lines 377-431). Each receives the same review target but operates under its own expert identity and framework. |
| Disagreements surface assumptions | PARTIAL | The synthesis template (Phase 4) includes a "Confidence Note" section that mentions "Disagreements between reviewers and which side was chosen" (line 582). However, this is generic across all 6 reviewers -- it does not specifically call out Expert alpha vs Expert beta tension. The Expert Advisor concept requires that disagreements between the two experts are surfaced as a distinct analytical signal, not merged into a general disagreement bucket. |
| Agreements provide high-confidence signals | MISSING | The synthesis template has no mechanism to highlight when both experts agree on a concern or suggestion. The concept requires that agreements carry special weight as "high-confidence signals," but the current synthesis treats expert outputs identically to internal reviewer outputs. |

**Required State**:

| State Element | Verdict | Evidence |
|---------------|---------|----------|
| Expert roster (name, domain, framework, usage history) | PASS | Line 375: "Read `expert_roster` from `cwf-state.yaml`." The roster is maintained externally; the skill reads it. |
| Expert pair assignment (alpha/beta, contrasting frameworks) | PASS | Lines 375-376 describe selection with contrast. Slot 5 is alpha, Slot 6 is beta with "contrasting framework from Expert alpha." |
| Analysis output per expert | PASS | Each expert writes to a dedicated output file: `review-expert-alpha-{mode}.md` and `review-expert-beta-{mode}.md`. |

**Required Actions**:

| Action | Verdict | Evidence |
|--------|---------|----------|
| Select experts (match domain, ensure contrast) | PASS (with caveat) | Described at line 375. The matching heuristic is underspecified (see Criterion 6 finding), but the action is present. |
| Launch parallel analysis (independent evaluation) | PASS | Both experts launch in the same message as all other reviewers (Phase 2.3). |
| Synthesize tension (surface agreements and disagreements) | PARTIAL | The synthesis phase does not distinguish expert-pair tension from general reviewer disagreement. The concept requires explicit tension synthesis between the two experts as a distinct analytical product. Currently, expert outputs are folded into the same synthesis flow as all 6 reviewers. |
| Update roster (track usage, propose additions) | MISSING | The skill never writes back to `cwf-state.yaml` to update expert usage history or propose new experts. The concept requires "track usage, propose additions" as a required action, but the review skill is read-only with respect to the roster. |

**Expert Advisor Summary**: The structural elements are in place (two experts, contrasting selection, parallel launch, dedicated output files). Two gaps exist:

1. **Tension synthesis is not distinct** -- expert alpha/beta disagreements are not surfaced as a separate analytical signal in the synthesis template. They are merged into the general "Confidence Note" alongside all other reviewer disagreements.
2. **Roster update is absent** -- the skill reads the expert roster but never updates usage history or proposes additions.

### 8.2 Agent Orchestration

**Required Behavior**: Orchestrator assesses complexity and spawns minimum agents needed. Each agent has distinct, non-overlapping work. Parallel execution in batches. Outputs are collected, verified, and synthesized.

| Check | Verdict | Evidence |
|-------|---------|----------|
| Complexity assessment | PASS | Phase 1.5 measures review target size and sets turn budgets with a 3-tier table (lines 152-158). |
| Minimum agents needed | PARTIAL | The skill always launches exactly 6 reviewers (Rule 1, line 642: "Always run ALL 6 reviewers -- deliberate naivete"). This is by design -- the skill explicitly rejects adaptive sizing in favor of fixed coverage. The concept says "spawns minimum agents needed," but the skill's design philosophy (deliberate naivete from agent-patterns.md) argues that 6 is always the minimum for adequate coverage. This is a defensible design choice, though it deviates from the concept's literal wording. |
| Distinct, non-overlapping work | PASS | Each of the 6 reviewers has a clearly defined, non-overlapping perspective: Security, UX/DX, Correctness, Architecture, Expert alpha, Expert beta. Perspectives are documented in `prompts.md` and `external-review.md`. |
| Parallel execution in batches | PASS | Phase 2.3 (line 267): "All 6 reviewers launch in a single message for parallel execution." Fallbacks (Phase 3.2) also launch in batches: "launch all needed fallback Task agents in one message" (line 504). |
| Outputs collected, verified, synthesized | PASS | Phase 3.1 reads all 6 files from session directory. Context recovery protocol validates each file (sentinel check). Phase 4 synthesizes with structured verdict rules. |

**Required State**:

| State Element | Verdict | Evidence |
|---------------|---------|----------|
| Work item decomposition | PASS | The 6 reviewer slots with assigned perspectives and mode-specific checklists constitute the decomposition. |
| Agent team composition | PASS | Fixed at 6 agents: 2 internal Task, 2 external (CLI or Task fallback), 2 expert Task. Documented in Phase 2 header. |
| Batch execution plan | PASS | Single batch of 6, with a contingent second batch for fallbacks. Sequential dependency: Phase 2 -> Phase 3 -> Phase 4. |
| Provenance metadata (source, tool, duration per output) | PASS | The Reviewer Provenance table (lines 597-604) tracks source, tool, and duration for each reviewer. External reviewers have measured `duration_ms` from meta files. |

**Required Actions**:

| Action | Verdict | Evidence |
|--------|---------|----------|
| Decompose into work items | PASS | Fixed decomposition into 6 reviewer perspectives. |
| Size team adaptively | N/A (by design) | The skill uses "4 parallel" pattern per agent-patterns.md (now 6 with experts), not adaptive sizing. Rule 1 makes this explicit. Acceptable deviation -- the skill is in the "4 parallel" category, not "Adaptive." |
| Launch parallel batch | PASS | "All 6 reviewers launch in a single message" (line 267). |
| Collect and verify results | PASS | Phase 3.1 reads files, applies context recovery protocol, re-validates with bounded retry. Phase 3.2 handles external failures with error classification. |
| Synthesize outputs | PASS | Phase 4 applies verdict rules, renders structured synthesis with concerns, suggestions, behavioral criteria, and provenance. |

**Agent Orchestration Summary**: Fully implemented. The fixed team size is a deliberate design choice documented in both the skill's rules and agent-patterns.md. All other required behaviors, state elements, and actions are present and well-specified.

### 8.3 Unclaimed Concept Check

Does the skill exhibit behavior matching a concept it does not claim?

| Concept | Evidence of behavior | Verdict |
|---------|---------------------|---------|
| Tier Classification | The skill does not classify decisions by evidence strength or route to human/agent tiers. Verdict rules (Phase 4.1) determine review outcome, not decision routing. | No match -- not unclaimed. |
| Decision Point | The skill does not decompose requirements into decision points. It consumes decision points (from plan criteria) but does not generate them. | No match -- not unclaimed. |
| Handoff | The skill does not generate session or phase handoff documents. Output is rendered to conversation (Rule 5). | No match -- not unclaimed. |
| Provenance | The skill tracks provenance metadata per reviewer (source, tool, duration, command). However, it does NOT check reference document staleness or detect when analytical criteria have become stale. The provenance tracked is execution provenance (which tool ran), not reference provenance (whether the review criteria are still valid). | No match -- different kind of provenance. Execution provenance is part of Agent Orchestration, not the Provenance concept. |

**No unclaimed concepts detected.** The skill does not exhibit behavior matching concepts outside its claimed set.

---

## Consolidated Findings

### Issues

| ID | Criterion | Severity | Location | Description |
|----|-----------|----------|----------|-------------|
| Q1 | 5 (Style) | minor | Lines 36-37 | Fallback latency rationale paragraph is explanatory filler, not procedural instruction. Remove or move to a design note. |
| Q2 | 5 (Style) | minor | Lines 304-305, 341-342 | Inline rationale for single-quote and stdin-redirect choices duplicates content from `external-review.md`. Remove from SKILL.md body. |
| Q3 | 5 (Style) | minor | Line 543 | Rule 5 restated inline ("do NOT write to a file unless the user asks"). Remove duplication; the Rules section is the canonical location. |
| Q4 | 6 (DoF) | moderate | Line 375 | Expert selection heuristic is high-freedom prose for a medium-fragility operation. Add a concrete matching criterion (e.g., keyword overlap between roster `domain` and diff file paths/content) and a contrast criterion (e.g., different `domain` values or explicitly non-overlapping `framework` descriptions). |
| Q5 | 7 (Anthropic) | minor | Frontmatter | Missing `allowed-tools` field. While optional, declaring the tools the skill depends on (Task, Bash, Read, Write) improves discoverability and enforceability. |
| Q6 | 7 (Anthropic) | minor | Description | Trigger/when-to-use phrasing is minimal ("Triggers: /review"). Could more explicitly describe when to invoke vs. `/retro`. |
| Q7 | 8 (Concept) | moderate | Phase 4 synthesis | Expert Advisor tension synthesis is not distinct. Expert alpha/beta disagreements are merged into the general Confidence Note rather than surfaced as a separate "Expert Tension" section. The concept requires that expert disagreements are a distinct analytical signal. |
| Q8 | 8 (Concept) | moderate | Phase 4 synthesis | Expert Advisor agreements are not highlighted as high-confidence signals. The synthesis template treats expert outputs the same as all other reviewers, losing the concept's signal-boosting property. |
| Q9 | 8 (Concept) | minor | Skill-wide | Expert Advisor roster update action is absent. The skill reads `expert_roster` but never writes usage history back or proposes additions. This may be deferred to `retro` or another skill, but the concept map claims the action for `review`. |

### Positive observations

1. **Agent Orchestration is exemplary.** The 6-reviewer parallel launch with fallback handling, error classification, provenance tracking, and context recovery is thorough and well-specified. The fixed team size is a principled design choice (deliberate naivete), not an oversight.

2. **Error handling is comprehensive.** Phase 3.2's error-type classification (CAPACITY/INTERNAL/AUTH/TOOL_ERROR) with distinct actions per type, plus the exit-code fallback table, leaves no ambiguous failure mode. The L9 error cause extraction for Confidence Notes is a strong accountability mechanism.

3. **Freedom levels are mostly well-calibrated.** 11 of 12 phases match their fragility level. The low-freedom CLI templates, turn budget tables, and verdict rules leave minimal room for agent drift.

4. **Context recovery integration is clean.** Phase 2.0's session directory resolution and Phase 3.1's re-validation loop correctly implement the shared context recovery protocol, enabling crash recovery without re-running completed reviewers.

5. **Mode-namespaced output files** (line 181) prevent filename collisions between review rounds in the same session -- a subtle but important detail for multi-review workflows.

<!-- AGENT_COMPLETE -->
