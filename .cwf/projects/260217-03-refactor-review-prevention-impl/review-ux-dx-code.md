## UX/DX Review

### Concerns (blocking)

- **[C1]** Trailing separator mismatch in `check-deletion-safety.sh` (diff lines 325-326). The `caller_preview` is built with `'; '` as separator but trimmed with `'%, '` (comma-space). The format string uses semicolons but the trim uses a comma pattern. Result: the final entry retains a trailing `'; '` that is never stripped. Should be `${caller_preview%'; '}` or `${caller_preview%; }`.
  Severity: moderate

- **[C2]** Code duplication across `workflow-gate.sh` and `cwf-live-state.sh`: five functions are copy-pasted with only cosmetic name differences: `trim_ws`/`cwf_live_trim`, `strip_quotes`/`cwf_live_strip_quotes`, `normalize_scalar`/`cwf_live_normalize_scalar`, `extract_live_scalar`/`cwf_live_extract_scalar_from_file`, `extract_live_list`/`cwf_live_extract_list_from_file`. Additionally, `trim_ws` and `strip_quotes` are duplicated again in `check-deletion-safety.sh` (diff lines 100-113). Three copies of the same parsing logic will drift independently. `cwf-live-state.sh` already exists as a sourceable library (it checks `BASH_SOURCE[0] == $0` for direct execution). The hook scripts should source it instead of inlining copies.
  Severity: moderate

- **[C3]** `check-deletion-safety.sh` writes grep stderr to a fixed path `/tmp/cwf-deletion-safety.err` (diff line 203). In a multi-session or multi-repo environment, concurrent hook invocations will race on this file. Use `mktemp` instead.
  Severity: moderate

- **[C4]** `workflow-gate.sh` silently exits 0 when `jq` is missing (diff line 369), while `check-deletion-safety.sh` blocks when `jq` is missing and deletion keywords are detected (diff lines 225-228). The inconsistency is confusing: one hook fails open, the other fails closed. The `workflow-gate.sh` fail-open behavior means the gate is completely bypassed if `jq` is absent, which contradicts the "fail-closed" design principle stated in the qualitative criteria. A `jq`-missing scenario should at minimum emit a warning via `json_allow` with an explanatory message, or block consistently.
  Severity: moderate

### Suggestions (non-blocking)

- **[S1]** `check-deletion-safety.sh` does not specify a `timeout` in `hooks.json` (diff lines 40-47), while the existing `read-guard.sh` entry (same hook type, `PreToolUse`) also has no timeout but `workflow-gate.sh` does (`timeout: 5000`). For a hook that invokes `grep -rl` across the repo, consider setting an explicit timeout to prevent stalls on large repositories. A 10-second timeout would be reasonable.

- **[S2]** The `--help` output for `cwf-live-state.sh` (diff line 1051) still reads `sed -n '3,22p'` — but the header comment block has grown from 20 lines to 24 lines with the addition of `list-set` and `list-remove` documentation. The help output will be truncated. Update to `sed -n '3,26p'` or use a dynamic approach.

- **[S3]** `hooks/README.md` is not updated with entries for `check-deletion-safety.sh` or `workflow-gate.sh`. The README serves as the script map for the hooks directory and every existing hook is listed there. Omitting the two new hooks breaks the document's completeness guarantee.

- **[S4]** The `cwf_live_sanitize_yaml_value` function (diff lines 646-655) replaces `[` and `]` with full-width Unicode parentheses `（` and `）`. This is a lossy transformation that silently corrupts user-visible data. If a value legitimately contains brackets (e.g., a task description like "fix [urgent] bug"), the stored value will read "fix （urgent） bug". Consider using proper YAML quoting (the value is already double-quoted) rather than character replacement, or document this behavior prominently so callers are aware.

- **[S5]** `workflow-gate.sh` `prompt_requests_blocked_action` (diff line 492) includes Korean terms (`커밋해|푸시해|배포해`) which is thoughtful for the Korean-speaking user, but these terms are hardcoded with no comment explaining their meaning. Add inline comments (e.g., `# 커밋해=commit, 푸시해=push, 배포해=deploy`) for maintainability by non-Korean-speaking contributors.

- **[S6]** Rule 16 in `impl/SKILL.md` (diff line 1070) is very long (one paragraph, ~80 words) compared to the other rules which are each one short sentence. The parenthetical "(stopgap -- structural fix deferred: modify triage output format to carry original recommendation)" mixes meta/rationale into what should be a crisp imperative rule. Consider splitting the parenthetical into a footnote or separate comment, keeping the rule itself concise.

