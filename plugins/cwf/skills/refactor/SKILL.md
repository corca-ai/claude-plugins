---
name: refactor
description: "Multi-mode code and skill review. Quick scan all plugins, deep-review a single skill, holistic cross-plugin analysis, commit-based tidying, or docs consistency check. Triggers: \"cwf:refactor\", \"/refactor\", \"tidy\", \"review skill\", \"cleanup code\", \"check docs consistency\""
---

# Refactor (cwf:refactor)

Multi-mode code and skill review tool.

**Language**: Write review reports in English. Communicate with the user in their prompt language.

## Quick Reference

```text
cwf:refactor                        Quick scan all marketplace skills
cwf:refactor --code [branch]        Commit-based tidying (parallel sub-agents)
cwf:refactor --skill <name>         Deep review of a single skill (parallel sub-agents)
cwf:refactor --skill --holistic     Cross-plugin analysis (parallel sub-agents)
cwf:refactor --docs                 Documentation consistency review
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

- For each flagged skill (flag_count > 0), list the specific flags.
- Suggest: "Run `cwf:refactor --skill <name>` for a deep review."

---

## Code Tidying Mode (`--code [branch]`)

Analyze recent commits for safe tidying opportunities — guard clauses, dead code removal, explaining variables. Based on Kent Beck's "Tidy First?" philosophy.

### 1. Get Target Commits

Run the script to get recent non-tidying commits:

```bash
bash {SKILL_DIR}/scripts/tidy-target-commits.sh 5 [branch]
```

- If branch argument provided (e.g., `cwf:refactor --code develop`), pass it to the script.
- If no branch specified, defaults to HEAD.

### 2. Parallel Analysis with Sub-agents

**Resolve session directory**: Read `cwf-state.yaml` → `live.dir` to get the current session directory path.

```yaml
session_dir: "{live.dir value from cwf-state.yaml}"
```

Apply the [context recovery protocol](../../references/context-recovery-protocol.md) — for each commit N (1-indexed), check `{session_dir}/refactor-tidy-commit-{N}.md`.

For each commit hash that needs analysis, launch a **parallel sub-agent** using Task tool:

```yaml
Task tool:
  subagent_type: general-purpose
  max_turns: 12
