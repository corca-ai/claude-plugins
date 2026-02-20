## Correctness Review

### Concerns (blocking)

- **[C1]** Off-by-one in retry loop: `run_case()` retries when `attempt <= max_retries`, but `attempt` starts at 1 (the first real attempt). With default `K46_TIMEOUT_RETRIES=1`, the loop will execute attempt 1 (initial), see the failure matches `retry_reason`, check `1 <= 1` (true), increment to attempt 2 (first retry), run again, and if it still fails, check `2 <= 1` (false) and break. This means `K46_TIMEOUT_RETRIES=1` gives 1 retry (2 total attempts), which matches the documentation "Retry count...before recording failure." However, `K46_TIMEOUT_RETRIES=0` gives 0 retries but still runs the initial attempt, which is correct. The naming is slightly misleading: "retry count" of 1 means 1 retry = 2 total invocations, which is consistent. **Upon closer analysis, this is correct but warrants caution** -- the variable name says "retries" and the loop logic delivers exactly that number of retries. No blocking issue.
  Severity: withdrawn (reclassified to S3 suggestion)

- **[C2]** `classify_case_result` uses global variables (`RUN_RESULT`, `RUN_REASON`) as return values. In `run_case()`, this function is called from within a `while :; do ... done` loop, and also separately for the fallback path. The global mutation pattern is fragile and could silently break if `classify_case_result` were ever called in a subshell or pipe. Currently the calls are all in the main shell, so this works, but the function returns data via side-effect globals without any documentation of this contract.
  Severity: moderate
  File: `/home/hwidong/codes/claude-plugins/scripts/runtime-residual-smoke.sh`, lines 170-191

- **[C3]** Missing `$2` validation on `shift 2` argument parsing: When options like `--k46-timeout-retries` or `--s10-no-output-retries` are passed without a following argument (e.g., script is called with `--k46-timeout-retries` as the last argument), `${2:-}` produces an empty string, and `shift 2` may fail under `set -e` because there is only one argument to shift. This would produce an unhelpful error. The same pattern exists for all other `shift 2` options in the argument parser, but those were pre-existing. The new retry options inherit this pre-existing bug.
  Severity: moderate
  File: `/home/hwidong/codes/claude-plugins/scripts/runtime-residual-smoke.sh`, lines 72-73 and 84-85

- **[C4]** AWK `print` with string concatenation in `append_session_entry()` produces unintended whitespace. The awk `print "  - id: \"" sid "\""` statement concatenates fields. In awk, `print expr1, expr2` inserts OFS (space by default) between arguments, but `print expr1 expr2` concatenates. The code uses `print "  - id: \"" sid "\""` which is actually three arguments separated by spaces to `print`, so awk will insert OFS (a space) between them, producing `  - id: " S260214-04 "` instead of the intended `  - id: "S260214-04"`. The existing test `grep -Fq "dir: \"$expected_plugin_bootstrap_inline\""` would appear to pass because the test fixture may be matching loosely. **This is a correctness bug** -- the YAML output will have spurious spaces inside the quoted values (e.g., `" value "` instead of `"value"`).
  Severity: critical
  File: `/home/hwidong/codes/claude-plugins/plugins/cwf/scripts/next-prompt-dir.sh`, lines 196-200 and 213-217 (within the awk block in `append_session_entry`)

- **[C5]** S10 fallback prompt masking: When `run_case` encounters `S10` + `NO_OUTPUT` after retries, it falls back to `cwf:setup --hooks`. If the fallback succeeds, the result is recorded as `PASS`/`WAIT_INPUT` and the fallback log overwrites the original log file. However, the `S10_NO_OUTPUT_COUNT` counter on line 332 is incremented based on the final recorded reason. Since the fallback changes `reason` to `WAIT_INPUT`, the NO_OUTPUT count will be 0 even though the original prompt failed. This is arguably the intended behavior (masking the transient failure), but it means the strict-mode gate at line 346 (`S10_NO_OUTPUT_COUNT > 0`) will never trigger for cases that were recovered by the fallback, which undermines the strict gate's ability to detect the underlying residual.
  Severity: moderate
  File: `/home/hwidong/codes/claude-plugins/scripts/runtime-residual-smoke.sh`, lines 268-301 and 346

### Suggestions (non-blocking)

- **[S1]** The `is_wait_input_log` function (line 163-168) uses a very long regex with many alternations. The regex is case-insensitive (`-i`) and includes patterns like `would you like me to` which could false-positive on many outputs. Consider narrowing the regex to match only the structured `WAIT_INPUT:` sentinel pattern if that is the canonical signal, or at minimum add a comment documenting that false-positive tolerance is intentional for this heuristic.
  File: `/home/hwidong/codes/claude-plugins/scripts/runtime-residual-smoke.sh`, lines 163-168

