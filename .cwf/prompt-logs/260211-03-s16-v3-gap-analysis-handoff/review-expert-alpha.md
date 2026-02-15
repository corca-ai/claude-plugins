### Expert Reviewer α: Gojko Adzic

**Framework Context**: Specification by Example — collaborative specification using key examples, living documentation, and concrete illustrations to bridge communication gaps between stakeholders and implementers (source: *Specification by Example*, Gojko Adzic, Manning Publications, 2011; supplemented by *Bridging the Communication Gap*, 2009, and *Fifty Quick Ideas to Improve Your Tests*, 2015)

---

## Review Summary

This is a well-structured analysis protocol that demonstrates significant awareness of omission risks and evidence hierarchy. Viewed through the Specification by Example lens, the document is strongest in its evidence-grounding discipline (the Decision Rationale table, the evidence hierarchy, the "Do Not Skip" constraints) and weakest in two areas that my framework considers critical: (1) the absence of concrete, illustrative key examples that would make the abstract phases executable without ambiguity, and (2) the lack of a collaborative specification mechanism that would allow the human stakeholder to validate the protocol's intent before the analysis agent commits to a full six-phase run.

I will focus my review on three areas where the Specification by Example framework reveals structural risks that surface-level analysis may miss.

---

#### Concerns (blocking)

- [High] **No key examples anchor the phase definitions — abstract process descriptions invite interpretation drift**
  Section: "Required Workflow", Phases 0-5

  In *Specification by Example*, I documented how teams across fifty projects consistently failed when specifications were "described at the wrong level of abstraction" — when they relied on procedural prose rather than concrete illustrations of what "done" looks like (SbE, Chapter 5: "Illustrating Using Examples"). The six phases in this protocol describe *activities* (e.g., "Extract user statements from session logs") but never show a single concrete example of what a well-formed row in `user-utterances-index.md` or `coverage-matrix.md` actually looks like.

  This matters because the executing agent must make dozens of micro-decisions: What counts as a "verbatim user statement (short)"? How short? Does a Korean-language utterance get translated or preserved? What granularity is a "theme tag"? Is `quality-feedback` a valid tag, or should it be `quality > feedback > hook-execution`? The protocol gives field names but no key examples, which is precisely the "telephone game" problem I describe in *Bridging the Communication Gap* (Chapter 3) — each intermediary reinvents their own interpretation.

  **Recommendation**: Add one fully worked key example row for each artifact format. For instance, `coverage-matrix.md` should include a sample row like:

  ```
  | #7: Hook toggle system | Implemented | plugins/cwf/hooks/hooks.json, ~/.claude/cwf-hooks-enabled.sh | S13.5-B verified |
  ```

  And `user-utterances-index.md` should include:

  ```
  | 260209/S14 | "Codex 로그도 동일 가중치로 포함해야" | evidence-parity | cwf-state.yaml codex entry | reflected |
  ```

  A single worked example per artifact eliminates more ambiguity than a page of procedural description. This is the core insight from *Focus on Key Examples* (gojko.net, 2014): "a small number of relatively simple scenarios that will be easy to understand, evaluate for completeness and criticise" serves specifications far better than exhaustive procedural instructions.

