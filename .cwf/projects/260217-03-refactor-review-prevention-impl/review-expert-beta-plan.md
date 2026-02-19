### Expert Reviewer B: W. Edwards Deming

**Framework Context**: Systems thinking, common cause vs special cause variation, PDCA cycle, "cease dependence on inspection" (Point 3) -- Out of the Crisis (MIT Press, 1986)

---

#### Preliminary: Common Cause vs Special Cause Diagnosis

Before evaluating the proposals, the fundamental question must be answered: Was the csv-to-toon.sh deletion incident a **special cause** (an aberrant event in an otherwise stable process) or a **common cause** (a predictable outcome of the system's design)?

The evidence overwhelmingly indicates **common cause variation**:

1. The signal chain (analysis -> triage -> impl) lost fidelity at each handoff. This is not an unusual failure -- it is the *expected behavior* of any multi-stage information pipeline without built-in verification at each stage boundary.
2. The context compaction mechanism systematically eroded the user's directive ("use cwf:run") across 4 compaction cycles. This is not operator error; it is an architectural property of the system.
3. The broken-link pre-push hook *did* fire and detect the symptom, but the agent's response (remove the reference) was the locally rational action given available information. The hook provided the wrong affordance.

When a system produces defects as a natural consequence of its design, Deming's Point 3 is clear: **cease dependence on inspection to achieve quality; build quality into the process itself.** The question for each proposal is whether it transforms the process or merely adds another inspection layer.

---

#### Analysis of Each Proposal

**Proposal A (Deletion Safety Hook): Process Transformation -- APPROVED**

This is the strongest proposal precisely because it intervenes at the *decision point* -- the moment when `git rm` or `rm` is executed. It does not rely on a downstream reviewer catching the error after the fact. It does not depend on the agent reading documentation. It is a structural constraint that makes the defective action impossible (or at minimum, requires explicit override).

From Point 3, this is the correct type of intervention: quality is built into the deletion operation itself, not inspected afterwards. The fail-closed design (exit 1 on parse error) correctly treats false positives as preferable to false negatives. The exclusion of `.cwf/projects/` paths is appropriate -- session artifacts are ephemeral and should not constrain runtime operations.

However, I note one concern: **the grep-based caller detection is inherently incomplete**. Variable interpolation (`"$SCRIPT_DIR/csv-to-toon.sh"`), dynamic sourcing, and indirect references will evade static grep. The plan acknowledges this implicitly by listing specific file extensions, but never explicitly states the limitation. This is an honest limitation of the tool, not a design flaw -- but it should be documented so operators understand the boundary of protection.

**Proposal B (Broken-Link Triage Protocol): Documentation -- CONDITIONAL**

This proposal adds a decision matrix to `agent-patterns.md` and a hint line to the check-links-local.sh error output. The triage protocol itself is well-designed: it classifies callers by type (runtime/build/test/docs/stale) and maps each classification to a specific action. The decision matrix eliminates the ambiguity that led the agent to choose "remove reference" as the default.

However, this is fundamentally a *documentation* intervention. Its effectiveness depends entirely on the agent reading and following the protocol at the moment of decision. Documentation is vulnerable to the same compaction-driven fidelity loss that caused the original incident. The saving grace is the hook hint line -- by embedding the protocol reference directly in the error output of check-links-local.sh, the triage guidance appears precisely when the agent needs it, regardless of what has been compacted away. **The hint line is the mechanism that elevates this from pure documentation to a process-embedded signal.**

The concern: the plan specifies adding the hint to the "block decision output (around line 82)" of check-links-local.sh. Looking at the actual file, line 82 is the `cat <<EOF` that outputs the block JSON. The hint should be added to the `reason` field so it appears in the decision output the agent sees. This is a minor implementation detail but critical for the mechanism to work.

**Proposal C (Recommendation Fidelity Check): Inspection -- WEAKEST**

This is the proposal I am most skeptical of. Adding a rule to impl SKILL.md that says "for each triage item referencing an analysis document, read the original recommendation and compare" is, in Deming's terms, **adding an inspection step to compensate for a process that does not build quality in**.

The root cause was fidelity loss in the analysis-to-triage pipeline. The correct systemic fix would be to change the triage output format to *require* the original recommendation alongside the action -- making contradiction structurally visible. Instead, this proposal asks the impl agent to manually cross-reference documents, which is exactly the kind of inspection step that will be forgotten, skipped, or misapplied under time pressure or context compaction.

That said, I understand why it was included: it is cheap to implement (one rule addition) and provides a defense-in-depth layer. I do not object to its inclusion, but I want to be clear that it addresses a symptom. The real fix for fidelity loss is structural: the triage format itself should carry the original recommendation. This is not in scope for this session, but should be a P1 follow-up.

**Proposal E+G (Workflow Enforcement Hook): Process Transformation -- APPROVED WITH NOTES**

This is the most ambitious and arguably most important proposal. The core insight is sound: hooks are injected every turn and survive context compaction, making them the only reliable enforcement mechanism for multi-stage workflows.

The PDCA cycle (Plan-Do-Check-Act) analysis:

- **Plan**: cwf:run establishes the pipeline with `remaining_gates`
- **Do**: Each stage executes
- **Check**: workflow-gate.sh reads state on every UserPromptSubmit and verifies compliance
- **Act**: Block non-compliant actions (ship without review-code), prompt stage invocation

This is a genuine PDCA loop embedded in the process, not an inspection layer. The fail-closed gate (blocking ship when review-code is pending) addresses the exact failure mode: the agent proceeding past gates because the user's directive was compacted away.

The recovery layer (stale pipeline detection, cleanup prompt, state_version for CAS-style write detection) demonstrates systems thinking -- acknowledging that the enforcement mechanism itself can fail and designing recovery paths.

Notes:

1. **The `list-set` / `list-remove` CLI additions to cwf-live-state.sh are well-scoped.** Keeping list operations as separate subcommands rather than overloading `set` with type detection follows the existing explicit API style. The gate name validation against a hard-coded enum prevents typos but introduces a maintenance burden: every new stage added to cwf:run's manifest must also be added to the enum.

2. **The UserPromptSubmit hook being synchronous (not async) is correct.** The existing `track-user-input.sh` is async because it performs Slack I/O and does not need to block agent action. `workflow-gate.sh` must block because its purpose is to prevent action before the prompt is processed. This is a meaningful distinction from the existing convention and should be called out explicitly in the hooks.json entry (the plan does this).

3. **The SKILL.md changes to cwf:run (Phase 1/2/3 state management) are the glue that makes this work.** Without the skill writing `remaining_gates` on init and removing completed stages on each transition, the hook has nothing to enforce. This is the "build quality into the process" part -- the enforcement is structural, not advisory.

---

#### Success Criteria Verification

**Behavioral (BDD):**

- [x] Proposal A: File deletion with runtime callers -> hook exits 1 with BLOCKED message
  - Plan Step 1 specifies `exit 1` with JSON `{"decision":"block","reason":"BLOCKED: {file} has runtime callers: {list}"}`. Correctly mapped to the existing hook decision output convention.

- [x] Proposal A: File deletion with no callers -> hook exits 0 silently
  - Plan Step 1 specifies `exit 0` (silent pass). Matches existing convention (check-links-local.sh exits 0 for non-markdown files).

- [x] Proposal A: grep/parse failure -> hook exits 1 (fail-closed)
  - Plan Step 1 explicitly states: "If grep/parse error: `exit 1` (fail-closed)". This is the correct behavior. Note: this differs from check-links-local.sh which exits 0 for some failure modes (file not found, not markdown). The difference is justified: deletion safety should fail-closed while link checking can be permissive for non-applicable files.

- [x] Proposal B: Broken link error includes triage protocol reference
  - Plan Step 2 specifies modifying check-links-local.sh to "append a hint line to the reason." The mechanism is correct. Implementation must ensure the hint appears within the `reason` field of the JSON output, not as a separate line after the JSON.

- [x] Proposal C: Triage action contradiction -> follow original recommendation
  - Plan Step 4 adds the rule to impl SKILL.md Rules section. The behavioral test is inherently soft (it depends on agent compliance with a text rule), but the rule text is clear and actionable.

- [x] Proposal E+G: remaining_gates includes review-code + ship attempt -> hook exits 1
  - Plan Step 3, item 2 (workflow-gate.sh), point 4: "If `remaining_gates` contains `review-code` AND prompt mentions ship/push/merge: `exit 1` with block message." This is the fail-closed gate.

- [x] Proposal E+G: Stage completion -> list-remove updates YAML list
  - Plan Step 3, item 1: `list-remove` CLI subcommand. SKILL.md changes (item 4) specify "after each stage completes, `list-remove` the completed stage from `remaining_gates`."

- [x] Proposal E+G: Stale active_pipeline -> cleanup prompt output
  - Plan Step 3, item 2 (workflow-gate.sh): "Recovery: if `active_pipeline` exists from a previous session (different `session_id`), output cleanup prompt."

- [x] Proposal E+G: active_pipeline set + empty remaining_gates -> warning output
  - Plan Step 3, item 2, point 5: "If `active_pipeline` is set but `remaining_gates` is empty: Output warning: stale pipeline state, suggest cleanup."

**Qualitative:**

- [x] **Hook scripts follow existing codebase conventions**: Plan specifies HOOK_GROUP, gate sourcing, stdin parse, decision output -- matching check-links-local.sh, track-user-input.sh, and other existing hooks.

- [x] **All new hooks are toggleable**: Plan Steps 1 and 3 both add entries to `.cwf/cwf-state.yaml` hooks section (`deletion_safety: true`, `workflow_gate: true`). The `cwf-hook-gate.sh` mechanism will respect `HOOK_DELETION_SAFETY_ENABLED=false` and `HOOK_WORKFLOW_GATE_ENABLED=false`.

- [x] **Fail-closed behavior**: Proposal A explicitly fail-closes on parse error. Proposal E+G fail-closes on gate violation. Proposal B is inherently advisory (the hook hint is informational, not blocking). This is the correct distribution: deterministic safety checks fail-closed, documentation-based guidance is advisory.

---

#### Concerns (blocking)

- [MEDIUM] **Proposal A: Grep-based detection boundary not documented in plan.** The plan does not explicitly state that `grep -rl` will miss variable-interpolated references like `"$SCRIPT_DIR/csv-to-toon.sh"` or `source "$DIR/lib.sh"`. While the spec mentions this for Proposal D ("variable interpolation limits static analysis"), Proposal A's plan section should include a comment in the script header acknowledging this limitation. Without it, operators may develop a false sense of security. This is not a design flaw -- it is a documentation gap.
  - Reference: Plan Step 1, item 1 (check-deletion-safety.sh)
  - Remediation: Add a header comment documenting the detection boundary (literal string matches only, no variable interpolation resolution)

- [LOW-MEDIUM] **Proposal E+G: Hard-coded gate enum creates maintenance coupling.** The plan specifies "gate name validation against allowed enum: gather, clarify, plan, review-plan, impl, review-code, refactor, retro, ship." This enum must be manually synchronized with cwf:run's Stage Definition table. If a new stage is added to cwf:run but not to the enum, `list-set` will reject it. The plan does not specify where this enum is maintained or how sync is enforced.
  - Reference: Plan Step 3, item 1 (cwf-live-state.sh)
  - Remediation: Either (a) add a comment in cwf-live-state.sh pointing to cwf:run SKILL.md Stage Definition as the source of truth, or (b) extract the enum to a shared constant file. Option (a) is appropriate for this session's scope.

#### Suggestions (non-blocking)

- **Proposal C should be explicitly marked as a stopgap.** Add a comment in the impl SKILL.md rule noting that the structural fix is to modify the triage output format to carry the original recommendation. This prevents the rule from being treated as a permanent solution when it is actually compensating for a process gap.

- **Proposal A: Consider adding `.mjs` import patterns to the grep.** The plan lists `*.mjs` in the search scope but does not account for ESM `import` statements that may reference shell scripts indirectly (e.g., through exec calls in Node scripts). This is a minor gap given the current codebase, but worth a comment for future extensibility.

- **Proposal E+G: The `user_directive` sanitization (escaping `:`, `\n`, `[`, `]`) should be tested with Korean text.** The spec mentions `"cwf:run 최대한 사용"` as an example directive. YAML-safe escaping must not corrupt multi-byte UTF-8 characters. The plan does not include a test case for this. Recommend adding a BDD scenario or at minimum a comment noting the requirement.

- **Plan commit strategy (4 steps = 4 commits) is sound.** Each commit is atomic and independently revertible. This follows the principle of building quality into the commit structure -- if Proposal E+G introduces a regression, it can be reverted without affecting Proposals A and B.

---

#### Verdict: **Conditional Pass**

The plan is well-designed and addresses the root causes identified in the post-incident review. Proposals A and E+G are genuine process transformations (Point 3: building quality into the process). Proposal B is effective because of the hook hint mechanism. Proposal C is the weakest link but acceptable as defense-in-depth.

The blocking concerns are documentation gaps, not design flaws. They can be addressed during implementation without revising the plan structure.

The one systemic observation I want to leave with: this plan creates 2 new hooks, modifies 2 existing files (hooks.json, cwf-live-state.sh), and adds rules to 2 SKILL.md files. Each hook adds execution overhead to every relevant tool call. The system is accumulating enforcement mechanisms -- which is appropriate for a system that has experienced a real incident -- but the PDCA cycle demands that we eventually **Study** (not just Check) whether these hooks are catching real defects or producing only false positives. If, after 10 sessions, the deletion safety hook has never fired on a real deletion-with-callers scenario, it should be evaluated for removal or simplification. Build quality in, but also measure whether your quality mechanisms are producing value.

#### Provenance
- source: REAL_EXECUTION
- tool: claude-code (agent thread)
- expert: W. Edwards Deming
- framework: Systems thinking, common cause vs special cause variation, PDCA cycle, Point 3 (cease dependence on inspection)
- grounding: Out of the Crisis (MIT Press, 1986)

<!-- AGENT_COMPLETE -->
