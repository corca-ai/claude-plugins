# Review Synthesis — S13.5-A Self-Healing Provenance System

> Commit: `75ef807` on branch `s13.5-a-provenance`
> Date: 2026-02-09

## Verdict: Conditional Pass

Provenance system is functionally correct and all 4 behavioral criteria are met. Three moderate concerns require attention before merge: JSON injection risk in `--json` output, missing field handling in provenance check, and handoff retro item propagation spec gap.

## Behavioral Criteria Verification

- [x] All 6 provenance sidecar files exist and report FRESH with exit code 0 — All 4 reviewers verified
- [x] Artificially stale provenance (skill_count: 5) reports STALE with correct delta message — Verified by Security, UX/DX, Codex. Note: delta displays `(4)` not `(+4)` (see S3 below)
- [x] Refactor holistic mode checks provenance before loading criteria, warns user if different — Phase 1b correctly placed between inventory and framework load
- [x] skill-conventions.md has formal Provenance Rule (not "Future Consideration") — Section promoted with full specification

## Concerns (must address)

- **Security [C1]** [moderate]: JSON injection via unescaped `printf` interpolation in `scripts/provenance-check.sh:136`. Values containing `"` or `\` produce malformed JSON. Low exploitation risk (files are version-controlled) but fragile for downstream consumers.

- **Correctness [C1]** [moderate]: Missing `skill_count`/`hook_count` fields in a `.provenance.yaml` file are treated as FRESH (false negative). `scripts/provenance-check.sh:112,119` only check non-empty values — a malformed sidecar silently passes.

- **Correctness [C2]** [moderate]: Handoff Phase 4b spec inconsistency — retro is listed as a source (line 228) but the output template and Rule 10 only mandate Deferred Actions + Lessons subsections. Retro action items could be silently dropped.

## Suggestions (optional improvements)

- **UX/DX [S1]**: `--level stop` has no behavioral difference from `warn` — either remove or document intended future distinction.
- **Security/UX/DX [S2]**: `--level` without argument crashes with opaque "unbound variable" error. Add arity validation.
- **UX/DX [S3]**: Add `--help` flag — current `Unknown option: --help` exit is poor UX.
- **Security/Codex/UX/DX [S3]**: Delta formatting `(4)` is ambiguous — should be `(+4)` for positive deltas.
- **UX/DX [S4]**: `docs-criteria.provenance.yaml` and `review-criteria.provenance.yaml` omit `designed_for` — inconsistent with 4 other files.
- **Architecture [S1]**: Commit bundles two distinct features (provenance + handoff unresolved items). Separate commits would improve traceability.
- **UX/DX [S5]**: ANSI colors not disabled for non-TTY output — piped output contains raw escape codes.
- **Security [S6]**: No target file existence check — dangling provenance (target renamed/deleted) silently reports FRESH.
- **Security [S4]**: `${skill_delta:+${skill_delta#+}}` expansion is a no-op — bash arithmetic never produces leading `+`.
- **Architecture [C1]**: YAML parsing via grep+sed is brittle — no support for quoted values, comments, or multi-line strings. Acceptable for current schema but fragile if format evolves.

## Confidence Note

- All 4 reviewers independently verified the same behavioral criteria with consistent results
- Security and Codex both flagged JSON injection and missing-field handling — high confidence these are real issues
- Delta formatting (`(4)` vs `(+4)`) was flagged by 3/4 reviewers — consensus finding
- Gemini review was notably concise compared to others — one concern and one suggestion. Possibly under-explored, but its architecture perspective (YAML parsing brittleness) was unique and valuable
- No external CLI fallbacks needed — both Codex and Gemini ran successfully

## Reviewer Provenance

| Reviewer | Source | Tool | Duration |
|----------|--------|------|----------|
| Security | REAL_EXECUTION | claude-task | 122s |
| UX/DX | REAL_EXECUTION | claude-task | 121s |
| Correctness | REAL_EXECUTION | codex | 250s |
| Architecture | REAL_EXECUTION | gemini | 64s |
