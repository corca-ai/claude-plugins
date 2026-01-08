# Public Agents and Skills for Claude Code

코르카에서 유지보수하는, Claude Code에서 사용할 수 있는 스킬과 훅 모음입니다.

## Skills

### clarify

모호하거나 불명확한 요구사항을 반복적인 질문을 통해 명확하고 실행 가능한 사양으로 변환하는 스킬입니다.

[team-attention/plugins-for-claude-natives](https://github.com/team-attention/plugins-for-claude-natives/blob/main/plugins/clarify/SKILL.md)에서 커스터마이즈하기 위해 복사해왔는데, 원본이 너무 잘 작동해서 그대로 사용하고 있습니다.

**사용법**: "다음 요구사항을 명확하게 해줘" 등으로 트리거

**주요 기능**:
- 원본 요구사항 기록 후 체계적인 질문을 통해 모호함 해소
- Before/After 비교를 통한 명확화 결과 제시
- 명확화된 요구사항을 파일로 저장하는 옵션 제공. 필요시 이 문서를 Plan 모드에 넣어서 구현하면 됨

### slack-to-md

1개 이상의 Slack 메시지 URL을 단일한 마크다운 문서로 변환하는 스킬입니다.

**사용법**: 
- 링크를 이용해 기존 메시지 취합하기: `SLACK_TO_MD <slack-message-url1> <slack-message-url2> <...>`
- 기존 문서 업데이트하기(예: 쓰레드에 새로 추가된 메시지를 기존 문서에 추가): `SLACK_TO_MD <path-to-file.md>`
- 그 외: `SLACK_TO_MD #foo 채널과 #bar 채널에서 이러저러한 내용을 취합해줘"

**주요 기능**:
- Slack 스레드의 모든 메시지를 마크다운으로 변환. 봇은 필요시 자동으로 해당 채널에 join
- 문서 생성을 위한 bash 스크립트를 이용해 토큰 절약
- 첫 메시지 내용을 기반으로 의미있는 파일명 자동 생성
- `slack-outputs/` 디렉토리에 저장

**필수 조건**:
- [slackcli](https://github.com/shaharia-lab/slackcli) 설치 필요
- Slack Bot 설정 및 권한 부여 필요

## Hooks

### attention.sh

Claude Code가 사용자의 입력을 60초 이상 기다릴 때 Slack 또는 Discord로 푸시 알림을 보내는 훅입니다. 알림에는 작업 컨텍스트(사용자 요청, Claude 응답, Todo 상태)가 포함되어 어떤 작업인지 즉시 파악할 수 있습니다. 원격 서버에 세팅해뒀을 때 유용합니다.

**필수 조건**:
- `jq` 설치 필요 (JSON 파싱용)

**설정 방법**:

1. `hooks/attention.sh`를 `~/.claude/hooks/`에 복사
2. `~/.claude/.env` 파일 생성 후 웹훅 URL 설정:
```bash
# ~/.claude/.env
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
DISCORD_WEBHOOK_URL=""  # Discord 사용 시 설정
```
3. `~/.claude/settings.json`에 훅 설정 추가:

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "idle_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/attention.sh"
          }
        ]
      }
    ]
  }
}
```

**알림 내용**:
- 📝 요청: 마지막 사용자 요청 (처음/끝 3줄씩 truncate)
- 🤖 응답: Claude의 마지막 응답 (처음/끝 3줄씩 truncate)
- ✅ Todo: 완료/진행중/대기 항목 수

**예시 알림**:
```
Claude Code @ hostname
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 요청:
Run the build and fix any type errors
...
and make sure all tests pass

🤖 응답:
I've fixed all 10 type errors:
- src/index.ts: fixed missing return type
...
All tests are now passing.

✅ Todo: 10/10 완료
```

## 설치

```bash
# 스킬 설치 (프로젝트별)
cp -r .claude/skills/* <your-project>/.claude/skills/

# 훅 설치 (전역)
cp hooks/attention.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/attention.sh
```
