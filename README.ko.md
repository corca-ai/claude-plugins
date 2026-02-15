# CWF (Corca Workflow Framework)

[English](README.md)

구조화된 개발 세션을 반복 가능한 워크플로우로 전환하는 Claude Code 플러그인입니다 -- 컨텍스트 수집부터 회고 분석까지. [Corca](https://www.corca.ai/)에서 [AI-Native Product Team](AI_NATIVE_PRODUCT_TEAM.ko.md)을 위해 유지보수합니다.

## 설치

### 빠른 시작

```bash
# 마켓플레이스 추가
claude plugin marketplace add https://github.com/corca-ai/claude-plugins.git

# CWF 설치
claude plugin install cwf@corca-plugins

# 훅 적용을 위해 Claude Code 재시작
```

### 업데이트

```bash
claude plugin marketplace update corca-plugins
claude plugin update cwf@corca-plugins
```

또는 Claude Code 내에서:

```text
cwf:update               # 새 버전이 있으면 확인 + 업데이트
cwf:update --check       # 버전 확인만
```

### 독립 플러그인 (레거시)

v3.0.0부터 독립 플러그인(gather-context, clarify, retro, refactor, attention-hook, smart-read, prompt-logger, markdown-guard, plan-and-lessons)은 마켓플레이스에서 제거되었습니다. 기존 설치가 있다면 제거하고 `cwf`를 설치하세요.

## 프레이밍 계약

### CWF가 하는 것

- 컨텍스트 수집, 요구사항 명확화, 계획, 구현, 리뷰, 회고, 핸드오프, 배포를 하나의 워크플로우 플러그인(`cwf`)으로 통합합니다.
- [`.cwf/cwf-state.yaml`](.cwf/cwf-state.yaml), prompt-log 산출물, 훅을 통해 페이즈/세션 경계에서 컨텍스트를 보존하는 상태 기반 워크플로우를 제공합니다.
- Expert Advisor, Tier Classification, Agent Orchestration, Decision Point, Handoff, Provenance의 공통 개념을 조합하는 스킬 프레임워크입니다.

### CWF가 하지 않는 것

- 프로젝트별 엔지니어링 표준, CI 게이트, 인간의 제품 책임 의사결정을 대체하지 않습니다.
- 모든 결정을 완전 자동화한다고 보장하지 않으며, 주관적 결정은 사용자 확인이 필요합니다.
- 각 스킬이 완전히 분리된 범용 플러그인 묶음이 아니며, CWF 스킬은 의도적으로 상호 연동됩니다.

### 가정

- 사용자가 `.cwf/prompt-logs/`, [`.cwf/cwf-state.yaml`](.cwf/cwf-state.yaml) 같은 세션 산출물을 저장/활용할 수 있는 저장소에서 작업합니다.
- [AGENTS.md](AGENTS.md)에서 시작해 세부 문서를 읽는 progressive disclosure 방식에 동의합니다.
- 반복 품질 이슈는 행동 지침보다 결정적 검증 스크립트로 관리하는 방식을 선호합니다.

### 주요 결정과 이유

1. **독립 플러그인 대신 통합 플러그인**
   - 이유: 페이즈 전환 시 컨텍스트 손실과 프로토콜 드리프트를 줄이기 위해서입니다.
2. **구현 전 인간 게이트, 구현 후 자율 체이닝(`run`)**
   - 이유: 고판단 결정은 사람이 통제하고, 범위 확정 이후 실행 속도는 유지하기 위해서입니다.
3. **멘션만으로 실행 가능한 핸드오프 계약**
   - 이유: 다음 세션 시작 동작을 결정적으로 만들고 시작 모호성을 줄이기 위해서입니다.
4. **개념/리뷰 기준의 Provenance 점검**
   - 이유: 스킬/훅 인벤토리 변경 시 기준 문서의 노후화를 조기에 탐지하기 위해서입니다.

## 왜 CWF인가?

AI 코딩 세션은 모든 경계에서 컨텍스트를 잃습니다. 세션이 끝나면 다음 세션은 처음부터 시작합니다. 요구사항이 명확화에서 구현으로 넘어갈 때 프로토콜과 제약 조건이 잊혀집니다. 5개 스킬 시스템을 위해 작성된 품질 기준은 시스템이 성장하면서 조용히 무의미해집니다.

CWF는 13개 스킬에 걸쳐 조합되는 6가지 빌딩 블록 개념으로 이 문제를 해결합니다. 독립된 도구 묶음이 아니라, 각 스킬이 동일한 기반 행동 패턴을 동기화하는 하나의 통합 플러그인입니다 -- 전문가 자문은 요구사항 명확화와 세션 회고 모두에서 사각지대를 드러내고, 티어 분류는 의사결정을 일관되게 증거나 인간에게 라우팅하며, 에이전트 오케스트레이션은 리서치부터 구현까지 작업을 병렬화합니다.

결과: 하나의 플러그인(`cwf`), 13개 스킬, 7개 훅 그룹. 컨텍스트가 세션 경계를 넘어 유지됩니다. 의사결정에 증거가 뒷받침됩니다. 품질 기준이 시스템과 함께 진화합니다.

## 핵심 개념

CWF 스킬이 조합하는 6가지 재사용 가능한 행동 패턴입니다. 이것을 이해하면 각 스킬이 무엇을 하는지뿐 아니라 왜 함께 작동하는지 알 수 있습니다.

**전문가 자문 (Expert Advisor)** -- 대립하는 전문가 프레임워크를 도입하여 사각지대를 줄입니다. 서로 다른 분석 렌즈를 가진 두 도메인 전문가가 문제를 독립적으로 평가하며, 그들의 의견 불일치가 숨겨진 가정을 드러냅니다.

**티어 분류 (Tier Classification)** -- 의사결정을 적절한 권한에 라우팅합니다. 코드베이스 증거(T1)와 베스트 프랙티스 합의(T2)는 자율적으로 해결되고, 진정으로 주관적인 결정(T3)만 인간에게 전달됩니다.

**에이전트 오케스트레이션 (Agent Orchestration)** -- 품질을 희생하지 않고 작업을 병렬화합니다. 오케스트레이터가 복잡도를 평가하고, 필요한 최소 에이전트를 생성하고, 의존성을 고려한 배치로 실행하고, 결과를 종합합니다.

**결정 포인트 (Decision Point)** -- 모호성을 명시적으로 포착합니다. 요구사항이 누구든 결정하기 전에 구체적인 질문으로 분해되어, 모든 선택에 기록된 증거와 근거가 뒷받침됩니다.

**핸드오프 (Handoff)** -- 경계를 넘어 컨텍스트를 보존합니다. 세션 핸드오프는 작업 범위와 교훈을, 페이즈 핸드오프는 프로토콜과 제약 조건을 전달합니다. 다음 에이전트가 백지 상태가 아닌 정보를 갖고 시작합니다.

**출처 추적 (Provenance)** -- 기준의 노후화를 감지합니다. 참조 문서는 작성 당시의 시스템 상태 메타데이터를 담고 있으며, 스킬은 오래된 기준을 적용하기 전에 이를 확인합니다.

## 워크플로우

CWF 스킬은 컨텍스트 수집에서 학습 추출까지 자연스러운 흐름을 따릅니다:

```text
gather -> clarify -> plan -> impl -> retro
```

| # | 스킬 | 트리거 | 하는 일 |
|---|------|--------|---------|
| 1 | [gather](#gather) | `cwf:gather` | 정보 수집 -- URL, 웹 검색, 로컬 코드 탐색 |
| 2 | [clarify](#clarify) | `cwf:clarify` | 모호한 요구사항을 리서치 + 티어 분류로 정밀한 스펙으로 전환 |
| 3 | [plan](#plan) | `cwf:plan` | 리서치 기반 구현 계획과 BDD 성공 기준 작성 |
| 4 | [impl](#impl) | `cwf:impl` | 계획에 따른 병렬 구현 오케스트레이션 |
| 5 | [retro](#retro) | `cwf:retro` | CDM 분석과 전문가 렌즈를 통한 지속 가능한 교훈 추출 |
| 6 | [refactor](#refactor) | `cwf:refactor` | 다중 모드 코드/스킬 리뷰 -- 스캔, 정리, 심층 리뷰, 전체적 분석 |
| 7 | [handoff](#handoff) | `cwf:handoff` | 세션 또는 페이즈 핸드오프 문서 생성 |
| 8 | [ship](#ship) | `cwf:ship` | GitHub 워크플로우 자동화 -- 이슈 생성, PR, 머지 관리 |
| 9 | [review](#review) | `cwf:review` | 6명 병렬 리뷰어에 의한 범용 리뷰 -- 내부 + 외부 CLI + 도메인 전문가 |
| 10 | [hitl](#hitl) | `cwf:hitl` | 재개 가능한 상태 저장과 룰 전파를 갖춘 human-in-the-loop diff/chunk 리뷰 |
| 11 | [run](#run) | `cwf:run` | gather부터 ship까지 전체 파이프라인을 단계 게이트와 함께 오케스트레이션 |
| 12 | [setup](#setup) | `cwf:setup` | 훅 그룹 설정, 도구 감지, 프로젝트 인덱스 선택 생성 |
| 13 | [업데이트](#업데이트) | `cwf:update` | CWF 플러그인 업데이트 확인 및 적용 |

**개념 조합**: gather, clarify, plan, impl, retro, refactor, review, hitl, run은 모두 에이전트 오케스트레이션을 동기화합니다. clarify는 가장 풍부한 조합으로, 전문가 자문, 티어 분류, 에이전트 오케스트레이션, 결정 포인트를 하나의 워크플로우에서 동기화합니다. review와 hitl은 서로 다른 입도(병렬 리뷰어 vs 청크 기반 인터랙티브 루프)에서 인간 판단이 포함된 리뷰 오케스트레이션을 수행합니다. handoff는 핸드오프 개념의 주요 구현체입니다. refactor는 전체적 모드에서 출처 추적을 활성화합니다.

## 스킬 레퍼런스

### gather

통합 정보 수집 -- URL, 웹 검색, 로컬 코드 탐색.

```text
cwf:gather <url>                  # 서비스 자동 감지 (Google/Slack/Notion/GitHub/웹)
cwf:gather --search <query>       # 웹 검색 (Tavily)
cwf:gather --search code <query>  # 코드 검색 (Exa)
cwf:gather --local <topic>        # 로컬 코드베이스 탐색
```

Google Docs/Slides/Sheets, Slack 스레드, Notion 페이지, GitHub PR/이슈, 일반 웹 URL을 자동 감지합니다. 내장 WebSearch 리다이렉트 훅이 Claude의 WebSearch를 `cwf:gather --search`로 라우팅합니다.

전체 레퍼런스: [SKILL.md](plugins/cwf/skills/gather/SKILL.md)

### clarify

리서치 기반 요구사항 명확화와 자율적 의사결정.

```text
cwf:clarify <requirement>          # 리서치 기반 (기본)
cwf:clarify <requirement> --light  # 직접 Q&A, 서브에이전트 없음
```

기본 모드: 요구사항을 결정 포인트로 분해 -> 병렬 리서치 (코드베이스 + 웹) -> 전문가 분석 -> 티어 분류 (T1/T2 자동 결정, T3 인간에게 질문) -> why-digging을 활용한 끈질긴 질문. 라이트 모드: 서브에이전트 없이 반복적 Q&A.

전체 레퍼런스: [SKILL.md](plugins/cwf/skills/clarify/SKILL.md)

### plan

병렬 리서치와 BDD 성공 기준을 갖춘 에이전트 지원 계획 작성.

```text
cwf:plan <task description>
```

병렬 선행 사례 + 코드베이스 리서치 -> 단계, 파일, 성공 기준(BDD + 정성적)이 포함된 구조화된 계획 -> `.cwf/prompt-logs/` 세션 디렉토리에 저장. 권장 흐름: 구현 전에 `cwf:review --mode plan`으로 계획을 먼저 검토해 plan 단계 우려사항을 해소합니다.

전체 레퍼런스: [SKILL.md](plugins/cwf/skills/plan/SKILL.md)

### impl

구조화된 계획에 기반한 구현 오케스트레이션.

```text
cwf:impl                    # 가장 최근 plan.md 자동 감지
cwf:impl <path/to/plan.md>  # 명시적 계획 경로
```

계획 로드(+ 페이즈 핸드오프가 있으면 함께) -> 도메인과 의존성별 작업 항목 분해 -> 적응형 에이전트 팀 구성(1-4명) -> 병렬 배치 실행 -> BDD 기준 대비 검증. 일반 순서: `cwf:plan` -> `cwf:review --mode plan` -> `cwf:impl` -> `cwf:review --mode code`.

전체 레퍼런스: [SKILL.md](plugins/cwf/skills/impl/SKILL.md)

### retro

적응형 세션 회고 -- 기본은 심층, 경량 모드는 `--light`로 선택.

```text
cwf:retro            # 적응형 (기본은 심층)
cwf:retro --deep     # 전문가 렌즈 포함 전체 분석
cwf:retro --light    # 섹션 1-4 + 7만, 서브에이전트 없음
```

섹션: 기억할 만한 컨텍스트, 협업 선호도, 낭비 감소(5 Whys), 핵심 의사결정 분석(CDM), 전문가 렌즈(심층), 학습 자료(심층), 관련 스킬. 발견 사항을 프로젝트 수준 문서에 영속화.

전체 레퍼런스: [SKILL.md](plugins/cwf/skills/retro/SKILL.md)

### refactor

5가지 운영 모드를 갖춘 다중 모드 코드/스킬 리뷰.

```text
cwf:refactor                        # 모든 스킬 퀵 스캔
cwf:refactor --code [branch]        # 커밋 기반 정리
cwf:refactor --skill <name>         # 단일 스킬 심층 리뷰
cwf:refactor --skill --holistic     # 크로스 플러그인 분석
cwf:refactor --docs                 # 문서 일관성 리뷰
```

퀵 스캔은 구조적 검사를 실행합니다. 코드 정리는 커밋을 분석하여 안전한 리팩토링을 찾습니다(Kent Beck의 "Tidy First?"). 심층 리뷰는 프로그레시브 디스클로저 기준으로 평가합니다. 전체적 모드는 크로스 플러그인 패턴 이슈를 감지합니다. 문서 모드는 문서 간 일관성을 점검합니다.

전체 레퍼런스: [SKILL.md](plugins/cwf/skills/refactor/SKILL.md)

### handoff

프로젝트 상태와 산출물로부터 세션 또는 페이즈 핸드오프 문서를 생성합니다.

```text
cwf:handoff                # next-session.md 생성 + 등록
cwf:handoff --register     # .cwf/cwf-state.yaml에 세션 등록만
cwf:handoff --phase        # phase-handoff.md 생성 (HOW 컨텍스트)
```

세션 핸드오프는 작업 범위, 교훈, 미해결 항목을 다음 세션으로 전달합니다. 페이즈 핸드오프는 프로토콜, 규칙, 제약 조건을 다음 워크플로우 페이즈(HOW)로 전달하며, plan.md(WHAT)를 보완합니다. 이제 `next-session.md`에는 멘션만으로 실행 가능한 실행 계약도 포함되며, 베이스 브랜치 탈출(브랜치 게이트)과 의미 단위 커밋 정책을 함께 명시합니다.

전체 레퍼런스: [SKILL.md](plugins/cwf/skills/handoff/SKILL.md)

### ship

GitHub 워크플로우 자동화 -- 이슈 생성, PR, 머지 관리.

```text
cwf:ship                                   # 사용법 표시
cwf:ship issue [--base B] [--no-branch]    # 이슈 + 피처 브랜치 생성
cwf:ship pr [--base B] [--issue N] [--draft]  # PR 생성
cwf:ship merge [--squash|--merge|--rebase]    # 승인된 PR 머지
cwf:ship status                            # 이슈, PR, 체크 상태 조회
```

세션 컨텍스트(plan.md, lessons.md, retro.md)에서 자동으로 이슈 본문과 PR 본문을 조합합니다. CDM 분석, 결정 테이블, 성공 기준 체크리스트를 PR에 포함합니다. 인간 판단이 불필요한 경우 자율 머지를 지원합니다.

전체 레퍼런스: [SKILL.md](plugins/cwf/skills/ship/SKILL.md)

### review

6명 병렬 리뷰어에 의한 범용 리뷰 -- 내러티브 판정.

```text
cwf:review                 # 코드 리뷰 (기본: code mode)
cwf:review --mode code     # 코드 리뷰 (명시적 code mode)
cwf:review --mode plan     # 계획/스펙 리뷰
cwf:review --mode clarify  # 요구사항 리뷰
```

2명 내부 리뷰어(Security, UX/DX) + 2명 외부 CLI 리뷰어(Codex, Gemini) + 2명 도메인 전문가가 병렬로 리뷰합니다. 외부 CLI가 없으면 Task 에이전트로 우아하게 폴백합니다. 판정은 Pass / Conditional Pass / Revise 세 단계입니다. plan.md의 BDD 성공 기준을 자동 검증합니다.

전체 레퍼런스: [SKILL.md](plugins/cwf/skills/review/SKILL.md)

### hitl

브랜치 diff를 human-in-the-loop 방식으로 청크 리뷰하며, 재개 가능한 상태와 룰 전파를 지원합니다.

```text
cwf:hitl                             # 기본 베이스(upstream/main) 기준으로 시작
cwf:hitl --base <branch>             # 명시적 베이스 브랜치 기준 리뷰
cwf:hitl --resume                    # 저장된 커서에서 재개
cwf:hitl --rule "<rule text>"        # 남은 큐에 적용할 리뷰 룰 추가
cwf:review --human                   # 호환 alias (내부적으로 cwf:hitl로 라우팅)
```

상태는 `.cwf/hitl/sessions/`(`state.yaml`, `rules.yaml`, `queue.json`, `events.log`)에 저장합니다. [`.cwf/cwf-state.yaml`](.cwf/cwf-state.yaml)에는 활성 HITL 세션 포인터 메타데이터만 저장합니다.

전체 레퍼런스: [SKILL.md](plugins/cwf/skills/hitl/SKILL.md)

### run

단계 게이트를 포함한 전체 CWF 파이프라인 자동 체이닝.

```text
cwf:run <task description>           # 처음부터 전체 파이프라인 실행
cwf:run --from impl                  # impl 단계부터 재개
cwf:run --skip review-plan,retro     # 특정 단계 건너뛰기
```

기본 흐름은 gather → clarify → plan → review(plan) → impl → review(code) → retro → ship이며, 구현 전 단계는 인간 게이트를 두고 구현 이후 단계는 기본적으로 자동 연쇄 실행되며 `ship` 단계는 사용자 확인 게이트를 둡니다.

전체 레퍼런스: [SKILL.md](plugins/cwf/skills/run/SKILL.md)

### setup

CWF 초기 설정.

```text
cwf:setup                # 전체 설정 (훅 + 도구 + repo-index 생성 여부 질문)
cwf:setup --hooks        # 훅 그룹 선택만
cwf:setup --tools        # 외부 도구 감지만
cwf:setup --codex        # Codex 사용자 스코프(~/.agents/*)에 CWF 스킬/레퍼런스 연결
cwf:setup --codex-wrapper # 세션 로그 자동 동기화를 위한 codex wrapper 설치
cwf:setup --cap-index    # CWF capability 인덱스만 생성/갱신 (.cwf/indexes/cwf-index.md)
cwf:setup --repo-index   # 저장소 인덱스 명시적 생성/갱신
cwf:setup --repo-index --target agents # AGENTS 기반 저장소용 AGENTS.md 관리 블록
```

대화형 훅 그룹 토글, 외부 AI CLI 및 API 키 감지(Codex, Gemini, Tavily, Exa), 선택적 Codex 연동(스킬 + wrapper), 선택적 인덱스 생성을 제공합니다. CWF capability 인덱스는 `cwf:setup --cap-index`로 명시적으로 생성합니다. 저장소 인덱스 재생성은 `cwf:setup --repo-index --target agents`로 [AGENTS.md](AGENTS.md) 관리 블록을 갱신합니다.

전체 레퍼런스: [SKILL.md](plugins/cwf/skills/setup/SKILL.md)

### Codex 연동

Codex CLI가 설치되어 있다면 다음 설정을 권장합니다.

```bash
cwf:setup --codex
cwf:setup --codex-wrapper
```

적용되는 내용:
- `~/.agents/skills/*`, `~/.agents/references`를 로컬 CWF에 심링크 (최신 파일 자동 반영)
- `~/.local/bin/codex` wrapper 설치 + PATH 업데이트(`~/.zshrc`, `~/.bashrc`)
- 이후 `codex` 실행 시 세션 markdown 로그가 `.cwf/prompt-logs/sessions/`에 `*.codex.md` 형식으로 자동 동기화
- 동기화 대상은 현재 실행에서 갱신된 세션으로 우선 고정되어, 같은 cwd에서 잘못된 세션 export를 줄입니다
- raw JSONL 복사는 기본 비활성(옵션 `--raw`)이며, raw export 시에도 민감정보 마스킹(redaction)이 적용됩니다

검증:

```bash
bash scripts/codex/install-wrapper.sh --status
type -a codex
```

기존 세션 로그를 일괄 마스킹하려면:

```bash
bash scripts/codex/redact-session-logs.sh
```

설치 후 새 셸을 열거나 `source ~/.zshrc`를 실행하세요. `codex`를 호출하는 alias(예: `codexyolo='codex ...'`)도 동일하게 wrapper를 사용합니다.

## 훅

CWF는 자동으로 실행되는 7개 훅 그룹을 포함합니다. 모두 기본 활성화되어 있으며, `cwf:setup --hooks`로 개별 그룹을 토글할 수 있습니다.

| 그룹 | 훅 유형 | 하는 일 |
|------|---------|---------|
| `attention` | Notification, Pre/PostToolUse | 유휴 상태 및 AskUserQuestion 시 Slack 알림 |
| `log` | Stop, SessionEnd | 대화 턴을 마크다운으로 자동 기록 |
| `read` | PreToolUse -> Read | 파일 크기 인식 읽기 가드 (500줄 이상 경고, 2000줄 이상 차단) |
| `lint_markdown` | PostToolUse -> Write\|Edit | 마크다운 린트 + 로컬 링크 검증 -- 린트 위반 시 자동 수정 유도, 깨진 링크 비동기 보고 |
| `lint_shell` | PostToolUse -> Write\|Edit | 셸 스크립트용 ShellCheck 검증 |
| `websearch_redirect` | PreToolUse -> WebSearch | Claude의 WebSearch를 `cwf:gather --search`로 리다이렉트 |
| `compact_recovery` | SessionStart -> compact | auto-compact 후 컨텍스트 복구를 위해 라이브 세션 상태 주입 |

## 설정

셸 프로파일(`~/.zshrc` 또는 `~/.bashrc`)에 환경 변수를 설정하세요. 레거시 하위호환으로 `~/.claude/.env`도 계속 지원합니다.

### Slack 알림 (attention 훅)

```bash
SLACK_BOT_TOKEN="xoxb-your-bot-token"       # chat:write + im:write 스코프를 가진 Slack App
SLACK_CHANNEL_ID="D0123456789"               # 봇 DM 채널 ID (또는 C...로 시작하는 채널 ID)
CLAUDE_CORCA_ATTENTION_DELAY=30              # AskUserQuestion 알림 지연 시간 (초)
```

레거시 웹훅 설정(스레딩 없음)은 `SLACK_WEBHOOK_URL`을 대신 설정하세요.

### 검색 API (gather 스킬)

```bash
TAVILY_API_KEY="tvly-..."                    # 웹 검색 및 URL 추출 (https://app.tavily.com)
EXA_API_KEY="..."                            # 코드 검색 (https://dashboard.exa.ai)
```

### Gather 출력

```bash
CLAUDE_CORCA_GATHER_CONTEXT_OUTPUT_DIR="./gathered"  # 기본 출력 디렉토리
```

### Smart-read 임계값

```bash
CLAUDE_CORCA_SMART_READ_WARN_LINES=500      # 이 줄 수 이상이면 경고 표시 (기본값: 500)
CLAUDE_CORCA_SMART_READ_DENY_LINES=2000     # 이 줄 수 이상이면 전체 읽기 차단 (기본값: 2000)
```

### 프롬프트 로거

```bash
CLAUDE_CORCA_PROMPT_LOGGER_DIR="/custom/path"  # 출력 디렉토리 (기본값: {cwd}/.cwf/prompt-logs/sessions)
CLAUDE_CORCA_PROMPT_LOGGER_ENABLED=false       # 로깅 비활성화 (기본값: true)
CLAUDE_CORCA_PROMPT_LOGGER_TRUNCATE=20         # 축약 임계값 (줄 수, 기본값: 10)
```

## 라이선스

MIT
