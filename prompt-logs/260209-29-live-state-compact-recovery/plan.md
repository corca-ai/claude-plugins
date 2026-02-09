# Plan: Plan Mode Removal + Live State + Compact Recovery

## Goal

Replace plan mode with a lighter, more robust context preservation system:
`cwf-state.yaml` `live` section + `SessionStart(compact)` hook for automatic
context recovery after auto-compact.

## Files to Change

```text
New (1):
  plugins/cwf/hooks/scripts/compact-context.sh

Changed (16):
  cwf-state.yaml                              — live section, remove hooks.plan_protocol
  scripts/check-session.sh                    — --live validation flag
  plugins/cwf/hooks/hooks.json                — remove plan hooks, add SessionStart(compact)
  plugins/cwf/skills/plan/SKILL.md            — remove hook complement description (L212-214)
  plugins/cwf/skills/setup/SKILL.md           — remove plan_protocol rows (L57, L92)
  plugins/cwf/skills/clarify/SKILL.md         — change plan mode mention (L314)
  plugins/cwf/references/plan-protocol.md     — remove plan mode timing references
  plugins/plan-and-lessons/.claude-plugin/plugin.json — deprecated: true
  .claude-plugin/marketplace.json             — remove plan-and-lessons entry
  CLAUDE.md                                   — Plan Mode → Session State section
  docs/project-context.md                     — hook config section update
  docs/plugin-dev-cheatsheet.md               — update plan-and-lessons example
  docs/skills-guide.md                        — update plan-and-lessons category
  README.md                                   — plan_protocol row + plan-and-lessons section
  README.ko.md                                — same in Korean

Deleted (2):
  plugins/cwf/hooks/scripts/enter-plan-mode.sh
  plugins/cwf/hooks/scripts/exit-plan-mode.sh

Skill live-update steps added (5):
  plugins/cwf/skills/clarify/SKILL.md
  plugins/cwf/skills/plan/SKILL.md
  plugins/cwf/skills/impl/SKILL.md
  plugins/cwf/skills/retro/SKILL.md
  plugins/cwf/skills/handoff/SKILL.md

Master plan (1):
  prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md

No-touch (prompt-logs/sessions/*, historical):
  191 files — past session logs, no modification needed
```

## Phase 1: cwf-state.yaml `live` Section + Validation Gate

### 1a. cwf-state.yaml

Add `live:` section after `hooks:` block:

```yaml
live:
  session_id: ""
  dir: ""
  branch: ""
  phase: ""        # clarify | plan | impl | review | retro | freeform
  task: ""
  key_files: []
  dont_touch: []
```

Remove `hooks.plan_protocol` key.

### 1b. check-session.sh

Add `--live` flag: FAIL if any of `session_id`, `dir`, `phase`, `task` in the
`live` section is empty. Existing `--impl` behavior unchanged.

## Phase 2: SessionStart(compact) Hook

### 2a. compact-context.sh (new)

```text
Input: stdin JSON (common fields + source: "compact")
Logic:
  1. Parse live section from cwf-state.yaml
  2. If live is empty → exit 0 (silent, pre-live session)
  3. If live populated → assemble additionalContext JSON
Output example:
  [Compact Recovery] Session: S13.5-C | Phase: impl
  Task: project-context.md slimming
  Branch: marketplace-v3
  Key files: cwf-state.yaml, docs/project-context.md
  Don't touch: plugins/cwf/ skill code, README.md
```

### 2b. hooks.json

Add `SessionStart` event with `compact` matcher.

## Phase 3: Plan Mode Removal

### 3a. hooks.json — remove 4 matcher groups

- PreToolUse > EnterPlanMode (enter-plan-mode.sh + start-timer.sh)
- PreToolUse > ExitPlanMode (exit-plan-mode.sh + start-timer.sh)
- PostToolUse > EnterPlanMode (cancel-timer.sh)
- PostToolUse > ExitPlanMode (cancel-timer.sh)

### 3b. Delete scripts

- `plugins/cwf/hooks/scripts/enter-plan-mode.sh`
- `plugins/cwf/hooks/scripts/exit-plan-mode.sh`

### 3c. attention.sh — remove plan mode detection (L122-124)

### 3d. plan-and-lessons plugin deprecate

- `plugin.json`: `"deprecated": true`
- `marketplace.json`: remove plan-and-lessons entry

## Phase 4: Documentation Updates

### 4a. CLAUDE.md

Replace Plan Mode section with:

```markdown
## Session State

When starting a new task or switching context, update the `live` section
in `cwf-state.yaml` (session_id, dir, branch, phase, task, key_files).

After implementation, write `next-session.md`, register the session in
`cwf-state.yaml`, and run `scripts/check-session.sh --impl`.
Fix all FAIL items before finishing.
```

### 4b. master-plan.md

- Infrastructure table: remove `plan-protocol` row (L70)
- Directory structure: remove `enter-plan-mode.sh`, add `compact-context.sh`
- Persistent Workflow State schema: add `live:` section, remove `plan_protocol`
- S13.5 workstream: add this session record

### 4c. plan-protocol.md

- L59 "when entering plan mode" → "at session start"
- L92 remove plan mode mention, change to session-start timing

### 4d. project-context.md

- Remove "EnterPlanMode hook is now provided by the plan-and-lessons plugin"
- Add compact-recovery pattern (SessionStart(compact) → live section injection)

### 4e. README.md / README.ko.md

- CWF hook table: remove `plan_protocol` row, add `compact_recovery` row
- plan-and-lessons section: deprecated notice or remove

### 4f. docs/plugin-dev-cheatsheet.md

- Update "Hook-only (e.g., smart-read, plan-and-lessons)" example

### 4g. docs/skills-guide.md

- Update "Instruction-only (plan-and-lessons, retro)" category

### 4h. AI_NATIVE_PRODUCT_TEAM.md / .ko.md

- plan-and-lessons plugin reference → CWF plan-protocol.md reference

### 4i. .claude/skills/review/SKILL.md

- "No plan.md found (plan mode)" wording change (L408)

### 4j. CHANGELOG.md — record changes at commit time

## Phase 5: CWF Skill `live` Update Steps

Add 1 step to each skill: "Edit `cwf-state.yaml` `live` section":

| Skill | Insert point | Update content |
|-------|-------------|----------------|
| clarify | Phase 1 start | `phase: clarify`, `task`, `key_files` |
| plan | Phase 1 start | `phase: plan`, `task` |
| impl | Phase 1 (Load Plan) | `phase: impl`, `key_files` from plan |
| retro | Phase 1 start | `phase: retro` |
| handoff | Phase 4.1 (session complete) | Clear `live` section (empty values) |

## Phase 6: Test + Verify

1. `check-session.sh --live` — FAIL (live empty)
2. Fill live section → `check-session.sh --live` — PASS
3. `compact-context.sh` standalone test: mock stdin → verify JSON output
4. `plugin update` + new session → hooks.json reflected
5. Manual `/compact` → post-compact context includes live info
6. `scripts/check-consistency.sh` — marketplace consistency
7. Cross-reference check across docs

## Dependencies

```text
Phase 1 (live schema + check gate)
  ├→ Phase 2 (compact hook) — needs live schema
  ├→ Phase 5 (skill updates) — needs live schema
  └→ Phase 3 (plan mode removal) — independent, parallel OK
       └→ Phase 4 (docs) — after Phase 1+3
            └→ Phase 6 (test) — after all
```

## Deferred Actions

- [x] None
