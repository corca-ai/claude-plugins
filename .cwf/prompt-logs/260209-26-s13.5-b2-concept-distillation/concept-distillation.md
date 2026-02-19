# CWF Concept Distillation

> Analytical framework: Daniel Jackson, *The Essence of Software* (2021)
> Subject: CWF (Corca Workflow Framework) — 9 skills, 7 hook groups, 1 plugin
> Date: 2026-02-09

## 1. Framework Summary

Jackson argues that software quality hinges on its **conceptual design** — the
abstract behavioral units users interact with. Five elements define this design:

| Element | Application to CWF |
|---------|-------------------|
| **Purpose** | Each concept has exactly one reason to exist, distinct from its specification |
| **Operational Principle** | An archetypal if-then narrative showing how the concept fulfills its purpose |
| **Concept Independence** | Every concept is understandable without reference to any other |
| **Synchronization** | Skills compose generic concepts — the app is a molecule, concepts are atoms |
| **Specificity** | 1:1 correspondence between purposes and concepts — no redundancy, no overloading |

CWF's design is analyzed at two layers: **generic concepts** (cross-cutting
behavioral atoms) and **application concepts** (the 9 skills as molecular
synchronizations of those atoms).

---

## 2. Generic Concepts

Six reusable behavioral abstractions that CWF skills synchronize. Each is
independently definable — understanding one requires no knowledge of the others.

### 2.1 Expert Advisor

**Purpose**: Reduce blind spots by introducing contrasting expert frameworks into
decision-making.

**Operational Principle**: When a decision requires judgment beyond what code or
best practices can resolve, two domain experts with contrasting analytical
frameworks evaluate the problem independently. Their disagreements surface
assumptions that a single perspective would miss, and their agreements provide
high-confidence signals. The result is a decision informed by structural tension
rather than single-viewpoint bias.

**State**:

- Expert roster (name, domain, framework, usage history)
- Expert pair assignment (alpha/beta, contrasting frameworks)
- Analysis output per expert (framework-specific evaluation)

**Actions**:

- Select experts (match domain keywords against roster, ensure contrast)
- Launch parallel analysis (each expert evaluates independently)
- Synthesize tension (surface agreements and disagreements)
- Update roster (track usage, propose additions after sessions)

**Synchronized by**: clarify (Phase 2.5 expert analysis), retro (Section 5
Expert Lens), review (multi-perspective verdicts)

---

### 2.2 Tier Classification

**Purpose**: Route decisions to the right authority — evidence for what evidence
can resolve, humans for what requires judgment.

**Operational Principle**: When a requirement contains ambiguous decision points,
each point is classified by evidence strength. If the codebase provides clear
signals (file patterns, existing conventions), the agent decides autonomously
(T1). If published best practices reach consensus, the agent decides with
citations (T2). If evidence conflicts, is absent, or the decision is inherently
subjective, the question is queued for the human (T3). The result is that humans
are only interrupted for genuinely subjective decisions.

**State**:

- Decision point list (questions extracted from requirements)
- Evidence map (codebase findings, web research, expert analysis per point)
- Tier assignment (T1/T2/T3 per point with rationale)

**Actions**:

- Decompose requirement into decision points
- Gather evidence (codebase search, web research, expert analysis)
- Classify tier (apply evidence strength rules)
- Auto-decide T1/T2 (cite evidence in decision record)
- Queue T3 for human (present with advisory context)

**Synchronized by**: clarify (Phases 1-4 — the primary synchronization)

---

### 2.3 Agent Orchestration

**Purpose**: Parallelize work across specialized sub-agents without sacrificing
quality or coordination.

**Operational Principle**: When a task can be decomposed into independent work
items, the orchestrator assesses complexity and spawns the minimum number of
agents needed — each with distinct, non-overlapping work. Agents execute in
parallel batches (respecting dependencies), and the orchestrator collects,
verifies, and synthesizes their outputs. The result is faster execution with
the same quality as sequential work, because parallelism is structural (no
shared state between agents) rather than hopeful.

**State**:

- Work item decomposition (steps, files, domains, dependencies)
- Agent team composition (count, pattern, assignments)
- Batch execution plan (parallel groups, sequential dependencies)
- Provenance metadata (source, tool, duration per agent output)

**Actions**:

- Decompose into work items (dependency analysis, domain detection)
- Size team adaptively (Single / Adaptive / Agent team / 4 parallel)
- Launch parallel batch (multiple Task calls in single message)
- Collect and verify results (check completeness, handle failures)
- Synthesize outputs (merge perspectives, resolve conflicts)

