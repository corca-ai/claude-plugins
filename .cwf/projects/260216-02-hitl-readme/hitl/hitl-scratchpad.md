# HITL Scratchpad

Session: `260216-02-hitl-readme`
Updated: `2026-02-16T09:27:26Z`

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

- D-021 (Applied): 사용자 수정분 기준으로 상단~핵심 개념 구간 정합성 정리.
  - Direction:
    - 비워둔 링크는 실제 섹션 앵커로 연결
    - 코멘트가 섞인 코드펜스/문장 잔여를 문서 본문 규칙으로 정리
    - 핵심 개념 순서를 운영 흐름(`결정 포인트 -> 전문가 자문 -> 티어 분류 -> ...`) 기준으로 재배치
    - 모호 표현(`시점에 맞는 권한`, `기준`)을 구체 용어로 치환
  - Applied to:
    - `README.ko.md` (설치/Codex 설정/접근/핵심 개념)

- D-022 (Applied): 핵심 개념 순서 변경에 맞춰 `개념 조합` 문단의 내부 나열 순서를 동기화.
  - Direction:
    - `clarify` 조합 설명도 `결정 포인트 -> 전문가 자문 -> 티어 분류 -> 에이전트 조율` 순서로 맞춤
  - Applied to:
    - `README.ko.md` (`개념 조합` 문단)

- D-023 (Applied): 용어/표기 통일.
  - Direction:
    - 문서 본문의 `결정 포인트`를 `의사결정 포인트`로 통일
    - 단독 표기 `` `cwf` ``는 사용하지 않고 `CWF`로 통일
    - `cwf:...` 명령 표기만 예외로 유지
  - Applied to:
    - `README.ko.md` (사용 시나리오/레거시 안내/핵심 개념/clarify/개념 조합/결과)

- D-024 (Applied): `ship` 문장 톤/표현 교정.
  - Direction:
    - `차단 이슈가 없고` -> `없거나`
    - `예외 머지` 표현 대신 `머지를 강행할 수 있습니다`
    - `같은 흐름으로 추가` 표현 제거, `머지 전에 cwf:hitl 추가`로 단순화
  - Applied to:
    - `README.ko.md` (`ship`의 설계 의도/무엇을 하는가)

- D-025 (Applied): `review/hitl/run` 구간의 사람/인간 표현을 사용자 중심으로 정렬.
  - Direction:
    - `사람 판단` -> `사용자 판단`
    - `사람이 직접 검토` -> `사용자가 직접 검토`
    - `인간 게이트` -> `사용자 게이트`
  - Applied to:
    - `README.ko.md` (`hitl` 소개/설계 의도, `run` 설계 의도)

- D-026 (Applied): `Codex 연동` 명령 블록 코드펜스 유형 정렬.
  - Direction:
    - 코딩 에이전트 내 명령 예시 표기 원칙에 맞춰 `bash` 대신 `text` 사용
  - Applied to:
    - `README.ko.md` (`### Codex 연동` 명령 블록)

- D-027 (Applied): `setup`/`Codex 연동` 내 `wrapper` 표기 정리.
  - Direction:
    - `codex wrapper` -> `Codex wrapper`
    - 본문 식별자 표기는 `` `wrapper` ``로 명확화
  - Applied to:
    - `README.ko.md` (`setup` 명령 주석, `Codex 연동` 설명 문장)

- D-028 (Applied): `Codex 연동`의 미합의 결론형 문장 완화 + 훅 표기 정리.
  - Direction:
    - `확장 가능합니다` 같은 결론형 표현 제거
    - 확장은 별도 설계/합의가 필요한 검토 항목으로 명시
    - 훅 표의 `->` 표기를 `→`로 통일하고, `cwf:setup` 조사(`를`)를 `을`로 교정
  - Applied to:
    - `README.ko.md` (`Codex 연동`, `훅`, `환경 설정` 도입 문장)

- D-029 (Applied): `가정` 문단 예시 표기만 국문화.
  - Direction:
    - `e.g.` -> `예:`로 교체
    - 반복 회피 목적의 `사람` 표현은 유지
  - Applied to:
    - `README.ko.md` (`가정` 마지막 bullet)

