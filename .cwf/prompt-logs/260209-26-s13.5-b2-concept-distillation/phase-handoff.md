# Phase Handoff: clarify → implementation

> Source phase: clarify (concept distillation + README v3 requirements)
> Target phase: implementation
> Written: 2026-02-09

## Context Files to Read

1. `CLAUDE.md` — project rules and protocols
2. `cwf-state.yaml` — current project state and session history
3. `references/essence-of-software/distillation.md` — Daniel Jackson's concept distillation (the analytical lens)
4. `plugins/cwf/references/skill-conventions.md` — shared structural template for CWF skills
5. `plugins/cwf/skills/*/SKILL.md` — all 9 CWF skills (read frontmatter + phases for concept analysis)
6. `README.md` — current README to rewrite
7. `AI_NATIVE_PRODUCT_TEAM.md` — target audience definition

## Design Decision Summary

### D1: Two-layer concept granularity

CWF concepts are analyzed at two layers:

- **Application concepts** — the 9 skills themselves (gather, clarify, plan, impl, retro, refactor, handoff, setup, update). Each has a purpose, operational principle, and independent state.
- **Generic concepts** — cross-cutting abstractions shared across skills (expert advisor, tier classification, phase handoff, agent patterns, decision points, skill conventions). These are reusable behavioral units that skills synchronize.

Skills are shown as synchronizations (compositions) of generic concepts. This mirrors Jackson's app = molecule, concept = atom model.

### D2: Jackson framework — 5 core elements

Apply these elements from the Essence of Software framework:

1. **Purpose** — each concept's raison d'être, distinct from its specification
2. **Operational Principle** — archetypal scenario showing how the concept fulfills its purpose
3. **Concept Independence** — concepts defined without reference to each other
4. **Synchronization** — how concepts compose in the CWF workflow (clarify→plan→impl→retro)
5. **Specificity** — 1:1 correspondence between purposes and concepts (no redundancy, no overloading)

State/Actions are implicit in existing SKILL.md phases; no separate formalization needed.

### D3: Distillation document location

`prompt-logs/260209-26-s13.5-b2-concept-distillation/concept-distillation.md` — session artifact alongside plan.md and lessons.md. The distillation is an intermediate analysis consumed by the README rewrite; after the README is written, the distillation's role is fulfilled. Permanent location unnecessary — traceable via cwf-state.yaml session history.

### D4: README full rewrite

README.md is fully rewritten around CWF single-plugin structure. Not a philosophy-only addition — the entire document transitions from 9 independent plugins to CWF-centered architecture. Legacy standalone plugins are removed or marked as superseded.

### D5: Target audience

Claude Code users who are part of AI-native product teams. They know Claude Code and the plugin system, but encounter CWF for the first time. The philosophy section explains WHY CWF exists and HOW its concepts compose, before diving into installation and usage.

### D6: Visualization

Markdown tables + text-based hierarchy only. No Mermaid diagrams. Consistent with existing codebase conventions.

## Protocols to Follow

1. **Concept distillation first, README second** — the README philosophy must emerge from the distillation analysis, not be written independently
2. **Jackson's OP format** — each concept's operational principle follows Jackson's if-then narrative pattern: "when X happens, Y results, which fulfills purpose Z"
3. **Two-layer presentation** — distillation document presents generic concepts first (the atoms), then application concepts as their synchronizations (the molecules)
4. **README follows Astro/Rails pattern** — lead with philosophy (why CWF exists), then concepts (what it does), then installation (how to use). Problem-solution framing with honest trade-off acknowledgment
5. **Newcomer-first writing** — every concept explained from purpose, not from implementation. No assumed knowledge of CWF v1/v2 history
6. **Code fences always have language specifiers** — per `.markdownlint.json`
7. **English for all documentation** — README.ko.md update is out of scope

## Do NOT

- Modify individual SKILL.md files (read-only for concept analysis)
- Modify `plugins/cwf/references/expert-advisor-guide.md` or `expert-lens-guide.md` (completed in S13.5-B)
- Modify `scripts/` directory or hook configurations
- Add Mermaid diagrams or any new visualization tooling
- Reference CWF v1/v2 migration history in the README (irrelevant to new users)
- Create README.ko.md (separate session)

## Implementation Hints

### For concept distillation

- **Generic concepts identified so far** (verify and expand during analysis):
  - Expert Advisor — domain expert sub-agents with contrasting frameworks
  - Tier Classification — T1 (codebase) / T2 (best-practice) / T3 (human) decision routing
  - Phase Handoff — WHAT vs HOW separation across workflow stages
  - Agent Patterns — sub-agent orchestration (Single, Adaptive, Agent team, 4 parallel)
  - Decision Points — capture-then-resolve pattern for ambiguity
  - Skill Conventions — structural template ensuring concept familiarity

- **For each concept, produce**: name, purpose (1 sentence), operational principle (1 paragraph), state (key entities), actions (key verbs), which skills synchronize it

- **For synchronization analysis**: map the workflow flow (gather→clarify→plan→impl→retro→refactor) and identify which generic concepts are activated at each stage

### For README rewrite

- **Structure suggestion** (from web research on effective READMEs):
  1. Title + one-line description
  2. Philosophy / Why CWF? (grounded in distillation)
  3. Core Concepts (the generic concepts, briefly)
  4. The Workflow (how skills compose)
  5. Quick Start (installation + first use)
  6. Skill Reference (table + brief per-skill section)
  7. Configuration
  8. License

- Current README is 336 lines. Keep new README similar or shorter — progressive disclosure, details in skill SKILL.md files

- `install.sh` script flags (`--all`, `--workflow`, `--infra`) need updating for CWF single-plugin model

## Success Criteria

```gherkin
Given the 9 CWF skills and Daniel Jackson's Essence of Software framework
When concept distillation is performed with two-layer granularity
Then a document at references/essence-of-software/cwf-concept-distillation.md
  identifies generic concepts, application concepts, their purposes,
  operational principles, and synchronization patterns

Given the concept distillation document
When the README.md is fully rewritten
Then it leads with a philosophy section grounded in the distillation,
  presents CWF as a single integrated plugin,
  and is accessible to a Claude Code user encountering CWF for the first time

Given the rewritten README
When a new user reads the philosophy section
Then they understand what CWF does, why it exists,
  and how its concepts compose into a workflow
  without needing knowledge of CWF v1/v2 history
```
