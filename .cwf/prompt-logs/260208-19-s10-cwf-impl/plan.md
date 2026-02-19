# S10: Build cwf:impl Skill

## Context

cwf:impl is the next skill in the CWF v3 build sequence (S10). It's the
implementation orchestration skill that takes a plan.md (from cwf:plan) and
autonomously decomposes it into parallelizable work items, spawns domain-appropriate
agents, and verifies completion against the plan's BDD success criteria.

This is the transition from interactive stages (gather → clarify → plan) to
autonomous stages (impl → review → retro). The plan is the fixed contract.

Session dir: `prompt-logs/260208-19-s10-cwf-impl/`
Branch: `marketplace-v3` (current)

## Goal

Create `plugins/cwf/skills/impl/SKILL.md` and `plugins/cwf/skills/impl/references/agent-prompts.md`
that orchestrate agent-assisted implementation from a plan.

## Files to Create

| File | Purpose |
|------|---------|
| `plugins/cwf/skills/impl/SKILL.md` | Main skill definition (~300 lines) |
| `plugins/cwf/skills/impl/references/agent-prompts.md` | Agent prompt template + decomposition heuristics (~150 lines) |
| `prompt-logs/260208-19-s10-cwf-impl/plan.md` | This plan (copy) |
| `prompt-logs/260208-19-s10-cwf-impl/lessons.md` | Session learnings |

## Design Decisions

### 1. Four Phases (not 5 or 6)

Tailored to impl's core value — IMPLEMENTATION ORCHESTRATION (S9 lesson: don't copy phases mechanically):

| Phase | Purpose |
|-------|---------|
| **1: Load Plan** | Find plan.md, extract sections (Steps, Files, BDD criteria, Don't Touch) |
| **2: Analyze & Decompose** | Identify domains, map dependencies, group into work items, size team |
| **3: Execute** | 3a (direct) for simple plans, 3b (agent team) for complex ones |
| **4: Verify & Suggest Review** | Check BDD criteria coverage, present summary, suggest cwf:review --mode code |

### 2. Task Tool (not TeamCreate)

All existing CWF skills use Task tool for sub-agents. TeamCreate adds messaging/coordination overhead that's unnecessary when the main session can directly read Task return values. Consistent with cwf:plan, cwf:clarify, cwf:review patterns.

### 3. Adaptive Team Sizing

From agent-patterns.md: "Avoid spawning agents that will idle."

| Work items | Agents | Strategy |
|------------|--------|----------|
| 1 (≤3 files) | 0 | Direct execution in main session (Phase 3a) |
| 2-3 | 2 | Group related items per agent |
| 4-6 | 3 | Balance parallelism vs coordination |
| 7+ | 4 (hard cap) | Beyond 4, overhead exceeds gains |

### 4. One Reference File

`references/agent-prompts.md` contains the implementation agent prompt template,
domain signal table, and dependency detection heuristics. Keeps SKILL.md under 500
lines while externalizing the longest content. (cwf:plan had zero reference files;
cwf:clarify has four — one is right for impl's moderate complexity.)

## Steps

### Step 1: Create session directory and plan artifacts ✅

- `mkdir -p prompt-logs/260208-19-s10-cwf-impl/`
- Write plan.md and lessons.md

### Step 2: Create SKILL.md ✅

- Path: `plugins/cwf/skills/impl/SKILL.md`
- Frontmatter: name, description, allowed-tools (Task, Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion)
- Phase 1: Load Plan — plan discovery (most recent `prompt-logs/*/plan.md`), section extraction, user confirmation
- Phase 2: Analyze & Decompose — domain signals table, step-to-domain mapping, dependency analysis, work item grouping, adaptive sizing, decomposition presentation
- Phase 3a: Direct Execution — simple plan path (1 item, ≤3 files)
- Phase 3b: Agent Team Execution — prompt construction (ref agent-prompts.md), parallel Task launches in single message, sequential batch handling, result collection
- Phase 4: Verify & Suggest Review — BDD criteria checklist, completion summary template, uncovered criteria handling, review suggestion
- Rules section (7-8 rules)
- References section

### Step 3: Create agent-prompts.md reference ✅

- Path: `plugins/cwf/skills/impl/references/agent-prompts.md`
- Implementation Agent Prompt Template (with placeholders)
- Domain Signal Table (file patterns → domain → agent expertise description)
- Dependency Detection Heuristics (file overlap, output references, ordering keywords)
- Simple Plan Detection heuristic

### Step 4: Post-implementation workflow

- Update lessons.md with implementation learnings
- Run `/retro`
- Run `scripts/check-session.sh`

## Don't Touch

- `plugins/cwf/skills/plan/` — plan skill (created in S9)
- `plugins/cwf/skills/clarify/` — clarify skill (created in S8)
- `plugins/cwf/skills/gather/` — gather skill (created in S7)
- `plugins/cwf/hooks/` — hook definitions
- `plugins/plan-and-lessons/` — keep intact until S14

## Success Criteria

### Behavioral (BDD)

```gherkin
Given a plan.md exists in prompt-logs/
When the user invokes cwf:impl
Then the skill finds and loads the most recent plan.md

Given cwf:impl has loaded a plan
When it analyzes the plan content
Then domain experts are identified from file patterns and step descriptions

Given cwf:impl has identified work items
When dependencies are analyzed
Then parallel-safe items are grouped separately from sequential dependencies

Given a simple plan (1 step, ≤3 files)
When cwf:impl runs
Then it executes directly without spawning sub-agents

Given a complex plan (4+ steps)
When cwf:impl spawns agents
Then each agent receives only its assigned work items, files, and relevant BDD criteria

Given implementation completes
When cwf:impl verifies against plan criteria
Then each BDD criterion is marked as covered or uncovered

Given cwf:impl finishes verification
When presenting results
Then cwf:review --mode code is suggested
```

### Qualitative

- SKILL.md follows existing CWF skill patterns (frontmatter, phases, rules, references)
- Phase structure reflects impl's orchestration purpose, not copied from plan/clarify
- Agent prompts are specific enough to produce useful implementation, not generic
- Adaptive sizing genuinely prevents idle agents

## Verification

1. Read SKILL.md — verify < 500 lines, frontmatter correct, 4 phases present
2. Read agent-prompts.md — verify template has all placeholders, domain table complete
3. Compare structure with cwf:plan SKILL.md — confirm phases are tailored (not copied)
4. Check markdown lint: no bare code fences, nested fences use 4-backtick
