## UX/DX Review

### Concerns (blocking)

- **[C1]** **`--json` flag on `check-schemas.sh` is documented in the color section but never defined as a CLI flag.** The plan references "disable when `--json`" for color output, and other scripts (`check-links.sh`, `doc-graph.mjs`, `find-duplicates.py`, `doc-churn.sh`) all have `--json` as an explicit output mode. However, `check-schemas.sh` (Step 4) has no `--json` flag in its CLI specification -- it only mentions `--json` in the color output note. This is an inconsistency: a user who has learned the `--json` pattern from the other four scripts will expect it to work on `check-schemas.sh` too. Either add `--json` to produce structured output (schema, file, pass/fail, error detail per target), or explicitly document why it is excluded. **Severity: moderate**

- **[C2]** **`provenance-check.sh` color pattern has a latent bug the new scripts would inherit.** The plan says "use provenance-check.sh pattern" for TTY-guarded color, and also says "--json disables color." But `provenance-check.sh` itself only checks `[[ -t 1 ]]` -- it does NOT reset colors when `JSON_OUTPUT=true` (the comment says it does, but the code does not). If the new scripts replicate the existing code verbatim, `--json` output piped to a TTY will contain ANSI escape codes embedded inside JSON strings, producing invalid JSON. The plan should explicitly specify the color-disable logic as: `if [[ -t 1 ]] && [[ "$JSON_OUTPUT" != "true" ]]; then ...`, rather than saying "use provenance-check.sh pattern." **Severity: critical**

- **[C3]** **`check-schemas.sh` does not handle unknown flags.** The plan specifies only `-h|--help` and no other flags, but does not show a `*)` catch-all in the argument parser. All existing scripts (`provenance-check.sh` line 39-43, `verify-skill-links.sh` line 47) print "Unknown option" and exit on unrecognized flags. The plan should specify this behavior for `check-schemas.sh` (and confirm it for all other scripts). **Severity: moderate**

### Suggestions (non-blocking)

- **[S1]** **Naming: `doc-graph.mjs` and `doc-churn.sh` use `doc-` prefix while `check-links.sh` and `check-schemas.sh` use `check-` prefix, and `find-duplicates.py` uses `find-`.** The existing repo uses `check-session.sh`, `provenance-check.sh`, and `verify-skill-links.sh` -- three different verb conventions. The new scripts add three more verb prefixes. Consider aligning on a consistent prefix convention for analysis/validation scripts, or at minimum document the naming rationale (e.g., `check-*` = pass/fail linter, `doc-*` = informational analysis, `find-*` = search). This is not blocking because the heterogeneous naming already exists, but it will compound over time.

- **[S2]** **`find-duplicates.py` `--shingle-size` flag name is domain jargon.** The help text says "word window size for similarity comparison" which is good, but the flag itself (`--shingle-size`) may confuse users unfamiliar with MinHash terminology. Consider `--window-size` or `--word-window` as a more self-describing alias with `--shingle-size` kept as a synonym. The help text partially mitigates this.

- **[S3]** **`doc-churn.sh --stale-days` vs `--days` semantic overlap may confuse users.** `--days 30` controls the lookback for commit counting, while `--stale-days 90` controls staleness classification. A user running `--days 90 --stale-days 30` would get commits counted over 90 days but staleness classified at 30 days -- this is valid but counter-intuitive. Consider renaming `--days` to `--commits-since` or `--lookback` to make the distinction clearer.

- **[S4]** **Missing "no results" feedback.** Several scripts have implicit "empty output = no findings" behavior (e.g., `find-duplicates.py` exits 0 with no output when no duplicates found, `doc-graph.mjs --orphans` exits 0 with no output when no orphans found). Adding an explicit "No duplicates found above threshold 0.70" or "No orphan documents detected" message on success would improve UX, especially for first-time users who may wonder if the tool ran correctly. Existing `provenance-check.sh` prints a summary line ("N sidecar files checked, all fresh") on success.

- **[S5]** **`doc-graph.mjs --impact <file>` accepts a single file.** For batch workflows (e.g., checking impact of a multi-file commit), users would need to invoke the script repeatedly. Consider accepting multiple files or stdin. This is not blocking since single-file mode is a valid MVP.

