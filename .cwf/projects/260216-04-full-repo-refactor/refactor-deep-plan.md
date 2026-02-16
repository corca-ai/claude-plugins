# Deep Review: plan

**Skill**: `plugins/cwf/skills/plan/SKILL.md`
**Word count**: 1589 | **Line count**: 332
**Claimed concepts**: Agent Orchestration, Decision Point

---

## Criterion 1: SKILL.md Size

| Metric | Value | Threshold | Verdict |
|--------|-------|-----------|---------|
| Word count | 1,589 | warn > 3,000; error > 5,000 | PASS |
| Line count | 332 | warn > 500 | PASS |

No size concerns. The skill is well within all thresholds.

---

## Criterion 2: Progressive Disclosure Compliance

### Metadata (frontmatter)

| Check | Verdict | Detail |
|-------|---------|--------|
| Fields limited to `name`, `description` | PASS | Only `name` and `description` present |
| Description includes what + when | PASS | Covers purpose ("Agent-assisted plan drafting...") and triggers (`cwf:plan`, "plan this task") |
| Description <= 1024 chars | PASS | ~299 characters |
| No XML tags in frontmatter | PASS | Clean |

### Body content

| Check | Verdict | Detail |
|-------|---------|--------|
| No "When to Use This Skill" section in body | PASS | Trigger info is correctly in the description only |
| No long code examples that should be in references | PASS | Code blocks are short and procedural (bash invocations, markdown templates) |
| No API docs, schemas, or lookup tables in body | PASS | The plan template in Phase 3 is a structural skeleton, not a lookup table; this is appropriate for inline inclusion since it is the core procedural output |

### Potential concern

The "Required Plan Sections" template (lines 203-256) is 54 lines of fenced markdown. This is borderline: it is the primary artifact the skill produces, so inline is defensible, but if additional sections are ever added it could be extracted to `references/plan-template.md`. No action required at current size.

**Verdict**: PASS -- no violations.

---

## Criterion 3: Duplication Check

The skill references one external file inline: `plan-protocol.md`.

| Content area | In SKILL.md? | In plan-protocol.md? | Duplication? |
|-------------|-------------|---------------------|--------------|
| Plan location rules | Phase 4 lines 273-277 (summary) | Full detail (lines 8-17) | Minor overlap |
| Success Criteria format | Phase 3 lines 230-242 (full BDD + qualitative two-layer) | Lines 20-31 (BDD only) | **Partial duplication** |
| lessons.md format | Phase 4 lines 287-299 (full template) | Lines 65-78 (full template) | **Duplication** |
| Language rules | Line 10 + Rule 11 | Lines 44-45 (plan), lines 82-83 (lessons) | **Duplication** |

### Findings

1. **lessons.md template duplication** (MINOR): The Expected/Actual/Takeaway template appears in both SKILL.md (lines 291-298) and plan-protocol.md (lines 70-78). The SKILL.md version omits the optional `When [situation] -> [action]` guideline from the protocol.
   - **Recommendation**: Keep the authoritative template in plan-protocol.md; reduce the SKILL.md instance to a pointer ("Follow the lessons format in plan-protocol.md").

2. **Language rule duplication** (MINOR): "Write plan.md in English / lessons.md in user's language" appears as the Language line (line 10), as Rule 11 (line 328), and again in plan-protocol.md (lines 44-45, 82-83). Three occurrences within the skill itself.
   - **Recommendation**: State once in the Rules section; remove the standalone line 10 or convert to a pointer.

3. **Success Criteria duplication** (MINOR): The two-layer format (BDD + Qualitative) is defined in Phase 3 (lines 230-242) and restated in the section "Success Criteria Format" (lines 258-263). This is internal duplication within the same file.
   - **Recommendation**: Merge into a single location. The "Success Criteria Format" subsection (lines 258-263) adds no new information beyond what the template already shows.

**Verdict**: MINOR issues -- three instances of internal/cross-file duplication. None severe, but cleaning up would reduce token cost and avoid drift risk.

---

## Criterion 4: Resource Health

### File quality

The skill has no local `references/` or `scripts/` directories. All references point to shared plugin-level resources:

| Referenced file | Exists | Size concern |
|----------------|--------|-------------|
| `../../references/plan-protocol.md` | Yes | 130 lines -- could use a brief TOC but not critical |
| `../../references/context-recovery-protocol.md` | Yes (via protocol name, not direct link) | 103 lines -- has clear sections |
| `../../references/agent-patterns.md` | Yes (referenced within sub-agent prompt) | 221 lines -- has TOC-equivalent section headers |

