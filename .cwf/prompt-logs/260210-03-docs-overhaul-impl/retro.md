# Retro: S32-impl — Docs Overhaul Implementation (L1-L3+L9)

> Session date: 2026-02-10
> Mode: deep

## 1. Context Worth Remembering

- **Full CWF pipeline exercised end-to-end**: clarify → plan → review(plan) → impl(4 agents) → review(code, 6 reviewers) → fix 3 concerns → commit → refactor quick-scan → retro. This is the first session to traverse every CWF stage in a single sitting.
- **Multiple auto-compactions occurred** during the session. The compact recovery hook (`session-start-compact.sh`) injected `cwf-state.yaml` live section each time, but detailed decisions made during impl/review phases were lost.
- **Context recovery protocol extracted**: A cross-cutting pattern (sub-agent file persistence with sentinel validation) was duplicated 9x across 5 skills. Review caught it; post-review fix extracted it to `plugins/cwf/references/context-recovery-protocol.md`.
- **Gemini CLI failure**: `MODEL_CAPACITY_EXHAUSTED` (HTTP 429) during code review. 104s wasted on internal retries before fallback to Task agent.
- **Expert roster used in review**: David Woods (resilience engineering) + James Reason (Swiss cheese model) as domain experts.
- **Master-plan remaining items**: S13.6 (Full CWF protocol design: auto-chaining) and S14 (Integration test, deprecate old plugins, merge to main). The master-plan is stale — S32's L1-L3+L9 work is not tracked there.

## 2. Collaboration Preferences

The user's delegation style is high-level and trust-based: "커밋하고 refactor 가자", "retro 합시다" — minimal specification, maximum autonomy. This works well when context is preserved. When context is lost (post-compaction), the same delegation style breaks because the agent lacks the implicit shared understanding that the user assumes is retained.

The user's feedback — "어느 순간부터 자꾸 내게 물어봐서" — signals a failure mode specific to long sessions with compaction. The agent's re-questioning was not a preference mismatch but a **context loss artifact**. The user experienced it as behavioral regression: the agent seemed to "forget" what was already decided.

### Suggested CLAUDE.md Updates

None. The issue is structural (compact recovery resolution), not behavioral. A CLAUDE.md rule like "don't re-ask decided questions" would be unenforceable — the agent doesn't know it's re-asking after compaction.

## 3. Waste Reduction

### 3.1 Compaction-induced re-questioning

**Symptom**: Agent asked user about already-decided matters after auto-compaction.

**5 Whys**:
1. Why did the agent re-ask? → It lost the detailed decisions from earlier in the session.
2. Why were decisions lost? → Auto-compaction summarized away the specific choices.
3. Why didn't compact recovery restore them? → The `decisions` field in `cwf-state.yaml` only had 5 high-level items.
4. Why only 5 items? → The recovery mechanism was designed during S29 for clarify/plan phases, where decision density is low.
5. Why wasn't it adapted for impl? → Phase-specific recovery requirements were not anticipated at design time.

**Root cause**: Structural constraint — compact recovery design assumes uniform decision density across phases. Impl phase has 10-50x more granular decisions than clarify/plan.

**Fix**: Phase-aware recovery (Tier 2: state change). See CDM 3 for detailed analysis.

### 3.2 Gemini CLI 104s wasted

**Symptom**: 104 seconds spent on Gemini CLI retries for a `MODEL_CAPACITY_EXHAUSTED` error that would not resolve through retrying.

**5 Whys**:
1. Why 104s? → Gemini CLI's internal exponential backoff retried 3 times.
2. Why didn't we fail fast? → Review SKILL.md Phase 3.2 only checks exit codes, not error type.
3. Why binary error handling? → The error classification was designed as success/fail without severity tiers.
4. Why no severity tiers? → Original review skill design (S5b) focused on "does it work?" not "why did it fail?"
5. Why not updated since? → L9 lesson identified this gap but implementation was deferred.

**Root cause**: Process gap — error-type-specific handling was identified (L9) but not implemented in this session's scope.

**Fix**: Add stderr parsing with fail-fast for CAPACITY errors to review SKILL.md Phase 3.2 (Tier 3: doc/skill update). See CDM 4.

