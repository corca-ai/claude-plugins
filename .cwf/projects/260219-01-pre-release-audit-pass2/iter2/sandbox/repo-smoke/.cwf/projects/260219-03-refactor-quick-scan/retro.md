# Retro: Sandbox Repo Smoke Test

> Session date: 2026-02-19

- Mode: light

## 1. Context Worth Remembering

- **Sandbox 환경**: `iter2/sandbox/repo-smoke`는 CWF 파이프라인(plan→impl→review→retro)의 end-to-end smoke test를 위한 격리된 git repo. 기존 README.md 외에 `hello.txt` 추가가 유일한 실질 변경.
- **CWF v0.8.0 설치 검증 중**: 별도 sandbox(`repo-install`)에서 설치가 진행되고, 이 repo에서는 pipeline 흐름 검증이 목표.
- **cwf-state.yaml 부재 이슈**: sandbox repo 초기 상태에 `cwf-state.yaml`이 없어 live-state 스크립트가 실패 → 수동 생성으로 해결 (이미 lessons.md에 기록됨).
- **프로젝트 디렉토리 3개 생성**: `260219-01-minimal-smoke-plan` (실질 작업), `260219-02-refactor-quick-scan`, `260219-03-refactor-quick-scan` (bootstrap만 된 빈 프로젝트).

## 2. Collaboration Preferences

- 사용자가 sandbox 환경에서 CWF 스킬들을 빠르게 순차 호출하는 패턴. plan→impl→refactor→retro 순서로 파이프라인 검증 진행.
- 최소 단위(hello.txt 1개 파일) 작업으로 파이프라인 자체의 동작을 확인하는 접근 — 기능 복잡도보다 pipeline 정상 흐름이 관심사.

### Suggested Agent-Guide Updates

- (해당 없음 — sandbox smoke test 세션이라 일반화할 collaboration 패턴 없음)

## 3. Waste Reduction

### 빈 프로젝트 디렉토리 2개 생성

`260219-02-refactor-quick-scan`과 `260219-03-refactor-quick-scan`이 bootstrap 템플릿 상태로 남아 있음. `next-prompt-dir --bootstrap`이 호출되었으나 실제 plan 내용이 채워지지 않음.

**5 Whys**:
1. 왜 빈 디렉토리가 생겼나? → refactor quick-scan을 시도하다 두 번 bootstrap함.
2. 왜 두 번? → 첫 번째 시도에서 문제가 있어 재시도했거나, 별도 스코프로 분리하려 했을 가능성.
3. 왜 내용이 안 채워졌나? → smoke test 목적상 빠르게 다음 단계(retro)로 넘어감.
4. **근본 원인**: bootstrap된 빈 프로젝트 디렉토리를 정리하는 메커니즘이 없음.
5. **분류**: Process gap — `next-prompt-dir --bootstrap` 후 일정 시간 내 plan.md가 갱신되지 않으면 경고하는 hook 또는 cleanup 스크립트가 없음.

### cwf-state.yaml 수동 생성

sandbox 초기화 시 `cwf-state.yaml`이 자동 생성되지 않아 live-state 스크립트 실패.

**5 Whys**:
1. 왜 실패했나? → `cwf-live-state.sh`가 파일 부재 시 에러.
2. 왜 파일이 없었나? → sandbox repo에 `cwf:setup`이 실행되지 않은 상태.
3. 왜 setup 없이 진행했나? → smoke test라 최소 경로를 택함.
4. **근본 원인**: `cwf-live-state.sh set`이 파일 부재 시 자동 생성(upsert)하지 않음.
5. **분류**: Process gap — 이미 lessons.md에 기록됨. live-state 스크립트에 auto-init 로직 추가가 구조적 해결책.

## 4. Critical Decision Analysis (CDM)

### CDM 1: Minimal smoke plan 선택 — hello.txt 단일 파일

