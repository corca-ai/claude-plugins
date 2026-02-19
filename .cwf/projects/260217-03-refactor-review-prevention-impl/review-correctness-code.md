# Correctness Review -- Prevention Proposals (Code)

**Verdict: Conditional Pass**

The implementation is well-structured with correct fail-closed semantics for the deletion-safety hook and appropriate fail-open behavior for the advisory workflow-gate hook. YAML manipulation follows established patterns from the existing codebase. Two moderate concerns need to be addressed before merge; all others are non-blocking.

---

## Concerns (blocking)

- **[C1]** `list-remove` CLI dispatch bumps `state_version` independently on root and session state files, causing version drift
  Severity: moderate
  File: `plugins/cwf/scripts/cwf-live-state.sh`, diff lines 1042-1047 (the `list-remove` case block)

  The code calls `cwf_live_bump_state_version` separately on `$effective_state` and `$root_state`. Each call reads the *current* version from its respective file, adds 1, and writes back. If the two files have different starting versions (plausible after partial sync failures or race conditions), they will diverge further.

  Contrast with the `cwf_live_set_list` function (diff lines 972-988), which correctly captures the version from the first bump and then *explicitly writes that same version* to the second file via `cwf_live_upsert_live_scalar`:
  ```bash
  state_version="$(cwf_live_bump_state_version "$effective_state")"
  # ...
  if [[ -n "$state_version" ]]; then
    cwf_live_upsert_live_scalar "$root_state" "state_version" "$state_version"
  fi
  ```

  The `list-remove` block should follow the same pattern:
  ```bash
  if [[ "$rl_key" == "remaining_gates" ]]; then
    sv="$(cwf_live_bump_state_version "$effective_state")"
    if [[ "$effective_state" != "$root_state" ]]; then
      cwf_live_upsert_live_scalar "$root_state" "state_version" "$sv"
    fi
  fi
  ```

  Impact: Divergent `state_version` values between root and session state. `workflow-gate.sh` reads `state_version` from whichever file `resolve` returns, so the value could be inconsistent depending on which file is resolved. This undermines the version as a reliable ordering signal.

- **[C2]** `caller_preview` trailing delimiter strip uses wrong character -- `, ` vs `; `
  Severity: moderate
  File: `plugins/cwf/hooks/scripts/check-deletion-safety.sh`, diff lines 325-327

  The code builds `caller_preview` using `"; "` as separator then strips trailing `", "`:
  ```bash
  caller_preview="$(printf '%s; ' "${CALLER_LINES[@]}")"
  caller_preview="${caller_preview%, }"
  ```

  The `${caller_preview%, }` suffix-strip pattern looks for a trailing comma-space `, ` but the actual trailing characters are semicolon-space `; `. The trailing `; ` is never removed. The BLOCKED message will read:
  `"Callers: foo.sh; bar.sh; . Restore file(s) or..."`
  with a stray `; ` before the period.

  Fix: `${caller_preview%; }`.

---

## Suggestions (non-blocking)

- **[S1]** Duplicated AWK list-extraction logic across `workflow-gate.sh` and `cwf-live-state.sh`
  `extract_live_list` in `workflow-gate.sh` (diff lines 445-476) is a near-verbatim copy of `cwf_live_extract_list_from_file` in `cwf-live-state.sh` (diff lines 706-738). Likewise `extract_live_scalar` duplicates `cwf_live_extract_scalar_from_file`, and `trim_ws`/`strip_quotes`/`normalize_scalar` duplicate their `cwf_live_*` counterparts. The hook already locates `LIVE_STATE_SCRIPT` (diff line 374); it could `source` it instead of `bash`-executing it to gain access to the shared functions. This eliminates a copy-paste maintenance hazard where a bug fix in one copy is not propagated to the other.

