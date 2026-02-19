## Handoff: Next Session (S6b)

### Context

- Read: `prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md` (overall plan)
- Read: `plugins/cwf/hooks/scripts/cwf-hook-gate.sh` (gate mechanism)
- Read: `plugins/cwf/hooks/hooks.json` (hook wiring)
- S6a migrated 3 simple hooks (check-markdown, smart-read, log-turn) into cwf stubs

### Task

Migrate attention-hook (8 scripts, complex state) + add check-shell.sh into cwf plugin.

### Scope

1. Migrate attention hook scripts: `attention.sh`, `start-timer.sh`, `cancel-timer.sh`, `heartbeat.sh`, `track-user-input.sh`
   - Source: `plugins/attention-hook/hooks/scripts/`
   - Target: `plugins/cwf/hooks/scripts/`
2. Build `check-shell.sh` — ShellCheck integration for PostToolUse:Write|Edit (new, not migration)
   - Source: Design from master-plan Decision #14
3. Migrate `enter-plan-mode.sh` from plan-and-lessons plugin
   - Source: `plugins/plan-and-lessons/hooks/scripts/enter-plan-mode.sh`
   - Target: `plugins/cwf/hooks/scripts/enter-plan-mode.sh`

### Don't Touch

- Skills (`plugins/cwf/skills/`) — these are S7+ work
- `redirect-websearch.sh` — deferred to S7 with gather migration
- `cwf-hook-gate.sh` — already working, no changes needed

### Success Criteria

- All attention-hook event paths work (idle notification, timer start/cancel, heartbeat)
- check-shell.sh blocks writes of .sh files with ShellCheck violations
- enter-plan-mode.sh injects protocol on EnterPlanMode
- Gate disable/enable works for all new hooks

### Dependencies

- Requires: S6a completed (done)
- Blocks: S7 (gather migration)

### After Completion

1. Create next session dir: `prompt-logs/{YYMMDD}-{NN}-{title}/`
2. Write plan.md, lessons.md in that dir
3. Write next-session.md (S7 handoff) in that dir

### Start Command

@prompt-logs/260208-11-cwf-infra-hooks/next-session.md 시작합니다
