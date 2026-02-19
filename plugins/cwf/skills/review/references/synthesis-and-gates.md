# Synthesis, Error Handling, and BDD Gates

Detailed `review` procedure for:
- Phase 4.2 synthesis template
- Error handling matrix
- BDD acceptance checks

`SKILL.md` keeps summary-level gate declarations and links to this file for full templates.

## 2. Render Review Synthesis

Output to the conversation **and** persist to `{session_dir}/review-synthesis-{mode}.md`:

```markdown
## Review Synthesis

### Verdict: {Pass | Conditional Pass | Revise}
{1-2 sentence summary of overall assessment}

### Behavioral Criteria Verification
(Only if criteria were extracted from plan and/or holdout scenarios)
- [x] {criterion} — {reviewer}: {evidence}
- [ ] {criterion} — {reviewer}: {reason for failure}

### Holdout Scenario Assessment
(Only when `--scenarios <path>` is provided)
- [x] {holdout scenario/check} — {reviewer}: {evidence}
- [ ] {holdout scenario/check} — {reviewer}: {reason for failure}

### Concerns (must address)
- **{reviewer}** [{severity}]: {concern description}
  {specific reference: file, line, section}

(If none: "No blocking concerns.")

### Suggestions (optional improvements)
- **{reviewer}**: {suggestion description}

(If none: "No suggestions.")

### Considered-Not-Adopted
(Only when reviewer requests conflict with explicit user decisions or accepted plan constraints)
- **{reviewer}**: {suggestion summary}
  Reason not adopted: {explicit decision/constraint reference}

(If none: "No considered-not-adopted items.")

### Commit Boundary Guidance
(Only when follow-up implementation is requested after this review)
- `tidy`: structural/readability-only changes with no behavior or policy effect
- `behavior-policy`: runtime behavior changes, validation logic, workflow/policy enforcement updates
- If both categories exist, split work into separate commit units:
  1. `tidy` commit(s) first
  2. `behavior-policy` commit(s) second
- After completing the first unit, run `git status --short`, confirm the next boundary, then commit before starting the next major unit.

### Confidence Note
{Note any of the following:}
- Disagreements between reviewers and which side was chosen
- Areas where reviewer confidence was low
- Malformed reviewer outputs that required interpretation
- Missing success criteria (if no plan was found)
- Base strategy used for code review target:
  "Base: {resolved_base} ({base_strategy})"
- Holdout scenario source:
  "`--scenarios {holdout_path}` ({holdout_count} checks)"
- External CLI fallbacks used, with extracted error cause from stderr:
  "Slot N ({tool}) FAILED → fallback. Cause: {extracted_error}"
  Include setup hint based on failed provider:
  "Codex -> `codex auth login`; Gemini -> `npx @google/gemini-cli`."
- Perspective differences between real CLI output and fallback interpretation
- Suggestions deliberately not adopted due to explicit user decision or approved plan constraints:
  "Considered-not-adopted: {item} — {reason/reference}"
- Session-log cross-check fields (code mode):
  - `session_log_present: {true|false}`
  - `session_log_lines: {int}`
  - `session_log_turns: {int}`
  - `session_log_last_turn: {header|none}`
  - `session_log_cross_check: {PASS|WARN}`

### Reviewer Provenance
| Reviewer | Source | Tool | Duration |
|----------|--------|------|----------|
| Security | REAL_EXECUTION | claude-task | — |
| UX/DX | REAL_EXECUTION | claude-task | — |
| Correctness | {REAL_EXECUTION / FALLBACK} | {slot3_tool / claude-task-fallback} | {duration_ms} |
| Architecture | {REAL_EXECUTION / FALLBACK} | {slot4_tool / claude-task-fallback} | {duration_ms} |
| Expert Alpha | REAL_EXECUTION | claude-task | — |
| Expert Beta | REAL_EXECUTION | claude-task | — |
```

The Provenance table adapts to actual results: if an external CLI succeeded, show `REAL_EXECUTION` with the CLI tool name and measured duration. If it fell back, show `FALLBACK` with `claude-task-fallback`.

### 3. Expert Roster Update

When expert reviewers (Slot 5-6) were used: Follow the Roster Maintenance procedure in `{CWF_PLUGIN_DIR}/references/expert-advisor-guide.md`.

### 4. Run-Stage Artifact Gate (code mode)

When `--mode code`, validate deterministic stage artifacts immediately after synthesis persistence:

```bash
bash {CWF_PLUGIN_DIR}/scripts/check-run-gate-artifacts.sh \
  --session-dir "{session_dir}" \
  --stage review-code \
  --strict \
  --record-lessons
```

If this gate fails, stop with file-level errors and require revision before marking review-code complete.

### 5. Cleanup

After rendering the synthesis, remove the temp directory:

```bash
rm -rf {tmp_dir}
```

This prevents sensitive review content (diffs, plans) from persisting in `/tmp/`.

---

## Error Handling

