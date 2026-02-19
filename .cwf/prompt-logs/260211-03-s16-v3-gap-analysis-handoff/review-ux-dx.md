## UX/DX Review

### Concerns (blocking)

- **[C1]** Missing "Context" section with read-list for the executing agent.
  Severity: moderate

  Every prior `next-session.md` in this project (S14, S15, S33) opens with a
  `## Context` section listing the files the agent should read first (e.g.,
  `cwf-state.yaml`, `master-plan.md`, specific lessons). The S17 handoff
  (`prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md`)
  omits this entirely. The "Hard Scope Anchor" section (lines 23-36) lists
  files to *collect*, but that is a different concern from what to *read for
  orientation* before starting work. An agent launching S17 cold will not
  know where to begin without an explicit read-list, violating the
  progressive-disclosure pattern the project itself establishes.

- **[C2]** Workstream milestone references in Phase 1 contain identifiers
  that do not match `cwf-state.yaml` session IDs.
  Severity: moderate

  Line 94 lists `S13.5 A/B/B2/B3/C/D/E, S32, S33, S14, S15` as workstream
  milestones to map. However, `cwf-state.yaml` uses hyphenated IDs like
  `S13.5-A`, `S13.5-B`, `S13.5-B2`, `S13.5-B3`, and includes `post-B3`,
  `S29`, `S32-impl` — none of which appear in the Phase 1 list. There is
  also no `S32` entry in `cwf-state.yaml` (there is `S32-impl`). The
  executing agent will need to guess whether `S32` means `S32-impl`, whether
  `S29` and `post-B3` are in scope, and whether `C/D/E` maps to a single
  session (`s13.5-c2de-docs-infra`) or three. This ambiguity conflicts with
  the document's own "omission resistance" goal. The milestone list should
  use exact `cwf-state.yaml` session IDs or explicitly state that the agent
  should derive the list from the YAML file.

- **[C3]** Master-plan decisions range is "#1-#20" but decisions evolved
  beyond 20 during hardening sessions.
  Severity: moderate

  Line 92 instructs the agent to map "Master-plan decisions (#1-#20)". The
  master plan (`prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md`)
  does list 20 numbered architecture decisions, but
  `docs/v3-migration-decisions.md` documents additional emergent decisions
  from S13.5-S33 (Expert-in-the-Loop, Concept Distillation, Compact
  Recovery, Context Recovery Protocol, Decision Journal, Auto-Chaining,
  Review Fail-Fast) that are unnumbered. The coverage matrix instruction
  should clarify whether these emergent decisions are in scope and how to
  reference them, or the agent will silently omit them — again contradicting
  the omission-resistance design intent.

- **[C4]** No "Don't Touch" / modification boundary section.
  Severity: moderate

  Prior handoffs (S14 lines 40-44, S15 lines 98-101) include a `## Don't
  Touch` section to establish guardrails. The S17 handoff says "Do not
  implement feature changes" (line 11-12) but does not specify which files
  or directories are off-limits for modification. Since this is an
  analysis-only session producing 7 new artifacts, the risk is that the
  agent modifies source files in `plugins/cwf/` or `cwf-state.yaml` while
  investigating. An explicit `## Don't Touch` section listing
  `plugins/cwf/**`, `cwf-state.yaml`, `scripts/**`, etc. would make the
  read-only intent enforceable rather than aspirational.

### Suggestions (non-blocking)

- **[S1]** Add a "Dependencies" section for consistency with project
  convention.

  Prior handoffs include `## Dependencies` listing what must be completed
  before the session starts and what the session blocks. S17 has no such
  section. Even if S17 has no hard blockers, stating "Requires: S16
  completed" and "Blocks: S18 planning" (or equivalent) helps the agent and
  the user understand the session's position in the sequence.

- **[S2]** Consider adding explicit output directory guidance.

  The document says "Create a manifest file in the session directory"
  (line 71) but never defines what "the session directory" is for S17. The
  executing agent must infer it from convention
  (`prompt-logs/YYMMDD-NN-title/`). Adding a single line like
  `Output directory: prompt-logs/{YYMMDD}-{NN}-s17-v3-gap-analysis/` would
  remove this ambiguity, consistent with how `plan.md` (line 30) gives
  explicit paths.

- **[S3]** The "Suggested Output Order to User" section (lines 205-210)
  feels disconnected from the "Completion Criteria" section (lines 186-196).

  Completion criteria list 7 artifacts, but the output order section
  references only 4 concepts (executive summary, high-confidence items,
  unknowns, proposed decision order). The mapping between these two sections
  is implicit. Consider either numbering the output-order items to reference
  the completion criteria artifacts, or adding a brief note like "Present
  results from the 7 artifacts in this order."

- **[S4]** Korean search terms in Phase 3 (lines 137-139) lack
  transliteration or English glosses.

  The terms `후속` (follow-up), `미구현` (not-implemented), `논의 필요`
  (discussion needed) are correct and valuable for mining bilingual session
  logs. However, an executing agent unfamiliar with Korean conventions in
  this project may not know how to weight these terms or recognize related
  variants. Adding inline English translations (as I have done
  parenthetically above) would make the document more robust for any agent.

- **[S5]** Phase 4 "Bidirectional Consistency Pass" (lines 155-165)
  describes the *what* but not the *how*.

  Every other phase specifies concrete actions (git commands in Phase 0,
  classification labels in Phase 1, search terms in Phase 3). Phase 4 says
  "Run two independent passes" and "Early to Late / Late to Early" but does
  not explain what operation constitutes a "pass". Does the agent re-read
  all artifacts chronologically? Re-check each gap candidate against the
  timeline? Cross-reference the coverage matrix against the user-utterance
  index? The agent will need to invent a method, which risks inconsistency
  and undermines the protocol's repeatability.

- **[S6]** The "After Completion" section is missing.

  Prior handoffs (S14 lines 83-87, S15 lines 104-109) include `## After
  Completion` with explicit steps: write session artifacts, update
  `cwf-state.yaml`, commit. S17's completion criteria (lines 186-196) cover
  artifact existence but not the post-session bookkeeping. Adding this
  section would align with project convention and prevent the agent from
  forgetting to register S17 in `cwf-state.yaml`.

- **[S7]** The "Start Command" (lines 214-216) is self-referential.

  It tells the user to `@` this same file
  (`prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md`).
  This is correct per convention, but for a document that is explicitly a
  handoff *to* S17, the start command description could clarify that this
  launches S17 (not S16). A small label change from "Start Command" to
  "S17 Start Command" would reduce ambiguity.

- **[S8]** Consider adding a rough time/token budget estimate.

  This protocol requires reading the entire git diff corpus from
  `42d2cd9..HEAD`, extracting user utterances from all session logs, and
  mining for gap candidates across all records. Given the project has 24+
  sessions, this is a substantial context window load. A note about expected
  scale (e.g., "Expect ~50-80 files in the corpus manifest") would help the
  executing agent plan its approach and avoid running out of context window
  mid-analysis.

### Provenance

source: REAL_EXECUTION
tool: claude-task
reviewer: UX/DX
duration_ms: —
command: —
<!-- AGENT_COMPLETE -->
