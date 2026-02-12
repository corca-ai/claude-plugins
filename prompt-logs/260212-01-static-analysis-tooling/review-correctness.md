## Correctness Review

Reviewer analyzed the revised plan (`plan.md`) for the 5-tool static analysis integration against the current codebase state (`cwf-state.yaml`, `provenance-check.sh`, `hooks.json`, `plugin.json`). All session IDs, schema targets, and convention references were verified against live artifacts.

### Concerns (blocking)

- **[C1]** **Session ID regex excludes S-prefixed digits-only IDs without letter after prefix.** The pattern `^[A-Za-z][A-Za-z0-9._-]*$` correctly matches `S0`, `S4.5`, `S13.5-A`, `post-B3`, `S32-impl`. However, it also permits empty-after-first-letter IDs (a single character like `S`), which is semantically meaningless. More critically, the live section has `session_id: "S24"` — this does match the pattern, so no issue there. But the regex allows degenerate IDs like `.` or `-` after the first alpha, meaning `S-` or `S.` would pass. Consider whether the minimum length should be 2+ (`^[A-Za-z][A-Za-z0-9._-]+$`) or if single-letter IDs are intentionally allowed. **Severity: moderate** — functionally all real IDs pass, but the pattern is more permissive than documented intent suggests.

- **[C2]** **`doc-graph.mjs` anchor stripping regex may miss URL-encoded fragments.** The plan specifies stripping `#fragment` and `?query` before `path.resolve`. However, markdown links can contain URL-encoded characters (e.g., `file.md%23section` where `%23` is `#`). If a link uses percent-encoding, the fragment will not be stripped, and `path.resolve` will attempt to resolve a path containing `%23section`, producing a false "broken ref" report. Should specify decoding URL-encoded paths before anchor stripping, or at minimum document this as a known limitation. **Severity: moderate** — unlikely in this repo's current content but architecturally unsound for a general-purpose tool.

- **[C3]** **`check-schemas.sh` temp file cleanup race on signal interruption.** The plan specifies `trap cleanup EXIT` and `mktemp` for YAML-to-JSON conversion. However, if the script receives SIGINT or SIGTERM, the `EXIT` trap may not fire in all bash versions (bash <4.4 does not reliably call EXIT trap on signal). The trap should be `trap cleanup EXIT INT TERM` to ensure temp file cleanup under interruption. **Severity: moderate** — temp files in `/tmp` are benign but accumulate across runs.

- **[C4]** **`doc-churn.sh` epoch timestamp comparison uses arithmetic on potentially empty values.** If a file has never been committed (newly added, unstaged), `git log --format=%at` returns empty. The plan does not specify how to handle files with zero git history (e.g., untracked files matched by glob but not yet committed). Arithmetic comparison against an empty epoch will cause bash arithmetic errors under `set -e`. Need explicit guard: skip files with no git log output, or default epoch to 0 with classification as "unknown". **Severity: critical** — will crash with `set -e` on any untracked `.md` file in the working tree.

- **[C5]** **`find-duplicates.py` block splitting regex `^#{1,6} ` misses ATX headings without trailing space.** Per CommonMark spec, `# Heading` requires a space after `#`, but some files may use `#Heading` (no space) — this would be treated as non-heading content and merged with the preceding block. Additionally, setext-style headings (`Heading\n===` or `Heading\n---`) are not handled; those blocks will be merged with surrounding content. This is a design choice, but should be documented or the regex should include both forms. **Severity: moderate** — functional but may produce larger-than-expected blocks that dilute similarity scores.

### Suggestions (non-blocking)

- **[S1]** **MinHash `num_perm=128` is a reasonable default but consider documenting the accuracy tradeoff.** At 128 permutations, the expected error of Jaccard estimation is ~1/sqrt(128) = ~8.8%. For the default threshold of 0.7, this means pairs with true similarity between ~0.61 and ~0.79 may be misclassified. A `--num-perm` flag would allow users to increase precision for auditing runs at the cost of memory/time.

- **[S2]** **`doc-graph.mjs` orphan exclusion list is hardcoded.** The root-level exclusion set (`README.md`, `README.ko.md`, `AGENTS.md`, `CLAUDE.md`, `cwf-index.md`) should be documented as configurable or extracted to a constant, since new root-level files may be added over time. Consider a `--exclude-orphan` flag or reading from a config file.

- **[S3]** **`check-schemas.sh` yq version detection regex could be more precise.** The plan uses `yq --version 2>&1 | grep -qE 'mikefarah|version v4'`. The Go `yq` by mikefarah is now on v4.x, but future v5 would not match `version v4`. Consider using `mikefarah` alone as the discriminator, or `version v[4-9]` to future-proof.

- **[S4]** **`doc-churn.sh` should handle files with spaces in names.** The plan does not specify quoting discipline for file paths passed to `git log`. If any markdown file path contains spaces, unquoted expansion will break. Ensure `"$file"` quoting in all git log invocations and IFS handling in file enumeration loops.

- **[S5]** **`find-duplicates.py` minimum block filter (3 lines, 20 words) should be applied after shingle generation, not before.** If applied before, a block with exactly 20 words but fewer than 3 shingles (with shingle size 3, that means fewer than 18 unique word trigrams) may still be inserted into LSH with very few shingles, producing unreliable similarity. Consider the minimum in terms of unique shingles instead, or at least document the interaction.

