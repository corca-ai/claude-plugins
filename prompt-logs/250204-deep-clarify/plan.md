# deep-clarify: Research-First Requirement Clarification

## Summary

New plugin `deep-clarify` — a research-first alternative to `clarify`. Instead of
asking the user about all ambiguities (clarify v1 approach), deep-clarify autonomously
researches via codebase exploration and best practice analysis, then only asks humans
about genuinely subjective decisions — with informed advisory opinions from two
opposing perspectives. The existing `clarify` plugin remains unchanged.

## Success Criteria

```gherkin
Given a vague requirement like "Add authentication to the app"
When the user triggers /deep-clarify
Then the agent decomposes the requirement into decision points,
  launches two parallel sub-agents (codebase + best practice),
  makes autonomous decisions for items with clear evidence,
  and only asks the human about genuinely subjective items.

Given a project using JWT auth with Express middleware
When clarifying "Add a logout feature"
Then the codebase researcher finds JWT + Express patterns,
  the agent autonomously decides to follow existing patterns,
  and reports this decision with file-path evidence.

Given conflicting evidence (codebase uses pattern X, best practice says Y)
When aggregating sub-agent results
Then the conflict is surfaced as a Tier 3 item and the human is asked to decide.

Given all ambiguities are resolvable via research
When no Tier 3 items exist
Then Phase 3.5 and Phase 4 are skipped entirely.

Given a Tier 3 item about choosing between REST vs GraphQL
When advisory sub-agents are launched
Then Advisor α argues for one side with reasoning,
  Advisor β argues for the other side with reasoning,
  and the human receives both perspectives alongside the question.

Given the best practice researcher finds sources by Martin Fowler on the topic
When reasoning about recommendations
Then the researcher explicitly adopts Fowler's documented perspective
  (grounded in published work, not fabricated positions).
```

## Architecture

```
User triggers /deep-clarify "Add auth to the app"
         │
    Phase 1: Capture & Decompose
    (list decision points)
         │
    Phase 2: Fan-out ──┬── Sub-agent A: Codebase Researcher
                       │   (Glob, Grep, Read → evidence per decision point)
                       │
                       └── Sub-agent B: Best Practice Researcher
                           (WebSearch → find sources → identify named experts
                            → reason from their published perspectives)
         │
    Phase 3: Aggregate & Classify
    (Tier 1: codebase-resolved, Tier 2: best-practice-resolved, Tier 3: ask human)
         │
    Phase 3.5: Advisory (Tier 3 items only, skip if empty)
    Fan-out ──┬── Advisor α: argues one perspective
              └── Advisor β: argues the opposing perspective
         │
    Phase 4: Human Questions (Tier 3 only, with advisory opinions attached)
         │
    Phase 5: Output (decisions table + clarified spec + save option)
```

## File Changes

### New files

| File | Purpose |
|------|---------|
| `plugins/deep-clarify/.claude-plugin/plugin.json` | Plugin metadata (v1.0.0) |
| `plugins/deep-clarify/skills/deep-clarify/SKILL.md` | 6-phase orchestrator (~270 lines) |
| `plugins/deep-clarify/skills/deep-clarify/references/codebase-research-guide.md` | Sub-agent A instructions (~70 lines) |
| `plugins/deep-clarify/skills/deep-clarify/references/bestpractice-research-guide.md` | Sub-agent B instructions (~80 lines) |
| `plugins/deep-clarify/skills/deep-clarify/references/aggregation-guide.md` | Tier classification rules + output format (~80 lines) |
| `plugins/deep-clarify/skills/deep-clarify/references/advisory-guide.md` | Tier 3 advisory sub-agent instructions (~60 lines) |

### Modified files

| File | Change |
|------|--------|
| `.claude-plugin/marketplace.json` | Add deep-clarify entry, bump metadata version |
| `README.md` | Add deep-clarify to table + detail section |
| `README.ko.md` | Same changes in Korean |

### Unchanged files

| File | Note |
|------|------|
| `plugins/clarify/` (entire directory) | v1 stays as-is, no modifications |

