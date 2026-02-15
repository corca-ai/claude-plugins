## Correctness Review

### Concerns (blocking)
- **[C1]** Missing required provenance fields are treated as **fresh** (false negative). In `scripts/provenance-check.sh:112` and `scripts/provenance-check.sh:119`, mismatch checks only run when `recorded_skills`/`recorded_hooks` are non-empty, so malformed sidecars bypass staleness detection. Real execution with an injected sidecar missing both fields returned `"status":"fresh"` and exit `0`.
  Severity: moderate
- **[C2]** Unresolved Retro items can be dropped due spec inconsistency. `plugins/cwf/skills/handoff/SKILL.md:228` lists Retro as a source, but the required output template at `plugins/cwf/skills/handoff/SKILL.md:234` and mandatory rule at `plugins/cwf/skills/handoff/SKILL.md:284` only require Deferred Actions + Lessons, not Retro output.
  Severity: moderate

### Suggestions (non-blocking)
- **[S1]** Add argument-arity validation for `--level` before reading `$2` at `scripts/provenance-check.sh:18`. `./scripts/provenance-check.sh --level` currently fails with `unbound variable` at `scripts/provenance-check.sh:19`.
- **[S2]** Escape JSON string fields before `printf` in `scripts/provenance-check.sh:136`; a `target` containing `"` produces invalid JSON.
- **[S3]** Delta formatting at `scripts/provenance-check.sh:116` and `scripts/provenance-check.sh:123` drops the positive sign (`(4)` vs `(+4)`), which weakens clarity.

### Behavioral Criteria Assessment
- [x] All 6 provenance sidecar files exist and report FRESH with exit code 0 — verified via `git ls-tree` (6 files) and `./scripts/provenance-check.sh` (`6/6 FRESH`, exit `0`).
- [ ] Artificially stale provenance (`skill_count: 5`) reports STALE with correct delta message — STALE + exit `1` verified, but delta text is `(4)` instead of expected signed form `(+4)` (`scripts/provenance-check.sh:116`).
- [x] Refactor holistic mode checks provenance before loading criteria, warns user if different — present at `plugins/cwf/skills/refactor/SKILL.md:201` through `plugins/cwf/skills/refactor/SKILL.md:214`.
- [x] `skill-conventions.md` has formal Provenance Rule (not "Future Consideration") — present at `plugins/cwf/references/skill-conventions.md:151`.

### Provenance
source: REAL_EXECUTION  
tool: codex  
reviewer: Correctness  
duration_ms: —  
command: `git show ...`; `./scripts/provenance-check.sh`; `./scripts/provenance-check.sh --json`; injected in-memory stale/malformed sidecar runs via `bash -c '... source ./scripts/provenance-check.sh ...'`