- **[S2]** `search_callers` writes to a fixed path `/tmp/cwf-deletion-safety.err` -- concurrent invocations will race
  File: `plugins/cwf/hooks/scripts/check-deletion-safety.sh`, diff line 203
  If two Claude sessions trigger the hook simultaneously, they share the same error file. Use `mktemp` to create a unique error capture file per invocation.

- **[S3]** Dead code: no-op conditional on `combined_hits`
  File: `plugins/cwf/hooks/scripts/check-deletion-safety.sh`, diff lines 283-285
  ```bash
  if [[ -n "$combined_hits" ]]; then
    :
  fi
  ```
  This conditional performs no action. Appears to be debugging residue. Can be removed without effect.

- **[S4]** `CALLER_LINES` limit of 6 is global across all deleted files, not per-file
  File: `plugins/cwf/hooks/scripts/check-deletion-safety.sh`, diff lines 307-313
  If the first deleted file has 6+ callers, no caller lines from subsequent deleted files are captured. The BLOCKED message could list "file A and file B have callers" but only show callers of file A. Consider either a per-file limit or documenting this as intentional truncation behavior.

- **[S5]** `cwf_live_sanitize_yaml_value` comment claims to neutralize `: [ ] { }` but code only replaces `[` and `]`
  File: `plugins/cwf/scripts/cwf-live-state.sh`, diff lines 245-254
  The comment says "neutralizes : [ ] { } which could confuse parsers" but the implementation only replaces `[` with fullwidth `(` and `]` with fullwidth `)`. The `{`, `}`, and `:` replacements mentioned in the comment are absent. Since scalar values are always emitted inside double quotes in the YAML, this is defense-in-depth and low risk, but the comment should match the code.

- **[S6]** `extract_deleted_from_bash` simple word-splitting on space misses quoted arguments
  File: `plugins/cwf/hooks/scripts/check-deletion-safety.sh`, diff lines 143-183
  The function uses `IFS=' ' read -r -a argv <<< "$segment"` to tokenize each command segment. This means a command like `rm "path with spaces/file.sh"` will split into `["rm", "\"path", "with", "spaces/file.sh\""]`. The `strip_quotes` function later can only remove surrounding quotes from a single token, but here the quotes are split across multiple tokens. This is an inherent limitation of the simple-split approach. The header comment documents that detection is best-effort, so this is acceptable, but worth noting that filenames with spaces will be mishandled.

- **[S7]** `search_callers` basename search can produce false positives for common filenames
  File: `plugins/cwf/hooks/scripts/check-deletion-safety.sh`, diff lines 287-293
  When `base_name` differs from `rel_path`, the code searches for just the basename (e.g., `"utils.sh"`). A file named `lib/utils.sh` being deleted would trigger a search for `"utils.sh"` which could match references to completely different files like `other/utils.sh`. This is acknowledged by the detection boundary comment as an accepted trade-off favoring safety (false positives over false negatives).

- **[S8]** `workflow-gate.sh` `prompt_requests_blocked_action` regex does not match multi-word prompts containing the keywords mid-sentence without word boundary
  File: `plugins/cwf/hooks/scripts/workflow-gate.sh`, diff line 492
  The regex `(^|[[:space:]])(cwf:ship|/ship|git[[:space:]]+push|...)([[:space:]]|$)` uses `grep -Eiq` which searches for the pattern anywhere in the input. This is correct for single-line matching. However, the `-q` flag combined with piped `printf '%s'` strips trailing newlines from the prompt. Since `$` matches end-of-string, a prompt ending in exactly `"cwf:ship"` (no trailing newline) will still match correctly because `grep` treats end-of-input as `$`. No actual bug, just noting the boundary behavior.

- **[S9]** The `remaining_gates` initialization in `run/SKILL.md` starts at `review-code` not `gather`
  File: `plugins/cwf/skills/run/SKILL.md`, diff line 1156
  `remaining_gates="review-code,refactor,retro,ship"` omits the pre-impl stages (`gather`, `clarify`, `plan`, `review-plan`, `impl`). This is semantically correct since `workflow-gate.sh` only blocks ship/push actions when `review-code` is in the list, and pre-impl stages have human gates. But a clarifying comment in SKILL.md would help future maintainers understand this is intentional, not an oversight.

