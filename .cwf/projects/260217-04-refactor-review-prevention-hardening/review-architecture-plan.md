I will read the target files to understand the plan and its context for the architecture review.
I have completed the architecture review of the proposed hardening plan. The plan effectively addresses the structural risks identified in the previous session's retro, particularly the "common-mode failure" risks and the need to convert conventions into deterministic gates.

### 1) Verdict: Pass

The plan is technically sound, highly detailed, and directly implements the expert recommendations (Leveson, Perrow, Dekker) from the handoff context.

### 2) Concerns

| Severity | File:Line | Description |
| :--- | :--- | :--- |
| **Moderate** | `plan.md`:48-59 | **Common-mode Failure Risk:** Consolidating live-state parsing into `cwf-live-state.sh` for use in safety hooks (`workflow-gate.sh`, etc.) creates a single point of failure. A syntax error or breaking change in this shared script could block all safety-critical operations (fail-closed). |
| **Minor** | `plan.md`:117 | **Test Ordering:** Pack B (Hook Exit-Code Tests) is scheduled for Step 4, after major structural changes in Steps 2 and 3. While acceptable, this means logic changes in those steps are not immediately protected by the new deterministic suite. |
| **Minor** | `plan.md`:100-106 | **Proposal I Risk:** Placing "Shared reference extraction" in the final step of a large session is risky. If extraction reveals deeper inconsistencies in how skills handle persistence, it may require revisiting files modified in Step 1 or 2. |

### 3) Suggestions

- **S1: Defensive Parsing in `cwf-live-state.sh`:** Ensure the shared parser in Step 2 is extremely defensive (e.g., using `jq` or `yq` with strict validation if available, or providing fallback values) to prevent safety hooks from crashing due to malformed YAML.
- **S2: Atomic Appends for `decision_journal`:** In Step 3, ensure `log-turn.sh` uses atomic append operations (e.g., `>>`) to the `decision_journal` to prevent corruption if multiple processes attempt to log state simultaneously (though rare in the current CLI flow).
- **S3: Pre-push Optimization:** For `check-script-deps.sh` (Step 5), ensure the dependency resolution is fast enough to avoid developer friction during push operations, especially as the plugin script count grows.

### 4) Behavioral Criteria Assessment

| Criterion (Given/When/Then) | Assessment | Notes |
| :--- | :--- | :--- |
| **Hook blocking scenarios...** | **Pass** | Addressed by `test-hook-exit-codes.sh` in Step 4. |
| **AskUserQuestion results...** | **Pass** | Addressed by `decision_journal` persistence in Step 3. |
| **Review prompt lines 1201+...** | **Pass** | Addressed by routing logic updates in Step 1. |
| **Script references are broken...** | **Pass** | Addressed by `check-script-deps.sh` in Step 5. |
| **README structures diverge...** | **Pass** | Addressed by `check-readme-structure.sh` in Step 5. |
| **Review mode code cross-check...** | **Pass** | Addressed by session-log synthesis in Step 6. |
| **Repeated persistence blocks...** | **Pass** | Addressed by shared-reference extraction in Step 6. |

<!-- AGENT_COMPLETE -->
