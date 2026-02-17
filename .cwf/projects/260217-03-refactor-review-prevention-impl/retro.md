# Retro: Prevention Proposals A, B, C, E+G 구현

> Session date: 2026-02-17
> Mode: deep (expert lens deferred — code review에서 James Reason + Charles Perrow 분석 완료)
> Pipeline: cwf:run (gather → clarify → plan → review-plan → impl → review-code → refactor → retro → ship)

## 1. Context Worth Remembering

- **Worktree 개발 패턴**: impl 세션은 main repo와 별도 worktree에서 진행. 브랜치 공유로 리뷰/커밋이 원활. 기존 worktree 재활용도 가능 (같은 base commit이면 브랜치 전환만으로 충분)
- **Hook exit code 규칙**: Claude Code hooks에서 `exit 1` = block, `exit 0` = allow. JSON의 `decision` 필드가 아닌 exit code가 실제 차단 메커니즘
- **cwf-live-state.sh 이중 역할**: CLI 도구이자 sourceable 라이브러리 (`BASH_SOURCE[0] == $0` 체크). 현재 hook들은 sourcing 대신 독립 구현을 사용하여 중복 발생
- **AWK 기반 YAML 상태 관리**: jq 없이 순수 shell/AWK로 YAML 조작. 장점은 zero-dependency이지만 파서 중복 위험이 trade-off
- **방어 깊이 비대칭 설계**: 삭제 안전 훅은 fail-closed (돌이킬 수 없는 행동), 워크플로우 게이트는 fail-open (복구 가능한 프로세스 위반). 결과의 비가역성에 기반한 의도적 비대칭

## 2. Collaboration Preferences

- 파이프라인 실행 중 최소 개입 선호 (auto-proceed 활용)
- worktree 컨텍스트 인식 여부를 명시적으로 확인함
- lesson 기록은 한국어로, 코드/아티팩트는 영어로 — 이 분리가 잘 작동함
- "fix it while the context is hot" 패턴: 세션 중 발견한 문제를 즉시 스코프에 포함 (Step 5 추가)

### Suggested Agent-Guide Updates

없음. 현재 AGENTS.md와 CLAUDE.md의 가이드가 세션 패턴과 일치함.

## 3. Waste Reduction

### 외부 CLI 타임아웃 (4회)
Plan review에서 Codex/Gemini 모두 120초 타임아웃 (2회), code review에서 Codex 180초 타임아웃 (1회), Gemini는 139초에 성공.

**5 Whys**:
1. 왜 타임아웃? → 프롬프트(~500줄)가 하드코딩된 120초 제한을 초과
2. 왜 하드코딩? → 초기 구현에서 프롬프트 크기 변동을 고려하지 않음
3. 왜 미고려? → code review 기준으로 설계되었고 plan review의 긴 프롬프트를 예상 못함
4. 왜 미예상? → 리뷰 프롬프트에 spec 문서가 포함될 수 있다는 것을 경험하기 전
5. 왜 경험 부족? → cwf:review가 plan 모드를 추가한 것이 비교적 최근

**근본 원인**: 프로세스 갭 → Step 5로 적응형 타임아웃 구현하여 해결. **구조적 잔여 문제**: Codex가 code review에서도 180초 타임아웃 — 테스트 하네스 생성 시도에 시간 소모. Codex의 "실행 우선" 행동은 리뷰 프롬프트와 불일치. reasoning_effort='xhigh' 설정이 부분적 원인일 수 있음.

### 컴팩트 복구 시 사용자 결정 유실
"4개로 합성 진행" 선택이 컴팩트 후 유실되어 fallback 재시도 3회 반복.

**5 Whys**:
1. 왜 재시도? → 컴팩트 요약에 사용자 결정이 포함되지 않음
2. 왜 미포함? → AskUserQuestion 응답이 컴팩트 요약에서 별도 추적되지 않음
3. 왜 미추적? → 현재 컴팩트 메커니즘이 대화 내용만 요약, 의사결정 포인트를 별도로 식별하지 않음
4. 왜 미식별? → 컴팩트 프로토콜의 설계 범위 밖
5. 왜 범위 밖? → decision_journal이 존재하지만 hook-level 의사결정까지 포함하지 않음

**근본 원인**: 구조적 제약 → decision_journal에 사용자 의사결정 포인트를 자동 기록하는 메커니즘 필요. project-context.md에 기록 권장.

### /tmp 파일에 대한 Hook 오발동
리뷰 프롬프트 파일을 /tmp에 작성할 때 PostToolUse hooks (markdown lint, link checker)가 repo 파일처럼 처리.

**5 Whys**:
1. 왜 오발동? → hooks가 모든 Write/Edit 도구 호출에 발동
2. 왜 모든 호출? → hooks.json의 matcher가 파일 경로를 필터링하지 않음
3. 왜 미필터링? → 현재 hook 아키텍처에서 파일 경로 기반 필터링이 지원되지 않거나 구현되지 않음

**근본 원인**: 프로세스 갭 → Bash heredoc으로 우회. 장기적으로 hook matcher에 path 필터 추가 고려.

## 4. Critical Decision Analysis (CDM)

### CDM 1: Build-on-top vs 재구현
이전 에이전트(S260217-02)의 ~500줄 미커밋 작업을 재활용하기로 결정. 구조적 스캐폴딩은 유효했으나 로직 결함(exit 0 대신 exit 1, PostToolUse 대신 PreToolUse)이 있어 수정 커밋 필요.

