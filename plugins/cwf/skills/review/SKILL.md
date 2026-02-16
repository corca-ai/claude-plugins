---
name: review
description: "Universal review with narrative verdicts for consistent quality gates before and after implementation. 6 parallel reviewers: 2 internal (Security, UX/DX) via Task + 2 external slots via available providers (Codex/Gemini CLI, Claude Task fallback) + 2 domain experts via Task. Graceful fallback when CLIs are unavailable. Modes: --mode clarify/plan/code. Triggers: \"/review\""
---

# Review (/review)

Apply consistent multi-perspective quality gates before implementation (plan) and after implementation (code) via 6 parallel reviewers (2 internal + 2 external slots + 2 domain experts).

**Language**: Match the user's language for synthesis. Reviewer prompts in English.

## Quick Reference

```text
/review                 Code review (default)
/review --mode plan     Plan/spec review
/review --mode clarify  Requirement review
/review --mode code --base marketplace-v3 --scenarios .cwf/projects/holdout.md
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

**Fallback latency**: If both external CLIs fail, the skill incurs a two-round-trip penalty — first the CLI attempts run (up to 120s timeout each), then fallback Task agents are launched sequentially. Error-type classification (Phase 3.2) enables fail-fast for CAPACITY errors, reducing wasted time.

## Mode Routing

| Input | Mode |
|-------|------|
| No args or `--mode code` | Code review |
| `--mode plan` | Plan review |
| `--mode clarify` | Clarify review |

Default: `--mode code`.

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

---

## Phase 2: Launch All Reviewers

Launch **six** reviewers in parallel: 2 internal (Task agents) + 2 external (CLI or Task fallback) + 2 domain experts (Task agents). All launched in a **single message** for maximum parallelism.

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

Resolve providers for external slots:

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

All 6 reviewers launch in a single message for parallel execution:

**Slot 1 — Security (always Task):**

```text
Task(subagent_type="general-purpose", name="security-reviewer", max_turns={max_turns}, prompt="
  {security_prompt}

  ## Output Persistence
  Write your complete review verdict to: {session_dir}/review-security-{mode}.md
  At the very end of the file, append this sentinel marker on its own line:
  <!-- AGENT_COMPLETE -->
")
```

**Slot 2 — UX/DX (always Task):**

```text
Task(subagent_type="general-purpose", name="uxdx-reviewer", max_turns={max_turns}, prompt="
  {uxdx_prompt}

  ## Output Persistence
  Write your complete review verdict to: {session_dir}/review-ux-dx-{mode}.md
  At the very end of the file, append this sentinel marker on its own line:
  <!-- AGENT_COMPLETE -->
")
```

**Slot 3 — Correctness (provider-routed):**

If Slot 3 provider resolves to `codex`:

```text
Bash(timeout=300000, command="START_MS=$(date +%s%3N); CODEX_RUNNER='{CWF_PLUGIN_DIR}/scripts/codex/codex-with-log.sh'; [ -x \"$CODEX_RUNNER\" ] || CODEX_RUNNER='codex'; timeout 120 \"$CODEX_RUNNER\" exec --sandbox read-only -c model_reasoning_effort='high' - < '{tmp_dir}/correctness-prompt.md' > '{tmp_dir}/slot3-output.md' 2>'{tmp_dir}/slot3-stderr.log'; EXIT=$?; END_MS=$(date +%s%3N); echo \"TOOL=codex EXIT_CODE=$EXIT DURATION_MS=$((END_MS - START_MS))\" > '{tmp_dir}/slot3-meta.txt'")
```

For `--mode code`, use `model_reasoning_effort='xhigh'` instead. Single quotes around config values avoid double-quote conflicts in the Bash wrapper.

If Slot 3 provider resolves to `gemini`:

```text
Bash(timeout=300000, command="START_MS=$(date +%s%3N); timeout 120 npx @google/gemini-cli -o text < '{tmp_dir}/correctness-prompt.md' > '{tmp_dir}/slot3-output.md' 2>'{tmp_dir}/slot3-stderr.log'; EXIT=$?; END_MS=$(date +%s%3N); echo \"TOOL=gemini EXIT_CODE=$EXIT DURATION_MS=$((END_MS - START_MS))\" > '{tmp_dir}/slot3-meta.txt'")
```

If Slot 3 provider resolves to `claude`:

```text
Task(subagent_type="general-purpose", name="correctness-fallback", max_turns={max_turns}, prompt="
  {correctness_fallback_prompt}

  ## Output Persistence
  Write your complete review verdict to: {session_dir}/review-correctness-{mode}.md
  At the very end of the file, append this sentinel marker on its own line:
  <!-- AGENT_COMPLETE -->
")
```

When Slot 3 uses external CLI and succeeds (exit 0 + non-empty output), copy output to session dir:

```bash
cp '{tmp_dir}/slot3-output.md' '{session_dir}/review-correctness-{mode}.md'
echo '' >> '{session_dir}/review-correctness-{mode}.md'
echo '<!-- AGENT_COMPLETE -->' >> '{session_dir}/review-correctness-{mode}.md'
```

**Slot 4 — Architecture (provider-routed):**

If Slot 4 provider resolves to `gemini`:

```text
Bash(timeout=300000, command="START_MS=$(date +%s%3N); timeout 120 npx @google/gemini-cli -o text < '{tmp_dir}/architecture-prompt.md' > '{tmp_dir}/slot4-output.md' 2>'{tmp_dir}/slot4-stderr.log'; EXIT=$?; END_MS=$(date +%s%3N); echo \"TOOL=gemini EXIT_CODE=$EXIT DURATION_MS=$((END_MS - START_MS))\" > '{tmp_dir}/slot4-meta.txt'")
```

Uses stdin redirection (`< prompt.md`) instead of `-p "$(cat ...)"` to prevent shell injection from review target content containing `$()` or backticks.

If Slot 4 provider resolves to `codex`:

```text
Bash(timeout=300000, command="START_MS=$(date +%s%3N); CODEX_RUNNER='{CWF_PLUGIN_DIR}/scripts/codex/codex-with-log.sh'; [ -x \"$CODEX_RUNNER\" ] || CODEX_RUNNER='codex'; timeout 120 \"$CODEX_RUNNER\" exec --sandbox read-only -c model_reasoning_effort='high' - < '{tmp_dir}/architecture-prompt.md' > '{tmp_dir}/slot4-output.md' 2>'{tmp_dir}/slot4-stderr.log'; EXIT=$?; END_MS=$(date +%s%3N); echo \"TOOL=codex EXIT_CODE=$EXIT DURATION_MS=$((END_MS - START_MS))\" > '{tmp_dir}/slot4-meta.txt'")
```

For `--mode code`, use `model_reasoning_effort='xhigh'` instead.

If Slot 4 provider resolves to `claude`:

```text
Task(subagent_type="general-purpose", name="architecture-fallback", max_turns={max_turns}, prompt="
  {architecture_fallback_prompt}

  ## Output Persistence
  Write your complete review verdict to: {session_dir}/review-architecture-{mode}.md
  At the very end of the file, append this sentinel marker on its own line:
  <!-- AGENT_COMPLETE -->
")
```

When Slot 4 uses external CLI and succeeds (exit 0 + non-empty output), copy output to session dir:

```bash
cp '{tmp_dir}/slot4-output.md' '{session_dir}/review-architecture-{mode}.md'
echo '' >> '{session_dir}/review-architecture-{mode}.md'
echo '<!-- AGENT_COMPLETE -->' >> '{session_dir}/review-architecture-{mode}.md'
```

**Slot 5 — Expert α (always Task):**

Expert selection: Read `expert_roster` from `cwf-state.yaml`. Analyze the review target for domain keywords; match against each roster entry's `domain` field. Select 2 experts with contrasting frameworks. If roster has < 2 matches, fill via independent selection.

```text
Task(subagent_type="general-purpose", name="expert-alpha", max_turns={max_turns}, prompt="
  Read {CWF_PLUGIN_DIR}/references/expert-advisor-guide.md.
  You are Expert α, operating in **review mode**.

  Your identity: {selected expert name}
  Your framework: {expert's domain}

  ## Review Target
  {the diff, plan content, or clarify artifact}

  ## Success Criteria to Verify
  {behavioral criteria + holdout checks as checklist, qualitative criteria as narrative items}

  Review through your published framework. Use web search to verify your expert identity
  and cite published work (follow Web Research Protocol in
  {CWF_PLUGIN_DIR}/references/agent-patterns.md; you have Bash access for
  agent-browser fallback on JS-rendered pages). Output in the review mode format
  from the guide.

  ## Output Persistence
  Write your complete review verdict to: {session_dir}/review-expert-alpha-{mode}.md
  At the very end of the file, append this sentinel marker on its own line:
  <!-- AGENT_COMPLETE -->
")
```

**Slot 6 — Expert β (always Task):**

```text
Task(subagent_type="general-purpose", name="expert-beta", max_turns={max_turns}, prompt="
  Read {CWF_PLUGIN_DIR}/references/expert-advisor-guide.md.
  You are Expert β, operating in **review mode**.

  Your identity: {selected expert name — contrasting framework from Expert α}
  Your framework: {expert's domain}

  ## Review Target
  {the diff, plan content, or clarify artifact}

  ## Success Criteria to Verify
  {behavioral criteria + holdout checks as checklist, qualitative criteria as narrative items}

  Review through your published framework. Use web search to verify your expert identity
  and cite published work (follow Web Research Protocol in
  {CWF_PLUGIN_DIR}/references/agent-patterns.md; you have Bash access for
  agent-browser fallback on JS-rendered pages). Output in the review mode format
  from the guide.

  ## Output Persistence
  Write your complete review verdict to: {session_dir}/review-expert-beta-{mode}.md
  At the very end of the file, append this sentinel marker on its own line:
  <!-- AGENT_COMPLETE -->
")
```

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

#### Error-type classification (check FIRST, before exit code)

When an external CLI exits non-zero, parse stderr **immediately** for error type keywords. This prevents wasting time on retries that cannot succeed.

1. Read `{tmp_dir}/slot{N}-stderr.log`
1. Classify by the **first matching** pattern:
   - `MODEL_CAPACITY_EXHAUSTED`, `429`, `ResourceExhausted`, `quota` → **CAPACITY**: fail-fast, immediate fallback, no retry
   - `INTERNAL_ERROR`, `500`, `InternalError`, `server error` → **INTERNAL**: 1 retry then fallback
   - `AUTHENTICATION`, `401`, `UNAUTHENTICATED`, `API key` → **AUTH**: abort immediately with setup hint
   - `Tool.*not found`, `Did you mean one of` → **TOOL_ERROR**: fail-fast, immediate fallback, no retry
1. Apply the action:
   - **CAPACITY**: Skip exit code check. Launch fallback immediately.
   - **INTERNAL**: Re-run the CLI command once. If still fails, launch fallback.
   - **AUTH**: Do NOT stop with report only. Ask whether to configure now (`codex auth login` or `npx @google/gemini-cli`) and retry that slot once. If user declines, continue with Task fallback and record in Confidence Note.
   - **TOOL_ERROR**: Skip exit code check. Ask whether to install now (recommended via `cwf:setup --tools`), then retry once if approved; otherwise launch fallback immediately. Record outcome in Confidence Note.
1. If **no pattern matches**, fall through to exit code classification below.

#### Exit code classification

| Exit code | Meaning | Action |
|-----------|---------|--------|
| 0 + non-empty output | Success | `source: REAL_EXECUTION` |
| 0 + empty output | Silent failure | `source: FAILED` → launch Task fallback |
| 124 | Timeout (120s exceeded) | `source: FAILED` → launch Task fallback |
| 126-127 | Permission denied / not found | `source: FAILED` → launch Task fallback |
| Other non-zero | Unclassified error | `source: FAILED` → launch Task fallback |

#### Error cause extraction (L9)

When an external CLI fails (exit code != 0), extract the actionable error cause from stderr for the Confidence Note:

1. Read the stderr log file: `{tmp_dir}/slot{N}-stderr.log`
2. Extract the first actionable error message using this priority:
   - **JSON stderr**: parse `.error.message` or `.error.details`
   - **Plain text stderr**: find the last line containing "Error" or "error"
   - **Fallback**: first 3 non-empty lines of stderr
3. Store the extracted error cause per slot:

```text
error_causes[slot_N] = "{error_type}: {extracted_error}"
```

#### Launch fallbacks

If fallbacks are needed, launch all needed fallback Task agents in **one message**, then read their results. Each fallback uses the fallback prompt template from `external-review.md` with the appropriate perspective (Correctness or Architecture).

Each fallback Task agent prompt must include output persistence:

```text
Task(subagent_type="general-purpose", name="{tool}-fallback", max_turns={max_turns}, prompt="
  {fallback_prompt}

  ## Output Persistence
  Write your complete review verdict to: {session_dir}/review-{slot_name}-{mode}.md
  At the very end of the file, append this sentinel marker on its own line:
  <!-- AGENT_COMPLETE -->
")
```

### 3.3 Assemble 6 review outputs

Collect all 6 outputs from session directory files (mix of `REAL_EXECUTION` and `FALLBACK` sources). Internal reviewers and expert reviewers follow the standard reviewer output format from `prompts.md`. Expert reviewers follow the review mode format from `expert-advisor-guide.md`.

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

Output to the conversation (do NOT write to a file unless the user asks):

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

### 3. Cleanup

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
5. **Output to conversation** — review results are communication, not state.
   Do not write files unless the user explicitly asks.
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
```

---

## References

- Internal reviewer perspectives: [references/prompts.md](references/prompts.md)
- External reviewer perspectives & CLI templates: [references/external-review.md](references/external-review.md)
- Agent patterns (provenance, synthesis, execution): [agent-patterns.md](../../references/agent-patterns.md)
- Expert advisor guide (expert sub-agent identity, grounding, review format): [expert-advisor-guide.md](../../references/expert-advisor-guide.md)
