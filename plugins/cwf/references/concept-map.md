# Concept Synchronization Map

<!-- Provenance: written at 9 skills, 14 hooks (S13.5-B3). Source: concept-distillation.md -->

Reference for refactor agents: 6 generic concepts with verification criteria, and a 9×6
synchronization map showing which concepts each skill composes.

## 1. Generic Concepts

Six reusable behavioral abstractions. Each is independently definable — understanding
one requires no knowledge of the others.

### 1.1 Expert Advisor

**Purpose**: Reduce blind spots by introducing contrasting expert frameworks into decision-making.

**Required Behavior**:

- Two domain experts with contrasting analytical frameworks evaluate independently
- Disagreements surface assumptions a single perspective would miss
- Agreements provide high-confidence signals

**Required State**:

- Expert roster (name, domain, framework, usage history)
- Expert pair assignment (alpha/beta, contrasting frameworks)
- Analysis output per expert

**Required Actions**:

- Select experts (match domain, ensure contrast)
- Launch parallel analysis (independent evaluation)
- Synthesize tension (surface agreements and disagreements)
- Update roster (track usage, propose additions)

### 1.2 Tier Classification

**Purpose**: Route decisions to the right authority — evidence for what evidence can resolve, humans for what requires judgment.

**Required Behavior**:

- Each decision point is classified by evidence strength
- T1 (codebase signals): agent decides autonomously
- T2 (published consensus): agent decides with citations
- T3 (conflicting/absent/subjective): queued for human

**Required State**:

- Decision point list (questions from requirements)
- Evidence map (codebase, web, expert per point)
- Tier assignment (T1/T2/T3 per point with rationale)

**Required Actions**:

- Decompose requirement into decision points
- Gather evidence (codebase, web, experts)
- Classify tier (apply evidence strength rules)
- Auto-decide T1/T2 (cite evidence)
- Queue T3 for human (present with advisory context)

### 1.3 Agent Orchestration

**Purpose**: Parallelize work across specialized sub-agents without sacrificing quality or coordination.

**Required Behavior**:

- Orchestrator assesses complexity and spawns minimum agents needed
- Each agent has distinct, non-overlapping work
- Parallel execution in batches (respecting dependencies)
- Outputs are collected, verified, and synthesized

**Required State**:

- Work item decomposition (steps, files, domains, dependencies)
- Agent team composition (count, pattern, assignments)
- Batch execution plan (parallel groups, sequential dependencies)
- Provenance metadata (source, tool, duration per output)

**Required Actions**:

- Decompose into work items (dependency analysis, domain detection)
- Size team adaptively (Single / Adaptive / Agent team / 4 parallel)
- Launch parallel batch (multiple Task calls in single message)
- Collect and verify results (completeness, failure handling)
- Synthesize outputs (merge perspectives, resolve conflicts)

### 1.4 Decision Point

**Purpose**: Capture ambiguity explicitly so it can be resolved with evidence rather than guesswork.

**Required Behavior**:

- Implicit choices are decomposed into concrete questions
- Each point is subjected to evidence gathering before deciding
- No ambiguity is silently resolved by assumption

**Required State**:

- Decision point list (question, status: open/resolved)
- Evidence per point (sources, confidence levels)
- Resolution record (decision, decided-by, evidence cited)

**Required Actions**:

- Extract decision points from requirement/task
- Attach evidence to points (research, codebase, experts)
- Resolve points (auto-decide or queue for human)
- Record resolution with provenance

### 1.5 Handoff

**Purpose**: Preserve context across session and phase boundaries so work can continue without re-discovery.

**Required Behavior**:

- Session handoffs (`next-session.md`) carry task scope, lessons, unresolved items
- Phase handoffs (`phase-handoff.md`) carry HOW context (protocols, rules, constraints)
- The plan carries WHAT; the handoff carries HOW

**Required State**:

- Session artifacts (plan.md, lessons.md, retro.md, phase-handoff.md)
- Unresolved items (deferred actions, unimplemented proposals, retro action items)
- Project state (cwf-state.yaml — stages, session history, expert roster)

**Required Actions**:

- Scan session artifacts for context worth preserving
- Propagate unresolved items to next session
- Generate handoff document (session or phase variant)
- Register session in project state

### 1.6 Provenance

**Purpose**: Detect when analytical criteria or reference guides have become stale relative to the current system state.

**Required Behavior**:

- Reference documents encode assumptions about system state at creation time
- Before applying a document, agent checks whether system has changed significantly
- Significant changes are flagged before proceeding

**Required State**:

- Provenance metadata per reference (system state at creation time)
- Current system state (skill count, hook groups, architecture)
- Staleness delta (what changed since creation)

**Required Actions**:

- Attach provenance to reference documents
- Check provenance against current state before applying
- Flag significant deltas to user
- Trigger reference update when staleness exceeds threshold

## 2. Synchronization Map

Which generic concepts each skill composes:

| Skill | Expert Advisor | Tier Classification | Agent Orchestration | Decision Point | Handoff | Provenance |
|-------|:-:|:-:|:-:|:-:|:-:|:-:|
| gather | | | x | | | |
| clarify | x | x | x | x | | |
| plan | | | x | x | | |
| impl | | | x | | x | |
| retro | x | | x | | | |
| refactor | | | x | | | x |
| handoff | | | | | x | |
| setup | | | | | | |
| update | | | | | | |

**Reading the map**:

- **Row** = one skill's concept composition (its molecule)
- **Column** = one concept's reach across the system (its reuse)
- **Sparse row** (setup, update) = infrastructure skill, no generic concept synchronization
- **Dense row** (clarify) = complex skill composing many concepts
- **Dense column** (Agent Orchestration) = pervasive concept reused across most skills

## 3. Usage Guide

### For Deep Review (Criterion 8: Concept Integrity)

Per-skill verification. Given a target skill:

1. Look up the skill's **row** in the synchronization map
2. For each `x` in that row, read the corresponding concept in Section 1
3. Verify against the SKILL.md:
   - Does the skill implement the concept's **required behavior**?
   - Does the skill maintain the concept's **required state**?
   - Does the skill perform the concept's **required actions**?
4. Flag gaps: concept claimed in map but not implemented, or implemented incorrectly

**Example**: Deep reviewing `gather` → row shows Agent Orchestration only → verify
adaptive sizing, parallel batch, output synthesis in gather's SKILL.md.

### For Holistic Analysis (Axis 2: Concept Integrity)

Cross-skill verification. Given the full inventory:

1. For each concept **column**, collect all skills with `x`
2. Compare how each skill implements the same concept:
   - Are implementations consistent? (e.g., all Expert Advisor users select from the same roster)
   - Is any skill under-synchronized? (implements concept but misses required actions)
   - Is any skill over-synchronized? (overloads the concept with extra purposes)
3. Check for concept overloading: a skill using one concept for two distinct purposes
4. Check for missing synchronization: a skill that should compose a concept but doesn't

**Example**: Column "Expert Advisor" → clarify, retro, review all compose it →
verify they all select from `expert_roster`, use contrasting frameworks, and synthesize
tension. If one uses experts without contrast, flag as under-synchronized.
