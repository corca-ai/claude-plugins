# Retro: Prevention Proposals A, B, C, E+G + Adaptive Review Timeout

> Session date: 2026-02-17
> Mode: deep
> Invocation: run_chain (cwf:run pipeline)
> Branch: feat/260217-03-review-prevention-impl (8 commits)
> Base: marketplace-v3

## 1. Context Worth Remembering

- CWF 훅 시스템은 두 가지 실패 모드를 사용: **fail-closed** (삭제 안전성, 되돌릴 수 없는 결과) vs **fail-open** (워크플로우 게이트, 프로세스 강제). 결정 기준은 결과의 비가역성.
- 훅 exit code 의미: `exit 0` = 허용, `exit 1` = 차단. JSON `decision` 필드만으로는 차단이 안 됨 — exit code가 실제 actuator.
- `cwf-live-state.sh`이 이제 list 연산(`list-set`, `list-remove`)을 지원. gate 이름 유효성 검사 포함.
- 리뷰 파이프라인: 6명 병렬 리뷰어 (내부 2 + 외부 CLI 2 + 도메인 전문가 2). 외부 CLI 타임아웃 스케일링: <300줄 → 120s, 300-800줄 → 180s, >800줄 → 240s.
- 이전 에이전트의 미커밋 작업 재활용: "build-on-top" 전략 + plan 대비 체계적 gap analysis로 결함 발견.
- `mktemp` + `trap EXIT` 패턴으로 동시 훅 호출 시 symlink race 방지.
- `state_version`은 root/session 파일 간 명시적 전파 필요 (독립 bump 시 drift 발생).
- `grep -rl` 기반 caller 탐지는 변수 보간 참조를 감지 못함 — 문서화된 잔여 위험.

## 2. Collaboration Preferences

- 사용자는 한국어로 소통하며 autonomous pipeline 실행(cwf:run) 허용
- 운영 장애 발견 시 mid-session 스코프 확장 수용 ("fix while context is hot")
- 수정 사항과 인과적 교훈(lesson)을 함께 기록하는 것을 선호
- 6명 리뷰어 코드 리뷰로 품질 게이트를 자동화하는 접근 신뢰

### Suggested Agent-Guide Updates

없음. 현재 AGENTS.md의 규칙이 이 세션의 워크플로우를 적절히 지원함.

## 3. Waste Reduction

### 낭비 1: Codex CLI 1271줄 프롬프트에서 240초 타임아웃

코드 리뷰 시 Codex CLI가 1271줄 프롬프트(리뷰어 역할 설명 + 1195줄 diff + BDD 기준)에서 240초 타임아웃(exit 124). 확장된 타임아웃(120→240s)도 부족했음.

- **Why**: 프롬프트가 diff 외에도 리뷰어 role 설명, 체크리스트, 성공 기준 등을 포함
- **Why**: review SKILL.md의 timeout 테이블이 >800줄 → 240s로 끝나며, 그 이상은 고려하지 않음
- **Why**: 외부 CLI가 처리 불가능한 프롬프트 크기에 대한 "max cutoff" 메커니즘이 없음
- **구조 원인**: 프로세스 갭 — 프롬프트 크기 상한 없이 외부 CLI에 전달
- **권장 티어**: Tier 3 (Doc) — review SKILL.md에 >1200줄 시 외부 CLI 건너뛰고 직접 Claude fallback 사용하는 규칙 추가
- **메커니즘**: review SKILL.md timeout 테이블에 4번째 행 추가: `> 1200 → skip external CLI (direct Task fallback)`

### 낭비 2: ShellCheck SC2086/SC2168 다중 편집 라운드

`replace_all`로 `$STDERR_TMP`를 일괄 치환했지만 shell 따옴표 컨텍스트를 포함하지 않아 SC2086 블로킹. 이후 `case` 블록 내 `local` 키워드로 SC2168 에러 추가 발생.

