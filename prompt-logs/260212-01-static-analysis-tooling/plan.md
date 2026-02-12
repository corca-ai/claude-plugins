# Static Analysis Tooling Integration

## Context

The claude-plugins repo has 494 markdown files (66 non-prompt-log), 9,567+ internal
cross-references, and no automated detection for dead links, duplicate content,
schema violations, orphan documents, or stale files. Existing validation is
limited to markdownlint (PostToolUse hook), shellcheck, verify-skill-links.sh
(SKILL.md only), and provenance-check.sh (staleness via sidecar files).

Prior conversation established tool selection and priorities. Research phase
confirmed API patterns, configuration options, and codebase conventions.

## Goal

Add 5 standalone analysis scripts + 1 config file + 3 JSON schemas + 1 vale stub
to `scripts/`, enabling automated detection of:

1. Dead links and broken anchors (lychee)
2. Document reference graph with orphan/impact analysis (remark)
3. Near-duplicate content blocks (datasketch MinHash/LSH)
4. Schema violations in YAML/JSON configs (ajv-cli + yq)
5. Document change frequency and staleness (git log)

## Scope

**In scope:**
- 5 new scripts in `scripts/`
- `scripts/package.json` for Node.js dependencies (pinned, with lockfile)
- `.lychee.toml` config at repo root
- 3 JSON schema files in `scripts/schemas/`
- `.vale.ini` stub + `.vale/styles/Vocab/CWF/` directory structure
- All scripts follow existing conventions (provenance-check.sh patterns)
- `.gitignore` update for `.lycheecache`

**Out of scope:**
- Hook integration (future session)
- CI/CD pipeline
- cwf:validate orchestrator skill
- Vale style rule authoring (stub only)
- Changes to existing scripts or hooks

## Commit Strategy

**Per step** — each step produces an independent, testable deliverable.

## Steps

### Step 1: lychee configuration + link checker wrapper

Create `.lychee.toml` at repo root:
- `include_fragments = true` for anchor validation
- `exclude_path`: `prompt-logs/`, `node_modules/`, `.git/`, `references/anthropic-skills-guide/`
- `include_extensions = ["md"]`
- `cache = true`, `max_cache_age = "2d"`
- `max_retries = 2`, `timeout = 20`, `max_concurrency = 8`
- `exclude` regex for known-placeholder URLs (localhost, example.com)
- `accept = [200, 204, 301, 302, 429]` (429 = rate-limited, not broken)

Add `.lycheecache` to `.gitignore` (lychee cache may contain resolved URLs).

Create `scripts/check-links.sh`:
- `#!/usr/bin/env bash`, `set -euo pipefail`
- `-h|--help` with usage function
- `--local` flag: skip external URLs, only check internal file refs + anchors
- `--json` flag: output JSON format
- Dependency check: `if ! command -v lychee &>/dev/null; then eprint "...install instructions..."; exit 1; fi`
  (exit 1 on missing dependency — matches `verify-skill-links.sh` and `redact-jsonl.sh` convention)
- Default: run `lychee` with `.lychee.toml` config on all non-excluded `.md` files
- Exit 0 = no broken links, exit 1 = broken links found
- Color output: `if [[ -t 1 ]] && [[ "$JSON_OUTPUT" != "true" ]]; then` (TTY-guarded AND --json-guarded; note: provenance-check.sh only checks TTY — new scripts must add the --json guard explicitly)

### Step 2: Node.js dependencies + Document reference graph (remark-based)

Create `scripts/package.json` with pinned dependencies:
```json
{
  "private": true,
  "type": "module",
  "dependencies": {
    "unified": "11.0.5",
    "remark-parse": "11.0.0",
    "unist-util-visit": "5.0.0"
  }
}
```
Run `npm install --prefix scripts/` to generate `scripts/package-lock.json`.
Add `scripts/node_modules/` to `.gitignore`. Commit `scripts/package.json` and `scripts/package-lock.json`.