- **[S6]** **`scripts/package.json` pins exact versions but `npm install` may resolve transitive dependencies to different versions.** The lockfile (`package-lock.json`) handles this, but the plan should explicitly state that `package-lock.json` must be committed (it does, line 88) and that `npm ci --prefix scripts/` should be preferred over `npm install` for reproducibility in instructions/documentation.

- **[S7]** **`.lychee.toml` `accept = [200, 204, 301, 302, 429]` treats 429 as non-broken.** While 429 (rate-limited) is transient, accepting it means the link's actual validity is unknown. A more correct approach would be to retry 429s (the plan sets `max_retries = 2`) but still report them if they persist. Verify that lychee's retry behavior applies before marking 429 as accepted — if `accept` prevents retries, this could mask permanently-rate-limited endpoints.

- **[S8]** **`doc-graph.mjs` filters `#`-only anchors but should also handle empty-string hrefs.** Some markdown tools produce `[text]()` with empty href. An empty string after `path.resolve` would resolve to the source file's directory, producing a false inbound link to a directory rather than a file.

- **[S9]** **`hooks.schema.json` uses `additionalProperties: false` on the hooks object.** This is correct per the plan's stated intent (unknown event names = drift). However, the matchers `Write|Edit` in the actual `hooks.json` (line 89) use pipe-separated patterns. The schema validates event *keys* (e.g., `PostToolUse`) not matcher values, so this is fine — but worth noting that matcher validation is out of scope and should not be confused with event name validation.

- **[S10]** **`doc-churn.sh` classification boundary conditions.** The plan defines fresh (<=7d), current (<=30d), stale (<=`--stale-days`), archival (>`--stale-days`). With default `--stale-days 90`, a file last modified exactly 30 days ago is "current" (<=30d). A file at 31 days would fall to "stale". But "stale" is defined as <=`--stale-days`, meaning a file at exactly 90 days is "stale", not "archival". These boundary semantics should be explicitly documented (inclusive vs exclusive bounds). If the user sets `--stale-days 30`, the "stale" category becomes empty (stale would be >30d and <=30d, which is impossible). Consider whether `--stale-days` should be a floor rather than a ceiling, or add validation that `--stale-days > 30`.

### Behavioral Criteria Assessment

- [x] **check-links.sh validates internal links and reports broken refs** — Plan specifies `--local` flag for internal-only mode, exit code 1 on broken links, file paths in output. BDD scenarios cover positive and negative cases.
- [x] **doc-graph.mjs detects orphan documents and handles anchors** — Plan specifies anchor stripping before `path.resolve` (addressing prior review C1), root-level file exclusion, prompt-logs exclusion. BDD scenarios cover anchor fragment case explicitly.
- [x] **find-duplicates.py avoids self-matches via query-before-insert** — Plan specifies incremental insert pattern (query LSH first, then insert), which inherently produces each pair (A,B) once and prevents self-matching. Addresses prior review concern.
- [x] **find-duplicates.py includes content before first heading** — Plan specifies "Content before the first heading becomes its own block (titled by filename)" and "Files without any headings become a single block". BDD scenario explicitly tests this.
- [x] **check-schemas.sh uses per-file error trapping** — Plan specifies `failed=0` counter with `if ! validate_target` pattern, preventing `set -e` from aborting on first failure. BDD scenario tests multi-file failure reporting.
- [x] **Session ID pattern matches all existing IDs** — Verified `^[A-Za-z][A-Za-z0-9._-]*$` against all 33 session IDs in `cwf-state.yaml`: `S0` through `S33`, `S4.5`, `S4.6`, `S5a`, `S5b`, `S6a`, `S6b`, `S7-prep`, `S11a`, `S11b`, `S13`, `S13.5-A`, `S13.5-B`, `S13.5-B2`, `S13.5-B3`, `post-B3`, `S29`, `S32-impl`. All match.
- [x] **doc-churn.sh uses epoch timestamps** — Plan specifies `git log --format=%at` for epoch-second timestamps, avoiding timezone ambiguity. ISO 8601 conversion for display only.
- [x] **All scripts follow provenance-check.sh conventions** — Plan references TTY-guarded color (`[[ -t 1 ]]`), `usage()` function, `REPO_ROOT` via `git rev-parse`, `--json` disabling color, `set -euo pipefail`, dependency check with exit 1. Verified against actual `provenance-check.sh` implementation.
- [ ] **doc-churn.sh handles untracked files gracefully** — No specification for files with zero git history. See C4.
- [ ] **check-schemas.sh temp cleanup is signal-safe** — Trap only covers EXIT, not INT/TERM. See C3.
- [x] **Block splitting includes all heading levels** — Plan specifies `^#{1,6} ` regex, covering h1 through h6. Prior review concern about h1-only splitting is resolved.
- [x] **Schema design uses additionalProperties: true with required fields** — Correct balance of drift detection (missing required fields) and organic evolution (new fields allowed). Exception: `hooks.schema.json` uses `additionalProperties: false` on the hooks object itself to catch unknown event names, which is appropriate.

### Provenance

source: REAL_EXECUTION
tool: claude-task
reviewer: Correctness

Files examined:
- `/home/hwidong/codes/claude-plugins/prompt-logs/260212-01-static-analysis-tooling/plan.md`
- `/home/hwidong/codes/claude-plugins/cwf-state.yaml`
- `/home/hwidong/codes/claude-plugins/scripts/provenance-check.sh`
- `/home/hwidong/codes/claude-plugins/plugins/cwf/hooks/hooks.json`
- `/home/hwidong/codes/claude-plugins/plugins/cwf/.claude-plugin/plugin.json`

<!-- AGENT_COMPLETE -->
