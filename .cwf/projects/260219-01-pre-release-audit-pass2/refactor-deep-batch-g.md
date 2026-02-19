# Deep Review Batch G

Skills under review: `ship`. Criteria 1‑9 from `plugins/cwf/skills/refactor/references/review-criteria.md` were applied to each section below; every finding includes line-level evidence.

## ship

### Highlights
- The mandatory output persistence block (write `{session_dir}/ship.md`, sync ambiguity debt, and run the `check-run-gate-artifacts` stage gate) enforces the deterministic-run contract before any GitHub operation finishes, keeping the skill aligned with the run/ship pipeline’s pass/fail authority (`plugins/cwf/skills/ship/SKILL.md:48-78`).
- `/ship issue`, `/ship pr`, `/ship merge`, and `/ship status` all list the exact `gh`/`git` commands, guards, and user prompts needed to keep the DMZ between autonomous agents and GitHub state clear, which matches the recorded error-handling checklist (`plugins/cwf/skills/ship/SKILL.md:82-314`).
- The narrative templates live entirely under `references/issue-template.md` and `references/pr-template.md`, and the SKILL simply tells the agent to load those files and substitute the required variables, preventing duplication while keeping the workflow description compact (`plugins/cwf/skills/ship/SKILL.md:98-187`; `plugins/cwf/skills/ship/references/issue-template.md:1-31`; `plugins/cwf/skills/ship/references/pr-template.md:1-64`).

### Findings
| Severity | Criterion | Finding | Evidence | Suggestion |
|---|---|---|---|---|
| info | 1 | no material finding (349 lines / ~1,800 words, well below the warning thresholds) | `plugins/cwf/skills/ship/SKILL.md:1-349` | n/a |
| info | 2 | no material finding (front matter contains only `name`/`description` with the `/ship` trigger, and the body focuses on actionable workflows instead of “when to use” prose) | `plugins/cwf/skills/ship/SKILL.md:1-35` | n/a |
| info | 3 | no material finding (issue/pr workflows refer to templates in `references/` rather than copying their content, so there is only one source for each narrative) | `plugins/cwf/skills/ship/SKILL.md:98-187` + `plugins/cwf/skills/ship/references/issue-template.md:1-31` + `plugins/cwf/skills/ship/references/pr-template.md:1-64` | n/a |
| info | 4 | no material finding (only the two reference templates exist, both under 100 lines and both referenced; there are no unused scripts or assets) | `plugins/cwf/skills/ship/references/issue-template.md:1-31` + `plugins/cwf/skills/ship/references/pr-template.md:1-64` + `plugins/cwf/skills/ship/SKILL.md:98-187` | n/a |
| info | 5 | no material finding (imperative instructions dominate every section: “Before any subcommand, verify…,” “Create a GitHub issue…,” “Check PR status…,” etc.) | `plugins/cwf/skills/ship/SKILL.md:27-299` | n/a |
| info | 6 | no material finding (low-freedom operations: concrete `gh`, `git`, and gate commands plus the decision matrix for merging keep fragile GitHub state transitions explicit) | `plugins/cwf/skills/ship/SKILL.md:32-263` | n/a |
| info | 7 | no material finding (front matter obeys the metadata-only rule, the description includes the trigger, and the rules section enforces the user-language override) | `plugins/cwf/skills/ship/SKILL.md:1-4` + `plugins/cwf/skills/ship/SKILL.md:333-344` | n/a |
| info | 8 | no material finding (`ship` is a sparse/concept-free skill in the synchronization map, so there are no missing generic concept obligations to check) | `plugins/cwf/references/concept-map.md:158-178` + `plugins/cwf/skills/ship/SKILL.md:82-299` | n/a |
| info | 9 | no material finding (`ship` relies on `live.dir`, `CWF_PLUGIN_DIR`, remote-base detection, and session-path indirection instead of hard-coded repo names, keeping the workflow portable) | `plugins/cwf/skills/ship/SKILL.md:48-131` | n/a |

### Prioritized actions
1. None — all nine criteria are satisfied for `ship`.

<!-- AGENT_COMPLETE -->
