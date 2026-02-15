## Architecture & Patterns Review

**Target**: `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md`
**Role**: Architecture & Patterns reviewer (substituting for Gemini CLI)

---

### Concerns (blocking)

- **[C1]** Phase 1 coverage matrix milestone list is inconsistent with actual
  session history.
  Severity: moderate

  Line 94 lists `S13.5 A/B/B2/B3/C/D/E, S32, S33, S14, S15` as workstream
  milestones, but omits several sessions that carried significant architectural
  changes: `S29` (plan mode removal + live state + compact recovery),
  `post-B3` (housekeeping), `S32-impl` (branch gate + clarify gate + sub-agent
  file persistence), and `S7-prep` (cwf-state.yaml population). These are all
  registered in `cwf-state.yaml` and introduced non-trivial implementation
  changes. The `S13.5 C/D/E` notation is also ambiguous -- `cwf-state.yaml`
  does not register a session with id `S13.5-C`, `S13.5-D`, or `S13.5-E`
  separately; they were merged as a combined `C2DE` workstream under a single
  branch `s13.5-c2de-docs-infra`. Meanwhile `S13.5-C1` (S29, live state +
  compact recovery) is registered under id `S29`, not under the S13.5 prefix
  at all.

  For an analysis session whose declared goal is "omission-resistant"
  coverage, a hardcoded milestone list with known gaps is a structural
  contradiction. The consuming agent may treat this list as exhaustive and
  skip sessions not enumerated here.

  **Recommendation**: Either (a) remove the hardcoded milestone list and
  instead instruct the agent to derive milestones from `cwf-state.yaml`
  sessions + `master-plan.md` roadmap programmatically, or (b) expand the
  list to include all registered sessions and clarify that the list is
  illustrative, not exhaustive.

- **[C2]** Hard Scope Anchor include list has a path overlap that can cause
  double-counting or confusion in the corpus manifest.
  Severity: moderate

  Lines 29-35 specify both `prompt-logs/**` (all directories and session logs)
  and then separately `prompt-logs/sessions/*.md` and
  `prompt-logs/sessions-codex/*.md`. Since `prompt-logs/**` is a recursive
  glob that already includes everything under `prompt-logs/`, the two
  subsequent entries are strict subsets. An executing agent may interpret this
  as three separate collection operations and produce duplicate entries in the
  corpus manifest, or worse, may interpret the specific entries as the *only*
  subdirectories to include if it reads the list as progressively narrowing.

  The git diff command in Phase 0 (line 77) uses
  `git diff --name-only 42d2cd9..HEAD -- 'prompt-logs/**'` which correctly
  captures everything. But the include list in the Hard Scope Anchor section
  creates an ambiguous specification that could diverge from the git command.

  **Recommendation**: Restructure the include list to use `prompt-logs/**` as
  the single prompt-logs entry, then add a note that
  `prompt-logs/sessions/*.md` and `prompt-logs/sessions-codex/*.md` must
  receive equal weight (preserving the user's intent from the Decision
  Rationale table, row 2) rather than listing them as separate include paths.

---

### Suggestions (non-blocking)

- **[S1]** The document departs significantly from the established handoff
  template defined in `master-plan.md` lines 448-481.

  The established template includes: `Context` (files to read), `Task`,
  `Scope`, `Don't Touch`, `Success Criteria`, `Dependencies`,
  `After Completion`, and `Start Command`. Prior handoff documents (e.g.,
  S13.5-A/next-session.md, S14/next-session.md, S15/next-session.md) all
  follow this structure with minor extensions.

  The S17 handoff replaces this with a novel structure: `Purpose`,
  `Operating Intent`, `Hard Scope Anchor`, `Evidence Hierarchy`,
  `Decision Rationale`, `Required Workflow` (6 phases), `Completion Criteria`,
  `Do Not Skip`, `Suggested Output Order`, `Start Command`. It drops
  `Context` (no file-read list), `Don't Touch`, `Dependencies`, and
  `After Completion` entirely.

  This departure is arguably justified given the document's unique
  analysis-only nature (it explicitly says "Do not implement feature changes
  in this session"), but it is not documented as an intentional deviation.
  Given the project's strong convention emphasis (see
  `references/skill-conventions.md`, `AGENTS.md` session state rules), an
  undocumented structural departure sets a precedent that may erode convention
  adherence in future sessions.

  **Recommendation**: Add a brief note (e.g., in Purpose or as a preamble)
  stating that this handoff intentionally diverges from the standard template
  because S17 is an analysis session, not an implementation session, and
  therefore omits implementation-specific sections (`Don't Touch`,
  `Dependencies`, `After Completion`).

