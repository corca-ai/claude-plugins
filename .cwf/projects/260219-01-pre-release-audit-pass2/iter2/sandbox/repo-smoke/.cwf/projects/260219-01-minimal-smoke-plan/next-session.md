# Next Session — Complete Smoke Implementation

> Handoff from: 260219-01-minimal-smoke-plan
> Written: 2026-02-19

## Context Files to Read

1. `.cwf/projects/260219-01-minimal-smoke-plan/plan.md` — approved smoke plan (create `hello.txt`)
2. `.cwf/projects/260219-01-minimal-smoke-plan/lessons.md` — session learnings (currently empty)
3. `.cwf/sessions/260219-1442-46d8d3db.claude.md` — impl session log (interrupted before file creation)
4. `.cwf/sessions/260219-1443-221a69dc.claude.md` — refactor quick-scan session log
5. `.cwf/sessions/review-security-plan.md` — security review (no blocking concerns)
6. `.cwf/sessions/review-ux-dx-plan.md` — UX/DX review (no blocking concerns)
7. `CLAUDE.md` — runtime adapter instructions (in parent repo `/home/hwidong/codes/claude-plugins/`)

## Task Scope

The previous session (`260219-01-minimal-smoke-plan`) ran the full CWF pipeline — setup, clarify, plan, review, impl, refactor — but the implementation step was interrupted before `hello.txt` was actually created. The repo still contains only `README.md`.

**This session completes the cycle:**

1. Create `hello.txt` at repo root with content `Hello, smoke test!`
2. Verify all success criteria from the plan pass
3. Commit the change on `feat/minimal-smoke-plan` branch

This is a 1-step, 1-file task. Treat the existing plan as already reviewed and approved (security + UX/DX reviews both passed with no blocking concerns).

## Don't Touch

- `README.md` — no modifications
- `.cwf/` directory — session artifacts are read-only for this task
- `.githooks/` — hook configuration is already set up
- Any files outside the repo root

## Lessons from Prior Sessions

No implementation learnings were recorded (lessons.md is empty — the impl session was interrupted before producing findings).

**Observations from session history:**
- The `cwf:setup --env` session had repeated AskUserQuestion failures (tool permission issues in sandbox), suggesting the sandbox environment may require broader tool permissions upfront
- The `cwf:impl` session created the feature branch `feat/minimal-smoke-plan` but did not complete file creation
- The `cwf:refactor --mode quick` session ran successfully and produced a refactor summary

## Success Criteria

```gherkin
Given the repo contains only README.md
When hello.txt is created at repo root with content "Hello, smoke test!"
Then hello.txt exists at repo root
And hello.txt contains exactly "Hello, smoke test!"
And git status shows hello.txt as a new untracked or staged file
And no existing files are modified (git diff shows no changes to tracked files)
And a commit is created on feat/minimal-smoke-plan with hello.txt
```

## Dependencies

- **Branch**: `feat/minimal-smoke-plan` already exists — switch to it if not already on it
- **Git hooks**: pre-commit and pre-push hooks are installed in `.githooks/`
- **No external dependencies**: this is a standalone file creation

## Dogfooding

Discover available CWF skills by scanning the `skills/` directory under the CWF plugin root. Use `cwf:impl` to execute the implementation if exercising the full pipeline is desired, or implement directly for a minimal completion.

## Execution Contract (Mention-Only Safe)

1. **Mention-only execution**: If the user input only mentions `next-session.md` (with or without "start"), treat it as "execute this handoff", not as a request to summarize the file.
2. **Branch gate before implementation edits**: Before creating `hello.txt`, detect the current branch. If on a base branch (`main`, `master`), switch to `feat/minimal-smoke-plan` and continue execution.
3. **Commit gate during execution**: After creating `hello.txt`, run `git status --short` to verify the change, then commit as a single meaningful unit (this is a 1-file change so one commit is appropriate).
4. **Selective staging**: Stage only `hello.txt`. Do not use `git add -A` or `git add .` which could capture unrelated changes.

## Start Command

> Create `hello.txt` at repo root with content "Hello, smoke test!", verify success criteria, and commit on `feat/minimal-smoke-plan`.
