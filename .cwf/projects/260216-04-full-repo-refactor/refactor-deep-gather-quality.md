# Deep Review: gather -- Quality + Concept (Criteria 5-8)

**Skill**: `gather` (1430 words, 263 lines)
**Reviewer scope**: Criteria 5 (Writing Style), 6 (Degrees of Freedom), 7 (Anthropic Compliance), 8 (Concept Integrity)
**Date**: 2026-02-16

---

## Criterion 5: Writing Style

**Verdict**: PASS (minor issues)

### Strengths

- Consistently uses imperative form throughout: "Parse args", "Execute the appropriate handler", "Save results", "Scan input for all URLs". This matches the review criteria's requirement for imperative/infinitive form.
- Concise examples are provided inline (e.g., the Quick Reference block, bash invocation snippets) rather than verbose explanations.
- No extraneous documentation files (no README.md, INSTALLATION_GUIDE.md, etc.).
- Information presented is genuinely skill-specific -- URL pattern tables, script invocations, timestamp parsing formulas -- not things the agent already knows.

### Issues

| ID | Severity | Location | Finding |
|----|----------|----------|---------|
| 5.1 | nitpick | Line 10, "Language" note | The sentence "Write gathered artifacts in English. Communicate with the user in their prompt language." uses imperative form correctly, but the bold **Language** label above the workflow body is slightly unusual placement. Not a violation, just atypical. |
| 5.2 | nitpick | Lines 214-218, Supplementary Research examples | The three bullet examples ("Gathered a Google Doc describing a migration plan...") use past tense narrative rather than imperative. Consider: "Google Doc with migration plan -> search for best practices". Minor; the surrounding prose is imperative. |

---

## Criterion 6: Degrees of Freedom

**Verdict**: PASS

The skill correctly calibrates freedom level to task fragility:

| Task Area | Freedom Level | Justification | Assessment |
|-----------|--------------|---------------|------------|
| URL classification | Low (specific pattern table) | Misrouting a URL to the wrong handler would silently produce bad output. The deterministic pattern table (line 43-51) eliminates guesswork. | Correct |
| Script invocations | Low (exact bash commands) | Scripts have specific argument signatures. Wrong arguments produce errors or corrupt output. Each handler section gives exact `bash` invocations. | Correct |
| `thread_ts` parsing | Low (explicit formula) | The formula `p{digits} -> {first10}.{rest}` (line 64) prevents a subtle, hard-to-debug error. | Correct |
| Search routing | Medium (decision tree in reference) | Multiple valid routes exist depending on query content. The reference `query-intelligence.md` provides a parameterized decision tree with keyword tables, but the agent applies judgment for ambiguous cases. | Correct |
| Supplementary research | High (text guidance) | After gathering, the agent decides whether supplementary search would help. This is inherently context-dependent. Lines 208-218 give only prose guidance with examples. | Correct |
| GitHub `gh` missing interaction | Medium (3 fixed options) | When `gh` is absent, lines 89-92 present exactly three choices. The agent must ask, not decide silently. | Correct |
| `--local` mode sub-agent prompt | Medium (template with variable) | The Task prompt on line 181 is parameterized with `<query>` and specifies output structure, but the sub-agent has freedom in exploration strategy. | Correct |

No mismatches detected. Freedom levels align with fragility across all task areas.

---

## Criterion 7: Anthropic Compliance

**Verdict**: PASS (one minor finding)

### Folder naming
- Plugin folder: `cwf` -- kebab-case (single word, valid). PASS.
- Skill folder: `gather` -- kebab-case (single word, valid). PASS.

### SKILL.md metadata
- Frontmatter contains only `name` and `description`. No `allowed-tools` (optional, not required). PASS.
- No XML tags in frontmatter values. PASS.
- `name: gather` matches skill folder name `gather`. PASS.

### Description quality
- Character count of description: ~395 characters. Well under the 1024 limit. PASS.
- Pattern check:
  - **What it does**: "Unified information acquisition that stabilizes context before reasoning: URL auto-detect (Google/Slack/Notion/GitHub/web), web search (Tavily/Exa), and local codebase exploration." PRESENT.
  - **When to use it**: "Trigger on: - \"cwf:gather\" command - When the user provides external content URLs matching supported services - When a reference file contains URLs that need to be fetched - When the user requests web search or code search". PRESENT.
  - **Key capabilities**: URL auto-detect, web search, local codebase exploration. PRESENT.
