# Plan — Minimal Smoke Plan

## Task

"Create a minimal smoke plan" — exercise the CWF plan→impl pipeline in the iter2 sandbox repo with a simple modification to the existing `hello.txt`.

## Goal

Modify `hello.txt` to append a second line, verifying the full CWF cycle (plan → impl → review) works end-to-end with an edit operation (as opposed to the prior session's file creation).

## Steps

### Step 1: Append line to hello.txt

- **Action**: Append a second line `Smoke iteration 2.` to `hello.txt`
- **Files to Modify**: `hello.txt`
- **Rationale**: Simplest possible edit that produces a verifiable git diff on an existing file. Tests the edit path (vs. the create path tested in iteration 1).

## Success Criteria

```gherkin
Given hello.txt exists at repo root with content "Hello, smoke test!"
When Step 1 is implemented
Then hello.txt contains two lines:
  | line | content              |
  | 1    | Hello, smoke test!   |
  | 2    | Smoke iteration 2.   |
And git diff shows exactly one added line in hello.txt
```

### Qualitative

- Change is atomic and trivially reversible
- No new files are created
- Diff is minimal and easy to review

## Commit Strategy

Per step — one commit for Step 1.

## Decision Log

| # | Decision Point | Evidence / Source | Alternatives Considered | Resolution | Status | Resolved By | Resolved At (UTC) |
|---|----------------|-------------------|-------------------------|------------|--------|-------------|-------------------|
| 1 | What change to make | `hello.txt` already exists from iteration 1; goal is minimal edit | Create a new file, modify README.md | Edit existing file — tests a different code path than iteration 1's create | resolved | agent | 2026-02-19 |
| 2 | Skip Phase 2 research | Repo has 2 files, task is trivially scoped | Launch full research agents | Adaptive sizing gate: skip — no value from research on a 2-file sandbox | resolved | agent | 2026-02-19 |

## Deferred Actions

- (none)
