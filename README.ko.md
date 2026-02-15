# CWF (Corca Workflow Framework)

[English](README.md)

구조화된 개발 세션을 컨텍스트 수집부터 회고 분석까지 반복 가능한 워크플로우로 전환하는 Claude Code 플러그인입니다. [Corca](https://www.corca.ai/)가 [AI-Native Product Team](AI_NATIVE_PRODUCT_TEAM.ko.md)을 위해 유지 관리합니다.

## 설치

### 빠른 시작

```bash
# 마켓플레이스 추가
claude plugin marketplace add https://github.com/corca-ai/claude-plugins.git

# CWF 설치
claude plugin install cwf@corca-plugins

# 스킬 및 훅 적용을 위해 Claude Code 재시작
```

### Codex 사용자(권장)

Codex CLI를 사용한다면 설치 직후 아래를 실행하세요.

```bash
cwf:setup --codex
cwf:setup --codex-wrapper
```

### 최신 버전으로 업데이트

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

v3.0.0부터 레거시 독립 플러그인은 마켓플레이스에서 제거되었습니다. 기존 독립 플러그인 설치가 있다면 제거하고 `cwf`를 설치하세요.

## 운영 원칙

### CWF의 역할

- 컨텍스트 수집, 요구사항 명확화, 계획, 구현, 리뷰, 회고, 핸드오프, 배포를 통합한 단일 워크플로우 플러그인(`cwf`)입니다.
- .cwf/cwf-state.yaml, 세션 로그 산출물, 훅을 통해 페이즈/세션 경계를 넘어 컨텍스트를 보존하는 상태 기반 워크플로우 시스템입니다.
- Expert Advisor, Tier Classification, Agent Orchestration, Decision Point, Handoff, Provenance라는 공통 개념으로 구성된 조합형 스킬 프레임워크입니다.

### CWF의 범위 밖

- 프로젝트별 엔지니어링 표준, CI 게이트, 사람의 제품 책임 의사결정을 대체하지 않습니다.
- 모든 결정을 완전히 자동화할 수 있다고 보장하지 않으며, 주관적 결정에는 여전히 사용자 확인이 필요합니다.
- 각 스킬이 분리된 범용 플러그인 묶음이 아니며, CWF 스킬은 의도적으로 상호 의존적으로 설계되어 있습니다.

### 가정

- 사용자는 .cwf/projects/, .cwf/cwf-state.yaml 같은 세션 산출물을 저장하고 활용할 수 있는 저장소에서 작업합니다.
- 사용자는 AGENTS.md에서 시작해 필요할 때 더 깊은 문서를 읽는 점진적 공개 방식에 동의합니다.
- 팀은 반복되는 품질 검사를 행동 기억에 의존하기보다 결정적 검증 스크립트로 관리하는 방식을 선호합니다.

### 주요 결정과 이유

1. **독립 플러그인 대신 통합 플러그인**
   - 이유: 페이즈 간 컨텍스트 손실과 프로토콜 드리프트를 방지하기 위해서입니다.
2. **구현 전 인간 게이트, 구현 후 자율 체이닝(`run`)**
   - 이유: 높은 판단이 필요한 결정은 사람의 통제 하에 두고, 범위가 확정된 이후에는 실행 속도를 유지하기 위해서입니다.
3. **파일 경로만 입력해도 시작되는 핸드오프 계약**
   - 이유: 세션 연속성을 결정적으로 만들고 시작 시 모호성을 줄이기 위해서입니다.
4. **개념/리뷰 기준에 대한 Provenance 점검**
   - 이유: 스킬/훅 인벤토리가 변경될 때 기준의 노후화를 탐지하기 위해서입니다.

위 항목은 CWF를 사용할 때 적용되는 운영 원칙입니다.

## 왜 CWF인가?

### 문제

AI 코딩 세션은 경계가 생길 때마다 컨텍스트를 잃습니다. 세션이 끝나면 다음 세션은 다시 처음부터 시작합니다. 요구사항이 명확화에서 구현으로 넘어갈 때 프로토콜과 제약 조건이 사라집니다. 5개 스킬 시스템을 기준으로 작성된 품질 기준은 시스템이 확장되면서 조용히 무의미해집니다.

### 접근

CWF는 13개 스킬 전반에 조합되는 6가지 빌딩 블록 개념으로 이 문제를 해결합니다. 각 스킬은 동일한 기반 행동 패턴을 공유하며, Expert Advisor는 요구사항 명확화와 세션 회고 모두에서 사각지대를 드러내고, Tier Classification은 의사결정을 일관되게 증거 또는 사람에게 라우팅하며, Agent Orchestration은 리서치부터 구현까지 작업을 병렬화합니다.

### 결과

결과: 하나의 플러그인(`cwf`), 13개 스킬, 7개 훅 그룹. 컨텍스트는 세션 경계를 넘어 유지되고, 의사결정은 증거 기반으로 이루어지며, 품질 기준은 시스템과 함께 진화합니다.

## 핵심 개념

CWF 스킬이 조합하는 6가지 재사용 가능한 행동 패턴입니다. 이를 이해하면 각 스킬이 무엇을 하는지뿐 아니라 왜 함께 작동하는지도 알 수 있습니다.

**전문가 자문 (Expert Advisor)** -- 대조되는 전문가 프레임워크를 도입해 사각지대를 줄입니다. 서로 다른 분석 렌즈를 가진 두 도메인 전문가가 문제를 독립적으로 평가하고, 의견 차이가 숨은 가정을 드러냅니다.

**티어 분류 (Tier Classification)** -- 의사결정을 적절한 권한으로 라우팅합니다. 코드베이스 증거(T1)와 베스트 프랙티스 합의(T2)는 자율적으로 해결하고, 진정으로 주관적인 결정(T3)만 사람에게 전달합니다.

**에이전트 조율 (Agent Orchestration)** -- 품질을 희생하지 않고 작업을 병렬화합니다. 조율자가 복잡도를 평가해 필요한 최소 에이전트를 구성하고, 의존성을 지키는 배치로 실행한 뒤 결과를 종합합니다.

**결정 포인트 (Decision Point)** -- 모호성을 명시적으로 포착합니다. 누군가가 결정을 내리기 전에 요구사항을 구체적 질문으로 분해해, 모든 선택에 증거와 근거가 기록되도록 합니다.

**핸드오프 (Handoff)** -- 경계를 넘어 컨텍스트를 보존합니다. 세션 핸드오프는 작업 범위와 교훈을, 페이즈 핸드오프는 프로토콜과 제약 조건을 전달합니다. 다음 에이전트는 백지 상태가 아니라 맥락을 가진 상태로 시작합니다.

**출처 추적 (Provenance)** -- 기준의 노후화를 감지합니다. 참조 문서는 작성 당시 시스템 상태 메타데이터를 포함하고, 스킬은 오래된 기준을 적용하기 전에 이를 확인합니다.

## 워크플로우

CWF 스킬은 컨텍스트 수집에서 학습 추출까지 자연스러운 흐름을 따릅니다:

```text
gather → clarify → plan → impl → retro
```

| # | 스킬 | 트리거 | 하는 일 |
|---|------|--------|---------|
| 1 | [gather](#gather) | `cwf:gather` | 정보 수집 -- URL, 웹 검색, 로컬 코드 탐색 |
| 2 | [clarify](#clarify) | `cwf:clarify` | 모호한 요구사항을 리서치 + 티어 분류로 정밀한 스펙으로 전환 |
| 3 | [plan](#plan) | `cwf:plan` | 리서치 기반 구현 계획과 BDD 성공 기준 작성 |
| 4 | [impl](#impl) | `cwf:impl` | 계획에 따른 병렬 구현 조율 |
| 5 | [retro](#retro) | `cwf:retro` | CDM 분석과 전문가 렌즈를 통한 지속 가능한 교훈 추출 |
| 6 | [refactor](#refactor) | `cwf:refactor` | 다중 모드 코드/스킬 리뷰 -- 스캔, 정리, 심층 리뷰, 전체적 분석 |
| 7 | [handoff](#handoff) | `cwf:handoff` | 세션 또는 페이즈 핸드오프 문서 생성 |
| 8 | [ship](#ship) | `cwf:ship` | GitHub 워크플로우 자동화 -- 이슈 생성, PR, 머지 관리 |
| 9 | [review](#review) | `cwf:review` | 6명 병렬 리뷰어를 통한 다각도 리뷰 |
| 10 | [hitl](#hitl) | `cwf:hitl` | 재개 가능한 상태 저장과 룰 전파를 갖춘 사람 참여형 변경사항/청크 리뷰 |
| 11 | [run](#run) | `cwf:run` | gather부터 ship까지 전체 파이프라인을 단계 게이트와 함께 조율 |
| 12 | [setup](#setup) | `cwf:setup` | 훅 그룹 설정, 도구 감지, 프로젝트 인덱스 선택 생성 |
| 13 | [update](#update) | `cwf:update` | CWF 플러그인 업데이트 확인 및 적용 |

**개념 조합**: `gather`, `clarify`, `plan`, `impl`, `retro`, `refactor`, `review`, `hitl`, `run`은 모두 에이전트 조율 개념을 공유합니다. `clarify`는 전문가 자문, 티어 분류, 에이전트 조율, 결정 포인트를 하나의 워크플로우에서 함께 사용합니다. `review`와 `hitl`은 서로 다른 검토 단위(병렬 리뷰어 vs 청크 기반 상호작용 루프)에서 사람의 판단과 구조화된 리뷰 조율을 결합합니다. `handoff`는 핸드오프 개념의 주요 구현체이며, `refactor`는 전체 분석 모드에서 출처 추적을 활성화합니다.

## 스킬 레퍼런스

### [gather](plugins/cwf/skills/gather/SKILL.md)

통합 정보 수집 -- URL, 웹 검색, 로컬 코드 탐색.

```text
cwf:gather <url>                  # 서비스 자동 감지 (Google/Slack/Notion/GitHub/웹)
cwf:gather --search <query>       # 웹 검색 (Tavily)
cwf:gather --search code <query>  # 코드 검색 (Exa)
cwf:gather --local <topic>        # 로컬 코드베이스 탐색
```

Google Docs/Slides/Sheets, Slack 스레드, Notion 페이지, GitHub PR/이슈, 일반 웹 URL을 자동 감지합니다. 내장 WebSearch 리다이렉트 훅이 Claude의 WebSearch를 `cwf:gather --search`로 라우팅합니다.

### [clarify](plugins/cwf/skills/clarify/SKILL.md)

리서치 우선 요구사항 명확화와 자율적 의사결정.

```text
cwf:clarify <requirement>          # 리서치 기반 (기본)
cwf:clarify <requirement> --light  # 직접 질의응답, 서브에이전트 없음
```

기본 모드: 요구사항을 결정 포인트로 분해 → 병렬 리서치(코드베이스 + 웹) → 전문가 분석 → 티어 분류(T1/T2 자동 결정, T3는 사람에게 질문) → 이유를 반복 탐색하는 방식으로 지속 질문. 라이트 모드: 서브에이전트 없이 질의응답을 반복합니다.

### [plan](plugins/cwf/skills/plan/SKILL.md)

병렬 리서치와 BDD 성공 기준을 갖춘 에이전트 지원 계획 작성.

```text
cwf:plan <task description>
```

병렬 선행 사례 + 코드베이스 리서치 → 단계, 파일, 성공 기준(BDD + 정성적)을 포함한 구조화된 계획 → `.cwf/projects/` 세션 디렉토리에 저장. 권장 흐름: 구현 전에 `cwf:review --mode plan`을 실행해 계획 단계 우려사항을 먼저 해소합니다.

### [impl](plugins/cwf/skills/impl/SKILL.md)

구조화된 계획에 기반한 구현 조율.

```text
cwf:impl                    # 가장 최근 plan.md 자동 감지
cwf:impl <path/to/plan.md>  # 명시적 계획 경로
```

계획을 로드하고(+ 페이즈 핸드오프가 있으면 함께), 도메인/의존성별 작업 항목으로 분해한 뒤, 적응형 에이전트 팀(1-4명)을 구성해 병렬 배치로 실행하고 BDD 기준으로 검증합니다. 일반 순서: `cwf:plan` → `cwf:review --mode plan` → `cwf:impl` → `cwf:review --mode code`.

### [retro](plugins/cwf/skills/retro/SKILL.md)

적응형 세션 회고 -- 기본은 심층, 경량 모드는 `--light`로 선택.

```text
cwf:retro            # 적응형 (기본은 심층)
cwf:retro --deep     # 전문가 렌즈 포함 전체 분석
cwf:retro --light    # 섹션 1-4 + 7만, 서브에이전트 없음
```

섹션: 기억할 만한 컨텍스트, 협업 선호도, 낭비 감소(5 Whys), 핵심 의사결정 분석(CDM), 전문가 렌즈(심층), 학습 자료(심층), 관련 스킬. 발견 사항은 프로젝트 수준 문서에 기록해 보존합니다.

### [refactor](plugins/cwf/skills/refactor/SKILL.md)

5가지 운영 모드를 갖춘 다중 모드 코드/스킬 리뷰.

```text
cwf:refactor                        # 모든 스킬 퀵 스캔
cwf:refactor --code [branch]        # 커밋 기반 정리
cwf:refactor --skill <name>         # 단일 스킬 심층 리뷰
cwf:refactor --skill --holistic     # 크로스 플러그인 분석
cwf:refactor --docs                 # 문서 일관성 리뷰
```

퀵 스캔은 구조적 검사를 실행합니다. 코드 정리는 커밋을 분석해 안전한 리팩토링을 찾습니다(Kent Beck의 "Tidy First?"). 심층 리뷰는 점진적 공개 원칙 기준으로 평가합니다. `--holistic` 모드는 크로스 플러그인 패턴 이슈를 감지합니다. `--docs` 모드는 문서 간 일관성을 점검합니다.

### [handoff](plugins/cwf/skills/handoff/SKILL.md)

프로젝트 상태와 산출물로부터 세션 또는 페이즈 핸드오프 문서를 생성합니다.

```text
cwf:handoff                # next-session.md 생성 + 등록
cwf:handoff --register     # .cwf/cwf-state.yaml에 세션 등록만
cwf:handoff --phase        # phase-handoff.md 생성 (작동 방식 컨텍스트)
```

세션 핸드오프는 작업 범위, 교훈, 미해결 항목을 다음 세션으로 전달합니다. 페이즈 핸드오프는 프로토콜, 규칙, 제약 조건을 다음 워크플로우 단계의 작동 방식으로 전달하며, 계획 문서의 작업 내용 범위를 보완합니다. `next-session.md`에는 파일 경로만 입력해도 바로 시작할 수 있는 실행 계약이 포함되며, 베이스 브랜치 탈출(브랜치 게이트)과 의미 단위 커밋 정책도 함께 담습니다.

### [ship](plugins/cwf/skills/ship/SKILL.md)

GitHub 워크플로우 자동화 -- 이슈 생성, PR, 머지 관리.

```text
cwf:ship                                   # 사용법 표시
cwf:ship issue [--base B] [--no-branch]    # 이슈 + 피처 브랜치 생성
cwf:ship pr [--base B] [--issue N] [--draft]  # PR 생성
cwf:ship merge [--squash|--merge|--rebase]    # 승인된 PR 머지
cwf:ship status                            # 이슈, PR, 체크 상태 조회
```

세션 컨텍스트(`plan.md`, `lessons.md`, `retro.md`)를 바탕으로 이슈/PR 본문을 구성하며, 머지 의사결정을 위한 CDM/결정 요약, 검증 체크리스트, 사람 판단 가드레일을 포함합니다.

### [review](plugins/cwf/skills/review/SKILL.md)

6명 병렬 리뷰어가 수행하는 다각도 리뷰.

```text
cwf:review                 # 코드 리뷰 (기본)
cwf:review --mode code     # 코드 리뷰 (명시적)
cwf:review --mode clarify  # 요구사항 리뷰
cwf:review --mode plan     # 계획/스펙 리뷰
```

2명 내부 리뷰어(Security, UX/DX)는 Task agents로, 2명 외부 리뷰어(Codex, Gemini)는 CLI로, 2명 도메인 전문가는 Task agents로 병렬 리뷰합니다. 외부 CLI를 사용할 수 없을 때는 우아하게 대체 경로로 전환합니다.

### [hitl](plugins/cwf/skills/hitl/SKILL.md)

브랜치 diff를 사람 참여형 방식으로 청크 리뷰하며, 재개 가능한 상태와 룰 전파를 지원합니다.

```text
cwf:hitl                             # 기본 베이스(upstream/main) 기준으로 시작
cwf:hitl --base <branch>             # 명시적 베이스 브랜치 기준 리뷰
cwf:hitl --resume                    # 저장된 커서에서 재개
cwf:hitl --rule "<rule text>"        # 남은 큐에 적용할 리뷰 룰 추가
cwf:review --human                   # 호환 별칭 (내부적으로 cwf:hitl로 라우팅)
```

상태는 .cwf/hitl/sessions/(state.yaml, rules.yaml, queue.json, fix-queue.yaml, events.log)에 저장합니다. .cwf/cwf-state.yaml에는 활성 HITL 세션 포인터 메타데이터만 저장합니다.

### [run](plugins/cwf/skills/run/SKILL.md)

단계 게이트를 포함한 전체 CWF 파이프라인 자동 체이닝.

```text
cwf:run <task description>           # 처음부터 전체 파이프라인 실행
cwf:run --from impl                  # impl 단계부터 재개
cwf:run --skip review-plan,retro     # 특정 단계 건너뛰기
```

기본 흐름은 gather → clarify → plan → review(plan) → impl → review(code) → retro → ship이며, 구현 전에는 인간 게이트를 두고 구현 후에는 기본적으로 자동 체이닝하며 `ship`에서 사용자 확인을 받습니다.

### [setup](plugins/cwf/skills/setup/SKILL.md)

CWF 초기 설정.

```text
cwf:setup                # 전체 설정 (훅 + 도구 + repo-index 생성 여부 질문)
cwf:setup --hooks        # 훅 그룹 선택만
cwf:setup --tools        # 외부 도구 감지만
cwf:setup --env          # 환경 변수 마이그레이션/부트스트랩만
cwf:setup --codex        # Codex 사용자 스코프(~/.agents/*)에 CWF 스킬/레퍼런스 연결
cwf:setup --codex-wrapper # 세션 로그 자동 동기화를 위한 codex wrapper 설치
cwf:setup --cap-index    # CWF capability 인덱스만 생성/갱신 (.cwf/indexes/cwf-index.md)
cwf:setup --repo-index   # 저장소 인덱스 명시적 생성/갱신
cwf:setup --repo-index --target agents # AGENTS 기반 저장소용 AGENTS.md 관리 블록
```

대화형 훅 그룹 토글, 외부 AI CLI 및 API 키 감지(Codex, Gemini, Tavily, Exa), 대화형 환경 변수 마이그레이션/부트스트랩(레거시 키를 표준 `CWF_*`로 변환), 선택적 Codex 연동(스킬 + wrapper), 선택적 인덱스 생성을 제공합니다. CWF capability 인덱스 생성은 `cwf:setup --cap-index`로 명시적으로 수행합니다. 저장소 인덱스 재생성은 `cwf:setup --repo-index --target agents`를 통해 AGENTS.md 관리 블록을 갱신합니다.

### [update](plugins/cwf/skills/update/SKILL.md)

CWF 플러그인 업데이트를 확인하고 적용합니다.

```text
cwf:update               # 새 버전이 있으면 확인 + 업데이트
cwf:update --check       # 버전 확인만
```

### Codex 연동

Codex CLI가 설치되어 있다면 다음 설정을 권장합니다.

```bash
cwf:setup --codex
cwf:setup --codex-wrapper
```

적용되는 내용:
- `~/.agents/skills/*`, `~/.agents/references`를 로컬 CWF에 심링크 (최신 파일 자동 반영)
- `~/.local/bin/codex` wrapper 설치 + PATH 업데이트(`~/.zshrc`, `~/.bashrc`)
- 이후 `codex` 실행 시 세션 markdown 로그가 `.cwf/projects/sessions/`에 `*.codex.md` 형식으로 자동 동기화
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

셸 프로파일(`~/.zshrc` 또는 `~/.bashrc`)에 환경 변수를 설정하세요. 표준 변수는 `CWF_*`를 사용합니다(`TAVILY_API_KEY`, `EXA_API_KEY`는 예외).

```bash
# 필수 — Slack 알림(attention 훅)
SLACK_BOT_TOKEN="xoxb-your-bot-token"            # chat:write + im:write 스코프를 가진 Slack App
SLACK_CHANNEL_ID="D0123456789"                   # 봇 DM 채널 ID (또는 C...로 시작하는 채널 ID)
# SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."  # 선택: 웹훅 폴백(스레딩 없음)

# 필수 — 검색 API(gather)
TAVILY_API_KEY="tvly-..."                        # 웹 검색 및 URL 추출 (https://app.tavily.com)
EXA_API_KEY="..."                                # 코드 검색 (https://dashboard.exa.ai)

# 선택 오버라이드 — attention
CWF_ATTENTION_DELAY=45                           # 기본값: 30
CWF_ATTENTION_REPLY_BROADCAST=true               # 기본값: false
CWF_ATTENTION_TRUNCATE=20                        # 기본값: 10
CWF_ATTENTION_USER_ID="U0123456789"              # 기본값: 미설정
# CWF_ATTENTION_USER_HANDLE="your-handle"        # 기본값: 미설정
# CWF_ATTENTION_PARENT_MENTION="<@U0123456789>"  # 기본값: 미설정

# 선택 오버라이드 — gather/read/session-log
CWF_GATHER_OUTPUT_DIR=".cwf/projects"               # 기본값: .cwf/projects
CWF_READ_WARN_LINES=700                             # 기본값: 500
CWF_READ_DENY_LINES=2500                            # 기본값: 2000
CWF_SESSION_LOG_DIR=".cwf/projects/sessions"        # 기본값: .cwf/projects/sessions
CWF_SESSION_LOG_ENABLED=false                       # 기본값: true
CWF_SESSION_LOG_TRUNCATE=20                         # 기본값: 10
CWF_SESSION_LOG_AUTO_COMMIT=true                    # 기본값: false

# 선택 오버라이드 — 아티팩트 경로(고급)
# CWF_ARTIFACT_ROOT=".cwf-data"                     # 기본값: .cwf
# CWF_PROJECTS_DIR=".cwf/projects"                  # 기본값: {CWF_ARTIFACT_ROOT}/projects
```

## 라이선스

MIT
