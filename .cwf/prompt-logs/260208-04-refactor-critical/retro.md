# Retro: Refactor Critical Fixes (S1)

> Session date: 2026-02-08
> Mode: light

## 1. Context Worth Remembering

- 유저는 CWF v3 마스터 플랜을 세션 단위로 실행 중. S0(플랜), S1(리팩터)까지 완료.
- 플랜이 이미 상세하게 짜여 있을 때, 유저는 "그대로 구현"을 기대함. 플랜 외 변경은 최소화하되 발견한 이슈는 lessons.md에 기록 후 보고.
- 유저는 세션 사이에 비동기로 아이디어를 정리하는 습관이 있음 ("샤워하면서 생각" 패턴). 구현 완료 후 논의 요청으로 전달됨.
- `jq -Rs .` + `printf '%s'` 조합이 이 프로젝트의 JSON 안전 인코딩 표준 패턴으로 확립됨.
- `_safe_load()` 함수가 prompt-logger에서 도입됨 — 여러 변수를 동일한 eval-free 패턴으로 로드할 때 반복을 줄이는 헬퍼. 다른 플러그인에서도 재사용 가능.

## 2. Collaboration Preferences

- 유저는 사전 설계된 플랜이 있을 때 별도 plan mode 진입 없이 바로 구현을 시작하는 것을 선호함. 이번 세션에서 플랜을 그대로 수용하고 즉시 실행에 들어간 방식이 좋았음.
- 유저는 구현 완료 후 논의를 분리하는 순서를 선호: "commit & push 먼저, 마스터 플랜 논의는 그 다음에".
- 마스터 플랜 논의에서 3가지 포인트 각각에 대해 반론/절충안을 제시한 것이 유용했음. 1번(Gemini)은 절충안 채택, 2번(ship skill)은 순서 조정, 3번(repo-level skill)은 즉시 동의.

### Suggested CLAUDE.md Updates

- 없음. 현재 CLAUDE.md의 "When executing a pre-designed plan" 규칙과 "In design discussions, provide honest counterarguments" 규칙이 이 세션에서 잘 적용됨.

## 3. Waste Reduction

**전반적으로 효율적인 세션.** 6-phase 24파일 수정을 단일 세션에서 완료. 주요 낭비 지점:

### `echo` vs `printf` 재작업

`jq -Rs .`로 JSON 안전 인코딩을 적용한 후 quick-scan.sh 테스트에서 trailing newline 발견. `echo "$var" | jq -Rs .` → `printf '%s' "$var" | jq -Rs .`로 재수정 필요.

- **Why**: `echo`가 자동으로 `\n`을 추가한다는 사실을 간과
- **Why**: `jq -Rs`가 raw string 전체를 읽어들이므로 trailing newline도 포함
- **Why**: 플랜에는 `jq -Rs .` 사용만 명시, pipe 입력 방식은 미지정
- **Root cause**: `jq -Rs .`를 처음 도입하는 패턴이었고, echo의 trailing newline 동작이 jq raw-slurp와 상호작용하는 방식에 대한 사전 지식이 없었음
- **분류**: Knowledge gap → lessons.md에 기록 완료. 향후 동일 패턴 적용 시 반복 방지됨.

### shellcheck 미설치

검증 단계에서 shellcheck를 실행하려 했으나 시스템에 미설치 + sudo 권한 없음. 계획에 shellcheck 검증이 포함되어 있었지만 실행 불가.

- **Why**: 개발 환경에 shellcheck가 기본 설치되어 있지 않음
- **Root cause**: 일회성 환경 제약. S3(ship skill) 이후 CI 파이프라인이나 hook으로 자동화할 수 있는 영역.
- **분류**: Structural constraint — cwf v3의 `check-shell.sh` hook(S6b)이 이 gap을 메꿀 예정.

## 4. Critical Decision Analysis (CDM)

### CDM 1: attention.sh에 `set -euo pipefail` 위치 결정

| Probe | Analysis |
|-------|----------|
| **Cues** | attention.sh는 `if [[ "${BASH_SOURCE[0]}" == "${0}" ]]` 가드로 sourced/direct 실행을 분리. test 파일이 `source attention.sh`로 함수를 가져옴. |
| **Goals** | strict mode 적용 vs 테스트 호환성 유지 |
| **Options** | (A) 파일 상단에 `set -euo pipefail` 추가, (B) `BASH_SOURCE` 가드 안에 추가, (C) strict mode 제외 (slack-send.sh처럼) |
| **Basis** | (A)는 테스트가 source할 때 strict mode가 전파되어 기존 테스트를 깨뜨릴 수 있음. (C)는 200줄 복잡 스크립트에서 안전성 포기. (B)가 두 목표를 모두 만족. |
| **Hypothesis** | (A) 선택 시 attention.test.sh에서 unbound variable 에러 발생 가능 (특히 `$SLACK_BOT_TOKEN` 미설정 시). |
| **Aiding** | "sourced script에서는 BASH_SOURCE 가드 안에 strict mode" 패턴을 cheatsheet에 추가하면 향후 유사 상황에서 즉시 판단 가능. |

