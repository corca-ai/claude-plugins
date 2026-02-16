### Expert Reviewer Beta: Charles Perrow

**Framework Context**: Normal Accident Theory -- analyzing systems through the dual dimensions of interaction complexity (linear vs complex/interactive) and coupling tightness, where systems that are both interactively complex and tightly coupled will inevitably produce "system accidents" that cannot be prevented by adding more safety layers. Source: *Normal Accidents: Living with High-Risk Technologies* (Basic Books, 1984; Princeton UP revised, 1999); verified via cwf-state.yaml expert_roster (verified: true).

---

#### Concerns (blocking)

- [HIGH] **workflow-gate.sh reimplements YAML parsing independently, creating a common-mode failure surface with cwf-live-state.sh.**
  In Normal Accident Theory, common-mode failure occurs when two supposedly independent safety channels share a hidden dependency -- a shared component, shared environment, or shared design flaw. Here, `workflow-gate.sh` (diff lines 427-476) contains its own `extract_live_scalar` and `extract_live_list` AWK implementations that parse the same YAML state file as `cwf-live-state.sh` (lines 76-91, 706-738). These are not independent safety channels -- they are two implementations of the same parser operating on the same data structure. A YAML formatting edge case that breaks one parser (e.g., a value containing a colon followed by a space, or an unexpected indent level) will break both, because both use the same regex-based AWK approach with the same structural assumptions about 2-space indentation under `live:`.

  This is precisely the failure mode Perrow describes in nuclear plant instrumentation: redundant sensors that share the same physical mounting bracket. The "redundancy" is illusory because the failure modes are correlated. The fix is to eliminate the duplication: `workflow-gate.sh` already locates `LIVE_STATE_SCRIPT` (line 374) and calls it for `resolve` (line 503). It should source the library and call `cwf_live_extract_scalar_from_file` and `cwf_live_extract_list_from_file` directly, converting these from two common-mode parsers into a single parser with a single maintenance point.

  Files: `plugins/cwf/hooks/scripts/workflow-gate.sh` (lines 427-476), `plugins/cwf/scripts/cwf-live-state.sh` (lines 76-91, 706-738).

- [MEDIUM] **The deletion safety hook and the workflow gate hook share no coordination mechanism, creating potential for interactive complexity under concurrent tool calls.**
  Both hooks fire on the same session context. `check-deletion-safety.sh` fires on PreToolUse for Bash commands. `workflow-gate.sh` fires on UserPromptSubmit for all prompts. They both read from the same repository state (git working tree, YAML files) and both produce blocking/allowing decisions. But they have no awareness of each other. Perrow's framework distinguishes *linear* interactions (A causes B in a predictable sequence) from *interactive/complex* interactions (A and B interact through unexpected pathways). Consider this scenario: a user submits a prompt that triggers `workflow-gate.sh` to emit a `[PIPELINE]` status warning (allowing), then the agent interprets this as clearance and issues a `git rm` that `check-deletion-safety.sh` must catch. The pipeline status message from hook A becomes contextual input that influences the agent's behavior going into hook B -- an interactive pathway that neither hook was designed to account for.

  This is not a bug per se -- it is an emergent interaction property of running multiple hooks that affect agent behavior through different mechanisms (blocking vs advisory messaging). The concern is that the advisory output of `workflow-gate.sh` may create a false sense of procedural compliance that reduces the agent's own caution, exactly when `check-deletion-safety.sh` needs the agent to still be cautious. This interactive complexity is characteristic of systems that Perrow would classify as requiring decentralized control -- yet the hook architecture is centralized (sequential hook execution, no inter-hook communication).

  Files: `plugins/cwf/hooks/hooks.json` (hook ordering), `plugins/cwf/hooks/scripts/workflow-gate.sh`, `plugins/cwf/hooks/scripts/check-deletion-safety.sh`.

#### Suggestions (non-blocking)

