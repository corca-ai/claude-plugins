# corca-plugins

[English](README.md)

코르카에서 유지보수하는, [AI-Native Product Team](AI_NATIVE_PRODUCT_TEAM.ko.md)을 위한 Claude Code 플러그인 마켓플레이스입니다.

## 설치

### 1. Marketplace 추가 및 업데이트

```bash
claude plugin marketplace add https://github.com/corca-ai/claude-plugins.git
```

새 플러그인이 추가되거나 기존 플러그인이 업데이트되면, 먼저 마켓플레이스를 업데이트하세요:
```bash
claude plugin marketplace update corca-plugins
```

그 다음 필요한 플러그인을 설치하거나 업데이트합니다:
```bash
claude plugin install <plugin-name>@corca-plugins  # 새로 설치
claude plugin update <plugin-name>@corca-plugins   # 기존 플러그인 업데이트
```

설치/업데이트 후 Claude Code를 재시작하면 적용됩니다.

또는 설치 스크립트를 사용하여 카테고리별로 설치할 수 있습니다:
```bash
bash scripts/install.sh --all        # 전체 9개 플러그인
bash scripts/install.sh --workflow   # 워크플로우 단계 1-6만
bash scripts/install.sh --infra     # attention-hook + prompt-logger + markdown-guard
bash scripts/install.sh --context --clarify  # 단계 조합 가능
```

마켓플레이스와 설치된 **모든** 플러그인을 한번에 업데이트하려면:
```bash
bash scripts/update-all.sh
```

터미널 대신 Claude Code 내에서도 동일한 작업이 가능합니다:
```text
/plugin marketplace add corca-ai/claude-plugins
/plugin marketplace update
```

### 2. 플러그인 오버뷰

