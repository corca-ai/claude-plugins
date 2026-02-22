# Lessons — retro-cwf-081-plus-postmortem

- Initialized by `next-prompt-dir --bootstrap`
- Add concrete learnings during planning and implementation

## Deep Retro Lesson — Update Oracle Integrity (2026-02-21)

- **Owner**: `plugin`
- **Apply Layer**: `upstream`
- **Promotion Target**: `plugins/cwf/scripts/check-update-latest-consistency.sh`
- **Due Release**: `0.8.9`
- **Expected**: `cwf:update` latest-version 판단이 사용자 체감 업데이트 경로와 일치한다.
- **Actual**: 캐시 기반 판정이 authoritative source와 불일치할 수 있어 `Current==Latest` 오판이 발생했다.
- **Takeaway**: 최신 판정은 authoritative source를 하드 게이트로 강제하고, 확인 불가 시 `UP_TO_DATE`를 금지해야 한다.

When update latest-version cannot be verified against authoritative marketplace metadata -> return `UNVERIFIED` and block success-style no-update verdicts.

## Deep Retro Lesson — Nested vs Top-Level Representativeness (2026-02-21)

- **Owner**: `plugin`
- **Apply Layer**: `upstream`
- **Promotion Target**: `scripts/premerge-cwf-gate.sh`
- **Due Release**: `0.8.9`
- **Expected**: smoke 환경 결과가 실사용 업데이트 경로를 충분히 대표한다.
- **Actual**: nested 세션 제약(예: marketplace refresh 불가)이 실사용 경로와 달라 오판을 조기에 차단하지 못했다.
- **Takeaway**: release/update 검증에는 top-level 사용자 경로를 별도 필수 체크로 유지해야 한다.

When nested-session refresh/update behavior differs from top-level behavior -> treat nested result as non-authoritative and require top-level verification evidence before release confidence claims.

## Deep Retro Lesson — Coverage Contract Before Deep Analysis (2026-02-21)

- **Owner**: `plugin`
- **Apply Layer**: `upstream`
- **Promotion Target**: `plugins/cwf/scripts/retro-coverage-contract.sh`
- **Due Release**: `0.8.9`
- **Expected**: 사용자가 범위를 지정하면 회고 초반에 전체 커버리지가 명시적으로 증빙된다.
- **Actual**: 첫 패스가 `plugins/cwf` 27개 변경 중심으로 보이면서, 사용자에게 “0.8.1 이후 전체를 본 것인지” 불신 신호를 만들었다.
- **Takeaway**: deep retro는 원인 분석 전에 `coverage contract`(총 파일 수, 포함/제외 범위, top-level 분해)를 먼저 산출/공유해야 한다.

When the user specifies a diff baseline/scope -> generate and cite a coverage matrix (total files, include/exclude rules, top-level breakdown) before causal narrative.

## Deep Retro Lesson — Reason Questions Use 5 Whys by Default (2026-02-21)

- **Owner**: `repo`
- **Apply Layer**: `local`
- **Promotion Target**: `AGENTS.md`
- **Due Release**: `2026-02-21`
- **Expected**: “왜/원인/이유” 질문에는 구조 원인까지 내려가는 일관된 포맷으로 답한다.
- **Actual**: 세션 중 일부 설명은 5 Whys 형식이 아닌 일반 설명으로 먼저 전달됐다.
- **Takeaway**: 원인 질문의 기본 응답 포맷을 5 Whys로 고정하고, 개선안은 그 다음에 제시한다.

When the user asks why/cause -> answer first in explicit 5 Whys structure, then propose fixes.

## Run Gate Violation — 2026-02-21T23:04:41Z
- **Owner**: `plugin`
- **Apply Layer**: `upstream`
- **Promotion Target**: `plugins/cwf/scripts/check-run-gate-artifacts.sh`
- **Due Release**: `next-release`
- Gate checker: `plugins/cwf/scripts/check-run-gate-artifacts.sh`
- Persistence gate: `HARD_FAIL`
- Recorded failures:
  - [refactor] refactor-summary.md missing heading: ## Refactor Summary

## Deep Retro Lesson — Debugging Capability Boundary (2026-02-22)

- **Owner**: `plugin`
- **Apply Layer**: `upstream`
- **Promotion Target**: `plugins/cwf/references/agent-patterns.md`
- **Due Release**: `next-release`
- **Expected**: 웹 디버깅 요구를 처리할 때 새 커맨드를 늘리지 않고 기존 stage(gather/impl/review)에서 직교적으로 재사용한다.
- **Actual**: `cwf:debug --web` 신설 가능성을 검토했지만, 현재 범위는 정보 탐색+구현 수정+검증의 조합으로 기존 stage 계약 안에서 충분히 수용 가능했다.
- **Takeaway**: 디버깅은 독립 명령보다 `agent-pattern`의 실행 패턴으로 먼저 흡수하고, 별도 계약이 필요할 때만 신규 skill route를 만든다.

When a proposed skill mostly composes existing stage responsibilities -> prefer agent-pattern integration first and add a new `cwf:<skill>` route only when it introduces unique contracts or irreversible workflow branches.

## Deep Retro Lesson — Conventions What/Why vs How Split (2026-02-22)

- **Owner**: `plugin`
- **Apply Layer**: `upstream`
- **Promotion Target**: `plugins/cwf/references/skill-conventions.md`
- **Due Release**: `next-release`
- **Expected**: `skill-conventions`가 철학/의도(what/why)를 명확히 유지하고, 실행 강제(how)는 단일 진입점으로 연결된다.
- **Actual**: how 정보가 `docs-criteria`와 deterministic gate 스크립트/훅으로 분산되어 보여 추적성이 약해질 우려가 있었다.
- **Takeaway**: conventions 문서에 `Enforcement Map`을 두고 what/why 문서에서 review criteria와 gate 구현을 한 번에 링크해 중복 없이 추적 가능하게 유지한다.

When policy intent and enforcement implementation live in separate files -> keep intent in one conventions document and maintain a single enforcement map that links review criteria and deterministic gate authorities.

## Deep Retro Lesson — Flagged Skill Refactor Commit Granularity (2026-02-22)

- **Owner**: `repo`
- **Apply Layer**: `local`
- **Promotion Target**: `AGENTS.md`
- **Due Release**: `2026-02-22`
- **Expected**: 다중 flagged skill 정리 시 변경 추적성과 롤백 단위가 명확하다.
- **Actual**: 병렬 수정 중 lint 실패가 섞이면 어느 skill에서 문제가 났는지 확인 비용이 증가했다.
- **Takeaway**: flagged 스킬 리팩터는 skill 단위(`review`, `run`, `retro`)로 lint 검증 후 순차 커밋한다.

When refactoring multiple flagged skills in one session -> commit per skill after deterministic lint/link gates to keep diagnosis and rollback boundaries explicit.
