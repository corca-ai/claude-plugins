# Correctness Review — Prevention Proposals (Code)

**Verdict: Conditional Pass**

The implementation is sound overall with correct fail-closed/fail-open semantics, well-structured YAML manipulation, and appropriate input validation. Two moderate concerns require attention before merge; all other findings are non-blocking suggestions.

---

## Concerns (blocking)

- **[C1]** `cwf_live_remove_list_item` loses filtered output due to subshell pipe
  Severity: moderate
  File: `plugins/cwf/scripts/cwf-live-state.sh`, diff lines 834-838 (function `cwf_live_remove_list_item`)

  The `while` loop filtering items is part of a pipeline (`| while IFS= read -r line`), which runs in a subshell. However, the actual issue is more subtle: the `cwf_live_extract_list_from_file ... | while ... done > "$list_file"` construct is correct syntactically because the entire `while ... done` block's stdout is redirected to `$list_file`. **However**, there is a real correctness issue: the `while IFS= read -r line` loop receives input from `cwf_live_extract_list_from_file` via pipe, and the comparison `[[ "$line" != "$item_to_remove" ]]` works correctly for exact matches. But the pipe-to-while pattern means the `list_file` variable used inside the `while` body is indeed available (it's the outer scope variable captured by the subshell). The redirect `> "$list_file"` applies to the `while...done` compound command, so the filtered output does flow to the file. After re-analysis, this is actually correct. **Withdrawing this concern.**

  *CORRECTION*: Re-examining more carefully, the construct is:
  ```bash
  cwf_live_extract_list_from_file "$state_file" "$key" | while IFS= read -r line; do
    if [[ "$line" != "$item_to_remove" ]]; then
      printf '%s\n' "$line"
    fi
  done > "$list_file"
  ```
  This is correct. The `> "$list_file"` redirect captures stdout of the entire `while...done` compound command, including the piped input side. The printf output goes to `$list_file`. No issue here.

  **Replacing with actual concern:**

- **[C1]** `list-remove` does not synchronize `state_version` consistently across root and session state files
  Severity: moderate
  File: `plugins/cwf/scripts/cwf-live-state.sh`, diff lines 1038-1047 (the `list-remove` CLI dispatch block)

  When `effective_state != root_state`, the code calls `cwf_live_bump_state_version` on both files independently. Each call reads the current version from its respective file, increments by 1, and writes back. Since root and session state files may have different `state_version` values (e.g., if one was updated but a sync was interrupted), the two files could end up with divergent version numbers.

  Compare with `cwf_live_set_list` (diff lines 972-988) which correctly bumps on the effective state first, captures the resulting version number, then explicitly writes that same version to the root state via `cwf_live_upsert_live_scalar`. The `list-remove` CLI block should follow the same pattern:

  ```bash
  if [[ "$rl_key" == "remaining_gates" ]]; then
    sv="$(cwf_live_bump_state_version "$effective_state")"
    if [[ "$effective_state" != "$root_state" ]]; then
      cwf_live_upsert_live_scalar "$root_state" "state_version" "$sv"
    fi
  fi
  ```

  Instead it does:
  ```bash
  if [[ "$rl_key" == "remaining_gates" ]]; then
    cwf_live_bump_state_version "$effective_state" >/dev/null
    if [[ "$effective_state" != "$root_state" ]]; then
      cwf_live_bump_state_version "$root_state" >/dev/null
    fi
  fi
  ```

  This will cause version drift between root and session state when they have different starting versions.

- **[C2]** `caller_preview` trailing delimiter uses wrong character
  Severity: moderate
  File: `plugins/cwf/hooks/scripts/check-deletion-safety.sh`, diff lines 325-327

  The code builds `caller_preview` with `"; "` as separator but then strips trailing `", "`:
  ```bash
  caller_preview="$(printf '%s; ' "${CALLER_LINES[@]}")"
  caller_preview="${caller_preview%, }"
  ```

  The `%; ` suffix strip looks for `, ` (comma-space) but the actual trailing characters are `; ` (semicolon-space). This means the trailing `; ` is never stripped from the output. The BLOCKED message will have a trailing `; ` before the period, producing: `"Callers: foo.sh; bar.sh; . Restore file(s) or..."`.

  Fix: change `${caller_preview%, }` to `${caller_preview%; }`.

---

## Suggestions (non-blocking)

- **[S1]** Duplicated AWK list-extraction logic between `workflow-gate.sh` and `cwf-live-state.sh`
  The `extract_live_list` function in `workflow-gate.sh` (diff lines 445-476) is a near-identical copy of `cwf_live_extract_list_from_file` in `cwf-live-state.sh` (diff lines 706-738). Similarly, `extract_live_scalar` duplicates `cwf_live_extract_scalar_from_file`, and `normalize_scalar`/`trim_ws`/`strip_quotes` duplicate their `cwf_live_*` counterparts. Consider sourcing the shared functions from `cwf-live-state.sh` directly. The hook already locates `LIVE_STATE_SCRIPT` (diff line 374) and calls it via `bash`; it could `source` it instead to reuse the functions. This would prevent future divergence.

