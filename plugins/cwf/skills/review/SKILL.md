---
name: review
description: |
  Universal review with narrative verdicts. 6 parallel reviewers:
  2 internal (Security, UX/DX) via Task + 2 external (Codex, Gemini) via CLI
  + 2 domain experts via Task. Graceful fallback when CLIs unavailable.
  Modes: --mode clarify/plan/code. Triggers: "/review"
allowed-tools:
  - Task
  - Read
  - Write
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

# Review (/review)

Universal review with narrative verdicts via 6 parallel reviewers (2 internal + 2 external CLI + 2 domain experts).

**Language**: Match the user's language for synthesis. Reviewer prompts in English.

## Quick Reference

```text
/review                 Code review (default)
/review --mode plan     Plan/spec review
/review --mode clarify  Requirement review
```

## External CLI Setup (one-time)

For full 4-reviewer coverage, authenticate external CLIs:

```bash
codex auth login          # OpenAI Codex
npx @google/gemini-cli    # Google Gemini (interactive first-run setup)
```

Both are optional — the skill falls back to Claude Task agents when CLIs
are missing or unauthenticated. But real CLI reviews provide diverse model
perspectives beyond Claude.

**Fallback latency**: If both external CLIs fail, the skill incurs a
two-round-trip penalty — first the CLI attempts run (up to 120s timeout each),
then fallback Task agents are launched sequentially. Error-type classification
(Phase 3.2) enables fail-fast for CAPACITY errors, reducing wasted time.

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

Extract `--mode` from user input. Default to `code` if not specified.

### 2. Detect review target

Automatically detect what to review based on mode:

**--mode code:**

Try in order (first non-empty wins):

1. Detect base branch: check `main`, then `master`, then the default remote branch
   via `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'`
2. Branch diff vs base: `git diff $(git merge-base HEAD {base_branch})..HEAD`
   - Only if current branch differs from the detected base branch
3. Staged changes: `git diff --cached`
4. Last commit: `git show HEAD`

If all empty, ask user with AskUserQuestion.

**--mode plan:**

1. Search for the most recent plan file:
   ```bash
   ls -td prompt-logs/*/plan.md 2>/dev/null | head -1
   ```
2. If not found, check `prompt-logs/*/master-plan.md`
3. If not found, ask user with AskUserQuestion

**--mode clarify:**

1. Search for recent clarification artifacts:
   ```bash
   ls -td prompt-logs/*/clarify-result.md 2>/dev/null | head -1
   ```
2. If not found, ask user with AskUserQuestion

### 3. Extract behavioral/qualitative criteria

Search the associated plan.md for success criteria to use as verification input:

1. Find the most recent `prompt-logs/*/plan.md` by modification time
2. Extract **behavioral criteria** — look for Given/When/Then patterns or
   checkbox-style success criteria. These become a pass/fail checklist.
3. Extract **qualitative criteria** — narrative criteria like "should be
   intuitive" or "maintain backward compatibility". These are addressed
   in the narrative verdict.
4. If no plan.md or no criteria found: proceed without criteria.
   Note in synthesis: "No success criteria found — review based on
   general best practices only."

---

## Phase 2: Launch All Reviewers

Launch **six** reviewers in parallel: 2 internal (Task agents) + 2 external (CLI or Task fallback) + 2 domain experts (Task agents).
All launched in a **single message** for maximum parallelism.

### 2.0 Resolve session directory and context recovery

Read `cwf-state.yaml` → `live.dir` to get the current session directory path.

```yaml
session_dir: "{live.dir value from cwf-state.yaml}"
```

Apply the [context recovery protocol](../../references/context-recovery-protocol.md) to these files:

| Slot | Reviewer | Output file |
|------|----------|-------------|
| 1 | Security | `{session_dir}/review-security.md` |
| 2 | UX/DX | `{session_dir}/review-ux-dx.md` |
| 3 | Correctness | `{session_dir}/review-correctness.md` |
| 4 | Architecture | `{session_dir}/review-architecture.md` |
| 5 | Expert α | `{session_dir}/review-expert-alpha.md` |
| 6 | Expert β | `{session_dir}/review-expert-beta.md` |

