# CWF Artifact Migration Status (`.cwf` First)

Current status for moving CWF-generated artifacts from repository root into `.cwf/`.

## Decision

- Final target: CWF-generated artifacts live under `.cwf/`.
- Current strategy: `.cwf` is the default write location for session artifacts and generated indexes.
- `cwf-state.yaml` remains the project SSOT and stores pointer metadata for relocated state.

## Scope

### Artifact classes

1. Machine state (cursor/state/rules/queues/cache)
2. Session logs and narrative docs (`prompt-logs/**`)
3. Generated indexes (`cwf-index`/repo index outputs)

### Compatibility policy

- Legacy reads from root `prompt-logs/**` remain supported during transition.
- New writes default to `.cwf/prompt-logs/**`.

## Target Layout

```text
.cwf/
  hitl/
    sessions/
      {session_id}/
        state.yaml
        rules.yaml
        queue.json
        events.log
  prompt-logs/                 # canonical session artifact location
  indexes/                     # generated-index location
```

## Phase Plan

## Phase 1 — HITL state-first migration (Completed)

- Introduce `cwf:hitl` state under `.cwf/hitl/sessions/**`.
- Keep `cwf-state.yaml` as pointer-only index for active HITL state.
- Do not move other skill artifact paths yet.

Exit criteria:
- HITL resume/restart works from `.cwf/hitl/**`.
- `cwf-state.yaml` pointer is sufficient to recover state.

## Phase 2 — Path abstraction for session artifacts (Completed)

- Add shared resolver for legacy and next-generation artifact roots.
- Update scripts/skills to consume resolver instead of hard-coded paths.
- Support dual-read (legacy + new) during transition.

Exit criteria:
- All session-aware skills resolve paths through shared abstraction.
- No direct hard-coded `prompt-logs/` writes in critical skills.

## Phase 3 — Prompt logs canonical move (Completed)

- Set canonical session artifact root to `.cwf/prompt-logs/`.
- Keep root `prompt-logs` compatibility via dual-read support.

Exit criteria:
- New sessions write to `.cwf/prompt-logs/` by default.
- Legacy readers continue to function.

## Phase 4 — Generated index consolidation (Completed)

- Consolidate generated index artifacts under `.cwf/indexes/`.
- Preserve AGENTS managed-block update behavior for repository index.
- Keep user-facing entrypoints stable.

Exit criteria:
- Index generation no longer creates root-level transient artifacts.
- Coverage/link checks remain deterministic.

## Phase 5 — Compatibility sunset (Pending)

- Remove legacy root `prompt-logs` read fallbacks after migration window closes.
- Simplify scripts to `.cwf`-only path resolution.
- Update docs to remove transition notes.

Exit criteria:
- No legacy-path dependency in active skills/hooks/scripts.

## Risks and Guardrails

- Risk: breaking resume for in-flight sessions.
  - Guardrail: dual-read period + pointer-based discovery.
- Risk: hidden hard-coded paths.
  - Guardrail: grep gate for `prompt-logs/` literals before each phase cutover.
- Risk: user discoverability drop.
  - Guardrail: keep user-facing docs focused on commands, not internal paths.
