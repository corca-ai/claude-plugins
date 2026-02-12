## Architecture Review (Implementation)

This review assesses the **implemented code** (not the plan) for the 5 static analysis scripts, 3 JSON schemas, and supporting configuration files. The prior plan-phase architecture review identified concerns [C1] (mixed-paradigm `scripts/` directory) and [C2] (`hooks.schema.json` asymmetry undocumented). This review evaluates whether those were addressed and identifies new concerns arising from the actual implementation.

### Concerns (blocking)

- **[C1]** **`doc-graph.mjs` lines 113-141: `await_import_fs()` indirection is unnecessary dead complexity.** The function `readdirRecursive` (line 113) calls `await_import_fs()` (line 137) which returns `{ readdirSync: readdirSyncImpl }` where `readdirSyncImpl` is imported at the top-level on line 141 as `import { readdirSync as readdirSyncImpl } from 'node:fs'`. This is a pointless indirection -- `readdirSync` is already available via the line 11 import (`import { readFileSync, existsSync, statSync } from 'node:fs'`), which does NOT include `readdirSync`, so it was imported separately on line 141. The `await_import_fs` wrapper function and aliased import should be replaced with a direct `import { readdirSync } from 'node:fs'` added to the existing line 11 import, and `readdirRecursive` should call `readdirSync` directly. This dead indirection looks like a remnant of an attempted dynamic import that was abandoned. It is confusing to maintainers and misleading (the `await_` prefix suggests async behavior, but the function is fully synchronous).
  - File: `/home/hwidong/codes/claude-plugins/scripts/doc-graph.mjs`, lines 113-141
  - Severity: moderate

- **[C2]** **`check-schemas.sh` line 128: yq stderr is redirected into the temp file.** The command `yq -o json "$data_path" > "$tmpfile" 2>&1` redirects both stdout and stderr into `$tmpfile`. If `yq` emits warnings or error messages to stderr, those text lines will be written into the JSON temp file, producing invalid JSON that `ajv-cli` will subsequently fail to parse. The `2>&1` should be removed so stderr from `yq` goes to the console, and only stdout (the JSON conversion) goes to the temp file. Alternatively, redirect stderr separately: `yq -o json "$data_path" > "$tmpfile" 2>/dev/null` or `2>&2`.
  - File: `/home/hwidong/codes/claude-plugins/scripts/check-schemas.sh`, line 128
  - Severity: moderate

- **[C3]** **`doc-graph.mjs` lines 276 and 330-344: duplicated JSON output block.** The `mode === 'json' || (mode === 'summary' && jsonOutput)` branch at line 276 and the `mode === 'summary'` branch with `if (jsonOutput)` at lines 330-344 produce identical JSON output objects. The same `output` construction (stats, adjacency, orphans, broken_refs, top_referenced) is duplicated verbatim. The `mode === 'json'` value is never actually set by any CLI flag -- no `--json` flag sets `mode = 'json'`; instead `--json` sets `jsonOutput = true`. So the `mode === 'json'` check on line 276 is dead code, and the entire first branch could be removed. The `summary` mode's JSON path (lines 331-344) already handles the case correctly. This structural duplication makes the output logic harder to reason about and introduces risk of divergence if one branch is updated but not the other.
  - File: `/home/hwidong/codes/claude-plugins/scripts/doc-graph.mjs`, lines 276-290 and 330-344
  - Severity: moderate

- **[C4]** **`check-links.sh` emits colored status messages even in `--json` mode.** Lines 79-82 print `"Running link check..."` and `"Mode: local only..."` using `echo -e` with color variables before lychee runs. When `--json` is active, lychee outputs JSON to stdout, but these status lines (lines 79-82) also go to stdout, prepending non-JSON text before the JSON payload. This produces unparseable output when piped to `jq`. The status messages should be sent to stderr when `--json` is active, or suppressed entirely. The same issue applies to the trailing "All links are valid." / "Broken links detected." messages on lines 86 and 90.
  - File: `/home/hwidong/codes/claude-plugins/scripts/check-links.sh`, lines 79-82, 86, 90
  - Severity: moderate

