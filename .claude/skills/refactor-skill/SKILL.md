---
name: refactor-skill
description: |
  Review skills against skill-creator's Progressive Disclosure philosophy.
  Analyze SKILL.md size, duplication, unused resources, and suggest refactorings.
  Use --holistic for cross-plugin analysis (pattern propagation, boundary issues, missing connections).
  Triggers: "/refactor-skill"
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
  - Task
---

# Refactor Skill (/refactor-skill)

Review skills for Progressive Disclosure compliance and suggest refactorings.

**Language**: Match the user's language.

## Commands

```
/refactor-skill <name>       Deep review of a single skill
/refactor-skill              Quick scan all plugins, report flagged ones
/refactor-skill --holistic   Cross-plugin analysis: patterns, boundaries, connections
```

No args → run quick scan. With `<name>` → deep review. With `--holistic` → cross-plugin analysis.

## Quick Scan Mode (no args)

Run the structural scan script:

```bash
bash {SKILL_DIR}/scripts/quick-scan.sh
```

Parse the JSON output and present a summary table:

| Plugin | Skill | Words | Lines | Flags |
|--------|-------|-------|-------|-------|

For each flagged skill (flag_count > 0), list the specific flags.
Suggest: "Run `/refactor-skill <name>` for a deep review."

## Deep Review Mode (`<name>`)

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
2. **Progressive Disclosure** — Check three-level hierarchy compliance:
   - Metadata: only `name` + `description`, description includes triggers
   - Body: core workflow only, no detailed schemas/API docs/lookup tables
   - Resources: loaded on demand, large ones have grep patterns in SKILL.md
3. **Duplication** — Compare SKILL.md body with reference file contents. Flag overlapping paragraphs.
4. **Reference File Health** — Size, TOC presence, referenced in SKILL.md, no deep nesting.
5. **Unused Resources** — Files in scripts/references/assets not mentioned in SKILL.md.
6. **Writing Style** — Imperative form, no extraneous docs, concise examples.
7. **Degrees of Freedom** — Match instruction specificity to task fragility.

### 5. Produce report

Output a structured report:

```
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

## Holistic Mode (`--holistic`)

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
