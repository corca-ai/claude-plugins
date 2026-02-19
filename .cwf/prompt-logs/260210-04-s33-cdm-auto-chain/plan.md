# S33 Plan: CDM Improvements + Auto-Chaining + Gate Extraction

## Context

S32-impl retro identified 4 CDMs: cross-cutting plan duplication (CDM 1),
commit strategy mismatch (CDM 2), compaction decision loss (CDM 3), and
Gemini CLI fail-fast gap (CDM 4). S13.6 auto-chaining was deferred. Ousterhout
recommended gate extraction to narrow impl/SKILL.md interface.

User decisions: full cwf:run implementation (not design-only), decision
journal mechanism (not simple plan.md auto-load).

## Goal

Implement all 4 CDM improvements, build cwf:run auto-chaining skill, and
extract impl gates to a shared reference.

## Steps

### Step 0: Extract impl gates to shared reference

Create `plugins/cwf/skills/impl/references/impl-gates.md` containing:
- Branch Gate (currently Phase 0.5)
- Clarify Completion Check (currently Phase 1.0)
- Commit Gate (currently Phase 3a.6, 3b.3.5)

Replace inline content in impl/SKILL.md with 1-2 line pointers to the
reference file. Preserve all functionality.

### Step 1: CDM 1 — Plan cross-cutting pattern gate

In `plugins/cwf/skills/plan/SKILL.md`:
- Add "Cross-Cutting Pattern Gate" section in Phase 3 before plan finalization
- Prohibit "동일 적용" / "apply the same pattern" as step instructions
- When 3+ targets share identical logic: mandate shared reference as Step 0
- Add Rule 7 codifying the gate

### Step 2: CDM 2 — Impl commit strategy branching

In `plugins/cwf/skills/impl/SKILL.md`:
- Add Phase 2.6 "Cross-Cutting Assessment" to Analyze & Decompose
- Detect whether changes are cross-cutting (one concept across 3+ files)
- Cross-cutting → commit by change pattern; modular → commit per work item
- Update Rule 12 to reflect the branching strategy

### Step 3: CDM 3 — Decision journal + phase-aware compact recovery

Two files:

**a) impl/SKILL.md**: Add decision journal instructions
- Phase 0: initialize `live.decision_journal` in cwf-state.yaml
- During Phases 2-4: append significant decisions to journal
- Format: YAML list of timestamped decision strings

**b) compact-context.sh**: Phase-aware recovery
- Parse `phase` field from live section
- When phase=impl: inject plan.md summary (first 80 lines from key_files
  plan path) + decision_journal entries into additionalContext
- When phase=clarify/plan: current behavior unchanged

### Step 4: CDM 4 — Review fail-fast for CAPACITY errors

In `plugins/cwf/skills/review/SKILL.md` Phase 3.2:
- Add error-type classification BEFORE exit code table
- CAPACITY (429, quota) → fail-fast, immediate fallback
- INTERNAL (500) → 1 retry then fallback
- AUTH (401) → abort with setup hint
- Reduce Gemini CLI timeout from 280s to 120s

### Step 5: Build cwf:run auto-chaining skill

Create `plugins/cwf/skills/run/SKILL.md`:
- Full pipeline: gather → clarify → plan → review(plan) → impl →
  review(code) → retro → ship
- Decision #19 gates: user gates pre-impl, auto gates post-impl
- `--from <stage>` flag to resume from a specific stage
- Review failure handling: auto-fix attempt → re-review → user escalation
- Uses Skill tool to invoke each stage skill sequentially

### Step 6: Update plugin.json and cwf-state.yaml

- Add `cwf:run` trigger to plugin.json
- Add `decision_journal` field to cwf-state.yaml live section schema

## Success Criteria

### Behavioral (BDD)

```gherkin
Given a plan with identical logic for 4+ targets
When cwf:plan drafts
Then a shared reference file is specified as Step 0

Given cross-cutting changes across 5 files
When impl determines commit strategy
Then commits are organized by change pattern (not work item)

Given phase=impl and auto-compaction occurs
When compact recovery fires
Then plan.md content and decision journal are included in recovery context

Given Gemini CLI returns MODEL_CAPACITY_EXHAUSTED
When review Phase 3.2 processes the error
Then fallback is triggered immediately (not after 3 retries)

Given a full task from scratch
When cwf:run is invoked
Then stages execute in order with user gates at clarify→plan and plan→impl
```

### Qualitative

- CDM improvements are minimal, surgical — not over-engineered
- Auto-chaining respects Decision #19 (autonomous post-impl, human-gated pre-impl)
- Gate extraction reduces impl/SKILL.md line count while preserving all functionality
- Decision journal adds minimal overhead to the impl workflow

## Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| plugins/cwf/skills/impl/references/impl-gates.md | Create | Extracted gates |
| plugins/cwf/skills/impl/SKILL.md | Edit | Gate pointers + CDM 2 + CDM 3 |
| plugins/cwf/skills/plan/SKILL.md | Edit | CDM 1 cross-cutting gate |
| plugins/cwf/skills/review/SKILL.md | Edit | CDM 4 fail-fast |
| plugins/cwf/hooks/scripts/compact-context.sh | Edit | CDM 3 phase-aware recovery |
| plugins/cwf/skills/run/SKILL.md | Create | Auto-chaining skill |
| plugins/cwf/.claude-plugin/plugin.json | Edit | Add cwf:run trigger |
| cwf-state.yaml | Edit | Decision journal schema |

## Don't Touch

- plugins/cwf/references/context-recovery-protocol.md
- plugins/cwf/skills/gather/
- README.md / README.ko.md
