### Expert Reviewer α: James Reason

**Framework Context**: Swiss cheese model and defense-in-depth barrier analysis — accidents result from latent conditions (holes) in successive defense layers aligning simultaneously, allowing an active failure to propagate through all barriers. Source: *Managing the Risks of Organizational Accidents* (Ashgate, 1997), roster-verified.

---

#### Analytical Framing

The 260216 incident — where an agent deleted `csv-to-toon.sh`, a file with active runtime callers, during a refactoring session — is a textbook example of what I term an "organizational accident" in my published taxonomy. The active failure (the deletion command) was not the root cause. The root cause was the absence of defense barriers at the point of action. No single barrier is ever perfect; each has latent conditions (holes) that can align. The design philosophy must therefore be defense-in-depth: multiple independent barriers, each with different failure modes, so that the probability of simultaneous alignment is reduced to acceptable levels.

The 10-file, +952/-13 diff under review implements five proposals that create barriers across four functional defense layers: (1) Prevention — stopping the hazard at the point of action, (2) Detection — identifying the hazard before it causes harm, (3) Mitigation — limiting harm scope, and (4) Recovery — guiding restoration. I will evaluate whether this architecture achieves genuine redundancy or merely creates the appearance of depth through correlated barriers.

---

#### Behavioral Criteria Assessment

**BDD-1: Given delete file with runtime callers, PreToolUse hook exits 1 with blocked message**

PASS. In `check-deletion-safety.sh`, the main loop (diff lines 281-314) iterates over `DELETED_REL`, calls `search_callers` with both the relative path and the basename, filters out self-references (diff line 301), and accumulates `FILES_WITH_CALLERS`. When non-empty, `json_block` is called at diff line 335 with a reason string reading `"BLOCKED: deleted file(s) have runtime callers: ${blocked_files}. Callers: ${caller_preview}. Restore file(s) or remove callers first."` The `json_block` function exits 1. The message format uses "deleted file(s) have runtime callers" rather than the exact criterion wording, but it communicates the same semantics unambiguously. The caller preview (up to 6 lines, diff line 310) gives the agent immediately actionable context.

**BDD-2: Given delete file with no callers, hook exits 0 silently**

PASS. When `search_callers` returns no hits for any candidate and `FILES_WITH_CALLERS` remains empty, the script reaches `exit 0` at diff line 317. No JSON output is emitted — the hook is transparent for non-hazardous deletions. This is the correct fail-open behavior for the non-hazard path: the barrier only activates when a threat is present.

**BDD-3: Given grep fails or parse error, hook exits 1 with actionable error (fail-closed)**

PASS. The `search_callers` function (diff lines 185-216) uses `set +e` to capture grep's exit code. When `rc > 1` (grep internal error, as opposed to rc=1 for no-match), it sets `SEARCH_FAILED=1` and captures `SEARCH_ERROR` from the stderr temp file. The main loop checks `SEARCH_FAILED` at diff line 295 and calls `json_block "BLOCKED: deletion safety search failed (${SEARCH_ERROR:-unknown error})."` For jq absence, lines 224-228 also call `json_block` — the hook cannot safely parse input without jq and therefore refuses to allow the operation. This implements the critical fail-closed principle: when the detection mechanism itself is impaired, the barrier defaults to blocking rather than passing. In my framework, this addresses the "degraded barrier" failure mode where a defense layer silently loses its detection capability.

**BDD-4: Given "rm -rf node_modules", node_modules excluded, hook exits 0**

PASS. Two independent exclusion mechanisms operate: (1) the `to_repo_rel` post-processing at diff lines 254-256 uses a case statement to skip `node_modules/*`, `tmp/*`, and `.cwf/projects/*` paths; (2) the `search_callers` grep itself uses `--exclude-dir=node_modules` (diff line 198). When all candidates are excluded, `DELETED_REL` is empty and the script exits 0 at diff line 275. The double-layered exclusion is good defense practice — the filtering and the search scope independently prevent false positives on dependency directories.

**BDD-5: Broken link error references Triage Protocol, agent-patterns.md contains triage matrix**

