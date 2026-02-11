# GAP Decisions

- RANGE: 42d2cd9..01293b3e2501153789e40699c09777ac6df64624

## Decision Log

| decision_id | date | gap_id | decision | rationale | implementation contract | status |
|---|---|---|---|---|---|---|
| DEC-001 | 2026-02-11 | GAP-001 | Implement `cwf:review --scenarios <path>` properly before v3 merge (not deferred to v4). | Holdout validation is a high-impact quality gate and was already reserved in the v3 design line. | Add executable scenario ingestion and review integration in `plugins/cwf/skills/review/SKILL.md`; include BDD checks and evidence output path behavior. | Decided |
| DEC-002 | 2026-02-11 | GAP-002 | Implement dual strategy: upstream-aware base detection by default + explicit `--base <branch>` override. | Umbrella branch workflows need deterministic defaults, but operators still need manual control for atypical branch graphs. | Update `plugins/cwf/skills/review/SKILL.md` mode routing and target detection; add BDD checks for (a) normal upstream path, (b) explicit override path. | Decided |
| DEC-003 | 2026-02-11 | GAP-003 | Keep classification as `Unknown` for now; run a dedicated trace to decide `Resolved` vs `Unresolved` before implementation planning. | Evidence indicates partial work happened, but closure is not explicit enough to classify safely. | Next trace must map S13.5-B2 integration points to current `plugins/cwf/skills/refactor/references/*.md` and produce a binary closure verdict with evidence lines. | Decided |
| DEC-004 | 2026-02-11 | GAP-004 | Keep Decision #20 as a philosophy-level rule (no new deterministic enforcement in v3 pre-merge scope). | Team judgment quality is considered sufficient; additional hard gates are treated as unnecessary process overhead for this item. | No implementation action for GAP-004. Keep as accepted-policy risk and monitor through normal review/retro signals. | Decided |
| DEC-005 | 2026-02-11 | GAP-005 | Unify runtime logs into `prompt-logs/sessions/` with suffix naming (`*.claude.md`, `*.codex.md`), while temporarily supporting legacy `sessions-codex/` reads. | A single directory reduces omission risk in retro/handoff and preserves runtime provenance via suffix. | Update Codex sync output target and naming rule; update retro/handoff source discovery to read both new and legacy paths during migration window. | Decided |
| DEC-006 | 2026-02-11 | GAP-006 | Apply hybrid gate policy: hard-gate critical orchestration stages, soft-gate non-critical stages for missing sub-agent persistence artifacts. | Full hard-gating everywhere risks unnecessary blockage; full soft-gating risks silent data loss. Hybrid policy balances reliability and throughput. | Add stage-tier policy to orchestrators: review/plan/retro critical outputs require hard fail; optional/advisory outputs use warning+retry. | Decided |
| DEC-007 | 2026-02-11 | GAP-014 | Extend `check-session.sh` with a minimal semantic set first (not full expansion): core closure checks only. | Minimal semantic checks reduce false PASS risk with lower complexity and lower false-positive cost than full overhaul. | Add first-wave semantic checks for `GAP(Unresolved/Unknown)->BL` closure and `CW->GAP` mapping (optionally frozen RANGE consistency) before broader expansion. | Decided |

## Definition of Done for DEC-001

1. `--scenarios <path>` is parsed and used during review execution.
2. Missing/invalid scenario file behavior is explicit (fail with message or deterministic fallback policy).
3. Review output includes holdout assessment traceability.
4. Session artifacts include BDD evidence for at least one positive and one negative case.

## Definition of Done for DEC-002

1. Review target detection first resolves upstream/umbrella-safe base branch.
2. `--base <branch>` overrides default detection deterministically.
3. Invalid `--base` input behavior is explicit and testable.
4. Review provenance/output captures which base strategy was used.

## Definition of Done for DEC-003

1. `GAP-003` trace report exists with explicit line-level evidence.
2. Final class is updated from `Unknown` to `Resolved` or `Unresolved`.
3. If `Unresolved`, backlog item is updated with concrete implementation scope.

## Definition of Done for DEC-004

1. `GAP-004` is tagged as accepted-policy risk in decision/backlog artifacts.
2. No enforcement work item is added for v3 pre-merge.

## Definition of Done for DEC-005

1. New Codex logs are written under `prompt-logs/sessions/*.codex.md`.
2. Claude logs are normalized to `prompt-logs/sessions/*.claude.md` (or equivalent explicit runtime suffix policy).
3. Retro/handoff source discovery supports both:
   - `prompt-logs/sessions/*.codex.md`, `prompt-logs/sessions/*.claude.md`
   - legacy `prompt-logs/sessions-codex/*.md` (temporary compatibility)
4. Migration completion criteria are documented (when legacy path can be removed).

## Definition of Done for DEC-006

1. Stage-tier policy is explicit (critical vs non-critical outputs).
2. Critical stages fail deterministically on missing required sub-agent artifacts.
3. Non-critical stages emit warning + bounded retry policy.
4. Session outputs record which gate path (hard/soft) was applied.

## Definition of Done for DEC-007

1. `check-session.sh` supports the first-wave semantic checks for closure integrity.
2. Failure output is explicit about which semantic relation is broken.
3. Existing impl artifact checks remain backward-compatible.
