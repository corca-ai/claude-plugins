# CWF Skill Conventions

Shared structural conventions for all skills in the CWF plugin. Use this as a template when creating new skills and as a checklist when reviewing existing ones.

## SKILL.md Structure

Every skill MUST follow this section order:

```text
---
(frontmatter)
---

# {Title}

{1-2 line description}

**Language**: Write {artifact type} in English. Communicate with the user in their prompt language.

## Quick Start / Quick Reference

## {Phases / Workflow}

## Rules

## References
```

## Frontmatter

```yaml
---
name: {skill-name}
description: |
  {One-line description.}
  Triggers: "{cwf:name}", "{natural language triggers}"
allowed-tools:
  - {tool list — alphabetical order recommended}
---
```

- `name`: lowercase, matches directory name
- `description`: multi-line with `|`, includes `Triggers:` line
- `allowed-tools`: only tools the skill actually uses

## Language Declaration

Place immediately after the 1-2 line description, before any sections.

**Standard pattern**:

```text
**Language**: Write {artifact type} in English. Communicate with the user in their prompt language.
```

**Exception**: Skills producing user-facing artifacts in the user's language (e.g., retro) may use:

```text
**Language**: Write {artifact} in the user's language. Communicate with the user in their prompt language.
```

## Context-Deficit Resilience (Global Contract)

All CWF skills must remain executable when prior conversation context is missing or truncated.

- Do not depend on implicit chat memory.
- Recover intent from persisted state/artifacts/handoff files first.
- If required artifacts are missing, fail with explicit remediation steps (which file is missing and how to regenerate it).

Minimum fallback path for context-deficit conditions:
1. Resolve effective live-state file (`cwf-live-state.sh resolve`).
2. Load session directory artifacts (`plan.md`, `lessons.md`, `retro.md`, `next-session.md`, `phase-handoff.md` as applicable).
3. Apply skill-specific deterministic recovery gates before continuing.

## Runtime Script Path Placeholder (Global Contract)

For CWF runtime helper commands in SKILL/references docs:

- Use `{CWF_PLUGIN_DIR}/scripts/...` as the canonical placeholder form.
- Do not use `{SKILL_DIR}/../../scripts/...` in new or updated instructions.
- In this repository, `{CWF_PLUGIN_DIR}` resolves to [plugins/cwf](..).

## Missing Dependency Handling (Global Contract)

When a required executable/library/key is missing:

- Do not end with a passive "missing/unavailable" message only.
- Ask whether the user wants to install/configure now.
- If install is approved, run the concrete install/config command and retry the failed step once.
- If installation is declined or fails, provide exact follow-up commands and continue with explicit fallback (or stop if no safe fallback exists).

## Rules Section

Every skill MUST have a `## Rules` section before `## References`.

### Universal rules (include in every skill)

These rules apply to all CWF skills. Include them verbatim:

1. **All code fences must have language specifier**: Never use bare fences.
2. **cwf-state.yaml is SSOT**: Read before modifying. Edit, do not overwrite.
   (Only for skills that read/write cwf-state.yaml.)
3. **cwf-state.yaml auto-init**: If cwf-state.yaml does not exist in the project root,
   create it with the minimum schema before proceeding. See [cwf-state-init](#cwf-stateyaml-auto-init) below.
4. **Context-deficit resilience**: Skills must execute using persisted state/artifacts/handoff files when prior conversation context is unavailable.
5. **Missing dependency interaction**: When prerequisites are missing, ask to install/configure now; do not only report unavailability.

## cwf-state.yaml Auto-Init

When a CWF skill needs cwf-state.yaml and it does not exist, create it with:

```yaml
# cwf-state.yaml — Corca Workflow Framework project state
# Git-tracked, per-project. Read/written by cwf skills.

workflow:
  current_stage: clarify
  started_at: "{today YYYY-MM-DD}"

sessions: []

tools:
  codex: unknown
  gemini: unknown

hooks:
  attention: true
  log: true
  read: true
  lint_markdown: true
  lint_shell: true
  websearch_redirect: true
  compact_recovery: true

live: {}

expert_roster: []
```

Skills that update `live` (clarify, plan, impl, retro, handoff) should populate it on first use. The `sessions` list grows as sessions complete.

compact-context.sh already handles missing cwf-state.yaml gracefully (exits 0).

### Skill-specific rules

Add rules specific to the skill's domain (e.g., "Research first, ask later" for clarify, "Plan is the contract" for impl).

## References Section

Every skill MUST have a `## References` section as the final section.

### Shared references (relative path from `skills/{name}/SKILL.md`)

| Reference | Path | When to link |
|-----------|------|-------------|
| Agent patterns | [agent-patterns.md](agent-patterns.md) | Skills using Task tool or sub-agents |
| Plan protocol | [plan-protocol.md](plan-protocol.md) | Skills producing plan/lesson artifacts |
| Expert advisor | [expert-advisor-guide.md](expert-advisor-guide.md) | Skills using expert sub-agents |
| Skill conventions | [skill-conventions.md](skill-conventions.md) | (for refactor validation, not in individual skills) |

### Skill-specific references

Link to files in the skill's own `references/` directory using relative paths:

```text
- [file.md](references/file.md) — description
```

## Agent Pattern Declaration

If the skill uses sub-agents, declare the pattern in the References section:

```text
- [agent-patterns.md](agent-patterns.md) — {pattern name} pattern
```

Pattern names: Single, Adaptive, Agent team, 4 parallel. Must match the pattern declared in `agent-patterns.md`.

## Reporting Principle

When a skill produces quantitative output (counts, scores, coverage, violations), **provide enough context for the reader to assess significance without external knowledge.**

The reader should never need to look up a denominator, baseline, or total to understand whether a number is good or bad.

Examples:

```text
Bad:  "7 rules disabled"          → reader must know the total to judge
Good: "7/55 rules disabled (13%)" → reader can judge immediately

Bad:  "4 skills have broken refs" → is that a lot?
Good: "4/9 skills (44%) have broken refs" → clearly significant

Bad:  "3 errors found"            → compared to what?
Good: "3 errors found (down from 12 in last review)" → trend is clear
```

This applies to analysis reports, quick scans, review summaries, and any skill output that includes numbers.

## Checklist for New Skills

- [ ] Frontmatter: name, description (with Triggers), allowed-tools
- [ ] Language declaration after title (standard pattern)
- [ ] Quick Start section with usage examples
- [ ] Phase-based workflow (numbered phases)
- [ ] Rules section with universal + skill-specific rules
- [ ] References section with correct relative paths (`../../references/`)
- [ ] All code fences have language specifiers
- [ ] markdownlint passes (0 errors)

## Checklist for Holistic Review

- [ ] All skills follow section order (frontmatter → title → Language → Quick Start → Phases → Rules → References)
- [ ] Language declarations use standard pattern
- [ ] All skills have Rules section
- [ ] Shared reference paths use `../../references/` (avoid deeper parent traversal forms)
- [ ] Agent pattern matches declaration in agent-patterns.md
- [ ] No repeated patterns that should be extracted to shared references

## Future Consideration: Self-Healing Criteria

Reference guides and analysis criteria can become stale as the system grows. Proven case: `holistic-criteria.md` was written for 5 skills but missed analysis dimensions relevant to 9 skills (S13).

**Idea**: Each guide/criteria file carries provenance metadata (system state at creation time). Skills check provenance against current state before applying the criteria. If significantly different, flag to the user before proceeding.

This concept needs more failure cases before generalizing. Track occurrences and revisit post-v1.0 when usage data accumulates. See `holistic-criteria.md` for the first provenance implementation.
