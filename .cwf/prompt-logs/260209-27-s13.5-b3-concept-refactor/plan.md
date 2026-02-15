# Plan: Concept-Based Refactor Integration (S13.5-B3)

## Handoff Context

**Previous session**: S13.5-B2 (concept distillation + README v3)
**Handoff document**: `prompt-logs/260209-26-s13.5-b2-concept-distillation/next-session.md`
**Session directory**: `prompt-logs/260209-27-s13.5-b3-concept-refactor/`
**Branch**: `feat/concept-refactor-integration` (base: `marketplace-v3`)
**Lessons**: `prompt-logs/260209-27-s13.5-b3-concept-refactor/lessons.md`
**Phase handoff**: `prompt-logs/260209-27-s13.5-b3-concept-refactor/phase-handoff.md`

### Context Files to Read

1. `prompt-logs/260209-27-s13.5-b3-concept-refactor/phase-handoff.md` — **HOW**: protocols, do-nots, implementation hints
2. `prompt-logs/260209-27-s13.5-b3-concept-refactor/lessons.md` — session lessons (11 items, accumulated during planning)
3. `CLAUDE.md` — project rules and protocols
4. `cwf-state.yaml` — session history and project state
5. `prompt-logs/260209-26-s13.5-b2-concept-distillation/concept-distillation.md` — 6 generic + 9 application concepts, synchronization map
6. `plugins/cwf/skills/refactor/SKILL.md` — current refactor skill (deep review + holistic modes)
7. `plugins/cwf/skills/refactor/references/review-criteria.md` — deep review criteria (8 criteria, 2 agents)
8. `plugins/cwf/skills/refactor/references/holistic-criteria.md` — holistic analysis (3 dimensions, 3 agents)
9. `plugins/cwf/references/skill-conventions.md` — shared conventions checklist

## Context

S13.5-B2 applied Jackson's Essence of Software to analyze CWF into 6 generic
concepts and a 9×6 synchronization map. The next-session.md proposed integrating
this into refactor's quality detection via 3 integration points:
1. Deep Review: Concept Integrity criterion
2. Holistic: Synchronization Analysis dimension (4th)
3. Concept Map reference document

During planning, full orthogonality analysis revealed that neither the existing
holistic dimensions nor the proposed additions are orthogonal. This expanded the
scope from "add concept analysis" to "restructure both frameworks with concept
analysis as the organizing opportunity."

## Orthogonality Analysis Results

### Holistic: Existing 3 dimensions are NOT orthogonal

| Overlap | Evidence |
|---------|----------|
| PP 1c ↔ BI | "3+ skills repeat pattern → extract" and "skills partially duplicate functionality" detect same phenomenon |
| MC re-implementation ↔ BI | "internal research when another skill provides" is both boundary issue and missing connection |
| BI ↔ MC general | Same inter-skill relationship space, inverse poles (too much overlap vs too little connection) |

### Deep Review: Criteria 4 and 5 overlap

Criterion 4 "Reference file not mentioned in SKILL.md → Unused" is a subset of
Criterion 5 "files in scripts/, references/, assets/ not referenced." Same check,
different scope.

### Proposed 4th holistic dimension: NOT orthogonal

Synchronization Analysis decomposes into existing dimensions:
- Concept consistency → Pattern Propagation
- Over-synchronization → Boundary Issues
- Under-synchronization → Missing Connections

## Design: Restructured Frameworks

### Holistic: Form / Meaning / Function (3 axes, 3 agents)

Replace existing 3 dimensions with principled decomposition based on semiotic axes:

**Axis 1 — Convention Compliance (Form)**
- Does each skill follow shared structural templates?
- Sources from: existing PP 1a (convention checklist) + PP 1b (pattern gaps)
- Focus: individual skill structural consistency
- Input: `skill-conventions.md`

**Axis 2 — Concept Integrity (Meaning)**
- Does each skill implement its claimed concepts correctly?
- Are skills sharing a concept consistent in implementation?
- Under/over-synchronization detection
- Sources from: existing PP 1c (behavioral extraction) + existing BI (functional duplication as concept overlap) + NEW concept analysis
- Input: `concept-map.md` + individual SKILL.md files