### 3.3 9x context recovery duplication

**Symptom**: Identical 3-step recovery protocol duplicated across 5 skills (9 instances total).

**5 Whys**:
1. Why duplicated? → Each parallel impl agent copied the pattern inline.
2. Why inline? → Plan said "apply the same pattern" without specifying a shared file.
3. Why no shared file in plan? → Plan focused on "what" not "how" for cross-cutting concerns.
4. Why didn't orchestrator catch it? → Parallel agents can't see each other's output during execution.
5. Why no pre-extraction step? → Plan template lacks a "cross-cutting pattern check" gate.

**Root cause**: Process gap — plan template needs a cross-cutting pattern detection gate for parallel agent execution.

**Fix**: Add cross-cutting pattern check to plan template (Tier 3: skill update). See CDM 1.

## 4. Critical Decision Analysis (CDM)

### CDM 1: 9x Duplicated Context Recovery — Extraction vs Inline

Plan Step 4 described "Common pattern (applies to all sub-agent persistence steps 4-9)" with Steps 5-9 referencing "Apply the same context recovery pattern from Step 4." However, this was an intra-plan reference, not a shared file specification. Each of 4 parallel impl agents copied the full pattern into their assigned SKILL.md files.

| Probe | Analysis |
|-------|----------|
| **Cues** | Plan's "동일 패턴 적용" instruction, existing shared reference precedent (`expert-advisor-guide.md`), 4 parallel agents unable to see each other's work |
| **Knowledge** | CWF already had `plugins/cwf/references/` with shared docs. This pattern was known but not applied at plan time. |
| **Goals** | Competing: (a) consistent recovery across 5 skills, (b) self-containment per skill, (c) impl speed via parallel agents. Speed (c) won over sharing (a). |
| **Options** | (1) Plan specifies shared reference file as Step 0, (2) Plan describes inline + "동일 적용" (chosen), (3) Orchestrator extracts common pattern after first agent completes |
| **Basis** | Plan treated shared file extraction as implementation detail, but parallel agent structure requires it as a plan-level decision. |
| **Analogues** | S13.5-B: `expert-advisor-guide.md` extracted after initial inline duplication across 3 skills — same pattern repeated. |

**Key lesson**: "3개 이상 대상에 동일 로직 → 공유 참조 파일 우선 생성" rule needed in plan template.

### CDM 2: Single Commit vs Fine-Grained Per-Work-Item Commits

Plan Decision #2 specified "fine-grained per-work-item commits" but actual implementation used a single commit. The cross-cutting nature of context recovery protocol made work-item boundaries misalign with meaningful commit boundaries.

| Probe | Analysis |
|-------|----------|
| **Cues** | Step 4 (clarify persistence) and Step 7 (review persistence) shared the same cross-cutting pattern, binding them semantically |
| **Knowledge** | L3 lesson from 93-file monolithic diff drove the "fine-grained" decision, but that session's changes were modular, not cross-cutting |
| **Options** | (1) Per-work-item (11 commits), (2) Per-pattern (3 commits: persistence + git gate + log-turn fix), (3) Single commit (chosen), (4) Hybrid |
| **Basis** | Cross-cutting changes, review concern fixes, and compaction time pressure made clean separation impractical |

**Key lesson**: Commit boundary = change pattern, not work item. Plan should assess "is this change cross-cutting?" before committing to a commit strategy.

### CDM 3: Compaction Decision Loss — Recovery Resolution Gap

User feedback: "어느 순간부터 자꾸 내게 물어봐서." The `decisions` field preserved 5 high-level items but impl phase generates dozens of granular decisions.

| Probe | Analysis |
|-------|----------|
| **Cues** | User's direct feedback about question repetition starting at a specific point (post-compaction) |
| **Knowledge** | Recovery hook designed in S29 for clarify/plan phases. Impl decision density is 10-50x higher. |
| **Goals** | (a) Recovery compactness vs (b) decision completeness vs (c) user experience. (a) and (b) directly conflict. |
| **Options** | (1) Expand decisions to 20-30 items, (2) Keep 5 high-level only (chosen), (3) High-level decisions + auto-load plan.md on recovery, (4) Decision journal — write granular decisions to file during impl |
| **Situation Assessment** | Recovery hook was designed for session restart, not mid-session compaction. Mid-session needs micro-decisions; recovery provides macro-context only. |

