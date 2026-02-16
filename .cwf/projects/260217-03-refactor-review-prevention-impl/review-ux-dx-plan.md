## UX/DX Review

### Concerns (blocking)

- **[C1]** PostToolUse matcher for Proposal A uses `"Bash"` but deletion can also occur via `Write` tool (overwriting with empty content) or `Edit` tool (removing all content). More critically, the existing PostToolUse matcher `"Write|Edit"` already fires for Write/Edit and runs `check-links-local.sh`, `check-shell.sh`, `check-markdown.sh` — but the plan registers `check-deletion-safety.sh` under a *separate* `"Bash"` matcher only. This means `git rm` is caught but a hypothetical `rm` executed outside Bash (e.g., via a future tool) is not. The plan should explicitly state that the `"Bash"` matcher is the only necessary scope and document *why* Write/Edit deletions are out of scope (e.g., those tools don't delete files, they overwrite content).
  - Reference: Plan Step 1, item 2 ("Add new PostToolUse matcher entry for `"Bash"` after the existing `"Write|Edit"` matcher")
  - Severity: moderate

- **[C2]** The `check-deletion-safety.sh` plan describes matching patterns `git rm`, `rm ` (with trailing space), and `unlink` in `tool_input.command`. However, the trailing-space heuristic for `rm ` is fragile: `rm` with flags like `rm -f file.sh` has a space after `-f`, not directly after `rm`. The plan should specify the regex pattern precisely. For example, `\brm\s+` would match `rm file`, `rm -f file`, `rm -rf dir/` — but the plan says "rm (with space to avoid false positives like `rm -rf node_modules`)" which suggests it *wants* to avoid `rm -rf` but uses a pattern that would still match it. This creates a contradiction: `rm -rf node_modules` does start with `rm ` (with trailing space). The plan needs a clearer deletion-pattern specification — either an explicit regex, or a list of positive/negative examples, to avoid implementer confusion.
  - Reference: Plan Step 1, item 1 ("Parse `tool_input.command` from stdin JSON for deletion patterns: `git rm`, `rm ` (with space to avoid false positives like `rm -rf node_modules`), `unlink`")
  - Severity: critical

- **[C3]** The plan adds `list-set` and `list-remove` as new CLI subcommands to `cwf-live-state.sh`, but the existing usage/help message at line 400 only shows `{resolve|sync}` and `set`. The plan does not mention updating the help/usage output. Users (developers maintaining hooks or debugging state) who run `cwf-live-state.sh --help` or provide an invalid subcommand will see the old usage string that does not mention `list-set` or `list-remove`. This violates discoverability.
  - Reference: Plan Step 3, item 1 (new CLI subcommands) vs. `/home/hwidong/codes/claude-plugins/plugins/cwf/scripts/cwf-live-state.sh` lines 397-403 (existing help/usage)
  - Severity: moderate

- **[C4]** The plan specifies `workflow-gate.sh` as a UserPromptSubmit hook but does not specify the `matcher` value. Looking at `hooks.json`, the existing UserPromptSubmit entry uses `"matcher": ""` (empty string = match all prompts). The new `workflow-gate.sh` also needs to match all prompts (it checks state on every prompt). However, the hooks.json structure groups hooks under a single matcher. If both `track-user-input.sh` (async) and `workflow-gate.sh` (synchronous) share the same `"matcher": ""`, they must be in the same hooks array. The plan says "Add `workflow-gate.sh` to UserPromptSubmit hooks array (synchronous, no `async: true`)" but does not specify whether it goes into the *existing* empty-matcher array alongside `track-user-input.sh` or as a new matcher entry. This distinction matters because the existing hook is `async: true` while the new one must be synchronous. The plan should explicitly specify the hooks.json structure change (new matcher entry or appended to existing array).
  - Reference: Plan Step 3, item 3 ("Add `workflow-gate.sh` to UserPromptSubmit hooks array")
  - Severity: moderate

### Suggestions (non-blocking)

- **[S1]** The plan uses emoji (`⚠`) in hook output messages (Step 3, item 2: `"⚠ Active pipeline: {active_pipeline} (phase: {phase})"`). While this is visible in terminal output, emoji rendering can be inconsistent in log files, CI environments, or piped output. Consider using a text prefix like `[WARNING]` or `WARNING:` instead, consistent with the `BLOCKED:` prefix used in Proposal A. This would maintain visual consistency across all new hooks.
  - Reference: Plan Step 3, item 2 (workflow-gate.sh output format)

- **[S2]** The gate name validation enum in Step 3 (`gather`, `clarify`, `plan`, `review-plan`, `impl`, `review-code`, `refactor`, `retro`, `ship`) is hard-coded. The cwf:run SKILL.md Stage Definition table (lines 59-69 of `SKILL.md`) is the authoritative source of stage names. If stages are added or renamed in `run/SKILL.md`, the hard-coded enum in `cwf-live-state.sh` will silently drift. Consider: (a) documenting the enum as a "must be updated when run/SKILL.md changes" contract, or (b) adding a comment in the enum listing the authoritative source file path.
  - Reference: Plan Step 3, item 1 ("Add gate name validation against allowed enum") and Decision Log #5

- **[S3]** The plan specifies `cwf_live_sanitize_yaml_value()` for escaping `:`, `\n`, `[`, `]` in `user_directive` values. This is good, but the plan does not specify what `active_pipeline` or `pipeline_override_reason` values look like or whether they also need sanitization. If `pipeline_override_reason` is free-form text from the user (e.g., "user said: skip review because time pressure"), it contains `:` and should also be sanitized. The plan should clarify which fields pass through sanitization.
  - Reference: Plan Step 3, item 1 (`cwf_live_sanitize_yaml_value`)

- **[S4]** The `list-remove` operation could silently succeed when the item is not in the list (e.g., removing `review-code` when it was already removed). The plan does not specify idempotency behavior. For developer experience, `list-remove` should either (a) be explicitly idempotent (silent success, documented), or (b) exit non-zero when the item is not found. Idempotent is likely the right choice for compaction-recovery scenarios, but it should be stated.
  - Reference: Plan Step 3, item 1 (`cwf_live_remove_list_item`)

- **[S5]** Proposal C (Step 4) inserts a new rule and renumbers subsequent rules. The plan says "Insert new rule after current Rule 15 (before 'Language split is mandatory')". This references a specific rule number that may have changed since the plan was written. The plan should reference the rule by content/name rather than number, or verify the current rule numbering at implementation time.
  - Reference: Plan Step 4, item 1

- **[S6]** The plan specifies `deletion_safety: true` and `workflow_gate: true` in `cwf-state.yaml` hooks section, and the Deferred Actions mention adding these to `cwf:setup` hook group selection UI. However, the current `cwf-hooks-enabled.sh` gate mechanism uses `HOOK_{GROUP}_ENABLED` environment variables. The plan should confirm that the `HOOK_GROUP` values (`deletion_safety` and `workflow_gate`) map correctly to `HOOK_DELETION_SAFETY_ENABLED` and `HOOK_WORKFLOW_GATE_ENABLED` respectively, and that these are consistent with the `cwf-state.yaml` hooks key names. This is currently consistent but worth stating explicitly for maintainer confidence.
  - Reference: Plan Steps 1 and 3 (`.cwf/cwf-state.yaml` hook toggle) and `/home/hwidong/codes/claude-plugins/plugins/cwf/hooks/scripts/cwf-hook-gate.sh` lines 22-23

- **[S7]** The `workflow-gate.sh` recovery logic (detecting stale `active_pipeline` from a previous session via different `session_id`) does not specify how `session_id` comparison works. The current `cwf-state.yaml` has `live.session_id: "260217-03"`, but the plan does not describe how the hook determines the *current* session ID to compare against the stored one. If it reads from the hook's stdin JSON `session_id` field (as `track-user-input.sh` does), this should be stated. If it relies on some other mechanism, that should be documented.
  - Reference: Plan Step 3, item 2 (Recovery section: "previous session (different `session_id`)")

### Behavioral Criteria Assessment

- [x] **Proposal A: File deletion with runtime callers -> hook exits 1 with BLOCKED message** — Plan Step 1 explicitly specifies `exit 1` with JSON `{"decision":"block","reason":"BLOCKED: {file} has runtime callers: {list}. Restore file or remove callers first."}`. The output format follows the existing `check-links-local.sh` convention (JSON with `decision` and `reason` fields). Error message is actionable: identifies the file, lists callers, and provides two resolution paths (restore or remove callers).

- [x] **Proposal A: File deletion with no callers -> hook exits 0 silently** — Plan Step 1 states "If no callers: `exit 0` (silent pass)". Consistent with existing hooks like `check-shell.sh` line 53 (`exit 0` on clean pass).

- [x] **Proposal A: grep/parse failure -> hook exits 1 (fail-closed)** — Plan Step 1 states "If grep/parse error: `exit 1` (fail-closed)". However, the plan does not specify the error *message* for this case. Existing hooks output a JSON `{"decision":"block","reason":...}` even on tool-missing errors (see `check-links-local.sh` lines 43-48). The plan should specify whether the fail-closed path also outputs a JSON block message (for consistent agent behavior) or just exits 1 silently. Marking as pass because the exit behavior is correct, but the error message design is underspecified.

- [x] **Proposal B: Broken link error includes triage protocol reference** — Plan Step 2 specifies modifying `check-links-local.sh` around line 82 to append `"For triage guidance, see references/agent-patterns.md § Broken Link Triage Protocol"` to the block reason. The section heading matches what will be added to `agent-patterns.md` ("## Broken Link Triage Protocol").

- [x] **Proposal C: Triage action contradiction -> follow original recommendation** — Plan Step 4 adds a "Recommendation Fidelity Check" rule to `impl/SKILL.md` with explicit instruction: "If the triage action contradicts or simplifies the original recommendation: follow the original, not the triage summary." This is a prose rule (not a hook), which is appropriate for this type of judgment-requiring check.

- [x] **Proposal E+G: remaining_gates includes review-code + ship attempt -> hook exits 1** — Plan Step 3, item 2, point 4 specifies: "If `remaining_gates` contains `review-code` AND prompt mentions ship/push/merge: `exit 1` with block message." The plan uses the existing hook blocking convention.

- [x] **Proposal E+G: Stage completion -> list-remove updates YAML list** — Plan Step 3, item 1 adds `list-remove` CLI subcommand, and Step 3, item 4 updates `run/SKILL.md` Phase 2 to call `list-remove` after each stage completes. The data flow is: stage completes -> `cwf-live-state.sh list-remove . remaining_gates {stage}` -> YAML list item removed.

- [x] **Proposal E+G: Stale active_pipeline -> cleanup prompt output** — Plan Step 3, item 2 (Recovery section) specifies: "if `active_pipeline` exists from a previous session (different `session_id`), output cleanup prompt." This is covered in the hook design.

- [x] **Proposal E+G: active_pipeline set + empty remaining_gates -> warning output** — Plan Step 3, item 2, point 5 specifies: "If `active_pipeline` is set but `remaining_gates` is empty: Output warning: stale pipeline state, suggest cleanup." This matches the behavioral criterion exactly.

### Provenance

```
source: REAL_EXECUTION
tool: claude-task
reviewer: UX/DX
duration_ms: —
command: —
```
<!-- AGENT_COMPLETE -->
