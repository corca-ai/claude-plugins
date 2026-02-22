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

Execute these deterministic sub-steps in order:
1. parse flags (`--mode`, `--base`, `--scenarios`, provider overrides)
2. detect review target by mode (`code`/`plan`/`clarify`) with explicit base strategy provenance
3. extract behavioral + qualitative criteria from latest plan artifacts
4. validate and merge holdout checks when `--scenarios` is provided
5. compute turn budget + CLI timeout and apply 1200-line external CLI cutoff
6. set `web_debug_scope=true` when browser-runtime evidence is required

Full commands, routing matrix, and provenance fields are in [references/target-and-routing.md](references/target-and-routing.md).

---

## Phase 2: Launch All Reviewers

Launch **six** reviewers in parallel: 2 internal (Task agents) + 2 external (CLI or Task fallback) + 2 domain experts (Task agents). Default is a **single-message launch**; when slot capacity is insufficient, split into deterministic batches after preflight.
- Shared output persistence contract: [agent-patterns.md § Sub-agent Output Persistence Contract](../../references/agent-patterns.md#sub-agent-output-persistence-contract).

### 2.0 Pre-launch setup

Before slot launch, complete deterministic pre-launch routing:
1. resolve `session_dir` and apply context-recovery validation for mode-suffixed output files
2. prepare internal/external prompts (including `web_debug_scope` browser block when required)
3. detect provider preflight and route Slot 3/4 providers
4. run agent-slot preflight (`--required 6`) and choose single-batch or deterministic multi-batch
5. resolve Slot 5/6 experts from `expert_roster` with tie-break policy

Full command templates and routing details are in [references/target-and-routing.md](references/target-and-routing.md).

### 2.3 Launch reviewers (single batch or deterministic batches)

Launch slots with mode-suffixed output persistence:
- Slot 1/2: internal Task reviewers (Security, UX/DX)
- Slot 3/4: provider-routed external reviewers (Correctness, Architecture)
- Slot 5/6: expert Task reviewers with contrasting frameworks, using identities resolved in Phase 2.2.2

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
13. **Preserve explicit decisions** — when reviewer suggestions conflict with explicit user decisions or accepted plan constraints, include them under `Considered-Not-Adopted` with reason/reference.
14. **Capacity-aware launch** — run agent-slot preflight before reviewer launch; if capacity is insufficient, use deterministic batches instead of oversubscribing.
15. **Code-mode session-log fields are mandatory** — always include deterministic `session_log_*` keys in Confidence Note for `--mode code`.
16. **Code-mode artifact gate is mandatory** — `review-code` is not complete unless `check-run-gate-artifacts.sh --stage review-code --strict` passes.
17. **Language override** — synthesis output follows the user's language; reviewer prompts remain in English.
18. **Browser-runtime claims need evidence** — when `web_debug_scope=true`, reviewers must provide reproducible browser evidence following [Web Debug Loop Protocol](../../references/agent-patterns.md#web-debug-loop-protocol).

---

## BDD Acceptance Checks

Use the canonical BDD acceptance checks from [references/synthesis-and-gates.md](references/synthesis-and-gates.md) when validating review-skill changes.

---

## References

- Internal reviewer perspectives: [references/prompts.md](references/prompts.md)
- External reviewer perspectives & CLI templates: [references/external-review.md](references/external-review.md)
- Target detection + provider/expert routing details: [references/target-and-routing.md](references/target-and-routing.md)
- Orchestration and fallback templates: [references/orchestration-and-fallbacks.md](references/orchestration-and-fallbacks.md)
- Synthesis template, error matrix, and BDD checks: [references/synthesis-and-gates.md](references/synthesis-and-gates.md)
- Agent patterns (provenance, synthesis, execution, web-debug): [agent-patterns.md](../../references/agent-patterns.md)
- Expert advisor guide (expert sub-agent identity, grounding, review format): [expert-advisor-guide.md](../../references/expert-advisor-guide.md)