**Key lesson**: Recovery resolution must match phase decision density. Phase-aware strategy: impl phase should auto-load plan.md content or maintain a decision journal.

### CDM 4: Gemini CLI 104s Wait — Missing Fail-Fast

Gemini CLI failed with `MODEL_CAPACITY_EXHAUSTED` (429). Internal retries consumed 104s before Task agent fallback was triggered.

| Probe | Analysis |
|-------|----------|
| **Cues** | HTTP 429 in stderr, but Phase 3.2 error handling only checked exit codes |
| **Options** | (1) Current: 3 retries + full timeout (104s), (2) Fail-fast on CAPACITY errors (~10s), (3) Parallel hedging (CLI + Task simultaneously), (4) Pre-flight health check |
| **Tools** | Gemini CLI `--max-retries 0` or `--timeout 30s` options were not investigated at plan/impl time |

**Key lesson**: Error-type-specific strategy: CAPACITY → fail-fast, INTERNAL → 1 retry + fallback, AUTH → abort immediately. Parse stderr, not just exit codes.

### Cross-Cutting Pattern

All 4 CDMs share a structural pattern: **design-time assumptions invalidated at execution time**.
- Plan assumed work items are independent → cross-cutting pattern made them coupled
- Plan assumed per-work-item commits are natural → cross-cutting made them unnatural
- Recovery assumed 5 decisions suffice → impl density made them insufficient
- Error handling assumed binary success/fail → error types required differentiated responses

## 5. Expert Lens

### Expert Alpha: Frederick P. Brooks, Jr.

**Framework**: Conceptual Integrity, "Plan to throw one away", Second-System Effect, essential vs accidental complexity
**Source**: *The Mythical Man-Month* (1975, 20th anniversary ed. 1995), "No Silver Bullet" (1986), *The Design of Design* (2010)

#### 1. Conceptual Integrity Failure — What 9x Duplication Reveals

Brooks declared in Chapter 4: "Conceptual integrity is the most important consideration in system design." The 9x duplication is a textbook case of conceptual integrity collapse. 4 parallel agents working independently fractured a single concept (context recovery) into 9 separate instances. The plan's "동일 적용" instruction delegated architecture to implementors — exactly the mistake Brooks warned against.

In Brooks's communication overhead model (n(n-1)/2 paths), 4 agents with 0 communication paths don't eliminate overhead — they make coordination **impossible**. The plan should have served as Brooks's "surgical team" chief architect, injecting shared vision. "동일 적용" was not vision injection but vision abdication.

#### 2. "Plan to Throw One Away" — Compact Recovery as First System

CDM 3's compact recovery problem maps to Brooks's Chapter 11: the first system must inevitably be discarded. The `decisions` field designed in S29 for clarify/plan phases was this "first system." It hadn't experienced impl-phase decision density. The problem: **it was deployed without recognition that it was a throwaway**.

The user's "자꾸 물어봐서" feedback reflects what Brooks called essential complexity in "No Silver Bullet" — managing infinite decisions in a finite context window is an essential contradiction of AI agent sessions, not an accidental one solvable by tool changes. It requires architectural response: decision externalization.

#### 3. Second-System Effect — Plan Over-Engineering

Brooks's Chapter 5 warns that designers who succeeded with their first system overload the second. The plan's 11 elaborate steps, per-work-item commit strategy, and dual review with 6 reviewers bear hallmarks of over-incorporating lessons from prior sessions. CDM 2 confirmed this: the commit strategy collapsed under cross-cutting reality.

**What worked well** is also explainable through Brooks: the pipeline structure (clarify → plan → review → impl → review → fix → refactor) follows his separation of design and implementation. The context recovery protocol extraction, though belated, was the correct move toward recovering conceptual integrity.

**Recommendations**:
1. "Shared spec first" principle in plan: when cross-cutting patterns are identified, mandate a shared reference file as Step 0. "동일 적용" should be treated as a prohibited instruction.
2. Redesign compact recovery as Brooks's "second system" — with phase-aware decision resolution and a decision journal mechanism for impl phase.

