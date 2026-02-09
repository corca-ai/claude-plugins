# Next Session: S13.5 C2/D/E + S13.6

## Context Files to Read

1. `CLAUDE.md` — project rules and protocols
2. `docs/plugin-dev-cheatsheet.md` — plugin development patterns
3. `cwf-state.yaml` — session history and project state (SSOT)
4. `prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md` — S13.5 workstream table for C2/D/E scope
5. `docs/project-context.md` — audit target for C2
6. `plugins/prompt-logger/hooks/scripts/log-turn.sh` — auto-commit logic (lines 463-483) for E
7. `plugins/cwf/hooks/scripts/compact-context.sh` — compact recovery hook (reference for E integration)

## Task Scope

Complete the remaining S13.5 workstreams (C2, D, E) and S13.6 protocol design.
Four workstreams in one session:

### C2: project-context.md Slimming

- Audit every entry: is it still current? duplicated in CLAUDE.md? graduated to a skill/doc?
- Remove stale entries, deduplicate, graduate mature patterns to their canonical locations
- Goal: project-context.md should contain only patterns that don't have a better home

### D: Hook Infrastructure

- Slack threading: attention notifications should thread replies (not flat messages)
- Shared module extraction: common patterns across hook scripts (env loading, state file management) into a shared utility

### E: prompt-logger Orphaned Session Log Recovery

- Problem: if SessionEnd auto-commit fails (staged changes exist, abnormal exit), session logs are left uncommitted
- Solution: Add `SessionStart(startup)` hook to prompt-logger that checks for uncommitted `.md` files in `prompt-logs/sessions/` and auto-commits them
- Implementation: new script (e.g., `commit-orphans.sh`) + add `SessionStart` entry to prompt-logger's `hooks.json`
- Must not interfere with existing staged changes (same `git diff --cached --quiet` guard)
- Context: this session discovered the gap when auto-compact fired mid-session and the session log was not committed

### S13.6: CWF Full Protocol Auto-Chaining

- Design the `cwf` single invocation that chains: gather → clarify → plan → review → impl → retro → ship
- Auto-transition rules from cwf-state.yaml `stages` (auto: true/false)
- Human checkpoints at gather→clarify and plan→impl boundaries
- Skill orchestration mechanism (skill calling skill, or SKILL.md as orchestrator)

## Don't Touch

- `plugins/cwf/skills/gather/` — scripts and references stable since S7
- `plugins/cwf/skills/review/references/` — review criteria stable since S13.5-B3
- `prompt-logs/sessions/` — read-only historical logs
- Existing compact-context.sh session log injection — just shipped, don't modify

## Lessons from Prior Sessions

1. **Plan document ≠ current state** (S29): Always check cwf-state.yaml for completion status, not master-plan roadmap
2. **Compact does NOT change session ID** (S29): SessionStart(compact) fires with the same session_id. Verify system internals against official docs before assuming
3. **Hook output schemas are asymmetric** (S29): PreCompact has no hookSpecificOutput; SessionStart can inject additionalContext. Always verify capabilities per event
4. **Deterministic validation > behavioral instruction** (S13): check-session.sh catches what CLAUDE.md rules miss
5. **Bootstrapping order matters** (S29): When implementing a safety mechanism, activate it before the work it protects

## Success Criteria

```gherkin
Given project-context.md has been audited
When comparing before/after line counts
Then at least 20% reduction with no information loss (graduated or deduplicated)

Given prompt-logger SessionStart(startup) hook is installed
When a new session starts with uncommitted .md files in prompt-logs/sessions/
Then orphaned files are auto-committed before the session proceeds

Given cwf protocol design is complete
When reading the S13.6 output document
Then auto-chaining rules, human checkpoints, and skill orchestration are specified
```

## Dependencies

- Requires: S29 (C1) completed — live state and compact recovery in place
- Blocks: S14 (integration test + main merge)

## Dogfooding

Discover available CWF skills via the plugin's `skills/` directory or
the trigger list in skill descriptions. Use CWF skills for workflow stages
instead of manual execution.

## Start Command

```text
@prompt-logs/260209-29-live-state-compact-recovery/next-session.md S13.5 C2/D/E + S13.6 시작합니다. cwf-state.yaml 읽고 현재 상태 파악 후 cwf:clarify 로 스코프 확정하세요.
```
