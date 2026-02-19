## Security Review

### Concerns (blocking)

- **[C1]** Proposal A: Deletion pattern matching in `check-deletion-safety.sh` (plan.md Step 1, item 1) uses simple string matching on `tool_input.command` for patterns like `rm ` (with trailing space), `git rm`, `unlink`. This is bypassable via trivial command variations: `rm  ` (double space), `command rm`, `/bin/rm`, `rm -f`, variable expansion (`$CMD file`), `find ... -delete`, `mv file /dev/null`, `> file` (truncation), or multi-line commands where `rm` appears after a newline. The plan should enumerate the minimum set of canonical patterns the agent would use and document that non-canonical deletions are an accepted residual risk, OR use a post-hoc file-existence check instead of command parsing.
  Severity: moderate

  Rationale: The hook fires on PostToolUse, meaning it inspects the command *after* execution. However, hooks.json registers it as a PostToolUse hook that outputs `{"decision":"block",...}` — the blocking JSON protocol is what existing PostToolUse hooks use (see `check-links-local.sh` line 82-84). The plan says "Parse `tool_input.command` from stdin JSON for deletion patterns" — but `tool_input.command` is the *command text*, not its output. If the hook fires post-execution, the file is already deleted. The plan needs to clarify whether the hook should be **PreToolUse** (to block before deletion) or PostToolUse (to detect and request restoration). The spec (review-and-prevention.md) says "PostToolUse hook" but the pseudocode says "fires after Bash/Edit/Write tool calls." If the deletion has already occurred by the time the hook runs, `exit 1` does not prevent it — it only signals the agent to restore. This is a semantic gap in the plan's safety claim "the deletion is prevented" (BDD criterion line 153-154).

- **[C2]** Proposal E+G: `user_directive` field is written to `cwf-state.yaml` via `cwf-live-state.sh set`. The plan mentions `cwf_live_sanitize_yaml_value()` to escape `:`, `\n`, `[`, `]` (Step 3, item 1, bullet 7). However, the plan does not specify *where* sanitization is called in the data flow. The existing `cwf_live_upsert_live_scalar()` (cwf-live-state.sh line 198-242) uses `cwf_live_escape_dq()` which only escapes `\` and `"` — it does NOT escape YAML-special characters. If `cwf_live_sanitize_yaml_value()` is a new function but `cwf_live_upsert_live_scalar()` is the actual writer, the sanitization function must be integrated into the write path, not left as an orphan utility. The plan should specify: (a) whether `cwf_live_sanitize_yaml_value()` wraps or replaces `cwf_live_escape_dq()`, and (b) whether it is called inside `cwf_live_upsert_live_scalar()` or at the call site.
  Severity: security

  Without this clarification, a `user_directive` value containing `: ` or `\n` could corrupt the YAML state file, potentially injecting arbitrary YAML keys into the `live:` block. Since `workflow-gate.sh` reads this file to make gate enforcement decisions, YAML corruption could cause the gate to silently malfunction.

### Suggestions (non-blocking)

- **[S1]** Proposal A: The `grep -rl` caller search (Step 1) runs across the entire repository for each deleted file. For repositories with large file counts, this could introduce noticeable latency on PostToolUse. Consider: (a) limiting the search scope to `plugins/` and root config files, (b) adding a timeout (e.g., 5 seconds) with fail-closed on timeout, (c) caching results per-session. The plan already excludes `.cwf/projects/` which is good, but the full repo scan remains unbounded.

- **[S2]** Proposal A: The exclusion pattern `rm ` (with space) is documented as avoiding false positives like `rm -rf node_modules`. However, `rm -rf node_modules` *does* start with `rm ` (rm-space), so this exclusion rationale in plan.md line 41 is incorrect. The pattern will match `rm -rf node_modules`. The plan should either: (a) clarify that this is intentional (all `rm` commands are inspected), or (b) add additional filtering logic for paths outside the project scope (e.g., `node_modules`, `/tmp`).

- **[S3]** Proposal E+G: `workflow-gate.sh` reads `cwf-state.yaml` on every UserPromptSubmit (every user turn). The YAML parsing is done via AWK (matching the existing `cwf_live_extract_scalar_from_file` pattern). If the state file is corrupted or has unexpected structure, the AWK parser fails silently (returns empty string), and the hook may exit 0 (no enforcement). The plan mentions fail-closed behavior for Proposal A but does not explicitly specify fail-closed for `workflow-gate.sh` parse failures. Recommend: if `active_pipeline` read fails (file missing, parse error), output a warning rather than silently passing.

- **[S4]** Proposal E+G: Gate name validation uses a hard-coded enum (Step 3, item 1, bullet 8): `gather`, `clarify`, `plan`, `review-plan`, `impl`, `review-code`, `refactor`, `retro`, `ship`. This enum must stay synchronized with the stage table in `run/SKILL.md` (line 59-69 of SKILL.md). If a new stage is added to run but not to the enum, `list-set` will reject it. The plan should note this coupling explicitly and consider sourcing the enum from a single location.

