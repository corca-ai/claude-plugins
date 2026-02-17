## UX/DX Review
### Concerns (blocking)
- **[C1] Stage provenance currently records the orchestrator instead of the stage skill, which breaks operator traceability and weakens deterministic audit value.**
  Evidence: `.cwf/projects/260217-05-full-skill-refactor-run/run-stage-provenance.md:4` logs `Stage=impl` with `Skill=cwf:run`, while the stage map and provenance contract define `impl -> cwf:impl` (`plugins/cwf/skills/run/SKILL.md:124`, `plugins/cwf/skills/run/SKILL.md:305`).
  Impact: Operators cannot reliably infer which skill produced stage outputs; downstream provenance consumers can misclassify execution history.
- **[C2] Human-readable provenance and machine-readable provenance metadata disagree on hook count, creating conflicting operator signals.**
  Evidence: `plugins/cwf/references/concept-map.md:3` states `15 hooks`, while `plugins/cwf/references/concept-map.provenance.yaml` records `hook_count: 18`.
  Impact: Determinism and maintenance confidence degrade when two official provenance surfaces disagree.

### Suggestions (non-blocking)
- **[S1]** Add a deterministic validator for `run-stage-provenance.md` that enforces `Stage -> Skill` mapping against `plugins/cwf/skills/run/SKILL.md` stage definitions.
- **[S2]** Normalize or downscope committed `*.stderr.log` artifacts (for example, summary + pointer instead of full raw logs) to reduce high-churn review noise and improve maintenance ergonomics.
- **[S3]** In `plugins/cwf/skills/update/SKILL.md`, capture an immutable pre-update snapshot path (or copy) before marketplace/install steps so Phase 3 diffing cannot collapse when cache paths are reused.

### Behavioral Criteria Assessment
- [ ] Operator clarity: stage provenance should unambiguously map each stage to its invoked skill.
- [ ] Determinism: provenance counters should be consistent across human-readable banners and sidecar metadata.
- [x] Maintenance ergonomics: cross-skill docs now centralize repeated policy into canonical references/checklists, reducing duplicated rule text.

### Provenance
source: REAL_EXECUTION
tool: claude-task
reviewer: UX/DX
duration_ms: —
command: —
<!-- AGENT_COMPLETE -->
