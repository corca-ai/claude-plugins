# Security Review — Static Analysis Tooling Plan (Revised)

**Reviewer:** Security
**Date:** 2026-02-12
**Artifact:** `prompt-logs/260212-01-static-analysis-tooling/plan.md`
**Verdict:** APPROVE with suggestions

---

## Security Review

### Concerns (blocking)

None.

The revised plan adequately addresses the security-relevant issues that would have been present in a naive implementation. Specifically:

1. **Dependency pinning is addressed.** `scripts/package.json` pins exact versions (`unified@11.0.5`, `remark-parse@11.0.0`, `unist-util-visit@5.0.0`) and commits a lockfile. `npx ajv-cli@5` pins the major version. These are reasonable controls for a developer tooling repo that is not a production service.

2. **Exit-on-missing-dependency is now exit 1.** The plan explicitly states `exit 1` for all missing-dependency checks, consistent with `provenance-check.sh` conventions and preventing silent pass-through when tools are absent.

3. **YAML-to-JSON conversion uses temp file via mktemp, not variable interpolation.** This eliminates shell injection risk from YAML content containing shell metacharacters. The plan also specifies `trap cleanup EXIT` for temp file cleanup, preventing data leakage via leftover temp files.

4. **Anchor stripping before path.resolve.** This prevents path traversal confusion where a fragment like `#../../etc/passwd` could theoretically influence path resolution.

5. **yq variant verification.** The plan checks for the mikefarah/Go variant specifically, preventing accidental use of the Python `yq` (which wraps `jq` and has different security properties and invocation patterns).

### Suggestions (non-blocking)

- **[S1]** `npx ajv-cli@5` pins the major version but allows minor/patch drift. Consider pinning to exact version (e.g., `npx ajv-cli@5.0.0`) for full reproducibility. The risk here is low since `npx` fetches from npm and ajv-cli is a well-maintained package, but exact pinning would match the discipline applied to `scripts/package.json`. Severity: low.

- **[S2]** The plan specifies `pip install --user datasketch` in the install instructions. There is no hash pinning or version pin for the Python dependency. Consider recommending a specific version (e.g., `pip install --user datasketch==1.6.5`) in the error message's install instructions. Without a version pin, a compromised PyPI package could be installed. The risk is mitigated by the fact that this is a developer tool run manually, not a CI dependency. Severity: low.

- **[S3]** `check-links.sh` accepts `429` (Too Many Requests) as a valid status code. This is reasonable to avoid false positives from rate limiting, but the `--json` output should ideally distinguish between "verified OK" (200/204) and "skipped due to rate limit" (429) so consumers can re-check those links later. This is more of a correctness concern than security, but opaque 429 acceptance could mask actual broken links on heavily-rate-limited hosts. Severity: informational.

- **[S4]** `find-duplicates.py` uses `pathlib.Path.rglob("*.md")` with "(no symlink following)" noted in the plan. Confirm that the implementation uses `rglob` with `follow_symlinks=False` (Python 3.13+) or validates that matched paths are not symlinks via `Path.is_symlink()`. Without this, a symlink pointing outside the repo could cause the script to read arbitrary files. The practical risk is low in a single-developer repo, but worth noting for defense in depth. Severity: low.

- **[S5]** The `.lychee.toml` configuration includes `cache = true` with a `.lycheecache` file. The plan correctly adds `.lycheecache` to `.gitignore`. Confirm that the cache file does not inadvertently store authentication tokens or cookies from external URL checks. Lychee's documentation indicates the cache stores URL-to-status mappings only (no credentials), but this should be verified during implementation. Severity: informational.

- **[S6]** `doc-churn.sh` uses `git log --format=%at` which is safe from injection since `%at` produces only numeric epoch timestamps. The plan does not mention sanitizing file paths in the JSON output. File paths from `git ls-files` are generally safe, but paths containing double quotes or backslashes should be JSON-escaped (the existing `provenance-check.sh` does this manually at lines 178-181). Ensure the implementation follows the same JSON-escaping pattern or uses `jq` for output construction. Severity: low.

- **[S7]** The `hooks.schema.json` uses `additionalProperties: false` on the hooks object, which is the correct strictness level for event-name validation. However, the `patternProperties` pattern `^(SessionStart|UserPromptSubmit|Notification|PreToolUse|PostToolUse|Stop|SessionEnd)$` should be verified against the actual hooks.json to ensure completeness. I confirmed the current hooks.json uses exactly these 7 event names, so the schema is aligned. No action needed -- just flagging that future hook event additions will require a schema update. Severity: informational.

### Behavioral Criteria Assessment

- [x] **Missing-dependency exits non-zero** — Plan explicitly specifies `exit 1` for all 5 scripts on missing dependencies (lines 67-68, 93, 115-116, 174-177, and by convention for doc-churn.sh which has no external deps).
- [x] **No secrets in committed files** — No `.env`, credentials, or tokens are created or read. `.lycheecache` (which could theoretically contain resolved URLs) is gitignored. `scripts/node_modules/` is gitignored.
- [x] **Temp file hygiene** — `check-schemas.sh` uses `mktemp` for YAML-to-JSON conversion with `trap cleanup EXIT` for guaranteed cleanup.
- [x] **No eval/exec of user-controlled input** — No `eval`, `source`, or dynamic command construction from file content. Shell scripts use `set -euo pipefail`. Python script uses `import` only for known packages.
- [x] **No network exposure in default mode** — `check-links.sh` has a `--local` flag for offline-only operation. All other scripts are purely local (filesystem + git). No scripts start servers or listen on ports.
- [x] **Path traversal mitigated** — `doc-graph.mjs` strips anchors/queries before `path.resolve`. `find-duplicates.py` uses `rglob` with documented no-symlink-following.
- [x] **Dependency versions pinned** — Node.js deps pinned exactly in `package.json` with lockfile. `npx ajv-cli@5` pinned to major. Python `datasketch` is the only unpinned external dependency (flagged in S2).
- [x] **yq variant verified** — Plan checks for mikefarah/Go variant explicitly before use, preventing accidental use of incompatible Python yq.
- [x] **JSON output uses proper serializers** — Plan specifies `JSON.stringify` for Node.js, `json.dumps` for Python, and manual escaping (following provenance-check.sh pattern) for bash. No raw string concatenation of untrusted data into JSON.
- [x] **No shell injection vectors** — YAML content is written to temp files, not interpolated into shell variables. `npx` invocations use static package names (no variable expansion). File paths from `git`/`find` are quoted.

### Provenance

```
source: REAL_EXECUTION
tool: claude-task
reviewer: Security
duration_ms: —
command: —
```

<!-- AGENT_COMPLETE -->
