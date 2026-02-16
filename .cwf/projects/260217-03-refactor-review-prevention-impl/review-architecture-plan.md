## Architecture Review

Reviewer: Architecture
Target: `/home/hwidong/codes/claude-plugins/.cwf/projects/260217-03-refactor-review-prevention-impl/plan.md`
Spec: `/home/hwidong/codes/claude-plugins/.cwf/projects/260217-01-refactor-review/review-and-prevention.md`

---

### Concerns (blocking)

- **[C1]** Proposal A `check-deletion-safety.sh` parses `tool_input.command` but this is a **new input schema** for PostToolUse hooks. All existing PostToolUse hooks (`check-markdown.sh`, `check-shell.sh`, `check-links-local.sh`) parse `tool_input.file_path` from `Write|Edit` matchers. The Bash tool's stdin JSON uses `tool_input.command` (a free-form string), not `tool_input.file_path`. The plan says to detect deletion patterns via regex on `tool_input.command` (`git rm`, `rm `, `unlink`), but the regex `rm ` (with trailing space) is fragile:
  - `rm -rf dir/` has a flag between `rm` and the path -- the plan says "with space to avoid false positives like `rm -rf node_modules`" but then this IS `rm ` with a space, so the comment contradicts itself.
  - Multi-file deletions (`rm file1 file2`) require path extraction per argument.
  - Piped/subshell deletions (`find ... -exec rm {} \;`, `xargs rm`) would be missed entirely.
  - The plan does not specify how to extract the **file path** from the command string for the subsequent `grep -rl` caller search. This path extraction is the hardest part and is left unspecified.

  **Recommendation**: The plan must include a concrete path-extraction algorithm (e.g., parse arguments after `git rm`, `rm`, `unlink` using shell-safe splitting). The regex patterns and extraction logic should be documented with test cases covering `git rm file`, `rm -f file`, `rm file1 file2`, and pipe chains. Alternatively, acknowledge these as known false-negative gaps and document them explicitly as limitations, relying on Proposal D (P2) for deeper coverage.

  Severity: **moderate**

- **[C2]** Proposal E+G `workflow-gate.sh` as a **synchronous** UserPromptSubmit hook introduces a **latency tax on every single user prompt**. The existing UserPromptSubmit hook (`track-user-input.sh`) is explicitly `async: true` to avoid blocking the prompt path. The plan states workflow-gate.sh must be synchronous ("Must block agent before it processes the prompt; async would be advisory only"), which is correct for safety semantics, but creates a performance concern:
  - The hook must: find repo root (`git rev-parse`), read and parse `cwf-state.yaml` YAML (custom AWK), extract multiple fields, evaluate gate conditions.
  - This runs **on every user prompt**, not just during cwf:run sessions.
  - When `active_pipeline` is not set (the common case for non-cwf:run sessions), the hook should fast-exit, but the plan does not specify this fast-exit path clearly.

  **Recommendation**: The plan should explicitly specify that when `active_pipeline` is empty/absent, the hook exits 0 immediately after the YAML field extraction (no further processing). This fast-exit guarantee must be documented as a design requirement, not left as an implementation detail.

  Severity: **moderate**

- **[C3]** Proposal E+G modifies `cwf-live-state.sh` with `list-set` and `list-remove` CLI subcommands, `cwf_live_upsert_live_list()`, `cwf_live_remove_list_item()`, sanitization, and gate validation. This is **5-6 new functions plus 2 new subcommands** in a single step, making `cwf-live-state.sh` significantly more complex (currently ~405 lines, would grow to ~550+ lines). The plan groups all of this into Step 3 alongside creating `workflow-gate.sh` AND modifying `hooks.json`, `SKILL.md`, and `cwf-state.yaml` -- a single commit for ~7 files with substantial new logic.

  The plan's own commit strategy says "per step: each step gets its own commit. 4 steps = 4 commits." But Step 3 is doing the work of 2-3 steps. The `cwf-live-state.sh` list infrastructure is a **foundation** that E+G depends on, and it should be separable.

  **Recommendation**: Consider splitting Step 3 into sub-commits: (3a) list operations in `cwf-live-state.sh`, (3b) `workflow-gate.sh` hook + registration. This preserves atomicity while making the diff reviewable. At minimum, document why the single-commit approach is preferred despite the scope.

  Severity: **moderate**

