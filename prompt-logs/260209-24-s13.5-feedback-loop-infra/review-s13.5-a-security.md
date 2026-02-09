## Security Review

### Concerns (blocking)

- **[C1]** JSON injection via unescaped string interpolation in `--json` output mode (`scripts/provenance-check.sh` lines 136-139).
  The `printf` on line 136 interpolates `$pfile_rel`, `$target`, `$written_session`, and `$last_reviewed` directly into a JSON string using `%s` format specifiers with no escaping. If any `.provenance.yaml` file contains double quotes, backslashes, or newlines in its `target` field, the produced JSON will be malformed or structurally altered.
  **Verified**: I created a test file with `target: "test\", \"injected\": true, \"x\": \""` and the script produced invalid/injectable JSON output: `"target":""test\", \"injected\": true, \"x\": \""`.
  Severity: **moderate** -- The `.provenance.yaml` files are developer-authored and checked into version control, so exploitation requires a malicious commit. However, if the `--json` output is ever consumed by another script (e.g., `jq`, CI pipeline), a crafted provenance file could alter the parsed JSON structure.
  **Fix**: Use `jq -n` for JSON construction, or at minimum escape double quotes and backslashes in string values before interpolation (e.g., `${target//\"/\\\"}`).

- **[C2]** Non-numeric `skill_count`/`hook_count` causes uncontrolled `$((...))` arithmetic evaluation failure (`scripts/provenance-check.sh` lines 114, 120).
  When a `.provenance.yaml` file contains a non-integer `skill_count` (e.g., `abc` or `0+0*0`), the `$((CURRENT_SKILLS - recorded_skills))` expression either crashes with "unbound variable" (for alphabetic strings) or silently evaluates arithmetic expressions (for `0+0*0`, bash evaluates it as `0` and computes `9 - 0 = 9`). The `set -e` flag causes the script to exit on the error, but the exit happens mid-loop -- after already printing "FRESH" for prior files but before printing a summary, leaving partial/misleading output.
  Severity: **moderate** -- Same threat model as C1 (requires malicious commit). The real risk is that a typo in a provenance file (e.g., `skill_count: nine`) causes the script to crash without a clear error message, making it a fragile validation tool.
  **Fix**: Validate that `recorded_skills` and `recorded_hooks` match `^[0-9]+$` before using them in arithmetic. Skip the file or report an error if they don't.

### Suggestions (non-blocking)

- **[S1]** The YAML parser (lines 86-104) does not strip surrounding quotes from values. A value like `target: "CLAUDE.md"` would store `"CLAUDE.md"` (with quotes) rather than `CLAUDE.md`. The current `.provenance.yaml` files happen to not quote their `target`, `skill_count`, or `hook_count` fields, so this works today. But it is fragile -- YAML allows quoting, and a future edit by a developer or tool (e.g., `yq`) could add quotes, breaking comparison logic silently.
  **File**: `scripts/provenance-check.sh` lines 88-102.

- **[S2]** The `--level` flag crashes with "unbound variable" if provided without an argument (line 19: `LEVEL="$2"` under `set -u`). The error message is unhelpful. Consider adding a guard: `[[ $# -lt 2 ]] && echo "Error: --level requires an argument" >&2 && exit 1`.
  **File**: `scripts/provenance-check.sh` line 19.

- **[S3]** The `find` command on line 53 for counting skills uses a relative path `plugins/cwf/skills` after `cd "$REPO_ROOT"`. If `git rev-parse --show-toplevel` fails (e.g., in a detached worktree or non-git context) and falls back to `pwd`, and `pwd` is not the repo root, both `find` commands will silently return 0 for both skills and hooks. This would make all provenance files appear "fresh" even if the system state has changed. Consider adding a check that `plugins/cwf/skills` exists after `cd`.
  **File**: `scripts/provenance-check.sh` lines 49-54.

- **[S4]** The `${skill_delta:+${skill_delta#+}}` expansion on line 116 is intended to strip a leading `+` sign, but bash arithmetic never produces a leading `+` for positive numbers (e.g., `$((9 - 5))` produces `4`, not `+4`). The expansion is a no-op. For negative deltas, the `-` is preserved correctly. If the intent is to show `+4` for positive growth, the logic should be `[[ $skill_delta -gt 0 ]] && skill_delta="+$skill_delta"`.
  **File**: `scripts/provenance-check.sh` lines 116, 123.

- **[S5]** No hardcoded secrets, API keys, tokens, or credentials found in any of the committed files. All 6 `.provenance.yaml` sidecar files contain only metadata (session IDs, integer counts, and human-readable scope descriptions). This is clean.

- **[S6]** The provenance sidecar files do not verify that the `target` file actually exists in the same directory. A provenance file could reference a deleted or renamed document and still report "FRESH" if the counts match. Consider adding an existence check for the target file.
  **File**: `scripts/provenance-check.sh` -- no target file existence check in the loop body (lines 75-149).

### Behavioral Criteria Assessment

- [x] **All 6 provenance sidecar files exist and report FRESH with exit code 0** -- Verified by running `scripts/provenance-check.sh` against the commit state. All 6 files reported FRESH. Exit code was 0.

- [x] **Artificially stale provenance (skill_count: 5) reports STALE with correct delta message** -- Verified by editing `holistic-criteria.provenance.yaml` to `skill_count: 5` and running the script. Output: `STALE  plugins/cwf/skills/refactor/references/holistic-criteria.provenance.yaml -> holistic-criteria.md (skills: 5 -> 9 (4))`. Exit code was 1.

- [x] **Refactor holistic mode checks provenance before loading criteria, warns user if different** -- The refactor `SKILL.md` adds Phase "1b. Provenance Check" (lines 201-210) between the inventory build (Phase 1) and the criteria load (Phase 2). It instructs: read the `.provenance.yaml`, compare counts against inventory, warn user with specific delta, use `AskUserQuestion` to gate proceed/pause. This is correctly placed as a gate before Phase 2.

- [x] **skill-conventions.md has formal Provenance Rule (not "Future Consideration")** -- The section heading was changed from `## Future Consideration: Self-Healing Criteria` to `## Provenance Rule: Self-Healing Criteria` (line 151 of `skill-conventions.md`). The content was expanded from a 3-line "idea" placeholder to a full specification with subsections.

### Provenance

```text
source: REAL_EXECUTION
tool: claude-task
reviewer: Security
duration_ms: 122315
command: git show 75ef807
```