- **Why**: `replace_all`은 문자열 수준 연산으로 shell 인용 컨텍스트를 이해하지 못함
- **Why**: SC2168 (`local`은 함수 내에서만 유효)은 bash 지식 갭
- **구조 원인**: 일회성 실수 (SC2086 도구 한계 + SC2168 지식 갭)
- **권장 티어**: 별도 조치 불필요 — lessons.md에 이미 기록됨
- **교훈**: shell 변수를 `replace_all`할 때 항상 따옴표 포함하여 치환

### 낭비 3: Compaction으로 인한 의사결정 유실 (이전 세션에서 관찰)

plan 리뷰 시 사용자의 "4개로 합성 진행" 결정이 compaction으로 유실되어 fallback 재시도 3회. 이 세션의 CDM-4에서 상세 분석됨.

- **Why**: 사용자 결정이 conversation context(휘발성)에만 존재
- **Why**: decision_journal이 hook 수준 운영 결정까지 포함하지 않음
- **Why**: AskUserQuestion 응답을 자동으로 persistent state에 기록하는 메커니즘 부재
- **구조 원인**: 프로세스 갭 — compaction-immune 결정 저장 미구현
- **권장 티어**: Tier 2 (State) — `cwf-live-state.sh set . decision_journal[N]="..."` 자동 호출
- **메커니즘**: AskUserQuestion 응답 후 cwf-live-state.sh decision_journal에 자동 append

## 4. Critical Decision Analysis (CDM)

### CDM-1: 이전 에이전트 코드 위에 구축 vs 재구현

이전 에이전트(S260217-02)가 ~500줄의 미커밋 셸 스크립트를 남김. Build-on-top 전략을 선택하여 gap analysis 후 타겟 수정. 컨텍스트 예산은 절약했으나 `exit 0` 버그와 PostToolUse 타이밍 결함을 상속받아 fix commit이 필요했음.

**핵심 교훈**: 이전 에이전트의 미커밋 작업 위에 구축할 때, 코드 수정 전에 현재 plan 대비 명시적 gap analysis를 수행. 구조적 스캐폴딩이 재사용 가치이고, 로직 세부사항이 버그가 숨는 곳.

### CDM-2: Fail-closed/fail-open 비대칭

삭제 안전성은 fail-closed (비가역적 결과), 워크플로우 게이트는 의존성 실패 시 fail-open (세션 마비 방지). 결과 비가역성 기반, API 일관성 기반이 아님. 코드 리뷰에서 비일관성으로 지적(3/6)되었으나 의도적 설계.

**핵심 교훈**: 여러 안전 메커니즘 설계 시 fail-closed vs fail-open을 결과 비가역성과 트리거 빈도에 기반하여 선택. API 일관성이 아님. 비대칭의 근거를 명시적으로 문서화.

### CDM-3: 적응형 CLI 타임아웃의 mid-session 스코프 확장

plan 리뷰 중 Codex/Gemini CLI가 120초 타임아웃. 사용자가 이번 스코프에 포함 지시. 작은 수정(3행 테이블 + 4개 문자열 교체)으로 정당화됨.

**핵심 교훈**: 세션 중 운영 장애가 시스템 설계 결함을 드러내고 수정이 세션 스코프 대비 작을 때, "fix while context is hot" 패턴 적용. 지연 시 인과 체인이 유실됨.

### CDM-4: 4/6 리뷰어로 진행 결정의 compaction 유실

사용자의 "4개로 합성 진행" 결정이 compaction으로 유실. 3회 불필요한 fallback 재시도 발생. compaction-immune 저장소에 사용자 결정 기록 필요.

**핵심 교훈**: 세션 중 사용자 결정을 compaction-immune 저장소(state file)에 즉시 기록. 결정을 다시 묻는 비용은 토큰 낭비뿐 아니라 에이전트 연속성에 대한 사용자 신뢰 침식.

## 5. Expert Lens

### Expert α: Nancy Leveson (STAMP/STPA)

**프레임워크**: STAMP/STPA — 사고를 컴포넌트 실패가 아닌 부적절한 제어로 모델링. 계층적 제어 구조, 안전하지 않은 제어 행동, 피드백 채널 분석.
**출처**: *Engineering a Safer World* (MIT Press, 2011), roster-verified.

