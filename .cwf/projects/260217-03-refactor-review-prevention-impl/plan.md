# Plan — Implement Prevention Proposals A, B, C, E+G + Adaptive Review Timeout

## Context

The 260216-04 full-repo-refactor session accidentally deleted `csv-to-toon.sh` (a runtime dependency) and removed provenance sidecars. Post-incident review (`.cwf/projects/260217-01-refactor-review/review-and-prevention.md`) identified root causes and proposed 9 prevention mechanisms (A–I). This session implements the P0 and P1 proposals — the prevention and signal preservation layers.

The spec document already contains detailed pseudocode, BDD acceptance criteria, and file targets. This plan operationalizes them into implementation steps.

Additionally, during plan review (Stage 4), Codex and Gemini CLIs both timed out (120s) because the review prompt (~500 lines: plan + spec) exceeded the hardcoded timeout. This exposed that `cwf:review`'s external CLI timeout is not adaptive to prompt size. Step 5 addresses this.

## Goal

Implement 4 prevention proposals as deterministic hooks, rules, and protocol documentation, plus one operational fix:

- **A**: PreToolUse hook that blocks file deletion when runtime callers exist
- **B**: Broken-link triage protocol that prevents "remove reference" as default response
- **C**: Recommendation fidelity check rule in impl SKILL.md (stopgap — structural fix deferred)
- **E+G**: UserPromptSubmit hook that enforces pipeline gate compliance (compaction-immune)
- **Timeout**: Adaptive external CLI timeout in cwf:review based on prompt size

## Scope

**In scope**: Proposals A, B, C, E+G (P0 + P1) + adaptive review timeout

**Out of scope**: Proposals D (script dep graph), F (session log review), H (README structure sync), I (shared reference extraction) — all P2, deferred

## Commit Strategy

**Per step**: Each step gets its own commit. 5 steps = 5 commits.

All code changes happen in the worktree at `/home/hwidong/codes/claude-plugins-wt-260217-run` on branch `feat/260217-03-review-prevention-impl`. Session artifacts stay in the main repo.

## Steps

### Step 1: Proposal A — Deletion Safety Hook

Create `check-deletion-safety.sh` as a **PreToolUse** hook for Bash tool calls. PreToolUse fires before the tool executes, so the deletion can be actually prevented (not just detected after the fact).

**Files to create/modify (in worktree)**:

1. **Create** `plugins/cwf/hooks/scripts/check-deletion-safety.sh`:
   - Follow check-links-local.sh template structure (HOOK_GROUP, gate, stdin parse, decision output)
   - `HOOK_GROUP="deletion_safety"`
   - Parse `tool_input.command` from stdin JSON for deletion patterns using these regexes:
     - `\bgit\s+rm\b` — matches `git rm` with word boundaries
     - `\brm\s+` — matches `rm ` followed by args/paths. This intentionally matches all `rm` invocations including `rm -rf`; path-based filtering below excludes non-project files
     - `\bunlink\b` — matches `unlink` command
   - Extract deleted file paths from the matched command
   - For each detected deleted file path:
     - Skip if path is outside the repo root or within `node_modules/`, `/tmp/`, `.cwf/projects/`
     - `grep -rl` across `*.sh`, `*.md`, `*.mjs`, `*.yaml`, `*.json`, `*.py` in the repo root
     - Exclude the deleted file itself from search results
     - Exclude `.cwf/projects/` paths (session artifacts)
   - If callers found: `exit 1` with JSON `{"decision":"block","reason":"BLOCKED: {file} has runtime callers: {list}. Cancel deletion or remove callers first."}`
   - If grep/parse error: `exit 1` with JSON `{"decision":"block","reason":"BLOCKED: deletion safety check failed (parse error). Review command manually."}` (fail-closed, with actionable message)
   - If no callers: `exit 0` (silent pass)
   - **Header comment**: Document that `grep -rl` detects literal string matches only. Variable-interpolated references (e.g., `"$SCRIPT_DIR/csv-to-toon.sh"`, `source "$DIR/lib.sh"`) will not be detected. This is an accepted residual risk — static analysis cannot resolve all dynamic references.
   - **Scope rationale** (in header comment): This hook targets `Bash` tool calls only. The `Write` and `Edit` tools overwrite file content but do not remove files from the filesystem, so they are out of scope for deletion safety.

