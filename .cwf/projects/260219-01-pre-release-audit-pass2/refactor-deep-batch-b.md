# Deep Review Batch B

Skills under review: `handoff` (session/phase handoff orchestration) and `hitl` (human-in-the-loop chunk review). All nine criteria from `plugins/cwf/skills/refactor/references/review-criteria.md` were applied to each skill as required for the planned deep skill audit.

## handoff

### Highlights
- Phase 3 instructs the agent to build each of the nine canonical sections from `plan-protocol.md` (context files, scope, don't touch, lessons, success criteria, dependencies, dogfooding, execution contract, and start command) and to defer implied `Execution Contract` clauses to the canonical reference, ensuring the session handoff remains lean yet complete (`plugins/cwf/skills/handoff/SKILL.md:87-131`).
- Phase 4 (registering the session) plus Phase 4b (propagating deferred actions, lesson proposals, and retro action items) cover the required `Handoff` state (session artifacts and unresolved items) and actions (scan artifacts, propagate context, generate doc, register in `cwf-state.yaml`) without duplication (`plugins/cwf/skills/handoff/SKILL.md:221-331`).

### Findings
- None. All nine review criteria are satisfied and the documented workflow cleanly implements the Handoff concept without redundant prose or missing references.

### Portability
- No portability risks were observed; the skill uses relative paths within the CWF workspace and provides fallbacks when master-plan artifacts are absent, so it degrades gracefully across repositories.

## hitl

### Highlights
- Decision points are surfaced by the agreement round (Phase 0.5) and the chunk-review loop (Phase 2) that force the reviewer to spell out the chunk, excerpt, intent, focused questions, and follow-up prompts before pausing; this satisfies Criterion 8 for both the Decision Point and the Handoff concepts (`plugins/cwf/skills/hitl/SKILL.md:51-123`).
- The State Model plus the Resume/Close steps persist the scratchpad, queue, rules, and events under `.cwf/projects/{session-dir}/hitl/` and keep only pointers in `cwf-state.yaml`, satisfying the Handoff requirements for resumable state and the ability to restart without losing intent (`plugins/cwf/skills/hitl/SKILL.md:8-49`, `137-158`).

### Findings
1. **[Criterion 3] Duplication risk in intent-resync instructions.** Phase 0.75 lays out the full intent-resync gate and the manual-edit guard, yet Rules 13-15 repeat the same gate semantics verbatim (set `intent_resync_required`, pause chunk review, log the change). Having the same operational contract in two places makes it easy to forget to update one copy, which undermines the deterministic-gate posture the skill depends on (`plugins/cwf/skills/hitl/SKILL.md:80-85` vs `plugins/cwf/skills/hitl/SKILL.md:175-177`).
2. **[Criterion 9] Portability assumption on cwf-state live pointer.** The first `--resume` step assumes `cwf-state.yaml` provides `live.hitl.state_file`; if that pointer is absent (e.g., running `cwf:hitl` before any session state exists), the skill has no bootstrap path for `state.yaml`/`rules.yaml` and fails to locate its working directory (`plugins/cwf/skills/hitl/SKILL.md:47-49`).

### Portability Risk Analysis
- **Assumption:** `live.hitl.state_file` is already set in `cwf-state.yaml` before `cwf:hitl` loads `state.yaml` (`plugins/cwf/skills/hitl/SKILL.md:47-49`).
- **Impact:** In a repo with no live state (fresh clone or the first HITL run) the skill cannot resolve the session directory, so it cannot persist state or resume; the user must manually create the `.cwf/projects/.../hitl` structure, defeating the expectation of automatic continuity.
- **Hardening:** Detect the missing pointer at Phase 0; when absent, prompt the user for the desired session directory (or auto-create one) and record the resolved path in `cwf-state.yaml` so future runs have a bootstrap reference. This keeps portability intact and avoids silent failures on first-run repositories.

<!-- AGENT_COMPLETE -->