- **[S2]** `search_callers` writes errors to a fixed path `/tmp/cwf-deletion-safety.err`
  File: `plugins/cwf/hooks/scripts/check-deletion-safety.sh`, diff line 203
  If two concurrent hook invocations run (e.g., multiple Claude sessions), they will race on the same error file. Consider using `mktemp` for the error file.

- **[S3]** The `combined_hits` variable is set but the `if [[ -n "$combined_hits" ]]; then :; fi` block (diff lines 283-285) is a no-op
  File: `plugins/cwf/hooks/scripts/check-deletion-safety.sh`, diff lines 282-285
  This appears to be dead code / debugging residue. The `combined_hits` value from `search_callers "$rel_path"` is used later regardless. The conditional with `:` (no-op) can be removed without effect.

- **[S4]** `CALLER_LINES` limit of 6 is applied globally across all deleted files, not per-file
  File: `plugins/cwf/hooks/scripts/check-deletion-safety.sh`, diff lines 307-313
  If the first deleted file has 6+ callers, no caller lines from subsequent deleted files will be captured. This could make the BLOCKED message misleading (showing "file A and file B have callers" but only listing callers of file A). Consider either a per-file limit or documenting this as intentional truncation.

- **[S5]** `prompt_requests_blocked_action` regex includes Korean terms but no Chinese/Japanese equivalents
  File: `plugins/cwf/hooks/scripts/workflow-gate.sh`, diff line 492
  The regex matches Korean terms (`commit-hae`, `push-hae`, `deploy-hae`). This is consistent with the project's Korean-speaking user base documented in AGENTS.md. No change needed, but worth noting the locale-specificity for future reference.

- **[S6]** `cwf_live_sanitize_yaml_value` replaces `[` and `]` with fullwidth parentheses but does not handle `{` and `}`
  File: `plugins/cwf/scripts/cwf-live-state.sh`, diff lines 245-254
  The comment says "neutralizes : [ ] { } which could confuse parsers" but the code only replaces `[` -> `(` (fullwidth) and `]` -> `)` (fullwidth). The `{` and `}` replacements and `:` replacement mentioned in the comment are absent. Either update the comment to match the code, or add the missing replacements. Since scalar values are already double-quoted in the YAML output, this is defense-in-depth and low risk.