2. **Modify** `plugins/cwf/hooks/hooks.json`:
   - Add new **PreToolUse** matcher entry for `"Bash"` in the `PreToolUse` hooks array
   - Register `check-deletion-safety.sh`

3. **Modify** `.cwf/cwf-state.yaml`:
   - Add `deletion_safety: true` to `hooks:` section

**Commit**: `feat(hooks): add deletion safety PreToolUse hook (Proposal A)`

### Step 2: Proposal B — Broken-Link Triage Protocol

Add triage protocol documentation and hook hint.

**Files to modify (in worktree)**:

1. **Modify** `plugins/cwf/references/agent-patterns.md`:
   - Insert new `## Broken Link Triage Protocol` section before `## Design Principles`
   - Content from spec: git log check, caller classification (runtime/build/test/docs/stale), decision matrix, triage recording
   - Include `### Integration with check-links-local.sh hook` subsection

2. **Modify** `plugins/cwf/hooks/scripts/check-links-local.sh`:
   - In the block decision output (around line 82), append a hint line to the reason:
     `"For triage guidance, see references/agent-patterns.md § Broken Link Triage Protocol"`

**Commit**: `docs(cwf): add broken-link triage protocol (Proposal B)`

### Step 3: Proposal E+G — Workflow Enforcement Hook

The most complex proposal. Creates a compaction-immune pipeline enforcement mechanism.

**Files to create/modify (in worktree)**:

1. **Modify** `plugins/cwf/scripts/cwf-live-state.sh`:
   - Add `cwf_live_sanitize_yaml_value()` function (before `cwf_live_upsert_live_scalar`):
     - Escapes `:`, `\n`, `[`, `]` for YAML safety
     - **Integration**: Called inside `cwf_live_upsert_live_scalar()` as a wrapper around the existing `cwf_live_escape_dq()`. The write path becomes: caller → `cwf_live_upsert_live_scalar()` → `cwf_live_sanitize_yaml_value()` → `cwf_live_escape_dq()` → AWK upsert. This ensures ALL scalar values pass through YAML sanitization, not just `user_directive`.
     - Applies to: `user_directive`, `pipeline_override_reason`, and any other free-form text fields
   - Add `cwf_live_upsert_live_list()` function (after `cwf_live_upsert_live_scalar`):
     - Takes: state_file, key, space-separated list values
     - Writes YAML list format (`  key:\n    - item1\n    - item2`)
     - Replaces existing list if present, creates if absent
   - Add `cwf_live_remove_list_item()` function:
     - Takes: state_file, key, item_to_remove
     - Removes single item from YAML list under `live:` block
     - **Idempotent**: silent success when item is not found (no error). This is intentional for compaction-recovery scenarios where a stage removal may be replayed.
   - Update `cwf_live_validate_scalar_key()`: add `remaining_gates` to blocked keys (it's a list, not scalar)
   - Update `cwf_live_set_scalars()`: allow `active_pipeline`, `user_directive`, `pipeline_override_reason`, `state_version` as scalar keys
   - Add new CLI subcommands `list-set` and `list-remove`:
     ```bash
     bash cwf-live-state.sh list-set . remaining_gates review-code refactor retro ship
     bash cwf-live-state.sh list-remove . remaining_gates review-code
     ```
   - Add gate name validation against allowed enum: `gather`, `clarify`, `plan`, `review-plan`, `impl`, `review-code`, `refactor`, `retro`, `ship`
     - **Sync comment**: Add `# Source of truth: plugins/cwf/skills/run/SKILL.md Stage Definition table` in the enum definition
   - **Update help/usage message** (line ~400): Add `list-set` and `list-remove` to the usage output alongside existing `{resolve|sync}` and `set`

2. **Create** `plugins/cwf/hooks/scripts/workflow-gate.sh`:
   - `HOOK_GROUP="workflow_gate"`
   - UserPromptSubmit hook (synchronous, not async)
   - Parse `session_id` from stdin JSON (same pattern as `track-user-input.sh` line 26: `SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')`)
   - On each user prompt:
     1. Find repo root (`git rev-parse --show-toplevel`)
     2. Read `cwf-state.yaml` live section. If file missing or parse fails: output `[WARNING] workflow-gate: state file unreadable` and `exit 0` (advisory warning, not blocking — fail-open for parse errors since blocking would prevent all work)
     3. If `active_pipeline` is set:
        - Compare stored `session_id` with current session's `session_id` (from stdin JSON). If different: output cleanup prompt for stale pipeline and `exit 0` (advisory)
        - Output reminder: `[PIPELINE] Active: {active_pipeline} (phase: {phase})`
        - Output remaining gates list
        - Output: `Do NOT skip gates. Use Skill tool to invoke next stage.`
     4. If `remaining_gates` contains `review-code` AND user prompt matches ship/push pattern:
        - Ship/push detection regex: `\b(cwf:ship|git\s+push|gh\s+pr\s+create)\b` — matches concrete commands, not casual word usage. This avoids false positives from phrases like "we'll ship later" while catching actual ship attempts.
        - `exit 1` with block message: `{"decision":"block","reason":"BLOCKED: review-code gate pending. Run cwf:review --mode code before shipping."}`
     5. If `active_pipeline` is set but `remaining_gates` is empty:
        - Output warning: `[WARNING] Stale pipeline state: active_pipeline set but no remaining gates. Run: bash cwf-live-state.sh set . active_pipeline=""`
     6. If `pipeline_override_reason` is set:
        - Output warning that gates are overridden with recorded reason

3. **Modify** `plugins/cwf/hooks/hooks.json`:
   - Add a **new matcher entry** in the UserPromptSubmit hooks array for `workflow-gate.sh`. This must be a separate entry from the existing `track-user-input.sh` because:
     - `track-user-input.sh` uses `"async": true` (non-blocking Slack I/O)
     - `workflow-gate.sh` must be synchronous (blocking gate enforcement)
     - Same `"matcher": ""` (match all prompts) but different hook properties
   - Structure: `{"matcher": "", "hooks": [{"type": "command", "command": "...", "timeout": 5000}]}`

4. **Modify** `plugins/cwf/skills/run/SKILL.md`:
   - Phase 1 (Initialize): add `active_pipeline`, `user_directive`, `remaining_gates`, `state_version` initialization
   - Phase 2 (Stage Execution Loop): after each stage completes, `list-remove` the completed stage from `remaining_gates` and increment `state_version`
   - Phase 3 (Completion): clear `active_pipeline`, `remaining_gates`, `user_directive`, `pipeline_override_reason`
   - Rules: add rule about `--skip-gate` override requiring `pipeline_override_reason`

5. **Modify** `.cwf/cwf-state.yaml`:
   - Add `workflow_gate: true` to `hooks:` section

**Commit**: `feat(hooks): add workflow enforcement UserPromptSubmit hook (Proposal E+G)`

### Step 4: Proposal C — Recommendation Fidelity Check

Add rule to impl SKILL.md. **This is explicitly a stopgap** — the structural fix (modifying triage output format to carry original recommendations inline) is deferred. This rule compensates for a process gap with a prose instruction.

**Files to modify (in worktree)**:

1. **Modify** `plugins/cwf/skills/impl/SKILL.md`:
   - Insert new rule before the "Language split is mandatory" rule (find by content, not number — rule numbering may shift):
     - **Recommendation Fidelity Check** (stopgap): For each triage item referencing an analysis document, read the original recommendation, compare with triage action, follow original if contradiction found. For deletions: apply pre-mortem simulation.
     - Include inline comment: `(Stopgap — structural fix: modify triage output format to carry original recommendation. See Deferred Actions.)`
   - Renumber subsequent rules

**Commit**: `docs(cwf): add recommendation fidelity check rule to impl (Proposal C)`

### Step 5: Adaptive External CLI Timeout in cwf:review

During this session's plan review, Codex and Gemini CLIs both timed out (120s) on a ~500-line prompt. The hardcoded `timeout 120` does not account for prompt size variation across review modes.

**Files to modify (in worktree)**:

1. **Modify** `plugins/cwf/skills/review/SKILL.md`:
   - In Phase 1 (section 5, "Measure review target size"), add an **external CLI timeout scaling table** alongside the existing turn budget table:

     | Prompt lines | `cli_timeout` | Rationale |
     |-------------|---------------|-----------|
     | < 300 | 120 | Standard timeout for small/medium reviews |
     | 300–800 | 180 | Extended for plan reviews with spec documents |
     | > 800 | 240 | Large reviews (multi-file diffs, complex plans) |

   - Store the resolved `cli_timeout` value alongside `max_turns`
   - In Phase 2.3, replace all 4 occurrences of hardcoded `timeout 120` with `timeout {cli_timeout}` in the Codex and Gemini CLI command templates
   - Update the fallback latency note in the "External CLI Setup" section to reference dynamic timeout

**Commit**: `fix(review): scale external CLI timeout by prompt size`

## Success Criteria

### Behavioral (BDD)

```gherkin
# Proposal A
Given an agent executing cwf:impl attempts to delete a file via Bash
When the file has runtime callers (grep across *.sh/*.md/*.mjs/*.yaml/*.json/*.py)
Then the PreToolUse hook exits 1 with "BLOCKED: {file} has runtime callers"
And the deletion command is not executed (PreToolUse blocks before execution)

Given an agent attempts to delete a file with no callers
When check-deletion-safety.sh runs
Then the hook exits 0 silently and the command proceeds

Given grep fails or cannot parse the deletion command
When check-deletion-safety.sh runs
Then the hook exits 1 with actionable error message (fail-closed)

Given an agent runs "rm -rf node_modules"
When check-deletion-safety.sh runs
Then the path "node_modules/" is excluded from caller search (not a project file)
And the hook exits 0

# Proposal B
Given a pre-push hook reports a broken link to a recently deleted file
When the agent reads the error message
Then the error includes a reference to the Broken Link Triage Protocol
And agent-patterns.md contains the full triage decision matrix

# Proposal C
Given cwf:impl receives a triage item referencing an analysis document
When the triage action contradicts the original recommendation
Then the Rules section instructs the agent to follow the original recommendation

# Proposal E+G
Given cwf:run is active with remaining_gates including review-code
When the user prompt contains "cwf:ship" or "git push" or "gh pr create"
Then the UserPromptSubmit hook exits 1 with gate violation message

Given cwf:run completes a stage
When remaining_gates is updated via list-remove
Then the completed stage is removed from the YAML list

Given a stale active_pipeline from a previous session exists
When a new session starts and workflow-gate.sh fires
Then a cleanup prompt is output to the agent

Given active_pipeline is set but remaining_gates is empty
When workflow-gate.sh fires
Then a stale state warning is output

# Adaptive CLI Timeout
Given a review prompt has 500 lines
When cwf:review launches external CLIs
Then the CLI timeout is set to 180 seconds (not the default 120)

Given a review prompt has 100 lines
When cwf:review launches external CLIs
Then the CLI timeout remains at the default 120 seconds
```

### Qualitative

- Hook scripts follow existing codebase conventions (HOOK_GROUP, gate, stdin parse, decision output)
- cwf-live-state.sh list operations use the same AWK patterns as existing scalar operations
- All new hooks are toggleable via cwf-hooks-enabled.sh
- Documentation changes integrate naturally with existing sections (no orphan sections)
- Fail-closed behavior for safety hooks (Proposal A); fail-open for advisory hooks (workflow-gate parse errors)
- check-deletion-safety.sh header documents detection boundary (literal matches only, no variable interpolation)
- cwf-live-state.sh help/usage reflects all available subcommands including list-set/list-remove
- Proposal C rule is explicitly marked as a stopgap with structural fix noted in Deferred Actions

## Files to Create/Modify

| File | Action | Step | Purpose |
|------|--------|------|---------|
| `plugins/cwf/hooks/scripts/check-deletion-safety.sh` | Create | 1 | PreToolUse hook for file deletion safety |
| `plugins/cwf/hooks/hooks.json` | Edit | 1, 3 | Register new hooks (PreToolUse Bash, UserPromptSubmit) |
| `.cwf/cwf-state.yaml` | Edit | 1, 3 | Add hook toggle entries |
| `plugins/cwf/references/agent-patterns.md` | Edit | 2 | Add Broken Link Triage Protocol section |
| `plugins/cwf/hooks/scripts/check-links-local.sh` | Edit | 2 | Add triage protocol hint to error output |
| `plugins/cwf/scripts/cwf-live-state.sh` | Edit | 3 | Add list-set/list-remove commands, gate validation, YAML sanitization |
| `plugins/cwf/hooks/scripts/workflow-gate.sh` | Create | 3 | UserPromptSubmit hook for pipeline gate enforcement |
| `plugins/cwf/skills/run/SKILL.md` | Edit | 3 | Add pipeline state management to Phase 1/2/3 |
| `plugins/cwf/skills/impl/SKILL.md` | Edit | 4 | Add Recommendation Fidelity Check rule (stopgap) |
| `plugins/cwf/skills/review/SKILL.md` | Edit | 5 | Add adaptive CLI timeout scaling |

## Decision Log

| # | Decision | Rationale | Alternatives Considered |
|---|----------|-----------|------------------------|
| 1 | Proposal A uses **PreToolUse** (not PostToolUse) | PreToolUse fires before command execution, allowing actual prevention. PostToolUse can only detect after the fact. Plan review flagged this as HIGH/critical. | PostToolUse with `git checkout HEAD -- {file}` restore instruction |
| 2 | Exclude `.cwf/projects/`, `node_modules/`, `/tmp/` from caller search | Session artifacts are ephemeral; node_modules and tmp are not project files | Include all paths in search |
| 3 | Proposal E+G uses synchronous hook (not async) | Must block agent before it processes the prompt; async would be advisory only | Async with stronger wording |
| 4 | List operations as separate CLI subcommands (`list-set`, `list-remove`) | Cleaner API than overloading `set` with type detection; explicit is better than implicit | Overload `set` to auto-detect list values |
| 5 | Gate name validation against hard-coded enum with sync comment | Prevents typos; comment points to `run/SKILL.md` Stage Definition as source of truth | Free-form gate names; shared constant file |
| 6 | `rm` regex matches all `rm` invocations; path filtering excludes non-project files | The original plan's `rm ` (trailing space) rationale contradicted its own behavior. All `rm` invocations should be inspected; the filtering happens at the path level. | Pattern-based exclusion of `rm -rf` |
| 7 | Ship/push detection uses concrete command patterns, not casual keywords | Regex `\b(cwf:ship\|git\s+push\|gh\s+pr\s+create)\b` avoids false positives from "we'll ship later" while catching actual ship commands | Semantic analysis; broader keyword matching |
| 8 | `cwf_live_sanitize_yaml_value()` wraps `cwf_live_escape_dq()` inside the write path | All scalar values pass through sanitization, not just caller-selected fields. Prevents YAML injection from any free-form text field. | Call-site sanitization (easy to forget) |
| 9 | `workflow-gate.sh` as separate hooks.json entry (not in existing array) | Existing `track-user-input.sh` is `async: true`; mixing async and sync hooks in the same array creates confusing semantics | Append to existing matcher array |

## Don't Touch

- `plugins/cwf/skills/gather/` — Proposal D (P2) deferred
- Any `.cwf/projects/260216-*` or `260217-01-*` directories (previous session artifacts)
- `plugins/cwf/hooks/scripts/check-markdown.sh` — unrelated hook
- `README.md`, `README.ko.md` — no README changes in this session

## Deferred Actions

- [ ] Proposal D: Script dependency graph in pre-push (P2)
- [ ] Proposal F: Session log cross-check in cwf:review (P2)
- [ ] Proposal H: README structure sync validation (P2)
- [ ] Proposal I: Shared reference extraction (P2)
- [ ] Add `deletion_safety` and `workflow_gate` to cwf:setup hook group selection UI
- [ ] Proposal C structural fix: modify triage output format to carry original recommendation inline (eliminates need for prose rule)
- [ ] Compaction recovery: decision journal inclusion in compaction summary (prevents re-asking resolved decisions)
