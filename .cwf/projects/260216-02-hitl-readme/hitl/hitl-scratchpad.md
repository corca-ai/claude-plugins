# HITL Scratchpad

Session: `260216-02-hitl-readme`
Updated: `2026-02-16T06:51:14Z`

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

- D-003 (Applied, v2): Session-first live-state writes + root summary compatibility implemented.
  - Root state keeps global/index metadata and optional `live.state_file` pointer.
  - Session-local state file (`session-state.yaml`) is resolved as effective live state when present and now acts as the default write target for scalar phase/task/session metadata.
  - Implemented by:
    - `scripts/cwf-live-state.sh`, `plugins/cwf/scripts/cwf-live-state.sh` (`resolve`/`sync`/`set`)
    - `set` writes effective session live state first, then synchronizes root `live` summary fields + `live.state_file` pointer
    - `plugins/cwf/hooks/scripts/compact-context.sh` now reads effective live-state file (session-first, root fallback)
    - `scripts/check-session.sh --live` and `plugins/cwf/scripts/check-session.sh --live` now validate effective live state
    - `plugins/cwf/scripts/check-growth-drift.sh` now validates hybrid pointer semantics and root-summary/effective-state scalar consistency
    - mirror-drift pair list + script map updated for `cwf-live-state.sh`
    - core skill docs migrated from direct root-live edits to helper-script contract (`plan`, `clarify`, `run`, `impl`, `retro`, `review`, `refactor`, `context-recovery-protocol`)
  - Remaining note:
    - list-field writes (`key_files`, `decision_journal`) still use manual edit on the resolved live-state file; scalar phase/session metadata is now script-managed.

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

- D-012 (Applied): HITL must update scratchpad after applying agreed edits.
  - Direction:
    - agreement capture alone is insufficient; post-edit state must be written back to `hitl-scratchpad.md` in the same loop.
    - keep status (`Applied/In progress`), rationale, and remaining items synchronized before continuing chunk review.
  - Applied to `plugins/cwf/skills/hitl/SKILL.md`.

- D-013 (Applied): `README.ko.md` setup 문장에 인덱스의 저장소 전역 탐색/라우팅 목적을 명시.
  - Final wording:
    - `에이전트가 CWF 사용법 및 저장소 전역을 빠르게 탐색하는 걸 돕는 인덱스 문서를 생성(별도 파일 또는 AGENTS.md 통합)`
  - Applied to `README.ko.md`.

- D-014 (Applied): 세션 로그는 Claude/Codex 공통으로 다중 로그 심링크를 세션 디렉토리에 유지.
  - Direction:
    - runtime 로그 원본은 `.cwf/projects/sessions/`에 저장
    - 각 세션 디렉토리에는 단일 파일이 아니라 `session-logs/*.md`로 다중 심링크
    - 기존 소비자 호환용으로 `session-log.md`는 대표 로그 alias로 유지
    - 로그 헤더에 기록 주체(`Recorded by: {user}@{host}`)를 남김
  - Implemented by:
    - `plugins/cwf/hooks/scripts/log-turn.sh` (Claude logs)
    - `plugins/cwf/scripts/codex/sync-session-logs.sh` + `scripts/codex/sync-session-logs.sh` (Codex logs)
    - `plugins/cwf/skills/retro/SKILL.md` (multi-link policy)
    - `docs/cwf-artifact-migration-plan.md` (path policy update)

- D-015 (Applied): README/문서 코멘트 HITL 진행 형식을 고정.
  - Direction:
    - 각 항목을 `Before / After / After Intent` 순서로 제시
    - 사용자가 중단하지 않는 한 "다음 항목 진행 여부"를 묻지 않고 연속 진행
  - Applied to:
    - `plugins/cwf/skills/hitl/SKILL.md` (Rules 11, 12)
    - `README.ko.md` (운영 원칙의 향후 방향 문장 정리)

- D-016 (Applied): `README.ko.md`의 남은 인라인 코멘트 구간을 why/what 톤으로 정리.
  - Applied sections:
    - `retro`: 도구 관점 기록 이유 명확화
    - `refactor`: 설계 의도 불렛 구조 단순화
    - `ship`: 사용자 명시 요청 기반 예외 머지 정책 문장 반영
    - `review`: Codex 메인 에이전트 상황의 외부 슬롯 동작 명시
    - `hitl`: 합의 라운드 중심 목적 문장 + 불필요한 alias 노출 제거
    - `update`: 설계 의도 섹션 신설
    - `Codex 연동`: wrapper 확장 가능 범위(세션 단위 후처리) 명시

