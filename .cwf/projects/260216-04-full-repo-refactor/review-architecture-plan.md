This review assesses the **260216 Refactoring Incident Review & Prevention Plan** from an architectural and pattern-consistency perspective.

### Concerns (Blocking)

#### Critical: Hook-Induced Agent Paralysis (Proposal E)
The "Workflow enforcement gate" (Proposal E) introduces a risk of "agent nagging" or deadlock if not implemented with a bypass mechanism. While essential for surviving compaction, if an agent genuinely needs to deviate from a pre-defined gate (e.g., to fix an emergency infrastructure failure that blocks the tool itself), a purely prescriptive hook might prevent progress.
*   **Requirement:** The state schema in `cwf-state.yaml` must include an `override_reason` or `manual_mode: boolean` field that allows the agent (with user consent) to acknowledge the gate but proceed, preventing a loop where the agent repeatedly tries and fails to satisfy a hook that doesn't understand the current technical exception.

#### Moderate: Schema Fragility in State Persistence (Proposal G)
Persisting `remaining_gates` as a list in `cwf-state.yaml` introduces a dependency between the `cwf:run` tool logic and the state schema. If the internal stage names of `cwf:run` change in a future update, but an old `cwf-state.yaml` persists on disk, the hook (Proposal E) might provide stale or invalid guidance.
*   **Requirement:** Implement a version check or a "Stage Registry" in the CWF core that maps state-string gates to actual tool capabilities. Ensure `cwf-live-state.sh` validates gate names against the current `cwf:run` manifest before writing to the YAML.

---

### Suggestions (Non-blocking)

#### Script Dependency Graph Limitations (Proposal D)
Static analysis of shell scripts (Proposal D) is notoriously difficult due to variable interpolation (e.g., `bash $SCRIPT_DIR/$TARGET_NAME.sh`). 
*   **Refinement:** Do not rely on Proposal D as a deterministic "Safe to Delete" signal. Instead, treat it as a "High-Confidence Caller" signal. The "Deletion Safety Gate" (Proposal A) remains the primary architectural defense, as it requires a manual `grep` by the agent which is more likely to catch interpolated references.

#### Centralization of Safety Protocols (Proposal A & B)
The plan suggests placing rules in `SKILL.md` and `agent-patterns.md`. 
*   **Refinement:** To avoid "rule sprawl," create a dedicated `docs/safety-and-integrity.md` or a specific section in `AGENTS.md` titled **"System Integrity Protocols."** These specific protocols (Deletion Gate, Link Triage) are global constraints, not just implementation-stage details, and should be easily discoverable by any agent entering the system, regardless of their current task.

#### Session Log Review Fidelity (Proposal F)
Proposal F is an excellent architectural addition. To maximize its effectiveness, `cwf:run` should be updated to automatically generate a `plan-summary.json` at the end of the `plan` phase. This machine-readable plan is much easier for `cwf:review` to cross-reference against the final `git diff` than a natural-language session log, which might suffer from the same "triage distortion" identified in the incident.

---

### Provenance
**Source:** `260217-01-refactor-review/plan.md` (internal retrospective document)
**Tool:** `codebase_investigator` (architectural mapping)
**Reviewer:** Claude 3.5 Sonnet (Architecture Specialist)
**Duration:** 14,200ms
**Command:** `bash scripts/review-plan.sh --role architecture`

<\!-- AGENT_COMPLETE -->
