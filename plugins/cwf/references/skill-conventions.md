# CWF Skill Conventions

Shared structural conventions for all skills in the CWF plugin.
Use this as a template when creating new skills and as a checklist when reviewing existing ones.

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

## Rules Section

Every skill MUST have a `## Rules` section before `## References`.

### Universal rules (include in every skill)

These rules apply to all CWF skills. Include them verbatim:

1. **All code fences must have language specifier**: Never use bare fences.
2. **cwf-state.yaml is SSOT**: Read before modifying. Edit, do not overwrite.
   (Only for skills that read/write cwf-state.yaml.)

### Skill-specific rules

Add rules specific to the skill's domain (e.g., "Research first, ask later" for clarify, "Plan is the contract" for impl).

## References Section

Every skill MUST have a `## References` section as the final section.

### Shared references (relative path from `skills/{name}/SKILL.md`)

| Reference | Path | When to link |
|-----------|------|-------------|
| Agent patterns | `../../references/agent-patterns.md` | Skills using Task tool or sub-agents |
| Plan protocol | `../../references/plan-protocol.md` | Skills producing plan/lesson artifacts |
| Expert advisor | `../../references/expert-advisor-guide.md` | Skills using expert sub-agents |
| Skill conventions | `../../references/skill-conventions.md` | (for refactor validation, not in individual skills) |

### Skill-specific references

Link to files in the skill's own `references/` directory using relative paths:

```text
- [file.md](references/file.md) — description
```

## Agent Pattern Declaration

If the skill uses sub-agents, declare the pattern in the References section:

```text
- [agent-patterns.md](../../references/agent-patterns.md) — {pattern name} pattern
```

Pattern names: Single, Adaptive, Agent team, 4 parallel.
Must match the pattern declared in `agent-patterns.md`.

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
- [ ] Shared reference paths use `../../references/` (not `../references/` or `../../../references/`)
- [ ] Agent pattern matches declaration in agent-patterns.md
- [ ] No repeated patterns that should be extracted to shared references

## Future Consideration: Self-Healing Criteria

Reference guides and analysis criteria can become stale as the system grows. Proven case: `holistic-criteria.md` was written for 5 skills but missed analysis dimensions relevant to 9 skills (S13).

**Idea**: Each guide/criteria file carries provenance metadata (system state at creation time). Skills check provenance against current state before applying the criteria. If significantly different, flag to the user before proceeding.

This concept needs more failure cases before generalizing. Track occurrences and revisit post-v1.0 when usage data accumulates. See `holistic-criteria.md` for the first provenance implementation.
