# Plan: Add hello.sh with Test

## Task

"Add hello.sh printing hello with test"

## Scope Summary

- **Goal**: Create a `hello.sh` script that prints "hello" and a test script to verify it works
- **Key Decisions**: Test approach (shell-based assertion)
- **Known Constraints**: Minimal scope — one script, one test

## Steps

### Step 1: Create `hello.sh`

Create `hello.sh` at the project root:

```bash
#!/usr/bin/env bash

echo "hello"
```

Make it executable (`chmod +x`).

### Step 2: Create `test_hello.sh`

Create `test_hello.sh` at the project root:

```bash
#!/usr/bin/env bash

output=$(./hello.sh)
if [ "$output" = "hello" ]; then
  echo "PASS: hello.sh prints hello"
  exit 0
else
  echo "FAIL: expected 'hello', got '$output'"
  exit 1
fi
```

Make it executable and run it to verify.

## Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `hello.sh` | Create | Shell script that prints "hello" |
| `test_hello.sh` | Create | Test script that verifies hello.sh output |

## Success Criteria

### Behavioral (BDD)

```gherkin
Scenario: hello.sh prints hello
  Given hello.sh exists and is executable
  When the user runs ./hello.sh
  Then the output is exactly "hello"

Scenario: test passes
  Given hello.sh and test_hello.sh exist and are executable
  When the user runs ./test_hello.sh
  Then it exits with code 0
  And prints "PASS"
```

### Qualitative

- Scripts use portable [#!/usr/bin/env bash](#!/usr/bin/env bash) shebang
- Test provides clear PASS/FAIL output

## Commit Strategy

Single commit containing both `hello.sh` and `test_hello.sh` (atomic feature).

## Decision Log

| # | Decision Point | Evidence / Source | Alternatives Considered | Resolution | Status | Resolved By | Resolved At (UTC) |
|---|----------------|-------------------|-------------------------|------------|--------|-------------|-------------------|
| 1 | Test framework | Task is trivial; no external deps needed | bats, shunit2 | Plain shell assertion | resolved | agent | 2026-02-19 |
| 2 | Test file location | Single-script project | [tests/](tests/) subdirectory | Project root alongside `hello.sh` | resolved | agent | 2026-02-19 |

## Deferred Actions

- (none)
