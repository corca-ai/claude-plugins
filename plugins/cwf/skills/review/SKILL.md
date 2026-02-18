---
name: review
description: "Universal review with narrative verdicts for consistent quality gates before and after implementation. 6 parallel reviewers: 2 internal (Security, UX/DX) via Task + 2 external slots via available providers (Codex/Gemini CLI, Claude Task fallback) + 2 domain experts via Task. Graceful fallback when CLIs are unavailable. Modes: --mode clarify/plan/code. Triggers: \"/review\""
---

# Review (/review)

Apply consistent multi-perspective quality gates before implementation (plan) and after implementation (code) via 6 parallel reviewers (2 internal + 2 external slots + 2 domain experts).

## Quick Reference

```text
/review                 Code review (default)
/review --mode plan     Plan/spec review
/review --mode clarify  Requirement review
/review --mode code --base <base-branch> --scenarios .cwf/projects/holdout.md
/review --mode code --correctness-provider gemini --architecture-provider claude
```

Recommended linkage:
- `cwf:plan` → `cwf:review --mode plan` before `cwf:impl`
- `cwf:impl` → `cwf:review --mode code` before `cwf:ship`

## External CLI Setup (one-time)

For full 4-reviewer coverage, authenticate external CLIs:

```bash
codex auth login          # OpenAI Codex
npx @google/gemini-cli    # Google Gemini (interactive first-run setup)
```

Both are optional — the skill falls back to Claude Task agents when CLIs are missing or unauthenticated. But real CLI reviews provide diverse model perspectives beyond Claude.

**Fallback latency**: If both external CLIs fail, the skill incurs a two-round-trip penalty — first the CLI attempts run (up to {cli_timeout}s timeout each, scaled by prompt size), then fallback Task agents are launched sequentially. Error-type classification (Phase 3.2) enables fail-fast for CAPACITY errors, reducing wasted time.

## Mode Routing

| Input | Mode |
|-------|------|
| No args or `--mode code` | Code review |
| `--mode plan` | Plan review |
| `--mode clarify` | Clarify review |
| `--human` | Route to `cwf:hitl` (do not run review; invoke hitl skill directly) |

Default: `--mode code`.

When `--human` is detected (with or without `--mode`), stop review processing and invoke `cwf:hitl` instead, passing through any `--base` flag. This routes the F-8 alias declared in hitl's triggers.

---

## Phase 1: Gather Review Target

### 1. Parse mode flag

Extract flags from user input:

- `--mode` (default: `code`)
- `--base <branch>` (optional, code mode only)
- `--scenarios <path>` (optional holdout scenarios file)
- `--correctness-provider <auto|codex|gemini|claude>` (optional, default: `auto`)
- `--architecture-provider <auto|gemini|codex|claude>` (optional, default: `auto`)

### 2. Detect review target

Automatically detect what to review based on mode:

**--mode code:**

Try in order (first non-empty wins):

1. Resolve base strategy:
   - If `--base <branch>` is provided:
     - Verify branch exists locally (`refs/heads/{branch}`) or in origin (`refs/remotes/origin/{branch}`).
     - If only remote exists, use `origin/{branch}`.
     - If neither exists: stop with explicit error and ask user for a valid branch.
     - Record `base_strategy: explicit (--base)`.
   - If `--base` is not provided:
     - First try upstream-aware detection:
       `git rev-parse --abbrev-ref --symbolic-full-name @{upstream} 2>/dev/null`
     - If upstream exists, use it and record `base_strategy: upstream`.
     - Otherwise fallback to `main`, `master`, then default remote branch
       (`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'`)
       and record `base_strategy: fallback`.
2. Branch diff vs resolved base:
   `git diff $(git merge-base HEAD {resolved_base})..HEAD`
   - Only if current branch differs from the detected base branch
3. Staged changes: `git diff --cached`
4. Last commit: `git show HEAD`
5. Store review-target provenance for synthesis:
   - `resolved_base`
   - `base_strategy`
   - `diff_range` (when branch diff path is used)

If all empty, ask user with AskUserQuestion.

**--mode plan:**

1. Search for the most recent plan file:
   ```bash
   ls -td .cwf/projects/*/plan.md 2>/dev/null | head -1
   ```
2. If not found, check `.cwf/projects/*/master-plan.md`
3. If not found, ask user with AskUserQuestion

**--mode clarify:**

1. Search for recent clarification artifacts:
   ```bash
   ls -td .cwf/projects/*/clarify-result.md 2>/dev/null | head -1
   ```
2. If not found, ask user with AskUserQuestion