- **[S7]** The `remaining_gates` initialization in `run/SKILL.md` starts with `review-code,refactor,retro,ship` but the full pipeline starts at `gather`
  File: `plugins/cwf/skills/run/SKILL.md`, diff line 1156
  The initial `remaining_gates` list skips `gather`, `clarify`, `plan`, `review-plan`, and `impl`. This makes sense semantically (these are the "remaining" gates after initialization, and the pre-impl stages have human gates that don't need workflow-gate enforcement), but the `workflow-gate.sh` hook only checks for `review-code` in `remaining_gates` before blocking ship actions. If the intent is that the hook only guards post-impl shipping, this is correct. Worth a clarifying comment in the SKILL.md.

- **[S8]** The `to_repo_rel` function in `check-deletion-safety.sh` does not resolve symlinks
  File: `plugins/cwf/hooks/scripts/check-deletion-safety.sh`, diff lines 115-141
  If a file path contains symlinks, the comparison `[[ "$raw_path" != "$REPO_ROOT/"* ]]` could fail even for files inside the repo. This is a minor edge case since symlinks in repo roots are uncommon.

---

## Behavioral Criteria Assessment

- [x] **BDD 1**: Given an agent attempts to delete a file via Bash / When the file has runtime callers / Then PreToolUse hook exits 1 with "BLOCKED"
  Evidence: `check-deletion-safety.sh` lines 278-335 (diff) -- `search_callers` finds references via `grep -rl`, `FILES_WITH_CALLERS` accumulates matches, and `json_block` emits `{"decision":"block","reason":"BLOCKED: ..."}` with `exit 1`. The `json_block` function at diff line 97 explicitly calls `exit 1`.

- [x] **BDD 2**: Given an agent attempts to delete a file with no callers / Then the hook exits 0 silently
  Evidence: diff lines 316-318 -- `if [[ ${#FILES_WITH_CALLERS[@]} -eq 0 ]]; then exit 0; fi`. Also diff lines 240-242 handle the case of no deletions detected: `exit 0`. And diff lines 274-276 handle no repo-relative paths resolved: `exit 0`.

- [x] **BDD 3**: Given grep fails or cannot parse the deletion command / Then the hook exits 1 with actionable error (fail-closed)
  Evidence: Two paths:
  (a) If `jq` is missing and input looks like a deletion: diff lines 225-228 call `json_block "Deletion safety gate requires jq for safe parsing."` which exits 1.
  (b) If `grep -rl` fails with exit code >1: diff lines 207-211 set `SEARCH_FAILED=1`, then diff lines 295-297 call `json_block "BLOCKED: deletion safety search failed..."` which exits 1.

- [x] **BDD 4**: Given "rm -rf node_modules" / Then node_modules/ is excluded from caller search / And hook exits 0
  Evidence: `search_callers` uses `--exclude-dir=node_modules` (diff line 198). The `to_repo_rel` result for `node_modules` paths gets caught by diff lines 254-256: `case "$rel_path" in node_modules/*|...) continue ;;`. So the file is excluded from `DELETED_REL` and exit 0 is reached at diff line 274-276 (empty `DELETED_REL`).

- [x] **BDD 5**: Given a broken link to a recently deleted file / Then the error includes reference to Broken Link Triage Protocol
  Evidence: diff line 345 modifies `check-links-local.sh` to append `\nFor triage guidance, see references/agent-patterns.md Section Broken Link Triage Protocol` to the REASON string.

- [x] **BDD 6**: Given cwf:impl receives a triage item contradicting original recommendation / Then Rules section instructs to follow original
  Evidence: diff lines 1070-1071 add rule 16 to `impl/SKILL.md`: "For each triage item referencing an analysis document, read the original analysis recommendation before acting. If the triage action contradicts or simplifies the original recommendation: follow the original, not the triage summary."

- [x] **BDD 7**: Given cwf:run active with remaining_gates including review-code / When prompt contains "cwf:ship" / Then UserPromptSubmit hook exits 1 with gate violation
  Evidence: `workflow-gate.sh` diff lines 533-538: `if list_contains "review-code" "${REMAINING_GATES[@]}" && prompt_requests_blocked_action "$PROMPT"` checks both conditions. `prompt_requests_blocked_action` (diff line 491-493) matches `cwf:ship` via the regex. If matched and no override reason, `json_block` is called with the BLOCKED message, exiting 1.

- [x] **BDD 8**: Given cwf:run completes a stage / When remaining_gates updated via list-remove / Then completed stage removed from YAML list
  Evidence: `cwf_live_remove_list_item` (diff lines 824-841) extracts the current list, filters out the target item, and upserts the filtered list. The CLI dispatch (diff lines 1008-1049) invokes this for both effective and root state, maintaining synchronization. The `list-remove` command validates the key and gate name before operating.

- [x] **BDD 9**: Given stale active_pipeline from previous session / Then cleanup prompt output
  Evidence: `workflow-gate.sh` diff lines 515-517: when `SESSION_ID` differs from `STORED_SESSION_ID`, the hook calls `json_allow` with a `[WARNING] Stale pipeline detected` message including cleanup instructions.

- [x] **BDD 10**: Given active_pipeline set but remaining_gates empty / Then stale state warning output
  Evidence: `workflow-gate.sh` diff lines 526-528: `if [[ "${#REMAINING_GATES[@]}" -eq 0 ]]; then json_allow "[WARNING] Active pipeline '...' has no remaining_gates..."`. This uses `json_allow` (exit 0) which is correct for advisory warnings.

- [x] **BDD 11**: Given review prompt has 500 lines / Then CLI timeout is 180 seconds
  Evidence: `review/SKILL.md` diff lines 1092-1100: table specifies 300-800 lines maps to `cli_timeout` of 180. 500 lines falls in the 300-800 range.

- [x] **BDD 12**: Given review prompt has 100 lines / Then CLI timeout remains 120 seconds
  Evidence: `review/SKILL.md` diff lines 1092-1100: table specifies < 300 lines maps to `cli_timeout` of 120. 100 lines is < 300.

---

## Qualitative Criteria Assessment

### Fail-closed for safety hooks; fail-open for advisory hooks
**Pass.** `check-deletion-safety.sh` (safety) uses `exit 1` / `json_block` for all error paths: missing jq (diff lines 225-228), failed grep (diff lines 295-297), and wildcard deletions (diff lines 244-246). `workflow-gate.sh` (advisory/gate) uses `exit 0` / `json_allow` for warnings (stale pipeline, empty gates) and only `exit 1` / `json_block` for the specific blocked action case. Missing `jq` in workflow-gate results in `exit 0` (diff lines 368-370), which is fail-open -- correct for an advisory hook.

### Header documents detection boundary
**Pass.** `check-deletion-safety.sh` has a clear header comment (diff lines 63-69) documenting: "Detection boundary: grep -rl detects literal string matches only. Variable-interpolated references... will NOT be detected. This is an accepted residual risk."

### List operations use same AWK patterns as existing scalar operations
**Partial pass.** The AWK patterns in `cwf_live_upsert_live_list` (diff lines 747-821) follow the same structural pattern as `cwf_live_upsert_live_scalar`: `BEGIN` block for state, `/^live:/` detection, `in_live && /^[^[:space:]]/` for section end, and `END` block for append-if-missing. The key-matching pattern `"^[[:space:]]{2}" key ":[[:space:]]*"` is consistent. However, as noted in [S1], the hook's local copies (`extract_live_list`, `extract_live_scalar`) duplicate rather than source these patterns, creating a maintenance burden.

---

## Provenance

source: FALLBACK
tool: claude-task-fallback
reviewer: Correctness
duration_ms: --
command: codex (timed out after 180s)

<!-- AGENT_COMPLETE -->