**Synchronized by**: clarify (parallel research + advisory), plan (parallel
prior art + codebase research), impl (agent team execution), retro (batched CDM
+ Expert Lens), refactor (parallel review agents)

---

### 2.4 Decision Point

**Purpose**: Capture ambiguity explicitly so it can be resolved with evidence
rather than guesswork.

**Operational Principle**: When a requirement or task description contains
implicit choices, the agent decomposes it into concrete decision points — framed
as specific questions, not categories. Each point is then subjected to evidence
gathering before anyone is asked to decide. The result is that decisions are
made with full context, and no ambiguity is silently resolved by assumption.

**State**:

- Decision point list (question, status: open/resolved)
- Evidence per point (sources, confidence levels)
- Resolution record (decision, decided-by, evidence cited)

**Actions**:

- Extract decision points from requirement/task
- Attach evidence to points (from research, codebase, experts)
- Resolve points (auto-decide or queue for human)
- Record resolution with provenance

**Synchronized by**: clarify (Phase 1 capture, Phase 3 classify), plan (Phase 1
scope — key decisions identified before research)

---

### 2.5 Handoff

**Purpose**: Preserve context across session and phase boundaries so work can
continue without re-discovery.

**Operational Principle**: When a session ends or a workflow transitions between
phases, the agent generates a structured document capturing what matters for the
next stage. Session handoffs (`next-session.md`) carry task scope, lessons, and
unresolved items. Phase handoffs (`phase-handoff.md`) carry HOW context
(protocols, rules, constraints) while the plan carries WHAT. The result is that
the next agent starts with full context instead of re-reading the entire
conversation history.

**State**:

- Session artifacts (plan.md, lessons.md, retro.md, phase-handoff.md)
- Unresolved items (deferred actions, unimplemented proposals, retro action items)
- Project state (cwf-state.yaml — stages, session history, expert roster)

**Actions**:

- Scan session artifacts for context worth preserving
- Propagate unresolved items to next session
- Generate handoff document (session or phase variant)
- Register session in project state

**Synchronized by**: handoff (primary — both session and phase modes), impl
(Phase 1.1b — consumes phase-handoff.md)

---

### 2.6 Provenance

**Purpose**: Detect when analytical criteria or reference guides have become
stale relative to the current system state.

**Operational Principle**: When a reference document (review criteria, analysis
framework, expert roster) is created, it encodes assumptions about the system at
that point in time — number of skills, hook groups, architectural patterns.
Before applying such a document, the agent checks whether the system has changed
significantly since creation. If it has, the agent flags the staleness to the
user before proceeding. The result is that criteria evolve with the system
instead of silently becoming irrelevant.

**State**:

- Provenance metadata per reference (system state at creation time)
- Current system state (skill count, hook groups, architecture)
- Staleness delta (what changed since reference creation)

**Actions**:

- Attach provenance to reference documents
- Check provenance against current state before applying
- Flag significant deltas to user
- Trigger reference update when staleness exceeds threshold

**Synchronized by**: refactor (holistic mode — checks criteria provenance
against current plugin inventory)

---

## 3. Application Concepts

The 9 CWF skills, presented in workflow order. Each is a synchronization
(composition) of generic concepts — Jackson's molecule built from atoms.

### 3.1 gather

**Purpose**: Acquire information from external sources and local codebase into a
unified format for downstream consumption.

**Operational Principle**: When the user needs external context — a Google Doc, a
Slack thread, web search results, or local code patterns — gather auto-detects
the source type, applies the appropriate handler, and saves structured output.
The result is that all information acquisition flows through a single entry point
with consistent output format.

**Generic Concepts Composed**: Agent Orchestration (sub-agent for `--local`
mode; adaptive pattern — broad queries may parallelize)

**Agent Pattern**: Adaptive

---

### 3.2 clarify

**Purpose**: Transform vague requirements into precise, actionable specifications
by resolving ambiguity with evidence.

**Operational Principle**: When a user presents an ambiguous requirement, clarify
decomposes it into decision points, launches parallel research agents (codebase +
web), classifies each point by evidence tier, engages expert advisors for
contested items, and asks the human only about genuinely subjective decisions.
The result is a clarified requirement where every decision has a recorded
rationale.

**Generic Concepts Composed**: Decision Point (Phase 1 decomposition, Phase 3
classification), Tier Classification (Phase 3 T1/T2/T3 routing), Expert Advisor
(Phase 2.5 contrasting expert analysis), Agent Orchestration (parallel research
+ parallel advisory sub-agents)

**Agent Pattern**: Agent team (4+ parallel sub-agents: 2 researchers + 2 experts
+ 2 advisors across phases)