---

### Suggestions (non-blocking)

- **[S1]** Proposal A specifies the grep search should exclude `.cwf/projects/` paths (Decision #2 in the Decision Log). This is correct for session artifacts, but the plan should also consider excluding `node_modules/`, `.git/`, and other non-source directories to avoid false positives and performance issues on large repos. The existing `check-links-local.sh` (line 33) uses a case pattern for `.cwf/projects/` exclusion -- the same pattern should be reused for consistency.

- **[S2]** Proposal A registers a new PostToolUse matcher entry for `"Bash"` in `hooks.json`. The existing PostToolUse section has a `"Write|Edit"` matcher. Adding a separate `"Bash"` matcher creates a second hook group under PostToolUse with a different HOOK_GROUP (`deletion_safety` vs `lint_markdown`/`lint_shell`). This is the correct structural pattern -- matchers should not be merged (`"Write|Edit|Bash"`) since the hooks have completely different logic. The plan correctly follows this pattern.

- **[S3]** The plan specifies `cwf_live_sanitize_yaml_value()` to escape `:`, `\n`, `[`, `]` for YAML safety of `user_directive`. This is good but incomplete -- YAML also has special characters `#` (comment), `%` (directive), `&`/`*` (anchors/aliases), `!` (tags), `{`/`}` (flow mapping), and `>` / `|` (block scalars). A more robust approach would be to always double-quote the value (which the existing `cwf_live_upsert_live_scalar` already does via `cwf_live_escape_dq`). Consider whether a separate sanitize function is needed at all, or if the existing quoting behavior is sufficient.

- **[S4]** Proposal B modifies `check-links-local.sh` line 82 to append a triage protocol hint. The current output format on line 80-84 constructs a JSON `reason` field. Adding a hint line to the reason string is non-disruptive, but the plan should specify the exact format to ensure it does not break JSON escaping. The existing `printf ... | jq -Rs .` pattern on line 80 handles multi-line strings correctly, so appending `\nFor triage guidance...` inside the printf is safe.

- **[S5]** Proposal E+G introduces gate name validation against a hard-coded enum: `gather`, `clarify`, `plan`, `review-plan`, `impl`, `review-code`, `refactor`, `retro`, `ship` (Decision #5). This enum duplicates the stage definition in `run/SKILL.md` Phase 2 Stage Definition table (lines 59-69). If a new stage is added to cwf:run, both locations must be updated. Consider extracting the enum to a shared location (e.g., a file that both `cwf-live-state.sh` and `SKILL.md` reference) or at minimum adding a comment cross-referencing the SSOT.

- **[S6]** The plan specifies `workflow-gate.sh` should detect stale `active_pipeline` from a previous session using `session_id` comparison. However, the plan does not specify **where** the current session's `session_id` comes from in the UserPromptSubmit hook context. The compact-context.sh hook (line 36) extracts `session_id` from stdin JSON (`jq -r '.session_id // empty'`), but UserPromptSubmit hooks receive different stdin fields than SessionStart hooks. The plan should verify that `session_id` is available in UserPromptSubmit stdin or propose an alternative detection mechanism (e.g., reading `live.session_id` from cwf-state.yaml and comparing with a process-level session identifier).

- **[S7]** Proposal C adds a rule to `impl/SKILL.md` as "Recommendation Fidelity Check." The plan says "Insert new rule after current Rule 15 (before 'Language split is mandatory')." The current Rule 15 in `impl/SKILL.md` (line 438) is "Incremental lessons are mandatory" and Rule 16 (line 439) is "Language split is mandatory." The insertion point is precise. However, this is a **prose rule** -- the same class of defense that 5/6 reviewers criticized as insufficient for Proposal A. The spec acknowledges this tension (Proposal C was elevated to P1, not P0, because it is prose-level). This is acceptable as documented, but worth noting that Proposal C's effectiveness depends entirely on agent compliance during compacted sessions.

- **[S8]** The plan modifies `.cwf/cwf-state.yaml` to add `deletion_safety: true` and `workflow_gate: true` under `hooks:`. The current hooks section (lines 395-401) has 7 entries. The plan's Deferred Actions note that these should be added to `cwf:setup` hook group selection UI, which is correctly deferred. However, the plan does not specify whether these hooks should default to `true` (enabled) or `false` (disabled) for **existing installations**. The existing convention (per `cwf-hook-gate.sh` line 12-13: "Default: enabled — hooks work without cwf:setup") means any hook without an explicit `false` in `~/.claude/cwf-hooks-enabled.sh` will be active. This is the correct default for safety hooks (fail-closed), but may surprise users who haven't run cwf:setup recently.

- **[S9]** The `cwf_live_remove_list_item()` function for `list-remove` needs careful specification of edge cases: what happens when removing the last item from a list? Does the key become an empty list (`remaining_gates: []`), get deleted entirely, or become null? The behavior matters because `workflow-gate.sh` checks "if remaining_gates is empty" for stale-state warnings. The plan should specify the empty-list representation explicitly to avoid ambiguity between "empty list" and "key absent."

---

### Behavioral Criteria Assessment

#### BDD Criteria

- [x] **Proposal A: File deletion with runtime callers -> hook exits 1 with BLOCKED message** -- Plan Step 1 specifies `exit 1` with JSON `{"decision":"block","reason":"BLOCKED: {file} has runtime callers: {list}..."}` when `grep -rl` finds callers. Follows the blocking pattern from existing hooks (`check-links-local.sh`, `check-shell.sh`). Note: the plan uses `exit 1` but existing hooks use `exit 0` with `{"decision":"block",...}` -- see [C1] for command parsing concerns, but the blocking behavior itself is specified.

- [x] **Proposal A: File deletion with no callers -> hook exits 0 silently** -- Plan Step 1 explicitly states "If no callers: exit 0 (silent pass)". Matches existing convention in `check-links-local.sh` line 69 (`exit 0` on clean).

- [x] **Proposal A: grep/parse failure -> hook exits 1 (fail-closed)** -- Plan Step 1 states "If grep/parse error: exit 1 (fail-closed)". Spec Section 6 Proposal A confirms "Fail-closed: false positive가 false negative보다 안전하다." However, note that existing hooks (e.g., `check-links-local.sh`) use `exit 0` with `{"decision":"block",...}` rather than `exit 1` for blocking. The plan should clarify whether `exit 1` without JSON output is the intended fail-closed mechanism or whether it should output a block decision JSON before exiting.

- [x] **Proposal B: Broken link error includes triage protocol reference** -- Plan Step 2 modifies `check-links-local.sh` line 82 area to append `"For triage guidance, see references/agent-patterns.md S Broken Link Triage Protocol"` to the reason string. The triage protocol content is added to `agent-patterns.md` as a new section.

- [x] **Proposal C: Triage action contradiction -> follow original recommendation** -- Plan Step 4 adds a rule to `impl/SKILL.md` specifying "If the triage action contradicts or simplifies the original recommendation: follow the original, not the triage summary." This is prose-only but correctly specified.

- [x] **Proposal E+G: remaining_gates includes review-code + ship attempt -> hook exits 1** -- Plan Step 3 item 2 specifies: "If remaining_gates contains review-code AND prompt mentions ship/push/merge: exit 1 with block message." Synchronous hook ensures blocking before prompt processing.

- [x] **Proposal E+G: Stage completion -> list-remove updates YAML list** -- Plan Step 3 item 1 adds `list-remove` subcommand to `cwf-live-state.sh`. Step 3 item 4 modifies `run/SKILL.md` Phase 2 to call `list-remove` after each stage completes.

- [x] **Proposal E+G: Stale active_pipeline -> cleanup prompt output** -- Plan Step 3 item 2 specifies: "Recovery: if active_pipeline exists from a previous session (different session_id), output cleanup prompt." See [S6] regarding session_id availability.

- [x] **Proposal E+G: active_pipeline set + empty remaining_gates -> warning output** -- Plan Step 3 item 2 specifies: "If active_pipeline is set but remaining_gates is empty: Output warning: stale pipeline state, suggest cleanup."

#### Qualitative Criteria

- [x] **Hook scripts follow existing codebase conventions** -- Plan explicitly references `check-links-local.sh` template structure for Proposal A (HOOK_GROUP, gate, stdin parse, decision output). Both new hooks (`check-deletion-safety.sh`, `workflow-gate.sh`) specify HOOK_GROUP and source `cwf-hook-gate.sh`. Convention adherence is well-specified.

- [x] **cwf-live-state.sh list operations use the same AWK patterns as existing scalar operations** -- Plan Step 3 specifies `cwf_live_upsert_live_list()` "after `cwf_live_upsert_live_scalar`" following the same pattern. The existing scalar AWK pattern (lines 207-241 of `cwf-live-state.sh`) uses `in_live` tracking, key matching, and `mktemp`-based atomic writes. The plan implies list operations will follow this same structure.

- [x] **All new hooks are toggleable via cwf-hooks-enabled.sh** -- Both new hooks specify HOOK_GROUP values (`deletion_safety`, `workflow_gate`) and source `cwf-hook-gate.sh`, which reads `HOOK_{GROUP}_ENABLED` from `~/.claude/cwf-hooks-enabled.sh`. The gate mechanism is inherited.

- [x] **Documentation changes integrate naturally with existing sections** -- Proposal B inserts into `agent-patterns.md` before "Design Principles" (existing section). Proposal C inserts into `impl/SKILL.md` Rules section after Rule 15. Both are incremental additions to existing structure.

- [x] **Fail-closed behavior: false positives preferred over false negatives for safety hooks** -- Proposal A specifies `exit 1` on parse/grep failure. Proposal E+G uses synchronous blocking on gate violations. Both align with the fail-closed principle.

---

### Architectural Observations

**Separation of concerns**: The plan maintains clean separation between:
- State management (`cwf-live-state.sh`) -- data layer
- Enforcement (`workflow-gate.sh`, `check-deletion-safety.sh`) -- hook layer
- Orchestration (`run/SKILL.md`) -- skill layer
- Documentation (`agent-patterns.md`, `impl/SKILL.md`) -- reference layer

Each component has a single responsibility. Dependencies flow in the correct direction: hooks read state, skills write state, documentation informs behavior.

**Pattern consistency**: The plan follows established patterns faithfully. Both new hooks follow the HOOK_GROUP + gate + stdin parse + decision output template. New CLI subcommands follow the existing `set`/`sync`/`resolve` pattern in `cwf-live-state.sh`. The `hooks.json` registration follows existing matcher-group-command structure.

**Extension points**: The gate name enum (Decision #5) is a hardcoded extension point. Adding new pipeline stages requires updating both the enum in `cwf-live-state.sh` and the stage table in `run/SKILL.md`. This is a managed coupling, not an architectural flaw, but is worth tracking.

**Technical debt**: The plan introduces minimal technical debt:
- The `rm ` regex parsing (C1) is a known limitation, documented as addressable by Proposal D (P2).
- The prose-only nature of Proposal C is explicitly acknowledged.
- The deferred proposals (D, F, H, I) are cleanly scoped out.

**Dependency direction**: Clean. `workflow-gate.sh` depends on `cwf-live-state.sh` (reads state), `run/SKILL.md` depends on `cwf-live-state.sh` (writes state). No circular dependencies. The hook layer is read-only with respect to state -- it reads `cwf-state.yaml` but does not modify it.

---

### Summary

The plan is architecturally sound. It follows existing conventions closely, maintains clean separation of concerns, and introduces two new hooks that integrate naturally with the existing hook infrastructure. The three moderate concerns ([C1]-[C3]) are all addressable without structural changes -- they relate to specification precision (path extraction algorithm), performance guarantees (fast-exit path), and commit granularity (Step 3 scope). None of them challenge the fundamental design.

**Verdict: Conditional Pass** -- address the moderate concerns in the implementation spec or document them as known limitations with mitigation plans.

### Provenance

```
source: FALLBACK
tool: claude-task-fallback
reviewer: Architecture
duration_ms: -
command: -
```

<!-- AGENT_COMPLETE -->
