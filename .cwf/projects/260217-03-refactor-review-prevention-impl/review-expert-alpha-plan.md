### Expert Reviewer α: Nancy Leveson

**Framework Context**: STAMP/STPA systems safety engineering — analyzing hooks as control actions within a hierarchical control structure, identifying unsafe control actions (UCAs) and inadequate feedback that could lead to hazards. Source: Engineering a Safer World: Systems Thinking Applied to Safety (MIT Press, 2011).

---

## Control Structure Model

Before evaluating individual proposals, I map the plan's defense mechanisms onto a STAMP control structure. The controlled process is **agent behavior during cwf:impl and cwf:run execution**. The controllers are:

1. **Hook layer** (automated, compaction-immune): `check-deletion-safety.sh` (Proposal A), `workflow-gate.sh` (Proposal E+G)
2. **Protocol layer** (document-mediated, compaction-vulnerable): Broken Link Triage Protocol (Proposal B), Recommendation Fidelity Check (Proposal C)
3. **State layer** (persistent YAML, read by hooks): `cwf-state.yaml` live section fields (`active_pipeline`, `remaining_gates`, `state_version`)

The critical safety constraint is: **No file deletion may occur when runtime callers exist, and no pipeline stage may be skipped without explicit override.**

---

## STPA Analysis: Unsafe Control Actions (UCAs)

### UCA-1: Deletion safety hook does NOT block when it should (Proposal A)

| UCA Type | Description | Plan Coverage |
|----------|-------------|---------------|
| Not provided | Hook fails to fire because `hooks.json` matcher mismatches the tool name | Partially covered — plan registers for "Bash" matcher |
| Provided too late | PostToolUse fires AFTER the deletion has already executed (`git rm` is immediate) | **NOT COVERED** — critical gap |
| Incorrect | grep search scope misses a caller file type (e.g., `.toml`, `.cfg`, Makefile) | Partially covered — plan lists 8 extensions but acknowledges no `.toml`/Makefile |
| Stopped too soon | Hook exits 0 when grep itself fails silently (e.g., no files matching glob) | Covered — fail-closed on parse error (exit 1) |

**Critical finding on UCA "Provided too late"**: The plan specifies a **PostToolUse** hook. By definition, PostToolUse fires after the tool has already executed. If the agent runs `git rm csv-to-toon.sh`, the file is already deleted by the time the hook runs. The hook can report the violation and block further actions, but it **cannot undo the deletion**. The plan's BDD criterion says "the deletion is prevented" — this is inaccurate for PostToolUse. The deletion has occurred; what is prevented is the agent *proceeding without awareness*.

This is a fundamental control theory issue: a **post-action controller cannot prevent the action it monitors**. In STAMP terms, this is an open-loop control action with no actuator path to reverse the controlled process state. The plan should either:
- (a) Use **PreToolUse** instead, parsing `tool_input.command` before execution (the command text is available in PreToolUse), or
- (b) Accurately describe PostToolUse behavior as "detection + rollback guidance" rather than "prevention", and include a `git checkout -- {file}` restore instruction in the block output.

The plan's Decision Log #1 says "Command text is available before execution" — this actually argues FOR PreToolUse, not PostToolUse. The decision rationale contradicts the hook event choice.

### UCA-2: Deletion safety hook blocks when it should NOT

| UCA Type | Description | Plan Coverage |
|----------|-------------|---------------|
| Provided when not needed | Deleting a file that is only referenced in `.cwf/projects/` (session artifacts) triggers block | Covered — plan excludes `.cwf/projects/` paths |
| Provided when not needed | Deleting `node_modules` contents or temp files triggers block | Partially covered — plan notes `rm ` with space to avoid `rm -rf node_modules`, but `git rm some-temp.sh` could still match |

### UCA-3: Workflow gate does NOT block when it should (Proposal E+G)

| UCA Type | Description | Plan Coverage |
|----------|-------------|---------------|
| Not provided | `remaining_gates` YAML list is malformed/corrupted — parser returns empty, hook thinks no gates remain | Partially covered — `active_pipeline` set + empty `remaining_gates` triggers warning, but does not block |
| Not provided | Agent uses `Edit` tool to directly modify files instead of `cwf:ship` — hook only fires on UserPromptSubmit, not on tool use | Covered by design — hook fires every prompt, reminding agent of pending gates |
| Provided too late | Hook fires on UserPromptSubmit but agent has already composed a multi-tool response | **Architectural limitation** — UserPromptSubmit blocks before Claude processes the prompt, so this is actually safe |
| Stopped too soon | Hook checks for "ship" and "push" keywords but agent uses `gh pr create` or `git push origin` with different phrasing | Partially covered — keyword matching is inherently brittle |

### UCA-4: Workflow gate blocks when it should NOT

