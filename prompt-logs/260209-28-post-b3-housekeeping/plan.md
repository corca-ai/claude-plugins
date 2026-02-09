# Plan: Post S13.5-B3 Housekeeping

## Context

S13.5-B3 (concept-based refactor integration) completed, PR #18 merged into
`marketplace-v3`. Several housekeeping items were deferred: provenance files not
updated for new hook, experts not registered, master-plan not updated with B3.
Additionally, prompt-logs sequence numbering has been broken (260209 starts at 24
instead of 01), and the plan mode protocol needs improvement — session artifacts
should be created before plan mode entry so plan mode only does mechanical checks.

## Tasks

### 1. Provenance hook_count update (5 files)

Update `hook_count: 13` → `hook_count: 14` in 5 provenance files.
Reason: `exit-plan-mode.sh` added in S13.5-B3.

### 2. Expert roster update (cwf-state.yaml)

Add James Reason and Sidney Dekker to `expert_roster`.

### 3. Master-plan update

Add S13.5-B3 row to the workstream table.

### 4. Hook audit — document findings

Record hook audit results (NONE/LOW/MEDIUM risk categories) in lessons.md.

### 5. Fix prompt-logs sequence numbering

Create `scripts/next-prompt-dir.sh` for automatic sequence numbering.
Update `protocol.md` to reference this script.

### 6. Plan mode protocol improvement

Update protocol.md Timing section so session artifacts are created before
entering plan mode.

### 7. Session artifacts

Create session directory and register in cwf-state.yaml.

## Success Criteria

```gherkin
Given 5 provenance files with hook_count: 13
When hook_count is updated to 14
Then grep "hook_count: 13" returns 0 matches in provenance files
  And grep "hook_count: 14" returns exactly 5+ matches

Given expert_roster with 4 experts
When Reason and Dekker are added
Then expert_roster contains 6 entries with all required fields

Given master-plan workstream table missing B3
When B3 row is added
Then table shows A, B, B2, B3, C, D with correct statuses

Given scripts/next-prompt-dir.sh created
When run with "test-title"
Then output is "prompt-logs/YYMMDD-NN-test-title" with correct NN

Given updated protocol.md
When agent starts a session
Then session dir and artifacts are created before entering plan mode
```

## Deferred Actions

- [ ] Check if target documents (CLAUDE.md, project-context.md, etc.) need
      content updates for exit-plan-mode.sh
- [ ] Run `scripts/check-session.sh --impl` after implementation
- [ ] Run `/ship issue` if needed for remaining S13.5-C/D work
