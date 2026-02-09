# Next Session: S13.5-B2 — Concept Distillation + README v3

## Context Files to Read

1. `CLAUDE.md` — project rules and protocols
2. `docs/plugin-dev-cheatsheet.md` — plugin development patterns
3. `cwf-state.yaml` — session history and project state
4. `references/essence-of-software/distillation.md` — Daniel Jackson's concept distillation, the conceptual foundation for this session
5. `plugins/cwf/references/skill-conventions.md` — shared structural template for CWF skills
6. `plugins/cwf/skills/*/SKILL.md` — all 9 CWF skills (scan frontmatter + phases)
7. `README.md` — current README to overhaul
8. `prompt-logs/260209-25-s13.5-b-expert-loop/lessons.md` — lessons from S13.5-B

## Task Scope

Distill the conceptual model of CWF skills using the Essence of Software framework, then use that distillation to write the README v3 philosophy section.

### What to Build

1. **Concept distillation document**: Analyze all 9 CWF skills through the concept lens (what are the core concepts? what purposes do they serve? how do they compose?). Output as a reference doc in `docs/` or `references/`.
2. **README v3 philosophy overhaul**: Rewrite the README to articulate CWF's design philosophy grounded in the concept distillation. This was originally assigned to S14 but moved here because the philosophy should emerge from concept analysis, not be retrofitted after integration.

### Key Design Points

- The distillation should identify the essential concepts across skills (e.g., "plan", "handoff", "expert", "phase", "provenance") and how they relate
- README philosophy should be accessible to newcomers, not just v3 migration veterans
- Consider the audience: AI-native product teams who want to adopt CWF

## Don't Touch

- Individual SKILL.md files (read-only for concept analysis)
- `plugins/cwf/references/expert-advisor-guide.md` and `expert-lens-guide.md` (completed in S13.5-B)
- `scripts/` directory
- Hook configurations

## Lessons from Prior Sessions

1. **Canonical template over recent example** (S12): Always read the canonical template, not recent instances
2. **Agent results require spot-checks** (S13.5-B): Verify factual claims from agents against source files before presenting to user
3. **Separation of concerns: WHAT vs HOW** (S13.5-B): plan carries WHAT, phase handoff carries HOW
4. **Reference guide separation by consumer count** (S13.5-B): 1 consumer = specialized, N consumers = shared guide
5. **Count-agnostic logic design** (S13.5-B): Use any/all/none conditions for extensibility

## Unresolved Items from S13.5-B

### From S13.5-A (carry-forward)

- [ ] [carry-forward] Review skill Rule 5: save review results as files in session directory
- [ ] [carry-forward] Review skill `--base <branch>` flag for umbrella branch pattern
- [ ] [carry-forward] Review skill individual reviewer files as default behavior
- [ ] [carry-forward] Plan mode → session plan.md deadlock: ExitPlanMode hook to copy plan (cwf:plan 스킬 소관 — PostToolUse:ExitPlanMode hook으로 ~/.claude/plans/ 최신 파일을 prompt-logs/{session}/plan.md로 자동 복사)
- [ ] [carry-forward] Retro session symlink: team run support
- [ ] [carry-forward] EnterPlanMode lessons.md enforcement hook

## Success Criteria

```gherkin
Given the 9 CWF skills and the Essence of Software framework
When concept distillation is performed
Then a document identifies core concepts, their purposes, and composition patterns

Given the concept distillation document
When the README v3 philosophy section is written
Then it articulates CWF's design philosophy in terms accessible to newcomers

Given the updated README
When a new user reads the philosophy section
Then they understand what CWF does, why it exists, and how its concepts compose
```

## Dependencies

- Requires: S13.5-B (expert-in-the-loop, phase handoff — complete)
- Blocks: S13.5-C (project-context slimming), S13.6 (full protocol)

## Dogfooding

Discover available CWF skills via the plugin's `skills/` directory or
the trigger list in skill descriptions. Use CWF skills for workflow stages
instead of manual execution.

## Start Command

```text
Read the context files above, then use cwf:clarify to decompose the concept distillation task into decision points. Use references/essence-of-software/distillation.md as the conceptual lens for analyzing all 9 CWF skills.
```
