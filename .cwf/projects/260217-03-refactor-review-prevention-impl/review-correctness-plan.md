# Correctness Review — Plan: Implement Prevention Proposals A, B, C, E+G

**Reviewer**: Correctness & Performance (substitution run)
**Target**: `.cwf/projects/260217-03-refactor-review-prevention-impl/plan.md`
**Spec**: `.cwf/projects/260217-01-refactor-review/review-and-prevention.md`
**Existing hooks**: `plugins/cwf/hooks/hooks.json`, `plugins/cwf/hooks/scripts/cwf-hook-gate.sh`
**State management**: `plugins/cwf/scripts/cwf-live-state.sh`
**Hook template**: `plugins/cwf/hooks/scripts/check-links-local.sh`

---

## Correctness Review

### Concerns (blocking)

- **[C1]** PostToolUse timing semantics: deletion has already occurred when hook fires (plan.md Step 1, lines 36-56; spec Section 6, Proposal A)
  Severity: critical

  The plan registers `check-deletion-safety.sh` as a **PostToolUse** hook for the `"Bash"` matcher. PostToolUse fires **after** the Bash tool has already executed. By the time the hook runs, `git rm file.sh` or `rm file.sh` has already completed and the file is deleted from the working tree.

  The plan's BDD criterion states "the deletion is prevented" (plan.md line 154), but this is factually impossible with PostToolUse semantics. The hook's `exit 1` with `{"decision":"block",...}` tells the agent the action was problematic, but the file is already gone. The block message says "Restore file or remove callers first" — the agent must then execute `git checkout -- {file}` to undo the deletion, which is recovery, not prevention.

  All existing PostToolUse hooks (`check-markdown.sh`, `check-shell.sh`, `check-links-local.sh`) work because they validate the **result** of Write/Edit operations where the file still exists. For deletion, the file no longer exists.

  Contrast with PreToolUse hooks: `redirect-websearch.sh` and `read-guard.sh` fire **before** the tool executes and can return `{"decision":"deny"}` to prevent execution entirely. This is the correct hook event for prevention.

  **Recommendation**: Switch Proposal A to a **PreToolUse** hook on `"Bash"` that inspects `tool_input.command` before execution. If callers exist, return `{"decision":"deny","reason":"BLOCKED: ..."}`. This actually prevents the deletion. Alternatively, keep PostToolUse but (a) reframe the BDD criterion to "the agent is forced to restore the file", (b) include an explicit restore command (`git checkout -- {file}`) in the block reason, and (c) acknowledge this is recovery-after-the-fact, not prevention.