**Axis 3 — Workflow Coherence (Function)**
- Do skills connect properly in the workflow?
- Are triggers unambiguous? Are data flows complete?
- Sources from: existing MC (output→input, manual invocation, hook bridging) + existing BI (trigger ambiguity, hook conflicts)
- Input: condensed inventory map

Existing "Boundary Issues" is dissolved: concept overlap → Axis 2, trigger/role clarity → Axis 3.

### Deep Review: Merge 4+5, add Concept Integrity → 8 criteria, 4+4 agents

| # | Criterion | Change | Agent |
|---|-----------|--------|-------|
| 1 | Size | unchanged | A (Structural) |
| 2 | Progressive Disclosure | unchanged | A |
| 3 | Duplication | unchanged | A |
| 4 | **Resource Health** | merged old 4+5 | A |
| 5 | Writing Style | renumbered from 6 | B (Quality+Concept) |
| 6 | Degrees of Freedom | renumbered from 7 | B |
| 7 | Anthropic Compliance | renumbered from 8; Composability kept with note | B |
| 8 | **Concept Integrity** | NEW | B |

Agent A: Structural (1-4). Agent B: Quality+Concept (5-8). Balanced 4+4.

## Implementation Steps

### Step 1: Create `plugins/cwf/references/concept-map.md` (NEW)

Distill from `concept-distillation.md` sections 2 and 4:

```text
# Concept Synchronization Map

## 1. Generic Concepts
  ### 1.1–1.6: Each concept with purpose, required behavior, required state, required actions
  (Verification-friendly format extracted from operational principles)

## 2. Synchronization Map (9×6 table)

## 3. Usage Guide
  ### For Deep Review (Criterion 8: Concept Integrity)
  ### For Holistic Analysis (Axis 2: Concept Integrity)
```

### Step 2: Create `plugins/cwf/references/concept-map.provenance.yaml` (NEW)

```yaml
target: concept-map.md
written_session: S13.5-B3
last_reviewed: S13.5-B3
skill_count: 9
hook_count: 13
designed_for:
  - "6 generic concepts with verification criteria for refactor analysis"
  - "9x6 synchronization map for deep review and holistic modes"
```

### Step 3: Restructure `plugins/cwf/skills/refactor/references/holistic-criteria.md`

Replace existing 3 sections with:

```text
## 1. Convention Compliance (Form)
  ### 1a. Convention checklist verification (from old PP 1a)
  ### 1b. Pattern gaps (from old PP 1b)
  ### 1c. Structural extraction opportunities (from old PP 1c, structural subset)

## 2. Concept Integrity (Meaning)
  ### 2a. Per-concept implementation consistency (NEW — concept-map.md based)
  ### 2b. Under-synchronization detection (NEW — sparse sync map rows)
  ### 2c. Over-synchronization / concept overloading detection (from old BI functional duplication)

## 3. Workflow Coherence (Function)
  ### 3a. Data flow completeness (from old MC output→input)
  ### 3b. Trigger clarity (from old BI trigger ambiguity + hook conflicts)
  ### 3c. Workflow automation opportunities (from old MC manual invocation + hook bridging)
```

### Step 4: Restructure `plugins/cwf/skills/refactor/references/review-criteria.md`

- Merge criteria 4+5 into "4. Resource Health"
- Renumber 6→5, 7→6, 8→7
- Add "8. Concept Integrity" with verification table
- Add note in 7.Composability: "see holistic Axis 2 for rigorous cross-skill analysis"

### Step 5: Update `plugins/cwf/skills/refactor/SKILL.md`

**Deep Review mode:**
- Agent A: criteria 1-4 (Structural)
- Agent B: criteria 5-8 (Quality+Concept), receives `concept-map.md`
- Update prompts and criteria range references

