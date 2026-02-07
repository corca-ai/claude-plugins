---
name: suggest-tidyings
description: Analyze recent commits to suggest safe tidying opportunities—guard clauses, dead code removal, explaining variables. Use when user says "suggest tidyings", "tidy", "find refactoring", "cleanup code", or wants to improve readability without changing behavior. Accepts optional branch argument.
---

# Suggest Tidyings

Analyze recent commits to find small, safe code improvements.

**Key Principle**: Each suggestion must be a perfectly safe, independent, small change. No logic changes, easy to review.

## Workflow

### 1. Get Target Commits

Run the script to get recent non-tidying commits:

```bash
{SKILL_DIR}/scripts/tidy-target-commits.sh 5 [branch]
```

- If branch argument provided (e.g., `/suggest-tidyings develop`), pass it to the script
- If no argument, defaults to HEAD

### 2. Parallel Analysis with Sub-agents

For each commit hash, launch a **parallel sub-agent** using Task tool:

```yaml
Task tool with subagent_type: general-purpose
```

Each sub-agent should:

1. Read `{SKILL_DIR}/references/tidying-guide.md` for techniques, constraints, and output format
2. Analyze commit diff: `git show {commit_hash}`
3. Check if changes still exist: `git diff {commit_hash}..HEAD -- {file}` (skip modified regions)
4. Return suggestions or "No tidying opportunities"

### 3. Aggregate Results

Collect all sub-agent results and present:

```markdown
# Tidying Analysis Results

## Commit: {hash} - {message}
- suggestion 1
- suggestion 2

## Commit: {hash} - {message}
- No tidying opportunities
```

## References

- Tidying techniques and output format: [references/tidying-guide.md](references/tidying-guide.md)