- **[S7]** The stale pipeline warning in `workflow-gate.sh` (diff line 517) includes a raw command: `Run: bash cwf-live-state.sh set . active_pipeline="" to clean up.` This is not a copy-pasteable command since it lacks the full path. Either use the resolved `$LIVE_STATE_SCRIPT` variable in the message, or phrase it as a skill invocation that the agent can follow directly.

- **[S8]** `cwf-live-state.sh` header comment (diff lines 611-616) documents the new `list-set` and `list-remove` subcommands, but the `list-remove` documentation says `Remove a single item from a list field (idempotent).` without mentioning that it also bumps `state_version` when the key is `remaining_gates`. This side effect is non-obvious and worth documenting.

### Behavioral Criteria Assessment

- [x] **Given delete file with runtime callers -> PreToolUse hook exits 1 with "BLOCKED"** -- `json_block` function (diff line 86-98) outputs `{"decision":"block",...}` and `exit 1`. The reason string starts with "BLOCKED:" (diff line 329). Caller search runs `grep -rl` and block triggers when `FILES_WITH_CALLERS` is non-empty (diff lines 316-335).

- [x] **Given delete file with no callers -> hook exits 0 silently** -- When `DELETED_RAW` is empty and no wildcard, exits 0 at diff line 241. When `DELETED_REL` is empty after filtering, exits 0 at diff line 275. When no callers found, exits 0 at diff line 317.

- [x] **Given grep fails or parse error -> hook exits 1 with actionable error (fail-closed)** -- `search_callers` checks `rc > 1` (diff line 207), sets `SEARCH_FAILED=1`. Caller loop checks this flag and calls `json_block "BLOCKED: deletion safety search failed (${SEARCH_ERROR:-unknown error})."` (diff line 296). The "unknown error" fallback and error message are actionable. Additionally, missing `jq` triggers a block (diff lines 224-228).

- [x] **Given "rm -rf node_modules" -> node_modules/ excluded, hook exits 0** -- `node_modules/*` is in the skip list at diff line 255, and grep `--exclude-dir=node_modules` at diff line 198 prevents false caller matches.

- [x] **Given broken link -> error includes triage protocol reference** -- The `check-links-local.sh` diff (line 345) appends `\nFor triage guidance, see references/agent-patterns.md § Broken Link Triage Protocol` to the error reason.

- [x] **Given triage contradicts analysis -> Rules instructs follow original** -- Rule 16 in `impl/SKILL.md` (diff line 1070) states: "If the triage action contradicts or simplifies the original recommendation: follow the original, not the triage summary."

- [x] **Given cwf:run active + review-code pending + "cwf:ship" -> hook blocks** -- `workflow-gate.sh` checks `list_contains "review-code" "${REMAINING_GATES[@]}"` AND `prompt_requests_blocked_action "$PROMPT"` (diff line 533). The action regex matches `cwf:ship` and `/ship`. Block reason: "BLOCKED action: ship/push/commit requested while review-code is still pending" (diff line 538).

- [x] **Given stage completes -> remaining_gates updated** -- `run/SKILL.md` (diff lines 1155-1156, 1164-1165) instructs `list-set . remaining_gates="{remaining gate stages in order}"` at each stage transition. `cwf-live-state.sh` `cwf_live_set_list` (diff lines 874-989) implements the write with state synchronization.

- [x] **Given stale active_pipeline -> cleanup prompt** -- `workflow-gate.sh` compares `SESSION_ID` vs `STORED_SESSION_ID` (diff line 516-517). On mismatch, emits `json_allow` with `[WARNING] Stale pipeline detected` and cleanup instructions.

- [x] **Given active_pipeline + empty remaining_gates -> stale warning** -- When `REMAINING_GATES` array length is 0, emits `json_allow` with `[WARNING] Active pipeline '...' has no remaining_gates` (diff lines 526-528).

- [x] **Given 500-line prompt -> CLI timeout 180s** -- The timeout scaling table in `review/SKILL.md` (diff lines 1093-1100) maps 300-800 lines to 180s. A 500-line prompt falls in the 300-800 range, yielding `cli_timeout=180`.

- [x] **Given 100-line prompt -> CLI timeout 120s** -- The timeout scaling table maps `< 300` lines to 120s. A 100-line prompt falls in this range, yielding `cli_timeout=120`.

### Provenance
source: REAL_EXECUTION
tool: claude-task
reviewer: UX/DX
duration_ms: --
command: --
<!-- AGENT_COMPLETE -->