---

### 3.3 plan

**Purpose**: Convert a task description into a structured, research-backed
implementation plan with verifiable success criteria.

**Operational Principle**: When a task needs planning, plan launches parallel
research agents (prior art + codebase analysis), synthesizes findings into a
structured plan with BDD success criteria, and writes artifacts to the session
directory. The result is a plan that serves as a contract for implementation —
concrete steps, explicit scope, and testable criteria.

**Generic Concepts Composed**: Decision Point (Phase 1 — key decisions
identified during scoping), Agent Orchestration (Phase 2 — parallel prior art +
codebase research)

**Agent Pattern**: Agent team (2 parallel research sub-agents)

---

### 3.4 impl

**Purpose**: Orchestrate autonomous implementation from a structured plan,
decomposing work into parallelizable items and verifying completion.

**Operational Principle**: When a plan exists, impl loads it (and any phase
handoff), decomposes steps into work items by domain and dependency, sizes an
agent team adaptively, executes in parallel batches, and verifies every BDD
criterion. The result is that the plan's contract is fulfilled by coordinated
agents rather than a single serial executor.

**Generic Concepts Composed**: Agent Orchestration (Phases 2-3 — decomposition,
team sizing, parallel execution), Handoff (Phase 1.1b — consumes
phase-handoff.md for HOW context)

**Agent Pattern**: Agent team (1-4 agents, adaptively sized)

---

### 3.5 retro

**Purpose**: Extract durable learnings from a session through structured
analysis and multi-perspective evaluation.

**Operational Principle**: When a session ends, retro analyzes the full
conversation for context worth remembering, collaboration patterns, wasted
effort (with 5 Whys root cause analysis), and critical decisions (CDM). In deep
mode, it adds expert lens analysis and learning resources via parallel
sub-agents. The result is a retro.md that captures not just what happened but
why, with findings persisted to project-level documents.

**Generic Concepts Composed**: Expert Advisor (Section 5 Expert Lens — deep
mode), Agent Orchestration (Batched sub-agents: CDM + Learning Resources in
Batch 1, Expert alpha + beta in Batch 2)

**Agent Pattern**: 4 parallel (2 batches of 2 sub-agents in deep mode)

---

### 3.6 refactor

**Purpose**: Detect structural issues, stale patterns, and improvement
opportunities across code and skills.

**Operational Principle**: When quality review is needed, refactor offers five
modes — quick scan (structural checks), code tidying (commit-based refactoring),
deep review (single skill evaluation), holistic analysis (cross-plugin patterns),
and docs review (consistency checks). Each mode uses parallel sub-agents divided
by perspective, not module. The result is that quality issues are found by agents
with distinct analytical lenses, preventing blind spots.

**Generic Concepts Composed**: Agent Orchestration (parallel sub-agents in code
tidying, deep review, and holistic modes), Provenance (holistic mode checks
criteria staleness against current system state)

**Agent Pattern**: 4 parallel (varies by mode — 1/commit for code, 2 for deep,
3 for holistic)

---

### 3.7 handoff

**Purpose**: Generate structured context-transfer documents that preserve session
and phase knowledge across boundaries.

**Operational Principle**: When a session completes or a workflow transitions
between phases, handoff reads project state, session artifacts, and unresolved
items, then generates a document for the next stage. Session handoffs carry task
scope and lessons; phase handoffs carry protocols and constraints. The result is
that context survives the session boundary.

**Generic Concepts Composed**: Handoff (primary — this skill is the direct
instantiation of the generic concept)

**Agent Pattern**: Single

---

### 3.8 setup

**Purpose**: Configure CWF's hook groups, detect external tools, and generate a
project index for progressive disclosure.

**Operational Principle**: When CWF is first installed or needs reconfiguration,
setup presents interactive hook group selection, detects external AI CLI
availability and API keys, and generates an index.md with entry points. The
result is a configured environment where the user controls which hooks are active
and knows which tools are available.

**Generic Concepts Composed**: (None — setup is a pure infrastructure skill with
no generic concept synchronization)

**Agent Pattern**: Single

---

### 3.9 update

**Purpose**: Check and apply CWF plugin updates from the marketplace.

**Operational Principle**: When the user wants the latest CWF version, update
compares installed vs. marketplace versions, confirms with the user, installs
the update, and summarizes changes. The result is a frictionless upgrade path.

**Generic Concepts Composed**: (None — update is a pure infrastructure skill with
no generic concept synchronization)

**Agent Pattern**: Single

---

## 4. Synchronization Map

Which generic concepts each skill activates:

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

### Sequential Flow

