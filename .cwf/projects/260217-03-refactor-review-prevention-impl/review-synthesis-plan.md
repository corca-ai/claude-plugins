## Review Synthesis

### Verdict: Revise

Two behavioral criteria fail and multiple critical-severity concerns converge across 4-6 reviewers. The plan's core architecture is sound, but Proposal A's hook timing and command parsing require revision before implementation can proceed.

### Behavioral Criteria Verification

- [ ] **Proposal A: File deletion with runtime callers -> hook exits 1 with BLOCKED** — **Security, Correctness, Expert α, Architecture**: PostToolUse fires after deletion; "prevention" is factually impossible. The hook detects but cannot undo. BDD criterion "the deletion is prevented" is inaccurate.
- [x] **Proposal A: File deletion with no callers -> hook exits 0 silently** — All 6 reviewers: correctly specified.
- [x] **Proposal A: grep/parse failure -> hook exits 1 (fail-closed)** — All 6 reviewers: correctly specified. Correctness notes `grep` exit code 1 (no match) vs 2 (error) distinction needs explicit handling.
- [x] **Proposal B: Broken link error includes triage protocol reference** — All 6 reviewers: correctly specified. UX/DX and Correctness note precise insertion point (inside printf format string at line 80).
- [x] **Proposal C: Triage action contradiction -> follow original recommendation** — All 6 reviewers: correctly specified as prose rule. Expert β (Deming): weakest proposal, should be marked as stopgap.
- [ ] **Proposal E+G: remaining_gates includes review-code + ship attempt -> hook exits 1** — **Correctness, Expert α**: UserPromptSubmit only inspects user prompt text. Agent-initiated `cwf:ship` or `git push` (the actual incident scenario) is not intercepted. Advisory reminder is the real defense; keyword block is secondary.
- [x] **Proposal E+G: Stage completion -> list-remove updates YAML list** — All 6 reviewers: correctly specified. Correctness notes quoting consistency and empty-list edge case need specification.
- [x] **Proposal E+G: Stale active_pipeline -> cleanup prompt output** — All 6 reviewers: correctly specified. Multiple reviewers note session_id sourcing from stdin JSON should be made explicit.
- [x] **Proposal E+G: active_pipeline set + empty remaining_gates -> warning output** — All 6 reviewers: correctly specified.

### Concerns (must address)

- **Security, Correctness, Expert α (Leveson), Architecture** [critical]: **PostToolUse cannot prevent deletions.** Switch Proposal A to PreToolUse with `{"decision":"deny"}` on `tool_input.command`, or keep PostToolUse but (a) reframe BDD criterion to "detection + forced restore", (b) include `git checkout HEAD -- {file}` in block message. Plan's own Decision Log #1 supports PreToolUse.

- **Security, Correctness, UX/DX, Architecture** [critical]: **`rm ` pattern matching is contradictory and path extraction is unspecified.** The plan says trailing space avoids `rm -rf node_modules` but `rm -rf` starts with `rm `. Need explicit regex patterns and a path extraction algorithm (strip flags, treat remaining tokens as paths). Acknowledge pipe/variable-interpolation patterns as known limitations per Proposal D.

- **Security** [security]: **YAML sanitization integration gap.** `cwf_live_sanitize_yaml_value()` must be integrated into the write path (`cwf_live_upsert_live_scalar`), not left as orphan utility. User_directive containing `: ` or `\n` could corrupt YAML state and cause workflow-gate.sh to malfunction.

- **UX/DX** [moderate]: **hooks.json structure for workflow-gate.sh unspecified.** Must clarify whether sync `workflow-gate.sh` shares the empty-matcher array with async `track-user-input.sh` or gets a new matcher entry.

- **Correctness, Expert α** [moderate]: **Keyword-based ship/push detection is brittle and incomplete.** Doesn't catch agent-initiated actions, Korean prompts, or indirect phrasing. Consider complementary PreToolUse hook for Skill/Bash matching `cwf:ship`, `git push`, `gh pr merge`.

- **Architecture** [moderate]: **Synchronous hook latency on every prompt.** workflow-gate.sh must specify a fast-exit path when `active_pipeline` is absent (the common case for non-cwf:run sessions).

