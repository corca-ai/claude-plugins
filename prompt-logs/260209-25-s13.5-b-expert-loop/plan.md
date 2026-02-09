# Plan: Phase Handoff (`--phase` mode) for CWF Handoff Skill

## Context

After clarify+spec, clearing context loses HOW (protocols, rules, must-read references). `plan.md` carries WHAT but not HOW. This change adds `--phase` mode to the handoff skill to produce `phase-handoff.md` — a lightweight document focused on implementation context (HOW), consumed by `cwf:impl` alongside `plan.md`.

A manual prototype already exists at `prompt-logs/260209-25-s13.5-b-expert-loop/phase-handoff.md` validating the output format.

## Implementation Steps

### Step 1: Modify `plugins/cwf/skills/handoff/SKILL.md`

**1a. Frontmatter description** (line 3-6): Add `--phase` mode mention and trigger.

**1b. Opening paragraph** (line 19): Mention `phase-handoff.md` alongside `next-session.md`.

**1c. Quick Start** (lines 25-27): Add `cwf:handoff --phase` line.

**1d. Insert Phase 3b** (after line 201, before the `---` separator):

New section "Phase 3b: Generate phase-handoff.md (--phase mode)" with:

- **Prerequisite flow**: Phase 1.1 + 1.2 execute normally. Phase 1.3 reads only `lessons.md`. Phase 2 skipped entirely.
- **3b.1 Determine Phase Transition**: Identify source/target phases from context. AskUserQuestion if ambiguous.
- **3b.2 Gather HOW Context**: Extract from conversation history — Context Files, Design Decisions, Protocols, Prohibitions, Implementation Hints, Success Criteria.
- **3b.3 Generate phase-handoff.md**: Write to `prompt-logs/{session-dir}/phase-handoff.md` with 6 sections:
  1. Context Files to Read
  2. Design Decision Summary
  3. Protocols to Follow
  4. Do NOT
  5. Implementation Hints
  6. Success Criteria (BDD)
- **3b.4 User Review**: Draft-then-review via AskUserQuestion (Confirm / Edit / Cancel).

**1e. Update Phase 4** (after line 213): Add "4.1b Register Phase Handoff (--phase mode)" — adds `phase-handoff.md` to artifacts, does NOT set `completed_at` (session continues), skips Phase 4b and Phase 5.

**1f. Add rules** (after line 288): 4 new rules:
- Phase handoff captures HOW, not WHAT (no plan.md duplication)
- Written by the phase that has context
- Intra-session (no `completed_at`)
- Draft-then-review

### Step 2: Modify `plugins/cwf/skills/impl/SKILL.md`

**2a. Insert Phase 1.1b** (after line 50): "Phase Handoff Discovery" — check for `phase-handoff.md` in same directory as plan.md. If found, read all sections. If not found, proceed normally. Read Context Files listed in phase-handoff.md before Section Extraction.

**2b. Update Section Extraction table** (line 56-66): Add 3 rows for Phase Handoff Protocols, Do NOT, and Hints.

**2c. Update User Confirmation template** (lines 74-83): Add Phase Handoff status, protocol count, Do NOT count.

**2d. Update Phase 3 execution** (lines 161-169 and 179-185): Include phase handoff hints and Do NOT constraints in both direct execution and agent prompts.

**2e. Update Phase 4 verification** (line 235): Merge phase-handoff.md BDD criteria with plan criteria.

**2f. Add 2 rules** (after line 309):
- Phase handoff protocols are binding (same weight as plan constraints)
- Phase handoff is optional (impl works with plan.md alone)

### Step 3: Modify `plugins/cwf/skills/clarify/SKILL.md`

**3a. Update Phase 5 Follow-up** (line 309): Replace single review suggestion with two suggestions:
1. `cwf:review --mode clarify`
2. `cwf:handoff --phase` — recommended when context will be cleared before impl

**3b. Update --light mode output** (around line 357): Add phase handoff suggestion.

## Critical Files

| File | Action | Estimated change |
|------|--------|-----------------|
| `plugins/cwf/skills/handoff/SKILL.md` | Add Phase 3b + updates | ~75 lines added |
| `plugins/cwf/skills/impl/SKILL.md` | Add Phase 1.1b + updates | ~35 lines added |
| `plugins/cwf/skills/clarify/SKILL.md` | Update Phase 5 follow-up | ~10 lines changed |

## Verification

1. **Markdown lint**: `npx markdownlint-cli2 plugins/cwf/skills/handoff/SKILL.md plugins/cwf/skills/impl/SKILL.md plugins/cwf/skills/clarify/SKILL.md`
2. **Cross-reference check**: Verify all file references resolve (phase-handoff.md format, plan-protocol.md link)
3. **Prototype comparison**: Compare Phase 3b.3 output template against the existing prototype at `prompt-logs/260209-25-s13.5-b-expert-loop/phase-handoff.md` to ensure format consistency
4. **Line budget**: handoff ~370 lines, impl ~350 lines — both within 500-line convention