- **[S5]** Proposal E+G: The plan specifies that `workflow-gate.sh` detects stale `active_pipeline` from a previous session by comparing `session_id`. However, it does not specify *how* `workflow-gate.sh` obtains the current session's ID. The hook receives `session_id` in its stdin JSON (as seen in `track-user-input.sh` line 26: `SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')`), but the plan does not mention parsing `session_id` from stdin. This should be made explicit.

- **[S6]** Proposal E+G: The `--skip-gate` override mechanism (plan.md Step 3, item 4) stores the reason in `pipeline_override_reason`. The plan does not specify whether the override persists across compaction events. If `pipeline_override_reason` is set and the session compacts, the hook will continue to show the override warning but the *context* of why it was overridden may be lost. This is acceptable behavior (fail-open for overrides is the intended UX), but should be documented as a known property.

- **[S7]** Proposal B: The broken-link triage protocol is documentation-only (agent-patterns.md). Its effectiveness depends entirely on the agent reading and following the protocol. This is acknowledged in the spec as the intended design (P0 documentation + hook hint). No additional security concern beyond noting that this is a soft control, not a hard gate.

- **[S8]** Proposal A: The plan registers `check-deletion-safety.sh` as a PostToolUse hook for `"Bash"` matcher (Step 1, item 2). The existing PostToolUse hooks use matcher `"Write|Edit"`. Since file deletion can also occur via the `Write` tool (writing empty content to overwrite) or via `Bash` executing `mv` (rename that removes the original), the matcher scope should be reviewed. Matching on `"Bash"` alone would miss `Write`-based file destruction, though this is an edge case.

### Behavioral Criteria Assessment

- [x] **Proposal A: File deletion with runtime callers -> hook exits 1 with BLOCKED message** — Plan Step 1 specifies exit 1 with JSON `{"decision":"block","reason":"BLOCKED: {file} has runtime callers: {list}..."}`. The behavior is defined. However, see C1 regarding whether PostToolUse can actually *prevent* the deletion vs. detect and request restoration.

- [x] **Proposal A: File deletion with no callers -> hook exits 0 silently** — Plan Step 1 explicitly states: "If no callers: `exit 0` (silent pass)". Matches the existing convention (check-links-local.sh exits 0 on clean check).

- [x] **Proposal A: grep/parse failure -> hook exits 1 (fail-closed)** — Plan Step 1 explicitly states: "If grep/parse error: `exit 1` (fail-closed)". This is the correct security posture.

- [x] **Proposal B: Broken link error includes triage protocol reference** — Plan Step 2, item 2 specifies modifying `check-links-local.sh` around line 82 to append: "For triage guidance, see references/agent-patterns.md Broken Link Triage Protocol". The hint is embedded in the block decision output.

- [x] **Proposal C: Triage action contradiction -> follow original recommendation** — Plan Step 4 adds a rule to `impl/SKILL.md` instructing: "If the triage action contradicts or simplifies the original recommendation: follow the original, not the triage summary." Clear behavioral specification.

- [x] **Proposal E+G: remaining_gates includes review-code + ship attempt -> hook exits 1** — Plan Step 3, item 2, bullet 4 specifies: "If `remaining_gates` contains `review-code` AND prompt mentions ship/push/merge: `exit 1` with block message". The fail-closed gate behavior is defined.

- [x] **Proposal E+G: Stage completion -> list-remove updates YAML list** — Plan Step 3, item 1 defines `cwf_live_remove_list_item()` function and `list-remove` CLI subcommand. Plan Step 3, item 4 modifies `run/SKILL.md` Phase 2 to call `list-remove` after each stage. The update path is specified.

- [x] **Proposal E+G: Stale active_pipeline -> cleanup prompt output** — Plan Step 3, item 2, recovery section specifies: "if `active_pipeline` exists from a previous session (different `session_id`), output cleanup prompt." The behavior is defined, though see S5 regarding how current session_id is obtained.

- [x] **Proposal E+G: active_pipeline set + empty remaining_gates -> warning output** — Plan Step 3, item 2, bullet 5 specifies: "If `active_pipeline` is set but `remaining_gates` is empty: Output warning: stale pipeline state, suggest cleanup." Matches the BDD criterion.

### Additional Security Observations

**Secret management**: No secrets are introduced. All state is stored in YAML files within the repository. Hook toggles use environment variables via `cwf-hooks-enabled.sh`. No API keys, tokens, or passwords involved.

**Auth/authz**: Not applicable — this is a local CLI tool (Claude Code hooks), not a networked service. No authentication layer exists or is needed.

**Dependency risks**: No new external dependencies introduced. The hooks use standard POSIX utilities (`grep`, `awk`, `jq`, `bash`). `jq` is already a dependency of existing hooks.

**Insecure defaults**: All new hooks default to enabled (matching existing convention in `cwf-hook-gate.sh` line 26-28: hooks are enabled unless explicitly set to `"false"`). This is the correct default for safety hooks — fail-closed.

### Provenance

```
source: REAL_EXECUTION
tool: claude-task
reviewer: Security
duration_ms: —
command: —
```
<!-- AGENT_COMPLETE -->