PASS. `check-links-local.sh` diff (line 345) appends `\nFor triage guidance, see references/agent-patterns.md § Broken Link Triage Protocol` to the REASON string. The `agent-patterns.md` diff (lines 549-598) adds the complete triage protocol with four sections: (1) git log check for recent deletions, (2) caller-type classification table (Runtime, Build/Test, Documentation, Stale), (3) decision matrix mapping each caller type to an action (with "Runtime caller exists" mapping to "STOP. Restore the deleted file."), and (4) record-keeping instruction. The protocol also includes an integration section (lines 589-598) explaining how agents should respond when the hook blocks.

**BDD-6: Given triage item contradicts analysis recommendation, Rules instruct to follow original**

PASS. `impl/SKILL.md` diff (lines 1070-1071) inserts Rule 16 "Recommendation Fidelity Check" which explicitly states: "If the triage action contradicts or simplifies the original recommendation: follow the original, not the triage summary." The rule also mandates a pre-mortem simulation for file deletions. It is correctly marked as a stopgap with the deferred structural fix identified: "modify triage output format to carry original recommendation."

**BDD-7: Given cwf:run active with remaining_gates including review-code, ship/push/commit prompt triggers block**

PASS. `workflow-gate.sh` implements this at diff lines 533-538. The compound condition checks `list_contains "review-code" "${REMAINING_GATES[@]}"` AND `prompt_requests_blocked_action "$PROMPT"`. The regex at line 492 covers: `cwf:ship`, `/ship`, `git push`, `git merge`, `gh pr create`, `gh pr merge`, and Korean equivalents. When both conditions are true and no `pipeline_override_reason` is set, `json_block` emits the status message plus `"BLOCKED action: ship/push/commit requested while review-code is still pending."` The override mechanism (lines 534-536) provides a documented escape hatch — the override reason is surfaced in the allow message, maintaining auditability.

**BDD-8: Given cwf:run completes a stage, remaining_gates is updated via list-set**

PASS. `cwf-live-state.sh` adds the `list-set` subcommand (diff lines 874-989) which validates list keys, validates gate names for `remaining_gates`, writes items to a temp file, and calls `cwf_live_upsert_live_list` on both the effective and root state files. The `cwf_live_upsert_live_list` function (diff lines 740-822) uses an AWK state machine to find the existing list in the YAML, replace it with the new items, or insert it if absent. Additionally, `list-remove` (diff lines 1008-1048) provides idempotent single-item removal via `cwf_live_remove_list_item`. Both operations bump `state_version` when modifying `remaining_gates`, creating an audit trail.

**BDD-9: Given stale active_pipeline from previous session, cleanup prompt output**

PASS. `workflow-gate.sh` lines 515-517 compare `SESSION_ID` (from the hook input) against `STORED_SESSION_ID` (from the live state file). When both exist and differ, `json_allow` outputs a WARNING identifying the stale pipeline and its owning session, plus the exact cleanup command: `bash cwf-live-state.sh set . active_pipeline=""`. This is a detection-and-guidance barrier — it does not automatically clear the stale state (which would be a recovery action with its own risks), but ensures the operator cannot miss the condition.

**BDD-10: Given active_pipeline set but remaining_gates empty, stale state warning**

PASS. Lines 526-528: when `REMAINING_GATES` array length is 0, `json_allow` outputs a WARNING about missing remaining_gates with "Run cleanup or reinitialize run-state before continuing." This catches the contradictory state where a pipeline claims to be active but has nothing left to enforce.

**BDD-11: Given 500-line review prompt, CLI timeout set to 180s**

PASS. `review/SKILL.md` diff adds a CLI timeout scaling table (diff lines 1092-1100): `< 300` lines maps to 120s, `300-800` lines maps to 180s, `> 800` lines maps to 240s. 500 lines falls in the 300-800 range, yielding 180s. The `{cli_timeout}` placeholder replaces the hardcoded `120` in all four external CLI templates (codex slot 3, gemini slot 3, gemini slot 4, codex slot 4).

**BDD-12: Given 100-line review prompt, CLI timeout remains at 120s**

