# CWF Artifact Path Policy

Current policy for CWF-generated artifacts under `.cwf/`.

## Decision

- Canonical artifact root: `.cwf/`
- Canonical session artifact directory: `.cwf/projects/`
- Project workflow state: [`.cwf/cwf-state.yaml`](../.cwf/cwf-state.yaml)
- Legacy root session-artifact compatibility: removed

## Scope

### Artifact classes

1. Machine state (cursor/state/rules/queues/cache)
2. Session artifacts (plans, lessons, retro, handoff, session logs)
3. Generated indexes (`cwf-index`/repo index outputs)

## Canonical Layout

```text
.cwf/
  projects/                    # canonical session artifacts
    {session-dir}/
      hitl/
        state.yaml
        rules.yaml
        queue.json
        events.log
  indexes/                     # generated indexes
```

## Implementation Rules

- All session-aware scripts and skills must resolve paths through `cwf-artifact-paths.sh`.
- Default resolver output must point to `.cwf/projects/`.
- User overrides can be set in .cwf/config.local.yaml / .cwf/config.yaml (preferred) or via `CWF_ARTIFACT_ROOT` and `CWF_PROJECTS_DIR` environment variables.
- New session runtime logs are written under `.cwf/projects/sessions/`.
- Session log symlinks in session dirs are stored under `session-logs/*.md` (multi-log support). `session-log.md` is a compatibility alias to one representative log.

## Guardrails

- No hard-coded legacy artifact path literals in active scripts/skills/docs.
- Deterministic checks (lint/link/index coverage) must exclude `.cwf/projects/` artifacts from normal doc quality gates.
- User-facing docs should reference commands and expected outputs, not migration-era compatibility behavior.