- **[S6]** **`check-schemas.sh` hard-codes the 3 target files.** If a new config file is added to the repo in the future, the script must be modified. Consider a convention where schemas in `scripts/schemas/` are auto-discovered based on a naming pattern (e.g., `<name>.schema.json` validates `<name>.yaml` or `<name>.json` at a known path), or at minimum document where to add new targets. This is a maintainability concern, not a UX blocker.

- **[S7]** **`verify-skill-links.sh` uses exit 2 for usage/config errors, but the plan's exit taxonomy only defines 0 and 1.** The plan states "Exit code taxonomy: 0 = success/clean, 1 = findings or tool error." This is correct for simplicity, but means a missing dependency and a validation failure produce the same exit code. An operator running these in automation cannot distinguish "lychee is not installed" from "broken links were found." Consider reserving exit 2 for setup/dependency errors (matching `verify-skill-links.sh` precedent), or explicitly document why collapsing to 0/1 is preferred.

- **[S8]** **`--include-prompt-logs` flag on `find-duplicates.py` and `doc-churn.sh` would be more consistent as `--all` or `--no-exclude`.** The flag name hard-codes the directory name being toggled. If another directory gets excluded in the future, the flag name becomes misleading. A more generic name like `--all` (meaning "include everything, skip no directories") would be more future-proof. Minor point.

### Behavioral Criteria Assessment

- [x] All scripts provide `-h|--help` -- Plan explicitly specifies this for all 5 scripts, and the BDD Scenario Outline covers it with exit 0 verification. Evidence: Steps 1-5 each list `-h|--help`, BDD "Scenario Outline: All scripts respond to --help."
- [x] All scripts exit 1 on missing dependencies with install instructions -- Plan specifies dependency checks in each step with explicit install command text and exit 1. BDD Scenario Outline covers all 5 scripts + 2 deps for check-schemas.sh. Evidence: Steps 1-5 each have dependency check blocks; BDD "Scenario Outline: All scripts exit 1 on missing dependencies."
- [x] Exit 0 = clean, exit 1 = findings -- Explicitly stated per script (except doc-churn.sh which is always exit 0 as informational). Evidence: Each step ends with exit code specification.
- [x] Color output gated by TTY detection -- Specified in every step. Evidence: Steps 1-5 all reference TTY detection pattern.
- [ ] Color disabled in `--json` mode -- Mentioned in plan text but implementation detail is ambiguous (see C2). The provenance-check.sh pattern being referenced does not actually implement this. Evidence: provenance-check.sh lines 56-67 only check `[[ -t 1 ]]`, not `$JSON_OUTPUT`.
- [x] JSON output is valid and jq-parseable -- Stated in qualitative criteria. Evidence: "JSON output is valid and parseable by jq; Node/Python scripts use native JSON serializers."
- [x] Scripts are independently runnable -- Each script has its own dependency check and setup instructions. No shared state. Evidence: Qualitative criterion "No shared state or dependencies between scripts."
- [x] `prompt-logs/` excluded from analysis by default -- Specified in each relevant script (check-links.sh via .lychee.toml exclude_path, doc-graph.mjs parse exclusion, find-duplicates.py default exclusion, doc-churn.sh default exclusion). Evidence: Each step mentions prompt-logs exclusion.
- [x] Schemas use `additionalProperties: true` for organic evolution -- Explicitly stated for cwf-state.schema.json and plugin.schema.json. hooks.schema.json uses `additionalProperties: false` on the hooks object only (unknown event names are a real error). Evidence: Step 4 schema specifications.
- [x] Unknown flags produce an error and exit nonzero -- Present in provenance-check.sh reference but only implicitly assumed for new scripts (see C3). Partially satisfied: the plan says "follow existing conventions from provenance-check.sh" which includes this, but it is not explicit per-script.
- [x] Node dependencies are pinned with lockfile -- Explicitly specified in Step 2 with exact version numbers and `npm install` to generate lockfile. Evidence: Step 2 package.json with pinned versions.
- [x] BDD scenarios are concrete with observable assertions -- Scenarios include specific file paths, specific output strings ("PASS", "FAIL"), specific exit codes, and negative assertions ("no file under prompt-logs/ appears"). Evidence: All 12 scenarios + 2 Scenario Outlines use concrete assertions.

### Provenance

source: REAL_EXECUTION
tool: claude-task
reviewer: UX/DX
duration_ms: --
command: --
<!-- AGENT_COMPLETE -->