### Unused resources

No local `references/`, `scripts/`, or `assets/` directories exist for this skill, so no orphan check is needed.

### External references in SKILL.md

| Filename referenced | Line | Status |
|--------------------|------|--------|
| `plan-protocol.md` | 175, 273 | Referenced and used |
| `context-recovery-protocol.md` | 79 (link), 166 | Referenced and used |
| `agent-patterns.md` | 103 (within sub-agent prompt) | Referenced and used |
| `cwf-live-state.sh` | 39, 71 | Script reference, used |
| `next-prompt-dir.sh` | 276 | Script reference, used |

**Verdict**: PASS -- all references resolve; no orphan resources.

---

## Criterion 5: Writing Style

| Check | Verdict | Detail |
|-------|---------|--------|
| Imperative/infinitive form | PASS | Consistent imperative throughout ("Record the task", "Identify what needs planning", "Present a brief scope summary") |
| No extraneous documentation | PASS | No README or installation guide |
| Concise examples over verbose explanations | PASS | Templates are terse; explanations are brief |
| Only novel information | MOSTLY PASS | The "Design Intent (Post-v3 Architecture)" section (lines 18-31) explains architectural rationale. This is useful context but is 14 lines of prose that does not drive agent behavior. It could be moved to a reference document |

### Finding

1. **Design Intent section** (MINOR): Lines 18-31 provide architectural motivation ("CWF v3 moved planning from runtime-specific plan-mode hooks..."). This is valuable for human readers but does not contain actionable instructions for the agent. At 14 lines it is not large, but it is pure rationale, not procedure.
   - **Recommendation**: Move to plan-protocol.md or a dedicated design-notes reference. Replace with a one-line pointer if needed.

**Verdict**: PASS with one minor observation.

---

## Criterion 6: Degrees of Freedom

| Area | Freedom level | Appropriate? | Notes |
|------|--------------|-------------|-------|
| Phase 0 (live state update) | Low (exact script) | YES | Fragile stateful operation; script is correct |
| Phase 1 (parse & scope) | High (text guidance) | YES | Context-dependent scoping; multiple valid approaches |
| Phase 2 (parallel research) | Medium (YAML pseudocode) | YES | Structured sub-agent prompts with flexibility in content |
| Phase 2.4 (persistence gate) | Low (explicit policy) | YES | Critical data integrity gate; strict is correct |
| Phase 3 (plan drafting) | Medium (template + rules) | YES | Template enforces structure; prose within sections is flexible |
| Phase 4 (write artifacts) | Low (script + exact format) | YES | File creation is fragile; script invocation is correct |
| Phase 5 (review offer) | High (suggestion text) | YES | Advisory only; flexibility appropriate |
| Cross-cutting pattern gate | Medium (rule + example) | YES | Pattern detection is context-dependent; rule gives clear threshold (3+ targets) |
| Preparatory refactoring check | Medium (threshold rule) | YES | Clear threshold (300+ lines, 3+ changes) with flexible application |

**Verdict**: PASS -- freedom levels are well-calibrated to task fragility throughout.

---

## Criterion 7: Anthropic Compliance

### Folder naming

| Check | Verdict |
|-------|---------|
| Plugin folder: `cwf` (kebab-case) | PASS |
| Skill folder: `plan` (kebab-case) | PASS |

### Metadata

| Check | Verdict | Detail |
|-------|---------|--------|
| Only `name`, `description` in frontmatter | PASS | No extra fields |
| No XML tags in frontmatter | PASS | Clean |
| `name` matches folder name | PASS | `name: plan`, folder: `plan` |

### Description quality

| Check | Verdict | Detail |
|-------|---------|--------|
| <= 1024 characters | PASS | ~299 chars |
| What + When + Key capabilities | PASS | What: "Agent-assisted plan drafting"; When: triggers listed; Key: "parallel research, BDD success criteria, cwf:review integration" |
| Trigger phrases present | PASS | `cwf:plan`, "plan this task" |
| Differentiates from similar skills | PASS | Mentions specific capabilities (BDD, review integration, plan-impl-review continuity) |

### Composability

| Check | Verdict | Detail |
|-------|---------|--------|
| No duplication of other skills' functionality | PASS | Research is plan-specific (prior art + codebase analysis), not duplicating `gather` |
| Cross-skill references use defensive checks | PASS | Review offer is a suggestion ("For a multi-perspective review... run: cwf:review"), not a hard dependency |
| Output consumable by other skills | PASS | `plan.md` and `lessons.md` are the contract consumed by `impl` and `review` |
| Avoids hard dependencies | PASS | Uses "Consider running" pattern for review |

