## Refactor Review: handoff

### Summary
- Word count: 2,072 words (well below the 3,000-word warning and 5,000-word error thresholds).
- Line count: 415 lines (below the 500-line warning line count).
- Resources referenced: `plugins/cwf/references/plan-protocol.md`, `plugins/cwf/scripts/check-session.sh`, and the shared `cwf-state.yaml`; there are no unused `references/` or `scripts/` assets in this skill directory.
- Duplication warning: the SKILL repeats the full next-session template and execution contract that already exist in `plan-protocol`, which increases the risk of the two documents drifting apart.

### Findings
#### [medium] Repeating the canonical next-session template and execution contract
**What**: `Phase 3: Generate next-session` walks through nine required sections (Context Files, Task Scope, Don't Touch, Lessons, Success Criteria, Dependencies, Dogfooding, Execution Contract, Start Command) and gives the same detailed structure that is already spelled out in `plugins/cwf/references/plan-protocol.md` under “Handoff Document (milestone sessions)” and its Execution Contract subsection. Maintaining the same template/contract in two places makes the SKILL harder to keep consistent with the reference doc.
**Where**: `plugins/cwf/skills/handoff/SKILL.md`, Phase 3 (the bulk of the next-session template) and the Execution Contract paragraph vs. `plugins/cwf/references/plan-protocol.md`, section “Handoff Document (milestone sessions).”
**Suggestion**: Collapse the SKILL body to a behavior-centric workflow, and treat `plan-protocol` as the single source of truth for the template and contract text. Keep only a brief reminder (e.g., “Generate the nine `next-session.md` sections per `plan-protocol`”) and focus the SKILL on the decisions and orchestration steps unique to handoff.

#### [medium] No procedure when the current session is not registered in `cwf-state.yaml`
**What**: Phase 4.1 lists the update steps “If the current session entry exists in `cwf-state.yaml`…” but never says what to do when no entry exists. Phase 1.2 references matching against `sessions` or asking the user if ambiguous, yet there’s no follow-up when the session is brand-new (still missing from the list). An agent following the SKILL can end up unable to add `next-session.md` to `artifacts` because there is no entry to update.
**Where**: `plugins/cwf/skills/handoff/SKILL.md`, Phase 4.1 (Register in `cwf-state.yaml`) versus the earlier session-identification steps in Phase 1.2.
**Suggestion**: Add an explicit branch that handles the “no session entry” case—prompt the user to register the session in `cwf-state.yaml`, or create a minimal entry (with the current session directory and stage) before appending artifacts. This keeps `next-session.md` from being orphaned when the tracking record is missing.

### Suggested Actions
1. Replace the lengthy `next-session.md` template/execution-contract text in Phase 3 with a concise set of reminders that point to `plugins/cwf/references/plan-protocol.md` for the canonical structure, keeping the SKILL focused on orchestration.
2. Introduce an explicit fallback when a matching `cwf-state.yaml` session entry is absent (prompt the user, create a stub entry, or fail-fast with guidance) before touching `artifacts` or `completed_at`.

<!-- AGENT_COMPLETE -->