### Suggestions (non-blocking)

- **[S1]** **Prior plan-phase concern [C2] was addressed.** The `hooks.schema.json` now includes a `$comment` field (line 12: `"Unknown event names indicate drift -- the Claude hooks runtime only supports these 7 event types"`), which satisfies the plan-phase recommendation to make the `additionalProperties: false` rationale explicit. Well done.

- **[S2]** **Prior plan-phase concern [C1] remains valid but is inherently acceptable.** The `scripts/` directory is now a mixed-paradigm directory with `.sh`, `.mjs`, `.py`, `package.json`, `package-lock.json`, `node_modules/`, and `schemas/`. This was flagged in the plan review and remains cosmetically suboptimal but structurally functional. The `package.json` `"private": true` and `"type": "module"` declarations are correct and sufficient.

- **[S3]** **`find-duplicates.py` line 184: repo root discovery uses parent-of-parent heuristic.** The line `repo_root = Path(__file__).resolve().parent.parent` assumes `find-duplicates.py` lives exactly one directory below the repo root (i.e., in `scripts/`). The bash scripts use `git rev-parse --show-toplevel` which is location-independent. The Node.js script (`doc-graph.mjs`) also uses `git rev-parse --show-toplevel`. The Python script should use `subprocess.run(['git', 'rev-parse', '--show-toplevel'], ...)` for consistency and to avoid breaking if the script is ever moved or symlinked. This is a pattern consistency issue, not a correctness issue for the current layout.

- **[S4]** **`doc-graph.mjs` line 169: fragment-only anchor check `(url.startsWith('#') && !url.includes('/'))` has a logic gap.** A URL like `#some/path` (fragment containing a slash) would NOT be skipped by this check and would be processed as a relative path reference. After stripping the `#` on line 179, `url` becomes empty (the entire URL was the fragment), so the `if (!url) return` on line 187 catches it. However, the initial check's intent is unclear -- why would a fragment-only anchor contain a `/`? The `!url.includes('/')` condition appears to be guarding against something specific but is redundant given the later empty-string check. Simplifying to just `url.startsWith('#')` would be clearer.

- **[S5]** **`doc-churn.sh` line 88: `find` command does not exclude `prompt-logs/` early.** The script uses `find . -name "*.md" -type f ! -path "./.git/*" ! -path "*/node_modules/*"` and then filters `prompt-logs/` in a separate loop (lines 91-100). For a repo with 494 markdown files where most are in `prompt-logs/`, adding `! -path "./prompt-logs/*"` to the `find` command would avoid reading and then discarding hundreds of entries. The current approach works correctly but does unnecessary work. This is a performance suggestion, not a correctness issue.

- **[S6]** **`find-duplicates.py` line 190: `always_exclude` list is constructed but never used.** The variable `always_exclude = [repo_root / "node_modules", repo_root / ".git"]` is assigned but the actual filtering on lines 192-195 uses a different approach (checking `part in f.relative_to(repo_root).parts`). The `always_exclude` list is dead code and should be removed.

- **[S7]** **`check-schemas.sh` JSON output does not include validation error details.** When `--json` mode is active and a validation fails, the error details from `ajv-cli` are suppressed (line 140-141: `if [[ "$JSON_OUTPUT" != "true" ]]; then echo "$output" >&2`). The JSON output only contains `{"file":"...","status":"FAIL"}` with no error field. Adding an `"errors"` field to the JSON entry with the ajv output would make the `--json` mode more useful for programmatic consumption. The `provenance-check.sh` JSON output includes detailed per-file fields; `check-schemas.sh` should follow the same pattern.