### Expert Beta: John Ousterhout

**Framework**: Deep vs Shallow modules, complexity management, information leakage, strategic vs tactical programming, pass-through methods
**Source**: *A Philosophy of Software Design* (2018; 2nd ed. 2021), "Always Measure One Level Deeper" (*CACM*, 2018)

#### 1. Context Recovery Protocol — Deep or Shallow Module?

The protocol's interface (3 steps: resolve dir → check file + sentinel → reuse or re-execute) matches its implementation depth exactly. By Ousterhout's rectangle metaphor, this is a **shallow module** — it moves complexity rather than hiding it.

But shallowness isn't the real problem — **9x replication of a shallow module is**. This is textbook information leakage (Chapter 5): 5 skills sharing identical knowledge about session dir resolution, file checking, and sentinel validation. The extraction to `context-recovery-protocol.md` was the correct post-hoc fix, but Ousterhout's principle that "design decisions should be made early and in one place" (Chapter 7) aligns with CDM 1's finding that this should have happened at plan time.

#### 2. SKILL.md Interface Bloat — Tactical Programming Accumulation

Every step in the plan was **tactical**: inserting specific code blocks into specific SKILL.md phases. L1 (Branch Gate), L2 (Clarify Gate), L3 (File Persistence) — each is a tactical response to an immediate problem. Individually reasonable, but their **cumulative effect** is concerning.

impl/SKILL.md grew from a clean 4-phase pipeline (Load → Decompose → Execute → Verify) to ~10+ sub-phases. Ousterhout calls this "interface bloat" — each added feature widens the interface, transferring complexity to the module's user (the AI agent itself). Combined with compaction, wider interfaces mean more context to lose — **tactical fixes exacerbating the original problem**.

Ousterhout's solution: extract gates (Branch, Clarify, Commit) to shared references (e.g., `references/git-workflow-gates.md`). impl/SKILL.md shrinks back to "apply gate → see reference" — narrow interface, deep implementation.

#### 3. "Always Measure One Level Deeper" — Plan Decomposition Error

The plan decomposed at file-level ("modify 5 SKILL.md files") not concept-level ("introduce context recovery protocol concept, then project it into 5 skills"). Ousterhout would see this as a pass-through method problem: each skill's change was merely a pass-through of a single concept without adding depth.

The real "work item" was one deep task: "design context recovery protocol and apply it." Had the plan been concept-level, per-work-item commits would have worked naturally — first commit creates the shared concept file, subsequent commits add reference points.

**Recommendations**:
1. Shift plan decomposition from file-level to concept-level. Cross-cutting patterns → first step creates shared concept (deep module), subsequent steps add reference points (shallow connectors).
2. Extract impl/SKILL.md gates to references to narrow the interface and improve compaction resistance.

## 6. Learning Resources

### Context Window Management in Long-Running AI Agent Sessions

**Resource 1-1**: [Effective Context Engineering for AI Agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) (Anthropic)
Anthropic's official engineering blog defining compaction as "summarizing conversation at context window limits" and presenting high-fidelity distillation patterns. Covers sub-agent architecture for context isolation and file-based memory systems. Directly addresses S32's core problem — decision loss after compaction — and validates the `cwf-state.yaml` + sub-agent isolation approach.

