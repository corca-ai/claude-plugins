# Next Session: S1 — Refactor Critical Fixes

## What This Is

CWF v3 마켓플레이스 마스터 플랜의 첫 번째 구현 세션.
9개 개별 플러그인을 단일 `cwf` 플러그인으로 통합하는 프로젝트의 사전 작업.

Full context (optional): `prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md`

## Task

main 브랜치에서 리팩터 리뷰 critical/important 이슈 수정.

## Scope

### Critical Fixes

1. **JSON escaping** — `jq` 미사용으로 인한 quote 미처리
   - `plugins/refactor/skills/refactor/scripts/quick-scan.sh:155,167`
   - `.claude/skills/plugin-deploy/scripts/check-consistency.sh` (`json_str()`)

2. **Unsafe eval** — `eval "$(grep ...)"` 패턴 제거
   - `plugins/gather-context/skills/gather-context/scripts/search.sh:37`
   - `plugins/gather-context/skills/gather-context/scripts/code-search.sh:29`
   - `plugins/gather-context/skills/gather-context/scripts/extract.sh:36`

3. **Stale lock** — lock file cleanup 누락
   - `plugins/attention-hook/hooks/scripts/track-user-input.sh`

### Convention Fixes

4. **`set -euo pipefail` 추가** — 11개 hook 스크립트 (markdown-guard, prompt-logger 제외 — 이미 있음)
5. **`#!/bin/bash` → `#!/usr/bin/env bash`** — 같은 11개 스크립트

## Don't Touch

- shell-guard는 standalone으로 만들지 않음 (v3에서 `cwf:lint-shell` hook으로 통합 예정)
- 환경변수 리네이밍은 S2에서 진행 (`CLAUDE_ATTENTION_*` → `CLAUDE_CORCA_ATTENTION_*`)
- CLAUDE.md / project-context.md 리팩터링은 S2에서 진행

## Success Criteria

- `shellcheck` critical warning 없음 (수정한 스크립트 전부)
- `grep -r 'eval "$(grep' plugins/` 결과 0건
- attention-hook test fixtures 통과 (`plugins/attention-hook/hooks/scripts/attention.test.sh`)

## After Completion

1. S1 세션 디렉토리 생성 (`prompt-logs/{YYMMDD}-{NN}-refactor-critical/`)
2. 해당 디렉토리에 plan.md, lessons.md 작성
3. 해당 디렉토리에 **next-session.md** 작성 (S2 핸드오프)
4. retro 실행
5. commit & push

## Handoff Convention

- master-plan.md는 `prompt-logs/260208-03-cwf-v3-master-plan/`에 단일 원본으로 유지
- 아키텍처 결정 변경 시 원본 직접 수정 (lessons.md에 변경 사유 기록)
- 각 세션은 자기 디렉토리에 next-session.md 생성 → 다음 세션이 이것만 @멘션
- Single source of truth: cwf-state.yaml + master-plan.md + 최신 세션의 next-session.md
