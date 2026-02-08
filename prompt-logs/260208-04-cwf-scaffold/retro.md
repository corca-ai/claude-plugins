# Retro: S4 — CWF Scaffold

> Session date: 2026-02-08
> Mode: light

## 1. Context Worth Remembering

- CWF v3 마이그레이션은 세션 단위로 점진적 진행 (S1-S2 리팩토링, S3 /ship 스킬, S4 스캐폴드)
- cwf 플러그인은 기존 7개 훅 플러그인을 하나로 통합하는 구조 — 훅 그룹별 게이트 메커니즘으로 개별 on/off 지원
- `cwf-hook-gate.sh`는 sourced 스크립트로 설계 — `exit 0`이 호출 스크립트를 종료시킴 (의도된 동작)
- hooks.json에서 하나의 matcher에 여러 hook command를 배열로 넣을 수 있음 (EnterPlanMode: attention + plan-protocol)
- Bash 3.2 호환성을 위해 `printenv`로 동적 변수 조회 (nameref `${!var}` 불가)

## 2. Collaboration Preferences

- 상세한 플랜이 주어지면 별도 확인 질문 없이 바로 구현 → 효율적
- 플랜의 검증 단계(5개 체크)를 모두 자동화해서 수행 — 이 패턴 유지
- `/ship issue` → 커밋 → `/ship pr` → `/retro` 순서가 자연스러운 워크플로우로 정착

### Suggested CLAUDE.md Updates

없음 — 현재 CLAUDE.md가 이 세션의 워크플로우를 이미 잘 반영하고 있음.

## 3. Waste Reduction

효율적인 세션이었음. 주요 관찰:

- **Explore 에이전트 사용**: agent-patterns.md 내용을 찾기 위해 Explore 에이전트를 사용한 것은 적절. master-plan.md의 위치를 직접 알 수 없었으므로 탐색이 필요했음.
- **병렬 파일 쓰기**: 13개 파일을 한 번에 병렬로 Write — 컨텍스트 효율적.
- **Exit code 출력 이슈**: 게이트 비활성화 테스트에서 `exit 0`이 파이프라인 전체를 종료시켜 exit code가 출력되지 않는 현상을 추가 확인함. 한 턴의 낭비이나, 소싱 동작을 검증한 것이므로 가치 있는 확인.

**Root cause**: exit code 테스트 패턴에서 sourced `exit`의 동작을 사전에 고려하지 않음 → 프로세스 갭이 아닌 일회성 실수. sourced 스크립트의 exit 전파 특성은 lessons.md에 이미 기록됨.

## 4. Critical Decision Analysis (CDM)

### CDM 1: 스캐폴드 플랜을 그대로 구현 vs 수정 제안

| Probe | Analysis |
|-------|----------|
| **Cues** | 사용자가 S4 플랜 전문을 전달. 16개 파일, 디렉토리 구조, 검증 단계까지 상세히 명시 |
| **Goals** | 빠른 구현 vs 플랜 검증. 상세 플랜이 이미 마스터 플랜에서 도출되었으므로 추가 검증보다 실행 우선 |
| **Options** | (A) 플랜대로 구현, (B) 기존 코드와 차이점 확인 후 수정 제안, (C) EnterPlanMode로 재검토 |
| **Basis** | 플랜이 기존 hooks.json/스크립트 패턴을 정확히 반영하고 있었음 — 실제 코드를 읽어 확인 후 그대로 진행 |
| **Experience** | 경험이 적은 에이전트는 플랜을 읽지 않고 바로 구현하거나, 반대로 불필요한 재설계를 시도할 수 있음. 기존 코드를 먼저 읽고 플랜과 비교한 것이 적절 |
| **Tools** | 6개 기존 hooks.json + 4개 기존 스크립트를 병렬로 Read — 패턴 확인에 효과적 |

**Key lesson**: 상세 플랜이 있어도 기존 코드 패턴을 먼저 읽어 플랜의 정합성을 검증하는 것이 안전. 플랜 오류를 구현 후에 발견하면 비용이 큼.

### CDM 2: cwf-hook-gate.sh의 sourced 설계 선택

| Probe | Analysis |
|-------|----------|
| **Cues** | 플랜에서 "sourced (not executed)" 명시. 게이트가 호출 스크립트를 직접 종료시키려면 source가 필수 |
| **Goals** | (1) 비활성 훅의 빠른 종료, (2) 최소 보일러플레이트, (3) Bash 3.2 호환 |
| **Options** | (A) source + exit, (B) 함수 호출 + return 체크, (C) wrapper 스크립트 |
| **Basis** | source + exit이 가장 간결. 각 stub은 2줄(HOOK_GROUP + source)로 게이트 적용 완료. return 체크는 매 스크립트에 if문 추가 필요 |
| **Analogues** | 기존 `slack-send.sh`가 sourced 패턴 사용 중 (cheatsheet에서도 sourced 스크립트 가이드라인 명시) |
| **Aiding** | cheatsheet의 "Sourced scripts: do NOT add `set -euo pipefail`" 가이드라인이 정확히 적용됨 |

**Key lesson**: sourced 게이트 패턴은 보일러플레이트를 최소화하지만, `exit`의 전파 특성을 모든 호출자가 이해해야 함. 게이트 스크립트 상단의 주석에 이 동작을 명시한 것이 중요.

## 5. Expert Lens

> Run `/retro --deep` for expert analysis.

## 6. Learning Resources

> Run `/retro --deep` for learning resources.

## 7. Relevant Skills

### Installed Skills

| 스킬 | 활용 여부 | 분석 |
|------|----------|------|
| `/ship` (local) | 사용함 | issue 생성 + PR 생성에 활용. 워크플로우 자동화 효과적 |
| `/plugin-deploy` (local) | 미사용 | S4는 scaffold이고 marketplace 등록은 S14로 deferred — 미사용 적절 |
| `/retro` (marketplace) | 사용함 | 현재 실행 중 |
| `/refactor` (marketplace) | 미사용 | scaffold 단계에서는 리뷰할 기존 코드가 없으므로 적절 |
| `/clarify` (marketplace) | 미사용 | 플랜이 이미 상세했으므로 clarify 불필요 |
| `/gather-context` (marketplace) | 미사용 | 기존 코드 패턴 확인은 직접 Read로 충분 |

### Skill Gaps

이 세션에서 발견된 워크플로우 갭 없음. `/ship`이 issue → PR 사이클을 잘 처리함.