Create `scripts/doc-graph.mjs`:
- `#!/usr/bin/env node`
- Standard ESM imports from `scripts/node_modules/` (resolved via `scripts/package.json`)
- Dependency check: verify `scripts/node_modules/` exists, if not print `Run: npm install --prefix scripts/` and exit 1
- Modes:
  - `--orphans`: list documents with zero inbound links (excluding prompt-logs/)
  - `--impact <file>`: given a changed file, list all documents that reference it (reverse lookup)
  - `--json`: output full adjacency list as JSON
  - Default (no flag): print human-readable summary (total docs, total links, orphan count, top-referenced files)
- Parse all `.md` files (excluding `prompt-logs/`, `node_modules/`)
- Extract `link` and `image` nodes via `unist-util-visit`
  - Filter: only process relative paths (skip `http://`, `https://`, `data:`, `#`-only anchors)
- **Anchor stripping before path resolution**: strip `#fragment` and `?query` from link URLs before `path.resolve`
  (e.g., `file.md#section` → resolve `file.md`, record `#section` separately for anchor-level analysis)
- Resolve relative paths against source file directory using `path.resolve`
- Build adjacency list: `{source: [resolved_targets]}`
- Detect: orphan docs (no inbound, excluding root-level files: `README.md`, `README.ko.md`, `AGENTS.md`, `CLAUDE.md`, `cwf-index.md`), broken internal refs (target doesn't exist)
- `-h|--help` support via `process.argv` parsing
- Color output with TTY detection (use `process.stdout.isTTY`, disable when `--json`)
- Exit 0 = clean, exit 1 = orphans or broken refs found

### Step 3: Near-duplicate detection (datasketch)

Create `scripts/find-duplicates.py`:
- `#!/usr/bin/env python3`
- Check `datasketch` availability: `try: import datasketch except ImportError: eprint("...install..."); sys.exit(1)`
- Print install instructions: `pip install --user datasketch` (use `--user` to avoid system Python contamination)
- Modes:
  - Default: scan non-prompt-log `.md` files, report duplicate block pairs above threshold
  - `--threshold N`: Jaccard similarity threshold (default: 0.7, raised from 0.5 to reduce false positives)
  - `--shingle-size N`: word-level shingle size (default: 3). Help text: "word window size for similarity comparison"
  - `--json`: JSON output
  - `--include-prompt-logs`: also scan prompt-logs/ (off by default)
- Processing pipeline:
  1. Find all target `.md` files via `pathlib.Path.rglob("*.md")` (no symlink following)
  2. For each file, split by any heading (`^#{1,6} `) into blocks (minimum 3 lines, minimum 20 words per block)
     - Content before the first heading becomes its own block (titled by filename)
     - Files without any headings become a single block
  3. For each block, generate word-level k-shingles (lowercased, stripped of punctuation)
  4. Create MinHash (num_perm=128) per block
  5. **Insert blocks incrementally**: for each block, query LSH first, then insert.
     This inherently avoids self-matches and produces each pair (A,B) exactly once.
  6. Output: sorted by similarity score descending
- Output format: `file_a:line → file_b:line (similarity: 0.XX) "block_header"`
- `-h|--help` with `__doc__` docstring
- `eprint()` function for stderr
- Color output with TTY detection (`sys.stdout.isatty()`, disable when `--json`)
- Exit 0 = no duplicates above threshold, exit 1 = duplicates found

### Step 4: JSON Schema validation (ajv-cli + yq)

Create 3 schema files in `scripts/schemas/`:

**`cwf-state.schema.json`**:
- Top-level required: `workflow`, `sessions`, `tools`, `hooks`, `live`
- `workflow`: required `current_stage` (enum), `started_at` (string), `stages` (object)
- `sessions`: array of session objects, each requiring `id`, `title`, `dir`, `branch`
- `session.id`: pattern `^[A-Za-z][A-Za-z0-9._-]*$` (matches real IDs: `S0`, `S4.5`, `S13.5-A`, `post-B3`, `S32-impl`)
- `tools`: object with string values
- `hooks`: object with boolean values
- `live`: required `session_id`, `dir`, `branch`, `phase`, `task`
- `expert_roster`: array of objects with required `name`, `domain`
- Use `$defs` for session and expert reusable definitions
- `additionalProperties: true` at all levels (top-level and nested objects) — rely on `required` for drift detection, allow organic field addition

**`plugin.schema.json`**:
- Required: `name`, `description`, `version`
- `name`: string, pattern `^[a-z][a-z0-9-]*$`
- `version`: string, pattern semver
- `author`: object with `name` (string), `url` (string, format uri)
- `repository`: string
- `additionalProperties: true`

**`hooks.schema.json`**:
- Required: `hooks` (object)
- `hooks` keys: use `patternProperties` with enum-like pattern matching valid event names: `^(SessionStart|UserPromptSubmit|Notification|PreToolUse|PostToolUse|Stop|SessionEnd)$`
- Each event value: array of hook-group objects
- Hook-group: required `matcher` (string), `hooks` (array)
- Hook entry: required `type` (enum: "command"), `command` (string), optional `async` (boolean)
- `additionalProperties: false` on the `hooks` object itself (unknown event names = drift)

Create `scripts/check-schemas.sh`:
- `#!/usr/bin/env bash`, `set -euo pipefail`
- `-h|--help` with usage function
- Dependency checks (exit 1 on missing, with install instructions):
  - `yq`: verify mikefarah/Go variant via `yq --version 2>&1 | grep -qE 'mikefarah|version v4'`
  - `npx`: verify available
- Pin ajv-cli version: use `npx ajv-cli@5 validate ...` (v5+ required for `--spec=draft2020`)
- Validate each target with **per-file error trapping** (do not let `set -e` abort on first failure):
  ```bash
  failed=0
  for pair in "${targets[@]}"; do
    if ! validate_target "$pair"; then
      failed=1
    fi
  done
  exit $failed
  ```
  1. `cwf-state.yaml` → convert via `yq -o json` to temp file (`mktemp`) → validate against `cwf-state.schema.json`
  2. `plugins/cwf/.claude-plugin/plugin.json` → validate directly against `plugin.schema.json`
  3. `plugins/cwf/hooks/hooks.json` → validate directly against `hooks.schema.json`
- Use `npx ajv-cli@5 validate -s <schema> -d <data> --spec=draft2020 --all-errors`
- YAML conversion: pipe via `yq -o json <file> > "$tmpfile"` (direct pipe to temp file, no variable interpolation)
- Collect all results, report pass/fail per file
- `--json`: JSON output (structured per-file pass/fail results)
- Unknown flags: print "Unknown option" and exit 1 (match provenance-check.sh convention)
- Color output: `if [[ -t 1 ]] && [[ "$JSON_OUTPUT" != "true" ]]; then` (combined TTY + --json guard)
- Exit 0 = all valid, exit 1 = any validation failure
- Clean up temp files on exit via `trap cleanup EXIT INT TERM` (signal-safe cleanup; EXIT alone may not fire on SIGINT/SIGTERM in bash <4.4)

### Step 5: Document churn analysis (git log)

Create `scripts/doc-churn.sh`:
- `#!/usr/bin/env bash`, `set -euo pipefail`
- `-h|--help` with usage function
- `--days N`: lookback period for commit counting (default: 30)
- `--stale-days N`: threshold for stale classification (default: 90). Files with last commit older than this are "stale"
- `--stale-only`: only show files classified as stale or archival
- `--json`: JSON output
- `--include-prompt-logs`: include prompt-logs/ (off by default)
- Analysis per file (use `git log --format=%at` for epoch-second timestamps to avoid timezone issues):
  - Last commit date (epoch seconds, convert to ISO 8601 for display)
  - Commit count in `--days` period
  - Lines changed in period (via `--numstat`)
  - Status classification based on last commit age:
    fresh (≤7d), current (≤30d), stale (≤`--stale-days`), archival (>`--stale-days`)
- Default output: sorted table with status color coding
  - GREEN = fresh/current, YELLOW = stale, RED = archival
- JSON output: array of `{path, last_modified, last_modified_epoch, commits, lines_changed, status}`
  (raw epoch included so callers can apply their own classification)
- Color output: `if [[ -t 1 ]] && [[ "$JSON_OUTPUT" != "true" ]]; then` (combined TTY + --json guard)
- **Untracked file guard**: Files matched by glob but with no git history (untracked, newly added) will produce empty output from `git log --format=%at`. Before arithmetic comparison, check for empty epoch: if `git log` returns empty, classify the file as `unknown` with epoch 0 and skip commit-count/lines-changed analysis. This prevents bash arithmetic errors under `set -e`.
- Exit 0 always (informational tool, not a linter)

### Step 6: Vale stub

Create `.vale.ini` at repo root:
- `StylesPath = .vale/styles`
- `MinAlertLevel = suggestion`
- `Vocab = CWF`
- `[*.md]` section with `BasedOnStyles = Vale`
- `[prompt-logs/**]` section to skip prompt-logs
- Comment explaining this is a stub for future activation

Create vocabulary directory (no custom style rules in this step — vocabulary only):
- `.vale/styles/Vocab/CWF/accept.txt`: common project terms (cwf, lychee, datasketch, etc.)
- `.vale/styles/Vocab/CWF/reject.txt`: empty file

### Step 7: Integration verification

Run each tool and verify:
1. `scripts/check-links.sh --local` — exits 0 if all internal links resolve; output includes file paths checked
2. `scripts/doc-graph.mjs --orphans` — exits 0 or 1; output lists orphan file paths (if any)
3. `scripts/find-duplicates.py --threshold 0.7` — exits 0 or 1; output lists block pairs with similarity scores (if any)
4. `scripts/check-schemas.sh` — validates all 3 config files; exits 0 with per-file PASS output
5. `scripts/doc-churn.sh --days 7` — exits 0; output includes table with status column showing fresh/current/stale
6. All scripts respond to `-h`/`--help` with usage text and exit 0
7. All scripts exit 1 with install instructions when required dependency is missing

## Success Criteria

### Behavioral (BDD)

```gherkin
Scenario: check-links.sh validates internal links
  Given .lychee.toml and scripts/check-links.sh exist
  And a markdown file docs/a.md contains [link](nonexistent.md)
  When check-links.sh --local is executed
  Then stdout contains "nonexistent.md" as a broken link
  And exit code is 1
  And no file under prompt-logs/ appears in the output

Scenario: check-links.sh succeeds on valid links
  Given all internal markdown links resolve to existing files
  When check-links.sh --local is executed
  Then exit code is 0

Scenario: doc-graph.mjs detects orphan documents
  Given scripts/doc-graph.mjs exists and npm install --prefix scripts/ has been run
  And a file plugins/cwf/references/orphan-example.md exists but is not referenced by any other file
  When doc-graph.mjs --orphans is executed
  Then stdout contains "plugins/cwf/references/orphan-example.md"
  And root-level files (README.md, README.ko.md, AGENTS.md, CLAUDE.md, cwf-index.md) do NOT appear as orphans
  And no file under prompt-logs/ appears in the output
  And exit code is 1

Scenario: doc-graph.mjs handles anchor fragments correctly
  Given docs/a.md contains [link](b.md#section-1)
  And docs/b.md exists
  When doc-graph.mjs --orphans is executed
  Then b.md has at least 1 inbound reference (the link from a.md)
  And the link is NOT reported as broken

Scenario: find-duplicates.py reports near-duplicate blocks
  Given datasketch is installed
  And two markdown files each contain a block with >90% word overlap (>20 words)
  When find-duplicates.py --threshold 0.7 is executed
  Then stdout contains both file paths with similarity >= 0.70
  And no self-matches appear (same file:same line)
  And exit code is 1

Scenario: find-duplicates.py includes content before first heading
  Given a file with no ## heading contains 50 words of prose
  When find-duplicates.py is executed
  Then that file's content is analyzed as a block (not silently discarded)

Scenario: check-schemas.sh validates all config files
  Given scripts/schemas/ contains 3 schema files and current config files are valid
  When check-schemas.sh is executed
  Then stdout contains "PASS" for each of cwf-state.yaml, plugin.json, hooks.json
  And exit code is 0

Scenario: check-schemas.sh reports per-file failures without aborting
  Given cwf-state.yaml is temporarily modified to have an invalid structure
  When check-schemas.sh is executed
  Then stdout contains "FAIL" for cwf-state.yaml
  And stdout ALSO contains results for plugin.json and hooks.json (not aborted)
  And exit code is 1

Scenario: check-schemas.sh accepts real session IDs
  Given cwf-state.yaml contains sessions with IDs "S4.5", "S13.5-A", "post-B3"
  When check-schemas.sh is executed
  Then cwf-state.yaml passes validation (pattern accepts these IDs)

Scenario: doc-churn.sh reports staleness per file
  Given scripts/doc-churn.sh exists
  When doc-churn.sh --days 30 is executed
  Then stdout contains a table with columns for path, last modified date, and status
  And each file is classified as fresh/current/stale/archival
  And exit code is 0

Scenario Outline: All scripts respond to --help
  When <script> --help is executed
  Then stdout contains "Usage"
  And exit code is 0
  Examples:
    | script                       |
    | scripts/check-links.sh       |
    | scripts/doc-graph.mjs        |
    | scripts/find-duplicates.py   |
    | scripts/check-schemas.sh     |
    | scripts/doc-churn.sh         |

Scenario Outline: All scripts exit 1 on missing dependencies
  Given <dependency> is not installed
  When <script> is executed
  Then stderr contains installation instructions for <dependency>
  And exit code is 1
  Examples:
    | script                     | dependency |
    | scripts/check-links.sh     | lychee     |
    | scripts/doc-graph.mjs      | node_modules (npm install) |
    | scripts/find-duplicates.py | datasketch |
    | scripts/check-schemas.sh   | yq         |
    | scripts/check-schemas.sh   | npx        |
```

### Qualitative

- Scripts follow existing conventions from provenance-check.sh (TTY-guarded color, usage(), REPO_ROOT via git rev-parse, --json disables color)
- Each script is independently runnable with clear setup steps (install dependency → run script)
- JSON output is valid and parseable by jq; Node/Python scripts use native JSON serializers (`JSON.stringify`, `json.dumps`)
- No shared state or dependencies between scripts
- Schemas use `additionalProperties: true` + `required` fields — strict enough to catch missing required fields (drift) but permissive for adding new fields (organic evolution)
- Exit code taxonomy: 0 = success/clean, 1 = findings or tool error, distinct from -h/--help (exit 0)

## Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `.lychee.toml` | Create | lychee link checker configuration |
| `.gitignore` | Edit | Add `.lycheecache`, `scripts/node_modules/` |
| `scripts/check-links.sh` | Create | Link checker wrapper |
| `scripts/package.json` | Create | Node.js dependencies for doc-graph.mjs (pinned) |
| `scripts/package-lock.json` | Create (generated) | npm lockfile for reproducible installs |
| `scripts/doc-graph.mjs` | Create | Document reference graph builder |
| `scripts/find-duplicates.py` | Create | Near-duplicate detection via MinHash/LSH |
| `scripts/schemas/cwf-state.schema.json` | Create | Schema for cwf-state.yaml |
| `scripts/schemas/plugin.schema.json` | Create | Schema for plugin.json |
| `scripts/schemas/hooks.schema.json` | Create | Schema for hooks.json |
| `scripts/check-schemas.sh` | Create | Schema validation wrapper |
| `scripts/doc-churn.sh` | Create | Git log churn analysis |
| `.vale.ini` | Create | Vale configuration stub |
| `.vale/styles/Vocab/CWF/accept.txt` | Create | Project vocabulary |
| `.vale/styles/Vocab/CWF/reject.txt` | Create | Empty reject list |

## Don't Touch

- `plugins/cwf/hooks/hooks.json` — no hook additions in this session
- `cwf-state.yaml` — only live section updates (no schema changes)
- Any existing scripts in `scripts/`
- `README.md`, `AGENTS.md` — no documentation updates
- `.markdownlint.json` — existing lint config untouched

## Deferred Actions

- [ ] Hook integration for check-links.sh and check-schemas.sh (future session)
- [ ] cwf:validate orchestrator skill combining all tools (future session)
- [ ] Vale style rules authoring based on datasketch duplicate analysis results
- [ ] CI/CD pipeline for automated validation on PR