- D-030 (Applied): 워크플로우 테이블 `하는 일` 문구를 why/what 기준으로 전면 교정.
  - Direction:
    - `clarify`는 "스펙으로 전환" 대신 의사결정 포인트 분해 + 티어 분류로 입력 정제로 표현
    - `impl`/`retro`는 추상 문구를 줄이고 실제 실행/환원 동작을 명시
    - `refactor`는 `review`와의 역할 중복을 피하도록 "정리/정합성 회복" 중심으로 표현
    - `hitl`의 `사람 참여형` 표현을 자연스러운 사용자 합의/청크 검토 문장으로 교체
  - Applied to:
    - `README.ko.md` (`워크플로우` 테이블)

- D-031 (Applied): `개념 조합` 문단 제거.
  - Direction:
    - 워크플로우 소개에서 필수성이 낮고 중복 설명이 발생하므로 삭제
  - Applied to:
    - `README.ko.md` (`워크플로우` 직후 문단)

- D-032 (Applied): README 설명 문맥의 경로 표기는 링크 대신 백틱 경로로 유지.
  - Direction:
    - 문서 탐색 목적 링크가 아닌 설명용 경로(`.cwf/projects/`, `.cwf/cwf-state.yaml`)는 인라인 코드로 표기
  - Applied to:
    - `README.ko.md` (`gather`, `hitl` 설명 문단)

- D-033 (Applied): `retro` 설명을 섹션 단위로 명시화.
  - Direction:
    - "섹션별 설명이 필요" 요구에 맞춰 `무엇을 하는가`에 7개 섹션 목적을 번호로 명시
    - 심층 모드 보조 산출물 파일(`retro-cdm-analysis.md`, `retro-expert-*.md`, `retro-learning-resources.md`)을 README에 직접 표기
  - Applied to:
    - `README.ko.md` (`retro`의 설계 의도/무엇을 하는가)

- D-034 (Applied): `update` 설명은 사용자 문장(1인칭 동기)을 최대한 유지.
  - Direction:
    - 공식 문체보다 실제 도입 동기를 드러내는 문장을 우선
    - `계약과 동기화` 표현 제거
  - Applied to:
    - `README.ko.md` (`update`의 설계 의도)

- D-035 (Applied): `run` 설명에 프로젝트별 `cwf-state` 역할을 명시.
  - Direction:
    - `run`의 상태 관리 설명에서 전역/추상 표현 대신 "각 프로젝트의 `.cwf/cwf-state.yaml`"을 직접 표기
    - `cwf-state`는 포인터, 세부 상태는 세션 파일이라는 역할 분리를 명확화
  - Applied to:
    - `README.ko.md` (`run`의 무엇을 하는가)

- D-036 (Applied): `setup`에 Agent Team 설정 단계를 구현.
  - Direction:
    - `cwf:setup` 실행 흐름에 Agent Team 설정(Phase 2.9)을 추가
    - Agent Team 설정만 재실행 가능한 `cwf:setup --agent-teams` 경로 추가
    - 실제 적용은 스크립트로 수행해(`configure-agent-teams.sh`) 상태 조회/enable/disable을 결정적으로 처리
  - Implemented by:
    - `plugins/cwf/skills/setup/SKILL.md` (mode routing + phase 2.9 + rules/references)
    - `plugins/cwf/skills/setup/scripts/configure-agent-teams.sh` (new)
    - `plugins/cwf/skills/setup/README.md` (file map update)
    - `README.ko.md` (`setup` quick start/table/설계 의도/무엇을 하는가 동기화)

- D-037 (Agreed): HITL 완화는 새 플래그를 추가하지 않고 기존 규약 안에서 개선.
  - Direction:
    - `Before/After/After Intent`와 넓은 문맥 제시 규약은 유지
    - 진행 방식은 더 창의적/지능적으로 운영하되, 별도 모드 플래그는 도입하지 않음