- D-017 (Applied): HITL 진행 규칙 해석 보정.
  - Clarification:
    - "다음 항목 진행 여부를 묻지 않는다"는 전체 자율 진행이 아니라, 현재 항목 합의 직후 다음 청크를 즉시 제시한다는 의미
    - 현재 항목이 미합의 상태면 같은 항목에서 계속 합의
  - Applied to:
    - `plugins/cwf/skills/hitl/SKILL.md` (Rule 12 wording fix)

- D-018 (Applied): `CWF의 역할`에서 향후 방향 문장을 제거.
  - Direction:
    - 현재 역할/범위 설명은 현재 동작만 유지하고, 미래 계획 문구는 제외
  - Applied to:
    - `README.ko.md` (`CWF의 역할` 문단)

- D-019 (Applied): `접근` 섹션 문장 구조 재구성.
  - Direction:
    - "토큰은 이미 싸고 더 싸질 것"을 전제로 효과 중심 설계를 첫 문단에 명시
    - "효율을 완전히 등한시하지 않는다"는 문장을 같은 문단 안에서 회고 루프와 연결
    - "실행 경로 안정화"를 "올바른 문서/코드 작성 강제"로 구체화
    - 운영 결정은 번호+이유 분리 대신 `항목: 이유` 형태의 간결한 목록으로 정리
    - 출처 추적 별도 운영 결정 문단은 제거
  - Applied to:
    - `README.ko.md` (`접근` 문단/목록/운영 결정 블록)

- D-020 (Applied): 문서 HITL의 `Before/After` 제시 범위를 확대.
  - Direction:
    - 판단 가능한 수준의 주변 맥락(문단/소절 전체)을 함께 제시
    - 단일 문장만 떼어 보여주는 방식은 지양
  - Applied to:
    - `plugins/cwf/skills/hitl/SKILL.md` (Rule 11 context requirement)

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

- I-003 (Applied, v1): Add a repository-wide growth tracking design tied to provenance/state.
  - Why: CWF assumes skills/scripts will keep growing per user environment; growth impact must be visible across the whole codebase, not only per-skill.
  - Direction: design a mechanism that detects and reports cross-surface mismatch (skills/docs/hooks/scripts/state), then reflect it in runtime checks and docs.
  - v1 scope:
    - add `check-growth-drift.sh` to report mismatches across skills/docs/scripts/state/provenance
    - wire report into strict pre-push profile as non-blocking (`--level inform`)
    - update setup/dev docs to include this report in strict profile behavior
  - Implemented by:
    - `scripts/check-growth-drift.sh`, `plugins/cwf/scripts/check-growth-drift.sh`
    - strict profile hook integration (`configure-git-hooks.sh`)
    - setup/dev docs updates
  - Commit: `433f3b2`

- I-004 (Applied): Add project-level runtime configuration layer.
  - Files:
    - `.cwf/config.yaml` (shared, non-secret)
    - `.cwf/config.local.yaml` (local/secret, gitignored)
  - Resolution order:
    1) project local (`.cwf/config.local.yaml`)
    2) project shared (`.cwf/config.yaml`)
    3) process environment
    4) shell profiles
  - Scope: update env loader, setup/migration flow, and README/README.ko alignment.
  - Implemented by:
    - env-loader and artifact path resolver project-config precedence
    - setup bootstrap script (`bootstrap-project-config.sh`)
    - README.ko/README env + quick-start alignment
  - Commit: `2e31c47`

## Open Questions

- None currently. Continue with remaining implementation backlog.

## Skill Update Backlog

- S-001 (Applied): `plan/SKILL.md` description/rationale rewritten around runtime-independent file contracts (`plan.md` + `lessons.md` + optional `phase-handoff.md`).
- S-002 (Applied): language policy aligned (`plan.md` in English, `lessons.md` in user language) across `plan/SKILL.md`, `impl/SKILL.md`, and `plan-protocol.md`.
- S-003 (Applied): `impl/SKILL.md` now requires incremental `lessons.md` updates during direct and batch execution.
- S-004 (Applied): plan why-text aligned with post-plan-mode architecture (gather+clarify quality input, handoff continuity, file-contract reliability across runtimes).

## Next Pending Item

- Continue `README.ko.md` agreement/apply loop.
- Reflect remaining README.ko intent comments into README.md and related skill docs one chunk at a time via HITL.

## Notes

- This scratchpad is intentionally narrative; actionable edits still map to queue/fix-queue state.