**Verdict**: PASS -- full compliance.

---

## Criterion 8: Concept Integrity

### Synchronization map row for `plan`

| Concept | Claimed | Implemented? |
|---------|---------|-------------|
| Agent Orchestration | x | Evaluate below |
| Decision Point | x | Evaluate below |

### 8.1 Agent Orchestration

#### Required behavior

| Behavior | Present? | Evidence |
|----------|---------|---------|
| Orchestrator assesses complexity and spawns minimum agents needed | PARTIAL | The skill always spawns exactly 2 sub-agents (Prior Art Researcher, Codebase Analyst). There is no adaptive sizing: the team composition is fixed regardless of task complexity. The context recovery check (2.1) can skip agents whose output already exists, but this is recovery, not adaptive sizing |
| Each agent has distinct, non-overlapping work | PASS | Prior Art Researcher does web research; Codebase Analyst does codebase analysis. Clear separation |
| Parallel execution in batches | PASS | "Launch sub-agents simultaneously using the Task tool" (line 90) |
| Outputs collected, verified, and synthesized | PASS | Phase 2.3 reads output files; Phase 2.4 applies persistence gate; Phase 3 synthesizes into plan |

#### Required state

| State element | Present? | Evidence |
|--------------|---------|---------|
| Work item decomposition | PARTIAL | Phase 1 decomposes into goal/decisions/constraints, but there is no explicit dependency analysis or domain detection for the research agents |
| Agent team composition | PASS | Fixed at 2 agents with clear role assignments |
| Batch execution plan | PASS | Single parallel batch (both agents launched simultaneously) |
| Provenance metadata | NOT PRESENT | Sub-agent prompts do not include provenance tracking instructions (source, tool, duration). The context-recovery protocol checks sentinel markers but does not track provenance metadata per the concept definition |

#### Required actions

| Action | Present? | Evidence |
|--------|---------|---------|
| Decompose into work items | PASS | Phase 1 parse-and-scope |
| Size team adaptively | FAIL | Fixed 2-agent team. No complexity assessment drives team size. For simple tasks (e.g., "add a config field"), launching a Prior Art Researcher may be unnecessary overhead |
| Launch parallel batch | PASS | Phase 2.2 "Launch sub-agents simultaneously" |
| Collect and verify results | PASS | Phase 2.3 + 2.4 (read files + persistence gate) |
| Synthesize outputs | PASS | Phase 3 integrates research into plan |

#### Agent Orchestration findings

1. **No adaptive sizing** (MODERATE): The skill always spawns 2 sub-agents regardless of task complexity. For trivial planning tasks (rename a variable, update a config value), prior art research adds latency and token cost with little value. The concept requires complexity-driven team composition.
   - **Recommendation**: Add a complexity gate after Phase 1. For focused/simple tasks, skip the Prior Art Researcher and run only the Codebase Analyst (or run inline without sub-agents). This aligns with the "Adaptive" pattern in agent-patterns.md.

2. **No provenance metadata** (MINOR): Sub-agent outputs lack `source`, `tool`, `timestamp`, `duration_ms` metadata as defined in agent-patterns.md. The context recovery protocol's sentinel marker is a persistence check, not provenance.
   - **Recommendation**: Add provenance instructions to sub-agent prompts, or document that plan sub-agents are exempt from provenance tracking (and why).

### 8.2 Decision Point

#### Required behavior

| Behavior | Present? | Evidence |
|----------|---------|---------|
| Implicit choices decomposed into concrete questions | PASS | Phase 1 step 2: "What are the key decisions to make?" |
| Each point subjected to evidence gathering before deciding | PASS | Phase 2 research agents gather evidence; Phase 3 instructs "Flag conflicts between best practices and existing code as decision points" (line 269) |
| No ambiguity silently resolved by assumption | PARTIAL | The skill instructs to identify decisions and flag conflicts, but does not have an explicit "no silent resolution" gate or checklist |

#### Required state

| State element | Present? | Evidence |
|--------------|---------|---------|
| Decision point list (question, status) | PARTIAL | Phase 1 captures "Key Decisions" but does not maintain a formal list with open/resolved status |
| Evidence per point (sources, confidence) | PARTIAL | Research agents provide evidence, but there is no explicit mapping of evidence to specific decision points |
| Resolution record (decision, decided-by, evidence cited) | NOT PRESENT | The plan template does not include a "Decision Log" or "Resolved Decisions" section. Decisions are embedded implicitly in the plan steps, not tracked explicitly |