---

## Behavioral Criteria Assessment

- [x] **BDD 1**: Given delete file with runtime callers --> PreToolUse hook exits 1 with "BLOCKED: {file} has runtime callers"
  Evidence: `check-deletion-safety.sh` diff lines 278-335 -- `search_callers` finds references via `grep -rl`, matches accumulate in `FILES_WITH_CALLERS`, and `json_block` emits `{"decision":"block","reason":"BLOCKED: deleted file(s) have runtime callers: ..."}` with `exit 1` (diff line 97).

- [x] **BDD 2**: Given delete file with no callers --> hook exits 0 silently
  Evidence: Three exit-0 paths: no deletions detected (diff lines 240-242), no repo-relative paths resolved (diff lines 274-276), no files with callers after filtering (diff lines 316-318). All are silent `exit 0`.

- [x] **BDD 3**: Given grep fails or parse error --> hook exits 1 with actionable error (fail-closed)
  Evidence: Two paths: (a) Missing `jq` + input looks like deletion: `json_block` at diff lines 225-228 exits 1. (b) `grep -rl` exit code > 1: `SEARCH_FAILED=1` at diff lines 207-211, then `json_block "BLOCKED: deletion safety search failed..."` at diff lines 295-297 exits 1. Both are fail-closed with actionable messages.

- [x] **BDD 4**: Given "rm -rf node_modules" --> node_modules/ excluded from caller search, hook exits 0
  Evidence: `search_callers` uses `--exclude-dir=node_modules` (diff line 198). The relative path `node_modules/...` is caught by `case "$rel_path" in node_modules/*|...) continue` (diff lines 254-256). The file is excluded from `DELETED_REL`, and `exit 0` is reached at diff lines 274-276 if the array is empty.

- [x] **BDD 5**: Given broken link to recently deleted file --> error includes reference to Broken Link Triage Protocol + agent-patterns.md contains triage decision matrix
  Evidence: Diff line 345 appends `\nFor triage guidance, see references/agent-patterns.md Section Broken Link Triage Protocol` to `check-links-local.sh` REASON output. Diff lines 549-599 add the full "Broken Link Triage Protocol" section to `agent-patterns.md` including the decision matrix table (diff lines 578-583).

- [x] **BDD 6**: Given triage item contradicts analysis recommendation --> Rules section instructs follow original recommendation
  Evidence: `impl/SKILL.md` diff lines 1070-1071 add Rule 16 "Recommendation Fidelity Check": "read the original analysis recommendation before acting. If the triage action contradicts or simplifies the original recommendation: follow the original, not the triage summary."

- [x] **BDD 7**: Given cwf:run active with remaining_gates including review-code + prompt contains "cwf:ship"/"git push"/"gh pr create" --> UserPromptSubmit hook exits 1 with gate violation
  Evidence: `workflow-gate.sh` diff lines 533-538: `list_contains "review-code" "${REMAINING_GATES[@]}" && prompt_requests_blocked_action "$PROMPT"` checks both conditions. `prompt_requests_blocked_action` (diff line 492) matches `cwf:ship`, `git push`, `gh pr create`, `gh pr merge` via regex. When matched and no `pipeline_override_reason`, `json_block` exits 1 with "BLOCKED action: ship/push/commit requested while review-code is still pending."

- [x] **BDD 8**: Given cwf:run completes a stage --> remaining_gates is updated (list-set rebuilds list)
  Evidence: `run/SKILL.md` diff lines 1164-1166 instruct using `list-set` at each stage transition: `bash cwf-live-state.sh list-set . remaining_gates="{remaining gate stages in order}"`. `cwf_live_set_list` (diff lines 874-989) parses the comma-separated input, validates gate names, writes via `cwf_live_upsert_live_list`, and bumps `state_version`.

