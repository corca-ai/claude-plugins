### Expert Reviewer Beta: Nancy Leveson

**Framework Context**: Systems-Theoretic Accident Model and Processes (STAMP) / System-Theoretic Process Analysis (STPA) -- treating safety as a dynamic control problem where losses result from inadequate enforcement of safety constraints by the system's control structure, not merely from component failures (source: *Engineering a Safer World: Systems Thinking Applied to Safety*, MIT Press, 2011; supplemented by *STPA Handbook*, Leveson & Thomas, 2018)

---

## Review Summary

The S17 handoff document (`next-session.md`) defines an analysis protocol intended to be "omission-resistant." Through the STAMP/STPA lens, I treat this protocol as a **safety control structure** -- the document is a controller that must enforce safety constraints (completeness, accuracy, traceability) on a controlled process (the S17 analysis session). Losses in this context are not physical harm but **epistemic losses**: silent omissions, false completions, uncaught intent drift, and premature closure of genuinely unresolved items.

The protocol shows significant design strength in its evidence hierarchy, its explicit "Unknown" status preservation, and its Decision Rationale table. However, applying STPA's four categories of unsafe control actions reveals structural gaps in the control structure that could permit the very omission failures the protocol is designed to prevent.

I will focus my analysis on three areas where the STAMP framework reveals control-structure deficiencies that other analytical lenses are less equipped to detect.

---

#### Concerns (blocking)

- [Critical] **The control structure lacks feedback channels -- the protocol is open-loop with respect to its own completeness constraints**
  Section: Entire document; specifically "Required Workflow" (Phases 0-5) and "Completion Criteria" (lines 186-196)

  In STAMP, the most dangerous system architectures are those that operate open-loop: the controller issues commands but receives no feedback about whether the controlled process has actually achieved the desired state. In *Engineering a Safer World* (Chapter 4: "STAMP: An Accident Causality Model"), I identify "inadequate or missing feedback" as one of the primary causal factors in control structure failures. The classic pattern is: a controller believes the system is in a safe state because it issued the correct command, while in reality the controlled process has drifted into an unsafe state that the controller cannot observe.

  This protocol exhibits precisely this pattern. Consider the control flow:

  1. The protocol (controller) specifies that Phase 0 must produce a corpus manifest with "counts by category" and "any missing or unreadable files."
  2. Phases 1-5 consume this manifest as their input corpus.
  3. The Completion Criteria check that `analysis-manifest.md` "exists with counts and missing-file note."

  At no point does the control structure verify that the manifest is **complete relative to the actual scope**. There is no feedback loop that compares the manifest's file count against an independently derived expected count (e.g., from `cwf-state.yaml` session count, or from the git range's total file count across all included paths). The protocol assumes that if the git command executes and produces output, the corpus is complete. But the git command on line 77 only covers `prompt-logs/**`, while the Hard Scope Anchor (lines 28-35) includes `plugins/cwf/**`, `cwf-state.yaml`, `master-plan.md`, and `v3-migration-decisions.md`. This is not merely a "missing path" bug -- it is an **open-loop control deficiency** where the controller has no way to detect that its own scope specification was not fully executed.

  In STPA terms, the unsafe control action here is: **"Controller provides control action (proceed to Phase 1) when the process variable (corpus completeness) has not been verified."** This is a Type 2 UCA (control action provided too early / before prerequisites satisfied) combined with a missing feedback channel.

  **Recommendation**: Add a verification gate between Phase 0 and Phase 1. The gate should:
  (a) Independently compute expected file counts from all scope-anchor paths (not just `prompt-logs/**`).
  (b) Compare manifest counts against expected counts.
  (c) Halt with an explicit discrepancy report if mismatch exceeds a threshold.
  This transforms the open-loop Phase 0 -> Phase 1 transition into a closed-loop transition with feedback.