#### Required actions

| Action | Present? | Evidence |
|--------|---------|---------|
| Extract decision points from requirement | PASS | Phase 1 step 2 |
| Attach evidence to points | PARTIAL | Phase 3 "Research Integration" instructs to reference findings, but does not map evidence to specific decision points |
| Resolve points (auto-decide or queue for human) | PARTIAL | Rule 6 says "Preserve task intent: Refine the approach, don't redirect the goal" but there is no explicit T1/T2/T3 classification or human-queue mechanism. The Phase 3 instruction "Flag conflicts" (line 269) implies human queuing but does not formalize it |
| Record resolution with provenance | NOT PRESENT | No decision log section in the plan template |

#### Decision Point findings

1. **No formal decision log** (MODERATE): The concept requires explicit state tracking (decision point list with status, evidence mapping, resolution records). The skill captures decisions informally in Phase 1 ("Key Decisions") and implicitly embeds resolutions in the plan steps, but never maintains a structured decision log. This means decisions can be silently resolved without traceability.
   - **Recommendation**: Add a "Decision Log" section to the required plan template, or add a phase between research and drafting that explicitly resolves each decision point with cited evidence. This could be lightweight:
   ```markdown
   ## Decision Log
   | # | Question | Resolution | Evidence |
   |---|----------|-----------|----------|
   | 1 | ... | ... | ... |
   ```

2. **No human-queue mechanism** (MINOR): The concept's required action "Resolve points (auto-decide or queue for human)" is partially implemented via "Flag conflicts" (line 269) but there is no structured queue. The plan's "Deferred Actions" section could serve this role but is described as "requests received during plan mode that cannot be handled immediately" rather than as a decision-escalation queue.
   - **Recommendation**: Clarify that unresolvable decision points (conflicting evidence, subjective choices) should be listed in a "Decisions for User" subsection or routed to Deferred Actions with a decision-point tag.

### 8.3 Unclaimed concept check

| Concept | Exhibited? | Evidence |
|---------|-----------|---------|
| Expert Advisor | No | No expert roster or contrasting frameworks |
| Tier Classification | No | No T1/T2/T3 classification (though Decision Point partially overlaps) |
| Handoff | No | Plan produces `plan.md` + `lessons.md` but does not generate handoff documents; handoff is a separate skill |
| Provenance | No | No staleness checking of reference documents |

No unclaimed concepts detected. The skill does not exhibit behavior matching concepts it does not claim.

---

## Summary

| Criterion | Verdict | Issues |
|-----------|---------|--------|
| 1. Size | PASS | None |
| 2. Progressive Disclosure | PASS | None |
| 3. Duplication | MINOR | Three instances of internal/cross-file duplication (lessons template, language rule, success criteria format) |
| 4. Resource Health | PASS | None |
| 5. Writing Style | PASS | Design Intent section is rationale-only (minor) |
| 6. Degrees of Freedom | PASS | Well-calibrated throughout |
| 7. Anthropic Compliance | PASS | Full compliance |
| 8. Concept Integrity | MODERATE | Agent Orchestration: no adaptive sizing, no provenance. Decision Point: no formal decision log, no structured resolution tracking |

### Priority recommendations

1. **(MODERATE) Add adaptive sizing gate**: After Phase 1, assess task complexity. For simple/focused tasks, skip Prior Art Researcher or run a single inline analysis instead of spawning 2 sub-agents. This aligns the skill with Agent Orchestration's core principle.

2. **(MODERATE) Add Decision Log to plan template**: Add a lightweight structured section that maps decision points to evidence and resolutions. This closes the Decision Point concept's state-tracking gap without adding significant template weight.

3. **(MINOR) Eliminate internal duplication**: Consolidate the three duplicated elements (lessons template, language rule, success criteria format) to single authoritative locations. This reduces token cost by ~15-20 lines and prevents drift.

4. **(MINOR) Consider moving Design Intent section**: The 14-line architectural rationale block provides no procedural value to the agent. Moving it to plan-protocol.md or a design-notes reference would tighten the skill body.

5. **(MINOR) Add provenance metadata to sub-agent prompts**: Include `source`, `tool`, `timestamp` in sub-agent output instructions per agent-patterns.md, or explicitly document the exemption.

<!-- AGENT_COMPLETE -->