- Trigger phrases are explicit. PASS.
- Differentiation: the description clearly scopes to information acquisition (not planning, not implementation). PASS.

### Composability
- No duplication of functionality from other installed skills detected. The `gather` skill is the sole owner of URL fetching, web search, and local exploration.
- Cross-skill references: Line 163 references `cwf:setup --env` and `cwf:setup --tools` for missing dependency configuration. This is a soft suggestion pattern ("run cwf:setup"), not a hard import. PASS.
- Output format: gathered artifacts are saved as `.md` files in `OUTPUT_DIR`, which is a standard format consumable by all downstream skills (clarify, plan, impl, etc.). PASS.
- Line 90 references `{SKILL_DIR}/../setup/scripts/install-tooling-deps.sh` for `gh` installation. This is a relative path to a sibling skill's script.

| ID | Severity | Location | Finding |
|----|----------|----------|---------|
| 7.1 | minor | Line 90 | Direct file path reference to sibling skill script (`{SKILL_DIR}/../setup/scripts/install-tooling-deps.sh`). Criterion 7 says "Cross-skill references should use defensive checks (gate on file/directory existence)." No existence check is specified before calling this script. Recommend adding: "If the script exists, run it; otherwise, suggest `cwf:setup --tools`." |

---

## Criterion 8: Concept Integrity -- Agent Orchestration

**Verdict**: PASS (one observation)

### Synchronization map lookup

The concept map (Section 2) shows `gather` composes exactly one concept:

| Concept | Claimed? |
|---------|----------|
| Expert Advisor | no |
| Tier Classification | no |
| **Agent Orchestration** | **yes** |
| Decision Point | no |
| Handoff | no |
| Provenance | no |

### Required Behavior verification

From concept-map.md Section 1.3, Agent Orchestration requires:

> Orchestrator assesses complexity and spawns minimum agents needed

- **Assessment**: The `--local` mode (lines 179-186) explicitly launches a single sub-agent via `Task()`. This is the "Single" pattern from the adaptive sizing spectrum. For URL and `--search` modes, the gather skill itself acts as orchestrator executing scripts sequentially -- no sub-agents needed because each script is an atomic operation. The skill correctly spawns the minimum agents needed (0 for URL/search, 1 for local). PASS.

> Each agent has distinct, non-overlapping work

- **Assessment**: Only one sub-agent is ever spawned (for `--local`), so overlap is impossible. For multi-URL inputs, the skill processes URLs sequentially through the pattern table rather than spawning parallel agents -- this is appropriate because URL handlers are I/O-bound scripts, not reasoning tasks. PASS.

> Parallel execution in batches (respecting dependencies)

- **Assessment**: The skill does not explicitly describe parallel batching for multiple URLs. However, the concept says "respecting dependencies" -- and URL processing order may matter (e.g., a Notion page referencing a Google Doc). Sequential processing is the safe default. The concept map example in the review criteria (Section 3) says to verify "parallel batch for broad queries" -- the `--local` mode uses a single Task call, which is the correct "Single" sizing. For `--search`, the scripts are atomic calls, not parallelizable reasoning tasks. PASS with observation (see 8.1 below).

> Outputs are collected, verified, and synthesized

- **Assessment**: For URL mode, outputs are saved to `OUTPUT_DIR` (line 34-35). For `--local`, the sub-agent output is saved to `{OUTPUT_DIR}/local-{sanitized-query}.md` (line 183). For `--search`, scripts output formatted markdown directly (line 159). Collection is present. Verification is implicit (scripts exit non-zero on failure, and the skill specifies graceful degradation). Synthesis is present in the form of the "Supplementary Research" section (lines 206-218), which suggests follow-up searches after URL gathering. PASS.

### Required State verification