Skip to Phase 3 if all 6 files are valid. In recovery mode (all files cached), skip Phase 2.1–2.3 entirely — proceed directly to Phase 3. Note that temp-dir metadata (`{tmp_dir}/*-meta.txt`) will not exist in recovery; use `duration_ms: —` and `source: CACHED` in provenance for recovered slots.

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
{behavioral criteria as checklist, qualitative criteria as narrative items}
(If none: "No specific success criteria provided. Review based on general best practices.")

## Output Format
{output format section from prompts.md}

IMPORTANT:
- Be specific. Reference exact files, lines, sections.
- Distinguish Concerns (blocking) from Suggestions (non-blocking).
- If success criteria are provided, assess each one in the Behavioral Criteria Assessment.
- Include the Provenance block at the end.
```

For **external** reviewers (Codex, Gemini):

1. Read `{SKILL_DIR}/references/external-review.md`
2. Extract the reviewer's Role section + mode-specific checklist
3. Create temp dir: `mktemp -d /tmp/claude-review-XXXXXX`
4. Write prompt files to temp dir: `codex-prompt.md` and `gemini-prompt.md`
   - Same structure as internal prompts (role + mode checklist + review target + criteria)
   - Use the **external provenance format** from `external-review.md` (includes `duration_ms`, `command`)

### 2.2 Detect CLI availability

Single Bash call to check both:

```bash
command -v codex && echo CODEX_FOUND; command -v npx && echo NPX_FOUND
```

Parse the output:
- Contains `CODEX_FOUND` → Codex CLI binary exists (auth assumed OK)
- Contains `NPX_FOUND` → npx exists, Gemini CLI *may* be available

Note: `NPX_FOUND` only confirms npx is installed, not that Gemini CLI is
authenticated or cached. Runtime failures are handled in Phase 3.2.

### 2.3 Launch all 6 in ONE message

All 6 reviewers launch in a single message for parallel execution:

**Slot 1 — Security (always Task):**

```text
Task(subagent_type="general-purpose", name="security-reviewer", max_turns=12, prompt="
  {security_prompt}

  ## Output Persistence
  Write your complete review verdict to: {session_dir}/review-security.md
  At the very end of the file, append this sentinel marker on its own line:
  <!-- AGENT_COMPLETE -->
")
```

**Slot 2 — UX/DX (always Task):**

```text
Task(subagent_type="general-purpose", name="uxdx-reviewer", max_turns=12, prompt="
  {uxdx_prompt}

  ## Output Persistence
  Write your complete review verdict to: {session_dir}/review-ux-dx.md
  At the very end of the file, append this sentinel marker on its own line:
  <!-- AGENT_COMPLETE -->
")
```

**Slot 3 — Correctness (Codex or fallback):**

If Codex available:

```text
Bash(timeout=300000, command="START_MS=$(date +%s%3N); CODEX_RUNNER='./scripts/codex/codex-with-log.sh'; [ -x \"$CODEX_RUNNER\" ] || CODEX_RUNNER='codex'; timeout 120 \"$CODEX_RUNNER\" exec --sandbox read-only -c model_reasoning_effort='high' - < '{tmp_dir}/codex-prompt.md' > '{tmp_dir}/codex-output.md' 2>'{tmp_dir}/codex-stderr.log'; EXIT=$?; END_MS=$(date +%s%3N); echo \"EXIT_CODE=$EXIT DURATION_MS=$((END_MS - START_MS))\" > '{tmp_dir}/codex-meta.txt'")
```

For `--mode code`, use `model_reasoning_effort='xhigh'` instead.
Single quotes around config values avoid double-quote conflicts in the Bash wrapper.

After successful Codex execution (exit 0 + non-empty output), copy output to session dir:

```bash
cp '{tmp_dir}/codex-output.md' '{session_dir}/review-correctness.md'
echo '' >> '{session_dir}/review-correctness.md'
echo '<!-- AGENT_COMPLETE -->' >> '{session_dir}/review-correctness.md'
```

If Codex NOT available:

```text
Task(subagent_type="general-purpose", name="codex-fallback", max_turns=12, prompt="
  {codex_fallback_prompt}

  ## Output Persistence
  Write your complete review verdict to: {session_dir}/review-correctness.md
  At the very end of the file, append this sentinel marker on its own line:
  <!-- AGENT_COMPLETE -->
")
```

Using the fallback prompt template from `external-review.md` with the Correctness perspective.

**Slot 4 — Architecture (Gemini or fallback):**

If Gemini available:

```text
Bash(timeout=300000, command="START_MS=$(date +%s%3N); timeout 120 npx @google/gemini-cli -o text < '{tmp_dir}/gemini-prompt.md' > '{tmp_dir}/gemini-output.md' 2>'{tmp_dir}/gemini-stderr.log'; EXIT=$?; END_MS=$(date +%s%3N); echo \"EXIT_CODE=$EXIT DURATION_MS=$((END_MS - START_MS))\" > '{tmp_dir}/gemini-meta.txt'")
```

Uses stdin redirection (`< prompt.md`) instead of `-p "$(cat ...)"` to prevent
shell injection from review target content containing `$()` or backticks.

After successful Gemini execution (exit 0 + non-empty output), copy output to session dir:

```bash
cp '{tmp_dir}/gemini-output.md' '{session_dir}/review-architecture.md'
echo '' >> '{session_dir}/review-architecture.md'
echo '<!-- AGENT_COMPLETE -->' >> '{session_dir}/review-architecture.md'
```

If Gemini NOT available:

```text
Task(subagent_type="general-purpose", name="gemini-fallback", max_turns=12, prompt="
  {gemini_fallback_prompt}

  ## Output Persistence
  Write your complete review verdict to: {session_dir}/review-architecture.md
  At the very end of the file, append this sentinel marker on its own line:
  <!-- AGENT_COMPLETE -->
")
```

Using the fallback prompt template from `external-review.md` with the Architecture perspective.

**Slot 5 — Expert α (always Task):**

Expert selection: Read `expert_roster` from `cwf-state.yaml`. Analyze the review target
for domain keywords; match against each roster entry's `domain` field. Select 2 experts
with contrasting frameworks. If roster has < 2 matches, fill via independent selection.

```text
Task(subagent_type="general-purpose", name="expert-alpha", max_turns=12, prompt="
  Read {CWF_PLUGIN_DIR}/references/expert-advisor-guide.md.
  You are Expert α, operating in **review mode**.

  Your identity: {selected expert name}
  Your framework: {expert's domain}

  ## Review Target
  {the diff, plan content, or clarify artifact}

  ## Success Criteria to Verify
  {behavioral criteria as checklist, qualitative criteria as narrative items}

  Review through your published framework. Use web search to verify your expert identity
  and cite published work (follow Web Research Protocol in
  {CWF_PLUGIN_DIR}/references/agent-patterns.md; you have Bash access for
  agent-browser fallback on JS-rendered pages). Output in the review mode format
  from the guide.

  ## Output Persistence
  Write your complete review verdict to: {session_dir}/review-expert-alpha.md
  At the very end of the file, append this sentinel marker on its own line:
  <!-- AGENT_COMPLETE -->
")
```

**Slot 6 — Expert β (always Task):**

```text
Task(subagent_type="general-purpose", name="expert-beta", max_turns=12, prompt="
  Read {CWF_PLUGIN_DIR}/references/expert-advisor-guide.md.
  You are Expert β, operating in **review mode**.

  Your identity: {selected expert name — contrasting framework from Expert α}
  Your framework: {expert's domain}

  ## Review Target
  {the diff, plan content, or clarify artifact}

  ## Success Criteria to Verify
  {behavioral criteria as checklist, qualitative criteria as narrative items}

  Review through your published framework. Use web search to verify your expert identity
  and cite published work (follow Web Research Protocol in
  {CWF_PLUGIN_DIR}/references/agent-patterns.md; you have Bash access for
  agent-browser fallback on JS-rendered pages). Output in the review mode format
  from the guide.

  ## Output Persistence
  Write your complete review verdict to: {session_dir}/review-expert-beta.md
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
| 1 | `{session_dir}/review-security.md` |
| 2 | `{session_dir}/review-ux-dx.md` |
| 3 | `{session_dir}/review-correctness.md` |
| 4 | `{session_dir}/review-architecture.md` |
| 5 | `{session_dir}/review-expert-alpha.md` |
| 6 | `{session_dir}/review-expert-beta.md` |

For external CLI reviewers (Codex, Gemini), also read metadata from temp dir:
- `{tmp_dir}/codex-meta.txt` or `{tmp_dir}/gemini-meta.txt` for exit code and duration
- `{tmp_dir}/codex-stderr.log` or `{tmp_dir}/gemini-stderr.log` for error details

For successful external reviews, **override** the provenance `duration_ms` with
the actual value from the meta file (not any value the CLI may have generated).
Use the actual command executed for the `command` field.

### 3.2 Handle external failures

#### Error-type classification (check FIRST, before exit code)

When an external CLI exits non-zero, parse stderr **immediately** for error type keywords. This prevents wasting time on retries that cannot succeed.

1. Read `{tmp_dir}/{tool}-stderr.log`
1. Classify by the **first matching** pattern:
   - `MODEL_CAPACITY_EXHAUSTED`, `429`, `ResourceExhausted`, `quota` → **CAPACITY**: fail-fast, immediate fallback, no retry
   - `INTERNAL_ERROR`, `500`, `InternalError`, `server error` → **INTERNAL**: 1 retry then fallback
   - `AUTHENTICATION`, `401`, `UNAUTHENTICATED`, `API key` → **AUTH**: abort immediately with setup hint
   - `Tool.*not found`, `Did you mean one of` → **TOOL_ERROR**: fail-fast, immediate fallback, no retry
1. Apply the action:
   - **CAPACITY**: Skip exit code check. Launch fallback immediately.
   - **INTERNAL**: Re-run the CLI command once. If still fails, launch fallback.
   - **AUTH**: Do NOT launch fallback. Report: `Slot N ({tool}) AUTH error. Run codex auth login / npx @google/gemini-cli to configure.`
   - **TOOL_ERROR**: Skip exit code check. Launch fallback immediately. Note in Confidence Note: `Slot N ({tool}) TOOL_ERROR — CLI attempted unavailable tool.`
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

1. Read the stderr log file: `{tmp_dir}/{tool}-stderr.log`
2. Extract the first actionable error message using this priority:
   - **JSON stderr**: parse `.error.message` or `.error.details`
   - **Plain text stderr**: find the last line containing "Error" or "error"
   - **Fallback**: first 3 non-empty lines of stderr
3. Store the extracted error cause per slot:

```text
error_causes[slot_N] = "{error_type}: {extracted_error}"
```

#### Launch fallbacks

If fallbacks are needed, launch all needed fallback Task agents in **one message**,
then read their results. Each fallback uses the fallback prompt template from
`external-review.md` with the appropriate perspective (Correctness or Architecture).

Each fallback Task agent prompt must include output persistence:

```text
Task(subagent_type="general-purpose", name="{tool}-fallback", max_turns=12, prompt="
  {fallback_prompt}

  ## Output Persistence
  Write your complete review verdict to: {session_dir}/review-{slot_name}.md
  At the very end of the file, append this sentinel marker on its own line:
  <!-- AGENT_COMPLETE -->
")
```

### 3.3 Assemble 6 review outputs

Collect all 6 outputs from session directory files (mix of `REAL_EXECUTION` and `FALLBACK` sources).
Internal reviewers and expert reviewers follow the standard reviewer output
format from `prompts.md`. Expert reviewers follow the review mode format
from `expert-advisor-guide.md`.

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
(Only if criteria were extracted from plan)
- [x] {criterion} — {reviewer}: {evidence}
- [ ] {criterion} — {reviewer}: {reason for failure}

### Concerns (must address)
- **{reviewer}** [{severity}]: {concern description}
  {specific reference: file, line, section}

(If none: "No blocking concerns.")

### Suggestions (optional improvements)
- **{reviewer}**: {suggestion description}

(If none: "No suggestions.")

### Confidence Note
{Note any of the following:}
- Disagreements between reviewers and which side was chosen
- Areas where reviewer confidence was low
- Malformed reviewer outputs that required interpretation
- Missing success criteria (if no plan was found)
- External CLI fallbacks used, with extracted error cause from stderr:
  "Slot N ({tool}) FAILED → fallback. Cause: {extracted_error}"
  Include setup hint: "Run `codex auth login` / `npx @google/gemini-cli` to enable."
- Perspective differences between real CLI output and fallback interpretation

### Reviewer Provenance
| Reviewer | Source | Tool | Duration |
|----------|--------|------|----------|
| Security | REAL_EXECUTION | claude-task | — |
| UX/DX | REAL_EXECUTION | claude-task | — |
| Correctness | {REAL_EXECUTION / FALLBACK} | {codex / claude-task-fallback} | {duration_ms} |
| Architecture | {REAL_EXECUTION / FALLBACK} | {gemini / claude-task-fallback} | {duration_ms} |
| Expert Alpha | REAL_EXECUTION | claude-task | — |
| Expert Beta | REAL_EXECUTION | claude-task | — |
```

The Provenance table adapts to actual results: if an external CLI succeeded,
show `REAL_EXECUTION` with the CLI tool name and measured duration. If it fell
back, show `FALLBACK` with `claude-task-fallback`.

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
| `--scenarios <path>` flag used | Holdout scenario validation (planned). Print "Not yet implemented. Proceeding without holdout scenarios." |
| No git changes found (code mode) | AskUserQuestion: ask user to specify target |
| No plan.md found | AskUserQuestion: ask user to specify target |
| All 6 reviewers report no issues | Verdict = Pass. Note "clean review" in synthesis |
| Codex/Gemini CLI not found | Task agent fallback with same perspective. Mark `FALLBACK` in provenance. |
| External CLI timeout (120s) | Mark `FAILED`. Spawn Task agent fallback. Note in Confidence Note. |
| External CLI auth error | Mark `FAILED`. Spawn Task agent fallback. Note in Confidence Note. |
| External output malformed | Extract by pattern matching. Note in Confidence Note. |

---

## Rules

1. **Always run ALL 6 reviewers** — deliberate naivete. Never skip a reviewer
   because the change "looks simple." Each perspective catches different issues.
   Expert reviewers complement, not replace — the 4 core reviewers always run.
2. **Narrative only** — no numerical scores, no percentages, no letter grades.
   Verdicts are Pass / Conditional Pass / Revise.
3. **Never inline review** — always use Task sub-agents. The main agent
   synthesizes but does not review directly.
4. **Conservative default** — stricter reviewer determines the verdict when
   reviewers disagree.
5. **Output to conversation** — review results are communication, not state.
   Do not write files unless the user explicitly asks.
6. **Criteria from plan** — review verifies plan criteria, it does not
   invent its own. If no criteria exist, review on general best practices
   and note the absence.
7. **Graceful degradation** — external CLI failure (missing binary,
   timeout, auth error) never blocks the review. Fall back to a Task
   sub-agent with the same perspective. Always record the fallback in
   the Provenance table and Confidence Note.

---

## References

- Internal reviewer perspectives: [references/prompts.md](references/prompts.md)
- External reviewer perspectives & CLI templates: [references/external-review.md](references/external-review.md)
- Agent patterns (provenance, synthesis, execution): `plugins/cwf/references/agent-patterns.md`
- Expert advisor guide (expert sub-agent identity, grounding, review format): `plugins/cwf/references/expert-advisor-guide.md`
