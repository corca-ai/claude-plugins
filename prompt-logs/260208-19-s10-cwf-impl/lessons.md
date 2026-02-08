# Lessons — S10: cwf:impl Skill

### Phase structure should reflect purpose, not precedent

- **Expected**: Might need 5 phases like clarify, or 4 phases plus sub-phases
- **Actual**: 4 phases with 3a/3b split naturally fits impl's dual execution path
- **Takeaway**: The 3a/3b split (direct vs agent team) is unique to impl — it's not a pattern from other skills. This confirms the S9 lesson: tailor phases to the skill's core value

### Reference file count matches complexity

- **Expected**: Might need 2+ reference files (like clarify's 4)
- **Actual**: One reference file (agent-prompts.md) covers all externalized content at 153 lines
- **Takeaway**: impl's reference needs are moderate — the prompt template, domain table, and dependency heuristics are closely related and belong together. Splitting them would add navigation cost without clarity benefit

### Nested code fences need careful handling

- **Expected**: Standard markdown code fences throughout
- **Actual**: The agent prompt template contains markdown with code fences inside it, requiring 4-backtick nesting
- **Takeaway**: Any skill that includes templates (prompts, output formats) with their own code fences needs the 4-backtick pattern. This is a recurring pattern for orchestration skills

### bypassPermissions mode for implementation agents

- **Expected**: Default mode for Task tool agents
- **Actual**: Implementation agents need `mode: bypassPermissions` to create/edit files autonomously without user confirmation per-file
- **Takeaway**: Orchestration skills that spawn file-writing agents should explicitly specify bypassPermissions to avoid agents stalling on permission prompts

### lessons.md is write-only without consumption mechanism (recurring: S8 → S10)

- **Expected**: S8 lesson ("next-session.md를 빠뜨림") would prevent the same mistake in S10
- **Actual**: S10 repeated the exact same omission. The lesson existed but was never read.
- **Takeaway**: lessons.md was a write-only artifact — no step in the workflow consumed prior sessions' lessons. Root cause was not "CLAUDE.md checklist incomplete" but "recorded lessons not applied."

### check-session.sh didn't use session_defaults (structural gap)

- **Expected**: `session_defaults.milestone: [next-session.md]` in cwf-state.yaml would catch missing next-session.md via check-session.sh
- **Actual**: check-session.sh only checked explicit `artifacts` field per session. session_defaults was defined but never parsed by the script. Additionally, session registration happened AFTER check-session.sh ran, so the script checked S9 instead of S10.
- **Takeaway**: Two fixes applied: (1) check-session.sh now falls back to session_defaults when no explicit artifacts, (2) CLAUDE.md workflow reordered — cwf-state.yaml registration before check-session.sh

### Deterministic validation over behavioral instruction

- **Expected**: Adding "remember to create next-session.md" to CLAUDE.md would prevent future omissions
- **Actual**: S8 already recorded this lesson, but it was not read in S10 — behavioral instructions failed across sessions. The fix that works: check-session.sh + session_defaults produces a deterministic FAIL when next-session.md is missing.
- **Takeaway**: For recurring mistakes, prefer deterministic checks (scripts that always run, pass/fail output) over behavioral instructions (rules in docs that may not be read). Instructions degrade as they accumulate; scripts scale. Persisted to project-context.md Design Principles.

### CLAUDE.md Plan Mode slimmed from 8 lines to 2

- **Expected**: Post-impl workflow needs step-by-step instructions (steps 0-5)
- **Actual**: enter-plan-mode.sh hook auto-injects protocol, session_defaults defines required artifacts, check-session.sh validates. The only non-automatable parts: "use EnterPlanMode for non-trivial tasks" (judgment) + "register in cwf-state.yaml" (bootstrap for eval) + "run check-session.sh" (the eval itself).
- **Takeaway**: When hooks + eval already enforce behavior, CLAUDE.md instructions are redundant. Removing them reduces CLAUDE.md's overfitting to the current milestone and makes it project-agnostic.
