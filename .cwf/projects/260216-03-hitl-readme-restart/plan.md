# Plan (Backfilled): 260216-03-hitl-readme-restart

> Backfilled at: 2026-02-16

## Session Goal

Harden workflow reliability after restart by fixing dependency handling, retro contract behavior, and session-log path consistency.

## Scope

- Install missing local dependency (`shellcheck`) and enforce install-prompt retry behavior
- Complete deep retro artifacts and persistence updates
- Normalize session log path handling with legacy compatibility
- Improve `check-session` usability (`--help`, session-dir selector)

## Deliverables

- Updated scripts/docs for session logging and retro behavior
- Completed retro artifacts under this session directory
- Backfilled baseline artifacts (`plan.md`, `lessons.md`)

## Success Criteria

- `check-session --live` passes
- Session log file is generated under `.cwf/sessions/` (legacy alias preserved)
- Session baseline artifacts are complete
