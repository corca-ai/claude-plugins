## Security Review

### Concerns (blocking)

- **[C1]** Predictable shared temp file creates a symlink race (TOCTOU) in `check-deletion-safety.sh`
  Severity: moderate

  In `search_callers()` (diff lines 191-216), grep stderr is redirected to the hardcoded path `/tmp/cwf-deletion-safety.err`, which is then read back via `head -n 1`. Because `/tmp` is world-writable and the filename is predictable, a local attacker could pre-create a symlink at `/tmp/cwf-deletion-safety.err` pointing to a sensitive file. The subsequent `rm -f /tmp/cwf-deletion-safety.err` would then delete the symlink target. While exploitation requires local access and timing, the fix is trivial: use `mktemp` for the error file, consistent with the pattern already used elsewhere in `cwf-live-state.sh`.

  Additionally, the same file is written and read across multiple sequential calls to `search_callers()` within the same hook invocation. If two concurrent hook invocations run (e.g., two Bash tool calls in parallel), they would clobber each other's error files, leading to incorrect `SEARCH_FAILED` decisions (either false-positive blocks or missed failures).

  Recommended fix: replace `/tmp/cwf-deletion-safety.err` with a `mktemp`-created file initialized once at script startup and cleaned up in a trap.

- **[C2]** `cwf_live_sanitize_yaml_value` does not neutralize `{` `}` `:` despite the comment claiming it does
  Severity: moderate

  In `cwf-live-state.sh` (diff lines 645-655), the comment says "this additionally neutralizes : [ ] { } which could confuse parsers," but the implementation only replaces `[` and `]`. The characters `:`, `{`, and `}` are not replaced. Since all values are written inside double-quoted YAML strings and `cwf_live_escape_dq` handles `\`, `"`, and `\n`, the actual YAML injection risk from `:{}` inside double-quoted strings is low. However, the misleading comment is a maintenance hazard -- a future developer may rely on the stated guarantee that `{}:` are neutralized, when they are not.

  Recommended fix: either implement the full sanitization stated in the comment (add `value="${value//:/：}"`, `value="${value//{/（}"`, `value="${value//}/）}"`), or correct the comment to accurately describe what is sanitized.

### Suggestions (non-blocking)

- **[S1]** `workflow-gate.sh` exits 0 (fail-open) when `jq` is missing (diff line 368-370). This is the opposite of the fail-closed philosophy stated in the design principles and used by `check-deletion-safety.sh` (which blocks when jq is unavailable, diff lines 224-228). While the workflow-gate is a softer safety net (informational + blocking for ship/push intents) compared to the deletion-safety gate (hard block), the inconsistency is worth documenting or aligning. If an agent manages to operate without jq, the workflow gate would provide zero protection against premature shipping.

- **[S2]** `extract_live_scalar` in `workflow-gate.sh` (diff lines 423-438) passes the `key` variable directly into an awk regex pattern via string concatenation (`pat = "^[[:space:]]{2}" key ":[[:space:]]*"`). If a caller ever passes a key containing regex metacharacters (e.g., `.`, `+`, `*`), this would match unintended fields. Currently, all keys are hardcoded internal strings (`active_pipeline`, `session_id`, `phase`, etc.) so this is not exploitable today, but it is a latent fragility. The same pattern exists in `cwf_live_extract_scalar_from_file` in `cwf-live-state.sh`. Consider documenting the constraint that keys must be plain alphanumeric/underscore strings, or escaping them.

- **[S3]** The `extract_deleted_from_bash` parser in `check-deletion-safety.sh` (diff lines 143-183) uses naive space-splitting (`IFS=' ' read -r -a argv`) and semicolon-splitting to parse shell commands. This means commands using subshells, quoted strings with spaces, pipes, `$(...)` expansions, or heredocs will be misparsed. For example, `rm "file with spaces.sh"` will be parsed as three separate args. This is acknowledged in the header comments as a detection boundary, but specific bypass patterns are worth documenting:
  - `rm $(echo secret.sh)` -- subshell expansion not resolved, file not detected
  - `rm "path with spaces/file.sh"` -- split incorrectly, path not detected
  - `cat file.sh | xargs rm` -- piped deletion not detected
  - `find . -name '*.sh' -delete` -- find-based deletion not detected

  These are accepted residual risks per the design doc, but the `strip_quotes` function (diff lines 107-113) is only applied during `to_repo_rel`, not during `extract_deleted_from_bash`, so quoted paths like `rm "foo.sh"` will attempt to match `"foo.sh"` (with quotes) rather than `foo.sh`. The `to_repo_rel` call later strips the quotes, so this actually works for simple cases, but intermediate glob/wildcard checks (diff line 176) would see `"*.sh"` rather than `*.sh` and miss the wildcard detection.

- **[S4]** Race condition between YAML state read and write in `cwf_live_remove_list_item` (diff lines 824-842). The function reads the current list, filters it, then calls `cwf_live_upsert_live_list` which reads the file again with awk and writes a new version. If two concurrent `list-remove` calls target the same file (e.g., two pipeline stages completing simultaneously), the second write could overwrite the first removal. This is low risk given single-agent sequential execution, but worth noting for future multi-agent scenarios.

