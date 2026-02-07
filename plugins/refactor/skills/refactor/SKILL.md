---
name: refactor
description: |
  Multi-mode code and skill review. Quick scan all plugins, deep-review a single skill,
  holistic cross-plugin analysis, commit-based tidying, or docs consistency check.
  Use when user says "/refactor", "tidy", "review skill", "cleanup code",
  "check docs consistency", or wants to improve code or skill quality.
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
  - Task
---

# Refactor (/refactor)

Multi-mode code and skill review tool.

**Language**: Match the user's language.

## Quick Reference

```text
/refactor                        Quick scan all marketplace skills
/refactor --code [branch]        Commit-based tidying (parallel sub-agents)
/refactor --skill <name>         Deep review of a single skill
/refactor --skill --holistic     Cross-plugin analysis (pattern, boundary, connections)
/refactor --docs                 Documentation consistency review
```

## Mode Routing

Parse the user's input:

| Input | Mode |
|-------|------|
| No args | Quick Scan |
| `--code` or `--code <branch>` | Code Tidying |
| `--skill <name>` | Deep Review |
| `--skill --holistic` or `--holistic` | Holistic Analysis |
| `--docs` | Docs Review |

---

## Quick Scan Mode (no args)

Run the structural scan script:

```bash
bash {SKILL_DIR}/scripts/quick-scan.sh {REPO_ROOT}
```

`{REPO_ROOT}` is the git repository root (5 levels up from SKILL.md in marketplace path, or use `git rev-parse --show-toplevel`).

Parse the JSON output and present a summary table:

| Plugin | Skill | Words | Lines | Flags |
|--------|-------|-------|-------|-------|

For each flagged skill (flag_count > 0), list the specific flags.
Suggest: "Run `/refactor --skill <name>` for a deep review."

---

## Code Tidying Mode (`--code [branch]`)

Analyze recent commits for safe tidying opportunities — guard clauses, dead code removal,
explaining variables. Based on Kent Beck's "Tidy First?" philosophy.

### 1. Get Target Commits

Run the script to get recent non-tidying commits:

```bash
bash {SKILL_DIR}/scripts/tidy-target-commits.sh 5 [branch]
```

- If branch argument provided (e.g., `/refactor --code develop`), pass it to the script.
- If no branch specified, defaults to HEAD.

### 2. Parallel Analysis with Sub-agents

For each commit hash, launch a **parallel sub-agent** using Task tool:

```yaml
Task tool with subagent_type: general-purpose
```

Each sub-agent prompt:

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

---

## Deep Review Mode (`--skill <name>`)

### 1. Locate the skill

Search for the SKILL.md in this order:
1. `plugins/<name>/skills/<name>/SKILL.md` (marketplace plugin)
2. `plugins/<name>/skills/*/SKILL.md` (skill name differs from plugin name)
3. `.claude/skills/<name>/SKILL.md` (local skill)

If not found, report error and stop.

### 2. Read the skill

Read the SKILL.md and all files in `references/`, `scripts/`, and `assets/` directories.

### 3. Load review criteria

Read `{SKILL_DIR}/references/review-criteria.md` for the evaluation checklist.

### 4. Evaluate against criteria

Apply each criterion from review-criteria.md:

1. **SKILL.md Size** — Word count and line count against thresholds.
2. **Progressive Disclosure** — Three-level hierarchy compliance.
3. **Duplication** — Compare SKILL.md body with reference file contents.
4. **Reference File Health** — Size, TOC presence, referenced in SKILL.md, no deep nesting.
5. **Unused Resources** — Files in scripts/references/assets not mentioned in SKILL.md.
6. **Writing Style** — Imperative form, concise examples, no extraneous docs.
7. **Degrees of Freedom** — Match instruction specificity to task fragility.
8. **Anthropic Compliance** — Folder naming, description quality, composability.

### 5. Produce report

Output a structured report:

```markdown
## Refactor Review: <name>

### Summary
- Word count: X (severity)
- Line count: X (severity)
- Resources: X total, Y unreferenced
- Duplication: detected/none

### Findings

#### [severity] Finding title
**What**: Description of the issue
**Where**: File and section
**Suggestion**: Concrete refactoring action

### Suggested Actions
1. Prioritized list of refactorings
2. Each with effort estimate (small/medium/large)
```

### 6. Offer to apply

Ask the user if they want to apply any suggestions. If yes, implement the refactorings.

---

## Holistic Mode (`--skill --holistic` or `--holistic`)

Cross-plugin analysis for global optimization. Read ALL skills and hooks, then analyze
inter-plugin relationships.

### 1. Inventory

Read every SKILL.md and hooks.json across:
- `plugins/*/skills/*/SKILL.md` (marketplace plugins)
- `plugins/*/hooks/hooks.json` (hook plugins)
- `.claude/skills/*/SKILL.md` (local skills)

Build a map: plugin name, type (skill/hook/hybrid), word count, capabilities, dependencies.

### 2. Load analysis framework

Read `{SKILL_DIR}/references/holistic-criteria.md` for the three analysis dimensions.

### 3. Analyze

Apply the three dimensions from the framework to the full inventory. Read each SKILL.md
body (references/ excluded unless needed for a specific finding). For each finding, cite
the specific skills and sections involved.

### 4. Produce report

Save to `{REPO_ROOT}/prompt-logs/{YYMMDD}-refactor-holistic/analysis.md`. Create the
directory if it doesn't exist (use next sequence number if date prefix already exists).

Report structure:
```markdown
# Cross-Plugin Analysis

> Date: {YYYY-MM-DD}
> Plugins analyzed: N skills, M hooks, L local skills

## Plugin Map
(table: name, type, words, key capabilities)

## 1. Pattern Propagation
(good patterns one skill has that others should adopt)

## 2. Boundary Issues
(overlapping roles, ambiguous triggers, unclear when-to-use)

## 3. Missing Connections
(natural handoffs between skills that are currently broken)

## Prioritized Actions
(table: priority, action, effort, impact, affected plugins)
```

### 5. Discuss

Present the report summary. The user may want to discuss findings, adjust priorities,
or plan implementation sessions. Update the report with discussion outcomes.

---

## Docs Review Mode (`--docs`)

Review documentation consistency across the repository.

### 1. CLAUDE.md Review

Read the project's `CLAUDE.md` and evaluate:
- Size: flag if exceeding ~200 lines (progressive disclosure — details belong in docs/)
- Accuracy: do referenced files/paths exist?
- Staleness: do referenced plugins/skills still exist and match current state?

### 2. Project Context Review

Read `docs/project-context.md` and check:
- Plugin listing matches actual `plugins/` directory contents
- Architecture patterns are current (no references to removed/renamed plugins)
- Convention entries match actual practice

### 3. README Review

Read `README.md` and `README.ko.md`:
- Plugin overview table matches `marketplace.json` entries
- Each active plugin has install/update commands
- Deprecated plugins are clearly marked
- Korean version mirrors English structure and content

### 4. Cross-Document Consistency

Check alignment between:
- `marketplace.json` plugin list ↔ README overview table
- `marketplace.json` descriptions ↔ `plugin.json` descriptions
- `docs/project-context.md` plugin listing ↔ actual `plugins/` contents
- Dead internal links (file references that don't resolve)

Present findings as a prioritized list of inconsistencies with suggested fixes.

### 5. Document Design Quality

Read `{SKILL_DIR}/references/docs-criteria.md` Section 5 and evaluate:
- Orphaned documents unreachable from entry points
- Circular references or deep navigation paths (>3 hops)
- Inline overload (substantive content that should be a separate doc)
- Auto-generated files committed to git
- Non-obvious decisions lacking documented rationale
- Self-evident instructions wasting reader attention

---

## References

- Review criteria for deep review: [references/review-criteria.md](references/review-criteria.md)
- Holistic analysis framework: [references/holistic-criteria.md](references/holistic-criteria.md)
- Tidying techniques for --code mode: [references/tidying-guide.md](references/tidying-guide.md)
- Docs review criteria: [references/docs-criteria.md](references/docs-criteria.md)
