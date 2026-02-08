# S3 Plan: Build `/ship` Skill

## Context

The cwf v3 migration (S3–S14) requires frequent GitHub operations: creating issues for each session, opening PRs from feature branches to `marketplace-v3`, and merging when approved. `/ship` automates this cycle as a repo-level skill, eliminating manual `gh` CLI invocations and ensuring consistent PR body formatting (lessons, CDM, review checklist).

This is the first session on `marketplace-v3` branch.

## Scope

- **Subcommands**: `issue`, `pr`, `merge`, `status` (no `full` — agent composes as needed)
- **Base branch**: configurable via `--base` (default: `marketplace-v3`)
- **Type**: Instruction-only SKILL.md with reference templates (no scripts)

## File Structure

```text
.claude/skills/ship/
├── SKILL.md                    # Core instructions (<500 lines)
└── references/
    ├── pr-template.md          # PR body template with {VARIABLES}
    └── issue-template.md       # Issue body template with {VARIABLES}
```

## Implementation Steps

- [x] 1. Create `marketplace-v3` branch from `main`
- [x] 2. Write `references/issue-template.md`
- [x] 3. Write `references/pr-template.md`
- [x] 4. Write `SKILL.md`
- [x] 5. Test: `/ship`, `/ship status`, `/ship issue`, `/ship pr`
- [ ] 6. Session wrap-up: lessons.md, next-session.md, `/retro`, commit & push

## Success Criteria

```gherkin
Given gh CLI is authenticated and marketplace-v3 branch exists
When user invokes `/ship issue`
Then a GitHub issue is created with session context and a feature branch is checked out

Given a feature branch with commits ahead of base
When user invokes `/ship pr`
Then a PR is created with lessons, CDM section, review checklist, linked to the issue

Given an approved PR with passing checks
When user invokes `/ship merge`
Then the PR is squash-merged and branch is deleted

Given any state
When user invokes `/ship status`
Then current issues, PRs, and session progress are displayed
```

## Deferred Actions

- (none)
