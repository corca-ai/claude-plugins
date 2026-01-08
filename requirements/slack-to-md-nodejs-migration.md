# Slack-to-MD: Node.js Migration Requirements

## Original Requirement
"slack-to-md skill을 사용하는 데 있어서 slackcli 를 외부 의존성으로 두고 있는데, 그 대신 필요한 모든 작업을 내재화할 수 있게 nodejs 로 작동하는 스크립트를 slack-to-md skill 폴더 내에 작성해줘. 인증은 해당 디렉토리 안의 .env에 BOT_TOKEN으로 하도록 하고. .env.local 은 해당 디렉토리의 gitignore에 추가. config cache 같은 데에 user id 와 user name 이 매핑되어 저장되어 있게 하고."

## Clarified Requirements

### Goal
slackcli 외부 의존성을 제거하고, Slack API를 직접 호출하는 Node.js 스크립트로 대체

### Scope
- `scripts/slack-to-md.sh` → `scripts/slack-to-md.mjs` (Node.js)로 교체
- Slack API 직접 호출 (conversations.replies, users.info, conversations.join)
- 사용자 ID↔이름 캐시 시스템
- 환경 변수 기반 인증

### Constraints
- Node 18+ 내장 fetch만 사용 (외부 npm 패키지 없음)
- 캐시: `.cache/users.json` (skill 디렉토리 내)
- `.env` - 템플릿 파일 (`BOT_TOKEN=`), git tracked
- `.env.local` - 실제 토큰 값, gitignored
- 권한 부족 시 필요한 권한 안내 메시지 출력

### Success Criteria
- 기존 bash 스크립트와 동일한 인터페이스 유지
- slackcli 설치 없이 동작
- 사용자 캐시로 API 호출 최소화

## Decisions Made

| Question | Decision |
|----------|----------|
| 의존성 관리 | Native only (Node 18+ fetch) |
| 캐시 위치 | `.cache/users.json` in skill dir |
| not_in_channel 처리 | 자동 join 시도 + 권한 부족 시 안내 메시지 |
| 환경 변수 파일 | `.env` (템플릿, tracked) + `.env.local` (실제값, ignored) |

## Implementation Notes

### File Structure (After)
```
.claude/skills/slack-to-md/
├── SKILL.md                    # 업데이트 필요 (slackcli 의존성 제거 반영)
├── .env                        # BOT_TOKEN= (템플릿, tracked)
├── .env.local                  # BOT_TOKEN=xoxb-... (실제값, ignored)
├── .gitignore                  # .env.local, .cache/ 추가
├── .cache/
│   └── users.json              # {userId: userName} 매핑 캐시
├── scripts/
│   ├── slack-to-md.mjs         # 새 Node.js 스크립트 (메인)
│   └── slack-to-md.sh          # 삭제 또는 deprecated
└── references/
    └── slackcli-usage.md       # Slack API 참조로 업데이트 가능
```

### Slack API Endpoints Required
- `conversations.replies` - 스레드 메시지 조회
- `conversations.join` - 채널 자동 참여
- `users.info` - 사용자 정보 조회 (캐시 미스 시)

### Required OAuth Scopes
- `channels:read` - 퍼블릭 채널 정보
- `channels:history` - 퍼블릭 채널 메시지 읽기
- `channels:join` - 봇 자동 채널 참여
- `users:read` - 사용자 정보 조회

### Error Handling
권한 부족 시 출력 예시:
```
Error: missing_scope
Required scope: channels:join
Please add this scope to your Slack app at https://api.slack.com/apps
```