**핵심 분석**:

1. **PostToolUse→PreToolUse 수정 (Moment 1)**: STAMP에서 "control action provided too late" — PostToolUse 훅은 이미 발생한 상태 전이를 관찰만 하는 open-loop observation. PreToolUse 훅은 상태 전이 전 개입 가능한 closed-loop control action. 이전 에이전트의 `exit 0` 사용은 actuator 메커니즘에 대한 flawed mental model — exit code가 actuator이고 JSON은 피드백.

2. **Fail-closed/fail-open 비대칭 (Moment 2)**: STAMP의 safety constraint enforcement principle의 올바른 적용. 비대칭 근거가 코드 자체에 문서화되지 않아 향후 유지보수자가 "일관성 수정"으로 control structure를 degradation할 위험.

3. **Compaction 결정 유실 (Moment 3)**: 계층적 제어 구조에서 inadequate feedback. 시스템 이벤트(compaction)가 상위 컨트롤러(사용자)와 하위 컨트롤러(에이전트) 간 피드백 채널을 절단. `remaining_gates`에는 적용된 compaction-immune 패턴이 운영 결정에는 미적용.

**권장 사항**:
- STAMP 기반 훅 설계 템플릿 작성: controlled process, safety constraint, control action, actuator, feedback channel, fail mode + rationale, detection boundary
- Compaction을 예외가 아닌 정상 운영 조건으로 취급: 컨트롤러 행동에 영향을 주는 모든 state는 기본적으로 compaction-immune

### Expert β: Sidney Dekker (Drift into Failure)

**프레임워크**: 시스템은 갑작스러운 붕괴가 아닌 점진적, 국소적으로 합리적인 적응을 통해 안전 마진을 침식하다 전복점을 넘어 실패.
**출처**: *Drift into Failure* (Ashgate, 2011); *The Field Guide to Understanding 'Human Error'* (CRC Press, 3rd ed., 2014), roster-verified.

**핵심 분석**:

1. **상속된 exit-code 결함 (Moment 1)**: 이전 에이전트의 `exit 0` 사용은 단순 버그가 아닌 practical drift — work-as-imagined (JSON `decision` 필드가 차단 제어)와 work-as-done (exit code가 차단 제어) 사이의 격차. 모든 blocking path에서 일관된 오류는 locally coherent misunderstanding의 hallmark. 현재 훅 아키텍처에 이 drift를 구조적으로 방지하는 메커니즘이 없음.

2. **grep -rl 한계를 "수용된 잔여 위험"으로 (Moment 2)**: 원본 사고를 유발한 정확한 탐지 갭($SCRIPT_DIR/csv-to-toon.sh)이 예방 메커니즘에 그대로 존재. 이것은 Vaughan의 normalization of deviance의 시작점. 훅이 에이전트의 주의력을 감소시키지만(훅이 보호한다고 믿으므로), 감소된 주의력이 결국 탐지 갭과 만남 — 훅 자체가 다음 실패의 씨앗.

3. **Compaction 결정 유실 (Moment 3)**: 조직 교대 인수인계에서 상황 적응이 유실되고 후임자가 표준 절차를 재적용하는 패턴과 구조적으로 동일.

**권장 사항**:
- 모든 훅에 대한 구조적 exit-code 강제 테스트 작성: blocking path가 실제로 non-zero exit하는지 검증하는 integration test. convention을 structure로 전환.
- grep 탐지 경계를 수동적 "수용된 잔여 위험"에서 능동적 운영 가이드로 재프레이밍: 삭제 허용 시(exit 0) 탐지 한계를 알리는 advisory 메시지 출력.

## 6. Learning Resources

### Resource 1: Designing Modular Bash — Functions, Namespaces, and Library Patterns

**URL**: https://www.lost-in-it.com/posts/designing-modular-bash-functions-namespaces-library-patterns/