PASS. 100 < 300, so the table yields 120s. The original hardcoded timeout value is preserved for small reviews.

---

#### Qualitative Criteria Assessment

**Fail-closed design preference**

SATISFIED. The two new hooks demonstrate an appropriate asymmetry in their fail-closed behavior:

- `check-deletion-safety.sh` is **strongly fail-closed**: jq missing blocks, grep failure blocks, wildcard deletion blocks. This is correct because file deletion is irreversible — a false positive (blocking a safe deletion) costs a retry; a false negative (allowing a dangerous deletion) costs data loss and incident recovery.

- `workflow-gate.sh` is **selectively fail-closed**: it fails open when jq is missing (exit 0) or when the live-state script is missing (exit 0), because it cannot determine pipeline state without these dependencies and blocking all prompts would be excessively disruptive. But it fails closed for the specific scenario it guards against: shipping unreviewed code. The fail-closed/fail-open boundary is drawn at the right point — when the hook's detection capability is intact and it detects a violation, it blocks; when its detection capability is absent, it cannot block without creating unacceptable false positive rates.

This asymmetry reflects a key principle from my framework: defense barriers should be calibrated to the consequence severity of the hazard they guard against. Irreversible harm (file deletion) warrants aggressive fail-closed behavior. Process violations (premature shipping) warrant fail-closed only when the detection mechanism is functional.

**Compaction immunity for workflow enforcement**

SATISFIED. The workflow gate reads from persistent YAML state files (`cwf-state.yaml` and `session-state.yaml`) via `cwf-live-state.sh resolve`. These files are on disk, not in chat context. When Claude's conversation context is compacted (auto-compact), the pipeline state is not lost — the hook re-reads from the filesystem on every prompt submission. The `state_version` field (diff lines 844-865) provides version tracking that survives compaction, and the `remaining_gates` list (a YAML list in the persistent file) represents the ground truth for pipeline progress regardless of what the agent "remembers" in context.

This addresses a critical latent condition in the pre-incident architecture: workflow enforcement that depended on the agent's memory of pipeline state could silently lose its enforcement capability during compaction. The persistent YAML approach eliminates this failure mode.

**Minimal performance overhead**

SATISFIED. Both hooks employ fast-exit patterns for common non-matching cases:

- `check-deletion-safety.sh`: If the Bash command contains no `rm`, `git rm`, or `unlink` token, the extraction produces an empty `DELETED_RAW` array and the script exits 0 at diff line 241 — no grep search is performed.

- `workflow-gate.sh`: If no `active_pipeline` is set in the live state, the script exits 0 at diff line 510 — no prompt parsing or gate checking is performed. Even when a pipeline is active, the prompt regex check (diff line 533) is only invoked after confirming `review-code` is in the remaining gates.

The jq-based JSON parsing adds a subprocess call, but jq is typically fast and the input is small (the hook receives a single JSON object). The grep-based caller search in `check-deletion-safety.sh` could be slow on very large repositories, but the `--exclude-dir` filters and the limited file type includes (`*.sh`, `*.md`, `*.mjs`, `*.yaml`, `*.json`, `*.py`) bound the search space.

---

#### Defense-in-Depth Layer Analysis (Swiss Cheese Model)

I map the five proposals to my four defense layers, identifying the specific failure mode each barrier addresses and the residual holes in each:

