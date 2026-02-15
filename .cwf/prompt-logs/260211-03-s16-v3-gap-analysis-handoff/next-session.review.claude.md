# Review Synthesis: S16 next-session.md

## Verdict: Conditional Pass

이 handoff 문서는 omission-resistant 분석 프로토콜로서 evidence hierarchy,
Decision Rationale table, bidirectional consistency pass 등 강력한 구조적
설계를 보여주지만, 6명의 리뷰어가 공통적으로 지적한 **구조적 제어 결함**과
**모호한 scope 정의** 문제가 해결되어야 안전하게 실행 가능합니다.

## Concerns (must address)

- **Codex (Correctness)** [critical]: Phase 0의 git 명령이
  `prompt-logs/**`만 커버하여 Hard Scope Anchor에 명시된
  `plugins/cwf/**`, `cwf-state.yaml`, `docs/v3-migration-decisions.md`
  변경 파일이 corpus manifest에서 구조적으로 누락됩니다.
  `next-session.md:77`
- **Codex (Correctness)** [critical]: `42d2cd9..HEAD`에서 HEAD를 세션 시작
  시 고정하는 절차가 없어, 분석 중 새 커밋 유입 시 Phase 간 입력 집합
  불일치가 발생합니다. `next-session.md:25-26`
- **UX/DX** [moderate]: Workstream milestone 목록
  (`S13.5 A/B/B2/B3/C/D/E, S32, S33`)이 `cwf-state.yaml` 실제 session
  ID(`S13.5-A`, `S32-impl`, `S29`, `post-B3`)와 불일치합니다.
  `next-session.md:94`
- **UX/DX** [moderate]: Master-plan decisions "#1-#20"만 지정하여
  S13.5-S33에서 발생한 emergent decisions
  (`v3-migration-decisions.md`)가 coverage matrix에서 누락될 수 있습니다.
  `next-session.md:92`
- **UX/DX** [moderate]: 기존 handoff 관례인 `## Context` read-list,
  `## Don't Touch` boundary 섹션이 없습니다.
- **Codex (Correctness)** [moderate]: Phase 0에서 missing/unreadable을
  "명시"만 요구하고, 이후 Phase에서 해당 결손이 완료 판정에 반영되는
  메커니즘이 없습니다.
- **Architecture** [moderate]: Hard Scope Anchor에서
  `prompt-logs/**`와 `prompt-logs/sessions/*.md`가 중복 나열되어 scope
  해석 모호성이 있습니다. `next-session.md:29-31`
- **Expert β (Leveson/STPA)** [critical]: Phase 0→1 전환이 open-loop —
  manifest 완전성 검증 없이 coverage matrix 작성으로 진행됩니다.
- **Expert β (Leveson/STPA)** [high]: "Do Not Skip" 4개 항목이
  Completion Criteria에 대응하는 검증 메커니즘 없이 선언적으로만 존재합니다.
- **Expert α (Adzic/SbE)** [high]: 6개 artifact 포맷에 대한 key example이
  전무하여 해석 편차(telephone game) 위험이 있습니다.
- **Expert α (Adzic/SbE)** [high]: Completion criteria가
  existence-based로만 되어 있어 내용이 hollow한 채로 통과 가능합니다.

## Suggestions (optional improvements)

- **Codex**: 시작 시 `TIP=$(git rev-parse HEAD)` 고정, 분류 규칙 표준화
  (S1-S2)
- **UX/DX**: `## Dependencies`, `## After Completion` 섹션 추가, output
  directory 명시, Korean 검색어 영어 번역 병기, Phase 4 구체 절차 보완,
  corpus 규모 추정치 추가 (S1-S8)
- **Architecture**: Phase 4 timeline 기준 정의, error handling/compact
  recovery 프로토콜 추가, "Suggested Output Order"를 presentation concern으로
  분리 (S4-S6)
- **Expert α**: Phase 2 후 collaborative checkpoint 추가, Evidence
  Hierarchy 충돌 해결 예시 추가, "Do Not Skip"을 falsifiable assertion으로
  전환, `summary.md` 구조 정의
- **Expert β**: 프로토콜을 STPA control structure diagram으로 모델링,
  Phase 3 검색어 경계 명확화, degraded-mode 프로토콜 추가, Decision
  Rationale table에 "Do Not Skip" 항목 포함

## Confidence Note

- Gemini CLI가 120s timeout으로 실패 (TOOL_ERROR: `Tool "run_shell_command"
  not found`) → Architecture 슬롯에 Claude Task fallback이 사용됨.
  Architecture 관점의 다양성이 제한될 수 있음
- 6명 리뷰어 중 5명이 **Phase 0 git 명령의 scope 불완전성**을 독립적으로
  지적 — 높은 합의도
- 6명 중 4명이 **milestone/decision 목록의 불일치**를 지적 — Correctness와
  UX/DX, Architecture, Expert β 일치
- Security 리뷰어는 blocking concern 없음 (read-only analysis protocol
  특성상 보안 표면 최소)
- Expert α와 β의 분석이 상호보완적: α는 specification 명확성(해석 위험),
  β는 control structure 완전성(검증 위험)에 집중
- Success criteria가 plan.md에 없어 general best practices 기준으로만
  리뷰됨

## Reviewer Provenance

| Reviewer | Source | Tool | Duration |
|----------|--------|------|----------|
| Security | REAL_EXECUTION | claude-task | — |
| UX/DX | REAL_EXECUTION | claude-task | — |
| Correctness | REAL_EXECUTION | codex | 28954ms |
| Architecture | FALLBACK | claude-task-fallback | — |
| Expert Alpha | REAL_EXECUTION | claude-task | — |
| Expert Beta | REAL_EXECUTION | claude-task | — |