**Holistic mode:**
- Agent A: Axis 1 (Convention Compliance), receives `skill-conventions.md`
- Agent B: Axis 2 (Concept Integrity), receives `concept-map.md`
- Agent C: Axis 3 (Workflow Coherence), receives inventory map
- Update prompts, dimension names, and inputs
- Keep 3-agent count

**Rules section:**
- Update rule 3: agent descriptions
- Update rule 4: dimension names

**References section:**
- Add concept-map.md link

### Step 6: Update provenance sidecars

- `holistic-criteria.provenance.yaml`: update `last_reviewed`, update `designed_for` to reflect restructured dimensions
- `review-criteria.provenance.yaml`: update `last_reviewed`

## Files Summary

| File | Action | What changes |
|------|--------|-------------|
| `plugins/cwf/references/concept-map.md` | NEW | Concept definitions + sync map + usage guide |
| `plugins/cwf/references/concept-map.provenance.yaml` | NEW | Provenance sidecar |
| `plugins/cwf/skills/refactor/references/holistic-criteria.md` | REWRITE | 3 pragmatic → 3 principled dimensions (Form/Meaning/Function) |
| `plugins/cwf/skills/refactor/references/review-criteria.md` | RESTRUCTURE | Merge 4+5, renumber, add Concept Integrity as criterion 8 |
| `plugins/cwf/skills/refactor/SKILL.md` | EDIT | Update agent prompts, criteria ranges, dimension names, references |
| `plugins/cwf/skills/refactor/references/holistic-criteria.provenance.yaml` | EDIT | last_reviewed + designed_for |
| `plugins/cwf/skills/refactor/references/review-criteria.provenance.yaml` | EDIT | last_reviewed |

## Success Criteria

```gherkin
Given the restructured holistic-criteria.md with Form/Meaning/Function axes
When refactor --holistic runs cross-plugin analysis
Then 3 agents analyze Convention Compliance, Concept Integrity, and Workflow Coherence respectively
  And no finding legitimately belongs in two dimensions simultaneously

Given the restructured review-criteria.md with 8 criteria (merged 4+5, added Concept Integrity)
When refactor --skill <name> runs deep review
Then Agent A evaluates criteria 1-4 (Structural)
  And Agent B evaluates criteria 5-8 (Quality+Concept)
  And Criterion 8 verifies claimed concept composition against implementation

Given concept-map.provenance.yaml with skill_count=9
When a 10th skill is added to CWF
Then provenance-check.sh detects staleness in concept-map.md
```

## Verification

1. `bash scripts/provenance-check.sh` — concept-map appears as FRESH
2. Markdown lint on all modified .md files — 0 errors
3. SKILL.md stays under 500 lines after edits
4. Dry-run: mentally trace holistic Agent B (Concept Integrity) for clarify
   — should identify 4 synchronized concepts and compare Expert Advisor
   implementation with retro's
5. Dry-run: mentally trace deep review Agent B for gather
   — should identify 1 synchronized concept (Agent Orchestration) and verify
   adaptive sizing
6. Cross-check: no holistic finding should legitimately belong in two axes

## Deferred Actions

- [x] `/ship issue` after plan approval — deferred; hook infra took priority
- [x] Copy this plan to session directory — already in place
- [x] ExitPlanMode PostToolUse hook (exit-plan-mode.sh) — **built in this session**

## Session Status

**This plan is approved but NOT YET IMPLEMENTED.** Implementation was deferred
because the ExitPlanMode hook infrastructure was prioritized (S13.5-B3 detour).

**To resume implementation**: read this plan from the top. The Context Files to Read
section (especially phase-handoff.md and lessons.md) contains everything needed.
All 6 implementation steps remain pending. No files in the Files Summary have been
modified yet.

**Hook infra completed in this session**:
- `plugins/cwf/hooks/scripts/exit-plan-mode.sh` — PostToolUse hook for ExitPlanMode
- `plugins/cwf/hooks/hooks.json` — registered the hook
- Provenance hook_count changed: 13 → 14 (all provenance sidecars need update)