- **UX/DX** [moderate]: **cwf-live-state.sh help/usage not updated** for `list-set`/`list-remove` subcommands.

- **Architecture** [moderate]: **Step 3 scope is too large for a single commit.** Consider splitting into (3a) list operations in cwf-live-state.sh, (3b) workflow-gate.sh + registration.

- **Correctness** [moderate]: **grep exit code handling unspecified.** Must distinguish exit 1 (no match = safe) from exit 2 (error = fail-closed). `set -euo pipefail` would terminate on exit 1.

- **Correctness** [moderate]: **YAML list quoting consistency and empty-list representation.** Must establish canonical form (quoted vs unquoted items) and define behavior when last item is removed.

- **Expert β (Deming)** [moderate]: **Grep-based detection boundary not documented.** Variable interpolation (`"$SCRIPT_DIR/csv-to-toon.sh"`) will be missed. Must document as known limitation.

- **Expert β (Deming)** [moderate]: **Hard-coded gate enum creates maintenance coupling.** Must document sync requirement with `run/SKILL.md` Stage Definition table.

### Suggestions (optional improvements)

- **Expert α**: Add `git checkout HEAD -- {file}` restore instruction to Proposal A block message
- **Expert α**: Specify `state_version` conflict resolution behavior (currently undefined)
- **Expert α**: Add `list-get` subcommand for consistent list read path
- **Expert α**: Document interaction between Proposal A block and E+G pipeline state
- **Expert β**: Mark Proposal C as explicit stopgap with structural fix noted (triage format change)
- **Expert β**: Test Korean text in `user_directive` YAML sanitization
- **Architecture, Correctness**: YAML sanitization may be redundant with existing double-quoting — focus on newline handling only
- **Architecture, Expert β, Correctness**: Gate name enum should reference `run/SKILL.md` as single source of truth
- **Architecture, UX/DX, Correctness**: Explicitly specify `session_id` parsing from UserPromptSubmit stdin JSON
- **UX/DX, Architecture**: `list-remove` idempotency should be specified (recommend: idempotent, silent success)
- **UX/DX**: Use `[WARNING]` text prefix instead of emoji in hook output for consistent rendering
- **Correctness**: `state_version` is a monotonic counter, not CAS — simplify description
- **Correctness**: Verify PostToolUse hooks actually fire for `"Bash"` matcher in Claude Code runtime

### Commit Boundary Guidance

If addressing concerns in plan revision:
- `tidy`: help/usage update, documentation of grep detection boundary, gate enum source-of-truth comment, emoji to text prefix
- `behavior-policy`: PreToolUse switch, path extraction algorithm, YAML sanitization integration, hooks.json structure, keyword detection enhancement, fast-exit path, grep exit code handling, list quoting canonicalization

### Confidence Note

- **Disagreements**: Correctness reviewer fails BDD #1 and #6; other reviewers pass at spec level with concerns noted. Stricter assessment applied per conservative default.
- **Expert frameworks converge**: Leveson (STAMP: control action provided too late) and Deming (Point 3: build quality into process, not inspection after) both support PreToolUse over PostToolUse.
- **Base**: N/A (plan mode, not code mode)
- Slot 3 (codex) FAILED -> fallback. Cause: exit 124, timeout at 120s. Codex -> `codex auth login`.
- Slot 4 (gemini) FAILED -> fallback. Cause: exit 124, timeout at 120s. Gemini -> `npx @google/gemini-cli`.
- Both fallback agents used claude-task-fallback. Perspective coverage is maintained but model diversity is reduced.

### Reviewer Provenance

| Reviewer | Source | Tool | Duration |
|----------|--------|------|----------|
| Security | REAL_EXECUTION | claude-task | — |
| UX/DX | REAL_EXECUTION | claude-task | — |
| Correctness | FALLBACK | claude-task-fallback | — |
| Architecture | FALLBACK | claude-task-fallback | — |
| Expert α (Leveson) | REAL_EXECUTION | claude-task | — |
| Expert β (Deming) | REAL_EXECUTION | claude-task | — |
