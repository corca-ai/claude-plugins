# Retro: docs-criteria 강화 + deprecated 디렉토리 삭제

> Session date: 2026-02-07

## 1. Context Worth Remembering

- 이전 세션(260207-01)에서 plan.md와 lessons.md가 이미 작성됨. 이 세션은 plan 실행만 담당.
- CodeRabbit PR 리뷰 기반 수정(260207-03-coderabbit-fixes)이 이 세션 실행 사이에 원격에 병합됨 — refactor 1.0.0 → 1.0.1 patch bump, markdownlint 도입 등.
- wiki.g15e.com에 문서 설계 품질 기준이 정리되어 있으며 refactor --docs 모드에 통합 가능.
- deprecated 플러그인 4개(suggest-tidyings, deep-clarify, interview, web-search)는 v2.0.0 마켓플레이스 정리 시 이미 마켓플레이스에서 삭제되었으나, 소스 디렉토리는 "참조용"으로 남겨두었었음. 이번에 최종 삭제.

## 2. Collaboration Preferences

- 유저가 이전 세션에서 설계한 plan을 그대로 전달하며 "Implement the following plan"으로 실행을 위임. 이런 plan → implement 분리 패턴이 잘 작동함.
- 커밋 시 "main이 변경되었으니 감안해서" 같은 짧은 지시로 충분. pull → conflict resolution까지 자율적으로 기대.
- `/plugin-deploy`와 `/retro` 같은 후속 워크플로우를 유저가 명시적으로 요청하지 않아도 CLAUDE.md 프로토콜에 따라 자동 실행하는 것을 선호.

### Suggested CLAUDE.md Updates

- `update-all.sh` 실행 후 실패한 deprecated 플러그인을 `claude plugin uninstall`로 정리하는 단계를 워크플로우에 추가하는 것을 고려. 단, deprecated 플러그인 삭제는 일회성 이벤트이므로 CLAUDE.md에 영구적으로 추가할 필요는 없음. 제안 없음.

## 3. Waste Reduction

### 정확한 계획 대비 실행 중 발견된 추가 작업

계획에서 8개 파일 수정을 나열했으나, 실행 후 grep 검증에서 추가 4개 파일(gather-context 스크립트 3개, protocol.md 1개)이 발견됨. AI_NATIVE_PRODUCT_TEAM의 web-search, interview 링크도 계획에 명시되지 않았으나 실행 중 발견하여 수정.

**개선 방안**: plan 단계에서 `grep -r "deprecated-name" plugins/` 전수 검사를 포함하면 계획 시점에 완전한 파일 목록을 확보할 수 있음. 현재는 plan → implement 분리로 plan 단계에서 grep을 못 돌렸을 가능성도 있음.

### Stash 충돌 해결

`git stash && git pull && git stash pop`에서 10개 충돌 발생. modify/delete 충돌 8개(deprecated 삭제 vs upstream 수정)와 content 충돌 2개(plugin.json version, project-context.md). 모두 예측 가능한 충돌이었으나, stash pop 방식이 conflict 수를 늘림.

**대안**: `git stash`를 사용하기보다, 변경 사항을 먼저 commit한 후 `git pull --rebase`로 처리하면 충돌이 더 깔끔하게 정리됨. 또는 변경 전에 먼저 pull을 완료하는 습관.

## 4. Critical Decision Analysis (CDM)

### CDM 1: refactor 버전을 1.1.0으로 유지 (upstream 1.0.1과 충돌)

| Probe | Analysis |
|-------|----------|
| **Cues** | upstream에서 CodeRabbit 수정으로 1.0.1 patch bump가 들어온 상태. 우리는 새 기능(Section 5) 추가로 1.1.0 minor bump 필요. |
| **Goals** | semver 준수 (새 기능 = minor) vs upstream 변경 반영 |
| **Options** | (1) 1.1.0 유지 (upstream 1.0.1 위에 minor bump), (2) 1.1.1 (patch on top of 1.0.1), (3) 1.2.0 (arbitrary) |
| **Basis** | 새 기능 추가는 minor bump가 맞음. 1.0.1이 이미 병합된 상태에서 1.1.0은 semver 상 올바른 진행. 1.0.1 → 1.1.0은 patch 변경사항도 포함한다는 의미. |
| **Hypothesis** | 1.1.1로 했다면 "minor 변경을 patch로 표기"하는 semver 위반이 됨. |

**Key lesson**: upstream에서 patch bump가 먼저 병합되었더라도 새 기능 추가 시 minor bump로 가는 것이 semver 원칙에 맞음. patch → minor는 자연스러운 진행.

### CDM 2: retro의 deep-clarify 참조를 유지하기로 결정

| Probe | Analysis |
|-------|----------|
| **Cues** | `grep -r "deep-clarify" plugins/` 결과에서 retro 내 5개 참조 발견. 삭제 대상인가? |
| **Knowledge** | retro의 expert-lens 기능은 대화 히스토리에서 `/deep-clarify` 호출 패턴을 스캔하여 전문가 이름을 추출함. 디렉토리 경로가 아닌 대화 내용 매칭. |
| **Options** | (1) 모든 참조 삭제 — 일관성 확보, (2) 유지 — 기능적으로 유효한 참조 보존 |
| **Basis** | deep-clarify를 과거에 사용한 세션에서 retro를 돌릴 때 전문가 선택이 깨지지 않아야 함. 디렉토리 참조와 대화 내용 참조는 성격이 다름. |
| **Situation Assessment** | 참조의 성격을 정확히 구분함 — "이 이름이 코드에서 쓰이는 방식"을 파악한 후 판단. |

**Key lesson**: deprecated 이름을 일괄 삭제하기 전에, 각 참조가 "디렉토리/파일 경로"인지 "대화 내용/패턴 매칭"인지 구분해야 함. 후자는 제거하면 기능이 깨짐.

### CDM 3: stash pop 충돌 시 삭제 의도 관철

| Probe | Analysis |
|-------|----------|
| **Cues** | `git stash pop` 후 8개 modify/delete 충돌. upstream에서 deprecated 파일을 수정(CodeRabbit 마크다운 린트 수정)했고, 우리는 삭제. |
| **Goals** | deprecated 디렉토리 완전 삭제 vs upstream 수정 반영 |
| **Options** | (1) `git rm`으로 삭제 관철, (2) upstream 수정 수용 후 별도 커밋에서 삭제 |
| **Basis** | 파일 자체가 삭제 대상이므로 upstream의 린트 수정을 수용할 이유가 없음. `git rm`이 가장 깔끔. |
| **Aiding** | `git status`의 "Unmerged paths" 섹션에서 "deleted by them" 패턴을 보고 `git rm`으로 일괄 해결 가능하다는 것을 파악. |

**Key lesson**: modify/delete 충돌에서 삭제 의도가 명확하면 `git rm`으로 즉시 해결. upstream 수정의 내용이 무엇이든 삭제될 파일이므로 리뷰 불필요.

## 5. Expert Lens

이 세션은 사전 설계된 plan의 직접 실행 + 충돌 해결로, 도메인 전문가 분석이 추가 가치를 제공하기 어려운 경량 세션. 생략.

## 6. Learning Resources

plan 실행 + git 충돌 해결 중심의 루틴 세션으로, 새로운 지식 격차나 호기심 신호가 없음. 생략.

## 7. Relevant Skills

스킬 격차 없음. `update-all.sh` 실행 후 삭제된 플러그인의 로컬 설치분을 자동 uninstall하는 기능은 `update-all.sh` 스크립트 자체에 넣는 것이 적절 (별도 스킬 불필요).
