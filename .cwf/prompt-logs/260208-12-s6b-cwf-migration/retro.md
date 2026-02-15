# Retro: S6b CWF 마이그레이션

> Session date: 2026-02-08
> Mode: light

## 1. Context Worth Remembering

- CWF(Corca Workflow Framework)는 기존 분산된 hook 플러그인들을 단일 플러그인으로 통합하는 프로젝트. S6a(인프라 hooks 3개) 후 S6b(attention hook 5개 + 유틸리티 2개 + enter-plan-mode + check-shell.sh 신규)로 진행.
- attention-hook 시스템은 sourced utility(`slack-send.sh`) + subprocess utility(`parse-transcript.sh`) + 5개 실행 스크립트로 구성. `BASH_SOURCE` guard 패턴은 테스트용이었으나 CWF에서는 불필요.
- 사전에 잘 정리된 플랜이 있으면 마이그레이션은 거의 기계적 작업이 됨. 플랜의 파일 인벤토리, 마이그레이션 패턴, 검증 절차가 구체적이어서 구현 중 의사결정이 거의 없었음.

## 2. Collaboration Preferences

- 유저가 상세한 플랜을 제공하면 별도 확인 없이 바로 실행을 기대함. 이 세션에서 질문 없이 전체 구현이 완료됨.
- 플랜에 명시된 검증 절차(diff 검증, functional test, gate test)를 전부 수행하는 것을 기대함.

### Suggested CLAUDE.md Updates

없음 — 현재 CLAUDE.md가 이 워크플로우를 잘 반영하고 있음.

## 3. Waste Reduction

이 세션은 낭비가 거의 없었음. 플랜이 구체적이어서 구현이 일직선으로 진행됨.

**한 가지 개선점**: `track-user-input.sh`의 `[ -z "$CWD" ] && CWD="$PWD"` 패턴을 `if/then`으로 변경했는데, 이는 원본 소스에 있던 패턴임. 원본 attention-hook에도 같은 문제가 존재하므로 향후 원본 deprecation 전에 수정하거나, CWF 마이그레이션 완료 후 원본은 그대로 두고 CWF만 개선된 코드를 유지하는 방침을 결정할 필요가 있음.

**5 Whys**: 왜 원본에 안전하지 않은 패턴이 있었나? → 초기 개발 시 cheatsheet `&&` chain 가이드라인이 없었음 → 가이드라인 추가 후 기존 코드 전수 검사를 하지 않았음 → **프로세스 갭**: 가이드라인 추가 시 기존 코드 감사를 함께 수행하는 체크리스트가 없음. 향후 `/refactor --code` 로 한 번 정리하면 해결됨.

## 4. Critical Decision Analysis (CDM)

### CDM 1: attention.sh의 BASH_SOURCE guard 제거

| Probe | Analysis |
|-------|----------|
| **Cues** | 플랜에서 "CWF scripts are only executed, never sourced for testing"이라고 명시 |
| **Knowledge** | attention.test.sh가 원본에 존재하며, 이 guard는 테스트 sourcing을 위한 것이었음 |
| **Goals** | CWF 통합 단순화 vs 테스트 가능성 유지 |
| **Options** | (1) guard 유지 + 들여쓰기 그대로, (2) guard 제거 + 평탄화, (3) guard 제거 + 별도 테스트 구조 도입 |
| **Basis** | CWF 내에서 attention.test.sh를 사용하지 않을 것이므로 guard 불필요. 코드 가독성 개선. |
| **Hypothesis** | guard를 유지했다면 불필요한 들여쓰기로 가독성 저하 + CWF 패턴 불일치 |

**핵심 교훈**: 마이그레이션 시 원본의 테스트 인프라까지 그대로 옮길 필요 없음. 대상 환경의 테스트 전략에 맞게 단순화하는 것이 올바름.

### CDM 2: check-shell.sh를 check-markdown.sh 패턴으로 구현

| Probe | Analysis |
|-------|----------|
| **Cues** | 기존 check-markdown.sh가 PostToolUse 블로킹 hook의 검증된 패턴을 제공 |
| **Knowledge** | shellcheck -f gcc가 기계 파싱 가능한 출력을 제공 |
| **Goals** | 일관된 lint hook 패턴 유지 vs 최적의 shellcheck 활용 |
| **Options** | (1) check-markdown.sh 패턴 그대로 복제, (2) shellcheck 특화 기능(severity 필터링 등) 추가 |
| **Basis** | 최소 구현 우선. 필요할 때 확장 가능. over-engineering 방지. |
| **Aiding** | check-markdown.sh를 템플릿으로 사용한 것이 구현 속도와 일관성 모두 확보 |

**핵심 교훈**: 동일 카테고리의 hook은 기존 패턴을 템플릿으로 복제하면 일관성과 속도를 동시에 확보할 수 있음. "Convention over configuration" 원칙.

## 5. Expert Lens

> `/retro --deep`으로 전문가 분석 실행 가능.

## 6. Learning Resources

> `/retro --deep`으로 학습 리소스 추천 가능.

## 7. Relevant Skills

### Installed Skills

- **`/plugin-deploy`**: 이 세션 후 plugin.json 버전 범프, marketplace.json 동기화, README 업데이트에 사용해야 함. CLAUDE.md 워크플로우 step 4에 해당.
- **`/refactor --code`**: Waste Reduction에서 언급한 `&&` chain 패턴 정리에 사용 가능. 원본 attention-hook과 CWF 코드 모두 대상.

### Skill Gaps

추가적인 스킬 갭 없음. 마이그레이션 워크플로우는 기존 스킬 세트로 충분히 커버됨.
