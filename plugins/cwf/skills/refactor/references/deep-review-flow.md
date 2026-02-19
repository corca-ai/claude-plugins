# Deep Review Flow (`--skill <name>`)

## 1. Locate the skill

Search for the SKILL.md in this order:

1. `plugins/<name>/skills/<name>/SKILL.md` (marketplace plugin)
2. `plugins/<name>/skills/*/SKILL.md` (skill name differs from plugin name)
3. `.claude/skills/<name>/SKILL.md` (local skill)

If not found, report error and stop.

## 2. Read the skill

Read the SKILL.md and all files in `references/`, `scripts/`, and `assets/` directories.

## 3. Verify criteria provenance

Run provenance verification before loading deep-review criteria:

```bash
bash {CWF_PLUGIN_DIR}/scripts/provenance-check.sh --level inform --json
```

Confirm the output includes [review-criteria.provenance.yaml](review-criteria.provenance.yaml). If stale, continue but mark the final report with a provenance warning (include the skill/hook deltas).

## 4. Load review criteria

Read `{SKILL_DIR}/references/review-criteria.md` for the evaluation checklist.

## 5. Parallel Evaluation with Sub-agents

Resolve session directory using [session-bootstrap.md](session-bootstrap.md) with bootstrap key `refactor-skill`.

Derive a stable skill suffix from `--skill <name>`:

```bash
skill_suffix="$(printf '%s' "{skill name}" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
```

Apply the [context recovery protocol](../../../references/context-recovery-protocol.md) to these files:

| Agent | Output file |
|-------|-------------|
| Structural Review | `{session_dir}/refactor-deep-structural-{skill_suffix}.md` |
| Quality + Concept Review | `{session_dir}/refactor-deep-quality-{skill_suffix}.md` |

Launch **2 parallel sub-agents** in a single message using Task tool (`subagent_type: general-purpose`, `max_turns: 12`) — only for agents whose result files are missing or invalid.

Agent A — Structural Review (Criteria 1-4):

- Target skill name and SKILL.md content
- All reference file contents and resource file listing
- `{SKILL_DIR}/references/review-criteria.md` criteria sections 1-4
- Instructions: Evaluate Size, Progressive Disclosure, Duplication, Resource Health. Return structured findings per criterion.
- **Output Persistence**: write to `{session_dir}/refactor-deep-structural-{skill_suffix}.md` and append `<!-- AGENT_COMPLETE -->`

Agent B — Quality + Concept Review (Criteria 5-9):

- Target skill name and SKILL.md content
- All reference file contents and resource file listing
- `{SKILL_DIR}/references/review-criteria.md` criteria sections 5-9
- `{PLUGIN_ROOT}/references/concept-map.md` (Criterion 8)
- Instructions: Evaluate Writing Style, Degrees of Freedom, Anthropic Compliance, Concept Integrity, and Repository Independence/Portability.
- **Output Persistence**: write to `{session_dir}/refactor-deep-quality-{skill_suffix}.md` and append `<!-- AGENT_COMPLETE -->`

Both agents analyze and report; neither modifies files.

## 6. Produce report

Merge both agent outputs into a unified report:

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

## 7. Offer to apply

Ask the user whether to apply suggestions. If yes, implement the refactorings.
