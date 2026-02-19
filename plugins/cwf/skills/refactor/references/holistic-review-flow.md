# Holistic Review Flow (`--skill --holistic` or `--holistic`)

Cross-plugin analysis for global optimization. Read all skills and hooks, then analyze inter-plugin relationships.

## 1. Inventory

Read every SKILL.md and hooks.json across:

- `plugins/*/skills/*/SKILL.md` (marketplace plugins)
- `plugins/*/hooks/hooks.json` (hook plugins)
- `.claude/skills/*/SKILL.md` (local skills)

Build a condensed inventory map: plugin name, type (skill/hook/hybrid), word count, capabilities, dependencies.

## 2. Verify criteria provenance

Run provenance verification before loading holistic criteria:

```bash
bash {CWF_PLUGIN_DIR}/scripts/provenance-check.sh --level inform --json
```

Confirm the output includes [holistic-criteria.provenance.yaml](holistic-criteria.provenance.yaml). If stale, continue analysis but include a provenance warning and delta summary in the report.

## 3. Load analysis framework

Read `{SKILL_DIR}/references/holistic-criteria.md` for the three analysis axes and Section 0 portability baseline.

## 4. Parallel Analysis with Sub-agents

Resolve session directory using [session-bootstrap.md](session-bootstrap.md) with bootstrap key `refactor-holistic`.

Apply the [context recovery protocol](../../../references/context-recovery-protocol.md) to these files:

| Agent | Output file |
|-------|-------------|
| Convention Compliance | `{session_dir}/refactor-holistic-convention.md` |
| Concept Integrity | `{session_dir}/refactor-holistic-concept.md` |
| Workflow Coherence | `{session_dir}/refactor-holistic-workflow.md` |

Launch **3 parallel sub-agents** in a single message using Task tool (`subagent_type: general-purpose`, `max_turns: 12`) — only for agents whose result files are missing or invalid.

Agent A — Convention Compliance (Form):

- Inventory map (name, type, word count, capabilities)
- `{SKILL_DIR}/references/holistic-criteria.md` Section 1 and Section 0
- `{PLUGIN_ROOT}/references/skill-conventions.md`
- Instructions: verify convention checklists, pattern gaps, extraction candidates, and structural portability findings.
- **Output Persistence**: write to `{session_dir}/refactor-holistic-convention.md` and append `<!-- AGENT_COMPLETE -->`

Agent B — Concept Integrity (Meaning):

- Inventory map
- `{SKILL_DIR}/references/holistic-criteria.md` Section 2 and Section 0
- `{PLUGIN_ROOT}/references/concept-map.md`
- Instructions: compare concept composition across skills; detect inconsistencies, under-synchronization, over-synchronization, and semantic portability issues.
- **Output Persistence**: write to `{session_dir}/refactor-holistic-concept.md` and append `<!-- AGENT_COMPLETE -->`

Agent C — Workflow Coherence (Function):

- Inventory map
- `{SKILL_DIR}/references/holistic-criteria.md` Section 3 and Section 0
- Instructions: analyze data-flow completeness, trigger clarity, automation opportunities, and runtime portability behavior.
- **Output Persistence**: write to `{session_dir}/refactor-holistic-workflow.md` and append `<!-- AGENT_COMPLETE -->`

All 3 agents analyze and report; none modify files.

## 5. Produce report

Read the three outputs and merge into a unified report saved to `{REPO_ROOT}/.cwf/projects/{YYMMDD}-refactor-holistic/analysis.md` (create directory; use next sequence when date prefix already exists).

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

## 6. Discuss

Present the report summary. Let the user adjust priorities and implementation order; update report when decisions change.