| Defense Layer | Barrier | Mechanism | Residual Holes |
|---------------|---------|-----------|----------------|
| **Prevention** | `check-deletion-safety.sh` (Proposal A) | PreToolUse hook blocks `rm`/`git rm`/`unlink` when grep finds callers | Dynamic references (`$DIR/file.sh`), non-grep-detectable patterns, symlink indirection |
| **Prevention** | `workflow-gate.sh` (Proposal E+G) | UserPromptSubmit hook blocks ship/push when `review-code` in remaining_gates | Prompt must match regex; indirect shipping (e.g., raw `curl` to API) would bypass |
| **Detection** | `check-links-local.sh` triage reference (Proposal B) | Hook error message directs to triage protocol instead of "remove reference" default | Agent must actually follow the protocol; no enforcement mechanism beyond the instruction |
| **Detection** | `cwf-live-state.sh` stale pipeline/empty gates warnings | Surfaces contradictory or stale state on every prompt | Warnings are `json_allow` — they inform but do not block; agent can ignore |
| **Mitigation** | Broken Link Triage Protocol (Proposal B) | Decision matrix maps caller types to appropriate actions | Agent compliance is not enforced; protocol is advisory |
| **Mitigation** | Rule 16 Fidelity Check (Proposal C) | Instructs reading original recommendation before acting on triage summaries | Procedural rule only — no automated enforcement; marked as stopgap |
| **Recovery** | Cleanup commands in stale state warnings | Provides exact commands to clear stale pipeline state | Requires manual execution; no automatic recovery |
| **Recovery** | "Restore file(s) or remove callers first" in deletion block message | Guides corrective action after a block | Guidance only; agent must choose the correct path |

**Key structural finding**: The implementation achieves genuine defense-in-depth for the primary failure scenario (file deletion with runtime callers). Proposals A (automated prevention), B (guided detection + triage protocol), and C (cognitive mitigation) operate through independent mechanisms — a grep-based search, a broken-link scanner, and a process rule, respectively. Their failure modes are uncorrelated: Proposal A fails on dynamic references, Proposal B fails if the broken link scanner is not triggered, and Proposal C fails if the agent does not read the original recommendation. The probability of all three failing simultaneously is the product of their individual failure probabilities, not their sum.

For the workflow gate scenario (premature shipping), the defense is primarily a single prevention layer (the UserPromptSubmit hook) with detection support (stale state warnings). There is no independent automated backup if the regex fails to match a shipping intent. However, the consequence is a process violation (unreviewed code), not irreversible data loss, so a single strong automated layer with advisory backup is an appropriate risk posture.

---

#### Concerns (blocking)

After thorough analysis of all 10 changed files, I identify **no blocking concerns**. Each behavioral criterion is satisfied, the qualitative criteria are met, and the defense architecture is structurally sound.

The closest candidate for a blocking concern was the `cwf_live_remove_list_item` function's pipe-to-subshell pattern (diff line 834), where `cwf_live_extract_list_from_file ... | while IFS= read -r line; do ... done > "$list_file"` executes the while loop in a subshell due to the pipe. However, this is correct by design — the function only needs the filtered output written to `$list_file` via stdout redirection, and no shell variables from within the loop are needed afterward. The pattern is valid.

#### Suggestions (non-blocking)

- **Duplicated AWK list-extraction logic across `workflow-gate.sh` and `cwf-live-state.sh`**: The `extract_live_list` AWK block in `workflow-gate.sh` (diff lines 445-476) is character-for-character identical to `cwf_live_extract_list_from_file` in `cwf-live-state.sh` (diff lines 706-738). In my framework, duplicated defense logic creates a latent condition: when one copy is updated and the other is not, the inconsistency becomes a hole in the layer that was not updated. The duplication is likely motivated by startup performance (hooks should not source a large library script), which is a valid concern. I recommend either: (a) extracting the shared AWK into a tiny sourced fragment that both scripts include, or (b) at minimum, adding a cross-reference comment in both files noting the duplication. Track as technical debt.

- **Duplicated utility functions (`trim_ws`, `strip_quotes`, `normalize_scalar`)**: Same analysis as above. `workflow-gate.sh` reimplements these from `cwf-live-state.sh` (`cwf_live_trim`, `cwf_live_strip_quotes`, `cwf_live_normalize_scalar`). Same latent condition risk, same mitigation recommendation.

- **Fixed temp file path in `search_callers`**: `check-deletion-safety.sh` writes to `/tmp/cwf-deletion-safety.err` (diff line 203). If two sessions trigger the hook concurrently, they race on this file. Using `mktemp` would eliminate the race. The practical risk is low because Claude Code hooks are synchronous per session, but the pattern violates the general principle of not using fixed paths for temp files, and a shared machine with multiple users could trigger it.