- **[S8]** **`doc-churn.sh` lines 204-206: table formatting uses hardcoded column width of 30 for path.** The format `%-30s` truncates paths longer than 30 characters in the table display. Several real paths in this repo (e.g., `plugins/cwf/references/plan-protocol.md`) exceed 30 characters. Consider using a dynamic width based on the longest path, or removing the fixed-width padding entirely since the rest of the line uses labeled fields (`commits: N  lines: N  last: ISO`).

- **[S9]** **`provenance-check.sh` TTY color bug confirmed in implementation.** The prior correctness review (C2) and UX/DX review (C2) identified that `provenance-check.sh` line 57 only checks `[[ -t 1 ]]` without also checking `$JSON_OUTPUT`. All 5 new scripts correctly implement the combined guard `[[ -t 1 ]] && [[ "$JSON_OUTPUT" != "true" ]]`. This is an improvement over the existing convention. The existing `provenance-check.sh` should be fixed in a separate session to match.

- **[S10]** **Schema `cwf-state.schema.json` lines 44-46: `hooks` property restricts values to `boolean` only.** The `hooks` property uses `"additionalProperties": { "type": "boolean" }`, meaning every value under the `hooks` key in `cwf-state.yaml` must be a boolean. If the actual `cwf-state.yaml` `hooks` section contains nested objects or non-boolean values (e.g., configuration maps), this will fail. Verify the live `cwf-state.yaml` `hooks` section conforms.

### Behavioral Criteria Assessment

- [x] **check-links.sh validates internal links (exit 1 on broken, no prompt-logs)** -- The `--local` flag passes `--offline` to lychee (line 69). `.lychee.toml` excludes `prompt-logs/` via `exclude_path` (line 11-16). Exit code propagates from lychee (line 91). Evidence: `/home/hwidong/codes/claude-plugins/scripts/check-links.sh` lines 68-91, `/home/hwidong/codes/claude-plugins/.lychee.toml` lines 11-16.

- [x] **doc-graph.mjs detects orphans and handles anchor fragments** -- Orphan detection at lines 254-262 filters root-level exemptions and checks `inbound[f]` count. Anchor fragments stripped before `path.resolve` at lines 175-184 (`url.indexOf('#')` then `url.slice(0, hashIdx)`). Evidence: `/home/hwidong/codes/claude-plugins/scripts/doc-graph.mjs` lines 174-187, 254-262.

- [x] **find-duplicates.py reports near-duplicates (no self-matches)** -- Query-before-insert pattern at lines 229-246 (`candidates = lsh.query(mh)` before `lsh.insert(key, mh)`) inherently prevents self-matches and produces each pair exactly once. Evidence: `/home/hwidong/codes/claude-plugins/scripts/find-duplicates.py` lines 228-247.

- [x] **check-schemas.sh validates configs (per-file, no abort on failure)** -- The `failed=0` counter with `if validate_target "$pair"` loop (lines 154-179) prevents `set -e` from aborting on first failure. All three targets are processed regardless of individual results. Evidence: `/home/hwidong/codes/claude-plugins/scripts/check-schemas.sh` lines 149-179.

- [x] **doc-churn.sh reports staleness with classification** -- `classify_status()` function (lines 112-125) classifies into fresh/current/stale/archival/unknown based on epoch thresholds. Untracked files handled with empty-epoch guard (lines 159-164). Always exits 0 (line 227). Evidence: `/home/hwidong/codes/claude-plugins/scripts/doc-churn.sh` lines 111-125, 153-164, 227.

- [x] **All scripts respond to --help (exit 0)** -- Each script implements `-h|--help` argument handling: `check-links.sh` line 22-24, `doc-graph.mjs` lines 38-41, `find-duplicates.py` via argparse (line 15), `check-schemas.sh` lines 19-21, `doc-churn.sh` lines 27-29. All invoke `usage()` or equivalent and exit 0.