**Resource 1-2**: [Escaping Context Amnesia — Practical Strategies for Long-Running AI Agents](https://hadijaveed.me/2025/11/26/escaping-context-amnesia-ai-agents/)
Covers Input Pruning, Placeholder Compression, and Session Handoffs with concrete implementation patterns. The term "Context Amnesia" precisely names S32's phenomenon. Placeholder Compression could enhance `cwf-state.yaml`'s decisions field to preserve granular decisions in compressed form.

**Resource 1-3**: [Context Engineering Compaction Experiments](https://jxnl.co/writing/2025/08/30/context-engineering-compaction/) (Jason Liu)
Proposes experiments to quantify compaction's information preservation rate and cumulative loss across multiple compactions. Provides a measurement framework for validating whether `cwf-state.yaml`'s recovery mechanism remains effective after N compactions.

### Multi-Agent Orchestration Patterns

**Resource 2-1**: [Claude Code Swarms](https://addyosmani.com/blog/claude-code-agent-teams/) (Addy Osmani)
Deep analysis of Claude Code agent team architecture: Conductor vs Orchestrator patterns, narrow scope + clean context per agent, "80% planning and review, 20% execution." The "each agent owns different file sets" best practice directly addresses S32's cross-cutting duplication problem.

**Resource 2-2**: [Learning Claude Code — From Context Engineering to Multi-Agent Workflows](https://medium.com/data-science-collective/learning-claude-code-from-context-engineering-to-multi-agent-workflows-4825e216403f)
Systematic analysis of 4 context management strategies (3-tier memory hierarchy, intelligent retrieval, compression, isolation) and the "orchestration tradeoff" — cognitive load shifting from writing code to choosing between implementations. Directly maps to S32's 6-reviewer synthesis challenge.

**Resource 2-3**: [The Multi-Agent Playbook: 6 Agent Patterns for AI Developers](https://pub.towardsai.net/7-multi-agent-patterns-every-developer-needs-in-2026-and-how-to-pick-the-right-one-e8edcd99c96a)
Catalogs 6 multi-agent patterns (Sequential, Parallel, Hierarchical, Debate/Consensus, Pipeline, Self-organizing) with decision frameworks. S32's review structure (6 reviewers → 1 verdict) is Debate/Consensus; impl structure (4 agents) is Parallel.

### Code Review Automation with Multiple AI Models

**Resource 3-1**: [Multi-MCP — Multi-Model Code Review Server](https://github.com/religa/multi_mcp)
MCP server integrating OpenAI, Claude, and Gemini for parallel code review (~10s parallel vs ~30s sequential). Automates what S32 built manually. Includes graceful fallback handling for capacity errors — directly addresses CDM 4's fail-fast gap.

**Resource 3-2**: [AI-Powered Development Cycle with Claude Code](https://nakamasato.medium.com/ai-powered-development-cycle-with-claude-code-november-2025-snapshot-cc5255902ff2)
Multi-model consensus principle: "when multiple AIs suggest similar changes, it's usually worth making." Validates S32's review finding (3 moderate concerns from multi-model consensus). Cost optimization via ChatGPT Plus ($20/month unlimited) + Gemini CLI (free).

**Resource 3-3**: [RovoDev Code Reviewer System](https://www.emergentmind.com/topics/rovodev-code-reviewer) (Emergent Mind)
Atlassian's data: Claude 3.5 Sonnet + GPT-4o-mini pipeline achieved 38.7% actionability rate (auto-generated comments causing actual code changes), 31% PR cycle time reduction, 35.6% human review burden reduction. Provides quantitative benchmark for evaluating CWF's 6-reviewer pipeline effectiveness.

## 7. Relevant Skills

### Installed Skills

**CWF Skills** (11 skills): clarify, plan, impl, review, retro, refactor, gather, setup, update, handoff, ship.

All 11 CWF skills were relevant to this session — the full pipeline was exercised. Notable observations:

- **cwf:review**: Performed both spec review (plan mode) and code review (code mode). Caught 3 moderate concerns including 9x duplication. The 6-reviewer structure (2 internal + 2 external CLI + 2 domain experts) proved its value — concerns came from different perspectives that a single reviewer would likely miss.
- **cwf:refactor**: Quick scan mode ran post-impl, identifying 4 flagged skills. Useful as a lightweight structural health check between impl and retro.
- **cwf:impl**: Orchestrated 4 parallel agents. The decomposition and parallel execution worked; the gap was in plan-level specification of cross-cutting patterns (not impl's fault).

**Local Skills**:
- **plugin-deploy** (`.claude/skills/plugin-deploy/`): Not used in this session. Would be relevant when deploying the CWF plugin changes to marketplace, but session scope was limited to implementation.

### Skill Gaps

**Phase-aware compact recovery** is the most significant gap identified. The current `session-start-compact.sh` hook provides uniform recovery regardless of phase. A skill or hook enhancement to detect current phase and adjust recovery resolution (e.g., auto-loading plan.md content during impl phase) would address CDM 3.

No external skill discovery needed — this is an enhancement to existing CWF infrastructure, not a new workflow gap.