### 3. Extract behavioral/qualitative criteria

Search the associated plan.md for success criteria to use as verification input:

1. Find the most recent `.cwf/projects/*/plan.md` by modification time
2. Extract **behavioral criteria** — look for Given/When/Then patterns or
   checkbox-style success criteria. These become a pass/fail checklist.
3. Extract **qualitative criteria** — narrative criteria like "should be
   intuitive" or "maintain backward compatibility". These are addressed in the narrative verdict.
4. If no plan.md or no criteria found: proceed without criteria.
   Note in synthesis: "No success criteria found — review based on general best practices only."

### 4. Optional holdout scenarios (`--scenarios <path>`)

When `--scenarios` is provided:

1. Validate the file path exists, is readable, and is non-empty.
2. Parse holdout checks from one of:
   - Given/When/Then blocks
   - checklist items (`- [ ]` / `- [x]`)
3. If the file is missing/invalid or contains zero parseable checks:
   stop with an explicit error (do not silently ignore).
4. Merge parsed holdout checks into the review checklist as a separate
   "holdout" set (distinct from plan-derived behavioral criteria).
5. Record holdout provenance:
   - `holdout_path`
   - `holdout_count`

---

### 5. Measure review target size and set turn budget

Measure the review target size to determine agent turn budgets:

```bash
# For code mode: count diff lines
diff_lines=$(echo "$review_target" | wc -l)
```

**Turn budget scaling** (applies to all Task agents in Phase 2):

| Diff lines | `max_turns` | Rationale |
|------------|-------------|-----------|
| < 500 | 12 | Standard budget for small changes |
| 500–2000 | 20 | Extended for medium diffs |
| > 2000 | 28 | Large diffs need exploration + writing |

For `--mode plan` and `--mode clarify`, use the document line count instead of diff lines. Store the resolved `max_turns` value for use in Phase 2.

**CLI timeout scaling** (applies to external CLI invocations in Phase 2):

| Prompt lines | `cli_timeout` | Rationale |
|-------------|---------------|-----------|
| < 300 | 120 | Standard timeout for small/medium reviews |
| 300–800 | 180 | Extended for plan reviews with spec documents |
| > 800 | 240 | Large reviews (multi-file diffs, complex plans) |

Store the resolved `cli_timeout` value for use in Phase 2.

**External CLI cutoff (deterministic):**

- Compute `prompt_lines` from the final external prompt content (same basis used for timeout scaling).
- If `prompt_lines > 1200`, set:
  - `external_cli_allowed=false`
  - `external_cli_cutoff_reason=prompt_lines_gt_1200`
  - `external_cli_cutoff_value=1200`
- When `external_cli_allowed=false`, skip external CLI detection/attempts and route Slot 3/4 directly to `claude` Task fallbacks.
- Persist the cutoff evidence in synthesis Confidence Note:
  - `External CLI skipped: prompt_lines={prompt_lines} cutoff=1200 reason=prompt_lines_gt_1200`

---

## Phase 2: Launch All Reviewers