The primary workflow follows a gather-to-deliver arc:

```text
gather → clarify → plan → impl → retro
```

Each stage produces artifacts consumed by the next. gather provides raw context.
clarify transforms it into precise requirements. plan converts requirements into
an implementation contract. impl executes the contract. retro extracts learnings.
This sequence composes Agent Orchestration at every stage, with Decision Point
prominent in the early stages (clarify, plan) and Handoff bridging the middle
(impl consuming phase-handoff from clarify/plan).

### Feedback Loops

Two feedback loops operate orthogonally to the main sequence:

**Learning loop**: retro produces learnings → lessons.md → handoff propagates to
next session → clarify/plan consume as prior context. This loop ensures that
mistakes are not repeated across sessions.

**Quality loop**: refactor scans the system → Provenance detects stale criteria →
criteria are updated → next refactor applies fresh standards. This loop ensures
that the framework's own standards evolve with the system.

---

## 5. Concept Independence

Each generic concept is verifiable as independently definable:

| Concept | Independence Verification |
|---------|--------------------------|
| Expert Advisor | Can be understood purely as "contrasting experts reduce blind spots." No reference to tiers, handoffs, or orchestration needed. |
| Tier Classification | Can be understood purely as "route decisions by evidence strength." No reference to experts, agents, or handoffs needed. |
| Agent Orchestration | Can be understood purely as "parallelize work with minimum agents." No reference to tiers, experts, or handoffs needed. |
| Decision Point | Can be understood purely as "capture ambiguity as explicit questions." No reference to agents, experts, or tiers needed. |
| Handoff | Can be understood purely as "preserve context across boundaries." No reference to agents, tiers, or experts needed. |
| Provenance | Can be understood purely as "detect criteria staleness." No reference to agents, experts, or handoffs needed. |

All 6 concepts pass the independence test. A new user can learn any one concept
without prerequisite knowledge of the others.

---

## 6. Specificity Audit

Jackson's specificity principle requires 1:1 correspondence between purposes and
concepts — no redundancy (two concepts for one purpose) and no overloading (one
concept serving two purposes).

| Check | Result |
|-------|--------|
| Expert Advisor vs. Agent Orchestration | Distinct: Expert Advisor is about *contrasting frameworks* for judgment; Agent Orchestration is about *parallelizing work* for throughput. An expert analysis could run on a single agent; a parallel batch has nothing to do with expertise. |
| Decision Point vs. Tier Classification | Distinct: Decision Point is about *capturing* ambiguity; Tier Classification is about *routing* it to the right resolver. You need decision points before you can classify them. |
| Handoff vs. Provenance | Distinct: Handoff preserves *session context* across boundaries; Provenance detects *criteria staleness* over time. One is about knowledge transfer, the other about quality decay. |

**No redundancy found.** Each purpose maps to exactly one concept.

**No overloading found.** Each concept serves exactly one purpose.

### Candidate Missing Concept: Session Lifecycle

CWF manages session state via `cwf-state.yaml` — stages, checkpoints, artifacts,
session history. This cuts across setup (initialization), handoff (registration),
and retro (persist findings). It could be a seventh generic concept with purpose:
"Track workflow progress and enforce artifact expectations."

However, session lifecycle currently manifests as a shared data store
(`cwf-state.yaml`) rather than a behavioral concept with its own operational
principle. Skills read and write it, but there is no distinct *behavior* that
session lifecycle provides beyond data access. This makes it infrastructure, not
a concept in Jackson's sense. If CWF later adds automatic stage transitions or
artifact enforcement beyond `check-session.sh`, Session Lifecycle would graduate
to a full concept.

---

## 7. Insights for README

The distillation reveals CWF's architecture through a lens accessible to new
users:

- **6 building blocks, 9 tools**: The README should introduce the 6 generic
  concepts before the 9 skills, because the concepts explain *why* the skills
  work together while the skills explain *what* you can do.
- **Synchronization is the story**: CWF's value is not 9 independent tools but
  the composition of shared concepts across them. The synchronization map belongs
  in the README.
- **Purpose-first explanations**: Each skill should be introduced by its purpose
  (one sentence), not its implementation details. Details live in SKILL.md.
- **Two natural entry points**: Sequential flow (gather → impl) for users who
  want to follow the workflow, and individual skill lookup for users who want a
  specific capability.
- **Infrastructure skills are different**: setup and update compose no generic
  concepts — they are pure utility. The README should present them separately
  from the workflow skills.
- **Newcomer accessibility**: No concept requires understanding CWF's history.
  The distillation is purely forward-looking, and the README should be too.