- **[C2]** File path extraction from deletion commands is unspecified and has logic errors (plan.md Step 1, lines 41-42)
  Severity: critical

  The plan says: "Parse `tool_input.command` from stdin JSON for deletion patterns: `git rm`, `rm ` (with space to avoid false positives like `rm -rf node_modules`), `unlink`." The stated rationale for the trailing space on `rm ` is incorrect: `rm -rf node_modules` **does** start with `rm ` followed by a space character. The trailing-space pattern matches this command.

  Beyond the rationale error, the plan provides no specification for how to extract the actual file path(s) from detected commands. Real-world deletion commands include:
  - Flag handling: `rm -f path`, `rm -rf dir/`, `git rm --cached path`, `git rm -f -- path`
  - Multiple targets: `rm a.sh b.sh`, `git rm file1.sh file2.sh`
  - Compound commands: `rm a.sh && rm b.sh`, `rm a.sh; rm b.sh`
  - Pipelines: `find . -name "*.bak" -exec rm {} \;`, `xargs rm < filelist.txt`
  - Variable interpolation: `rm "$FILE"`, `rm "${BASE_DIR}/script.sh"` (no static analysis possible)
  - Whitespace in paths: `rm "path with spaces/file.sh"`
  - Tab separation: `rm\tfile.sh`
  - Directory deletion: `rm -rf plugins/cwf/skills/gather/` (deletes all files inside)

  Without a defined path extraction algorithm, the implementation will either be too naive (missing real deletions = false negatives, violating fail-closed) or too aggressive (blocking on benign commands = false positives causing friction).

  **Recommendation**: Define explicit extraction logic. Minimum viable approach: (1) match `git rm` or `rm` at word boundary, (2) strip known flags (`-f`, `-r`, `-rf`, `--force`, `--cached`, `--`), (3) treat remaining tokens as file paths, (4) filter to project-internal paths only. Acknowledge variable interpolation and pipeline patterns as known limitations (consistent with Proposal D's caveat in spec line 211-212).

- **[C3]** `grep -rl` caller search: filename vs path matching and self-exclusion timing (plan.md Step 1, lines 43-46)
  Severity: moderate

  The plan specifies `grep -rl` across `*.sh`, `*.md`, `*.mjs`, `*.yaml`, `*.json`, `*.py` to find callers of a deleted file. Several issues:

  1. **Search string ambiguity**: The plan does not specify whether to search for the full relative path (`plugins/cwf/skills/gather/scripts/csv-to-toon.sh`), the basename (`csv-to-toon.sh`), or both. Searching by basename produces false positives if the name is common (e.g., `utils.sh`, `config.yaml`). Searching by full relative path misses callers that use a different path form (e.g., `$SCRIPT_DIR/csv-to-toon.sh`, `./csv-to-toon.sh`, `../gather/scripts/csv-to-toon.sh`).

  2. **Self-exclusion is unnecessary for PostToolUse**: The plan says "Exclude the deleted file itself from search results." But if using PostToolUse, the file is already deleted, so `grep -rl` will not scan it. If the hook is changed to PreToolUse per C1's recommendation, the file still exists and self-exclusion becomes necessary.

  3. **`grep` exit code semantics**: `grep -rl` returns exit 0 (matches found), exit 1 (no matches), or exit 2 (error). With `set -euo pipefail`, exit 1 (no matches = no callers = safe to delete) would cause the script to terminate early. The hook must handle exit 1 as "no callers found" (safe), not as an error. This is the opposite of the fail-closed behavior needed for exit 2.

  **Recommendation**: (a) Search for both basename and known path patterns. (b) Use `grep -rl ... || true` or `set +e` around the grep call, then check the exit code explicitly (0 = callers found, 1 = no callers, 2 = error). (c) Clarify in the plan.

- **[C4]** `cwf_live_remove_list_item()`: YAML quoting inconsistency risk (plan.md Step 3, lines 88-89)
  Severity: moderate

  The plan adds `cwf_live_upsert_live_list()` and `cwf_live_remove_list_item()`. The existing `cwf_live_upsert_live_scalar()` always writes values with double-quote wrapping (line 222 of `cwf-live-state.sh`: `print "  " key ": \"" value "\""`). If `cwf_live_upsert_live_list()` writes list items **without** quotes (`- review-code`) but `cwf_live_remove_list_item()` searches for a **quoted** pattern (`- "review-code"`), or vice versa, the removal will fail silently.

  Additionally, when removing the last item from a list, the plan does not specify the resulting state. Options: (a) remove the key entirely, (b) leave `remaining_gates: []`, (c) leave `remaining_gates:` with no items (which is different from `[]` in YAML). The `workflow-gate.sh` logic (plan Step 3, item 5) checks for "empty remaining_gates" — the definition of "empty" must be consistent with the output of `cwf_live_remove_list_item()` when the last item is removed.

  **Recommendation**: (a) Establish a canonical form: either always quote list items or never quote them. (b) Define the empty-list representation and ensure `workflow-gate.sh`'s "empty" check handles all possible forms. (c) Use string equality (`==`) not regex matching (`~`) in AWK for list item removal, to avoid regex metacharacter issues with gate names containing `-`.

- **[C5]** `workflow-gate.sh` prompt keyword blocking is limited to user prompts, not agent actions (plan.md Step 3, item 2, point 4)
  Severity: moderate

  The plan specifies: "If `remaining_gates` contains `review-code` AND prompt mentions ship/push/merge: exit 1 with block message." As a UserPromptSubmit hook, this only inspects the **user's prompt text**. It cannot intercept:

  1. **Agent-initiated actions**: The agent can autonomously invoke `cwf:ship` via the Skill tool or execute `git push` via the Bash tool without the user ever mentioning "ship" or "push". This is the exact scenario from the incident: the agent decided to skip review on its own.
  2. **Indirect phrasing**: "Proceed to the next stage", "Continue the pipeline", "We're done, wrap it up" — none contain ship/push/merge keywords but could lead the agent to invoke ship.
  3. **False positives**: "Let's push the review boundaries" or "ship the design document" would trigger the block unnecessarily.
  4. **Korean prompts**: The user communicates in Korean. Keywords like "배포해", "푸시해", "머지해" would bypass English-only keyword matching.

  The advisory reminder (plan Step 3, items 3, 5, 6) is the real defense mechanism here — it fires every turn and reminds the agent of remaining gates. The keyword block (item 4) provides marginal additional value.

  **Recommendation**: (a) Acknowledge the blocking gate's limitations and document the advisory reminder as the primary defense. (b) Consider adding a complementary PreToolUse hook for the Skill tool (matcher: `ship`) and Bash tool (matching `git push|git merge|gh pr merge` in `tool_input.command`) to catch agent-initiated actions. (c) If keeping prompt keyword matching, add Korean keywords and use more specific patterns like `cwf:ship`, `git push`, `git merge`.

### Suggestions (non-blocking)

- **[S1]** `grep -rl` performance budget for Proposal A (plan.md Step 1, lines 43-46)

  Running `grep -rl` across 6 file extensions on every Bash tool call containing a deletion pattern could add 1-3 seconds of latency per deleted file. The plan excludes `.cwf/projects/` paths but should also exclude `.git/`, `node_modules/`, and any `vendor/` directories via `--exclude-dir`. The spec (line 143-144) lists `hooks.json` and `package.json` as separate search scope entries, but `*.json` already covers them — the spec's list is slightly redundant.

- **[S2]** `cwf_live_sanitize_yaml_value()` may be redundant with existing double-quoting (plan.md Step 3, line 97)

  The plan adds `cwf_live_sanitize_yaml_value()` to escape `:`, `\n`, `[`, `]` for YAML safety. However, the existing `cwf_live_upsert_live_scalar()` already wraps all values in double quotes (line 222: `print "  " key ": \"" value "\""`), and `cwf_live_escape_dq()` (lines 191-196) escapes `\` and `"`. In YAML, double-quoted strings already handle `:`, `[`, `]` safely. The only character that needs additional handling is `\n` (literal newline), which would break the line structure. The sanitizer should focus on newline replacement and be consistent with the existing `cwf_live_escape_dq()` pipeline.

- **[S3]** `state_version` as CAS mechanism is overspecified (spec line 276, plan.md Step 3)

  The spec describes `state_version` for "CAS-style stale write detection" but neither the plan nor the spec defines a compare-and-swap read cycle. The field is incremented on stage completion but never read for comparison before writes. This is effectively a monotonic audit counter, not a CAS mechanism. Recommend downgrading the description to "monotonic version counter for debugging and audit" and removing the CAS framing to avoid false confidence in concurrency safety.

- **[S4]** Stale session detection: explicit session_id sourcing (plan.md Step 3, item 2, "Recovery")

  The plan says "if `active_pipeline` exists from a previous session (different `session_id`), output cleanup prompt" but does not specify how `workflow-gate.sh` obtains the current session_id. Looking at `track-user-input.sh` (line 26), UserPromptSubmit stdin JSON includes `.session_id`. The plan should explicitly reference: `CURRENT_SESSION=$(echo "$INPUT" | jq -r '.session_id // empty')` and compare with `live.session_id` from cwf-state.yaml.

- **[S5]** Gate name enum should be defined in one canonical location (plan.md Step 3, line 98)

  The hard-coded gate name enum (`gather`, `clarify`, `plan`, `review-plan`, `impl`, `review-code`, `refactor`, `retro`, `ship`) must stay in sync with the stage definition table in `run/SKILL.md` (lines 59-69). If defined in `cwf-live-state.sh` as a bash array, it creates a coupling. Consider defining it once and sourcing it, or at minimum adding a comment citing the canonical source.

- **[S6]** `hooks.json` PostToolUse `"Bash"` matcher is a new pattern (plan.md Step 1, line 51)

  All existing PostToolUse hooks use the `"Write|Edit"` matcher. Adding a `"Bash"` matcher is structurally valid (the hooks.json format supports multiple matcher entries in each event array), but the plan should verify that the Claude Code hook runtime actually invokes PostToolUse hooks for Bash tool calls. This is an assumption. If the runtime only triggers PostToolUse for Write/Edit (the only currently registered tools), the new hook would be silently ignored.

- **[S7]** `cwf_live_validate_scalar_key()` update semantics (plan.md Step 3, lines 90-91)

  The plan says "Update `cwf_live_set_scalars()`: allow `active_pipeline`, `user_directive`, `pipeline_override_reason`, `state_version` as scalar keys." The current validator (lines 244-254 of `cwf-live-state.sh`) uses a **blocklist** pattern — it rejects known-bad keys and allows everything else. The listed new keys are **already allowed** by default. The only action needed is adding `remaining_gates` to the blocklist (since it's a list, not a scalar). The plan states this (line 90) but the phrasing at line 91 is misleading, suggesting allow-list additions are needed.

- **[S8]** Proposal B hint insertion location in check-links-local.sh (plan.md Step 2, lines 71-72)

  The plan says to "append a hint line to the reason" at "around line 82" of `check-links-local.sh`. The actual block output is at line 80 (`printf` constructing the REASON) and lines 82-84 (the JSON output). The hint must be inserted into the `printf` format string at line 80, e.g.: `printf 'Broken links detected in %s:\n%s%s\nFor triage guidance, see references/agent-patterns.md § Broken Link Triage Protocol' ...`. The plan should be more precise about the insertion point to avoid the hint appearing outside the JSON reason string.

### Behavioral Criteria Assessment

- [ ] **Proposal A: File deletion with runtime callers -> hook exits 1 with BLOCKED message** — FAILS on "deletion is prevented" semantics. PostToolUse fires after the Bash tool executes, so the file is already deleted when the hook runs. The hook can signal BLOCKED, but the deletion has already occurred. The agent would need to restore the file. See C1. The exit 1 and BLOCKED message logic itself is correct — only the timing/prevention claim fails.

- [x] **Proposal A: File deletion with no callers -> hook exits 0 silently** — Plan Step 1 (line 48) specifies exit 0 when no callers found. Logic is sound. Contingent on correct file path extraction (see C2) and correct `grep` exit code handling (see C3).

- [x] **Proposal A: grep/parse failure -> hook exits 1 (fail-closed)** — Plan Step 1 (line 47) specifies exit 1 on grep/parse error. Consistent with fail-closed safety design. Implementation must distinguish between `grep` exit 1 (no match = safe) and exit 2 (error = fail-closed). See C3 point 3.

- [x] **Proposal B: Broken link error includes triage protocol reference** — Plan Step 2 (lines 70-73) adds a hint to `check-links-local.sh` block reason output and adds the full triage protocol to `agent-patterns.md`. The existing code structure supports this cleanly. See S8 for precise insertion guidance.

- [x] **Proposal C: Triage action contradiction -> follow original recommendation** — Plan Step 4 (lines 138-141) adds "Recommendation Fidelity Check" rule to `impl/SKILL.md` Rules section. Content matches spec (spec lines 186-194). This is correctly designed as a prose rule (P1 priority), not a deterministic hook.

- [ ] **Proposal E+G: remaining_gates includes review-code + ship attempt -> hook exits 1** — PARTIAL. The UserPromptSubmit hook can only inspect user prompt text, not agent actions. If the user explicitly says "ship" or "push", the hook blocks correctly. If the agent autonomously invokes cwf:ship without the user mentioning these keywords, the hook cannot intercept. See C5. The advisory reminder (items 3, 5, 6) provides the primary defense; the blocking gate (item 4) is a secondary, keyword-dependent layer.

- [x] **Proposal E+G: Stage completion -> list-remove updates YAML list** — Plan Step 3 specifies `list-remove` CLI subcommand and `cwf_live_remove_list_item()` function. The design is sound for sequential single-writer scenarios. Implementation must handle quoting consistency (C4) and empty-list edge case.

- [x] **Proposal E+G: Stale active_pipeline -> cleanup prompt output** — Plan Step 3 item 2, "Recovery" section specifies session_id comparison and cleanup prompt. The session_id is available in UserPromptSubmit stdin JSON (confirmed via `track-user-input.sh` line 26). See S4 for implementation detail.

- [x] **Proposal E+G: active_pipeline set + empty remaining_gates -> warning output** — Plan Step 3, item 2, point 5 explicitly handles this case: "If `active_pipeline` is set but `remaining_gates` is empty: Output warning: stale pipeline state, suggest cleanup." Correct.

### Qualitative Criteria Assessment

- [x] **Hook scripts follow existing codebase conventions** — Plan references `check-links-local.sh` as template (line 39), specifies `HOOK_GROUP`, gate sourcing, stdin JSON parsing via `jq`, and `{"decision":"block","reason":...}` JSON output format. New hooks placed in `plugins/cwf/hooks/scripts/` matching existing structure.

- [x] **All new hooks are toggleable** — Plan adds `deletion_safety: true` and `workflow_gate: true` to `cwf-state.yaml` hooks section (lines 55, 128). New hooks define `HOOK_GROUP` and source `cwf-hook-gate.sh`, which checks `HOOK_{GROUP}_ENABLED` from `~/.claude/cwf-hooks-enabled.sh`. Consistent with existing toggle mechanism.

- [x] **Fail-closed behavior for safety hooks** — Proposal A: grep/parse error -> exit 1 (line 47). Proposal E+G: synchronous (not async), exit 1 on gate violation (line 104). Both default to blocking on uncertainty. This is correct for safety-critical hooks.

---

### Summary

The plan is well-structured, follows existing codebase conventions, and operationalizes the spec's proposals into concrete implementation steps. Three critical correctness concerns require resolution before implementation:

1. **C1 (PostToolUse timing)**: The most fundamental issue. PostToolUse cannot prevent deletions because the file is already gone when the hook fires. Switch to PreToolUse or reframe as recovery-with-restore.

2. **C2 (Path extraction)**: The file path extraction algorithm for deletion commands is completely unspecified. Without it, the hook cannot reliably determine which files were (or will be) deleted. This is the core logic of the hook.

3. **C5 (Prompt keyword blocking)**: The UserPromptSubmit blocking gate only catches explicit user mentions of ship/push/merge. Agent-initiated autonomous shipping (the actual incident scenario) is not intercepted. The advisory reminder is the real defense; the blocking gate should be acknowledged as secondary.

The remaining concerns (C3, C4) are moderate implementation details around grep exit code handling and YAML quoting consistency that are solvable during implementation with care.

Recommended resolution priority:
1. C1: Switch Proposal A to PreToolUse or document restore-based recovery semantics
2. C2: Define explicit file path extraction regex with test cases
3. C5: Add complementary PreToolUse hook for Skill/Bash tool to catch agent-initiated actions
4. C3: Specify grep exit code handling (0=callers, 1=none, 2=error)
5. C4: Establish canonical YAML list item quoting form and empty-list representation

### Provenance

```yaml
source: FALLBACK
tool: claude-task-fallback
reviewer: Correctness
duration_ms: —
command: —
```

<!-- AGENT_COMPLETE -->