- **`prompt_requests_blocked_action` detection boundary is undocumented**: `check-deletion-safety.sh` commendably documents its detection boundary in the header comment (diff lines 63-68, noting that dynamic references are not detected). `workflow-gate.sh` does not document what shipping intents the regex can and cannot match. For consistency and operator understanding, add a similar detection-boundary comment. For example: compound commands like `make deploy` or CI-triggering operations would not be caught by the regex.

- **`list-remove` CLI handler bumps version after both file updates**: In the `list-remove` dispatch (diff lines 1038-1048), `cwf_live_bump_state_version` runs after both `cwf_live_remove_list_item` calls complete. A process interruption between the list modification and the version bump would leave a modified list with a stale version number. The `list-set` function (via `cwf_live_set_list`) interleaves version bumps more tightly. For consistency, the `list-remove` handler should match the `list-set` pattern. Severity is low — a stale version number is detectable and self-corrects on the next state operation.

- **`remaining_gates` initialization covers only post-impl stages**: In `run/SKILL.md` (diff line 1156), the initial gates are `"review-code,refactor,retro,ship"` — only the autonomous post-impl stages. This is correct per Decision #19 (pre-impl stages are human-gated), but could confuse operators who expect the full pipeline to be represented. A brief inline comment explaining the rationale would improve clarity and prevent future maintainers from "fixing" this by adding pre-impl gates.

- **Proposal C (Rule 16) is an administrative control, not an engineered control**: The pre-mortem simulation instruction in Rule 16 depends on agent compliance — there is no automated enforcement. This is correctly identified as a stopgap in the rule text. In my taxonomy, administrative controls (procedures, training, rules) are inherently weaker than engineered controls (automated barriers) because they depend on the operator following the procedure correctly every time. Proposal A's hook provides the engineered control for the deletion scenario; Rule 16 provides cognitive reinforcement. The two layers complement each other, but Rule 16 should not be counted as an independent defense layer in risk assessments. It is more accurately a "barrier enhancer" that reduces the probability of the agent intentionally overriding or working around Proposal A's hook.

---

#### Swiss Cheese Model Verdict

The implementation constructs a multi-layered defense architecture that directly addresses the failure path of the 260216 incident. The key structural achievement is that the original failure path — deletion of a file with runtime callers — now encounters at minimum two independent automated barriers:

1. **Layer 1 (Engineered prevention)**: `check-deletion-safety.sh` blocks the deletion command before execution when grep detects callers.
2. **Layer 2 (Guided detection)**: `check-links-local.sh` detects the resulting broken links and directs the agent to the triage protocol, which mandates restoration when runtime callers exist.

Plus two reinforcing procedural barriers:

3. **Layer 3 (Administrative prevention)**: Rule 16 instructs reading the original analysis recommendation and performing a pre-mortem simulation before file deletions.
4. **Layer 4 (Process enforcement)**: The workflow gate prevents shipping unreviewed changes even if deletion does occur.

For all four layers to fail simultaneously: (a) grep would need to miss the caller (dynamic reference), AND (b) the broken link scanner would need to not trigger (file not referenced in markdown), AND (c) the agent would need to skip the fidelity check, AND (d) the agent would need to ship without review (bypass the workflow gate). The probability of this four-way alignment is orders of magnitude lower than the pre-incident single-layer architecture where no barriers existed at all.

The residual risks are documented (dynamic references, regex detection boundaries), low-probability, and none represent single points of failure.

---

#### Verdict: **Pass**

All 12 behavioral criteria are satisfied. The three qualitative criteria — fail-closed design preference, compaction immunity, and minimal performance overhead — are each met with appropriate engineering trade-offs. The defense-in-depth architecture is structurally sound, with genuinely independent barriers whose failure modes are uncorrelated. The non-blocking suggestions address latent conditions (code duplication, fixed temp paths, documentation gaps) that should be tracked as technical debt but do not compromise the current defense architecture's integrity.

#### Provenance

- source: REAL_EXECUTION
- tool: claude-task
- expert: James Reason
- framework: Swiss cheese model — defense-in-depth
- grounding: *Managing the Risks of Organizational Accidents* (Ashgate, 1997), roster-verified
<!-- AGENT_COMPLETE -->
