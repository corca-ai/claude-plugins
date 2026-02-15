# Next Session: README.ko HITL Review Restart

## Goal

Resume human-in-the-loop review starting from `README.ko.md`, with Korean wording consistency checks against `README.md`.

## Context Files to Read

1. `AGENTS.md`
2. `docs/interactive-doc-review-protocol.md`
3. `plugins/cwf/skills/hitl/SKILL.md`
4. `README.md`
5. `README.ko.md`

## Execution Contract (Mention-Only Safe)

If the user mentions only this file, execute directly:

1. Run `cwf:hitl --resume --scope docs`.
2. If no resumable cursor exists, start a new HITL queue from `README.ko.md`.
3. Apply review/fix policy:
   - `in_review` chunk fixes: immediate apply allowed.
   - `reviewed` area fixes: default to `fix-queue.yaml`.
   - If user explicitly requests immediate edit on reviewed area: apply edit, mark overlapping chunks `stale`, and run delta-review before close.
4. Keep review outputs concise and line-anchored.

## Start Command

```text
@.cwf/prompt-logs/260214-01-s25-post-s24-followup-retro-day2/next-session-readme-ko-hitl.md 시작합니다
```
