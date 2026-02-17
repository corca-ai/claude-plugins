---
name: refactor
description: "Multi-mode code and skill review for controlling drift as capability surface grows. Quick scan all plugins, deep-review a single skill, holistic cross-plugin analysis, commit-based tidying, or docs consistency check. Triggers: \"cwf:refactor\", \"/refactor\", \"tidy\", \"review skill\", \"cleanup code\", \"check docs consistency\""
---

# Refactor (cwf:refactor)

Control drift across code, skills, and docs as teams install and author more capabilities.

**Language**: Write review reports in English. Communicate with the user in their prompt language.

## Quick Reference

```text
cwf:refactor                        Quick scan all marketplace skills
cwf:refactor --code [branch]        Commit-based tidying (parallel sub-agents)
cwf:refactor --skill <name>         Deep review of a single skill (parallel sub-agents)
cwf:refactor --skill --holistic     Cross-plugin analysis (parallel sub-agents)
cwf:refactor --docs                 Documentation consistency review
```

Philosophy:
- `cwf:refactor` (no args) is a maintenance heartbeat for ecosystem-level drift detection.
- `cwf:refactor --skill <name>` is for focused diagnosis when one authored/installed skill needs targeted correction without paying the cost of full holistic analysis.
- Portability is a default review axis across deep, holistic, and docs modes (no extra flag).

## Mode Routing

Parse the user's input:

| Input | Mode |
|-------|------|
| No args | Quick Scan |
| `--code` or `--code <branch>` | Code Tidying |
| `--skill <name>` | Deep Review |
| `--skill --holistic` or `--holistic` | Holistic Analysis |
| `--docs` | Docs Review |

## Provenance Sidecars (Required)

Before using any criteria document, verify its provenance sidecar against the current live repository state (current skill/hook counts).

| Criteria | Provenance sidecar |
|----------|--------------------|
| [review-criteria.md](references/review-criteria.md) | [review-criteria.provenance.yaml](references/review-criteria.provenance.yaml) |
| [holistic-criteria.md](references/holistic-criteria.md) | [holistic-criteria.provenance.yaml](references/holistic-criteria.provenance.yaml) |
| [docs-criteria.md](references/docs-criteria.md) | [docs-criteria.provenance.yaml](references/docs-criteria.provenance.yaml) |

Verification command:

```bash
bash {CWF_PLUGIN_DIR}/scripts/provenance-check.sh --level inform --json
```

Provenance verification rules:
- Confirm the mode-relevant sidecar entry exists in the checker output.
- Compare sidecar `skill_count`/`hook_count` with checker `current.skills`/`current.hooks`.
- If the sidecar is missing or stale, continue review but prepend a **Provenance Warning** and include the delta in the report.

---

## Quick Scan Mode (no args)

Resolve session directory (for deterministic artifact persistence):

```bash
session_dir=$(bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh get . dir)
```

Run the structural scan script and persist raw output:

```bash
bash {SKILL_DIR}/scripts/quick-scan.sh {REPO_ROOT} > {session_dir}/refactor-quick-scan.json
```

`{REPO_ROOT}` is the git repository root (5 levels up from SKILL.md in marketplace path, or use `git rev-parse --show-toplevel`).

Parse the JSON output and present a summary table. Also persist a concise summary to `{session_dir}/refactor-summary.md`:

| Plugin | Skill | Words | Lines | Flags |
|--------|-------|-------|-------|-------|

- For each flagged skill (flag_count > 0), list the specific flags.
- Suggest: "Run `cwf:refactor --skill <name>` for a deep review."
- Include `Mode: cwf:refactor (Quick Scan)` and the scan command in the summary file.

After writing summary artifacts, run deterministic gate:

```bash
bash {CWF_PLUGIN_DIR}/scripts/check-run-gate-artifacts.sh \
  --session-dir "{session_dir}" \
  --stage refactor \
  --strict \
  --record-lessons
```

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

**Resolve session directory**: Resolve the effective live-state file, then read `live.dir`.

```bash
live_state_file=$(bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh resolve)
```

```yaml
session_dir: "{live.dir value from resolved live-state file}"
```

Apply the [context recovery protocol](../../references/context-recovery-protocol.md) — for each commit N (1-indexed), check `{session_dir}/refactor-tidy-commit-{N}.md`.