- [High] **No process model for the executing agent's state -- the protocol cannot detect when the agent's internal model has diverged from reality**
  Section: "Evidence Hierarchy" (lines 39-51), "Phase 4: Bidirectional Consistency Pass" (lines 155-165)

  In STAMP, every controller maintains a **process model** -- an internal representation of the controlled process's state that the controller uses to make decisions. Accidents occur when the process model becomes inconsistent with reality ("the controller's model of the process diverges from the actual process state" -- *Engineering a Safer World*, Chapter 4, Section 4.2.3). This is the fundamental causal mechanism in STAMP: not component failure, but model-reality mismatch.

  The S17 protocol defines an Evidence Hierarchy (implementation truth > intent truth) and a Conflict Rule (post-discussion reflection outranks early intent). These are correct classification rules. But the protocol does not specify how the executing agent should **maintain and update its process model** as it works through the phases. Specifically:

  - Phase 1 builds a coverage matrix based on reading implementation files.
  - Phase 2 extracts user utterances from session logs.
  - Phase 3 mines for gap candidates.
  - Phase 4 runs a bidirectional consistency pass.

  Each phase produces new information that could **invalidate classifications made in earlier phases**. For example, a user utterance discovered in Phase 2 might reveal that a feature classified as "Implemented" in Phase 1 was actually implemented incorrectly or incompletely relative to user intent. A gap candidate found in Phase 3 might reveal that a "Superseded" classification in Phase 1 was premature -- the supersession was discussed but never reflected in code.

  The protocol does not instruct the agent to propagate these discoveries backward. Phase 4 (Bidirectional Consistency Pass) is the closest mechanism, but it operates at the timeline level ("Early -> Late" and "Late -> Early"), not at the inter-phase level. There is no instruction to update Phase 1's coverage matrix based on Phase 2's utterance discoveries, or to revise Phase 2's "reflected/unreflected" classifications based on Phase 3's gap mining results.

  In STPA terms, the unsafe control action is: **"Controller maintains stale process model (earlier phase classifications) while making decisions based on new information (later phase discoveries)."** This is a Type 3 UCA (control action applied too long / not updated when conditions change).

  **Recommendation**: Add an explicit "back-propagation step" after Phase 4 that instructs the agent to revisit and update Phases 1-3 artifacts based on consistency-check findings. Alternatively, restructure Phase 4 as an inter-phase reconciliation step (not just a timeline pass) that explicitly checks: "Does any Phase 2 utterance contradict a Phase 1 classification? Does any Phase 3 gap candidate invalidate a Phase 2 status?"

- [High] **The "Do Not Skip" constraints are unenforced safety constraints -- they exist as policy but have no control mechanism**
  Section: "Do Not Skip" (lines 198-204)

  In *Engineering a Safer World* (Chapter 2), I make a distinction that is central to STAMP: "Safety constraints are not the same as safety goals. A safety goal is a desired property. A safety constraint is an enforceable restriction on system behavior." The four "Do Not Skip" items (lines 199-204) are stated as prohibitions:

  1. Do not discard low-confidence items; classify as `Unknown`.
  2. Do not infer resolution without evidence path.
  3. Do not treat `session.md` presence as completeness proof.
  4. Do not ignore Codex logs because they are shorter.

  These are safety constraints in intent but safety goals in practice. The protocol provides no enforcement mechanism, no detection mechanism, and no feedback mechanism for violations. In a physical safety system, this would be equivalent to posting a sign that says "Do not exceed pressure limit" without installing a pressure relief valve or a pressure sensor.

  Consider constraint #2: "Do not infer resolution without evidence path." How would anyone (the agent itself, a reviewer, the human stakeholder) detect a violation? The Completion Criteria (lines 186-196) do not require evidence paths for every resolution claim. The `gap-candidates.md` format (lines 142-152) specifies "Resolution evidence if any" -- the qualifier "if any" explicitly permits resolution claims without evidence, which directly contradicts constraint #2.

  In STPA terms, this is a **missing control action**: the constraint exists but no controller enforces it. The safety constraint is formally specified but operationally inert.

  **Recommendation**: For each "Do Not Skip" constraint, add a corresponding verification check in the Completion Criteria. For example:
  - Constraint #2 becomes: "Every `Resolved` classification in `gap-candidates.md` includes a non-empty `Resolution evidence` field referencing a specific file path or commit."
  - Constraint #4 becomes: "`user-utterances-index.md` contains at least one entry with source path matching `sessions-codex/`."
  Change `gap-candidates.md` field from "Resolution evidence if any" to "Resolution evidence (required for Resolved status; N/A for Unresolved/Unknown)."

---

#### Suggestions (non-blocking)

- **Model the S17 protocol as an explicit control structure diagram**

  In STPA practice, the first analytical step is always to draw the hierarchical safety control structure: identify controllers, controlled processes, control actions, and feedback channels (see *STPA Handbook*, Leveson & Thomas, 2018, Chapter 2: "Modeling the Control Structure"). The S17 protocol implicitly defines a control structure:

  - **Controller**: The `next-session.md` protocol document + the human stakeholder
  - **Controlled process**: The executing agent performing Phases 0-5
  - **Control actions**: Phase instructions, classification rules, evidence hierarchy
  - **Feedback channels**: Completion criteria checks (currently existence-only)
  - **Process model**: The agent's accumulated understanding of CWF v3 state

  Making this structure explicit -- even as a simple text diagram in the document -- would help identify where control actions lack corresponding feedback, where the process model can diverge, and where the human stakeholder's oversight role is undefined. Currently, the human stakeholder appears in the "Suggested Output Order to User" section but not in the control loop itself. The human is a recipient of final output, not a controller providing mid-process feedback. This is a single-point-of-control architecture with no redundancy.

