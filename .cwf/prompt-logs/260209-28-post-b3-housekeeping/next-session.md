## Handoff: Next Session (S13.5-C)

### Context

- Read: `cwf-state.yaml`, `docs/project-context.md`, `prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md`
- cwf-state.yaml: harden stage, S13.5-B3 complete, post-B3 housekeeping done
- Master-plan S13.5 workstream: A ✅, B ✅, B2 ✅, B3 ✅, C pending, D pending

### Task

project-context.md slimming — audit, deduplicate, and graduate content that has
moved into dedicated reference files.

### Scope

1. Audit `docs/project-context.md` for content duplicated in:
   - `plugins/cwf/references/concept-map.md`
   - `plugins/cwf/references/skill-conventions.md`
   - `plugins/cwf/references/expert-advisor-guide.md`
   - `plugins/cwf/references/agent-patterns.md`
2. Replace duplicated sections with pointers to authoritative sources
3. Remove stale information that no longer reflects current architecture
4. Update `docs/project-context.provenance.yaml` with review metadata

### Don't Touch

- `plugins/cwf/` skill/hook code (will be modified in S13.5-D)
- `README.md` / `README.ko.md` (stable from B2)

### Success Criteria

- `project-context.md` reduced in size with no information loss (pointers replace duplication)
- `provenance-check.sh` passes
- No broken cross-references

### Dependencies

- Requires: post-B3 housekeeping completed
- Blocks: S13.5-D (hook module abstraction), S13.6 (CWF protocol)

### Deferred from This Session

- [ ] Check if CLAUDE.md, project-context.md need exit-plan-mode.sh documentation
- [ ] `/ship issue` for S13.5-C/D work if not already created

### Start Command

@prompt-logs/260209-28-post-b3-housekeeping/next-session.md 시작합니다