접두사 기반 네임스페이싱(`cwf_yaml_` public, `_cwf_yaml_` internal), include guard, source 전 환경 설정 패턴을 체계적으로 다룸. 이 세션에서 6/6 리뷰어가 지적한 중복 AWK YAML 파싱 로직 추출에 직접 적용 가능. HN 논의(https://news.ycombinator.com/item?id=33354286)는 shell의 강점이 AWK/jq 같은 특수 언어 임베딩이라는 실용적 관점 보완.

### Resource 2: yq — Portable Command-Line YAML Processor

**URL**: https://github.com/mikefarah/yq

단일 Go 바이너리(의존성 없음)로 jq 유사 문법의 YAML 조작. `yq -i '.key = "value"' file.yaml` 형태의 in-place 편집 지원. 현재 커스텀 AWK 파서가 수행하는 모든 연산(get, set, list-set, list-remove)을 한 줄 표현식으로 대체 가능. 트레이드오프: zero-dependency 순수성 vs 파서 버그 클래스 전체 제거.

### Resource 3: Swiss Cheese Model for AI Safety — Multi-Layered Guardrails for FM-Based Agents

**URL**: https://arxiv.org/html/2408.02205v4

FM 기반 에이전트에 Swiss Cheese Model을 적용한 논문(Shamsujjoha et al., 2024, Data61/CSIRO). guardrail의 14개 품질 속성, 3개 설계 차원(quality attributes, pipelines, artifacts) 분류. 이 세션의 방어 심층 구현(자동 방지 훅, 가이드 탐지 트리아지, 인지 완화 프로세스 규칙, 워크플로우 강제 게이트)이 논문의 다층 아키텍처에 직접 대응.

## 7. Relevant Tools (Capabilities Included)

### Installed Capabilities

**CWF Skills** (13개): gather, clarify, plan, review, impl, refactor, retro, run, ship, handoff, hitl, setup, update

**이 세션에서 사용된 스킬**: run (pipeline orchestration), gather, clarify, plan, review (plan + code mode), impl, refactor, retro

**사용되지 않은 스킬**: ship (pipeline 미완료), handoff, hitl, setup, update

**Deterministic Tools/Hooks 사용됨**:
- `check-deletion-safety.sh` (신규, 이 세션에서 생성)
- `workflow-gate.sh` (신규, 이 세션에서 생성)
- `check-shell.sh` (PostToolUse ShellCheck 훅 — SC2086/SC2168 감지)
- `cwf-live-state.sh` (state 관리 — set, list-set, list-remove, resolve)
- `retro-collect-evidence.sh` (retro evidence 수집)
- `check-session.sh --impl` (세션 완전성 검사)
- Codex CLI (review slot 3, 타임아웃)
- Gemini CLI (review slot 4, 성공)
- `codex-with-log.sh` (Codex wrapper with logging)

### Tool Gaps

**Gap 1: 훅 exit-code integration test 부재**
- **Signal**: 이전 에이전트가 blocking path에서 `exit 0` 사용 — 구조적으로 탐지 불가
- **Candidate**: 각 훅에 대해 합성 blocking 입력으로 exit code 검증하는 셸 스크립트
- **Integration**: `cwf:setup` 또는 pre-commit에서 실행
- **Gain**: convention을 structure로 전환, 향후 훅 작성자의 동일 drift 방지
- **Pilot**: `plugins/cwf/hooks/scripts/test-hook-exit-codes.sh` — hooks.json의 각 등록 훅 대상

**Gap 2: >1200줄 프롬프트 외부 CLI 건너뛰기**
- **Signal**: 1271줄 프롬프트에서 Codex 240초 타임아웃
- **Candidate**: review SKILL.md timeout 테이블에 cutoff 행 추가
- **Integration**: cwf:review Phase 1.5
- **Gain**: 실패 확실한 외부 CLI 시도로 인한 지연 제거
- **Pilot**: SKILL.md 문서 수정만으로 구현 가능 (코드 변경 불필요)

추가 tool gap은 식별되지 않음.
