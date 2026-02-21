# Plan — retro-cwf-081-plus-postmortem

## Objective

Run a deep retrospective focused on why post-`0.8.1` bugs (especially `cwf:update` latest-version detection and update UX drift) were not caught early, and define durable prevention mechanisms.

## Scope

- Version window: `0.8.1` to `0.8.8`
- Primary surface: `plugins/cwf/skills/update/`, release metadata sync, smoke/gate coverage
- Evidence sources:
  - git history (`plugins/cwf/.claude-plugin/plugin.json` version bumps)
  - prior audit artifacts (`.cwf/projects/260219-01-pre-release-audit-pass2/*`)
  - live retro evidence (`retro-evidence.md`)

## Required Outputs

- `retro.md` (deep mode, 7 sections)
- Deep companion files:
  - `retro-cdm-analysis.md`
  - `retro-learning-resources.md`
  - `retro-expert-alpha.md`
  - `retro-expert-beta.md`
