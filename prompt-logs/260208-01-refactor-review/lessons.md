# Lessons — 260208-01 Refactor Review

## Agent Team 운영

- 3개 에이전트 병렬 실행이 효과적 — 코드/문서/리서치 관점 분리로 각각 집중도 높음
- research-agent가 가장 먼저 완료 (범위가 명확), refactor-agent가 가장 오래 걸림 (24개 스크립트 + 9개 플러그인 전체 읽기)
- 에이전트에게 TaskUpdate로 결과를 task description에 기록하게 하면 결과 취합이 편함

## 코드베이스 인사이트

- **JSON 문자열 구성**: bash에서 JSON을 문자열 연결로 만드는 패턴이 여러 스크립트에 반복 → escaping 버그의 근본 원인. jq로 마이그레이션이 근본적 해결책
- **convention drift**: 초기 플러그인(attention-hook, smart-read)과 최근 플러그인(markdown-guard, prompt-logger) 사이에 shebang, set -euo pipefail 등 컨벤션 차이가 큼
- **bare code fence**: markdown-guard가 신규 위반은 막지만, 기존 파일 ~25개에 누적 부채가 있음. 일괄 정리 필요
- **JS/TS 전용 도구들**: dependency-cruiser, knip 등은 이 레포에 부적합 — bash/md/json 중심 레포에는 shellcheck + jq가 최적

## Agent Team + Skill 제약

- **스킬은 session-level, agent는 process-level**: Task tool로 생성한 sub-agent는 플러그인 스킬 정의를 상속받지 못함. `/refactor`, `/gather-context` 등 스킬 호출이 필요한 작업은 메인 세션에서 직접 실행해야 함
- 스킬 기준을 agent에 간접 적용하려면, 해당 스킬의 reference docs(review-criteria.md 등)를 agent 프롬프트에 포함시켜야 함
- agent team 결과물의 critical 이슈는 반드시 실제 코드에서 spot-check 필요 — 라인 번호가 틀리거나 코드 해석이 부정확할 수 있음

## 도구 리서치

- shellcheck가 최우선 도입 대상 — 24개 스크립트에서 실제 버그(unquoted variables, unsafe eval 등)를 잡을 수 있음
- shell-guard를 markdown-guard와 별도 플러그인으로 만드는 것이 기존 사용자 영향 없이 안전
- jscpd는 레포 규모(3.4K lines)에서는 false positive가 너무 많아 실용성 낮음

## Retro 스킬 개선

- Waste Reduction이 현상 나열에 그치면 persist할 구조적 교훈을 놓침 → 5 Whys root cause drill-down 추가
- CDM 대상 선정에서 "의도와 결과가 괴리된 순간(intent-result gaps)"을 놓치기 쉬움 → cdm-guide.md에 명시적 추가
- Persist 단계에서 root cause의 미래 job을 묻는 JTBD 필터링 추가 → "이 교훈이 방지할 미래 상황은?" 질문으로 persist 위치 결정
