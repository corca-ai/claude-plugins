## UX/DX Review

**Target**: `/home/hwidong/codes/claude-plugins/.cwf/projects/260217-01-refactor-review/review-and-prevention.md`
**Mode**: plan (post-incident prevention proposal)

---

### Concerns (blocking)

- **[C1]** Proposal E+G introduces `remaining_gates` and `user_directive` as new fields in `cwf-state.yaml` live section (Section 6, Proposal G, lines 297-306), but `cwf-live-state.sh` `cwf_live_validate_scalar_key()` (line 244-254 in `plugins/cwf/scripts/cwf-live-state.sh`) explicitly blocks non-scalar keys and has a hard-coded deny-list. The proposal specifies `remaining_gates` as a comma-separated string (`"review-code,refactor,retro,ship"`), but it is semantically a list. This creates a naming/type inconsistency with the existing `live.key_files` (YAML list), `live.decision_journal` (YAML list), and `live.decisions` (YAML list). The `set` subcommand only handles scalar string upsert -- so `remaining_gates` would be stored as a raw string while all other multi-value fields are YAML lists. This means the proposed `workflow-gate.sh` hook would need to parse the string with a comma-split, while other hooks/scripts consuming lists use YAML array parsing. **No convention or migration path is specified for this representational mismatch.** A developer reading the state file will see two different patterns for list-like data and have no guidance on which to use.
  Severity: moderate

- **[C2]** Proposal E states the hook should be added as a `UserPromptSubmit` hook or integrated into `attention.sh` (Notification hook) (Section 6, Proposal E, point 2, line 267). These are fundamentally different injection points with different timing semantics. `UserPromptSubmit` fires before the agent processes user input -- the hook output becomes part of the prompt context. `Notification` fires when the agent goes idle. Proposal E's ASCII diagram (lines 251-260) shows the injection as "UserPromptSubmit or Notification hook output" without resolving which one. **This ambiguity is a blocking DX concern**: the hook placement determines whether the gate message is seen *before* the agent acts or *after* it has already acted. For a safety gate whose purpose is to prevent skipping workflow stages, only `UserPromptSubmit` provides the correct timing guarantee. The document must specify a single, definitive hook event and explain why.
  Severity: critical

- **[C3]** Proposal A (Deletion Safety Gate, lines 163-181) defines its caller check as: `grep -r "filename" --include="*.sh" --include="*.md" --include="*.mjs"`. This instruction is embedded in prose/markdown rule text intended for `plugins/cwf/skills/impl/SKILL.md`. However, AGENTS.md (line 13) establishes the invariant: "Deterministic gates define pass/fail authority; prose must not duplicate or override them." A `grep`-based caller check described in prose is not a deterministic gate -- it relies on the agent voluntarily executing it. **This contradicts the project's own operating invariant.** The proposal should either (a) acknowledge this is a soft/advisory rule and not call it a "gate," or (b) specify how to make it a deterministic gate (e.g., a hook script or a pre-commit check), which would then overlap with Proposal D (script dependency graph). As written, calling it a "safety gate" in prose-only form creates a false sense of protection.
  Severity: moderate

- **[C4]** Proposal E's `cwf-state.yaml` schema extension adds `workflow` and `user_directive` fields (Section 6, Proposal E, lines 265-266). The existing `cwf-state.yaml` already has a top-level `workflow:` key (line 4 of `.cwf/cwf-state.yaml`) that contains `current_stage` and `stages`. The proposal puts `workflow: "cwf:run"` inside the `live:` section. **This creates a naming collision**: `workflow` at root level means the project-level workflow definition (stages S0-S15), while `live.workflow` would mean the currently-active skill invocation. A developer or script reading `workflow` from the state file could easily conflate these two different concepts. The proposal should use a distinct key name (e.g., `active_pipeline`, `run_workflow`, or `active_chain`) to avoid semantic collision with the existing root-level `workflow` key.
  Severity: moderate

### Suggestions (non-blocking)

- **[S1]** Proposal B (Broken-link triage, lines 183-204) defines a decision matrix but does not specify **where the triage decision is recorded**. CWF skills generally persist decisions in `lessons.md` or `live.decision_journal`. Adding a single sentence like "Record the triage decision and outcome in `lessons.md`" would close the audit loop and align with the project's context-recovery philosophy. Without this, a triage decision made in one turn could be lost to compaction -- the very failure mode this document is trying to prevent.

- **[S2]** The Priority and Effort Matrix (Section 7, lines 313-321) labels three proposals as "P0 -- do now" (A, B, E+G). This is an unusually high number of simultaneous P0 items. From a DX perspective, implementers benefit from a clear sequencing recommendation even within the same priority tier. Proposal A is described as "Small" effort, Proposal B as "Small", and E+G as "Medium." A suggested implementation order (A first, then B, then E+G) would reduce cognitive load and allow each proposal to be independently validated before the more complex hook work begins.

- **[S3]** Proposal F (Session log review mode, lines 277-291) lists 5 cross-check items but provides no example of what a detected anomaly would look like in the review output. The other proposals (A, B) include concrete decision matrices and action tables. Adding a brief example output for Proposal F (e.g., "FLAG: Task #6 planned `cwf:run` invocation but execution trace shows 0 Skill tool calls for `cwf:run`") would make the proposal more actionable for the implementer building the review mode extension.

- **[S4]** The 5-Whys analysis (Section 2, lines 50-56) and session log analysis (Section 4, lines 96-128) are written entirely in Korean, while the proposals (Section 6) mix Korean headers with English bodies. The project's AGENTS.md (line 8) specifies: "Respond in Korean for conversation and English for code/docs." Since this document is a design doc (not conversation), it would improve consistency to either commit to English throughout or clearly delineate Korean sections (analysis/narrative) from English sections (spec/implementation). The current mixed pattern could confuse a contributor trying to extract implementation specs.

- **[S5]** Proposal C (Analysis-to-impl fidelity check, lines 208-219) says "follow the original, not the triage summary" but does not define what "original analysis document" means in terms of file path conventions. CWF sessions produce many artifacts (`refactor-deep-*.md`, `analysis.md`, etc.). Specifying a concrete path pattern (e.g., "the `analysis.md` or `refactor-deep-*.md` file in the same session directory") would reduce ambiguity for the impl agent that must locate and cross-reference the source.

- **[S6]** Proposal E's ASCII diagram (lines 246-260) is a strong visualization of the injection flow. However, the `user_directive` field stores a raw user utterance string ("cwf:run 최대한 사용"). No normalization or validation is proposed for this field. If the user says "use cwf:run as much as possible" or "cwf:run please" or "워크플로 돌려", the hook would need to match heterogeneous directive strings. Consider either (a) normalizing `user_directive` to a canonical enum value at write time (e.g., `"enforce_full_pipeline"`) or (b) clarifying that this field is informational-only and the hook acts solely on the presence of the `workflow` field, not the directive content.

- **[S7]** The document does not include measurable success criteria for any of the 7 proposals. For a prevention proposal, BDD-style acceptance checks (following the pattern established in `plugins/cwf/skills/review/SKILL.md` lines 675-699) would make verification unambiguous. For example, Proposal A could include: "Given an impl agent executing a triage item that calls for `git rm <file>` / When `<file>` is referenced by another script via `source`, `bash`, or `$()` / Then the agent does NOT delete the file and instead adds a missing reference." Without these, the implementer and reviewer have no shared definition of "done."

### Provenance
source: REAL_EXECUTION
tool: claude-task
reviewer: UX/DX
duration_ms: ---
command: ---
<!-- AGENT_COMPLETE -->