```

Each sub-agent prompt:

1. Read `{SKILL_DIR}/references/tidying-guide.md` for techniques, constraints, and output format
2. Analyze commit diff: `git show {commit_hash}`
3. Check if changes still exist: `git diff {commit_hash}..HEAD -- {file}` (skip modified regions)
4. Return suggestions or "No tidying opportunities"
5. **Output Persistence**: Write your complete analysis to: `{session_dir}/refactor-tidy-commit-{N}.md`. At the very end of the file, append this sentinel marker on its own line: `<!-- AGENT_COMPLETE -->`

### 3. Aggregate Results

Read all result files from the session directory (`{session_dir}/refactor-tidy-commit-{N}.md` for each commit) and present:

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

### 4. Parallel Evaluation with Sub-agents

**Resolve session directory**: Read `cwf-state.yaml` → `live.dir` to get the current session directory path.

```yaml
session_dir: "{live.dir value from cwf-state.yaml}"
```

Apply the [context recovery protocol](../../references/context-recovery-protocol.md) to these files:

| Agent | Output file |
|-------|-------------|
| Structural Review | `{session_dir}/refactor-deep-structural.md` |
| Quality + Concept Review | `{session_dir}/refactor-deep-quality.md` |

Launch **2 parallel sub-agents** in a single message using Task tool (`subagent_type: general-purpose`, `max_turns: 12`) — only for agents whose result files are missing or invalid:

**Agent A — Structural Review** (Criteria 1–4):

Prompt includes:
- Target skill name and SKILL.md content
- All reference file contents and resource file listing
- `{SKILL_DIR}/references/review-criteria.md` criteria sections 1–4
- Instructions: Evaluate Size, Progressive Disclosure, Duplication, Resource Health. Return structured findings per criterion.
- **Output Persistence**: Write your complete findings to: `{session_dir}/refactor-deep-structural.md`. At the very end of the file, append this sentinel marker on its own line: `<!-- AGENT_COMPLETE -->`

**Agent B — Quality + Concept Review** (Criteria 5–8):

Prompt includes:
- Target skill name and SKILL.md content
- All reference file contents and resource file listing
- `{SKILL_DIR}/references/review-criteria.md` criteria sections 5–8
- `{PLUGIN_ROOT}/references/concept-map.md` (for Criterion 8: Concept Integrity)
- Instructions: Evaluate Writing Style, Degrees of Freedom, Anthropic Compliance, Concept Integrity. Return structured findings per criterion.
- **Output Persistence**: Write your complete findings to: `{session_dir}/refactor-deep-quality.md`. At the very end of the file, append this sentinel marker on its own line: `<!-- AGENT_COMPLETE -->`

Both agents analyze and report; neither modifies files.

### 5. Produce report

Read result files from the session directory (`{session_dir}/refactor-deep-structural.md`, `{session_dir}/refactor-deep-quality.md`). Merge both agents' findings into a unified report:

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

Cross-plugin analysis for global optimization. Read ALL skills and hooks, then analyze inter-plugin relationships.

### 1. Inventory

Read every SKILL.md and hooks.json across:
- `plugins/*/skills/*/SKILL.md` (marketplace plugins)
- `plugins/*/hooks/hooks.json` (hook plugins)
- `.claude/skills/*/SKILL.md` (local skills)

Build a condensed inventory map: plugin name, type (skill/hook/hybrid), word count, capabilities, dependencies.

### 2. Load analysis framework

Read `{SKILL_DIR}/references/holistic-criteria.md` for the three analysis axes.

### 3. Parallel Analysis with Sub-agents

**Resolve session directory**: Read `cwf-state.yaml` → `live.dir` to get the current session directory path.

```yaml
session_dir: "{live.dir value from cwf-state.yaml}"
```

Apply the [context recovery protocol](../../references/context-recovery-protocol.md) to these files:

| Agent | Output file |
|-------|-------------|
| Convention Compliance | `{session_dir}/refactor-holistic-convention.md` |
| Concept Integrity | `{session_dir}/refactor-holistic-concept.md` |
| Workflow Coherence | `{session_dir}/refactor-holistic-workflow.md` |

Launch **3 parallel sub-agents** in a single message using Task tool (`subagent_type: general-purpose`, `max_turns: 12`) — only for agents whose result files are missing or invalid:

**Agent A — Convention Compliance (Form)**:

Prompt includes:
- Condensed inventory map (name, type, word count, capabilities)
- `{SKILL_DIR}/references/holistic-criteria.md` Section 1 content
- `{PLUGIN_ROOT}/references/skill-conventions.md` content (shared conventions checklist)
- Instructions: Verify each skill against skill-conventions.md checklists. Identify good patterns one skill has that others should adopt. Detect repeated patterns across 3+ skills that should be extracted to shared references. Read individual SKILL.md files for deeper investigation as needed. Return structured findings.
- **Output Persistence**: Write your complete findings to: `{session_dir}/refactor-holistic-convention.md`. At the very end of the file, append this sentinel marker on its own line: `<!-- AGENT_COMPLETE -->`

**Agent B — Concept Integrity (Meaning)**:

Prompt includes:
- Condensed inventory map (name, type, word count, capabilities)
- `{SKILL_DIR}/references/holistic-criteria.md` Section 2 content
- `{PLUGIN_ROOT}/references/concept-map.md` content (generic concepts + synchronization map)
- Instructions: For each concept column in the synchronization map, compare how composing skills implement the same concept. Detect inconsistencies, under-synchronization, and over-synchronization. Read individual SKILL.md files for deeper investigation as needed. Return structured findings.
- **Output Persistence**: Write your complete findings to: `{session_dir}/refactor-holistic-concept.md`. At the very end of the file, append this sentinel marker on its own line: `<!-- AGENT_COMPLETE -->`

**Agent C — Workflow Coherence (Function)**:

Prompt includes:
- Condensed inventory map (name, type, word count, capabilities)
- `{SKILL_DIR}/references/holistic-criteria.md` Section 3 content
- Instructions: Check data flow completeness between skills, trigger clarity, and workflow automation opportunities. Read individual SKILL.md files for deeper investigation as needed. Return structured findings.
- **Output Persistence**: Write your complete findings to: `{session_dir}/refactor-holistic-workflow.md`. At the very end of the file, append this sentinel marker on its own line: `<!-- AGENT_COMPLETE -->`

All 3 agents analyze and report; none modify files.

### 4. Produce report

Read result files from the session directory (`{session_dir}/refactor-holistic-convention.md`, `{session_dir}/refactor-holistic-concept.md`, `{session_dir}/refactor-holistic-workflow.md`). Merge 3 agents' outputs into a unified report. Save to `{REPO_ROOT}/.cwf/prompt-logs/{YYMMDD}-refactor-holistic/analysis.md`. Create the directory if it doesn't exist (use next sequence number if date prefix already exists).

Report structure:

```markdown
# Cross-Plugin Analysis

> Date: {YYYY-MM-DD}
> Plugins analyzed: N skills, M hooks, L local skills

## Plugin Map
(table: name, type, words, key capabilities)

## 1. Convention Compliance (Form)
(structural consistency, pattern gaps, extraction opportunities)

## 2. Concept Integrity (Meaning)
(concept consistency, under/over-synchronization)

## 3. Workflow Coherence (Function)
(data flow, trigger clarity, automation opportunities)

