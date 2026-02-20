# Retro: Minimal Smoke Plan — Iteration 2

> Session date: 2026-02-19
- Mode: light

## 1. Context Worth Remembering

- **Sandbox 반복 테스트 패턴**: `iter2/sandbox/repo-smoke`에서 iteration 1(hello.txt 생성) → iteration 2(hello.txt 편집)로 CWF plan→impl 파이프라인의 create/edit 두 코드 경로를 분리 검증.
- **적응적 리서치 스킵**: 파일 2개짜리 sandbox repo에서 Phase 2(리서치 에이전트)를 건너뛰는 것이 cwf:plan의 의도된 동작으로 확인됨.
- **빈 bootstrap 디렉토리 패턴 재발**: 이전 retro(260219-03)에서도 동일 문제 지적됨. 이번에도 `260219-05-refactor-quick-scan`이 bootstrap 상태로 잔존.

## 2. Collaboration Preferences

- 사용자가 동일 sandbox에서 skill을 반복 호출하며 각 iteration에서 다른 코드 경로(create vs edit)를 테스트하는 체계적 접근.
- 개별 스킬 완전 실행보다 전체 파이프라인 도달(plan→impl→retro)을 우선시하는 일관된 패턴.

### Suggested Agent-Guide Updates

- (해당 없음 — sandbox smoke test 반복 세션)

## 3. Waste Reduction

### 빈 bootstrap 디렉토리 재발 (260219-05)

이전 retro(260219-03)에서 이미 `260219-02`, `260219-03` bootstrap-only 디렉토리 잔존 문제를 지적했고, Tool Gaps에서 "stale bootstrap dir 검증 규칙 추가" 제안이 나왔으나, 구현되지 않은 채 동일 패턴이 재발.

**5 Whys**:
1. 왜 또 빈 디렉토리가 생겼나? → refactor quick-scan이 bootstrap 후 내용이 채워지지 않음.
2. 왜 내용이 안 채워졌나? → smoke test 목적상 retro로 바로 전환.
3. 왜 이전 retro에서 제안한 cleanup이 적용되지 않았나? → retro의 persist proposal이 실행되지 않은 채 다음 iteration 진행.
4. 왜 persist가 실행되지 않았나? → smoke test는 파이프라인 흐름 확인이 목적이라 개선 적용은 범위 밖.
5. **근본 원인**: One-off (smoke test 맥락). 실제 작업 세션에서도 재발하면 process gap으로 재분류 필요.

**분류**: One-off — smoke test 맥락에서는 자연스러운 부산물. 다만 이전 retro 제안(stale dir 감지)은 production 환경에서 여전히 유효.

## 4. Critical Decision Analysis (CDM)

### CDM 1: Create vs Edit 경로 분리 테스트

| Probe | Analysis |
|-------|----------|
| **Cues** | Iteration 1에서 hello.txt 생성 완료. 두 번째 iteration에서 동일 파일 편집으로 다른 코드 경로 테스트. |
| **Goals** | (1) edit 경로가 plan→impl에서 정상 작동하는지 확인 (2) 최소 변경으로 검증 |
| **Options** | (a) 기존 파일 수정 (b) 새 파일 추가 (c) 파일 삭제 후 재생성 |
| **Basis** | Iteration 1이 create 경로를 검증했으므로, edit 경로가 논리적 다음 단계. 삭제 경로는 smoke test에서 불필요한 복잡도. |
| **Aiding** | smoke test case 목록이 미리 정의되어 있었으면 iteration마다 어떤 경로를 테스트할지 즉석 결정할 필요 없었을 것. |

**Key lesson**: smoke test는 코드 경로(create/edit/delete)별로 최소 1회씩 커버하도록 사전 정의하면 iteration 간 결정 비용이 줄어든다.

### CDM 2: Phase 2 리서치 스킵 판단

| Probe | Analysis |
|-------|----------|
| **Cues** | repo에 파일 2개(README.md, hello.txt). 작업이 1줄 추가로 자명. |
| **Goals** | (1) cwf:plan의 adaptive sizing gate 동작 확인 (2) 불필요한 에이전트 실행 방지 |
| **Options** | (a) Phase 2 스킵 (b) Phase 2 실행하되 결과 무시 (c) Phase 2를 간소화 모드로 실행 |
| **Basis** | 파일 수와 작업 복잡도 기준으로 리서치 가치 제로 — 에이전트 실행은 순수 낭비 |

**Key lesson**: adaptive sizing gate의 "파일 ≤2, 작업 자명" 조건이 smoke test에서 올바르게 작동함을 확인. 이 게이트는 production에서도 소규모 repo 작업 시 유효.

## 5. Expert Lens

> Run `/retro --deep` for expert analysis.

## 6. Learning Resources

> Run `/retro --deep` for learning resources.

## 7. Relevant Tools (Capabilities Included)

### Installed Capabilities

**Plugins (marketplace)**:
- `claude-hud` — status/usage monitoring

**Local skills**:
- `plugin-deploy` — plugin lifecycle workflow

**CWF skills (이 세션에서 사용)**:
- `cwf:plan` — 사용됨 (iteration 2 hello.txt edit plan)
- `cwf:impl` — 사용됨 (hello.txt 편집)
- `cwf:retro` — 현재 실행 중

**사용되지 않은 가용 스킬**:
- `cwf:review`, `cwf:refactor`, `cwf:ship`, `cwf:gather`, `cwf:clarify`, `cwf:hitl`, `cwf:handoff`, `cwf:run`

### Tool Gaps

**이전 retro에서 제안된 미구현 항목 (여전히 유효)**:
- `next-prompt-dir --cleanup-stale` 또는 `check-session.sh`에 stale bootstrap dir 감지 규칙
- `cwf-live-state.sh set`의 auto-init 로직 (cwf-state.yaml 부재 시 skeleton 자동 생성)

**이번 세션 추가 신호**:
- smoke test case 사전 정의 목록이 없어 각 iteration에서 즉석 결정 발생. 그러나 이는 smoke test 프레임워크 자체의 부재이며, CWF tool gap이라기보다 테스트 전략 문서 부재.

No additional tool gaps identified beyond the carried-forward items above.
