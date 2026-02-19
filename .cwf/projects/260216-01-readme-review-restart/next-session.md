## Context Files to Read

1. [AGENTS.md](../../../AGENTS.md) — repository invariants and runtime behavior boundaries.
2. [docs/interactive-doc-review-protocol.md](../../../docs/interactive-doc-review-protocol.md) — interactive document review flow and HITL structure.
3. [plugins/cwf/skills/hitl/SKILL.md](../../../plugins/cwf/skills/hitl/SKILL.md) — resumable HITL review workflow.
4. [README.md](../../../README.md) — English canonical README under revision.
5. [README.ko.md](../../../README.ko.md) — Korean mirror under revision.
6. [plugins/cwf/skills/setup/SKILL.md](../../../plugins/cwf/skills/setup/SKILL.md) — setup UX contract (env migration included).

## Task Scope

Continue README/README.ko consistency review and apply remaining doc-quality corrections with HITL-friendly checkpoints.

### What to Build

- Finalize wording and structure changes requested in prior review rounds.
- Keep Korean text natural and remove unnecessary English parallel text in Korean docs.
- Keep skill/order/navigation consistent with canonical CWF ordering.
- Preserve single-plugin framing while removing repetitive phrasing.

### Key Design Points

- Prioritize user language for HITL communication and excerpt readability.
- Keep install/setup discoverability early in README, especially Codex compatibility and env setup.
- Use concise section-link style for skills (for example, heading-level skill links) instead of repeating `SKILL.md` lines.
- Treat `.cwf/prompt-logs/` as archive artifacts (not active docs).

## Don't Touch

- Do not rewrite historical archive content under `.cwf/prompt-logs/` except when explicitly requested.
- Do not revert unrelated in-flight implementation changes outside README/setup/doc-review scope.
- Do not reintroduce `CLAUDE_CORCA_*` or `CLAUDE_ATTENTION_*` as active canonical settings.

## Lessons from Prior Sessions

1. **Single-entry UX reduces friction** (S12/S24): optional setup knobs should be asked interactively in `cwf:setup`, not delegated to user memorization.
2. **Archive docs can break gates** (recent pre-commit run): lint/link checks should exclude historical prompt logs to avoid false blockers.
3. **Path consistency must be end-to-end** (recent migration): `.cwf/projects` needs script/docs/hook alignment together, not partial replacement.

## Success Criteria

```gherkin
Given the remaining README/README.ko review backlog
When the session applies edits and runs markdown/link checks
Then both READMEs are consistent, readable, and free of agreed terminology/structure issues.
```

```gherkin
Given users run `cwf:setup` without extra flags
When setup reaches environment configuration
Then legacy env keys are detected and migration choices are offered interactively.
```

```gherkin
Given archive artifacts exist in `.cwf/prompt-logs/`
When git hooks and markdown lint run
Then archive markdown files are excluded from lint gates by default.
```

## Dependencies

- Requires: commit `ff53f08` (projects path migration + legacy env cleanup baseline).
- Blocks: final README polish pass and subsequent v3 pre-release packaging.

## Dogfooding

Discover available CWF skills via the plugin's `skills/` directory or
trigger list in skill descriptions. Use CWF skills for review/handoff flow
instead of ad-hoc manual sequencing.

## Execution Contract (Mention-Only Safe)

If the user mentions only this file, treat it as an instruction to resume
README review execution directly.

- Branch gate:
  - Before implementation edits, check current branch.
  - If on a base branch (`main`, `master`, or repo primary branch), create/switch
    to a feature branch and continue.
- Commit gate:
  - Commit during execution in meaningful units (doc structure, setup UX, validation fixes).
  - Avoid one monolithic end-of-session commit when multiple logical units exist.
  - After each completed unit, run `git status --short` and commit before starting
    the next major unit.
- Staging policy:
  - Stage only intended files for each commit unit.
  - Do not use broad staging that may include unrelated changes.

## Start Command

```text
Resume README/README.ko review from this handoff file, apply remaining fixes, run checks, then commit and push.
```
