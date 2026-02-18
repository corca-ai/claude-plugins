# Orchestration and Fallback Details

Detailed `review` procedure for heavy execution blocks:
- Phase 2.3 (six-slot launch command templates)
- Phase 3.2 (external failure classification and fallback launch)

`SKILL.md` keeps mode routing and invariant summaries, while this file stores full templates.

## 2.3 Launch all 6 in ONE message

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
Bash(timeout=300000, command="START_MS=$(date +%s%3N); CODEX_RUNNER='{CWF_PLUGIN_DIR}/scripts/codex/codex-with-log.sh'; [ -x \"$CODEX_RUNNER\" ] || CODEX_RUNNER='codex'; timeout {cli_timeout} \"$CODEX_RUNNER\" exec --sandbox read-only -c model_reasoning_effort='high' - < '{tmp_dir}/correctness-prompt.md' > '{tmp_dir}/slot3-output.md' 2>'{tmp_dir}/slot3-stderr.log'; EXIT=$?; END_MS=$(date +%s%3N); echo \"TOOL=codex EXIT_CODE=$EXIT DURATION_MS=$((END_MS - START_MS))\" > '{tmp_dir}/slot3-meta.txt'")
```

For `--mode code`, use `model_reasoning_effort='xhigh'` instead. Single quotes around config values avoid double-quote conflicts in the Bash wrapper.

If Slot 3 provider resolves to `gemini`:

```text
Bash(timeout=300000, command="START_MS=$(date +%s%3N); timeout {cli_timeout} npx @google/gemini-cli -o text < '{tmp_dir}/correctness-prompt.md' > '{tmp_dir}/slot3-output.md' 2>'{tmp_dir}/slot3-stderr.log'; EXIT=$?; END_MS=$(date +%s%3N); echo \"TOOL=gemini EXIT_CODE=$EXIT DURATION_MS=$((END_MS - START_MS))\" > '{tmp_dir}/slot3-meta.txt'")
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
Bash(timeout=300000, command="START_MS=$(date +%s%3N); timeout {cli_timeout} npx @google/gemini-cli -o text < '{tmp_dir}/architecture-prompt.md' > '{tmp_dir}/slot4-output.md' 2>'{tmp_dir}/slot4-stderr.log'; EXIT=$?; END_MS=$(date +%s%3N); echo \"TOOL=gemini EXIT_CODE=$EXIT DURATION_MS=$((END_MS - START_MS))\" > '{tmp_dir}/slot4-meta.txt'")
```

Uses stdin redirection (`< prompt.md`) instead of `-p "$(cat ...)"` to prevent shell injection from review target content containing `$()` or backticks.

If Slot 4 provider resolves to `codex`:

```text
Bash(timeout=300000, command="START_MS=$(date +%s%3N); CODEX_RUNNER='{CWF_PLUGIN_DIR}/scripts/codex/codex-with-log.sh'; [ -x \"$CODEX_RUNNER\" ] || CODEX_RUNNER='codex'; timeout {cli_timeout} \"$CODEX_RUNNER\" exec --sandbox read-only -c model_reasoning_effort='high' - < '{tmp_dir}/architecture-prompt.md' > '{tmp_dir}/slot4-output.md' 2>'{tmp_dir}/slot4-stderr.log'; EXIT=$?; END_MS=$(date +%s%3N); echo \"TOOL=codex EXIT_CODE=$EXIT DURATION_MS=$((END_MS - START_MS))\" > '{tmp_dir}/slot4-meta.txt'")
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
   - `AUTHENTICATION`, `401`, `UNAUTHENTICATED`, `API key`, `auth login`, `not logged in`, `Please login` → **AUTH**: abort immediately with setup hint
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
| 124 | Timeout (120s exceeded) | If stderr indicates auth prompt, classify as `AUTH`; otherwise `source: FAILED` → launch Task fallback |
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