| 플러그인 | 유형 | 단계 | 설명 |
|---------|------|------|------|
| [gather-context](#gather-context) | Skill + Hook | 1. 컨텍스트 | 통합 정보 수집: URL 자동 감지, 웹 검색, 로컬 코드 탐색 |
| [clarify](#clarify) | Skill | 2. 명확화 | 통합 요구사항 명확화: 리서치 기반 또는 경량 Q&A |
| [smart-read](#smart-read) | Hook | 4. 구현 | 파일 크기 기반 지능적 읽기 강제 |
| [retro](#retro) | Skill | 5. 회고 | 적응형 세션 회고 — 기본은 경량, `--deep`으로 전문가 렌즈 포함 전체 분석 |
| [refactor](#refactor) | Skill | 6. 리팩토링 | 다중 모드 코드/스킬 리뷰: 퀵 스캔, 심층 리뷰, 티디잉, 문서 검사 |
| [attention-hook](#attention-hook) | Hook | 인프라 | 대기 상태일 때 Slack 알림 |
| [prompt-logger](#prompt-logger) | Hook | 인프라 | 대화 턴을 마크다운으로 자동 기록 (회고 분석용) |
| [markdown-guard](#markdown-guard) | Hook | 인프라 | Write/Edit 후 마크다운 검증 — 린트 위반 시 자동 수정 유도 |

## Skills

### [gather-context](plugins/gather-context/skills/gather-context/SKILL.md)

**설치**: `claude plugin install gather-context@corca-plugins` | **갱신**: `claude plugin update gather-context@corca-plugins`

URL 자동 감지, 웹 검색, 로컬 코드 탐색 3가지 모드를 제공하는 통합 정보 수집 레이어입니다. `web-search`의 모든 기능을 흡수하여 하나의 플러그인으로 모든 외부 정보 수집을 처리합니다. Google Docs, Slack, Notion, GitHub 콘텐츠를 위한 내장 변환기를 포함하며, 검색에는 Tavily와 Exa API를 사용합니다.

**사용법**:
- URL 수집: `/gather-context <url>` (Google, Slack, Notion, GitHub, 일반 웹 자동 감지)
- 웹 검색: `/gather-context --search <query>` (Tavily)
- 코드 검색: `/gather-context --search code <query>` (Exa)
- 뉴스/심층: `/gather-context --search --news <query>`, `/gather-context --search --deep <query>`
- 로컬 탐색: `/gather-context --local <topic>`
- 도움말: `/gather-context` 또는 `/gather-context help`

**지원 URL 서비스**:

| URL 패턴 | 핸들러 |
|----------|--------|
| `docs.google.com/{document,presentation,spreadsheets}/d/*` | Google Export (내장 스크립트) |
| `*.slack.com/archives/*/p*` | Slack to MD (내장 스크립트) |
| `*.notion.site/*`, `www.notion.so/*` | Notion to MD (내장 스크립트) |
| `github.com/*/pull/*`, `github.com/*/issues/*` | GitHub (`gh` CLI) |
| 기타 URL | Tavily 추출 → WebFetch 폴백 |

**저장 위치**: 통합 기본값 `./gathered/` (환경변수 `CLAUDE_CORCA_GATHER_CONTEXT_OUTPUT_DIR`로 변경 가능, 서비스별 환경변수로 개별 지정도 가능)

**필수 조건**:
- `TAVILY_API_KEY` — 웹 검색과 URL 추출에 필요 ([발급](https://app.tavily.com/home))
- `EXA_API_KEY` — 코드 검색에 필요 ([발급](https://dashboard.exa.ai/api-keys))
- API 키는 `~/.zshrc` 또는 `~/.claude/.env`에 설정

**빌트인 WebSearch 리다이렉트** (Hook):
- 이 플러그인을 설치하면 Claude의 빌트인 `WebSearch` 도구를 차단하고 `/gather-context --search`로 리다이렉트하는 `PreToolUse` 훅이 등록됩니다.

**주의사항**:
- 검색 쿼리가 외부 서비스로 전송됩니다. 기밀 코드나 민감한 정보를 포함하지 마세요.

### [clarify](plugins/clarify/skills/clarify/SKILL.md)

**설치**: `claude plugin install clarify@corca-plugins` | **갱신**: `claude plugin update clarify@corca-plugins`

clarify v1, deep-clarify, interview의 장점을 하나로 합친 통합 요구사항 명확화 스킬입니다. 리서치 기반(기본)과 경량 Q&A(`--light`) 두 가지 모드를 제공합니다. Team Attention의 [Clarify 스킬](https://github.com/team-attention/plugins-for-claude-natives/blob/main/plugins/clarify/SKILL.md)에서 출발했습니다.

**사용법**:
- `/clarify <요구사항>` — 리서치 기반 (기본)
- `/clarify <요구사항> --light` — 직접 Q&A, 서브에이전트 없음

**기본 모드** (리서치 기반):
1. 요구사항 캡처 및 결정 포인트 분해
2. 병렬 리서치: 코드베이스 탐색 + 웹/베스트 프랙티스 리서치 (gather-context 설치 시 활용, 미설치 시 내장 도구 폴백)
3. 티어 분류: T1 (코드베이스 해결) → 자동 결정, T2 (베스트 프랙티스 해결) → 자동 결정, T3 (주관적) → 사람에게 질문
4. T3 항목에 대해 대립하는 관점의 자문 서브에이전트가 의견 제시
5. Why-digging과 긴장 감지를 활용한 끈질긴 질문
6. 출력: 결정 테이블 + 명확화된 요구사항

**--light 모드** (직접 Q&A):
- AskUserQuestion을 통한 반복 질문
- 피상적 답변에 대한 Why-digging
- 답변 간 긴장 감지
- Before/After 비교 출력

**주요 기능**:
- 질문 전 자율 리서치 — 진정으로 주관적인 결정만 질문
- gather-context와 통합 (미설치 시 우아하게 폴백)
- 끈질긴 질문: 2-3단계 why-digging, 모순 감지
- 모든 항목이 리서치로 해결되면 자문/질문 단계 완전 생략
- 사용자 언어 자동 적응 (한국어/영어)

### [retro](plugins/retro/skills/retro/SKILL.md)

**설치**: `claude plugin install retro@corca-plugins` | **갱신**: `claude plugin update retro@corca-plugins`

적응형 세션 회고 스킬입니다. `lessons.md`가 세션 중 점진적으로 쌓이는 학습 기록이라면, `retro`는 세션 전체를 조감하는 종합 회고입니다. 기본은 경량 모드(빠르고 저비용), `--deep`으로 전문가 분석을 포함한 전체 회고를 수행합니다.

**사용법**:
- 세션 종료 시 (경량): `/retro`
- 전문가 렌즈 포함 전체 분석: `/retro --deep`
- 특정 디렉토리 지정: `/retro prompt-logs/260130-my-session`

**모드**:
- **경량** (기본): 섹션 1-4 + 7. 서브에이전트 없음, 웹 검색 없음. 세션 무게에 따라 에이전트가 자동 선택.
- **심층** (`--deep`): Expert Lens(병렬 서브에이전트)와 Learning Resources(웹 검색) 포함 전체 7개 섹션.

**주요 기능**:
- 유저/조직/프로젝트에 대한 정보 중 이후 작업에 도움될 내용 문서화
- 업무 스타일·협업 방식 관찰 후 CLAUDE.md 업데이트 제안 (유저 승인 후 적용)
- 낭비 분석(Waste Reduction): 허비된 턴, 과설계, 놓친 지름길, 컨텍스트 낭비, 커뮤니케이션 비효율 식별
- Gary Klein의 CDM(Critical Decision Method)으로 세션의 핵심 의사결정 분석
- Expert Lens (심층만): 병렬 서브에이전트가 실존 전문가의 관점에서 세션을 분석
- Learning Resources (심층만): 유저의 지식 수준에 맞춘 웹 검색 학습자료 제공
- 설치된 스킬 스캔 후 관련성 분석, 이후 외부 스킬 탐색 제안

**출력물**:
- `prompt-logs/{YYMMDD}-{NN}-{title}/retro.md` — plan.md, lessons.md와 같은 디렉토리에 저장

### [refactor](plugins/refactor/skills/refactor/SKILL.md)

**설치**: `claude plugin install refactor@corca-plugins` | **갱신**: `claude plugin update refactor@corca-plugins`

다중 모드 코드 및 스킬 리뷰 도구입니다. 빠른 구조 스캔부터 크로스 플러그인 분석까지 5가지 모드를 제공합니다. suggest-tidyings의 커밋 기반 티디잉 워크플로우를 흡수했습니다.

**사용법**:
- `/refactor` — 모든 마켓플레이스 스킬 퀵 스캔
- `/refactor --code [branch]` — 커밋 기반 티디잉 (병렬 서브에이전트)
- `/refactor --skill <name>` — 단일 스킬 심층 리뷰
- `/refactor --skill --holistic` — 크로스 플러그인 분석
- `/refactor --docs` — 문서 일관성 리뷰

**모드**:
- **퀵 스캔** (인자 없음): 모든 마켓플레이스 SKILL.md의 구조적 검사 — 단어/줄 수, 미참조 리소스, Anthropic 컴플라이언스(kebab-case, description 길이). 플래그와 함께 요약 테이블 출력.
- **코드 티디잉** (`--code`): 최근 non-tidying 커밋을 분석하여 안전한 리팩토링 기회를 찾습니다. 병렬 서브에이전트가 Kent Beck의 "Tidy First?" 철학에서 가져온 8가지 티디잉 기법(guard clauses, dead code, explaining variables 등)을 적용합니다.
- **심층 리뷰** (`--skill <name>`): 단일 스킬을 Progressive Disclosure 기준 + Anthropic 컴플라이언스로 평가합니다. 우선순위가 지정된 리팩토링 제안을 포함한 구조화된 보고서를 생성합니다.
- **전체적 분석** (`--skill --holistic`): 세 가지 차원(패턴 전파, 경계 이슈, 누락된 연결)에 걸친 크로스 플러그인 분석. 보고서를 `prompt-logs/`에 저장합니다.
- **문서 리뷰** (`--docs`): CLAUDE.md, README, project-context.md, marketplace.json, plugin.json 간의 일관성을 점검합니다. 깨진 링크, 오래된 참조, 구조적 불일치를 플래그합니다.

## Hooks

### [attention-hook](plugins/attention-hook/README.md)

**설치**: `claude plugin install attention-hook@corca-plugins` | **갱신**: `claude plugin update attention-hook@corca-plugins`

Claude Code가 입력을 기다릴 때 Slack 스레드로 알림을 보내는 훅입니다. 하나의 세션 알림이 하나의 스레드로 묶여 채널이 깔끔하게 유지됩니다. 원격 서버에 세팅해뒀을 때 유용합니다. ([작업 배경 블로그 글](https://www.stdy.blog/1p1w-03-attention-hook/))

**주요 기능**:
- **스레드 그룹화**: 첫 사용자 프롬프트가 부모 메시지를 생성하고, 이후 알림은 스레드 답글로 표시
- **대기 알림**: 사용자 입력을 60초 이상 기다릴 때 (`idle_prompt`)
- **AskUserQuestion 알림**: Claude가 질문 후 30초 이상 응답이 없을 때 (`CLAUDE_CORCA_ATTENTION_DELAY`)
- **Plan 모드 알림**: Claude가 Plan 모드 진입/종료를 요청하고 30초 이상 응답이 없을 때
- **하트비트 상태**: 장시간 자율 작업 중 주기적 상태 업데이트 (5분 이상 유휴)
- **하위 호환**: `SLACK_WEBHOOK_URL`만 설정된 경우 스레딩 없이 기존 방식으로 동작

> **호환성 주의**: 이 스크립트는 Claude Code의 내부 transcript 구조를 `jq`로 파싱합니다. Claude Code 버전이 업데이트되면 동작하지 않을 수 있습니다. 테스트된 버전 정보는 스크립트 주석을 참조하세요.

**필수 조건**:
- `jq` 설치 필요 (JSON 파싱용)
- Slack App (`chat:write` + `im:write` 권한, 권장) 또는 Incoming Webhook URL

**설정 방법** (Slack App — 스레딩 지원):

1. [api.slack.com/apps](https://api.slack.com/apps)에서 Slack App 생성, `chat:write` + `im:write` 스코프 추가, 워크스페이스에 설치
2. 채널 ID 확인: 봇에게 DM 열기 → 봇 이름 클릭 → 하단의 채널 ID 복사 (`D`로 시작). 채널 사용 시 `/invite @봇이름`으로 먼저 초대.
3. `~/.claude/.env` 파일 설정:
```bash
# ~/.claude/.env
SLACK_BOT_TOKEN="xoxb-your-bot-token"
SLACK_CHANNEL_ID="D0123456789"  # 봇 DM 채널 (또는 C...로 시작하는 채널 ID)
CLAUDE_CORCA_ATTENTION_DELAY=30  # AskUserQuestion 알림 지연 시간 (초, 기본값: 30)
```

레거시 웹훅 설정(스레딩 없음)은 `SLACK_WEBHOOK_URL`을 대신 설정하세요. 자세한 내용은 [플러그인 README](plugins/attention-hook/README.md)를 참조하세요.

**알림 내용**:
- 📝 사용자 요청 내용 (처음/끝 5줄씩 truncate)
- 🤖 요청에 대한 Claude의 응답 (처음/끝 5줄씩 truncate)
- ❓ 질문 대기 중: AskUserQuestion의 질문과 선택지 (있을 경우)
- ✅ Todo: 완료/진행중/대기 항목 수 및 각 항목 내용
- 💓 하트비트: 장시간 작업 중 Todo 진행 상황과 함께 주기적 상태 업데이트

**알림 예시**:

<img src="assets/attention-hook-normal-response.png" alt="Slack 알림 예시 1 - 일반적인 응답" width="600">

<img src="assets/attention-hook-AskUserQuestion.png" alt="Slack 알림 예시 2 - AskUserQuestion" width="600">

### [smart-read](plugins/smart-read/hooks/hooks.json)

**설치**: `claude plugin install smart-read@corca-plugins` | **갱신**: `claude plugin update smart-read@corca-plugins`

Read 도구 호출을 가로채서 파일 크기에 따라 지능적인 읽기를 강제하는 훅입니다. 큰 파일의 전체 읽기를 차단하여 컨텍스트 낭비를 방지하고, offset/limit 또는 Grep 사용을 안내합니다.

**동작 방식**:
- `PreToolUse` → `Read` 매처로 파일 읽기를 가로챔
- 전체 읽기 허용 전 파일 크기(줄 수)를 확인
- 작은 파일 (≤500줄): 조용히 허용
- 중간 파일 (500-2000줄): 허용하되 `additionalContext`로 줄 수 정보 제공
- 큰 파일 (>2000줄): 차단 후 `offset`/`limit` 또는 `Grep` 사용 안내
- 바이너리 파일 (PDF, 이미지, 노트북): 항상 허용 (Read가 자체적으로 처리)

**우회**: Claude가 `offset` 또는 `limit`을 명시적으로 설정하면 훅을 우회합니다. 둘 다 없을 때만 차단하므로, 의도적인 부분 읽기는 항상 허용됩니다.

**설정** (선택):

`~/.claude/.env`에서 임계값 조정:
```bash
# ~/.claude/.env
CLAUDE_CORCA_SMART_READ_WARN_LINES=500   # 이 줄 수 이상이면 additionalContext 추가 (기본값: 500)
CLAUDE_CORCA_SMART_READ_DENY_LINES=2000  # 이 줄 수 이상이면 읽기 차단 (기본값: 2000)
```

### [prompt-logger](plugins/prompt-logger/README.md)

**설치**: `claude plugin install prompt-logger@corca-plugins` | **갱신**: `claude plugin update prompt-logger@corca-plugins`

매 대화 턴을 마크다운 파일로 자동 기록하는 훅입니다. `Stop`과 `SessionEnd` 훅을 사용하여 턴이 완료될 때마다 증분 방식으로 캡처합니다. 모델 개입 없이 순수 bash + jq로 처리합니다.

**동작 방식**:
- `Stop` 훅: Claude 응답 완료 시 발동 → 완료된 턴을 기록
- `SessionEnd` 훅: 종료/클리어 시 발동 → 미기록 콘텐츠 캡처
- 두 훅 모두 동일한 멱등성 스크립트를 호출 (오프셋 기반 증분 처리)

**출력**: 세션당 하나의 마크다운 파일 (`{cwd}/prompt-logs/sessions/{date}-{hash}.md`)
- 세션 메타데이터 (모델, 브랜치, CWD, Claude Code 버전)
- 각 턴의 타임스탬프, 소요 시간, 토큰 사용량
- 전체 사용자 프롬프트 (이미지는 `[Image]`로 대체)
- 축약된 어시스턴트 응답 (임계값 초과 시 처음 5줄 + 마지막 5줄)
- 도구 호출 요약 (도구명 + 핵심 파라미터)

**설정** (선택):

`~/.claude/.env`에서 설정:
```bash
# ~/.claude/.env
CLAUDE_CORCA_PROMPT_LOGGER_DIR="/custom/path"        # 출력 디렉토리 (기본값: {cwd}/prompt-logs/sessions)
CLAUDE_CORCA_PROMPT_LOGGER_ENABLED=false              # 로깅 비활성화 (기본값: true)
CLAUDE_CORCA_PROMPT_LOGGER_TRUNCATE=20                # 축약 임계값 (줄 수, 기본값: 10)
```

### [markdown-guard](plugins/markdown-guard/hooks/hooks.json)

**설치**: `claude plugin install markdown-guard@corca-plugins` | **갱신**: `claude plugin update markdown-guard@corca-plugins`

모든 Write/Edit 작업 후 마크다운 파일을 검증하는 PostToolUse 훅입니다. `markdownlint-cli2`가 위반 사항(코드 펜스 언어 누락, 제목 주변 빈 줄 누락 등)을 감지하면 작업을 차단하고 이슈를 보고하여 Claude가 즉시 자체 수정할 수 있게 합니다.

**동작 방식**:
- `PostToolUse` → `Write|Edit` 매처(정규식)로 마크다운 쓰기를 가로챔
- 작성된 파일에 `npx markdownlint-cli2` 실행 (`.markdownlint.json` 설정 적용)
- 위반 발견 시: 린트 출력 내용과 함께 차단
- 정상 시: 조용히 통과

**주의사항**:
- `.md` 파일이 아니거나 `prompt-logs/` 경로는 자동으로 건너뜀
- `npx`나 `markdownlint-cli2`가 없으면 우아하게 건너뜀
- `markdownlint-cli2` 필요 (`npx`로 자동 설치)

## 삭제된 플러그인

다음 플러그인들은 마켓플레이스에서 삭제되었습니다. 소스 코드는 커밋 `238f82d`에서 참조할 수 있습니다.

### v2.0.0에서 삭제

| 삭제된 플러그인 | 대체 | 명령어 매핑 |
|------------|------|------|
| `suggest-tidyings` | [refactor](#refactor) `--code` | `/suggest-tidyings` → `/refactor --code` |
| `deep-clarify` | [clarify](#clarify) | `/deep-clarify <요구사항>` → `/clarify <요구사항>` |
| `interview` | [clarify](#clarify) | `/interview <topic>` → `/clarify <요구사항>` |
| `web-search` | [gather-context](#gather-context) | `/web-search <q>` → `/gather-context --search <q>` |

### v1.8.0에서 삭제

| 삭제된 플러그인 | 대체 |
|------------|------|
| `g-export` | `gather-context` (Google Docs/Slides/Sheets 내장) |
| `slack-to-md` | `gather-context` (Slack 스레드 변환 내장) |
| `notion-to-md` | `gather-context` (Notion 페이지 변환 내장) |

## 라이선스

MIT
