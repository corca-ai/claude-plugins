# Attention Hook Improvement Requirements

## Original Requirement

> attention.sh 및 hook에 대한 개선 요구사항
> - 내가 보고 있을 때도 알림이 온다. "내가 일정 시간 응답이 없을 때" 같이, 정말 내가 봐야 할 때만 알려주게 할 수 있나?
> - 어떤 작업이 끝난 건지 슬랙 알림에서 바로 알고 싶다.

## Clarified Requirements

### Goal
attention.sh를 개선하여 불필요한 알림을 줄이고, 알림에 작업 컨텍스트를 포함시킨다.

### Scope
- Hook 트리거를 `idle_prompt`로 변경 (60초 대기 후 알림)
- transcript 파싱하여 알림에 작업 정보 포함
- Slack/Discord 웹훅만 지원 (원격 서버 사용 전제)

### Constraints
- jq 의존성 필요 (JSON 파싱용)
- 원격 서버 환경에서 동작해야 함

### Success Criteria
- 사용자가 60초 이상 응답하지 않을 때만 알림 발생
- 알림에서 무슨 작업인지 즉시 파악 가능

## Decisions

| 질문 | 결정 |
|------|------|
| 알림 조건 | `idle_prompt` (60초 대기 후) |
| AskUserQuestion 알림 | idle_prompt로 통합 |
| 알림 내용 | 사용자 요청 + Claude 응답 + Todo (각 처음/끝 3줄 truncate) |
| 구현 방식 | jq 사용 |
| 알림 채널 | Slack/Discord 웹훅만 |

## Implementation Details

### Hook Configuration Change

**Before (settings.json):**
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "AskUserQuestion",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/attention.sh question"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/attention.sh done"
          }
        ]
      }
    ]
  }
}
```

**After (settings.json):**
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

### Notification Content Format

알림에 포함될 정보:
1. **마지막 사용자 요청**: 처음 3줄 + ... + 마지막 3줄
2. **Claude의 마지막 응답**: 처음 3줄 + ... + 마지막 3줄
3. **Todo 상태**: 완료/진행중/대기 항목 수

### Data Source

- Hook은 stdin으로 JSON을 받음
- `transcript_path` 필드에서 전체 대화 기록 파일 경로 획득
- jq로 파싱하여 필요한 정보 추출

### Example Notification Output

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
- src/utils.ts: fixed null check
...
All tests are now passing.

✅ Todo: 10/10 완료
```

## Technical Notes

### Hook Input (stdin JSON)
```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/session.jsonl",
  "cwd": "/working/directory",
  "hook_event_name": "Notification",
  "notification_type": "idle_prompt",
  "message": "Claude is waiting for your input"
}
```

### Transcript Format (JSONL)
각 줄이 하나의 메시지:
```json
{"type": "human", "message": {"content": "..."}}
{"type": "assistant", "message": {"content": "..."}}
```

### jq Parsing Examples
```bash
# 마지막 사용자 메시지
jq -s '[.[] | select(.type=="human")] | last | .message.content' "$TRANSCRIPT"

# 마지막 어시스턴트 메시지
jq -s '[.[] | select(.type=="assistant")] | last | .message.content' "$TRANSCRIPT"
```