## Detailed Design

### SKILL.md (~270 lines)

**Frontmatter:**
```yaml
---
name: deep-clarify
description: |
  Research-first requirement clarification. Autonomously resolves ambiguities
  through codebase exploration and best practice research. Only asks the human
  about genuinely subjective decisions — with informed advisory opinions.
  Triggers: "/deep-clarify", or when requirements need deep clarification.
allowed-tools:
  - Task
  - Read
  - Glob
  - Grep
  - Write
  - AskUserQuestion
---
```

**Phase 1: Capture & Decompose** — Record requirement verbatim, list concrete
decision points (questions, not categories). This list drives Phase 2.

**Phase 2: Parallel Research** — Launch two sub-agents simultaneously via Task tool
(`subagent_type: general-purpose`):
- Sub-agent A reads `{SKILL_DIR}/references/codebase-research-guide.md`, explores
  codebase with Glob/Grep/Read, reports evidence per decision point
- Sub-agent B reads `{SKILL_DIR}/references/bestpractice-research-guide.md`:
  1. Searches web for authoritative sources per decision point
  2. Identifies 2-3 named experts who have published on the topic
  3. Reasons from those experts' documented perspectives (grounded in actual work)

**Phase 3: Aggregate & Classify** — Read `{SKILL_DIR}/references/aggregation-guide.md`.
For each decision point, classify using the guiding principle:

> If you could arrive at a defensible answer through codebase exploration or best
> practice research, make the decision yourself. Only ask the human when reasonable
> people could disagree and no external evidence would settle it.

Classification rules:
- **Tier 1**: Codebase has clear evidence → decide, cite file paths
- **Tier 2**: Best practice has clear consensus (codebase silent) → decide, cite sources
- **Tier 3**: Evidence conflicts, both silent, or inherently subjective → queue for advisory + human

**Constructive tension**: When codebase and best practice conflict, that tension
itself is Tier 3 — present both sides to the human.

**Phase 3.5: Advisory** — If Tier 3 items exist, launch two advisory sub-agents
in parallel via Task tool (`subagent_type: general-purpose`):
- Both read `{SKILL_DIR}/references/advisory-guide.md`
- Both receive: the Tier 3 decision points + all research context from Phase 2
- Advisor α: assigned to argue for one perspective (the guide instructs how to pick)
- Advisor β: assigned to argue for the opposing perspective
- Each returns: a concise position statement with reasoning for each Tier 3 item
- If zero Tier 3 items, skip this phase entirely.

The advisory opinions are NOT decisions — they are informed perspectives to help
the human decide. The value is in the constructive difference between the two.

**Phase 4: Human Questions** — AskUserQuestion for Tier 3 items only. Each question
includes:
- The research context from Phase 2 (what codebase shows, what best practice says)
- Advisory α's position and reasoning
- Advisory β's position and reasoning
- The question itself with options

**Phase 5: Output** — Structured summary:
1. Agent decisions table (Tier + decision + evidence)
2. Human decisions table (with advisory context that informed the choice)
3. Clarified requirement spec (Goal, Scope, Constraints, Key Decisions)
4. Save-to-file option

### Sub-agent Reference Guides

Each guide follows the pattern established by `suggest-tidyings/references/tidying-guide.md`
(at `plugins/suggest-tidyings/skills/suggest-tidyings/references/tidying-guide.md`):
role statement → context → methodology → constraints → output format.

**codebase-research-guide.md** (~70 lines): Instructs sub-agent to explore project
structure, find relevant patterns/conventions/implementations, report evidence +
confidence level per decision point. Reports evidence, does NOT make final decisions.

**bestpractice-research-guide.md** (~80 lines): Instructs sub-agent to:
1. Search web for authoritative sources per decision point
2. Identify 2-3 **named, real experts** who have published/spoken on the topic
3. Reason from those experts' **documented** perspectives — grounded in actual
   published work, not fabricated positions
4. Report: sources found, experts identified, each expert's likely position
   (with citation), overall consensus level, noted disagreements
Uses WebSearch directly (web-search plugin hook redirect is transparent if present).