| State element | Present? | Evidence |
|---------------|----------|----------|
| Work item decomposition | Yes | URL pattern classification table (lines 43-51) decomposes input into typed work items. `--search` routing in query-intelligence.md decomposes query into routed backend + parameters. |
| Agent team composition | Yes (minimal) | Implicit: the skill is always a single orchestrator + 0-1 sub-agents. The `--local` section (line 179) explicitly defines the sub-agent as `subagent_type="general-purpose"`. |
| Batch execution plan | Partial | No explicit batch plan for multi-URL inputs. URLs are processed sequentially by handler type. This is acceptable given the I/O nature of the work. |
| Provenance metadata | Partial | Output files include source URLs (e.g., Slack exports include `> Source: $THREAD_URL`, line 43 of slack-to-md.sh). Google exports preserve original document title. Search results include source URLs. However, there is no explicit duration or tool metadata in output files. |

### Required Actions verification

| Action | Present? | Evidence |
|--------|----------|----------|
| Decompose into work items | Yes | URL pattern matching (lines 43-51), search routing (query-intelligence.md) |
| Size team adaptively | Yes | Single agent for `--local`, no agents for URL/search (scripts handle it). This is the "Single" tier of adaptive sizing. |
| Launch parallel batch | N/A | Gather's work items are I/O-bound script calls, not reasoning tasks requiring parallel sub-agents. The single `Task()` call for `--local` is correct. |
| Collect and verify results | Yes | Scripts exit non-zero on failure. Graceful degradation is specified (lines 249-253). Output files are saved to `OUTPUT_DIR`. |
| Synthesize outputs | Yes | Supplementary Research section (lines 206-218) synthesizes URL gathering with follow-up search. |

### Unclaimed concept check

Does `gather` exhibit behavior matching a concept it does not claim?

| Concept | Behavior match? | Analysis |
|---------|----------------|----------|
| Expert Advisor | No | No expert roster, no contrasting frameworks. |
| Tier Classification | No | No evidence-based tier routing of decisions. The URL pattern table is deterministic classification, not evidence-strength classification. |
| Decision Point | No | No explicit decomposition of ambiguity into decision points. The three-choice interaction for missing `gh` (lines 89-92) is a user prompt, not a decision point framework. |
| Handoff | No | No session artifacts, no next-session.md generation. |
| Provenance | No | No staleness checking of reference documents before applying them. |

No missing synchronization detected.

### Observations

| ID | Severity | Location | Finding |
|----|----------|----------|---------|
| 8.1 | observation | Lines 40-51, multi-URL processing | When multiple URLs are provided (`cwf:gather <url1> <url2> ...`), the skill does not describe whether to process them sequentially or in parallel. The Quick Reference (line 17) shows multi-URL syntax exists, but the Workflow section (lines 32-36) and URL Auto-Detect section do not specify ordering or batching strategy. For Agent Orchestration completeness, consider adding a single sentence: "Process multiple URLs sequentially, in pattern-table priority order." This makes the implicit behavior explicit. |

---

## Summary

| Criterion | Verdict | Findings |
|-----------|---------|----------|
| 5. Writing Style | PASS | 2 nitpicks (past tense in examples, bold label placement) |
| 6. Degrees of Freedom | PASS | No issues. Freedom levels well-calibrated to fragility. |
| 7. Anthropic Compliance | PASS | 1 minor (cross-skill script reference without existence gate) |
| 8. Concept Integrity | PASS | 1 observation (multi-URL batch strategy not explicit) |

### Unreferenced resource

| ID | Severity | Finding |
|----|----------|---------|
| R.1 | minor | `scripts/csv-to-toon.sh` is not referenced by filename in SKILL.md. It is called indirectly by `g-export.sh` (line 111 of that script), so it is a transitive dependency. Per Criterion 4 (Resource Health, not in this review's scope but noted for completeness): "A file is 'referenced' if its filename appears in SKILL.md." Consider adding `csv-to-toon.sh` to the Google Export section or the References list, or noting it as a dependency of `g-export.sh`. |

### Actionable items (prioritized)

1. **[7.1]** Add defensive existence check before calling `install-tooling-deps.sh` from sibling skill.
2. **[8.1]** Add explicit multi-URL processing order statement to URL Auto-Detect section.
3. **[R.1]** Reference `csv-to-toon.sh` in SKILL.md (Google Export section or References list).

<!-- AGENT_COMPLETE -->
