## Architecture Review

### Concerns (blocking)

- **[C1] Duplicated YAML Parsing Logic**
  `workflow-gate.sh` (lines 75–128) reimplements YAML scalar and list extraction using `awk`. These implementations are nearly identical to the new functions in `cwf-live-state.sh` (`cwf_live_extract_scalar_from_file`, `cwf_live_extract_list_from_file`). Having two sets of regex-based YAML parsers increases the risk of subtle bugs and synchronization issues if the `cwf-state.yaml` format evolves.
  Severity: moderate

- **[C2] Broken Argument Splitting in `check-deletion-safety.sh`**
  The `extract_deleted_from_bash` function (line 103) uses `IFS=' ' read -r -a argv <<< "$segment"` to parse command arguments. This will incorrectly split filenames containing spaces (e.g., `rm "my document.md"` becomes `my` and `document.md"`), causing the safety check to search for the wrong strings and potentially miss the deletion target.
  Severity: moderate

- **[C3] High Coupling between State and Validation**
  `cwf-live-state.sh` (line 289) hardcodes the list of valid gate names in `cwf_live_validate_gate_name`. This creates a maintenance bottleneck: any change to the workflow stages in `run/SKILL.md` now requires a synchronized update to this shell script.
  Severity: moderate

### Suggestions (non-blocking)

- **[S1] Consolidate `workflow-gate.sh` with `cwf-live-state.sh`**
  Instead of reimplementing parsing logic, `workflow-gate.sh` should source `cwf-live-state.sh` and use the provided library functions. This centralizes all YAML manipulation logic.
- **[S2] Use `git check-ignore` for Deletion Scope**
  `check-deletion-safety.sh` manually excludes directories like `node_modules` and `.git`. Using `git check-ignore` or respecting `.gitignore` would be a more robust architectural pattern for determining which files are "in-repo" and worth searching for callers.
- **[S3] Unused `state_version`**
  The `state_version` is bumped correctly but currently serves no functional purpose (no optimistic locking or cache invalidation checks). It adds slight complexity to the state management without immediate benefit.

### Behavioral Criteria Assessment

- [x] **Delete file with runtime callers → Block** — Handled by `search_callers` returning hits to `json_block`.
- [x] **Delete file with no callers → Pass** — Hook exits 0 when `FILES_WITH_CALLERS` is empty.
- [x] **Grep fails or parse error → Block** — `SEARCH_FAILED=1` triggers a fail-closed `json_block` (line 241).
- [x] **rm -rf node_modules → Pass** — Explicitly excluded in `to_repo_rel` case statement (line 205).
- [x] **Broken link triage protocol** — Integrated into `check-links-local.sh` and documented in `agent-patterns.md`.
- [x] **Triage vs analysis recommendation** — "Recommendation Fidelity Check" added to `impl/SKILL.md` (item 16).
- [x] **cwf:run active gate violation → Block** — `workflow-gate.sh` blocks ship/push/commit when `review-code` is in `remaining_gates`.
- [x] **cwf:run stage update** — `run/SKILL.md` now uses `list-set` to manage `remaining_gates`.
- [x] **Stale pipeline from previous session** — `workflow-gate.sh` (line 167) detects `SESSION_ID` mismatch and warns.
- [x] **Active pipeline set but remaining_gates empty** — `workflow-gate.sh` (line 175) emits a warning.
- [x] **500-line review prompt → 180s timeout** — Logic added to `review/SKILL.md` table.
- [x] **100-line review prompt → 120s timeout** — Defaults to standard timeout as per table.

### Provenance
source: REAL_EXECUTION
tool: gemini
reviewer: Architecture
duration_ms: —
command: —

<\!-- AGENT_COMPLETE -->
