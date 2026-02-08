# Agent Prompts Reference

Prompt template, domain detection, and dependency heuristics for cwf:impl.

---

## Implementation Agent Prompt Template

Use this template when constructing prompts for each implementation agent in
Phase 3b. Replace all `{placeholders}` with actual values.

````markdown
You are an implementation agent. Your job is to execute the assigned steps from
a plan precisely and completely.

## Goal

{goal from the plan}

## Your Assigned Steps

{numbered list of steps assigned to this agent, copied verbatim from plan}

## Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
{rows for files assigned to this agent}

## Success Criteria (your scope)

These BDD scenarios are relevant to your assigned steps. Your implementation
should satisfy them:

```gherkin
{relevant Given/When/Then scenarios}
```

## Don't Touch

These files are explicitly out of scope. Do NOT modify them under any
circumstances:

{list of Don't Touch files from plan}

## Context

{relevant context from the plan that helps understand the steps}

## Instructions

1. Read each assigned step carefully before starting
2. For each file to create: check if the parent directory exists first
3. For each file to modify: read the current content before editing
4. Follow existing codebase patterns — check neighboring files for conventions
5. Use language specifiers on all markdown code fences
6. After completing all steps, verify each file was created/modified as expected
7. Report what you completed, any issues encountered, and any deviations from
   the plan
````

---

## Domain Signal Table

Map file patterns and step keywords to implementation domains. Use this to assign
domain expertise descriptions when constructing agent prompts.

| File Pattern | Keywords | Domain | Agent Expertise |
|-------------|----------|--------|-----------------|
| `*.md`, `SKILL.md`, `CHANGELOG.md` | "document", "write", "draft" | Documentation | Markdown structure, skill frontmatter, reference organization |
| `*.sh`, `scripts/` | "script", "bash", "hook" | Shell/Scripting | Bash best practices, cross-platform compat, set -euo pipefail |
| `*.ts`, `*.js`, `*.mjs` | "node", "typescript", "api" | JavaScript/TypeScript | Node.js patterns, async/await, module systems |
| `*.py` | "python", "script" | Python | Python idioms, virtual environments, type hints |
| `*.json`, `plugin.json`, `hooks.json` | "config", "schema", "manifest" | Configuration | JSON schema, plugin manifests, marketplace entries |
| `*.yaml`, `*.yml` | "config", "workflow", "state" | Configuration | YAML structure, CI/CD workflows, state files |
| `references/*.md` | "reference", "guide", "template" | Reference Content | Instructional writing, template design, completeness |
| `hooks/scripts/` | "hook", "pre-tool", "post-tool" | Hook Development | Hook JSON format, stdin parsing, jq, exit codes |
| `SKILL.md` + `references/` | "skill", "phase", "workflow" | Skill Development | CWF skill patterns, phase structure, frontmatter |
| `tests/`, `*.test.*` | "test", "verify", "assert" | Testing | Test frameworks, assertion patterns, coverage |

When a step spans multiple domains, use the **primary domain** (the one with
the most files) for the agent expertise description. Mention secondary domains
in the context section.

---

## Dependency Detection Heuristics

Use these heuristics in Phase 2.2 to determine step ordering.

### File Overlap

Two steps that create or modify the **same file** must be sequential:

```text
Step 2: Create plugins/foo/SKILL.md
Step 4: Add Phase 3 to plugins/foo/SKILL.md
→ Sequential: Step 4 depends on Step 2
```

Exception: If both steps only **read** a file (not modify), they are independent.

### Output References

A step that references the **output** of a previous step is dependent:

```text
Step 1: Create the config schema in config.json
Step 3: Write validation logic that imports config.json schema
→ Sequential: Step 3 needs Step 1's output
```

Signals: "using the X from step N", "import from", "based on the output of",
file path mentioned in a prior step's "Files to Create" appears in a later
step's description.

### Ordering Keywords

Explicit ordering language creates dependencies:

| Keyword/Phrase | Interpretation |
|---------------|----------------|
| "after step N" | Depends on step N |
| "once X is done" | Depends on step that creates X |
| "then" (connecting two steps) | Sequential |
| "finally" | Last in sequence |
| "update ... created in step N" | Depends on step N |

### Independent Signals

Steps are parallel-safe when:

- They touch **different files** with no overlap
- They have **no cross-references** in their descriptions
- They are in **different domains** with no shared interfaces
- Their descriptions use **no ordering keywords**

---

## Simple Plan Detection

A plan qualifies for **Direct Execution (Phase 3a)** when ALL of these hold:

1. Total steps ≤ 3
2. Total files to create/modify ≤ 3
3. No step references output from another step
4. All steps are in the same or closely related domain

If any condition fails, use **Agent Team Execution (Phase 3b)**.

When in doubt, prefer Agent Team — the overhead of 2 agents is small compared
to the risk of a complex plan going wrong in direct execution.