| Probe | Analysis |
|-------|----------|
| **Cues** | sandbox repo가 README.md만 있는 빈 상태. 파이프라인 검증이 목표. |
| **Goals** | (1) plan→impl 흐름이 동작하는지 확인 (2) 가능한 빠르게 end-to-end 도달 |
| **Options** | (a) hello.txt 신규 생성 (b) README.md 수정 (c) 다중 파일 변경 |
| **Basis** | 신규 파일이 가장 깨끗 — 기존 파일 충돌 위험 제로, git diff가 명확 |
| **Aiding** | smoke test 템플릿이나 `cwf:plan --smoke` 같은 축약 모드가 있으면 더 빠를 것 |
| **Hypothesis** | README.md 수정을 택했다면 diff는 더 작지만, "기존 파일 변경 vs 신규 파일" 분기를 검증하지 못했을 것 |

**Key lesson**: 파이프라인 smoke test에서는 가장 단순하되 실제 git 흐름(add→commit)을 타는 변경을 선택하라. 기존 파일 수정보다 신규 파일 생성이 더 깨끗한 테스트 경로.

### CDM 2: refactor quick-scan 2회 시도 후 retro로 전환

| Probe | Analysis |
|-------|----------|
| **Cues** | 두 개의 bootstrap-only 프로젝트 디렉토리 존재 (plan.md 미갱신) |
| **Goals** | (1) refactor 스킬도 검증하고 싶음 (2) 하지만 retro까지 도달해야 전체 파이프라인 확인 |
| **Options** | (a) refactor 완료 후 retro (b) refactor 스킵하고 retro 진행 (c) refactor와 retro 병행 |
| **Basis** | 전체 파이프라인 도달이 우선 — refactor는 이후 별도 세션에서 검증 가능 |
| **Time Pressure** | pre-release audit 맥락이므로 모든 스킬의 기본 동작 확인이 시급 |

**Key lesson**: smoke test에서는 "파이프라인 전체 도달"을 "개별 스킬 완전 검증"보다 우선하라. 빈 bootstrap 디렉토리가 남더라도 end-to-end 흐름 확인이 더 가치 있다.

## 5. Expert Lens

> Run `/retro --deep` for expert analysis.

## 6. Learning Resources

> Run `/retro --deep` for learning resources.

## 7. Relevant Tools (Capabilities Included)

### Installed Capabilities

**Plugins (marketplace)**:
- `claude-dashboard` v1.8.1 — usage/status monitoring
- `cwf` v0.8.0 (project-scoped, repo-install) — workflow orchestration

**Local skills**:
- `plugin-deploy` — plugin lifecycle workflow

**CWF skills (이 세션에서 사용)**:
- `cwf:plan` — 사용됨 (minimal-smoke-plan)
- `cwf:impl` — 사용됨 (hello.txt 생성)
- `cwf:refactor` — 시도됨 (bootstrap만, 미완료)
- `cwf:retro` — 현재 실행 중

**Repo hooks**:
- `.githooks/pre-commit`, `.githooks/pre-push` — 설치됨

**사용되지 않은 가용 스킬**:
- `cwf:review`, `cwf:ship`, `cwf:gather`, `cwf:clarify`, `cwf:hitl`, `cwf:handoff`, `cwf:run`

### Tool Gaps

**빈 프로젝트 디렉토리 감지/정리**:
- **문제 신호**: bootstrap만 된 프로젝트 디렉토리 2개가 잔존
- **후보**: `check-session.sh`에 "stale bootstrap dir" 검증 규칙 추가, 또는 `next-prompt-dir`에 `--cleanup-stale` 옵션
- **통합점**: session 종료 시 또는 retro 시작 시 자동 스캔
- **예상 이점**: 아티팩트 디렉토리 오염 방지
- **파일럿**: retro 시작 시 bootstrap-only plan.md를 경고 출력하는 간단한 체크

**cwf-state.yaml auto-init**:
- **문제 신호**: sandbox에서 live-state 스크립트 실패
- **후보**: `cwf-live-state.sh set`에 파일 부재 시 minimal skeleton 자동 생성
- **통합점**: 스크립트 내부 로직
- **예상 이점**: setup 없이도 개별 스킬 실행 가능
- **파일럿**: `set` 명령 시 파일 없으면 `live:` 섹션만 있는 yaml 생성

No additional tool gaps beyond the two items above.
