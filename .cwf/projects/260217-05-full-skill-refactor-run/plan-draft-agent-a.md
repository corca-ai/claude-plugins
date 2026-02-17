Goal

Deliver a cwf:run-driven, gate-safe refactor run that covers the full `review-code -> refactor -> retro -> ship` progression, executes holistic and per-skill refactor reviews for all 13 skills, avoids Gemini-powered external reviews, and persists every intermediate artifact plus commit checkpoints in the current session directory.

Steps

1. Pre-run verification and artifact scaffolding (Plan stage).
   - Confirm gather/clarify findings (D1–D5) are recorded in `plan.md`/`lessons.md` and add a structured `Unresolved Items` section with canonical markers so downstream skills can parse deterministic metadata.
   - Register the session’s persistence gate: ensure `.cwf/projects/260217-05-full-skill-refactor-run/` already contains the required `review-code`, `refactor`, `retro`, and `ship` artifact placeholders and that `session-state.yaml` points to this directory.
   - Record the planned external-review provider choice (anything but Gemini, e.g., Codex or built-in `cwf:review` default) and log the expected artifact name `review-code-artifact.md` so the run stage can consume it.

2. `review-code` stage via `cwf:run --stage review-code`.
   - Execute the gate check (per D1) by running the current `review` workflow, collect the verdict/confidence, and persist results to `.cwf/projects/260217-05-full-skill-refactor-run/review-code-artifact.md` plus a structured summary for `run` to re-read.
   - Trigger an external provider that is not Gemini (configuring `cwf:review` flags or using another approved reviewer), and confirm the review output is committed as an artifact before continuing.
   - Capture any `Unresolved Items` raised by the reviewer in the session `lessons.md` entry.

3. `refactor` stage via `cwf:run --stage refactor`.
   - Start with `cwf:refactor --skill --holistic` to cover cross-cutting gate language, artifact expectations, and shared deterministic contracts referenced in gather summaries.
   - Follow with consecutive `cwf:refactor --skill <skill>` runs for each skill: `clarify`, `gather`, `handoff`, `hitl`, `impl`, `plan`, `refactor`, `retro`, `review`, `run`, `setup`, `ship`, `update`. Persist each skill’s artifact to `.cwf/projects/260217-05-full-skill-refactor-run/refactor-<skill>.md` (create placeholder names if skill reports no changes) and record any unresolved items in structured assisted sections.
   - Ensure each per-skill output includes deterministic gate checks (duplicate/clarify gating instructions) and document next steps or blocked areas in `.cwf/projects/260217-05-full-skill-refactor-run/refactor-issues.md` if needed.

4. `retro` stage via `cwf:run --stage retro`.
   - Run the retrospective workflow (`cwf:retro --mode full`) against the session, persist its summary to `.cwf/projects/260217-05-full-skill-refactor-run/retro-summary.md`, and capture lessons related to deterministic gate compliance for future sessions.
   - Confirm the retro artifacts satisfy the gate expectation by invoking `check-run-gate-artifacts --stage retro` (or equivalent script) and logging results.

5. `ship` stage via `cwf:run --stage ship`.
   - Launch `cwf:ship` (or the manual `/ship merge` path) but always precede it with `check-run-gate-artifacts --stage ship` to enforce the gate per Decision D2; persist the validation log to `.cwf/projects/260217-05-full-skill-refactor-run/ship-gate.md`.
   - Include any remaining unresolved scope items marked in structured metadata and note closure status in `lessons.md`.

Files to Create/Modify

| File | Action | Purpose |
| --- | --- | --- |
| `.cwf/projects/260217-05-full-skill-refactor-run/plan-draft-agent-a.md` | Create | Record this implementation plan draft for the cwf:run session contract. |
| `.cwf/projects/260217-05-full-skill-refactor-run/review-code-artifact.md` | Create/Edit | Persist `review-code` gate verdict, reviewer notes (non-Gemini), and unresolved items metadata for run consumption. |
| `.cwf/projects/260217-05-full-skill-refactor-run/refactor-<skill>.md` (13 files) | Create/Edit | Store per-skill refactor outputs, highlights, and unresolved-item markers for cross-skill gate tracking. |
| `.cwf/projects/260217-05-full-skill-refactor-run/refactor-issues.md` | Create | Aggregate blockers or shared decisions surfaced during the holistic/per-skill reviews. |
| `.cwf/projects/260217-05-full-skill-refactor-run/retro-summary.md` | Create | Capture retrospective findings tied to gate compliance and artifact persistence. |
| `.cwf/projects/260217-05-full-skill-refactor-run/ship-gate.md` | Create | Record the `check-run-gate-artifacts --stage ship` output and ship-stage readiness confirmation. |
| `lessons.md` | Edit | Document structured unresolved items, lessons learned this run, and references to non-blocking debt (D4/D5). |

Success Criteria (Behavioral + Qualitative)

### Behavioral (BDD)
- Given the session artifacts list and gate contracts, when `cwf:run --stage review-code` executes using a non-Gemini reviewer, then the `.cwf/projects/.../review-code-artifact.md` file exists with a verdict, reviewer identity, and structured `Unresolved Items` section.
- Given holistic and per-skill refactor runs, when each `cwf:refactor --skill <skill>` completes then its corresponding `.cwf/projects/.../refactor-<skill>.md` file contains actionable items, gate clarifications, and no missing persistence artifacts.
- Given the ship-stage enforcement requirement, when `check-run-gate-artifacts --stage ship` runs before `/ship merge`, then `ship-gate.md` reflects a PASS status and the resulting ship invocation succeeds without bypassing the gate.

### Qualitative
- The plan keeps artifact persistence explicit so any future agent can resume the session using the documented file names and structured metadata.
- Review/refactor outputs highlight deterministic gate language and resolve duplicate instructions identified in the gather results.
- Lessons summarize deferred decisions (D1, D4, D5) and specify which follow-up sessions should pick them up.

Commit Strategy

- Commit per stage checkpoint with descriptive messages (e.g., `stage: review-code gate ready`, `stage: refactor outputs`, `stage: retro summary`, `stage: ship gate`).
- Include a small, focused commit after generating per-skill refactor artifacts so that any rollback can target a single skill’s output without touching earlier stages.
- Tag the final commit with `cwf-run/260217-05` once `ship` stage passes to signal end-to-end completion.

Risks & Mitigations

1. Risk: Non-Gemini external reviewers might be unavailable or slower, delaying the `review-code` gate.
   - Mitigation: Pre-select fallback reviewers supported by `cwf:review` (Codex CLI or built-in) and schedule early in the run; log any delays as a risk entry in `retro-summary.md`.
2. Risk: Running 13 per-skill refactors may expose conflicting instructions or require more time than expected.
   - Mitigation: Start with the holistic refactor to surface cross-skill patterns, then run per-skill commands sequentially while tracking blockers in `refactor-issues.md`; pause the run and resolve blockers before proceeding to the next skill if gate-critical.
3. Risk: Artifact persistence gaps (missing refactor outputs, unresolved items) could fail downstream gates.
   - Mitigation: After each stage run, immediately verify that the expected artifact file exists and include a `PERSISTENCE_GATE` note in the relevant file header; reference this check when continuing to the next stage.
