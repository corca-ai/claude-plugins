# Retro: install.sh Bash 3 호환성 수정

> Session date: 2026-02-08
> Mode: light

## 1. Context Worth Remembering

- `scripts/install.sh`는 macOS 사용자를 주 타겟으로 하는 플러그인 설치 스크립트
- macOS 기본 bash는 3.2.x (Apple이 GPLv3 라이선스 이후 업데이트를 중단)
- Bash 4+ 전용 기능: `declare -A` (associative array), `${!arr[@]}` (nameref), `|&` (pipe stderr)
- plugin-dev-cheatsheet.md에 `set -u` 빈 배열 가드, `((var++))` exit code 문제 등 bash 주의사항이 있지만, Bash 3/4 호환성 경고는 없었음

## 2. Collaboration Preferences

- 유저가 에러 재현 명령만 간결하게 전달 → "모든 플래그를 테스트하고 수정해주세요"로 범위 명확화
- 간단한 버그 수정이므로 plan mode 없이 바로 진행 — 적절한 판단

### Suggested CLAUDE.md Updates

없음.

## 3. Waste Reduction

- **에러 메시지 미확인**: 유저가 에러 메시지를 붙여넣지 않았고, 에이전트도 먼저 `bash scripts/install.sh --all 2>&1`을 실행해서 에러를 재현하는 대신 스크립트를 읽고 `declare -A`를 발견하여 수정했다. 이 경우 원인이 명확했기에 결과적으로 낭비는 없었지만, 일반적으로는 에러 재현을 먼저 하는 것이 더 안전하다.
- **테스트 harness 한 번 실패**: 복합 플래그 테스트에서 `bash -c '...' -- $flags` 형태로 공백이 포함된 플래그 문자열을 전달했을 때, 단일 인자로 합쳐져서 FAIL이 발생했다. 이후 각 플래그를 개별 인자로 직접 전달하여 해결. 테스트 harness 자체의 quoting 문제를 먼저 확인했어야 했다.
- **낭비 수준**: 전체적으로 적음. 짧은 세션에 핵심 수정 1건 + 종합 테스트까지 완료.

## 4. Critical Decision Analysis (CDM)

### CDM 1: associative array → 일반 배열 + 선형 검색 교체

| Probe | Analysis |
|-------|----------|
| **Cues** | macOS bash 3.2에서 `declare -A`는 "invalid option" 에러 발생. `bash --version`으로 3.2.57 확인 |
| **Goals** | Bash 3 호환성 확보 vs. 코드 가독성/성능 유지 |
| **Options** | (1) 일반 배열 + 선형 검색, (2) `#!/usr/bin/env bash`를 Homebrew bash 4로 교체, (3) grep/임시파일 기반 중복 체크, (4) 중복 방지 로직 제거 |
| **Basis** | 옵션 1 선택 — 외부 의존성 없이 Bash 3에서 동작, 플러그인 수가 10개 미만이라 O(n²) 성능 문제 없음. Homebrew bash 의존은 설치 스크립트의 목적에 반함 |
| **Experience** | 경험 많은 shell 스크립터라면 처음부터 associative array를 피했을 것. macOS 타겟 스크립트에서 Bash 4 기능은 레드플래그 |
| **Aiding** | cheatsheet에 "Bash 3 호환성: `declare -A`, nameref, `|&` 사용 금지" 항목 추가하면 재발 방지 가능 |

**Key lesson**: macOS 타겟 bash 스크립트를 작성할 때는 Bash 3.2 호환성을 기본 가정으로 해야 한다. `declare -A`, `${!var}` (nameref), `|&` 등 Bash 4+ 기능은 사용하지 않는다.

### CDM 2: 빈 배열 순회 시 `"${to_install[@]+"${to_install[@]}"}"` 패턴 사용

| Probe | Analysis |
|-------|----------|
| **Cues** | `set -u` 환경에서 빈 배열 `"${arr[@]}"` 확장 시 "unbound variable" 에러 발생 가능 |
| **Goals** | `set -euo pipefail`과의 호환성 유지 |
| **Options** | (1) `${arr[@]+"${arr[@]}"}` (parameter expansion fallback), (2) `if [[ ${#arr[@]} -gt 0 ]]` 선행 체크, (3) `set -u` 제거 |
| **Basis** | 옵션 1이 가장 관용적이고 cheatsheet에도 이미 기록된 패턴. `add_plugins` 내부 반복문에서 매번 길이 체크하는 것보다 간결 |

**Key lesson**: cheatsheet의 "Empty array iteration under `set -u`" 패턴이 실전에서 정확히 적용되었다. 기존 가이드가 유효함을 확인.

## 5. Expert Lens

> Run `/retro --deep` for expert analysis.

## 6. Learning Resources

> Run `/retro --deep` for learning resources.

## 7. Relevant Skills

### Installed Skills

| 스킬 | 관련성 |
|------|--------|
| **refactor** (`/refactor`) | `--code` 모드로 install.sh 수정 커밋을 리뷰할 수 있었으나, 변경이 단순해서 불필요 |
| **plugin-deploy** (local) | install.sh는 플러그인이 아니라 인프라 스크립트이므로 해당 없음 |
| **gather-context** | 세션 중 외부 정보 검색 필요 없었음 |

이 세션에서 설치된 스킬 중 활용 여지가 있었던 것은 없음. 단순 버그 수정 세션.

### Skill Gaps

추가 스킬 갭 없음.
