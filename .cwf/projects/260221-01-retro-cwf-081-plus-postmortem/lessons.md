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