**Why named experts?** LLMs produce more specific, distinctive outputs when reasoning
from a named expert's perspective vs. a generic "domain expert" role. The key
constraint is grounding: the guide explicitly requires citing published work to
prevent hallucinating positions.

**aggregation-guide.md** (~80 lines): Contains the guiding principle (verbatim),
classification rules (Tier 1/2/3 conditions), conflict handling instructions, and
the output format for the final summary. This is the most critical reference file —
it encodes the decision-making philosophy without enumerating examples.

**advisory-guide.md** (~60 lines): Instructs advisory sub-agents for Tier 3 items.
- Role: "You are an advisor presenting one perspective on a subjective decision."
- Each advisor is assigned a side (α = first perspective, β = opposing perspective)
- Methodology: build the strongest honest case for your assigned perspective,
  acknowledge trade-offs, do NOT strawman the other side
- Output format per Tier 3 item: position statement (1-2 sentences), key arguments
  (2-3 bullets), acknowledged trade-offs (1-2 bullets)
- Constraint: present informed opinions, not decisions. The human decides.

### Relationship to clarify v1

`deep-clarify` is a new, independent plugin. `clarify` remains unchanged.
Users choose based on need:
- `/clarify` — quick, lightweight, asks about all ambiguities
- `/deep-clarify` — thorough, autonomous research first, asks only subjective items

## Implementation Sequence

1. [ ] Create `plugins/deep-clarify/.claude-plugin/plugin.json`
2. [ ] Write reference guides in `plugins/deep-clarify/skills/deep-clarify/references/`:
   - `codebase-research-guide.md`
   - `bestpractice-research-guide.md`
   - `aggregation-guide.md`
   - `advisory-guide.md`
3. [ ] Write `plugins/deep-clarify/skills/deep-clarify/SKILL.md` (6-phase orchestrator)
4. [ ] Update `.claude-plugin/marketplace.json` (add deep-clarify, bump version)
5. [ ] Update `README.md` and `README.ko.md`
6. [ ] Test locally: `claude --plugin-dir ./plugins/deep-clarify --dangerously-skip-permissions --resume`

## Verification

1. **Structure check**: Confirm SKILL.md < 500 lines, all reference guides < 100 lines each
2. **Local test**: Install plugin, trigger `/deep-clarify "Add user authentication"` on a
   sample project, verify Phase 2 sub-agents launch in parallel
3. **Tier classification**: Verify that codebase-evident decisions are auto-resolved,
   best-practice decisions cite sources and named experts, only subjective items go to Phase 3.5+4
4. **Advisory test**: Verify Phase 3.5 launches two advisors for Tier 3 items,
   each presenting a different perspective with reasoning
5. **Edge case — zero Tier 3**: Test with a highly constrained requirement where
   everything is resolvable; confirm Phase 3.5 and Phase 4 are both skipped
6. **Edge case — conflict**: Test where codebase pattern conflicts with best practice;
   confirm advisors argue both sides, human receives full context
7. **Expert grounding**: Verify best practice researcher cites actual published work,
   not fabricated expert positions
8. **Coexistence**: Confirm `clarify` (v1) is unaffected by `deep-clarify` installation

## Deferred Actions

- [ ] Adaptive mode: auto-detect requirement complexity to decide whether sub-agents
  are needed (noted during design discussion, deferred to future iteration)
- [ ] Dynamic sub-agent count: split best practice research by domain (e.g., security,
  performance, UX each get their own researcher) based on Phase 1 decomposition
  (discussed, deferred — requires knowing domains before research begins)

## Prior Art

- **Levels of Autonomy for AI Agents** (Knight First Amendment Institute): Defines L1-L5
  autonomy levels. deep-clarify operates at ~L3 — agent acts autonomously but surfaces
  decisions for human override. Relevant insight: autonomy level should match task
  complexity, not be fixed.
- **suggest-tidyings plugin**: Established the fan-out sub-agent pattern in this codebase
  (Task tool with `subagent_type: general-purpose`, parallel dispatch, aggregation).
