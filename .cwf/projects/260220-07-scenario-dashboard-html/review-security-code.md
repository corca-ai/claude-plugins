## Security Review

### Concerns (blocking)

- **[C1]** `invoke_prompt()` passes `$prompt` as a word argument directly to the `claude` binary via `"$CLAUDE_BIN" --print "$prompt"`. The prompt values are fixed strings (`"cwf:retro --light"`, `"cwf:setup"`, `"cwf:setup --hooks"`) embedded in the script itself. However, `$CLAUDE_BIN` originates from an unvalidated environment variable (`CLAUDE_BIN`) or the `--claude-bin` CLI flag. No canonicalization or path restriction is enforced — any executable path accepted. If an attacker controls `CLAUDE_BIN` (for example via a tainted environment passed into a CI pipeline that invokes this script), an arbitrary executable is run with `--dangerously-skip-permissions` and any file system access the agent permits. The `--dangerously-skip-permissions` flag amplifies the impact: once an attacker-controlled binary is substituted, it executes in the caller's working directory with full file-system write access as the invoking user.

  Location: `scripts/runtime-residual-smoke.sh`, lines 134-144 (validation) and line 199 (invocation).

  Severity: security

- **[C2]** `classify_case_result()` sets its outputs via global variables `RUN_RESULT` and `RUN_REASON` rather than function-local variables or a return convention. In `run_case()` the function is called twice: once in the retry loop (line 250) and once for the fallback path (line 289). Both call sites read `$RUN_RESULT`/`$RUN_REASON` immediately after. The risk is that if a subshell or coprocess were ever inserted between the `classify_case_result` call and the variable read, the globals would silently reflect stale state from the previous classification. Currently this is not exploitable, but the design is fragile: adding any backgrounded call between classify and consume (which is easy to do by accident in Bash) would corrupt case classification without any error. This is a latent TOCTOU-style data-race pattern on shared mutable globals.

  Location: `scripts/runtime-residual-smoke.sh`, lines 170-191 (`classify_case_result`), 251-252 and 289-291 (consumers).

  Severity: moderate

- **[C3]** `append_session_entry()` in `next-prompt-dir.sh` writes user-controlled data (session `title`, derived `id`, and `branch`) into a YAML file via AWK `print` statements without full YAML-safe escaping. `escape_yaml_dq()` (lines 145-150) only escapes backslash and double-quote. A title containing YAML-significant characters such as `:`, `#`, `|`, `>`, `[`, `]`, `{`, `}`, or a newline (possible if the shell variable is set from `$1` which is the raw CLI argument) will produce structurally invalid or semantically misinterpreted YAML. A newline in the title would be especially severe: AWK's `print` flushes a newline after each call, so `\n` in the title variable would inject a new YAML line, potentially breaking the document structure or injecting an arbitrary key-value pair into `cwf-state.yaml`. While `title` originates from a user-typed CLI argument, the script performs no length limit or character-class restriction on it.

  Location: `plugins/cwf/scripts/next-prompt-dir.sh`, lines 145-150 (`escape_yaml_dq`), lines 196-200 and 212-218 (AWK print blocks that inline the title, id, dir, branch).

  Severity: moderate

### Suggestions (non-blocking)

- **[S1]** `OUTPUT_DIR` and `attempt_log` file paths are constructed by concatenating `OUTPUT_DIR` with fixed suffixes (`/summary.tsv`, `/${case_id}-run${run_no}.log`, `.retry${attempt}`, `.fallback-hooks`). `case_id` is always one of `K46` or `S10` (controlled by the script itself), and `run_no` is a numeric counter, so path injection via those components is not currently possible. However, `OUTPUT_DIR` comes from the `--output-dir` flag or a date-derived default. If the directory is supplied by an external caller and contains `../` sequences, log files could be written outside the intended output directory. Consider resolving `OUTPUT_DIR` to an absolute canonical path (via `realpath` or `cd && pwd`) after validation, similar to the treatment already applied to `PLUGIN_DIR` (line 132).

  Location: `scripts/runtime-residual-smoke.sh`, lines 146-150.

- **[S2]** The `is_wait_input_log()` regex (line 165-167) is applied to arbitrary agent output stored in a log file using `grep -Eiq`. This is a heuristic classification based on natural-language pattern matching. A sufficiently crafted agent response that includes one of the wait-input trigger phrases (e.g., "would you like to provide") but is actually an error or adversarial output could cause a `FAIL/NO_OUTPUT` result to be reclassified as `PASS/WAIT_INPUT`. This is a logic-integrity concern rather than a direct security vulnerability, but in `strict` mode the misclassification would suppress a gate failure.

  Location: `scripts/runtime-residual-smoke.sh`, lines 163-168, 186-190.

- **[S3]** In `append_session_entry()`, the temporary file is created with `mktemp` (no template prefix, default `/tmp/tmp.XXXXXXXXXX`). After the AWK transform writes to `$tmp_file`, the file is moved over `$state_file` with `mv`. There is no file permission hardening on `$tmp_file` before the move: if `$state_file` is world-readable and the script runs as a shared-user daemon, the intermediate result in `/tmp` is readable to any process on the same host during the window between `mktemp` and `mv`. For a local developer tool this is low risk; for a multi-user CI host it could leak session metadata. Consider using `mktemp` with a prefix in the same directory as `$state_file` (e.g., `mktemp "${state_file}.tmp.XXXXXXXXXX"`) so the `mv` is atomic on the same filesystem and `/tmp` is never involved.

  Location: `plugins/cwf/scripts/next-prompt-dir.sh`, lines 185 and 234-235.

- **[S4]** `runtime-residual-smoke.sh` passes `--dangerously-skip-permissions` unconditionally to every Claude invocation (line 199). This flag disables the interactive permission confirmation that Claude normally requires before writing files or executing commands. For a smoke-test harness that only intends to observe agent behavior (not grant write access), this flag unnecessarily widens the attack surface. If an agent prompt triggers unexpected tool use, it can modify files without any gate. Consider whether a read-only or no-tools invocation mode is available, and document why `--dangerously-skip-permissions` is required if it genuinely is.

  Location: `scripts/runtime-residual-smoke.sh`, line 199.

- **[S5]** The `is_wait_input_log` grep in the mock (`runtime-residual-smoke-fixtures.sh`) emits fixed strings like `"WAIT_INPUT: setup requires user selection at phase 1.2."` to standard output and tests that the smoke script classifies them as `PASS/WAIT_INPUT`. This is correct for the mock, but the test does not cover the case where a real Claude binary emits an error that incidentally matches a wait-input phrase. The fixture test suite should include a negative case: a log that contains a wait-input phrase but represents a non-zero exit code, to verify that exit-code-based classification (`ERROR`) still takes priority over the phrase match. Currently the ordering in `classify_case_result` does give exit-code priority (lines 183-185 precede the `is_wait_input_log` check at lines 186-190), but there is no fixture that exercises this ordering.

  Location: `scripts/tests/runtime-residual-smoke-fixtures.sh`, combined with `scripts/runtime-residual-smoke.sh` lines 177-190.

### Behavioral Criteria Assessment

No specific success criteria were provided. Review based on general best practices per the review mandate.

### Provenance

```
source: REAL_EXECUTION
tool: claude-task
reviewer: Security
duration_ms: —
command: code-review diff 808189f^..HEAD -- plugins scripts
```

<!-- AGENT_COMPLETE -->
