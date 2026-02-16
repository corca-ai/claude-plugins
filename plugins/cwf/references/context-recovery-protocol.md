# Context Recovery Protocol

Shared validation protocol for sub-agent output file persistence and recovery after context compaction.

## Global Contract

This protocol exists to enforce context-deficit resilience across skills:

- Treat persisted state/artifacts/handoff files as the source of truth.
- Never require implicit conversational memory to continue execution.
- If required recovery inputs are missing, fail with explicit file-level remediation.

## Session Directory Resolution

Resolve the effective live-state file first, then read `live.dir`.

```bash
live_state_file=$(bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh resolve)
```

```yaml
session_dir: "{live.dir value from resolved live-state file}"
```

## File Validation

For each expected output file in the session directory:

1. Check if the file exists in `{session_dir}`
2. If it exists, read it and validate:
   - File is **non-empty**
   - File ends with the sentinel marker `<!-- AGENT_COMPLETE -->`
3. If **valid** → use the existing content; do NOT re-launch that sub-agent
4. If **invalid** (empty or missing sentinel) → re-launch the sub-agent, overwriting the file

## Stage-Tier Gate Policy

Use hybrid persistence gates by output criticality.

### Critical Outputs (hard gate)

If a critical output is invalid:

1. Re-launch once (bounded retry = 1)
2. Re-validate
3. If still invalid, **hard fail** the stage with an explicit file-level error

Critical by default for orchestrator stages:

- `cwf:plan` research outputs used to draft the plan
- `cwf:review` reviewer verdict files used for synthesis
- `cwf:retro` CDM output (deep mode Section 4 dependency)

### Non-Critical Outputs (soft gate)

If a non-critical output is invalid:

1. Re-launch once (bounded retry = 1)
2. Re-validate
3. If still invalid, continue with **warning + explicit omission note**

Typical non-critical examples:

- Advisory/optional outputs
- Deep retro Expert Lens / Learning Resources outputs when the corresponding
  section can be skipped with an explicit note

## Validation Loop Contract

Every orchestrator that uses this protocol should apply the same loop:

1. Recovery check (reuse valid files)
2. Launch only missing/invalid files
3. Re-validate launched files
4. Apply stage-tier gate (hard/soft)

## Gate Path Visibility

Gate choice must be observable in stage output:

- Hard gate path: report explicit failure with invalid file list
  (`PERSISTENCE_GATE=HARD_FAIL` or equivalent wording)
- Soft gate path: report warning + omission note
  (`PERSISTENCE_GATE=SOFT_CONTINUE` or equivalent wording)

## Agent Self-Persistence

Each sub-agent prompt MUST include output persistence instructions:

```text
Write your complete findings to: {session_dir}/{skill}-{agent-role}.md
The file MUST exist when you finish. End your output file with the exact
line `<!-- AGENT_COMPLETE -->` as the last line.
```

The orchestrator reads output files from the session directory — not in-memory Task return values.

## Design Notes

- The sentinel marker is a behavioral convention enforced by prompt instruction. Sub-agents that hit `max_turns` or crash may produce files without the sentinel, which triggers re-launch on recovery.
- File naming follows `{skill}-{agent-role}.md` (deterministic, no random components).
- All skills apply the same validation logic for consistency. Changes to the protocol should be applied here once, not in individual skills.