- **The tight coupling between run/SKILL.md stage transitions and cwf-live-state.sh's `remaining_gates` list creates a system where small timing errors have large consequences.**
  In Perrow's coupling taxonomy, tight coupling means the system has time-dependent processes, invariant sequences, and limited slack. The `remaining_gates` mechanism exhibits all three: (1) `list-set` must be called at every stage transition with the correct remaining list (time-dependent), (2) gates must be removed in the correct order matching the stage definition table (invariant sequence), and (3) there is no buffer between a missed `list-set` call and the workflow gate producing incorrect blocking/allowing decisions (no slack). A loosely coupled design would decouple the "what stage are we in" signal from the "what stages remain" signal -- for example, deriving remaining gates from the current `phase` value and the fixed stage definition table, rather than maintaining a separate mutable list that must be kept in sync. The current design requires the orchestrator to manually maintain a derived quantity, which is the structural signature of tight coupling.

  Files: `plugins/cwf/skills/run/SKILL.md` (stage execution loop, diff lines 1155-1156, 1164-1166), `plugins/cwf/scripts/cwf-live-state.sh` (list-set), `plugins/cwf/hooks/scripts/workflow-gate.sh` (remaining_gates consumption).

- **`check-deletion-safety.sh`'s `grep -rl` caller detection is a linear interaction masquerading as comprehensive coverage.**
  The hook's header comment (diff lines 63-69) honestly documents that variable-interpolated references escape detection. This honesty is commendable. But from a Normal Accident Theory perspective, the more important structural observation is that the detection mechanism is *linear* -- it follows a simple chain: extract paths from `rm` command, search for literal string matches, report hits. Linear systems are predictable and their failures are understandable. The danger arises when operators treat a linear detection system as if it were a comprehensive one. The `--include` whitelist (`.sh`, `.md`, `.mjs`, `.yaml`, `.json`, `.py` at lines 192-197) means that references in `.ts`, `.tsx`, `.toml`, `.cfg`, or any other file type will never be found. This is not a flaw in the search -- it is a design boundary. But unlike the variable-interpolation limitation (which is documented in the header), the file-type boundary is implicit in the `grep` flags. Both boundaries should be documented together so operators understand the complete detection envelope.

  File: `plugins/cwf/hooks/scripts/check-deletion-safety.sh`, lines 191-197 and header comment.

- **The `state_version` bumping mechanism is a coupling amplifier, not a coupling reducer.**
  `state_version` is incremented on every `remaining_gates` change (diff lines 853-865 for the bump function, called from `list-set` and `list-remove`). The version is then read by `workflow-gate.sh` and included in status messages (diff line 531). This creates an additional coupling channel: any consumer that caches or compares `state_version` values now has a hidden dependency on the *frequency* of gate transitions, not just their *content*. If a future hook or script uses `state_version` for staleness detection (a natural next step), it inherits tight coupling to the pipeline's internal transition cadence. Perrow's framework warns that version counters in tightly coupled systems become "hidden common modes" -- they appear to be simple metadata but actually encode temporal assumptions about system behavior.

  Files: `plugins/cwf/scripts/cwf-live-state.sh` (lines 847-865), `plugins/cwf/hooks/scripts/workflow-gate.sh` (line 522, 531).

- **The `cwf_live_sanitize_yaml_value` function replaces `[` and `]` with full-width Unicode but does not document this as a lossy transformation with coupling implications.**
  The sanitization (diff lines 646-655) is a defense-in-depth measure against YAML structure corruption. However, any downstream component that reads sanitized values back from YAML and compares them against original input will get a mismatch. This is an interactive complexity concern: the write path and the read path are no longer symmetric, and any component that assumes symmetry will produce silent errors. Perrow notes that asymmetric transformations in data paths are a common source of "mysterious" failures in complex systems because operators reason about the data as if it were unchanged.

  File: `plugins/cwf/scripts/cwf-live-state.sh`, lines 646-655.

- **The `prompt_requests_blocked_action` regex (line 492) is a brittle boundary between advisory and enforcement.**
  The function uses a fixed regex with English and Korean patterns to detect ship/push/commit intents. This is a *recognition* boundary -- it determines whether a user prompt triggers enforcement or passes through as advisory. Perrow's framework emphasizes that recognition boundaries in complex systems must be either extremely simple (easy to reason about exhaustively) or extremely comprehensive (covering all cases by construction). A regex that lists specific verbs in two languages occupies the dangerous middle ground: too complex to be trivially verifiable, too narrow to be comprehensive. A prompt like "please deploy this" or "merge it" or even "let's ship" (without the specific token boundaries the regex requires) would bypass the gate. This is not a blocking concern because the gate is defense-in-depth, but the confidence in its coverage should be calibrated accordingly.

  File: `plugins/cwf/hooks/scripts/workflow-gate.sh`, line 492.