| UCA Type | Description | Plan Coverage |
|----------|-------------|---------------|
| Provided when not needed | Stale `active_pipeline` from crashed previous session blocks legitimate new work | Covered — recovery layer detects stale state via session_id mismatch |
| Provided when not needed | User prompt contains the word "ship" in a non-shipping context (e.g., "relationship") | **NOT COVERED** — keyword matching has no semantic analysis |

### UCA-5: Protocol-layer controls fail silently (Proposals B, C)

| UCA Type | Description | Plan Coverage |
|----------|-------------|---------------|
| Not provided | Proposal B's triage protocol is a document — agent may not read it, especially after compaction | Partially covered — check-links-local.sh adds a hint, but the hint is only shown when a broken link is already detected |
| Not provided | Proposal C's fidelity check is a SKILL.md rule — it is a prose instruction, not a deterministic gate | Acknowledged — this is why C is P1, not P0 |

---

## Control Structure Analysis: Defense Layer Adequacy

### Layer 1: Prevention (Proposals A, B, C)

**Proposal A** is the strongest prevention mechanism because it is a deterministic, automated check. However, the PostToolUse timing issue (UCA-1) significantly weakens its preventive power. As a PostToolUse hook, it is more accurately a **detection** mechanism than a prevention mechanism. This is not a fatal flaw — detection-with-guidance is valuable — but the plan and BDD criteria overstate its capability.

**Proposal B** is a signal-preservation mechanism that depends on the agent reading and following documentation. In STAMP terms, this is an **open-loop** control: there is no feedback mechanism to verify the agent actually followed the triage protocol. The hint in check-links-local.sh output is good — it creates a feedback path — but only activates when a broken link is already detected.

**Proposal C** is the weakest control. It is a prose rule in SKILL.md, subject to the exact same compaction vulnerability that caused the original incident. The plan acknowledges this by making it P1 rather than P0. From a STAMP perspective, a rule that can be "forgotten" during compaction is not a control action — it is an intention.

### Layer 2: Detection (Proposal E+G)

**Proposal E+G** is well-designed as a compaction-immune enforcement mechanism. The UserPromptSubmit hook fires on every turn, creating a persistent feedback loop that survives compaction. The `remaining_gates` list in YAML provides persistent state that hooks can read independently of conversation context.

The recovery layer (stale pipeline detection, empty gates warning) addresses the key STAMP concern of **inadequate feedback**: the system can detect when its own state is inconsistent.

**Strength**: The `state_version` field provides a CAS-like mechanism for detecting stale writes. This is a feedback-rich design.

**Gap**: The plan does not specify what happens when `state_version` detects a conflict. The detection is present but the response is not specified.

### Layer 3: Recovery

The plan's recovery mechanisms are thin. The specification (Section 7) identifies this: the recovery layer contains only "Stale state recovery" from E+G. There is no mechanism to **undo** a deletion after Proposal A detects it. There is no mechanism to **rollback** a gate violation after Proposal E+G blocks it. In STAMP terms, the system has strong detection but weak recovery actuators.

---

## Behavioral Criteria Verification

### BDD Checklist

- [x] **Proposal A: File deletion with runtime callers -> hook exits 1 with BLOCKED message** — Plan Step 1 specifies this behavior. Concern: PostToolUse means deletion already happened; "BLOCKED" is misleading terminology. The exit 1 prevents the agent from proceeding, not from deleting.

- [x] **Proposal A: File deletion with no callers -> hook exits 0 silently** — Plan Step 1 specifies silent pass on no callers found.

- [x] **Proposal A: grep/parse failure -> hook exits 1 (fail-closed)** — Plan Step 1 explicitly states fail-closed on error. Matches codebase convention (check-links-local.sh blocks when lychee is unavailable).

- [x] **Proposal B: Broken link error includes triage protocol reference** — Plan Step 2 modifies check-links-local.sh to append triage reference hint.

- [x] **Proposal C: Triage action contradiction -> follow original recommendation** — Plan Step 4 adds rule to impl SKILL.md. Concern: prose rule, not deterministic gate.

- [x] **Proposal E+G: remaining_gates includes review-code + ship attempt -> hook exits 1** — Plan Step 3 specifies keyword detection and exit 1 block.

- [x] **Proposal E+G: Stage completion -> list-remove updates YAML list** — Plan Step 3 introduces `list-remove` CLI subcommand and SKILL.md integration.

- [x] **Proposal E+G: Stale active_pipeline -> cleanup prompt output** — Plan Step 3 specifies session_id comparison for stale detection.

- [x] **Proposal E+G: active_pipeline set + empty remaining_gates -> warning output** — Plan Step 3 specifies this as a specific condition check.

### Qualitative Checklist

