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

마켓플레이스와 설치된 **모든** 플러그인을 한번에 업데이트하려면:
```bash
bash scripts/update-all.sh
```

터미널 대신 Claude Code 내에서도 동일한 작업이 가능합니다:
```
/plugin marketplace add corca-ai/claude-plugins
/plugin marketplace update
```

### 2. 플러그인 오버뷰

| 플러그인 | 유형 | 설명 |
|---------|------|------|
| [clarify](#clarify) | Skill | 모호한 요구사항을 명확하게 정리 |
| [deep-clarify](#deep-clarify) | Skill | 리서치 기반 요구사항 명확화 (자율 의사결정) |
| [interview](#interview) | Skill | 구조화된 인터뷰로 요구사항 추출 |
| [suggest-tidyings](#suggest-tidyings) | Skill | 안전한 리팩토링 기회 제안 |
| [retro](#retro) | Skill | 세션 종료 시 포괄적 회고 수행 |
| [gather-context](#gather-context) | Skill | URL 자동 감지 후 외부 콘텐츠를 자체 스크립트로 수집 |
| [web-search](#web-search) | Skill + Hook | 웹 검색, 코드 검색, URL 콘텐츠 추출 |
| [attention-hook](#attention-hook) | Hook | 대기 상태일 때 Slack 알림 |
| [plan-and-lessons](#plan-and-lessons) | Hook | Plan 모드 진입 시 Plan & Lessons Protocol 주입 |
| [smart-read](#smart-read) | Hook | 파일 크기 기반 지능적 읽기 강제 |

## Skills

### [clarify](plugins/clarify/skills/clarify/SKILL.md)

**설치**: `claude plugin install clarify@corca-plugins` | **갱신**: `claude plugin update clarify@corca-plugins`

모호하거나 불명확한 요구사항을 반복적인 질문을 통해 명확하고 실행 가능한 사양으로 변환하는 스킬입니다. [Team Attention](https://github.com/team-attention)에서 만든 [Clarify 스킬](https://github.com/team-attention/plugins-for-claude-natives/blob/main/plugins/clarify/SKILL.md)을 가져와서 커스터마이즈했습니다. (사용법 참조: 정구봉님 [링크드인 포스트](https://www.linkedin.com/posts/gb-jeong_%ED%81%B4%EB%A1%9C%EB%93%9C%EC%BD%94%EB%93%9C%EA%B0%80-%EA%B0%9D%EA%B4%80%EC%8B%9D%EC%9C%BC%EB%A1%9C-%EC%A7%88%EB%AC%B8%ED%95%98%EA%B2%8C-%ED%95%98%EB%8A%94-skills%EB%A5%BC-%EC%82%AC%EC%9A%A9%ED%95%B4%EB%B3%B4%EC%84%B8%EC%9A%94-clarify-activity-7413349697022570496-qLts))

**사용법**: "다음 요구사항을 명확하게 해줘", "clarify the following:" 등으로 트리거

**주요 기능**:
- 원본 요구사항 기록 후 체계적인 질문을 통해 모호함 해소
- Before/After 비교로 명확해진 결과 제시
- 명확해진 요구사항을 파일로 저장하는 옵션 제공. 필요시 이 문서를 Plan 모드에 넣어서 구현하면 됨

### [deep-clarify](plugins/deep-clarify/skills/deep-clarify/SKILL.md)

**설치**: `claude plugin install deep-clarify@corca-plugins` | **갱신**: `claude plugin update deep-clarify@corca-plugins`

`clarify`의 리서치 중심 대안입니다. 모든 모호한 점을 사용자에게 물어보는 대신, 코드베이스 탐색과 베스트 프랙티스 분석을 통해 자율적으로 리서치한 뒤, 진정으로 주관적인 결정만 물어봅니다 — 두 개의 대립하는 관점에서 조언 의견을 함께 제공합니다.

**사용법**: `/deep-clarify <요구사항>`

**주요 기능**:
- 병렬 서브에이전트: 코드베이스 리서처 + 베스트 프랙티스 리서처 (실존 전문가 관점 활용)
- 3단계 분류: Tier 1 (코드베이스로 해결), Tier 2 (베스트 프랙티스로 해결), Tier 3 (사람이 결정)
- Tier 3 항목에 대해 대립하는 관점의 자문 서브에이전트가 양측 의견 제시
- 근거가 충돌하거나 본질적으로 주관적인 항목만 사람에게 질문
- 모든 항목이 리서치로 해결 가능하면 자문 및 질문 단계를 완전히 건너뜀

**clarify와의 차이**:
- `/clarify` — 빠르고 가벼움, 모든 모호한 점을 질문
- `/deep-clarify` — 철저한 자율 리서치 우선, 주관적 항목만 질문

### [interview](plugins/interview/skills/interview/SKILL.md)

**설치**: `claude plugin install interview@corca-plugins` | **갱신**: `claude plugin update interview@corca-plugins`

코르카의 AX 컨설턴트 [최정혁님](https://denoiser.club/)이 본인의 취향에 맞게 만드신 스킬입니다. 목적은 Clarify와 유사합니다. 구조화된 인터뷰를 통해 요구사항, 제약사항, 설계 결정을 추출하는 스킬입니다. 대화를 통해 프로젝트의 핵심 요구사항을 발견하고 문서화합니다.

**사용법**:
- `/interview <topic>` - 새 인터뷰 시작 (예: `/interview auth-system`)
- `/interview <topic> --ref <path>` - 참조 파일을 기반으로 인터뷰
- `/interview <topic> --workspace <dir>` - 작업 디렉토리 지정

**주요 기능**:
- 한 번에 하나의 질문으로 집중된 대화 진행
- 실시간으로 SCRATCHPAD.md에 메모 기록
- 인터뷰 종료 시 SYNTHESIS.md로 요약 문서 생성
- 사용자 언어 자동 감지 및 적응 (한국어/영어)

**출력물**:
- `SCRATCHPAD.md` - 인터뷰 중 실시간 메모
- `SYNTHESIS.md` - 정리된 요구사항 종합 문서
- `JUST_IN_CASE.md` - 미래 에이전트를 위한 추가 맥락 (선택)

### [suggest-tidyings](plugins/suggest-tidyings/skills/suggest-tidyings/SKILL.md)

**설치**: `claude plugin install suggest-tidyings@corca-plugins` | **갱신**: `claude plugin update suggest-tidyings@corca-plugins`

Kent Beck의 "Tidy First?" 철학에 기반하여 최근 커밋들을 분석하고 안전한 리팩토링 기회를 찾아주는 스킬입니다. Sub-agent를 병렬로 활용하여 여러 커밋을 동시에 분석합니다.

**사용법**:
- 현재 브랜치 분석: `/suggest-tidyings`
- 특정 브랜치 분석: `/suggest-tidyings develop`

**주요 기능**:
- 최근 non-tidying 커밋에서 tidying 기회 탐색
- 각 커밋별 병렬 분석 (Task tool + sub-agents)
- Guard Clauses, Dead Code Removal, Extract Helper 등 8가지 tidying 기법 적용
- 안전성 검증: HEAD에서 이미 변경된 코드는 제외
- `파일:라인범위 — 설명 (이유: ...)` 형식의 실행 가능한 제안

**핵심 원칙**:
- 로직 변경 없이 가독성만 개선하는 안전한 변경
- 한 커밋으로 분리 가능한 원자적 수정
- 누구나 쉽게 리뷰할 수 있는 간단한 diff

### [retro](plugins/retro/skills/retro/SKILL.md)

**설치**: `claude plugin install retro@corca-plugins` | **갱신**: `claude plugin update retro@corca-plugins`

세션 종료 시점에 포괄적인 회고를 수행하는 스킬입니다. [Plan & Lessons Protocol](plugins/plan-and-lessons/protocol.md)의 `lessons.md`가 세션 중 점진적으로 쌓이는 학습 기록이라면, `retro`는 세션 전체를 조감하는 종합 회고입니다.

**사용법**:
- 세션 종료 시: `/retro`
- 특정 디렉토리 지정: `/retro prompt-logs/260130-my-session`

**주요 기능**:
- 유저/조직/프로젝트에 대한 정보 중 이후 작업에 도움될 내용 문서화
- 업무 스타일·협업 방식 관찰 후 CLAUDE.md 업데이트 제안 (유저 승인 후 적용)
- 프롬프팅 습관 개선점 제안 (세션의 구체적 사례와 함께)
- 유저의 지식/경험 수준에 맞춘 학습자료 링크 제공
- 워크플로우에 도움될 스킬 탐색 또는 새 스킬 제작 제안

**출력물**:
- `prompt-logs/{YYMMDD}-{NN}-{title}/retro.md` — plan.md, lessons.md와 같은 디렉토리에 저장

### [gather-context](plugins/gather-context/skills/gather-context/SKILL.md)

**설치**: `claude plugin install gather-context@corca-plugins` | **갱신**: `claude plugin update gather-context@corca-plugins`

URL 유형을 자동 감지하여 외부 콘텐츠를 로컬 파일로 수집하는 통합 스킬입니다. 변환 스크립트가 내장되어 있어 **별도의 스킬 설치 없이** 하나의 플러그인으로 Google Docs, Slack, Notion 콘텐츠를 모두 수집할 수 있습니다. 기존의 [`slack-to-md`](https://www.stdy.blog/1p1w-01-slack-to-md/), [`g-export`](https://www.stdy.blog/1p1w-02-g-export/), `notion-to-md`를 통합한 스킬입니다.

**사용법**:
- 명시적 호출: `/gather-context <url>`
- URL 감지: 지원되는 서비스의 URL을 에이전트가 발견하면 자동으로 적절한 변환기 실행

**지원 서비스**:

| URL 패턴 | 핸들러 |
|----------|--------|
| `docs.google.com/{document,presentation,spreadsheets}/d/*` | Google Export (내장 스크립트) |
| `*.slack.com/archives/*/p*` | Slack to MD (내장 스크립트) |
| `*.notion.site/*`, `www.notion.so/*` | Notion to MD (내장 스크립트) |
| 기타 URL | WebFetch 폴백 |

**저장 위치**: 통합 기본값 `./gathered/` (환경변수 `CLAUDE_CORCA_GATHER_CONTEXT_OUTPUT_DIR`로 변경 가능, 서비스별 환경변수로 개별 지정도 가능)

**참고**:
- 정보 검색이 필요한 경우 `/web-search` 사용을 제안합니다.

### [web-search](plugins/web-search/skills/web-search/SKILL.md)

**설치**: `claude plugin install web-search@corca-plugins` | **갱신**: `claude plugin update web-search@corca-plugins`

Tavily와 Exa REST API를 활용하여 웹 검색, 코드 검색, URL 콘텐츠 추출을 수행하는 스킬입니다. **스크립트 위임 패턴** 사용: SKILL.md가 커맨드 파싱과 쿼리 인텔리전스를 담당하고, 래퍼 스크립트가 API 실행을 처리합니다.

**사용법**:
- 웹 검색: `/web-search <query>`
- 뉴스 검색: `/web-search --news <query>`
- 심층 검색: `/web-search --deep <query>`
- 코드/기술 검색: `/web-search code <query>`
- URL 콘텐츠 추출: `/web-search extract <url> [query]`

**주요 기능**:
- Tavily API를 통한 일반 웹 검색 (답변 요약 + 소스 목록)
- 쿼리 인텔리전스: 시간적 의도와 토픽을 자동 감지하여 스크립트 파라미터 설정
- 선택적 모디파이어: `--news`로 뉴스 토픽, `--deep`으로 심층 검색
- Exa API를 통한 코드/기술 전문 검색 (동적 토큰 할당)
- URL 추출 시 쿼리 파라미터로 관련성 기반 재정렬 지원
- 독립 실행 가능한 스크립트 (`search.sh`, `code-search.sh`, `extract.sh`)가 환경 변수 로딩, JSON 빌드, curl, 응답 포맷팅 처리
- 검색 결과에 Sources 섹션 포함

**필수 조건**:
- `TAVILY_API_KEY` — 웹 검색과 URL 추출에 필요 ([발급](https://app.tavily.com/home))
- `EXA_API_KEY` — 코드 검색에 필요 ([발급](https://dashboard.exa.ai/api-keys))
- API 키는 `~/.zshrc` 또는 `~/.claude/.env`에 설정

**빌트인 WebSearch 리다이렉트** (Hook):
- 이 플러그인을 설치하면 Claude의 빌트인 `WebSearch` 도구를 차단하고 `/web-search`로 리다이렉트하는 `PreToolUse` 훅이 함께 등록됩니다.
- 모든 웹 검색이 Tavily/Exa API를 통해 적절한 키 관리 하에 이루어지도록 보장합니다.
- 리다이렉트는 자동이며 추가 설정이 필요 없습니다.

**주의사항**:
- 쿼리가 외부 검색 서비스로 전송됩니다. 기밀 코드나 민감한 정보를 검색 쿼리에 포함하지 마세요.

## Hooks

### [attention-hook](plugins/attention-hook/README.md)

**설치**: `claude plugin install attention-hook@corca-plugins` | **갱신**: `claude plugin update attention-hook@corca-plugins`

Claude Code가 입력을 기다릴 때 Slack 스레드로 알림을 보내는 훅입니다. 하나의 세션 알림이 하나의 스레드로 묶여 채널이 깔끔하게 유지됩니다. 원격 서버에 세팅해뒀을 때 유용합니다. ([작업 배경 블로그 글](https://www.stdy.blog/1p1w-03-attention-hook/))

**주요 기능**:
- **스레드 그룹화**: 첫 사용자 프롬프트가 부모 메시지를 생성하고, 이후 알림은 스레드 답글로 표시
- **대기 알림**: 사용자 입력을 60초 이상 기다릴 때 (`idle_prompt`)
- **AskUserQuestion 알림**: Claude가 질문 후 30초 이상 응답이 없을 때 (`CLAUDE_ATTENTION_DELAY`)
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
CLAUDE_ATTENTION_DELAY=30  # AskUserQuestion 알림 지연 시간 (초, 기본값: 30)
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

### [plan-and-lessons](plugins/plan-and-lessons/hooks/hooks.json)

**설치**: `claude plugin install plan-and-lessons@corca-plugins` | **갱신**: `claude plugin update plan-and-lessons@corca-plugins`

Claude Code가 Plan 모드에 진입할 때(`EnterPlanMode` 도구 호출 시) Plan & Lessons Protocol을 자동으로 주입하는 훅입니다. 프로토콜은 `prompt-logs/{YYMMDD}-{NN}-{title}/` 디렉토리에 plan.md와 lessons.md를 생성하는 워크플로우를 정의합니다.

**동작 방식**:
- `PreToolUse` → `EnterPlanMode` 매처로 plan 모드 진입을 감지
- `additionalContext`로 프로토콜 문서 경로를 주입
- Claude가 프로토콜을 읽고 따름

**주의사항**:
- `/plan`이나 Shift+Tab으로 직접 plan 모드에 진입하는 경우에는 훅이 발동되지 않음 (CLI 모드 토글이라 도구 호출 없음)
- 커버리지를 위해 CLAUDE.md에 프로토콜 참조를 병행 설정하는 것을 권장

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

## 삭제된 스킬

다음 스킬들은 v1.8.0에서 삭제되었습니다. 동일한 기능이 [gather-context](#gather-context)에 내장되어 있습니다.

| 삭제된 스킬 | 대체 |
|------------|------|
| `g-export` | `gather-context` (Google Docs/Slides/Sheets 내장) |
| `slack-to-md` | `gather-context` (Slack 스레드 변환 내장) |
| `notion-to-md` | `gather-context` (Notion 페이지 변환 내장) |

**마이그레이션**:
```bash
claude plugin install gather-context@corca-plugins
```

## 라이선스

MIT