---

#### Behavioral Criteria Assessment

1. **File with runtime callers -> BLOCKED**: `extract_deleted_from_bash` parses `rm`/`git rm`/`unlink` commands (lines 143-183), `search_callers` runs `grep -rl` with `--fixed-strings` (lines 185-216), self-exclusion at line 301, `json_block` with caller preview at lines 329-335. **PASS**.

2. **File with no callers -> exit 0**: When `FILES_WITH_CALLERS` is empty after the loop, exit 0 at line 316. **PASS**.

3. **grep fails or parse error -> fail-closed**: `rc > 1` sets `SEARCH_FAILED=1` (line 207); checked at line 295 with `json_block`. Missing jq triggers block at lines 224-228. **PASS**.

4. **`rm -rf node_modules` -> excluded**: `node_modules/*` case at line 255, plus `--exclude-dir=node_modules` in grep at line 199. Double exclusion. **PASS**.

5. **Broken link references triage protocol**: `check-links-local.sh` change at diff line 345 appends triage reference to block reason. `agent-patterns.md` contains full protocol with decision matrix (diff lines 549-598). **PASS**.

6. **Triage contradicts analysis -> follow original**: Rule 16 in `impl/SKILL.md` (diff line 1070): "follow the original, not the triage summary." **PASS**.

7. **Ship/push while review-code pending -> BLOCKED**: `list_contains "review-code"` check at line 533, `prompt_requests_blocked_action` regex at line 492, `json_block` at line 537. Override path via `pipeline_override_reason` at lines 534-536. **PASS**.

8. **Stage completion -> remaining_gates updated**: `list-set` subcommand (diff lines 998-1007) calls `cwf_live_set_list` which calls `cwf_live_upsert_live_list`. `run/SKILL.md` shows `list-set` with remaining gates at stage transitions (diff lines 1155-1156, 1164-1166). The `list-remove` subcommand also exists (diff lines 1008-1048) for individual gate removal. **PASS** -- both mechanisms available; `list-set` is the primary integration point in the stage execution loop.

9. **Stale pipeline from previous session -> cleanup prompt**: Session ID comparison at diff lines 516-517; emits `json_allow` with `[WARNING] Stale pipeline detected` and cleanup command. **PASS**.

10. **Active pipeline with empty remaining_gates -> stale warning**: Check at diff lines 526-528; emits `json_allow` with warning about no remaining_gates. **PASS**.

11. **500-line review -> 180s timeout**: CLI timeout scaling table (diff lines 1095-1099) maps 300-800 lines to 180s. **PASS**.

12. **100-line review -> 120s timeout**: Table maps <300 lines to 120s. **PASS**.

#### Qualitative Criteria Assessment

- **Fail-closed design preference**: `check-deletion-safety.sh` blocks on missing jq (lines 224-228), search failure (line 295-296), and wildcard deletion (line 245). `workflow-gate.sh` correctly distinguishes: fails open for advisory (missing jq at line 369, missing live state at line 505) but fails closed for enforcement (ship intent with pending review-code at line 537). The deletion hook's fail-closed posture is the correct design for a safety-critical guard. **PASS**.

- **Compaction immunity**: `workflow-gate.sh` reads from persistent YAML on disk (`extract_live_scalar`, `extract_live_list` operating on `$LIVE_STATE_FILE`), not from chat memory or conversation context. The hook fires on `UserPromptSubmit`, which occurs before the agent has processed the prompt, making it immune to context window state. `check-deletion-safety.sh` reads from stdin (tool input JSON) and the git working tree, both persistent. **PASS**.

