# Next Session: Post S13.5-B3

## Status

S13.5-B3 concept refactor **구현 완료**. PR #18 open (`feat/concept-refactor-integration` → `marketplace-v3`).

- Branch: `feat/concept-refactor-integration`
- Issue: #17 (PR merges → auto-close)
- 인간 판단 필요 사항 2개가 PR에 기재됨 (아래 참조)

## How to start

**반드시 plan mode로 진입**하여 작업할 것. `EnterPlanMode`을 사용하여 plan을 작성하고
`ExitPlanMode`으로 승인받은 뒤 구현을 진행한다.

이유: exit-plan-mode.sh hook (PreToolUse:ExitPlanMode)이 Deferred Actions 섹션 존재를
검증하는 기능이 S13.5-B3에서 구현되었으며, fresh context에서 정상 작동하는지 테스트 필요.

## What needs to happen next

### 1. PR #18 리뷰 및 머지

PR의 "인간 판단 필요 사항":

- Form/Meaning/Function 3축이 실제 refactor 실행 시 기존 PP/BI/MC 대비 더 유용한 분석 결과를 만드는지
- concept-map.md의 verification criteria가 agent가 활용하기에 충분한 구체성을 가지는지

검증 방법: `refactor --holistic` 또는 `refactor --skill clarify` 실행 후 결과 판단.
머지: `/ship merge` (squash default).

### 2. Provenance housekeeping

5개 사이드카가 `hook_count: 13` → 실제 14. S13.5-B3에서 `exit-plan-mode.sh` 추가 후 미업데이트:

- `CLAUDE.provenance.yaml`
- `docs/project-context.provenance.yaml`
- `plugins/cwf/references/expert-advisor-guide.provenance.yaml`
- `plugins/cwf/references/skill-conventions.provenance.yaml`
- `plugins/cwf/skills/refactor/references/docs-criteria.provenance.yaml`

각 파일에서 `hook_count: 13` → `14`로 수정. 내용 변경이 필요한지도 함께 확인.

### 3. Unresolved items (이전 세션들에서 이월)

- [ ] Expert roster update: James Reason, Sidney Dekker 추가 검토 (S13.5-B3 retro에서 사용됨)
- [ ] Hook audit: 모든 hook script에서 silent `exit 0` paths 스캔 (Reason recommendation)

## Context Files to Read

1. `plugins/cwf/references/concept-map.md` — 이번에 생성된 concept-level 참조 문서
2. `plugins/cwf/skills/refactor/references/holistic-criteria.md` — Form/Meaning/Function 재구성 결과
3. `plugins/cwf/skills/refactor/references/review-criteria.md` — 8 criteria (merged 4+5, added 8)
4. `prompt-logs/260209-27-s13.5-b3-concept-refactor/lessons.md` — 18 lessons (3 sub-sessions)
5. `prompt-logs/260209-27-s13.5-b3-concept-refactor/retro.md` — 2개 retro (hook observability deep + implementation light)
