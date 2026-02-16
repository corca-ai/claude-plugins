# Retro — P0/P1 Prevention Controls

## Objective
Implement immediate prevention controls after the refactor incident, focused on deletion safety, workflow gate enforcement, and recommendation fidelity.

## What Worked
- Added deterministic fail-closed hooks for both deletion safety and workflow gate enforcement.
- Added list-safe live-state operations with gate-name validation and state-version bumping.
- Integrated broken-link triage protocol into shared guidance and surfaced it directly in link-check block output.
- Drift check passed after provenance alignment, confirming cross-surface consistency.

## What Nearly Failed
- Initial live-state update wrote to the prior session pointer before re-sync.
- Deletion safety script initially used `BASH_COMMAND` as a normal variable name, causing parsing mismatch.

## Corrective Actions Applied
- Standardized run initialization sequence (`set → sync → set`).
- Renamed command-parsing variable and added explicit functional tests for block/allow behavior.

## Remaining Risks
- Deletion safety currently favors false positives for basename matches.
- Workflow prompt intent detection is conservative but pattern-based; future multilingual intent expansion may be needed.

## Deferred Work
- Proposal D: script dependency graph checker
- Proposal F: session-log cross-check in `cwf:review --mode code`
- Proposal H: README structure sync checker
- Proposal I: shared reference extraction wave

### Post-Retro Findings
- We added PATH-level availability and setup dependency expansion in this same session because deterministic gates were already relying on markdown/link tooling during execution, while `cwf:setup` still treated part of that tooling as out-of-band.
- The immediate trigger was the `markdownlint-cli2 not installed` observation in validation flow. Even when `npx` fallback worked, `command -v` based checks and user expectation of `cwf:setup` coverage were misaligned.
- The correction was intentional architecture alignment, not a convenience tweak: make `cwf:setup` own installation attempts for required runtime binaries (including `markdownlint-cli2`, `lychee`, `npm`) and make degraded-mode escalation explicit when permissions or package managers block installation.
- This post-retro decision closes a contract gap: setup should configure both workflow logic and its deterministic execution prerequisites, otherwise quality gates become environment-dependent.