For each commit hash that needs analysis, launch a **parallel sub-agent** using Task tool:
- Shared output persistence contract: [agent-patterns.md § Sub-agent Output Persistence Contract](../../references/agent-patterns.md#sub-agent-output-persistence-contract).

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

### 3. Verify criteria provenance

Run provenance verification before loading deep-review criteria:

```bash
bash {CWF_PLUGIN_DIR}/scripts/provenance-check.sh --level inform --json
```

Confirm the output includes [review-criteria.provenance.yaml](references/review-criteria.provenance.yaml). If its status is stale, continue but mark the final report with a provenance warning (include the skill/hook deltas).

### 4. Load review criteria

Read `{SKILL_DIR}/references/review-criteria.md` for the evaluation checklist.

### 5. Parallel Evaluation with Sub-agents

**Resolve session directory**: Resolve the effective live-state file, then read `live.dir`.

```bash
live_state_file=$(bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh resolve)
```

```yaml
session_dir: "{live.dir value from resolved live-state file}"
```

Derive a stable skill suffix from `--skill <name>` (lowercase, non-alphanumeric replaced with `-`):

```bash
skill_suffix="$(printf '%s' "{skill name}" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
```

Apply the [context recovery protocol](../../references/context-recovery-protocol.md) to these files:

| Agent | Output file |
|-------|-------------|
| Structural Review | `{session_dir}/refactor-deep-structural-{skill_suffix}.md` |
| Quality + Concept Review | `{session_dir}/refactor-deep-quality-{skill_suffix}.md` |

Launch **2 parallel sub-agents** in a single message using Task tool (`subagent_type: general-purpose`, `max_turns: 12`) — only for agents whose result files are missing or invalid:

**Agent A — Structural Review** (Criteria 1–4):

Prompt includes:
- Target skill name and SKILL.md content
- All reference file contents and resource file listing
- `{SKILL_DIR}/references/review-criteria.md` criteria sections 1–4
- Instructions: Evaluate Size, Progressive Disclosure, Duplication, Resource Health. Return structured findings per criterion.
- **Output Persistence**: Write your complete findings to: `{session_dir}/refactor-deep-structural-{skill_suffix}.md`. At the very end of the file, append this sentinel marker on its own line: `<!-- AGENT_COMPLETE -->`

**Agent B — Quality + Concept Review** (Criteria 5–9):

Prompt includes:
- Target skill name and SKILL.md content
- All reference file contents and resource file listing
- `{SKILL_DIR}/references/review-criteria.md` criteria sections 5–9
- `{PLUGIN_ROOT}/references/concept-map.md` (for Criterion 8: Concept Integrity)
- Instructions: Evaluate Writing Style, Degrees of Freedom, Anthropic Compliance, Concept Integrity, and Repository Independence/Portability. Return structured findings per criterion.
- **Output Persistence**: Write your complete findings to: `{session_dir}/refactor-deep-quality-{skill_suffix}.md`. At the very end of the file, append this sentinel marker on its own line: `<!-- AGENT_COMPLETE -->`

Both agents analyze and report; neither modifies files.

### 6. Produce report

Read result files from the session directory (`{session_dir}/refactor-deep-structural-{skill_suffix}.md`, `{session_dir}/refactor-deep-quality-{skill_suffix}.md`). Merge both agents' findings into a unified report:

```markdown
## Refactor Review: <name>

### Summary
- Word count: X (severity)
- Line count: X (severity)
- Resources: X total, Y unreferenced
- Duplication: detected/none
- Portability risks: detected/none

### Findings

#### [severity] Finding title
**What**: Description of the issue
**Where**: File and section
**Suggestion**: Concrete refactoring action

### Suggested Actions
1. Prioritized list of refactorings
2. Each with effort estimate (small/medium/large)
```

### 7. Offer to apply

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

### 2. Verify criteria provenance

Run provenance verification before loading holistic criteria:

```bash
bash {CWF_PLUGIN_DIR}/scripts/provenance-check.sh --level inform --json
```

Confirm the output includes [holistic-criteria.provenance.yaml](references/holistic-criteria.provenance.yaml). If stale, continue analysis but include a provenance warning and delta summary in the report.

### 3. Load analysis framework

Read `{SKILL_DIR}/references/holistic-criteria.md` for the three analysis axes and Section 0 portability baseline.

### 4. Parallel Analysis with Sub-agents

**Resolve session directory**: Resolve the effective live-state file, then read `live.dir`.

```bash
live_state_file=$(bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh resolve)
```

```yaml
session_dir: "{live.dir value from resolved live-state file}"
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
- `{SKILL_DIR}/references/holistic-criteria.md` Section 0 portability baseline
- `{PLUGIN_ROOT}/references/skill-conventions.md` content (shared conventions checklist)
- Instructions: Verify each skill against skill-conventions.md checklists. Identify good patterns one skill has that others should adopt. Detect repeated patterns across 3+ skills that should be extracted to shared references. Include structural portability findings (hardcoded paths/layout assumptions). Read individual SKILL.md files for deeper investigation as needed. Return structured findings.
- **Output Persistence**: Write your complete findings to: `{session_dir}/refactor-holistic-convention.md`. At the very end of the file, append this sentinel marker on its own line: `<!-- AGENT_COMPLETE -->`

**Agent B — Concept Integrity (Meaning)**:

Prompt includes:
- Condensed inventory map (name, type, word count, capabilities)
- `{SKILL_DIR}/references/holistic-criteria.md` Section 2 content
- `{SKILL_DIR}/references/holistic-criteria.md` Section 0 portability baseline
- `{PLUGIN_ROOT}/references/concept-map.md` content (generic concepts + synchronization map)
- Instructions: For each concept column in the synchronization map, compare how composing skills implement the same concept. Detect inconsistencies, under-synchronization, and over-synchronization. Include semantic portability findings (generic claims vs repo-locked behavior). Read individual SKILL.md files for deeper investigation as needed. Return structured findings.
- **Output Persistence**: Write your complete findings to: `{session_dir}/refactor-holistic-concept.md`. At the very end of the file, append this sentinel marker on its own line: `<!-- AGENT_COMPLETE -->`

**Agent C — Workflow Coherence (Function)**:

Prompt includes:
- Condensed inventory map (name, type, word count, capabilities)
- `{SKILL_DIR}/references/holistic-criteria.md` Section 3 content
- `{SKILL_DIR}/references/holistic-criteria.md` Section 0 portability baseline
- Instructions: Check data flow completeness between skills, trigger clarity, workflow automation opportunities, and runtime portability behavior under missing/variant repository structures. Read individual SKILL.md files for deeper investigation as needed. Return structured findings.
- **Output Persistence**: Write your complete findings to: `{session_dir}/refactor-holistic-workflow.md`. At the very end of the file, append this sentinel marker on its own line: `<!-- AGENT_COMPLETE -->`

All 3 agents analyze and report; none modify files.

### 5. Produce report

Read result files from the session directory (`{session_dir}/refactor-holistic-convention.md`, `{session_dir}/refactor-holistic-concept.md`, `{session_dir}/refactor-holistic-workflow.md`). Merge 3 agents' outputs into a unified report. Save to `{REPO_ROOT}/.cwf/projects/{YYMMDD}-refactor-holistic/analysis.md`. Create the directory if it doesn't exist (use next sequence number if date prefix already exists).

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

### 6. Discuss

Present the report summary. The user may want to discuss findings, adjust priorities, or plan implementation sessions. Update the report with discussion outcomes.

---

## Docs Review Mode (`--docs`)

Review documentation consistency with this fixed flow:
1. Resolve/bootstrap docs contract (`bootstrap-docs-contract.sh`)
2. Deterministic tool pass (`markdownlint`, local link check, doc-graph)
3. Docs criteria provenance verification
4. Contract-aware entry docs, project context, README, and cross-document consistency review
5. Semantic quality and structural optimization synthesis (portability baseline always on)

Deterministic tool pass uses [scripts/check-links.sh](scripts/check-links.sh) and [scripts/doc-graph.mjs](scripts/doc-graph.mjs) with markdownlint; for docs-contract runtime regression checks, run [scripts/check-docs-contract-runtime.sh](scripts/check-docs-contract-runtime.sh).

Use `{SKILL_DIR}/references/docs-criteria.md` for evaluation criteria, [references/docs-contract.md](references/docs-contract.md) for contract schema, and [references/docs-review-flow.md](references/docs-review-flow.md) for full `--docs` procedure (commands, sequence, and reporting scope).

---

## Rules

1. Write review reports in English, communicate with user in their prompt language
2. Deep Review and Holistic use perspective-based parallel sub-agents (not module-based)
3. Deep Review: 2 agents (structural 1-4 + quality/concept/portability 5-9), single batch
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
- Docs review contract schema: [references/docs-contract.md](references/docs-contract.md)
- Docs review procedure flow: [references/docs-review-flow.md](references/docs-review-flow.md)
- Provenance sidecar (deep criteria): [references/review-criteria.provenance.yaml](references/review-criteria.provenance.yaml)
- Provenance sidecar (holistic criteria): [references/holistic-criteria.provenance.yaml](references/holistic-criteria.provenance.yaml)
- Provenance sidecar (docs criteria): [references/docs-criteria.provenance.yaml](references/docs-criteria.provenance.yaml)
- Shared agent patterns: [agent-patterns.md](../../references/agent-patterns.md)
- Skill conventions checklist: [skill-conventions.md](../../references/skill-conventions.md)
