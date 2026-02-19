# Iteration 1 마스터 시나리오

## 목적

퍼블릭 배포 전, "별도 레포의 신규 유저" 기준으로 CWF 설치, 셋업, 스킬 로드, 훅 동작을 실제 재현하고 분기별 결과를 기록한다.

## 진행 규칙

- 각 시나리오는 [project/iter1/scenarios](scenarios) 하위 개별 파일로 기록
- 의도와 다르게 동작하면 해당 경로 즉시 중단 후 증거만 기록
- 앞 경로에서 후행 실패가 명백하면 후속 시나리오는 SKIP 처리 가능
- 문서는 한글 작성

## 공통 환경

- 기준 저장소: [repo-root](../..)
- 시뮬레이션 레포: [project/iter1/sandbox](sandbox)
- 서브에이전트: Codex spawn_agent + claude non-interactive + gemini non-interactive

## 시나리오 목록

| ID | 분류 | 목표 | 실행 방식 | 상태 | 기록 파일 |
|---|---|---|---|---|---|
| I1-S00 | 준비 | 도구/CLI/기준 상태 캡처 | shell | DONE | [project/iter1/scenarios/I1-S00.md](scenarios/I1-S00.md) |
| I1-S01 | 설치 | marketplace 추가 + 플러그인 설치(project scope) | claude plugin | FAIL(BLOCKER) | [project/iter1/scenarios/I1-S01.md](scenarios/I1-S01.md) |
| I1-S02 | 설치 실패 | marketplace 미등록 상태 설치 실패 확인 | claude plugin | SKIP(선행 stronger failure) | [project/iter1/scenarios/I1-S02.md](scenarios/I1-S02.md) |
| I1-S03 | 설치 | 플러그인 설치(local scope) 분기 확인 | claude plugin | FAIL(BLOCKER) | [project/iter1/scenarios/I1-S03.md](scenarios/I1-S03.md) |
| I1-S10 | setup/full | cwf:setup full 경로 | claude print | PARTIAL(deadlock) | [project/iter1/scenarios/I1-S10.md](scenarios/I1-S10.md) |
| I1-S11 | setup/hooks | cwf:setup --hooks 분기 | claude print + 파일검증 | PASS(권한우회 조건) | [project/iter1/scenarios/I1-S11.md](scenarios/I1-S11.md) |
| I1-S12 | setup/tools | 누락 의존성 + Install now | claude print + PATH 조작 | PARTIAL | [project/iter1/scenarios/I1-S12.md](scenarios/I1-S12.md) |
| I1-S13 | setup/tools | 누락 의존성 + Show commands only | claude print + PATH 조작 | PARTIAL | [project/iter1/scenarios/I1-S13.md](scenarios/I1-S13.md) |
| I1-S14 | setup/tools | 누락 의존성 + Skip for now | claude print + PATH 조작 | PARTIAL | [project/iter1/scenarios/I1-S14.md](scenarios/I1-S14.md) |
| I1-S15 | setup/env | cwf:setup --env 분기 | claude print | PASS | [project/iter1/scenarios/I1-S15.md](scenarios/I1-S15.md) |
| I1-S16 | setup/agent-teams | cwf:setup --agent-teams 분기 | claude print | PARTIAL | [project/iter1/scenarios/I1-S16.md](scenarios/I1-S16.md) |
| I1-S17 | setup/git-hooks | git-hooks 모드/프로파일 분기 | claude print + git config | PASS | [project/iter1/scenarios/I1-S17.md](scenarios/I1-S17.md) |
| I1-S18 | setup/repo-index | repo-index targets agents/file/both | claude print | PASS | [project/iter1/scenarios/I1-S18.md](scenarios/I1-S18.md) |
| I1-S19 | setup/cap-index | cap-index 생성 + coverage gate | claude print | FAIL(deadlock) | [project/iter1/scenarios/I1-S19.md](scenarios/I1-S19.md) |
| I1-S20 | setup/codex | full setup codex integration level | script + claude print | PASS | [project/iter1/scenarios/I1-S20.md](scenarios/I1-S20.md) |
| I1-S21 | setup/codex | cwf:setup --codex scope-aware sync | claude print + script | PASS | [project/iter1/scenarios/I1-S21.md](scenarios/I1-S21.md) |
| I1-S22 | setup/codex-wrapper | cwf:setup --codex-wrapper opt-in/decline | script | PASS | [project/iter1/scenarios/I1-S22.md](scenarios/I1-S22.md) |
| I1-H30 | hook/read | read-guard deny/allow | hook script 재현 | PASS | [project/iter1/scenarios/I1-H30.md](scenarios/I1-H30.md) |
| I1-H31 | hook/websearch | websearch redirect deny | hook script 재현 | PASS | [project/iter1/scenarios/I1-H31.md](scenarios/I1-H31.md) |
| I1-H32 | hook/deletion | deletion safety block/allow | hook script 재현 | PASS | [project/iter1/scenarios/I1-H32.md](scenarios/I1-H32.md) |
| I1-H33 | hook/markdown | markdown/link lint gate | hook script 재현 | PASS | [project/iter1/scenarios/I1-H33.md](scenarios/I1-H33.md) |
| I1-H34 | hook/shell | shellcheck 유무 분기 | hook script 재현 | PASS | [project/iter1/scenarios/I1-H34.md](scenarios/I1-H34.md) |
| I1-H35 | hook/workflow | run-closing gate push 차단 | hook script 재현 | PASS | [project/iter1/scenarios/I1-H35.md](scenarios/I1-H35.md) |
| I1-H36 | hook/compact | compact recovery inject/guard | hook script 재현 | PASS | [project/iter1/scenarios/I1-H36.md](scenarios/I1-H36.md) |
| I1-H37 | hook/attention-log | attention/log 스모크 | hook script 재현 | PASS | [project/iter1/scenarios/I1-H37.md](scenarios/I1-H37.md) |
| I1-K40 | skill/load | gather 로드 스모크 | claude print + gemini print | PARTIAL | [project/iter1/scenarios/I1-K40.md](scenarios/I1-K40.md) |
| I1-K41 | skill/load | clarify 로드 스모크 | claude print + gemini print | FAIL(timeout) | [project/iter1/scenarios/I1-K41.md](scenarios/I1-K41.md) |
| I1-K42 | skill/load | plan 로드 스모크 | claude print + gemini print | PASS | [project/iter1/scenarios/I1-K42.md](scenarios/I1-K42.md) |
| I1-K43 | skill/load | review 로드 스모크 | claude print + gemini print | FAIL(timeout) | [project/iter1/scenarios/I1-K43.md](scenarios/I1-K43.md) |
| I1-K44 | skill/load | impl 로드 스모크 | claude print + gemini print | FAIL(timeout) | [project/iter1/scenarios/I1-K44.md](scenarios/I1-K44.md) |
| I1-K45 | skill/load | refactor 로드 스모크 | claude print + gemini print | PASS | [project/iter1/scenarios/I1-K45.md](scenarios/I1-K45.md) |
| I1-K46 | skill/load | retro 로드 스모크 | claude print + gemini print | FAIL(timeout) | [project/iter1/scenarios/I1-K46.md](scenarios/I1-K46.md) |
| I1-K47 | skill/load | handoff 로드 스모크 | claude print + gemini print | FAIL(timeout) | [project/iter1/scenarios/I1-K47.md](scenarios/I1-K47.md) |
| I1-K48 | skill/load | ship 로드 스모크 | claude print + gemini print | PASS | [project/iter1/scenarios/I1-K48.md](scenarios/I1-K48.md) |
| I1-K49 | skill/load | run 트리거 스모크 | claude print + gemini print | FAIL(timeout) | [project/iter1/scenarios/I1-K49.md](scenarios/I1-K49.md) |
| I1-K50 | skill/load | setup/update 스모크 | claude print + gemini print | PASS | [project/iter1/scenarios/I1-K50.md](scenarios/I1-K50.md) |
| I1-K51 | skill/load | hitl 로드 스모크 | claude print + gemini print | FAIL(timeout) | [project/iter1/scenarios/I1-K51.md](scenarios/I1-K51.md) |
| I1-R60 | run/e2e | cwf:run end-to-end | claude print + gemini print | FAIL(timeout) | [project/iter1/scenarios/I1-R60.md](scenarios/I1-R60.md) |

## 선행 실패 기반 스킵 규칙

- 설치 실패(I1-S01, I1-S03) 시 기본 설치 경로는 중단
- 검증 지속 목적일 때만 plugin-dir 우회 경로로 setup/skill/hook 검증 진행
- interactive 질문 단계가 non-interactive에서 deadlock이면 해당 경로 중단 후 스크립트 분해 검증

## 진행 로그

- 2026-02-19: 마스터 시나리오 초안 작성
- 2026-02-19: 설치/셋업 외 cwf:run 시나리오(I1-R60) 추가
- 2026-02-19: Iteration 1 실행 완료(총 38 시나리오)
