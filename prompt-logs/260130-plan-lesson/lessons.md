# Lessons: Plan & Lessons Protocol

## Ping-pong Learnings

### Claude should infer paths, not require explicit specification

- **Expected**: User specifies output paths; Claude documents "default" vs "exception" rules
- **Actual**: User expects Claude to determine paths from context. Separate "override" rules are redundant — if the user mentions a path, Claude naturally uses it
- **Takeaway**: Don't create branching rules for what a single principle covers

When stating a default behavior → check if the "exception" case is already handled by the default

### Progressive disclosure doesn't need to be documented as a rule

- **Expected**: Add a note about progressive disclosure in CLAUDE.md
- **Actual**: The existing CLAUDE.md already follows the pattern (lean top-level, details in docs/). New content naturally follows the same structure without being told
- **Takeaway**: If a codebase already embodies a principle structurally, documenting the principle as a rule is unnecessary

### Lessons vs retrospective are different concerns

- **Expected**: User's retrospective prompt could be integrated into lessons.md
- **Actual**: Lessons are incremental (accumulated during session). Retrospectives are comprehensive (end-of-session reflection covering prompting habits, learning resources, skill discovery). Coupling them muddies both
- **Takeaway**: When two things share a theme but differ in timing and scope, keep them separate

### CLAUDE.md instructs Claude, not the user

- **Expected**: Add reminders for user to run `/retro` and `/export` at session end
- **Actual**: User felt this was "slightly awkward" — CLAUDE.md defines Claude's behavior, not user checklists. User habits don't belong there
- **Takeaway**: Keep CLAUDE.md's audience clear: it's for Claude, not for the user
