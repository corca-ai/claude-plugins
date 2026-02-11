# CWF (Corca Workflow Framework)

[English](README.md)

구조화된 개발 세션을 반복 가능한 워크플로우로 전환하는 Claude Code 플러그인입니다 -- 컨텍스트 수집부터 회고 분석까지. [Corca](https://www.corca.ai/)에서 [AI-Native Product Team](AI_NATIVE_PRODUCT_TEAM.ko.md)을 위해 유지보수합니다.

## 왜 CWF인가?

AI 코딩 세션은 모든 경계에서 컨텍스트를 잃습니다. 세션이 끝나면 다음 세션은 처음부터 시작합니다. 요구사항이 명확화에서 구현으로 넘어갈 때 프로토콜과 제약 조건이 잊혀집니다. 5개 스킬 시스템을 위해 작성된 품질 기준은 시스템이 9개로 성장하면 조용히 무의미해집니다.

CWF는 11개 스킬에 걸쳐 조합되는 6가지 빌딩 블록 개념으로 이 문제를 해결합니다. 11개의 독립된 도구가 아니라, 각 스킬이 동일한 기반 행동 패턴을 동기화하는 하나의 통합 플러그인입니다 -- 전문가 자문은 요구사항 명확화와 세션 회고 모두에서 사각지대를 드러내고, 티어 분류는 의사결정을 일관되게 증거나 인간에게 라우팅하며, 에이전트 오케스트레이션은 리서치부터 구현까지 작업을 병렬화합니다.

결과: 하나의 플러그인(`cwf`), 11개 스킬, 7개 훅 그룹. 컨텍스트가 세션 경계를 넘어 유지됩니다. 의사결정에 증거가 뒷받침됩니다. 품질 기준이 시스템과 함께 진화합니다.

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
| 10 | [setup](#setup) | `cwf:setup` | 훅 그룹 설정, 도구 감지, 프로젝트 인덱스 선택 생성 |
| 11 | [update](#update) | `cwf:update` | CWF 플러그인 업데이트 확인 및 적용 |

**개념 조합**: gather, clarify, plan, impl, retro, refactor는 모두 에이전트 오케스트레이션을 동기화합니다. clarify는 가장 풍부한 조합으로, 전문가 자문, 티어 분류, 에이전트 오케스트레이션, 결정 포인트를 하나의 워크플로우에서 동기화합니다. handoff는 핸드오프 개념의 주요 구현체입니다. refactor는 전체적 모드에서 출처 추적을 활성화합니다. review는 전문가 자문과 출처 추적을 활용한 다관점 리뷰를 수행합니다.

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
cwf:update
```

### 독립 플러그인 (레거시)

CWF는 독립 플러그인(gather-context, clarify, retro, refactor, attention-hook, smart-read, prompt-logger, markdown-guard)의 모든 기능을 통합합니다. 독립 플러그인을 사용 중이라면 제거하고 `cwf`를 설치하세요. 독립 플러그인은 하위 호환을 위해 마켓플레이스에 남아 있지만 새로운 기능은 추가되지 않습니다. `plan-and-lessons` 플러그인은 폐기되었습니다 -- 플랜 모드 훅은 세션 상태 기반 컨텍스트 관리로 대체되었습니다.

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

병렬 선행 사례 + 코드베이스 리서치 -> 단계, 파일, 성공 기준(BDD + 정성적)이 포함된 구조화된 계획 -> `prompt-logs/` 세션 디렉토리에 저장.

전체 레퍼런스: [SKILL.md](plugins/cwf/skills/plan/SKILL.md)

### impl

구조화된 계획에 기반한 구현 오케스트레이션.

```text
cwf:impl                    # 가장 최근 plan.md 자동 감지
cwf:impl <path/to/plan.md>  # 명시적 계획 경로
```

계획 로드(+ 페이즈 핸드오프가 있으면 함께) -> 도메인과 의존성별 작업 항목 분해 -> 적응형 에이전트 팀 구성(1-4명) -> 병렬 배치 실행 -> BDD 기준 대비 검증.

전체 레퍼런스: [SKILL.md](plugins/cwf/skills/impl/SKILL.md)

### retro

적응형 세션 회고 -- 기본은 경량, 요청 시 심층.

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
cwf:handoff --register     # cwf-state.yaml에 세션 등록만
cwf:handoff --phase        # phase-handoff.md 생성 (HOW 컨텍스트)
```

세션 핸드오프는 작업 범위, 교훈, 미해결 항목을 다음 세션으로 전달합니다. 페이즈 핸드오프는 프로토콜, 규칙, 제약 조건을 다음 워크플로우 페이즈(HOW)로 전달하며, plan.md(WHAT)를 보완합니다.

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
cwf:review                 # 코드 리뷰 (기본)
cwf:review --mode plan     # 계획/스펙 리뷰
cwf:review --mode clarify  # 요구사항 리뷰
```

2명 내부 리뷰어(Security, UX/DX) + 2명 외부 CLI 리뷰어(Codex, Gemini) + 2명 도메인 전문가가 병렬로 리뷰합니다. 외부 CLI가 없으면 Task 에이전트로 우아하게 폴백합니다. 판정은 Pass / Conditional Pass / Revise 세 단계입니다. plan.md의 BDD 성공 기준을 자동 검증합니다.

전체 레퍼런스: [SKILL.md](plugins/cwf/skills/review/SKILL.md)

### setup

CWF 초기 설정.

```text
cwf:setup                # 전체 설정 (훅 + 도구 + 인덱스 생성 여부 질문)
cwf:setup --hooks        # 훅 그룹 선택만
cwf:setup --tools        # 외부 도구 감지만
cwf:setup --codex        # Codex 사용자 스코프(~/.agents/*)에 CWF 스킬/레퍼런스 연결
cwf:setup --codex-wrapper # 세션 로그 자동 동기화를 위한 codex wrapper 설치
cwf:setup --index        # 프로그레시브 인덱스 명시적 생성/갱신
cwf:setup --index --target file   # cwf-index.md만 (기본값)
cwf:setup --index --target agents # AGENTS.md 관리 블록만
cwf:setup --index --target both   # cwf-index.md + AGENTS.md 블록
```

대화형 훅 그룹 토글, 외부 AI CLI 및 API 키 감지(Codex, Gemini, Tavily, Exa), 선택적 Codex 연동(스킬 + wrapper), 선택적 프로그레시브 디스클로저 인덱스 생성을 제공합니다. 전체 setup에서는 인덱스 생성을 물어보고, 기존 `cwf-index.md`는 덮어쓰지 않습니다. 명시적 재생성은 `cwf:setup --index`를 사용하세요. 인덱스 출력 대상은 `cwf-index.md`, `AGENTS.md` 관리 블록, 또는 둘 다를 선택할 수 있습니다.

전체 레퍼런스: [SKILL.md](plugins/cwf/skills/setup/SKILL.md)

### 에이전트 엔트리 파일

- `AGENTS.md`는 공통 크로스-에이전트 엔트리포인트입니다(Codex, Claude Code, 호환 런타임).
- `CLAUDE.md`는 `AGENTS.md`를 참조하는 Claude 전용 thin adapter입니다.
- 프로그레시브 디스클로저 인덱스 기본 출력은 `cwf-index.md`이며, `cwf:setup --index --target agents|both`로 `AGENTS.md` 관리 블록에도 반영할 수 있습니다.

### Codex 연동

Codex CLI가 설치되어 있다면 다음 설정을 권장합니다.

```bash
cwf:setup --codex
cwf:setup --codex-wrapper
```

적용되는 내용:
- `~/.agents/skills/*`, `~/.agents/references`를 로컬 CWF에 심링크 (최신 파일 자동 반영)
- `~/.local/bin/codex` wrapper 설치 + PATH 업데이트(`~/.zshrc`, `~/.bashrc`)
- 이후 `codex` 실행 시 세션 로그가 `prompt-logs/sessions-codex/`로 자동 동기화
- 동기화되는 markdown/raw 로그는 자동으로 민감정보(API 키/토큰) 마스킹(redaction) 처리

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

### update

CWF 플러그인 업데이트 확인 및 적용.

```text
cwf:update               # 새 버전이 있으면 확인 + 업데이트
cwf:update --check       # 버전 확인만
```

전체 레퍼런스: [SKILL.md](plugins/cwf/skills/update/SKILL.md)

## 훅

CWF는 자동으로 실행되는 7개 훅 그룹을 포함합니다. 모두 기본 활성화되어 있으며, `cwf:setup --hooks`로 개별 그룹을 토글할 수 있습니다.

| 그룹 | 훅 유형 | 하는 일 |
|------|---------|---------|
| `attention` | Notification, Pre/PostToolUse | 유휴 상태 및 AskUserQuestion 시 Slack 알림 |
| `log` | Stop, SessionEnd | 대화 턴을 마크다운으로 자동 기록 |
| `read` | PreToolUse -> Read | 파일 크기 인식 읽기 가드 (500줄 이상 경고, 2000줄 이상 차단) |
| `lint_markdown` | PostToolUse -> Write\|Edit | 마크다운 검증 -- 린트 위반 시 자동 수정 유도 |
| `lint_shell` | PostToolUse -> Write\|Edit | 셸 스크립트용 ShellCheck 검증 |
| `websearch_redirect` | PreToolUse -> WebSearch | Claude의 WebSearch를 `cwf:gather --search`로 리다이렉트 |
| `compact_recovery` | SessionStart -> compact | auto-compact 후 컨텍스트 복구를 위해 라이브 세션 상태 주입 |

알림 예시:

<img src="assets/attention-hook-normal-response.png" alt="Slack 알림 -- 일반 응답" width="600">

<img src="assets/attention-hook-AskUserQuestion.png" alt="Slack 알림 -- AskUserQuestion" width="600">

## 설정

`~/.claude/.env`에 환경 변수를 설정하세요:

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
CLAUDE_CORCA_PROMPT_LOGGER_DIR="/custom/path"  # 출력 디렉토리 (기본값: {cwd}/prompt-logs/sessions)
CLAUDE_CORCA_PROMPT_LOGGER_ENABLED=false       # 로깅 비활성화 (기본값: true)
CLAUDE_CORCA_PROMPT_LOGGER_TRUNCATE=20         # 축약 임계값 (줄 수, 기본값: 10)
```

## 삭제된 플러그인

다음 플러그인들은 마켓플레이스에서 삭제되었습니다.

### v3.0.0에서 삭제

모든 독립 플러그인이 CWF로 통합되었습니다. 소스 코드는 커밋 `238f82d`에서 참조할 수 있습니다.

| 삭제된 플러그인 | 대체 | 명령어 매핑 |
|------------|------|------|
| `gather-context` | [gather](#gather) | `/gather-context <url>` -> `cwf:gather <url>` |
| `clarify` | [clarify](#clarify) | `/clarify <req>` -> `cwf:clarify <req>` |
| `retro` | [retro](#retro) | `/retro` -> `cwf:retro` |
| `refactor` | [refactor](#refactor) | `/refactor` -> `cwf:refactor` |
| `attention-hook` | [attention 훅 그룹](#훅) | (훅으로 자동 실행) |
| `smart-read` | [read 훅 그룹](#훅) | (훅으로 자동 실행) |
| `prompt-logger` | [log 훅 그룹](#훅) | (훅으로 자동 실행) |
| `markdown-guard` | [lint_markdown 훅 그룹](#훅) | (훅으로 자동 실행) |

### v2.0.0에서 삭제

| 삭제된 플러그인 | 대체 | 명령어 매핑 |
|------------|------|------|
| `suggest-tidyings` | [refactor](#refactor) `--code` | `/suggest-tidyings` -> `cwf:refactor --code` |
| `deep-clarify` | [clarify](#clarify) | `/deep-clarify <req>` -> `cwf:clarify <req>` |
| `interview` | [clarify](#clarify) | `/interview <topic>` -> `cwf:clarify <req>` |
| `web-search` | [gather](#gather) | `/web-search <q>` -> `cwf:gather --search <q>` |

### v1.8.0에서 삭제

| 삭제된 플러그인 | 대체 |
|------------|------|
| `g-export` | [gather](#gather) (Google Docs/Slides/Sheets 내장) |
| `slack-to-md` | [gather](#gather) (Slack 스레드 변환 내장) |
| `notion-to-md` | [gather](#gather) (Notion 페이지 변환 내장) |

## 라이선스

MIT