## Prioritized Actions
(table: priority, action, effort, impact, affected plugins)
```

### 5. Discuss

Present the report summary. The user may want to discuss findings, adjust priorities, or plan implementation sessions. Update the report with discussion outcomes.

---

## Docs Review Mode (`--docs`)

Review documentation consistency across the repository.

### 1. Deterministic Tool Pass (Required First)

Before proposing any new documentation rule, run this placement gate:

- `AUTO_EXISTING`: already enforced by lint/hook/script → remove prose duplication, do not add rule text.
- `AUTO_CANDIDATE`: enforceable via lint/hook/script but missing automation → propose automation change first, do not add prose rule text.
- `NON_AUTOMATABLE`: judgment-only guidance → keep as concise principle with rationale.

Only `NON_AUTOMATABLE` items should become or remain documentation rules.

Run deterministic checks before semantic review:

```bash
npx --yes markdownlint-cli2 "**/*.md"
bash {SKILL_DIR}/scripts/check-links.sh --local --json
node {SKILL_DIR}/scripts/doc-graph.mjs --json
```

Use tool output as the source of truth for lint-level issues.

- If a tool is unavailable, report a tooling gap and continue with best-effort semantic review.
- Do not restate lint-level findings manually unless you add repository-level interpretation or restructuring impact.

### 2. Agent Entry Docs Review

Read the project's AGENTS.md (and runtime adapter docs like CLAUDE.md) and evaluate with `{SKILL_DIR}/references/docs-criteria.md` Section 1:

- Compressed-index shape
- Less-is-more signal quality (line-level high/medium/low utility scoring across the full file, not intro-only)
- What/why versus how boundary
- Document-role clarity (each linked doc is defined by what it is, not procedural trigger phrasing)
- Routing duplication minimization (avoid repeated listing of the same targets across sections unless purpose differs materially)
- Automation-redundant instructions
- Routing completeness
- Accuracy and staleness

### 3. Project Context Review

Read docs/project-context.md and check:

- Plugin listing matches actual plugins/ directory contents
- Architecture patterns are current (no references to removed/renamed plugins)
- Convention entries match actual practice

### 4. README Review

Read README.md and README.ko.md:

- Plugin overview table matches `marketplace.json` entries
- Each active plugin has install/update commands
- Deprecated plugins are clearly marked
- Korean version mirrors English structure and content

### 5. Cross-Document Consistency

Check alignment between:

- .claude-plugin/marketplace.json plugin list ↔ README overview table
- .claude-plugin/marketplace.json descriptions ↔ plugin manifest descriptions under plugins/
- docs/project-context.md plugin listing ↔ actual plugins/ contents
- Entry-doc references ↔ actual filesystem paths
- Root-relative internal links (leading-slash paths like /path/to/doc.md) ↔ portability check (prefer file-relative links)

Present findings as a prioritized list of inconsistencies with suggested fixes.

### 6. Document Design Quality (Semantic Layer)

Read `{SKILL_DIR}/references/docs-criteria.md` Section 5 and evaluate semantic/structural issues that deterministic tools cannot fully judge:

- Orphan intent and ownership boundary quality (using doc-graph output)
- Circular references or deep navigation paths (>3 hops)
- Inline overload (substantive content that should be a separate doc)
- Unnecessary hard wraps in prose (especially when MD013 is disabled)
- Auto-generated files committed to git
- Non-obvious decisions lacking documented rationale
- Self-evident or automation-redundant instructions
- Scope overlap and ownership ambiguity

### 7. Structural Optimization

Read `{SKILL_DIR}/references/docs-criteria.md` Section 6 and synthesize:

- Merge candidates (scope-overlapping docs → identify primary absorber)
- Deletion candidates (unique content fits elsewhere)
- AGENTS/adapter trimming proposals (obvious + automation-redundant + duplicated)
- Target structure: before/after doc set comparison
- Principle compliance: rate each doc against the 7 documentation principles
- Automation promotion candidates (manual findings that should move to lint/hooks/scripts)

Present as a concrete restructuring proposal with rationale.

---

## Rules

1. Write review reports in English, communicate with user in their prompt language
2. Deep Review and Holistic use perspective-based parallel sub-agents (not module-based)
3. Deep Review: 2 agents (structural 1-4 + quality/concept 5-8), single batch
4. Holistic: 3 agents (Convention Compliance, Concept Integrity, Workflow Coherence), single batch after inline inventory
5. Code Tidying: 1 agent per commit, all in one message
6. Docs Review: inline, no sub-agents (single-context synthesis over whole-repo graph and deterministic outputs)
7. Docs Review must run the deterministic tool pass before semantic analysis
8. In Docs Review, do not report lint/hook-detectable issues as standalone manual findings when tool output already covers them
9. Sub-agents analyze and report; orchestrator merges. Sub-agents do not modify files
10. All code fences must have a language specifier

## References

- Review criteria for deep review: [references/review-criteria.md](references/review-criteria.md)
- Holistic analysis framework: [references/holistic-criteria.md](references/holistic-criteria.md)
- Concept synchronization map: [concept-map.md](../../references/concept-map.md)
- Tidying techniques for --code mode: [references/tidying-guide.md](references/tidying-guide.md)
- Docs review criteria: [references/docs-criteria.md](references/docs-criteria.md)
- Shared agent patterns: [agent-patterns.md](../../references/agent-patterns.md)
- Skill conventions checklist: [skill-conventions.md](../../references/skill-conventions.md)
