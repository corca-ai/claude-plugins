Now I have a thorough understanding of the architecture. Let me produce the review.

## Architecture Review

### Concerns (blocking)

- **[C1]** The `review-plan` checkpoint matrix (lines 17–39) performs its own inline verification script rather than delegating to `check-run-gate-artifacts.sh --stage review-plan`. Every other stage (`review-code`, `refactor`, `retro`, `ship`, `final completion`) delegates to the gate script, but `review-plan` uses a bespoke inline bash block with ad-hoc `grep` patterns. This creates a **separation-of-concerns violation**: `review-plan` gate logic lives in the checkpoint matrix document rather than in the canonical gate script. If the gate script is later extended to cover `review-plan` (which is already a valid gate name in `remaining_gates`), the two sources will drift. The inline sentinel check (`grep -q '<!-- AGENT_COMPLETE -->'`) duplicates `require_agent_complete_sentinel` from the gate script, and the synthesis section checks duplicate the pattern-match logic the gate script already implements for `review-code`.
  **Severity: moderate**

- **[C2]** Plan Step 5 specifies per-skill snapshot files (`refactor-skill-<name>.md`), and the checkpoint matrix verification (lines 95–99) checks for their existence. However, `check-run-gate-artifacts.sh --stage refactor` does **not** check per-skill files — it uses a "has_any" presence gate looking for `refactor-summary.md`, `refactor-quick-scan.json`, `refactor-deep-*.md`, and `refactor-tidy-commit-*.md`. This means the plan introduces a **second, undeclared gate layer** (the per-skill file existence loop) that is enforced only in the checkpoint matrix, not in the canonical gate script. If the matrix is not executed, or if a future run uses only `check-run-gate-artifacts.sh`, the per-skill completeness invariant is silently unenforced.
  **Severity: moderate**

### Suggestions (non-blocking)

- **[S1]** Consider extracting the `review-plan` inline verification into `check-run-gate-artifacts.sh` as a new `review-plan` stage handler. The gate script already recognizes `review-plan` as a valid gate name in `remaining_gates`, so the infrastructure is ready — only the artifact-check function body is missing. This would eliminate the C1 policy drift risk and bring `review-plan` into the same enforcement loop as all other stages.

- **[S2]** The Gemini provider-exclusion policy (plan line 19, matrix line 38) is enforced by grepping for `^tool:[[:space:]]*gemini$` in exactly two files (`review-correctness-plan.md`, `review-architecture-plan.md`). This is an incomplete check — it does not inspect the other four reviewer files or the synthesis. If a reviewer slot is unexpectedly routed to Gemini (e.g., `review-expert-alpha-plan.md`), the current check would not catch it. Consider broadening the grep to cover all six reviewer artifacts plus synthesis.

- **[S3]** Plan Step 8 ("Run plugin lifecycle verification for CWF") is the only step without a corresponding section in the checkpoint matrix. Adding an explicit pass condition (even if it is just "plugin-deploy exits zero") would maintain the matrix's completeness invariant.

- **[S4]** The plan lists 13 skills for per-skill refactor (Step 5), but the checkpoint matrix verification loop also lists 13 names. There is no cross-reference to a canonical skill registry. If a skill is added or removed, both the plan and the matrix must be updated independently. Consider sourcing the skill list from a single canonical location (e.g., `ls plugins/cwf/skills/*/SKILL.md | xargs -I{} basename $(dirname {})`) to prevent count drift.

- **[S5]** Plan Step 3 specifies commit ordering (`tidy` first, then `behavior-policy`), but there is no checkpoint verification for this ordering. Since the ordering is a stated invariant ("tidy changes first"), the matrix could enforce it by checking git log subject prefixes or tag metadata within the session commit range.

### Behavioral Criteria Assessment

- [x] **Deterministic gate architecture consistency**: All post-impl stages (`review-code`, `refactor`, `retro`, `ship`) delegate to `check-run-gate-artifacts.sh`, and the `phase=done` transition re-validates all four. The fail-closed invariant is preserved end-to-end.
- [x] **Workflow coherence (run/review/refactor/retro/ship)**: The pipeline order is well-defined in both the plan and `cwf:run` SKILL.md. Each stage has a clear artifact contract, and the checkpoint matrix covers all five post-plan stages plus final completion.
- [x] **Context-deficit resilience**: The plan explicitly requires artifact persistence, progressive checkpoint commits, and resumability without conversational dependency (qualitative criteria line 61).
- [x] **Deferred debt isolation**: D1, D4, D5 are explicitly listed as deferred (plan lines 71–73) and the "Don't Touch" section (line 68) prohibits bypassing deterministic gates to force completion.
- [ ] **Uniform gate delegation**: `review-plan` uses an inline verification script in the checkpoint matrix rather than delegating to the canonical gate script (C1).
- [ ] **Per-skill completeness enforcement in canonical gate**: The per-skill snapshot check is matrix-only, not in `check-run-gate-artifacts.sh` (C2).
- [x] **Provider policy enforcement**: Gemini exclusion is codified in both plan and matrix, though scope could be broadened (S2).
- [x] **Separation of concerns between skill and orchestrator**: Each skill self-enforces its gate post-write; the orchestrator (`cwf:run`) independently re-enforces at stage transitions. Dual-enforcement is architecturally sound.
- [x] **Hook-level fail-closed enforcement**: `workflow-gate.sh` blocks ship/push/commit intents while `review-code` is in `remaining_gates`, with stale-session awareness.

### Provenance

```
source: REAL_EXECUTION
tool: claude-cli
reviewer: Architecture
duration_ms: —
command: claude -p
```

<!-- AGENT_COMPLETE -->
