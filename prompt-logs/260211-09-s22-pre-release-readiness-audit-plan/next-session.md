# Next Session: S23 — Execute S22 Concerns 1-3 + Prepare Step 4 Prompt

## Context

S22 established a full-coverage, quality-first audit plan for release readiness.
The next session should execute concerns 1-3 autonomously, then generate a
high-fidelity interactive prompt for concern 4 and pause for user-led walkthrough.

## Context Files to Read First

1. `prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/plan.md`
2. `prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/lessons.md`
3. `plugins/cwf/skills/refactor/SKILL.md`
4. `README.md`
5. `README.ko.md`
6. `AGENTS.md`
7. `cwf-index.md`

## Execution Contract (Mention-Only Safe)

If the user mentions only this file, treat that as an instruction to execute
S22 phase-split audit work immediately.

- Required strategy: depth-first validation (quality over speed)
- Branch gate:
  - Before implementation edits, check current branch.
  - If on `main`/`master` (or repo primary branch), create/switch to a feature branch and continue.
- Commit gate:
  - Commit in meaningful units during execution (not monolithic at the end).
  - Stage only files for the current unit; avoid broad staging.
- Phase A coverage (autonomous):
  - `cwf:refactor --docs`
  - `cwf:refactor --holistic`
  - `cwf:refactor --skill <name>` for all 11 CWF skills
  - `cwf:refactor --code` (current branch context)
  - full script-path audit (`plugins/cwf/hooks/scripts/*`, `plugins/cwf/skills/*/scripts/*`, `scripts/*`, `scripts/codex/*`)
- Required gates:
  - README framing gate (is/is-not, assumptions, decisions+why)
  - discoverability architecture gate (entry path and self-containment)
  - first-user onboarding gate is deferred to interactive Step 4
- Required outputs for this run:
  - `refactor-evidence.md`
  - `skill-coverage-matrix.md`
  - `script-coverage-matrix.md`
  - `readme-framing-audit.md`
  - `discoverability-audit.md`
  - `readiness-prestep4.md`
  - `step4-interactive-prompt.md`
- Completion policy:
  - explicit pass/fail status for concerns 1-3
  - stop after writing `step4-interactive-prompt.md` and wait for user
  - no final Go/No-Go before interactive Step 4
  - register session state and run `scripts/check-session.sh --impl`

## Task

Execute S22 concerns 1-3 as written, then produce the Step 4 interactive prompt.
Stop after prompt generation; final walkthrough and Go/No-Go happen with user.

## Success Criteria

```gherkin
Given S22 full-coverage audit plan and repository state
When S23 executes concerns 1-3 plus prompt preparation
Then all required pre-Step4 artifacts are produced with file-level findings

Given Step 4 is explicitly interactive
When autonomous execution finishes
Then the session stops with a reusable user+agent walkthrough prompt
```

## Start Command

```text
@prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/next-session.md 시작합니다
```
