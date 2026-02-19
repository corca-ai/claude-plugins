Executive Summary
- Gather, clarify, plan, handoff, and HITL rely on overlapping routing and persistence controls, but the current descriptions leave the handoff handshake and pre-impl gating fragile; without a tighter contract, unresolved scope or research artifacts can slip between these front-pipeline skills.
- The persistence/recovery protocols are enforced per-skill (context-recovery files, hitl queues, plan persistence gate), yet the references and keywords used to detect unresolved work are inconsistent, which increases the cognitive load on anyone trying to trace the end-to-end flow.
- The report therefore argues for a small set of cross-skill refactors: canonical unresolved-item metadata, a shared context-recovery registry, and a deterministic stage-transition handoff so downstream skills can rely on the artifacts they expect.

Findings (severity: high/medium/low)
1. Severity: high — `handoff` Phase 4b (Urgent Unresolved Item propagation) demands that unresolved work be pulled from `plan.md`’s Deferred Actions and `lessons.md` keywords such as "구현은 별도 세션", "future", "carry-forward". Neither `plan` nor `clarify` currently prescribe a canonical form for unresolved entries, and `lessons.md` only says to list general learnings. Without structured metadata, the handoff rule "Unresolved items MUST be propagated" is easily violated and downstream sessions may lose scope/context when key items are missing from `next-session.md`.
2. Severity: medium — The persistence/recovery gates are implemented ad hoc: `clarify` forces context-recovery checks for `clarify-codebase-research.md`/`clarify-web-research.md`, `plan` hard-fails unless `plan-prior-art-research.md`/`plan-codebase-analysis.md` exist, and `HITL` keeps pointer-only state in `.cwf/projects/.../hitl/`. These instructions reference the same `context-recovery-protocol.md`, but nobody owns a shared manifest, so it is easy to miss which files must be validated, how retries should behave, or how `session_dir` is resolved when contexts roll over or auto-compact occurs.
3. Severity: medium — The routing/hand-off choreography is loosely enforced: `plan` only "suggests" `cwf:handoff --phase` and leaves stage completion updates to downstream agents, while `handoff` relies on `next-session.md` to list deferred actions/goals. There is no deterministic bridge (e.g., updating `cwf-state.yaml` or generating `phase-handoff.md` automatically) that guarantees the same session ID and artifacts are used, making the pre-impl gate (from plan to handoff) brittle and dependent on manual follow-up.

Proposed Refactors (prioritized)
1. Canonicalize unresolved-item metadata (e.g., front matter or fenced `Unresolved` block) in the artifacts that feed `handoff`. Require `plan`, `lessons`, and `clarify` outputs to tag deferred work with predictable markers so `next-session.md` can extract them reliably without keyword heuristics.
2. Introduce a shared context-recovery registry (doc/table or helper script) that enumerates each skill’s critical files, sentinel text, and validation/retry policy, ensuring the same gating logic is reused when `session_dir` is resolved or when the context is recovered after auto-compact.
3. Tighten the stage-transition handshake between `plan` and `handoff` by having `plan` explicitly mark its `live` session as ready for handoff (update `cwf-state`, touch a `ready-for-handoff` flag, or even call `cwf:handoff --phase` automatically) so the next skill can trust the artifacts and session metadata it reads.
4. (Optional) Consolidate duplicated instructions about BDD/qualitative success criteria and cross-cutting pattern checks into shared references rather than copying nearly identical blocks into both `plan` and `handoff` SKILLs, reducing duplication while preserving enforcement.

Affected Files
- plugins/cwf/skills/gather/SKILL.md
- plugins/cwf/skills/clarify/SKILL.md
- plugins/cwf/skills/plan/SKILL.md
- plugins/cwf/skills/handoff/SKILL.md
- plugins/cwf/skills/hitl/SKILL.md

Open Questions
1. Should we enforce structured annotations (e.g., YAML metadata or explicit `Unresolved` block) in `lessons.md`/`plan.md` so the handoff parsing no longer depends on fragile keyword spotting?
2. Would a centralized context-recovery manifest or helper script that each skill calls simplify the current ad hoc process of validating research artifacts and session dirs, especially when auto-compact restarts a session?
3. Do we want `plan` to update `cwf-state.yaml` or call `cwf:handoff --phase` automatically once its persistence gate passes, to guarantee the pre-impl handshake always happens before implementation work begins?