- **Minimal performance overhead**: Both hooks have fast-exit paths. `check-deletion-safety.sh` exits immediately if no `rm`/`git rm`/`unlink` detected in the command (line 240). `workflow-gate.sh` exits if no jq (line 369), no live state script (line 377), no live state file (line 505), or no active pipeline (line 509-510). The common case (non-deletion Bash commands, no active pipeline) hits an early exit. **PASS**.

---

#### System Accident Analysis (Framework-Specific)

Perrow's central thesis is that in systems with interactive complexity and tight coupling, accidents are "normal" -- they are an inherent property of the system's structure, not a result of operator error or component failure. The question for this review is: do the proposed safety mechanisms change the system's position on Perrow's interaction/coupling matrix, or do they add complexity that moves the system *toward* the high-risk quadrant?

**1. The system is moving from linear-loosely-coupled toward interactive-tightly-coupled.**

Before these changes, the CWF pipeline was relatively linear: stages executed in sequence, each stage read from artifacts left by the previous one, and failures were local (a bad commit could be reverted, a bad review could be re-run). The hooks add interactive complexity by creating new feedback pathways: the workflow gate reads live state that is written by the pipeline orchestrator, which reads hook output that influences its next action. This creates a loop: pipeline -> state -> hook -> agent behavior -> pipeline. The deletion safety hook adds another interaction: tool call -> hook -> block decision -> agent retry -> potentially different tool call -> hook again. These are not linear chains anymore; they are feedback systems with the potential for unexpected interaction effects.

The coupling also tightened. Before these changes, a stale `cwf-state.yaml` was an inconvenience. After these changes, a stale `cwf-state.yaml` with `active_pipeline="cwf:run"` and `remaining_gates` including `review-code` will *actively block legitimate work* in a new session. The stale pipeline detection (diff lines 516-517) mitigates this, but it depends on `session_id` being correctly populated -- a field that is set during pipeline initialization and could be empty or missing in edge cases. When the state file has enforcement authority (not just advisory), the coupling between state correctness and system operability becomes tight.

**2. The duplicated YAML parser is a common-mode failure waiting to happen.**

This is the most structurally concerning aspect of the implementation. Perrow defines common-mode failure as a failure that defeats multiple safety barriers simultaneously because those barriers share a common element. The two YAML parsers in `workflow-gate.sh` and `cwf-live-state.sh` share a common design (regex-based AWK with 2-space indent assumptions), operate on the same data (the YAML state file), and are maintained by the same team. If a future state file change introduces a YAML construct that the AWK parser handles incorrectly -- say, a multi-line value, a comment on the same line as a list item, or a key whose value contains `:[space]` -- both the enforcement mechanism (workflow gate) and the state management mechanism (live-state library) will misparse simultaneously. There is no independent verification channel. This is the signature pattern of systems where adding redundancy actually increases risk because the redundancy shares failure modes with the primary.

**3. The `remaining_gates` mechanism introduces invariant-sequence coupling without a recovery path.**

In Perrow's coupling analysis, invariant sequences are a hallmark of tight coupling: things must happen in exactly the right order, and there is no way to recover from a missed step without resetting the entire sequence. The `remaining_gates` list must be updated at every stage transition with exactly the right subset of gates in exactly the right order. If the orchestrator crashes between completing a stage and calling `list-set` (or `list-remove`), the gates are out of sync with reality. There is no self-healing mechanism -- no periodic reconciliation between the `phase` field (which *is* updated) and the `remaining_gates` list (which *should* be derivable from `phase` but is maintained independently). Perrow would characterize this as unnecessary tight coupling: the information in `remaining_gates` is derivable from `phase` plus the fixed stage definition table, yet the system maintains it as independent mutable state that must be kept in sync by an external actor (the orchestrator). This is the structural equivalent of having two clocks and no way to tell which one is right.

---

#### Provenance
- source: REAL_EXECUTION
- tool: claude-task
- expert: Charles Perrow
- framework: Normal Accident Theory (interactive complexity, tight/loose coupling, common-mode failure)
- grounding: *Normal Accidents: Living with High-Risk Technologies* (Basic Books, 1984; Princeton UP revised, 1999); verified via cwf-state.yaml expert_roster (verified: true)

<!-- AGENT_COMPLETE -->
