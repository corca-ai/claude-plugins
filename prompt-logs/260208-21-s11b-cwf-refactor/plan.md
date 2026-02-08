# S11b Plan — Migrate refactor → cwf:refactor

## Context

CWF v3 harden phase (S11–S13). The standalone `refactor` plugin (v1.1.2) needs to migrate into `plugins/cwf/skills/refactor/` as `cwf:refactor`, following the established migration pattern from S7–S11a. The master plan specifies "parallel sub-agents per review perspective" as the enhancement target.

Session dir: `prompt-logs/260208-21-s11b-cwf-refactor/`

## Target Structure

```text
plugins/cwf/skills/refactor/
├── SKILL.md              (adapted — frontmatter + parallel sub-agent enhancement)
├── references/
│   ├── review-criteria.md    (verbatim copy)
│   ├── holistic-criteria.md  (verbatim copy)
│   ├── tidying-guide.md      (verbatim copy)
│   └── docs-criteria.md      (verbatim copy)
└── scripts/
    ├── quick-scan.sh          (verbatim copy)
    └── tidy-target-commits.sh (verbatim copy)
```

## Implementation Steps

### Step 1: Create directories and copy verbatim files

Create `plugins/cwf/skills/refactor/{references,scripts}`. Copy 4 reference files and 2 scripts from `plugins/refactor/skills/refactor/`. Verify with `diff` (all 6 must be IDENTICAL). `chmod +x` scripts.

### Step 2: Write adapted SKILL.md

Changes from source:
- Frontmatter: `"Use when user says"` → `"Triggers:"`, add `Edit`/`AskUserQuestion`, reorder tools (`Task` first)
- Title: `# Refactor (cwf:refactor)` (was `/refactor`)
- Quick Reference: prefix with `cwf:refactor`
- Deep Review: Replace inline step 4 with 2 parallel sub-agents (structural + quality)
- Holistic: Replace inline step 3 with 3 parallel sub-agents (per dimension)
- Add shared agent-patterns.md reference
- Add Rules section (8 rules)

### Step 3: Version bump CWF plugin 0.5.0 → 0.6.0

### Step 4: Create session artifacts

### Step 5: Register session in cwf-state.yaml

### Step 6: Run check-session.sh

## Parallel Enhancement Summary

| Mode | Current | Enhanced | Agent Count |
|------|---------|----------|-------------|
| Quick Scan | Script, no agents | No change | 0 |
| Code Tidying | Parallel per commit | No change | N (1 per commit) |
| Deep Review | Single inline | 2 parallel perspective agents | 2 |
| Holistic | Single inline | Inline inventory + 3 parallel dimension agents | 3 |
| Docs Review | Single inline | No change | 0 |

## Success Criteria

```gherkin
Given cwf:refactor is invoked with no args
When Quick Scan runs
Then the script executes and outputs a summary table

Given cwf:refactor --skill <name> is invoked
When Deep Review runs
Then 2 parallel sub-agents (structural + quality) are launched
And results are merged into the standard report format

Given cwf:refactor --holistic is invoked
When Holistic mode runs
Then inventory is built inline
And 3 parallel sub-agents (per dimension) are launched
And results are merged into the standard report format

Given cwf:refactor --code is invoked
When Code Tidying runs
Then parallel per-commit sub-agents launch (existing behavior preserved)

Given cwf:refactor --docs is invoked
When Docs Review runs
Then sequential inline analysis executes (existing behavior preserved)

Given all 6 verbatim-copied files
When compared with originals via diff
Then all report IDENTICAL
```