- [x] **Hook scripts follow existing codebase conventions** — Plan references `check-links-local.sh` template structure, uses `HOOK_GROUP`, `cwf-hook-gate.sh` sourcing, stdin JSON parse, decision JSON output. Consistent with `check-shell.sh` and `check-links-local.sh` patterns observed in the codebase.

- [x] **All new hooks are toggleable** — Plan adds `deletion_safety: true` and `workflow_gate: true` to `cwf-state.yaml` hooks section, using the same `cwf-hook-gate.sh` pattern that reads `~/.claude/cwf-hooks-enabled.sh`.

- [x] **Fail-closed behavior** — Plan explicitly specifies fail-closed for Proposal A (grep failure -> exit 1) and Proposal E+G (gate violation -> exit 1). Consistent with check-links-local.sh blocking when lychee is unavailable.

---

#### Concerns (blocking)

- [**HIGH**] **PostToolUse cannot prevent deletions — control action timing mismatch (UCA-1)**
  Plan Step 1 registers `check-deletion-safety.sh` as a PostToolUse hook. PostToolUse fires after the tool has executed. When `git rm file.sh` runs, the file is already deleted before the hook fires. The BDD criterion "the deletion is prevented" is inaccurate. The hook can alert and block further progress, but the deletion itself cannot be intercepted at PostToolUse.
  *Reference: Plan Step 1, line "PostToolUse hook for Bash tool calls"; BDD criterion "And the deletion is prevented"*
  *STAMP classification: Control action provided too late — the actuator (hook exit code) cannot reverse the process variable (file state) after the process has already transitioned.*
  **Recommendation**: Either (a) move to PreToolUse with `tool_input.command` parsing (the plan's own Decision Log #1 notes command text is available before execution, which supports PreToolUse), or (b) keep PostToolUse but revise BDD criteria to say "detection and rollback guidance" and include `git checkout -- {file}` in the BLOCKED message.

- [**MEDIUM**] **Keyword-based ship/push detection is brittle (UCA-3, UCA-4)**
  Plan Step 3 checks if the user prompt "mentions ship/push/merge." Simple keyword matching produces both false negatives (`gh pr create`, `git push origin feature`) and false positives ("we'll ship this later in the discussion"). The plan does not specify the exact matching logic — regex patterns, word boundaries, or semantic analysis.
  *Reference: Plan Step 3, workflow-gate.sh behavior item 4*
  **Recommendation**: Specify exact regex patterns with word boundaries in the plan. Consider also matching against the agent's tool_input (checking for `git push`, `gh pr`, or Skill invocations containing "ship") rather than raw user prompt text, since UserPromptSubmit has access to the prompt content, not the agent's planned actions. Alternatively, add a secondary PostToolUse check on Bash/Skill for actual ship/push commands.

#### Suggestions (non-blocking)

- **Add explicit recovery instructions to Proposal A's block message**. When the hook detects a deletion with callers, the BLOCKED message should include: `git checkout HEAD -- {file}` to restore the deleted file. This closes the recovery gap identified in the control structure analysis — detection without recovery leaves the system in a hazardous state even after blocking.

- **Specify `state_version` conflict resolution behavior**. The plan introduces `state_version` for CAS-style stale write detection but does not specify what happens on conflict. In STAMP terms, a sensor without a defined response path is incomplete feedback. Recommend: on version mismatch, log a warning and re-read state before writing (optimistic retry), or fail-closed and report to the user.

- **Consider adding a `list-get` subcommand to `cwf-live-state.sh`**. The plan adds `list-set` and `list-remove` but no `list-get`. The `workflow-gate.sh` hook needs to read `remaining_gates` — it will presumably use `cwf_live_extract_scalar_from_file` or raw AWK, but a list is not a scalar. A dedicated `list-get` would ensure consistent parsing and avoid a gap between the write path (new list functions) and the read path (ad-hoc extraction).

- **Document the interaction between Proposal A and Proposal E+G**. If `check-deletion-safety.sh` blocks a deletion and the agent is mid-pipeline with `remaining_gates` active, there is a potential for cascading blocks. The plan should clarify: does a Proposal A block count as a pipeline failure? Should the agent attempt to resolve the block within the current stage, or should it halt the pipeline?

- **Proposal C: Consider augmenting the prose rule with a structured triage format**. The root cause of the original incident was fidelity loss from analysis to triage. Rather than relying solely on a prose instruction to "read the original recommendation," consider specifying a mandatory triage table column for `original_recommendation` that impl agents must populate before acting. This converts the open-loop prose control into a closed-loop artifact check.

---

#### Provenance
- source: REAL_EXECUTION
- tool: claude-task
- expert: Nancy Leveson
- framework: STAMP/STPA (Systems-Theoretic Accident Model and Processes / System-Theoretic Process Analysis)
- grounding: Engineering a Safer World: Systems Thinking Applied to Safety (MIT Press, 2011)
<!-- AGENT_COMPLETE -->