- **[S2]** The `next-prompt-dir.sh` regex for detecting the `sessions:` line was changed from `/^sessions:[[:space:]]*$/` to `/^sessions:[[:space:]]*(#.*)?$/` (allowing trailing comments). The corresponding `grep -Eq` on line 272 uses the pattern `'^sessions:[[:space:]]*($|\[[[:space:]]*\][[:space:]]*)(#.*)?$'`. These two regex patterns use different dialects (awk ERE vs grep ERE) but appear functionally consistent. However, the `session_entry_exists` function on line 158 only matches `^sessions:[[:space:]]*(#.*)?$` (the block-style form) and does **not** handle the inline `sessions: []` form. If `session_entry_exists` is called with a state file that still has `sessions: []`, the awk block will never set `in_sessions=1`, and the function will always report "not found." The `append_session_entry` function handles the inline form by expanding it, but `session_entry_exists` is called before `append_session_entry` in `bootstrap_session` (line 276), so this is safe in practice (the grep on line 272 matches inline `[]` and `append_session_entry` expands it). Still, the asymmetry between the two awk patterns is a maintenance hazard.
  File: `/home/hwidong/codes/claude-plugins/plugins/cwf/scripts/next-prompt-dir.sh`, lines 158 and 192

- **[S3]** The retry log naming convention uses `.retry2`, `.retry3`, etc. (where `attempt` starts at 2 for the first retry). This means the first attempt's log is the base `${case_id}-run${run_no}.log` and the first retry is `.retry2`. This is internally consistent but the numbering gap (no `.retry1`) could confuse operators reading the artifact directory. Consider starting retry numbering at 1 or adding a comment.
  File: `/home/hwidong/codes/claude-plugins/scripts/runtime-residual-smoke.sh`, line 236

- **[S4]** The `invoke_prompt` function runs `timeout` inside a subshell `(cd ... && timeout ...)`. The parentheses create a subshell. If the `timeout` command sends SIGTERM, it will terminate the `claude` process, but the subshell's exit code propagation is correct (the `timeout` exit code 124 propagates). No issue here, just noting the subshell is necessary for the `cd` and the `$?` capture works correctly outside via `set +e`.
  File: `/home/hwidong/codes/claude-plugins/scripts/runtime-residual-smoke.sh`, lines 193-201

- **[S5]** In the fixture test `runtime-residual-smoke-fixtures.sh`, the mock claude script at line 109 handles `cwf:setup --hooks` in the same branch as `cwf:setup`. However, the mock uses `state_file` to track `run_no` across both prompts. When the smoke script falls back from `cwf:setup` (which incremented `run_no`) to `cwf:setup --hooks`, the fallback will increment `run_no` again. This means the mock's state counter is shared across the primary and fallback attempts, which could affect the `run_no == 2` NO_OUTPUT trigger if the fallback happens to be the second call. The current test setup works because the observe mode's S10 runs 1-3 share the counter and run 2 is the one that gets NO_OUTPUT, triggers retry (which increments to 3), then fallback (which increments to 4). This coupling between mock state and retry logic is fragile.
  File: `/home/hwidong/codes/claude-plugins/scripts/tests/runtime-residual-smoke-fixtures.sh`, lines 109-136

- **[S6]** The HITL SKILL.md changes add `context_refs` as a required field for every chunk in `queue.json`, but there is no migration path documented for existing HITL sessions that were created before this change. If an existing `queue.json` lacks `context_refs`, the new "never present a chunk without at least one related context reference" invariant (SKILL.md line ~245) could cause a runtime failure or policy violation during `--resume`.
  File: `/home/hwidong/codes/claude-plugins/plugins/cwf/skills/hitl/SKILL.md`, new line at ~5 ("Every chunk review must be presented as: Primary Chunk + Related Context + Causal Lens")

- **[S7]** The `cwf-state.yaml` additions (lines 22-63 of the diff) add 6 new session entries. Sessions S260220-01 and S260220-03 and S260220-06 all share the same title `"retro-light"`, while S260220-02 through S260220-05 have unique suffixed titles. The duplicate titles are not a bug per se (IDs are unique), but could hamper human disambiguation when scanning the state file.
  File: `/home/hwidong/codes/claude-plugins/.cwf/cwf-state.yaml`

### Behavioral Criteria Assessment

No specific success criteria were provided. The review assessed the changes against general best practices for shell script correctness, edge-case handling, and test coverage fidelity:

1. **Retry logic**: The retry mechanism in `runtime-residual-smoke.sh` is sound in structure. The retry count semantics are internally consistent (N retries = N+1 total attempts). The fallback prompt mechanism for S10 NO_OUTPUT recovery is a reasonable hardening measure.

2. **YAML manipulation**: The `next-prompt-dir.sh` changes to handle inline `sessions: []` format are a meaningful improvement, but the awk print concatenation bug (C4) introduces malformed YAML output that could break downstream consumers.

3. **Test coverage**: New fixture tests cover the inline sessions expansion and the retry/fallback behavior. The tests are structurally sound but rely on shared mock state counters that create implicit coupling between test scenarios.

4. **HITL skill changes**: The requirement for `Related Context + Causal Lens` on every chunk is a design-level improvement. The state model additions (`context_refs`, `last_presented_chunk_id`, etc.) are well-structured. No backward compatibility story is documented.

5. **Setup routing**: The namespace routing guard change from prefix-only to token-match-anywhere is a targeted fix for a known misrouting issue. The implementation is documentation-only (SKILL.md), so correctness depends on the LLM following the instruction.

### Provenance

```
source: FALLBACK
tool: claude-task-fallback
reviewer: Correctness
duration_ms: --
command: --
```

<!-- AGENT_COMPLETE -->
