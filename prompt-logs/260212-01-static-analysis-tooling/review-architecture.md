## Architecture Review

### Concerns (blocking)

- **[C1]** `scripts/package.json` introduces a Node.js package ecosystem rooted inside `scripts/`, which currently contains only shell scripts and a `codex/` subdirectory. The `node_modules/` directory, `package.json`, and `package-lock.json` will coexist at the same level as `.sh` files, creating a mixed-paradigm directory. Additionally, running `npm install --prefix scripts/` will place `node_modules/` inside `scripts/`, meaning any Node.js ESM resolution (`import ... from "unified"`) works only if the script is executed from within `scripts/` or if the runtime resolves the `package.json` via the file's directory. The plan does not specify how `doc-graph.mjs` locates its dependencies -- it says "resolved via `scripts/package.json`" but Node.js ESM resolution walks up from the script's own directory, so this works only if `doc-graph.mjs` lives in `scripts/` (which it does). This is fine mechanically, but the plan should acknowledge that any future `.mjs` script placed elsewhere would not share these deps. Not blocking on correctness but borderline on structural clarity. **Severity: moderate**

- **[C2]** `hooks.schema.json` uses `additionalProperties: false` on the `hooks` object (line 169 of plan) to catch unknown event names, while the plan's stated philosophy everywhere else is `additionalProperties: true` for organic evolution (lines 153, 161, 350). This asymmetry is intentional and justified (unknown event names are genuinely invalid per the Claude hooks runtime), but the plan does not document this design rationale inline in the schema description or in the plan text beyond a parenthetical. If a future contributor adds a new Claude event type, the schema will reject it until updated -- this is the desired drift-detection behavior, but it should be made explicit in a schema `description` field or `$comment`. **Severity: moderate**

### Suggestions (non-blocking)

- **[S1]** The `scripts/` directory currently has a flat layout for top-level scripts (`check-session.sh`, `provenance-check.sh`, etc.) and a `codex/` subdirectory for Codex-specific tooling. Adding 5 new scripts (3 shell, 1 Node.js, 1 Python) plus `package.json`/`package-lock.json` plus a `schemas/` subdirectory will nearly triple the file count in `scripts/`. Consider grouping the new analysis scripts into a subdirectory (e.g., `scripts/analysis/` or `scripts/lint/`) to preserve the current lean top-level and keep the "operational scripts" (install, update, check-session, provenance-check, next-prompt-dir) visually distinct from "analysis/validation scripts." This is cosmetic and non-blocking.

- **[S2]** `doc-graph.mjs` is the only Node.js script in the repo. If future scripts need the same dependencies, the `scripts/package.json` approach works well. However, the plan does not specify a `"bin"` or `"scripts"` field in `package.json`. Adding a `"scripts": { "doc-graph": "node doc-graph.mjs" }` entry would let users run `npm run --prefix scripts doc-graph` as an alternative invocation, aligning with npm conventions. Low priority.

- **[S3]** The plan specifies `check-schemas.sh` will use `npx ajv-cli@5 validate ...`, which downloads `ajv-cli` on first run if not cached. This introduces a network dependency at validation time that none of the existing scripts have (existing scripts either use locally installed tools or fail fast). Consider adding `ajv-cli` to `scripts/package.json` dependencies instead, so `npm install --prefix scripts/` handles it once, and the script invokes `./scripts/node_modules/.bin/ajv validate ...` directly. This would make `check-schemas.sh` consistent with `doc-graph.mjs`'s approach (explicit local deps) and remove the implicit `npx` network fetch. Also eliminates the separate `npx` dependency check.

- **[S4]** `find-duplicates.py` uses `pip install --user datasketch` in its install instructions. The project has no `requirements.txt` or Python dependency manifest. For symmetry with the `scripts/package.json` approach for Node.js, consider adding a `scripts/requirements.txt` (even if it contains only `datasketch`). This would give a single `pip install -r scripts/requirements.txt` command and parallel the Node.js dependency management story.

- **[S5]** The plan's dependency check pattern for bash scripts (`command -v ... &>/dev/null`) matches `redact-jsonl.sh` and existing conventions well. However, `check-schemas.sh` has a more complex check for yq (`yq --version 2>&1 | grep -qE 'mikefarah|version v4'`) which is necessary to distinguish Go yq from Python yq. This is good practice, but the plan should note that this check may fail on yq v3 (some older distributions). The plan says "v4" but the grep pattern `mikefarah|version v4` would also match `mikefarah` regardless of version. This is probably fine for practical purposes.

- **[S6]** The `cwf-state.schema.json` session ID pattern `^[A-Za-z][A-Za-z0-9._-]*$` is well-researched against real IDs (`S0`, `S4.5`, `S13.5-A`, `post-B3`, `S32-impl`). Worth noting that this pattern also allows IDs like `a`, `Z`, or `A-----------` which are syntactically valid but semantically unlikely. Not a concern -- overly strict patterns cause more pain than loose ones in this context.