**핵심 교훈**: 이전 에이전트 작업 위에 구축할 때, 코드를 수정하기 *전에* plan 대비 명시적 갭 분석을 수행할 것. 구조적 스캐폴딩이 재사용 가치이고, 로직 세부사항에 버그가 숨어 있음.

### CDM 2: Fail-closed vs Fail-open 비대칭
삭제 안전 훅(fail-closed)과 워크플로우 게이트(fail-open)의 의도적 비대칭. 3/6 리뷰어가 불일치로 플래그했으나 결과 비가역성에 기반한 올바른 설계.

**핵심 교훈**: 여러 안전 메커니즘 설계 시 API 균일성이 아닌 결과의 비가역성과 트리거 빈도에 기반하여 fail 모드 선택. 비대칭의 근거를 명시적으로 문서화할 것.

### CDM 3: Step 5 추가 (적응형 CLI 타임아웃)
세션 중 발견된 운영 결함을 즉시 구현 스코프에 포함. 스코프 확장이지만 수정이 작고(SKILL.md 편집) 인과 관계가 명확.

**핵심 교훈**: 운영 실패가 시스템적 설계 결함을 드러내고 수정이 작으면, 현재 세션의 plan에 인과 레슨과 함께 추가. "context is hot" 패턴이 지연 티켓이 잃는 인과 체인을 보존.

### CDM 4: 4/6 리뷰어로 합성 진행
외부 CLI 실패 후 4명으로 합성 결정. 실용적으로 올바랐으나 컴팩트에 유실되어 3회 불필요한 재시도.

**핵심 교훈**: 사용자 결정은 컴팩트 면역 스토리지에 즉시 영속화해야 함. 결정된 질문을 다시 하면 신뢰가 침식되고 토큰이 낭비됨.

## 5. Expert Lens

Code review 단계에서 이미 두 전문가 분석 완료:
- **James Reason** (Swiss Cheese Model): 4층 방어 아키텍처 분석. 독립적 barrier의 실패 모드가 상관관계 없음을 확인. Pass 판정.
- **Charles Perrow** (Normal Accident Theory): 공통 모드 실패(AWK 파서 중복)와 tight coupling(remaining_gates 가변 상태)을 핵심 구조적 우려로 식별.

전체 분석: `review-expert-alpha-code.md`, `review-expert-beta-code.md` 참조.
전용 retro expert lens가 필요하면: `cwf:retro --deep`

## 6. Learning Resources

### Resource 1: Designing Modular Bash — Functions, Namespaces, Library Patterns
**URL**: https://www.lost-in-it.com/posts/designing-modular-bash-functions-namespaces-library-patterns/

4/6 리뷰어가 플래그한 AWK 파서 중복 문제를 직접 해결. prefix 네임스페이싱(`cwf_yaml_` public / `_cwf_yaml_` private), include guard, configuration-by-convention 패턴. Shell이 AWK/jq를 파이프라인으로 조율하는 것이 로직을 bash에 복제하는 것보다 낫다는 HN 논의도 참고.

### Resource 2: yq — Portable Command-Line YAML Processor
**URL**: https://github.com/mikefarah/yq

단일 Go 바이너리로 jq-like YAML 조작. 현재 3개의 중복 AWK 파서를 원라이너로 대체 가능. `yq -i '.live.remaining_gates += ["review-code"]' state.yaml`. Trade-off: zero-dependency 순수성 vs 파서 복잡도 감소. 안전 중요 훅 시스템에서 파서 복잡도 감소 자체가 안전 개선일 수 있음.

### Resource 3: Swiss Cheese Model for AI Safety
**URL**: https://arxiv.org/html/2408.02205v4

이 세션이 직관적으로 구축한 것을 형식화한 학술 논문. 14개 guardrail 품질 속성, 3개 설계 차원(quality attributes, pipelines, artifacts). `check-deletion-safety.sh`는 tool artifact guardrail at intermediate results pipeline, `workflow-gate.sh`는 plan artifact guardrail at prompt pipeline. Akira AI의 실시간 guardrails 가이드가 실용적 구현 패턴 보완.

## 7. Relevant Tools (Capabilities Included)

### Installed Capabilities

**13 CWF skills**: clarify, gather, handoff, hitl, impl, plan, refactor, retro, review, run, setup, ship, update

**Hook scripts** (이번 세션에서 확장):
- `check-deletion-safety.sh` (NEW — Proposal A)
- `workflow-gate.sh` (NEW — Proposal E+G)
- `check-links-local.sh` (MODIFIED — Proposal B triage hint)
- `read-guard.sh`, `check-session-end.sh` (기존)

**Deterministic tools used**: markdownlint, ShellCheck (SC2168 발견), git diff/log/status

### Tool Gaps

**No additional tool gaps identified.** 이번 세션에서 식별된 모든 자동화 필요사항은 구현됨:
- 삭제 안전: PreToolUse hook으로 자동화 완료
- 워크플로우 게이트: UserPromptSubmit hook으로 자동화 완료
- 브로큰 링크 트리아지: hook hint + protocol 문서화 완료

**잠재적 미래 도구**:
- `yq` 바이너리 도입 시 AWK 파서 중복 해소 가능 (Resource 2 참조)
- Hook matcher에 path filter 지원 시 /tmp 오발동 해소 가능