- **Define the "controlled process boundary" for Phase 3's open-ended search**

  Phase 3 instructs mining for `deferred`, `unimplemented`, `pending`, `TODO`, Korean equivalents, and "equivalent unresolved markers." The last category is unbounded. In safety engineering, unbounded search spaces are hazardous because the controller cannot distinguish between "search complete, no more results" and "search terminated before completion." This is the classic "absence of evidence vs. evidence of absence" problem that STAMP explicitly addresses through the concept of **safety constraint completeness** (*Engineering a Safer World*, Chapter 8: "Completeness").

  Adding a finite, enumerated list of search terms (even if long) and an explicit "other terms found during search" overflow bucket would make the search boundary verifiable. The agent can then report: "Searched for N defined terms plus M additional terms discovered during analysis" -- a closed-form completeness claim rather than an open-ended one.

- **Add a "degraded mode" protocol for partial completion**

  STAMP emphasizes that systems must be designed for degraded-mode operation, not just nominal-mode operation (*Engineering a Safer World*, Chapter 11: "Designing for Safety"). The current protocol is all-or-nothing: either all seven completion criteria are met, or the session is incomplete. But an analysis session operating on a large corpus may encounter context-window limits, auto-compact triggers, or time constraints that prevent full completion.

  A degraded-mode protocol would specify: (1) a priority ordering for artifacts (which to produce first if resources are limited), (2) a minimum viable output (e.g., "manifest + coverage matrix + summary constitutes a viable partial delivery"), and (3) explicit marking of which phases were completed vs. skipped in the summary. This is analogous to the safety engineering principle of "graceful degradation" -- the system should fail partially and visibly rather than fail completely or fail silently.

- **The Decision Rationale table is an exemplary safety constraint documentation practice -- extend it to cover the "Do Not Skip" items**

  The Decision Rationale table (lines 57-66) is the strongest element of this document from a STAMP perspective. It documents not just the rule but the **loss scenario** that motivated the rule ("Risk if omitted"). This is precisely the format I advocate for safety constraint documentation in *Engineering a Safer World* (Chapter 8): every constraint should be traceable to the hazard it prevents.

  The "Do Not Skip" items (lines 198-204) lack this traceability. Extending the Decision Rationale table to include these four constraints -- with explicit "Risk if violated" columns -- would make the protocol's safety case internally complete. For example: "Do not discard low-confidence items | Risk: False closure on potentially critical gaps, loss of omission-resistance guarantee."

---

#### Framework Fit Assessment

The STAMP/STPA lens is a strong fit for this review target. The `next-session.md` document defines a control structure for a complex analytical process where the primary hazards are epistemic -- silent omissions, false completions, model-reality divergence, and unenforced constraints. These are precisely the classes of system-level hazards that STAMP was designed to analyze: not failures of individual components, but inadequacies in the control structure that permits unsafe system states.

The document's design philosophy -- evidence hierarchies, conflict rules, bidirectional consistency checks, explicit "Unknown" preservation -- demonstrates a sophisticated awareness of the problem space. The gaps I identified are not design errors but **control-structure incompleteness**: the protocol specifies what the correct behavior should be but does not always provide the mechanisms to enforce or verify that behavior. This is the most common pattern in the systems I analyze -- well-intentioned safety requirements that lack the control-theoretic infrastructure to be operationally effective.

The STAMP framework is less useful for the document's presentational and formatting aspects (which Expert Alpha's Specification by Example lens addresses well) and more useful for the document's structural and procedural aspects -- specifically, where open-loop control, missing feedback, stale process models, and unenforced constraints create systemic risk.

---

#### Verdict: Conditional Pass

The protocol demonstrates strong analytical design with its evidence hierarchy, "Unknown"-preservation philosophy, bidirectional consistency pass, and Decision Rationale table. These elements show genuine systems-level thinking about omission resistance. However, the STAMP/STPA analysis reveals three structural control deficiencies that, if unaddressed, could permit the very epistemic losses the protocol is designed to prevent:

1. **Open-loop corpus verification** (no feedback between manifest completeness and actual scope).
2. **No inter-phase back-propagation** (later discoveries do not update earlier classifications).
3. **Unenforced safety constraints** (the "Do Not Skip" items are policy without mechanism).

Addressing these three issues -- by adding a Phase 0/1 verification gate, an inter-phase reconciliation step, and enforceable completion criteria tied to each "Do Not Skip" constraint -- would close the control loops and make the protocol's omission-resistance claim structurally sound rather than aspirationally stated.

---

#### Provenance

- source: REAL_EXECUTION
- tool: claude-task
- expert: Nancy Leveson
- framework: STAMP/STPA (Systems-Theoretic Accident Model and Processes / System-Theoretic Process Analysis)
- grounding: *Engineering a Safer World: Systems Thinking Applied to Safety* (MIT Press, 2011), *STPA Handbook* (Leveson & Thomas, 2018, available at psas.scripts.mit.edu), verified via Tavily search 2026-02-11: MIT Press Direct (direct.mit.edu/books/oa-monograph/2908), sunnyday.mit.edu/safer-world.pdf, STPA Handbook (flighttestsafety.org/images/STPA_Handbook.pdf)
<!-- AGENT_COMPLETE -->