| Situation | Action |
|-----------|--------|
| No review target found | AskUserQuestion: "What should I review?" |
| Reviewer output malformed | Extract by pattern matching, note in Confidence Note |
| External prompt lines > 1200 | Skip external CLIs for Slot 3/4, use Task fallbacks directly, and record cutoff evidence in Confidence Note. |
| `--scenarios <path>` file missing/unreadable | Stop with explicit error. Ask for a valid scenarios path. |
| `--scenarios <path>` has zero parseable checks | Stop with explicit error. Ask for GWT/checklist-formatted scenarios. |
| `--base <branch>` not found in local/origin refs | Stop with explicit error. Ask for a valid base branch. |
| No git changes found (code mode) | AskUserQuestion: ask user to specify target |
| No plan.md found | AskUserQuestion: ask user to specify target |
| All 6 reviewers report no issues | Verdict = Pass. Note "clean review" in synthesis |
| Configured external provider unavailable | Ask whether to install/configure now (recommended), retry once if approved, otherwise route per fallback policy (`auto` chain or explicit `claude`). |
| External CLI timeout (120s) | Mark `FAILED`. Spawn Task agent fallback. Note in Confidence Note. |
| External CLI auth error | Mark `FAILED`. Spawn Task agent fallback. Note in Confidence Note. |
| External output malformed | Extract by pattern matching. Note in Confidence Note. |
| Code mode and session log missing | Continue with `session_log_cross_check=WARN` and include deterministic session-log fields in Confidence Note. |
| Code mode artifact gate fails | Stop with explicit file-level errors from `check-run-gate-artifacts.sh` and request revision. |

---

## Rules

1. **Always run ALL 6 reviewers** — deliberate naivete. Never skip a reviewer
   because the change "looks simple." Each perspective catches different issues. Expert reviewers complement, not replace — the 4 core reviewers always run.
2. **Narrative only** — no numerical scores, no percentages, no letter grades.
   Verdicts are Pass / Conditional Pass / Revise.
3. **Never inline review** — always use Task sub-agents. The main agent
   synthesizes but does not review directly.
4. **Conservative default** — stricter reviewer determines the verdict when
   reviewers disagree.
5. **Output to conversation + persist** — review synthesis is both communication and downstream input. Always write `{session_dir}/review-synthesis-{mode}.md` alongside the conversation output so retro/handoff can consume it.
6. **Criteria from plan** — review verifies plan criteria, it does not
   invent its own. If no criteria exist, review on general best practices and note the absence.
7. **Graceful degradation** — external CLI failure (missing binary,
   timeout, auth error) never blocks the review. Fall back to a Task sub-agent with the same perspective. Always record the fallback in the Provenance table and Confidence Note.
8. **Missing dependency interaction** — when failures are caused by missing tools/auth, ask whether to install/configure now before final fallback-only completion.
9. **No silent holdout bypass** — when `--scenarios` is provided, the
   scenario file must be validated and assessed. Never downgrade to "best effort" silently.
10. **Base strategy must be explicit in output** — for code mode, always
   report which base path was used (explicit `--base`, upstream, or fallback).
11. **Critical reviewer outputs hard-fail** — if any required review file
    remains invalid after bounded retry, stop synthesis with explicit file-level error.
12. **Commit-boundary split for mixed follow-up work** — when review findings
    imply both `tidy` and `behavior-policy` changes, recommend separate commit
    units and `tidy` first.
13. **Preserve explicit decisions** — when a reviewer suggestion conflicts with
    explicit user decisions or accepted plan constraints, list it under
    `Considered-Not-Adopted` with concrete reason/reference instead of silently dropping.
14. **Code-mode session-log fields are mandatory** — always include deterministic `session_log_*` keys in Confidence Note for `--mode code`.
15. **Code-mode artifact gate is mandatory** — `review-code` is not complete unless `check-run-gate-artifacts.sh --stage review-code --strict` passes.

---

## BDD Acceptance Checks

Use these checks when validating updates to this skill:

```gherkin
Given a review invocation with --scenarios and a valid GWT/checklist file
When /review runs
Then holdout checks are included in reviewer prompts and synthesis with path/count provenance

Given a review invocation with --scenarios pointing to a missing file
When /review runs
Then the review stops with an explicit validation error instead of silently continuing

Given a review invocation with --mode code and no --base
When the current branch has an upstream
Then /review uses the upstream branch as base and records base_strategy=upstream

Given a review invocation with --mode code --base <branch>
When <branch> exists
Then /review deterministically uses that base and records base_strategy=explicit (--base)

Given review findings include both structural tidy changes and behavior-policy changes
When /review renders synthesis
Then the synthesis includes commit-boundary guidance to split tidy and behavior-policy commits

Given a reviewer suggestion conflicts with an explicit user decision
When /review renders synthesis
Then the suggestion is listed under Considered-Not-Adopted with reason/reference

Given a review target whose external prompt length is 1201 lines
When /review resolves external reviewer routing
Then Slot 3 and Slot 4 skip CLI execution and run Task fallback directly
And synthesis confidence note includes the deterministic cutoff evidence
```