Launch **six** reviewers in parallel: 2 internal (Task agents) + 2 external (CLI or Task fallback) + 2 domain experts (Task agents). All launched in a **single message** for maximum parallelism.
- Shared output persistence contract: [agent-patterns.md § Sub-agent Output Persistence Contract](../../references/agent-patterns.md#sub-agent-output-persistence-contract).

### 2.0 Resolve session directory and context recovery

Resolve the effective live-state file, then read `live.dir`.

```bash
live_state_file=$(bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh resolve)
```

```yaml
session_dir: "{live.dir value from resolved live-state file}"
mode_suffix: "{mode}"  # "code", "plan", or "clarify"
```

**Mode-namespaced output files**: All review output files include the mode as a suffix to prevent filename collisions between review rounds (e.g., `review-plan` followed by `review-code` in the same session). The suffix is the `--mode` value.

Apply the [context recovery protocol](../../references/context-recovery-protocol.md) to these files:

| Slot | Reviewer | Output file |
|------|----------|-------------|
| 1 | Security | `{session_dir}/review-security-{mode}.md` |
| 2 | UX/DX | `{session_dir}/review-ux-dx-{mode}.md` |
| 3 | Correctness | `{session_dir}/review-correctness-{mode}.md` |
| 4 | Architecture | `{session_dir}/review-architecture-{mode}.md` |
| 5 | Expert α | `{session_dir}/review-expert-alpha-{mode}.md` |
| 6 | Expert β | `{session_dir}/review-expert-beta-{mode}.md` |

Skip to Phase 3 if all 6 files are valid. In recovery mode (all files cached), skip Phase 2.1–2.3 entirely — proceed directly to Phase 3. Note that temp-dir metadata (`{tmp_dir}/*-meta.txt`) will not exist in recovery; use `duration_ms: —` and `source: CACHED` in provenance for recovered slots. All 6 review output files are **critical outputs** for review synthesis.

### 2.1 Prepare prompts

For **internal** reviewers (Security, UX/DX):

1. Read `{SKILL_DIR}/references/prompts.md`
2. Extract the reviewer's Role section + mode-specific checklist
3. Build prompt:

```text
You are conducting a {mode} review as the {reviewer_name}.

## Your Role
{role section from prompts.md}

## Review Focus ({mode})
{mode-specific checklist from prompts.md}

## Review Target
{the diff, plan content, or clarify artifact}

## Success Criteria to Verify
{behavioral criteria + holdout checks as checklist, qualitative criteria as narrative items}
(If none: "No specific success criteria provided. Review based on general best practices.")

## Output Format
{output format section from prompts.md}

IMPORTANT:
- Be specific. Reference exact files, lines, sections.
- Distinguish Concerns (blocking) from Suggestions (non-blocking).
- If success criteria are provided, assess each one in the Behavioral Criteria Assessment.
- Include the Provenance block at the end.
```

For **external** reviewer slots (Correctness, Architecture):

1. Read `{SKILL_DIR}/references/external-review.md`
2. Extract the reviewer's Role section + mode-specific checklist
3. Create temp dir: `mktemp -d /tmp/claude-review-XXXXXX`
4. Write prompt files to temp dir: `correctness-prompt.md` and `architecture-prompt.md`
   - Same structure as internal prompts (role + mode checklist + review target + criteria)
   - These are perspective prompts, not provider-bound prompts.
   - Use the **external provenance format** from `external-review.md` (includes `duration_ms`, `command`)

### 2.2 Detect provider availability and route external slots

Single Bash call to check both:

```bash
command -v codex && echo CODEX_FOUND; command -v npx && echo NPX_FOUND
```

Parse the output:
- Contains `CODEX_FOUND` → Codex CLI binary exists (auth assumed OK)
- Contains `NPX_FOUND` → npx exists, Gemini CLI *may* be available

Note: `NPX_FOUND` only confirms npx is installed, not that Gemini CLI is authenticated or cached. Runtime failures are handled in Phase 3.2.

If `external_cli_allowed=false` (from the 1200-line cutoff), skip detection and set both slots to `claude`.

Otherwise, resolve providers for external slots:

- Slot 3 (Correctness):
  - `--correctness-provider auto` → prefer `codex`, then `gemini`, then `claude`
  - explicit `codex` / `gemini` / `claude` overrides auto
- Slot 4 (Architecture):
  - `--architecture-provider auto` → prefer `gemini`, then `codex`, then `claude`
  - explicit `gemini` / `codex` / `claude` overrides auto

Provider semantics:
- `codex` / `gemini`: run external CLI for that slot
- `claude`: run Task fallback directly for that slot (no CLI attempt)

### 2.3 Launch all 6 in ONE message

Launch all 6 slots in one message with mode-suffixed output persistence:
- Slot 1/2: internal Task reviewers (Security, UX/DX)
- Slot 3/4: provider-routed external reviewers (Correctness, Architecture)
- Slot 5/6: expert Task reviewers with contrasting frameworks

Required invariants:
- Every slot writes `{session_dir}/review-*-{mode}.md` and appends `<!-- AGENT_COMPLETE -->`.
- External CLI success copies output into session file before synthesis.
- Use stdin prompt redirection for external CLI execution to avoid prompt-shell injection.

Full slot command templates and persistence snippets are in [references/orchestration-and-fallbacks.md](references/orchestration-and-fallbacks.md).

---

## Phase 3: Collect All Outputs

### 3.1 Read all results from session directory

Read review verdicts from the session directory files (not in-memory return values):

| Slot | File |
|------|------|
| 1 | `{session_dir}/review-security-{mode}.md` |
| 2 | `{session_dir}/review-ux-dx-{mode}.md` |
| 3 | `{session_dir}/review-correctness-{mode}.md` |
| 4 | `{session_dir}/review-architecture-{mode}.md` |
| 5 | `{session_dir}/review-expert-alpha-{mode}.md` |
| 6 | `{session_dir}/review-expert-beta-{mode}.md` |

Re-validate all six files with the context recovery protocol before synthesis. If any file remains invalid after one bounded retry, apply a **hard fail** for the stage and stop with explicit file-level error. Report the gate path explicitly (`PERSISTENCE_GATE=HARD_FAIL` or equivalent).

For external slot executions, also read metadata from temp dir:
- `{tmp_dir}/slot3-meta.txt` / `{tmp_dir}/slot4-meta.txt` for provider tool, exit code, and duration
- `{tmp_dir}/slot3-stderr.log` / `{tmp_dir}/slot4-stderr.log` for error details

For successful external reviews, **override** the provenance `duration_ms` with the actual value from the meta file (not any value the CLI may have generated). Use the actual command executed for the `command` field.

### 3.2 Handle external failures

Apply the deterministic failure flow:
1. classify stderr error type first (capacity/internal/auth/tool-error)
2. then apply exit-code fallback policy when no classifier matched
3. extract actionable cause text for Confidence Note
4. launch all required fallback Task agents in one message

Detailed classifier matrix, exit-code table, and fallback templates are in [references/orchestration-and-fallbacks.md](references/orchestration-and-fallbacks.md).

### 3.3 Assemble 6 review outputs

Collect all 6 outputs from session directory files (mix of `REAL_EXECUTION` and `FALLBACK` sources). Internal reviewers and expert reviewers follow the standard reviewer output format from `prompts.md`. Expert reviewers follow the review mode format from `expert-advisor-guide.md`.

### 3.4 Session-log cross-check (code mode)

When `--mode code`, perform a deterministic session-log cross-check before synthesis.

Before reading session-log artifacts, run a best-effort Codex sync:

```bash
bash {CWF_PLUGIN_DIR}/scripts/codex/sync-session-logs.sh --cwd "$PWD" --quiet || true
```

Inputs:

- Newest `session-logs/*.md`

Required output fields (for Confidence Note):

- `session_log_present`: `true|false`
- `session_log_lines`: integer (`0` when missing)
- `session_log_turns`: integer count of `^## Turn`
- `session_log_last_turn`: last `## Turn` header or `none`
- `session_log_cross_check`: `PASS|WARN`

Policy:

- If no session log exists, set `session_log_cross_check=WARN` and continue.
- Do not omit these fields in code mode.

---

## Phase 4: Synthesize

### 1. Determine verdict

Apply these rules in order (reviewer-count-agnostic — works with 2, 3, or 4 reviewers):

| Condition | Verdict |
|-----------|---------|
| Any unchecked behavioral criterion | **Revise** |
| Any Concern with severity `critical` or `security` | **Revise** |
| Any Concern with severity `moderate` | **Conditional Pass** |
| Only Suggestions or no issues found | **Pass** |

Conservative default: when reviewers disagree, the stricter assessment wins.

### 2. Render Review Synthesis

Output synthesis to the conversation **and** persist `{session_dir}/review-synthesis-{mode}.md`.

Synthesis must include:
- verdict summary
- behavioral criteria/holdout assessment (when provided)
- concerns and suggestions
- commit boundary guidance for tidy vs behavior-policy splits
- confidence note (including base strategy, fallback causes, and session-log fields in code mode)
- reviewer provenance table

Use the full markdown template from [references/synthesis-and-gates.md](references/synthesis-and-gates.md).

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

Use the deterministic error-handling matrix in [references/synthesis-and-gates.md](references/synthesis-and-gates.md), including scenario/base validation failures, external prompt cutoff behavior, fallback routing, and code-mode artifact/session-log gate outcomes.

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
13. **Code-mode session-log fields are mandatory** — always include deterministic `session_log_*` keys in Confidence Note for `--mode code`.
14. **Code-mode artifact gate is mandatory** — `review-code` is not complete unless `check-run-gate-artifacts.sh --stage review-code --strict` passes.
15. **Language override** — synthesis output follows the user's language; reviewer prompts remain in English.

---

## BDD Acceptance Checks

Use the canonical BDD acceptance checks from [references/synthesis-and-gates.md](references/synthesis-and-gates.md) when validating review-skill changes.

---

## References

- Internal reviewer perspectives: [references/prompts.md](references/prompts.md)
- External reviewer perspectives & CLI templates: [references/external-review.md](references/external-review.md)
- Orchestration and fallback templates: [references/orchestration-and-fallbacks.md](references/orchestration-and-fallbacks.md)
- Synthesis template, error matrix, and BDD checks: [references/synthesis-and-gates.md](references/synthesis-and-gates.md)
- Agent patterns (provenance, synthesis, execution): [agent-patterns.md](../../references/agent-patterns.md)
- Expert advisor guide (expert sub-agent identity, grounding, review format): [expert-advisor-guide.md](../../references/expert-advisor-guide.md)