- **[S7]** Color output convention: The plan correctly identifies `provenance-check.sh` as the canonical TTY-detection pattern (`if [[ -t 1 ]]; then`) and explicitly states it should NOT use the `check-session.sh` pattern (which unconditionally sets color variables). This is a good convention call. The plan should ensure `--json` mode also disables color even when stdout is a TTY -- this is stated in the plan for `check-links.sh` (line 71: "also disable color when `--json`") but should be verified as consistently stated for all 5 scripts. Reviewing: `check-links.sh` (stated), `doc-graph.mjs` (stated: "disable when `--json`"), `find-duplicates.py` (stated: "disable when `--json`"), `check-schemas.sh` (stated: "disable when `--json`"), `doc-churn.sh` (stated: "disable when `--json`"). All five are covered.

- **[S8]** The `.vale.ini` stub with `[prompt-logs/**]` exclusion uses a glob pattern. Vale's ignore syntax for sections is `[*.md]` style -- to ignore an entire directory, the correct Vale approach is listing it under `IgnoredDirectories` or using a `BlockIgnores` / `TokenIgnores` pattern. The plan should verify that `[prompt-logs/**]` is valid Vale section syntax for exclusion, or use `IgnoredDirectories = prompt-logs` in the global section instead.

### Behavioral Criteria Assessment

- [x] **Structural fit within existing architecture** -- New scripts follow the `scripts/` flat layout convention. `schemas/` subdirectory is a natural extension. `.lychee.toml` and `.vale.ini` at repo root follow the pattern of `.markdownlint.json` (existing root-level tool config). No hook/plugin modifications.

- [x] **Pattern consistency with conventions** -- `set -euo pipefail`, `usage()` function, `REPO_ROOT=$(git rev-parse --show-toplevel ...)`, TTY-guarded color from `provenance-check.sh`, exit 1 on missing deps from `verify-skill-links.sh`/`redact-jsonl.sh`, `--json` flag pattern from `provenance-check.sh`. All verified against actual file contents.

- [x] **Coupling analysis** -- Each script is independently runnable with zero shared state between scripts (plan line 349: "No shared state or dependencies between scripts"). `doc-graph.mjs` depends on `scripts/package.json` + `node_modules/` but self-checks. `check-schemas.sh` depends on `scripts/schemas/*.json` but these are co-located. No script modifies any existing file except `.gitignore` (append-only). Coupling is appropriately minimal.

- [x] **Evolution path / extension points** -- `additionalProperties: true` on schemas allows organic field growth. Deferred actions are clearly scoped (hook integration, CI, orchestrator skill, Vale rules). `--json` output on all scripts enables future machine consumption (hooks, CI, orchestrator). The commit-per-step strategy allows partial delivery.

- [x] **Convention adherence: file layout** -- New files placed in `scripts/` (scripts), `scripts/schemas/` (schemas), repo root (tool configs). Matches existing layout patterns. No files placed in unexpected locations.

- [x] **Convention adherence: naming** -- `check-links.sh`, `check-schemas.sh`, `doc-churn.sh` follow `verb-noun.sh` pattern (cf. `check-session.sh`, `provenance-check.sh`). `doc-graph.mjs` uses `.mjs` extension for ESM (standard Node.js convention). `find-duplicates.py` uses `.py` extension (standard Python). Schema files use `.schema.json` suffix (JSON Schema convention).

- [x] **Exit code taxonomy** -- Consistent with existing: 0 = clean/success, 1 = findings/errors, --help = exit 0. `doc-churn.sh` correctly exits 0 always (informational tool). `verify-skill-links.sh` uses exit 2 for usage errors but the new scripts use exit 1 for both findings and dependency errors -- this is a minor inconsistency but matches `provenance-check.sh` and `redact-jsonl.sh` conventions (exit 1 for all errors).

- [x] **Scope boundaries respected** -- "Don't Touch" list is explicit and reasonable. No changes to existing hooks, scripts, or configuration files (except `.gitignore` append). "Out of scope" correctly defers hook integration, CI, and orchestration.

- [ ] **Per-file error trapping in check-schemas.sh** -- The plan specifies a `failed=0` + loop pattern that prevents `set -e` from aborting on first validation failure (plan lines 178-187). This is good but has a subtle issue: `set -e` with a function called in an `if` context disables `set -e` inside the function. If `validate_target` internally uses commands that should fail-fast on unexpected errors (e.g., `yq` segfault vs. validation failure), those errors would be silently swallowed. The plan should consider distinguishing "expected validation failure" (exit 1 from ajv) from "unexpected tool crash" (exit 2+ or signal) inside `validate_target`. Not blocking, but worth noting for implementation.

### Provenance

source: REAL_EXECUTION
tool: claude-task
reviewer: Architecture
duration_ms: ---
command: ---

<!-- AGENT_COMPLETE -->