- D-038 (Applied, v1): Codex wrapper post-run quality checks (option 2 only).
  - Direction:
    - `cwf:setup --codex-wrapper`로 설치되는 wrapper 실행 뒤, "이번 실행에서 바뀐 파일" 기준의 경량 품질 점검을 자동 수행
    - 기본은 경고 모드(`warn`)로 보고만 하고, 필요 시 `strict`로 실패를 종료코드에 반영
    - 문서/셸/링크/라이브 상태 점검을 후처리로 묶어 사용자 검토 전에 기본 안전망을 제공
  - Implemented by:
    - `plugins/cwf/scripts/codex/post-run-checks.sh`, `scripts/codex/post-run-checks.sh` (new)
    - `plugins/cwf/scripts/codex/codex-with-log.sh`, `scripts/codex/codex-with-log.sh` (post-run hook + strict exit propagation)
    - `plugins/cwf/scripts/README.md` (script map)
    - `plugins/cwf/scripts/check-growth-drift.sh`, `scripts/check-growth-drift.sh` (mirror pair update)
  - Runtime controls:
    - `CWF_CODEX_POST_RUN_CHECKS=true|false` (default: `true`)
    - `CWF_CODEX_POST_RUN_MODE=warn|strict` (default: `warn`)
    - `CWF_CODEX_POST_RUN_QUIET=true|false` (default: `false`)

- D-039 (Applied): `README.ko.md`의 `retro` 7개 섹션 설명에 남아 있던 인라인 코멘트를 의도 문장으로 반영.
  - Direction:
    - 저장 위치 질문(`어디에 저장?`)은 `retro.md` 기본 + 재사용 가치 시 상위 문서 승격으로 명확화
    - CDM/Expert/Learning/Tool Gaps 항목은 \"왜 필요한가\"가 드러나도록 목적 문장으로 재작성
  - Applied to:
    - `README.ko.md` (`retro`의 7개 섹션 설명 목록)

- D-040 (Applied): SoT 기준으로 wrapper 설명과 README 동기화 정리.
  - Direction:
    - 구현된 wrapper 동작(세션 로그 동기화 + post-run 품질 점검)이 README/Setup 문서에 동일하게 반영되도록 정합화
    - `README.md`의 워크플로우 설명에서 SoT와 어긋난 보조 문단(`Concept composition`) 제거
  - Applied to:
    - `README.ko.md` (`setup`, `Codex 연동`의 wrapper 설명)
    - `README.md` (`retro`, `setup`, `Codex Integration` 설명 + concept composition 문단 제거)
    - `plugins/cwf/skills/setup/SKILL.md` (wrapper phase/옵션 설명)

- D-041 (Applied): 리트로 후속 반영 완료.
  - Direction:
    - 리트로 작성 뒤 완료된 수정사항(`README.ko` 잔여 코멘트 반영, README/Setup 동기화)을 회고 산출물에 반영
    - 이번 세션에서 발생한 범위 이탈/도구 위생 이슈의 원인과 방지책을 고정
  - Applied to:
    - `.cwf/projects/260216-02-hitl-readme/retro.md` (`Post-Retro Findings`)

- D-042 (Applied): 다음 세션 핸드오프에 retro 재발 방지 규약을 명시.
  - Direction:
    - deep retro 필수 절차(2-batch sub-agent, deep artifact + AGENT_COMPLETE, external learning resources, `/find-skills` 실행 근거)를 next-session에 강제 체크리스트로 고정
    - 다음 세션 구현 범위를 `2/4/5/6`만으로 명시하고 `3`은 제외
  - Applied to:
    - `.cwf/projects/260216-02-hitl-readme/next-session.md`

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

- Q-002: Codex 연동에서 wrapper 이후 확장할 세션 후처리(검증/상태 동기화) 훅 후보 정의.
- Q-003: HITL 기본 흐름의 체감 경직성을, 플래그 추가 없이 운영 방식 개선으로 어떻게 줄일지.

## Skill Update Backlog

- S-001 (Applied): `plan/SKILL.md` description/rationale rewritten around runtime-independent file contracts (`plan.md` + `lessons.md` + optional `phase-handoff.md`).
- S-002 (Applied): language policy aligned (`plan.md` in English, `lessons.md` in user language) across `plan/SKILL.md`, `impl/SKILL.md`, and `plan-protocol.md`.
- S-003 (Applied): `impl/SKILL.md` now requires incremental `lessons.md` updates during direct and batch execution.
- S-004 (Applied): plan why-text aligned with post-plan-mode architecture (gather+clarify quality input, handoff continuity, file-contract reliability across runtimes).

## Next Pending Item

- Define the next concrete implementation slice for Q-002 (wrapper post-run checks V2 candidate set).
- Implement a deterministic HITL intent-resync/state-check mechanism for Q-003.

## Notes

- This scratchpad is intentionally narrative; actionable edits still map to queue/fix-queue state.
