# HITL Scratchpad

Session: `260216-02-hitl-readme`
Updated: `2026-02-16T04:17:01Z`

## Purpose

Single source of truth for HITL consensus, rationale, and unresolved questions.

## Working Process

1. Agree each `README.ko.md` comment one by one.
2. Apply agreed edits to `README.ko.md`.
3. Propagate intent to related files (`README.md`, related skill/docs) after Korean SoT is stable.

## Agreed Decisions

- D-001 (Agreed): Add a strong SoT disclaimer at the top of `README.ko.md`.
  - Tone: strong policy, aligned with current document tone.
  - Direction: if docs and implementation diverge, implementation must be fixed to match the doc; request issue/PR reports.

- D-002 (Agreed): Quick Start keeps concise form, but setup reason must be explicit.
  - Direction: explain why `cwf:setup` is needed.
  - Include index reason explicitly (progressive disclosure / agent routing via managed AGENTS index), not vague "optional index generation".
  - Keep detailed flags deferred to the `#setup` section.

- D-003 (Agreed as implementation-plan item): Move toward a hybrid state model.
  - Root state keeps global/index metadata.
  - Session-local state handles volatile per-session execution state.
  - README/document updates follow after implementation design is finalized.

- D-004 (Agreed final wording): In the "CWF role" sentence, use flow-style wording:
  - `컨텍스트 수집 → 요구사항 명확화 → 계획 → 구현 → 리뷰 → 리팩토링 → 회고 → 배포 준비(GitHub 이슈 및 PR)`
  - Avoid plain `배포`.
  - Boundary wording uses `CI/CD` only (not `배포/CI CD`).

- D-005 (Agreed final wording pattern): Rewrite the "concept" definition sentence after grounding wording in `references/essence-of-software/distillation.md`, split into two sentences.
  - Sentence 1: concept definition.
  - Sentence 2: concept behavior in CWF.
  - Direction: prioritize source definition (clear purpose, reusable unit, own state, atomic actions), avoid over-interpretation.
  - Applied to `README.ko.md` with source-first wording.

- D-006 (Agreed wording update): Replace opaque `drift` wording in README prose with plain Korean.
  - Applied wording: `변화 누락`, `기준 어긋남`.

- D-007 (Agreed plan rationale wording): Rewrite `README.ko.md` plan rationale around post-v3 architecture.
  - Start with: `CWF 통합(v3.0) 이전에는 ... CWF v3에서는 ... 설계 의도는 다음과 같습니다.`
  - First point includes lesson capture during planning conversation (`lessons.md` accumulation).
  - Second point explains Claude Code plan-context reset option vs CWF handoff/file-continuity approach.
  - Closing sentence uses: `안전하게, 길게, 자율적으로, 똑똑하게 작업`.

- D-008 (Applied pattern expansion): Align other skill descriptions in `README.ko.md` to the same pattern used in plan.
  - Pattern: `설계 의도` (why-first) + `무엇을 하는가` (what summary).
  - Applied sections: `gather`, `clarify`, `impl`, `retro`, `refactor`, `handoff`, `ship`, `review`, `hitl`, `run`, `setup`, `update`, and `Codex 연동`.
  - Also removed stale inline review comments in those skill-reference blocks.

- D-009 (Wording correction): Replace `작업 흐름` heading with `무엇을 하는가` across skill references.
  - Reason: README skill reference should be `why + what` by default; detailed `how` belongs to each `SKILL.md` unless non-obvious.

- D-010 (Applied): Project-level config direction has been implemented and reflected in README.
  - Direction:
    - `.cwf/config.yaml`: shared, non-secret project settings.
    - `.cwf/config.local.yaml`: local/secret settings, excluded from version control.
    - Priority: project settings override global settings.

- D-011 (Applied): Add token-economics/effectiveness-first assumption and human-bottleneck framing.
  - Direction:
    - Add to `가정`: CWF targets heavy coding-agent usage (including `$200 Max` plan users), prioritizing effectiveness over immediate token efficiency.
    - Add to `문제`: in long parallel work, final bottleneck shifts to human cognition/review throughput; token minimization alone does not reduce end-to-end lead time.
  - Applied to `README.ko.md` and synchronized in `README.md`.

- I-001 (Applied): Make agreement-capture notes a default HITL behavior.
  - Implemented in `plugins/cwf/skills/hitl/SKILL.md` as default agreement round before chunk review.
  - `hitl-scratchpad.md` is now explicit state artifact and rationale log.
  - Goal: persist ongoing agreements/decisions during HITL so context is not lost between turns.

- I-002 (Applied): Keep one default `cwf:hitl` flow (no extra flag), but start with an agreement round before chunk-by-chunk discussion.
  - Steps:
    1) collect major decision points (prefer ship artifacts when available),
    2) merge user-provided issues,
    3) record agreements to `hitl-scratchpad.md`,
    4) apply high-impact agreed edits,
    5) ask whether to start chunk review.
  - Keep `queue.json` and `fix-queue.yaml` as execution queues.
  - Keep `hitl-scratchpad.md` as rationale/consensus log (separate role, linked workflow).

- I-003 (Planned implementation/design): Add a repository-wide growth tracking design tied to provenance/state.
  - Why: CWF assumes skills/scripts will keep growing per user environment; growth impact must be visible across the whole codebase, not only per-skill.
  - Direction: design a mechanism that detects and reports cross-surface mismatch (skills/docs/hooks/scripts/state), then reflect it in runtime checks and docs.
  - Status: requires joint design discussion before implementation.

- I-004 (In progress): Add project-level runtime configuration layer.
  - Files:
    - `.cwf/config.yaml` (shared, non-secret)
    - `.cwf/config.local.yaml` (local/secret, gitignored)
  - Resolution order:
    1) project local (`.cwf/config.local.yaml`)
    2) project shared (`.cwf/config.yaml`)
    3) process environment
    4) shell profiles
  - Scope: update env loader, setup/migration flow, and README/README.ko alignment.
  - Progress:
    - env-loader and artifact path resolver updated with project-config precedence
    - setup bootstrap script added (`bootstrap-project-config.sh`)
    - README.ko/README env section and quick-start rationale updated
  - Remaining:
    - finalize deterministic checks and commit

## Open Questions

- None currently. Continue with remaining implementation backlog.

## Skill Update Backlog

- S-001 (Applied): `plan/SKILL.md` description/rationale rewritten around runtime-independent file contracts (`plan.md` + `lessons.md` + optional `phase-handoff.md`).
- S-002 (Applied): language policy aligned (`plan.md` in English, `lessons.md` in user language) across `plan/SKILL.md`, `impl/SKILL.md`, and `plan-protocol.md`.
- S-003 (Applied): `impl/SKILL.md` now requires incremental `lessons.md` updates during direct and batch execution.
- S-004 (Applied): plan why-text aligned with post-plan-mode architecture (gather+clarify quality input, handoff continuity, file-contract reliability across runtimes).

## Next Pending Item

- Resolve the next unresolved README comment after D-005 and record agreement.

## Notes

- This scratchpad is intentionally narrative; actionable edits still map to queue/fix-queue state.
