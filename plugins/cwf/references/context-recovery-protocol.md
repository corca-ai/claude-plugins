# Context Recovery Protocol

Shared validation protocol for sub-agent output file persistence and recovery after context compaction.

## Session Directory Resolution

Read `cwf-state.yaml` → `live.dir` to get the current session directory path.

```yaml
session_dir: "{live.dir value from cwf-state.yaml}"
```

## File Validation

For each expected output file in the session directory:

1. Check if the file exists in `{session_dir}`
2. If it exists, read it and validate:
   - File is **non-empty**
   - File ends with the sentinel marker `<!-- AGENT_COMPLETE -->`
3. If **valid** → use the existing content; do NOT re-launch that sub-agent
4. If **invalid** (empty or missing sentinel) → re-launch the sub-agent, overwriting the file

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