- [x] **BDD 9**: Given stale active_pipeline from previous session --> cleanup prompt output to agent
  Evidence: `workflow-gate.sh` diff lines 515-517: when `SESSION_ID` differs from `STORED_SESSION_ID`, `json_allow "[WARNING] Stale pipeline detected: active_pipeline='...' belongs to session '...' but current session is '...'. Run: bash cwf-live-state.sh set . active_pipeline=\"\" to clean up."` The allow decision with warning ensures the agent can proceed while being informed.

- [x] **BDD 10**: Given active_pipeline set but remaining_gates empty --> stale state warning output
  Evidence: `workflow-gate.sh` diff lines 526-528: `if [[ "${#REMAINING_GATES[@]}" -eq 0 ]]; then json_allow "[WARNING] Active pipeline '...' has no remaining_gates in live state. Run cleanup or reinitialize run-state before continuing."` Uses `json_allow` (exit 0) which is correct for advisory/informational warnings.

- [x] **BDD 11**: Given 500-line review prompt --> CLI timeout set to 180s (not 120)
  Evidence: `review/SKILL.md` diff lines 1092-1100: timeout scaling table specifies 300-800 lines maps to `cli_timeout` of 180. 500 lines falls in this range.

- [x] **BDD 12**: Given 100-line review prompt --> CLI timeout remains at 120s
  Evidence: `review/SKILL.md` diff lines 1092-1100: table specifies < 300 lines maps to `cli_timeout` of 120. 100 < 300.

---

## Qualitative Criteria Assessment

### Fail-closed design: hooks prefer false-positive blocks over silent pass on errors
**Pass.** `check-deletion-safety.sh` (safety hook) is consistently fail-closed: missing jq triggers `json_block`/exit 1 when deletion-like input detected (diff lines 225-228); grep failure with rc > 1 triggers `json_block`/exit 1 (diff lines 295-297); wildcard deletion triggers `json_block`/exit 1 (diff lines 244-246). `workflow-gate.sh` (advisory hook) is intentionally fail-open for non-blocking scenarios: missing jq exits 0 (diff lines 368-370), missing live-state file exits 0 (diff lines 504-506), empty pipeline exits 0 (diff lines 509-511). Only the specific blocked-action condition (review-code pending + ship intent) triggers exit 1. This is appropriate differentiation -- safety hooks fail-closed, advisory hooks fail-open.

### Compaction immunity: workflow enforcement reads from persistent YAML, not chat memory
**Pass.** `workflow-gate.sh` resolves and reads the YAML live-state file at runtime (diff lines 503-524) using `cwf-live-state.sh resolve` and direct `awk`-based extraction from the file. No dependency on conversation context or chat history. The `state_version` field provides a monotonic counter to detect stale reads.

### Minimal performance overhead: fast-exit on non-matching common cases
**Pass.** Both hooks have early-exit paths for the common non-matching case:
- `check-deletion-safety.sh`: exits 0 immediately if no repo root (diff lines 80-82), if tool is not Bash (implicit -- `DELETED_RAW` stays empty, exit 0 at diff lines 240-242), or if no deletion commands detected (diff lines 240-242).
- `workflow-gate.sh`: exits 0 if no jq (diff lines 368-370), no live-state file (diff lines 504-506), no active pipeline (diff lines 509-511). The hook only proceeds to regex matching and list extraction when an active pipeline is confirmed.
- The `check-deletion-safety.sh` hook in `hooks.json` uses `"matcher": "Bash"` (diff line 41), so it only fires for Bash tool calls, not for Read/Write/Edit/etc.

---

## Provenance

source: FALLBACK
tool: claude-task-fallback
reviewer: Correctness
duration_ms: --
command: codex (timed out at 240s; substituted by claude-opus-4-6)

<!-- AGENT_COMPLETE -->