- [x] **All scripts exit 1 on missing deps** -- `check-links.sh` lines 55-61 (lychee), `doc-graph.mjs` lines 75-79 (node_modules), `find-duplicates.py` lines 29-37 (datasketch ImportError), `check-schemas.sh` lines 53-70 (yq + npx), `doc-churn.sh` has no external deps beyond git (always available in a git repo).

- [x] **Scripts follow existing conventions (TTY-guarded color, usage(), REPO_ROOT, --json)** -- All bash scripts use `set -euo pipefail`, `usage()` via sed, `REPO_ROOT=$(git rev-parse --show-toplevel ...)`, combined `[[ -t 1 ]] && [[ "$JSON_OUTPUT" != "true" ]]` color guard. Node.js script uses `process.stdout.isTTY && !jsonOutput`. Python script uses `sys.stdout.isatty() and not args.json`. All scripts handle unknown options with error + exit 1.

- [x] **Each script independently runnable** -- No script depends on another script. `doc-graph.mjs` depends on `scripts/node_modules/` (self-checks on line 75). `check-schemas.sh` depends on `scripts/schemas/*.json` (co-located, checked on line 114). `find-duplicates.py` depends on `datasketch` (checked on line 29). Each script documents its own setup requirements.

- [x] **JSON output valid and parseable** -- Node.js uses `JSON.stringify()` (doc-graph.mjs lines 290, 293, 313, 344). Python uses `json.dumps()` (find-duplicates.py line 254). Bash scripts use manual `printf` formatting with proper escaping (doc-churn.sh lines 192-195, check-schemas.sh lines 162-164, 172-174). Note: `check-links.sh` JSON validity depends on fixing [C4] above.

- [x] **No shared state between scripts** -- Scripts share no runtime state, temp files, or configuration. `.lychee.toml` is read only by `check-links.sh`. `scripts/schemas/` is read only by `check-schemas.sh`. `scripts/package.json` and `node_modules/` are used only by `doc-graph.mjs`.

- [x] **Exit code taxonomy: 0 = success, 1 = findings** -- `check-links.sh` exits with lychee's exit code (line 91). `doc-graph.mjs` exits 1 on orphans or broken refs (line 389). `find-duplicates.py` exits 1 on duplicates found (line 282). `check-schemas.sh` exits with `$failed` (line 197). `doc-churn.sh` always exits 0 (line 227, informational tool). `--help` exits 0 in all scripts.

### Pattern Consistency Matrix

| Convention | provenance-check.sh (existing) | check-links.sh | doc-graph.mjs | find-duplicates.py | check-schemas.sh | doc-churn.sh |
|---|---|---|---|---|---|---|
| `set -euo pipefail` | Yes | Yes | N/A (Node) | N/A (Python) | Yes | Yes |
| `usage()` from header | Yes (sed) | Yes (sed) | Yes (console.log) | Yes (argparse) | Yes (sed) | Yes (sed) |
| REPO_ROOT via git | Yes | Yes | Yes | No (parent.parent) [S3] | Yes | Yes |
| TTY color guard | `[[ -t 1 ]]` only | `[[ -t 1 ]] && !json` | `isTTY && !json` | `isatty() and !json` | `[[ -t 1 ]] && !json` | `[[ -t 1 ]] && !json` |
| Unknown option handler | Yes (exit 1) | Yes (exit 1) | Yes (exit 1) | Yes (argparse) | Yes (exit 1) | Yes (exit 1) |
| `--json` flag | Yes | Yes | Yes | Yes | Yes | Yes |
| Dep check + exit 1 | N/A | Yes | Yes | Yes | Yes | N/A |

### Provenance

```
source: FALLBACK
tool: claude-task-fallback
reviewer: Architecture
duration_ms: ---
command: git diff 34ebdf4..HEAD -- . ':!scripts/package-lock.json' ':!prompt-logs/' ':!cwf-state.yaml'
```

<!-- AGENT_COMPLETE -->
