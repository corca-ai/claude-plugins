# Plan — Minimal Smoke Test for hello.sh

## Task

"Create a minimal smoke plan" — verify that `hello.sh` prints the expected output and that `test_hello.sh` validates it.

## Scope Summary

- **Goal**: Ensure `hello.sh` outputs `hello` and `test_hello.sh` passes
- **Key Decisions**: None — scope is trivially clear
- **Known Constraints**: Two files only (`hello.sh`, `test_hello.sh`), both already staged on `feat/hello-script`

## Steps

### Step 1: Make scripts executable

Ensure both `hello.sh` and `test_hello.sh` have execute permissions.

**Files**: `hello.sh`, `test_hello.sh`

### Step 2: Run smoke test

Execute `test_hello.sh` and verify it exits with code 0 and prints `PASS`.

**Files**: `test_hello.sh` (run only)

## Success Criteria

```gherkin
Given hello.sh exists with content `echo "hello"`
When I run ./test_hello.sh
Then it prints "PASS: hello.sh prints hello"
And exits with code 0
```

### Qualitative

- No unnecessary files or changes introduced
- Scripts are portable (use `#!/usr/bin/env bash`)

## Commit Strategy

Per step — one commit for permission fix (if needed), one for verified smoke test pass.

## Decision Log

| # | Decision Point | Evidence / Source | Alternatives Considered | Resolution | Status | Resolved By | Resolved At (UTC) |
|---|----------------|-------------------|-------------------------|------------|--------|-------------|-------------------|
| 1 | Skip parallel research | Task is 2-file smoke test — adaptive sizing gate: narrow scope | Launch full research agents | Skip Phase 2 entirely | resolved | agent | 2026-02-19 |

## Deferred Actions

- (none)