**Key lesson**: Script가 source와 direct execution 양쪽으로 쓰이면, strict mode는 실행 경로 안에만 넣어야 한다. 이 패턴을 plugin-dev-cheatsheet.md에 문서화할 가치가 있음.

### CDM 2: gather-context 스크립트 shebang 변경 (플랜 범위 초과)

| Probe | Analysis |
|-------|----------|
| **Cues** | Phase 1에서 search.sh, extract.sh, code-search.sh의 eval 패턴을 수정하면서 `#!/bin/bash` shebang을 발견. 플랜의 Phase 4 목록에는 이 3개 파일이 없었음 (hooks/scripts/ 대상만). |
| **Goals** | 플랜 범위 준수 vs 이미 수정 중인 파일의 일관성 |
| **Options** | (A) 플랜대로 shebang 변경 안 함, (B) 이미 터치한 파일이니 함께 변경 |
| **Basis** | 파일을 이미 수정 중이고, 같은 커밋에 포함되므로 추가 비용 최소. 검증 기준(`grep -r '#!/bin/bash' plugins/*/hooks/scripts/`)은 hooks만 검사하므로 skills 하위는 별도 기준이 필요하지만, 일관성이 더 중요. |
| **Experience** | 더 신중한 접근이라면 유저에게 먼저 확인했을 것. 그러나 이 경우 리스크가 극히 낮고 (shebang 변경은 동작에 영향 없음) 유저가 이미 관련 컨벤션을 승인한 상태. |

**Key lesson**: 플랜 범위를 초과하는 변경은 리스크가 낮고 이미 터치 중인 파일이면 함께 처리해도 되지만, lessons.md에 기록하여 추적 가능성을 유지해야 한다.

### CDM 3: 마스터 플랜에 `/ship` 삽입 위치

| Probe | Analysis |
|-------|----------|
| **Cues** | 유저가 "v3의 첫번째로" 명시. ship skill은 이후 v3 세션의 워크플로우를 자동화하는 도구이므로, 가능한 한 먼저 만들어야 활용도가 높음. |
| **Goals** | (1) v3 워크플로우 자동화 극대화, (2) 기존 플랜 구조 유지, (3) S2는 main 브랜치에서 ship 없이 진행 |
| **Options** | (A) S2 이전에 삽입 (main 브랜치), (B) S3으로 삽입 (v3 첫 세션), (C) S4 scaffold와 병합 |
| **Basis** | (B) 채택. ship은 umbrella 브랜치에서 gh issue/PR 워크플로우를 관리하므로 main이 아닌 marketplace-v3에서 시작하는 것이 맞음. scaffold(S4)와 병합하면 한 세션이 너무 커짐. |
| **Aiding** | 세션 번호 재배정이 15세션으로 확대됨 — dependency graph와 next-session.md 체인 모두 업데이트 필요. |

**Key lesson**: 워크플로우 자동화 도구는 그 도구를 사용할 세션들보다 먼저 만들어야 한다. "도구 먼저, 산출물 나중에" 원칙.

## 5. Expert Lens

> `/retro --deep`을 실행하면 전문가 분석을 볼 수 있습니다.

## 6. Learning Resources

> `/retro --deep`을 실행하면 학습 리소스를 볼 수 있습니다.

## 7. Relevant Skills

### Installed Skills

| Skill | 관련성 |
|-------|--------|
| `/refactor` | quick-scan.sh를 직접 수정함. 다음 세션(S2)에서 `--docs` 모드 추가 예정. |
| `/plugin-deploy` | 6개 플러그인 버전 범프를 수동으로 했지만, check-consistency.sh도 함께 수정함. 다음부터 `/plugin-deploy`로 자동화 가능. |
| `/retro` | 현재 사용 중. |
| `/gather-context` | 3개 스크립트 수정 대상이었음. 직접 관련. |
| `/clarify` | 사용하지 않았지만, 마스터 플랜 논의 시 3가지 포인트를 `/clarify`로 체계적으로 정리했으면 더 구조화됐을 수 있음. 그러나 이번 논의는 짧고 명확했으므로 오버킬. |

### Skill Gaps

- **shellcheck 자동 실행**: 현재 시스템에 shellcheck 미설치. cwf v3의 `check-shell.sh` hook(S6b)이 이 gap을 메꿀 예정이므로 별도 스킬 불필요.
- **버전 범프 자동화**: 6개 plugin.json을 수동 편집함. `/plugin-deploy`가 있지만, 이번 세션처럼 다수 플러그인을 일괄 범프할 때는 batch 모드가 있으면 편리할 것. S2 이후 평가.

이 세션은 마스터 플랜 아키텍처 결정(ship skill 삽입, repo-level 개발 방식, Gemini 테스트 전략)이 포함되어 있습니다. `/retro --deep`을 실행하면 전문가 분석과 학습 리소스를 추가로 볼 수 있습니다.