- **[S2]** Missing `Context` section means the executing agent has no
  explicit file-read list.

  Every prior handoff document begins with a `Context` or `Context Files to
  Read` section that tells the agent exactly which files to load before
  starting work. The S17 handoff embeds file references throughout the
  document (lines 33-35 in Hard Scope Anchor, line 43-45 in Evidence
  Hierarchy) but does not provide a consolidated read list.

  This matters architecturally because the project uses progressive
  disclosure (`cwf-index.md`) as a core pattern -- agents are expected to
  read a curated entry set, not discover files ad hoc. Without a context
  section, the executing agent may start Phase 0 without having read
  `cwf-state.yaml`, `master-plan.md`, or `v3-migration-decisions.md`, which
  are essential for Phase 1's coverage matrix.

  **Recommendation**: Add a `Context` section at the top listing the minimum
  files to read before starting: `cwf-state.yaml`, `master-plan.md`,
  `v3-migration-decisions.md`, `cwf-index.md`, and this handoff document
  itself.

- **[S3]** Phase 0 git command only covers `prompt-logs/**`, but the Hard
  Scope Anchor also includes `plugins/cwf/**`, `cwf-state.yaml`,
  `master-plan.md`, and `v3-migration-decisions.md`.

  Line 77 specifies:
  ```
  git diff --name-only 42d2cd9..HEAD -- 'prompt-logs/**'
  ```
  This produces the file list for the corpus manifest, but it excludes all
  non-prompt-log files that are explicitly in scope (lines 32-35). A complete
  corpus manifest should also enumerate changes to `plugins/cwf/**` and the
  other included paths to fulfill the document's own "omission-resistant"
  goal.

  **Recommendation**: Expand the git command or add a second command:
  ```
  git diff --name-only 42d2cd9..HEAD -- 'prompt-logs/**' 'plugins/cwf/**' \
    'cwf-state.yaml' 'docs/v3-migration-decisions.md'
  ```
  Or instruct the agent to run multiple git commands covering all include
  paths.

- **[S4]** Phase 4 (Bidirectional Consistency Pass) lacks a definition of
  what "early" and "late" mean in the timeline.

  Lines 155-165 describe two passes ("Early -> Late" and "Late -> Early") but
  do not define the ordering axis. Is it chronological by session date
  (per `cwf-state.yaml` `completed_at`)? By git commit date? By session ID
  number? This matters because the session numbering is non-sequential
  (S13.5-A, S13.5-B, S13.5-B2, S13.5-B3, post-B3, S29, S32, S32-impl, S33,
  S14, S15, S16) and some sessions happened on the same date
  (`completed_at: "2026-02-08"` covers S0 through S6b).

  **Recommendation**: Add a one-line definition: "Timeline ordering follows
  `cwf-state.yaml` session sequence (registration order), not git commit
  timestamps or session ID lexical order."

- **[S5]** No error handling or partial-failure protocol.

  The document defines 6 phases and 7 completion criteria but does not
  address what happens if the executing agent encounters a failure mid-way
  (e.g., a file listed in the git range is unreadable, the corpus is too
  large to process in a single session, or auto-compact triggers during the
  analysis).

  Prior implementation sessions benefit from `cwf-state.yaml` `live` section
  for compact recovery and `plugins/cwf/hooks/scripts/compact-context.sh`
  for context injection. An analysis-only session producing 7 artifacts over
  a large corpus is a strong candidate for auto-compact, yet there is no
  guidance on which artifacts to persist first or how to resume.

  **Recommendation**: Add a brief "Resilience" section suggesting: (1) write
  artifacts in phase order so partial progress is preserved, (2) if
  auto-compact occurs, the agent can read already-written artifacts to
  resume, (3) `analysis-manifest.md` should be written first as it serves as
  the foundation for all subsequent phases.

- **[S6]** The `Suggested Output Order to User` section (lines 206-210)
  introduces a presentation concern into what is otherwise a pure execution
  protocol.

  This mixes two responsibilities: instructing the agent *what to produce*
  (the 6-phase workflow + 7 artifacts) and *how to present results to the
  user*. The execution phases already have a natural order. Adding a separate
  "suggested output order" that differs from the execution order (summary
  first, but summary is the last artifact produced) may confuse the executing
  agent about whether to change its execution sequence.

  **Recommendation**: Either move this section into the completion criteria
  as a final "presentation step" (Phase 6: Present results in this order),
  or clarify that this is a post-completion presentation guideline, not an
  execution directive.

- **[S7]** The Korean search terms in Phase 3 (lines 137-139) are not
  accompanied by their English translations.

  While the project operates bilingually (see `AGENTS.md` line 38: "The user
  communicates in Korean"), the handoff document is written in English. An
  executing agent that does not have Korean language context may not
  understand the semantic scope of `후속` (follow-up), `미구현`
  (unimplemented), `논의 필요` (discussion needed). Adding inline
  translations would make the search specification self-contained and
  reduce the risk of an agent treating these as opaque string literals
  rather than semantic categories.

  **Recommendation**: Add inline translations:
  `후속 (follow-up)`, `미구현 (unimplemented)`, `논의 필요 (needs discussion)`.

---

### Provenance

source: FALLBACK
tool: claude-task-fallback
reviewer: Architecture
duration_ms: ---
command: ---

<!-- AGENT_COMPLETE -->