- **[S5]** In the `prompt_requests_blocked_action` regex (diff line 492), the pattern matches Korean keywords (`커밋해|푸시해|배포해`) which is good for the user's language. However, the regex does not account for common variations like `git commit`, only `git push` and `git merge`. The function name says "blocked action" and the block message says "ship/push/commit requested," but `git commit` alone is not matched. This is arguably intentional (local commits without push are less dangerous), but the block message text is misleading if it claims to block "commit" when it does not match `git commit`.

- **[S6]** The `cwf_live_upsert_live_list` awk function (diff lines 746-822) uses `getline` to read from `list_file`. The `escape_dq` function within the awk script (diff lines 758-763) handles `\` and `"` but does not handle newlines, unlike the bash-level `cwf_live_escape_dq` which was updated to strip `\n`. If a list item somehow contains a newline (unlikely given comma-splitting), the awk output would break YAML structure. Low risk since list items come from validated gate names or comma-split input, but the awk-level escaping is weaker than the bash-level escaping.

### Behavioral Criteria Assessment

- [x] Given delete file with runtime callers -> PreToolUse hook exits 1 with "BLOCKED" -- `check-deletion-safety.sh` lines 329-335: constructs "BLOCKED: deleted file(s) have runtime callers" reason and calls `json_block` which exits 1.

- [x] Given delete file with no callers -> hook exits 0 silently -- Lines 274-276 and 316-318: when `DELETED_REL` or `FILES_WITH_CALLERS` is empty, `exit 0` is reached with no output.

- [x] Given grep fails or parse error -> hook exits 1 with actionable error (fail-closed) -- Lines 207-211 and 295-297: when `grep` returns rc > 1, `SEARCH_FAILED=1` is set, and the loop checks this flag to call `json_block` with "deletion safety search failed" message. Also, when jq is unavailable but deletion keywords are detected, it blocks (lines 225-228).

- [x] Given "rm -rf node_modules" -> node_modules/ excluded, hook exits 0 -- Lines 254-256: the `case` statement skips `node_modules/*` paths. Also, `search_callers` excludes `--exclude-dir=node_modules`.

- [x] Given broken link -> error includes triage protocol reference -- `check-links-local.sh` diff line 345: the REASON string now appends "For triage guidance, see references/agent-patterns.md ... Broken Link Triage Protocol".

- [x] Given triage contradicts analysis -> Rules section instructs follow original -- `impl/SKILL.md` diff line 1070: Rule 16 "Recommendation Fidelity Check" states "If the triage action contradicts or simplifies the original recommendation: follow the original, not the triage summary."

- [x] Given cwf:run active + review-code pending + "cwf:ship" -> UserPromptSubmit blocks -- `workflow-gate.sh` lines 533-538: checks `list_contains "review-code"` in REMAINING_GATES and `prompt_requests_blocked_action "$PROMPT"` which matches `cwf:ship`, then calls `json_block`.

- [x] Given stage completes -> remaining_gates updated via list-set -- `run/SKILL.md` diff lines 82-83: stage execution loop includes `list-set . remaining_gates="{remaining gate stages in order}"` after each phase update.

- [x] Given stale active_pipeline -> cleanup prompt output -- `workflow-gate.sh` lines 516-518: when `SESSION_ID != STORED_SESSION_ID`, calls `json_allow` with a WARNING message including cleanup instructions.

- [x] Given active_pipeline set + remaining_gates empty -> stale warning -- `workflow-gate.sh` lines 526-528: when `REMAINING_GATES` array is empty but pipeline is active, calls `json_allow` with warning to "Run cleanup or reinitialize run-state."

- [x] Given 500-line prompt -> CLI timeout 180s -- `review/SKILL.md` diff lines 1092-1100: the timeout scaling table shows 300-800 lines maps to `cli_timeout` 180s. 500 lines falls in this range.

- [x] Given 100-line prompt -> CLI timeout 120s -- Same table: < 300 lines maps to `cli_timeout` 120s. 100 lines falls in this range.

**Qualitative criteria:**

- **Fail-closed design**: Both hooks demonstrate fail-closed behavior. `check-deletion-safety.sh` blocks on jq absence, grep failure, and wildcard detection. `workflow-gate.sh` blocks ship/push while review-code is pending. The one exception is `workflow-gate.sh`'s fail-open on jq absence (noted in S1), which is a design trade-off rather than an oversight given the hook's advisory nature.

- **Compaction immunity**: Both hooks read from stdin (hook JSON input) and filesystem state (YAML files, git repo). No dependency on conversational memory. `workflow-gate.sh` resolves state via `cwf-live-state.sh resolve` which reads persisted YAML, making it compaction-immune. `check-deletion-safety.sh` operates purely on the incoming tool call JSON and grep results.

- **Minimal performance overhead**: `check-deletion-safety.sh` exits early (exit 0) for non-deletion commands before any grep search. `workflow-gate.sh` has a 5000ms timeout in hooks.json and exits early when no active pipeline exists. The `grep -rl` in `search_callers` excludes heavy directories (node_modules, .git, projects, prompt-logs, sessions). Performance overhead is proportional to repo size but bounded by the excluded directories.

### Provenance

source: REAL_EXECUTION
tool: claude-task
reviewer: Security
duration_ms: --
command: --

<!-- AGENT_COMPLETE -->
