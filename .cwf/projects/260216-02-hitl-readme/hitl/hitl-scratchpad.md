# HITL Scratchpad

Session: `260216-02-hitl-readme`
Updated: `2026-02-16T03:55:21Z`

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

- D-010 (Agreed env direction): Document future project-level config direction in README now, implement later.
  - Direction:
    - `.cwf/config.yaml`: shared, non-secret project settings.
    - `.cwf/config.local.yaml`: local/secret settings, excluded from version control.
    - Priority: project settings override global settings.

- I-001 (Planned implementation change): Make agreement-capture notes a default HITL behavior.
  - Current state: not implemented as default (current HITL state model has `state.yaml`, `rules.yaml`, `queue.json`, `fix-queue.yaml`, `events.log`).
  - Candidate artifact: `hitl-scratchpad.md`.
  - Goal: persist ongoing agreements/decisions during HITL so context is not lost between turns.

- I-002 (Agreed HITL default flow direction): Keep one default `cwf:hitl` flow (no extra flag), but start with an agreement round before chunk-by-chunk discussion.
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

- I-004 (Planned implementation/design): Add project-level runtime configuration layer.
  - Files:
    - `.cwf/config.yaml` (shared, non-secret)
    - `.cwf/config.local.yaml` (local/secret, gitignored)
  - Resolution order:
    1) project local (`.cwf/config.local.yaml`)
    2) project shared (`.cwf/config.yaml`)
    3) process environment
    4) shell profiles
  - Scope: update env loader, setup/migration flow, and README/README.ko alignment.

## Open Questions

- README top temporary memo block (`추가로 생각난 것들`) finalization and conversion to polished prose.

## Skill Update Backlog

- S-001 (Plan skill wording cleanup): `plugins/cwf/skills/plan/SKILL.md` description still mentions "plan-protocol hook (passive injection)" even though plan mode hooks were removed.
  - Direction: rewrite rationale around file-based execution contract (`plan.md` + `lessons.md`) and CWF pipeline integration.

- S-002 (Language policy consistency): lessons language rule is inconsistent across docs.
  - Evidence:
    - `plugins/cwf/references/plan-protocol.md` says lessons are in user language.
    - `plugins/cwf/skills/plan/SKILL.md` and `plugins/cwf/skills/impl/SKILL.md` currently say all implementation artifacts are in English.
  - Direction: explicitly separate `plan.md` language vs `lessons.md` language and align all references.

- S-003 (Lesson accumulation clarity in impl): lesson recording is strong for lesson-driven commits, but weaker as an explicit ongoing behavior.
  - Direction: in `plugins/cwf/skills/impl/SKILL.md`, add a clear rule to update `lessons.md` incrementally during implementation (not only when commit protocol is triggered).

- S-004 (Plan rationale alignment across README/skills): update plan why-text to reflect post-plan-mode architecture.
  - Direction: encode the agreed rationale that CWF replaces legacy plan-mode value via
    1) gather+clarify for higher-quality planning context,
    2) handoff for context-boundary recovery,
    3) file-based contracts for reliable plan→impl→review continuity across runtimes (including Codex).

## Next Pending Item

- Resolve the next unresolved README comment after D-005 and record agreement.

## Notes

- This scratchpad is intentionally narrative; actionable edits still map to queue/fix-queue state.