- [High] **Completion criteria are existence-based, not content-based — they cannot detect a hollow pass**
  Section: "Completion Criteria"

  The seven completion criteria all check for file existence and surface-level structural properties ("has evidence-linked status for all required rows", "includes one-way findings"). None of them specify a minimum content threshold or a behavioral validation that would distinguish a thorough analysis from a superficial one.

  In *Fifty Quick Ideas to Improve Your Tests* (Idea #12: "Check that outputs have expected properties"), I argue that the most dangerous tests are those that pass when the system produces technically valid but substantively empty output. The current completion criteria permit an agent to create `gap-candidates.md` with a single row classified as "Unknown" and satisfy criterion #4 ("contains explicit `Unknown` bucket if applicable").

  **Recommendation**: Add at least one quantitative floor per artifact. For example: "coverage-matrix.md covers all 20 master-plan decisions with non-Unknown status for at least 15" or "user-utterances-index.md contains at least N entries spanning at least M distinct sessions." These need not be exact — they serve as key examples of expected scale, which helps the executing agent calibrate effort. Alternatively, define a "sanity check" phase (Phase 5.5) where the agent presents artifact counts to the human before proceeding to the discussion backlog, creating a collaborative validation gate.

---

#### Suggestions (non-blocking)

- **The protocol would benefit from a "Specify Collaboratively" checkpoint before Phase 3**

  In *Specification by Example*, the process pattern sequence is: (1) Deriving scope from goals, (2) Specifying collaboratively, (3) Illustrating using examples, (4) Refining the specification, (5) Automating validation without changing specifications, (6) Validating frequently, (7) Evolving a living documentation system.

  The current protocol jumps from evidence collection (Phases 0-2) directly into gap mining (Phase 3) without a collaborative checkpoint where the human reviews the coverage matrix and utterance index for calibration. This is risky because Phases 3-5 build upon the completeness and accuracy of Phases 0-2. If the corpus manifest misses a session directory, or the coverage matrix misclassifies a "Partial" as "Implemented", all downstream gap analysis inherits that error silently.

  Adding an explicit human-review gate after Phase 2 — even a lightweight one ("Present artifact counts and 3 sample rows to user for confirmation before proceeding") — would embody the "Specifying Collaboratively" pattern and catch corpus-level errors before they propagate.

- **The Evidence Hierarchy should be illustrated with a conflict resolution example**

  The three-tier evidence hierarchy (Implementation truth > Intent truth > Conflict rule) is well-designed in principle, but the conflict rule ("Final status follows post-discussion artifact/code reflection / Original conflicting intent remains logged in Context/History") is abstract enough to be applied inconsistently. A single concrete scenario — e.g., "User requested feature X in S13, it was deferred in master-plan.md, then partially implemented in S14 hooks but never recorded in cwf-state.yaml — classify as Partial with history note" — would make the hierarchy a living specification rather than a policy statement.

  This aligns with my observation in *Bridging the Communication Gap* that "examples are simply a very effective communication technique" — the hierarchy is a rule, but a rule without an illustrative example is a specification waiting to be misinterpreted.

- **The "Do Not Skip" section could be reframed as falsifiable assertions**

  The four "Do Not Skip" items are stated as prohibitions ("Do not discard low-confidence items"). In the Specification by Example framework, prohibitions are weaker than positive assertions because they tell the agent what *not* to do without specifying what the correct behavior *looks like*. Reframing as positive, testable assertions would be stronger:

  - "Every item with insufficient evidence appears with status `Unknown`, not omitted" (testable: grep for items without status)
  - "Every resolution claim includes an evidence path to a specific file or commit" (testable: check for bare claims)
  - "Sessions without `session.md` appear in the corpus manifest" (testable: compare git diff output against manifest)
  - "Codex session logs appear in `user-utterances-index.md`" (testable: check for sessions-codex source entries)

  These reformulations make the constraints verifiable by the agent itself or by a reviewer, turning prohibitions into living documentation checkpoints.

- **Consider defining the `summary.md` artifact's structure**

  All six non-summary artifacts have structural definitions (field lists, categories, format requirements). The seventh artifact, `summary.md`, is described only as "a concise executive summary." This asymmetry means the most reader-facing artifact is the least specified. Even a minimal structure — e.g., "top 3 unresolved gaps, top 3 intent drift items, recommended decision order" — would make the summary a key example of what S17's output should communicate rather than leaving it to agent interpretation.

---

#### Framework Fit Assessment

The Specification by Example lens is a strong fit for this review target. The `next-session.md` document is essentially a specification for an analysis session — it defines inputs, process, outputs, and completion criteria. This maps directly onto the problem domain my framework addresses: how to write specifications that are executable, unambiguous, and resistant to the "telephone game" of interpretation drift.

The document's greatest strength from my framework's perspective is the Decision Rationale table. This is an excellent example of what I call "living documentation" — not just the rule, but the *why* behind the rule and the *risk* of omitting it. This table alone makes the protocol significantly more robust than a bare procedural checklist, because it enables an executing agent (or a future session) to reason about trade-offs rather than blindly following steps.

The document's greatest weakness is the gap between the quality of its procedural structure and the absence of concrete key examples. The protocol knows *what* to collect and *why*, but does not show *what good output looks like*. In my experience across the fifty projects documented in *Specification by Example*, this gap is where the majority of specification failures originate — not in missing rules, but in missing illustrations.

---

#### Verdict: Conditional Pass

The protocol is structurally sound and demonstrates sophisticated awareness of omission risks, evidence hierarchy, and bidirectional analysis. The Decision Rationale table and the "Do Not Skip" constraints show genuine specification discipline. However, the absence of key examples for each artifact format and the existence-only completion criteria create a real risk that a technically compliant execution could produce shallow or inconsistently formatted results. Adding one worked example row per artifact and one quantitative floor per completion criterion would elevate this from a good procedural checklist to a robust, self-validating specification.

---

#### Provenance

- source: REAL_EXECUTION
- tool: claude-task
- expert: Gojko Adzic
- framework: Specification by Example (collaborative specification, key examples, living documentation)
- grounding: *Specification by Example* (Manning, 2011), *Bridging the Communication Gap* (Neuri, 2009), *Fifty Quick Ideas to Improve Your Tests* (Neuri, 2015), "Focus on Key Examples" (gojko.net, 2014-05-05), "Specifying with Examples" (gojko.net, 2008-11-04), gojko.net/books/ (verified 2026-02-11)
<!-- AGENT_COMPLETE -->
