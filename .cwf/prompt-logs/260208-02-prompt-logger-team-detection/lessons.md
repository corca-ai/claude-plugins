# Lessons: prompt-logger 팀 감지 + 시간 파일명

## 검증된 사실

- Claude Code agent team config: `~/.claude/teams/{name}/config.json`
- `agentId`는 `{name}@{team-name}` 형태 — `session_id`와 완전히 다른 식별자
- Teammate transcript JSONL에는 `teamName`, `agentName` 필드가 있음 (첫 줄부터)
- Leader transcript에는 `teamName: null` (팀 생성 전 세션 시작이므로)
- Leader는 config의 `leadSessionId` 필드로 식별 가능
- Agent teams는 experimental — `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 필요

## 구현 교훈

### set -e + && 체인 = 위험
`[ -f "$f" ] && EXISTING="$f" && break` — glob 미매칭 시 `[ -f ]`가 exit 1을 반환하고
`set -e`에 의해 스크립트 즉시 종료. `if/then` 블록으로 대체해야 함.

### 파일명에 시간 추가 시 일관성 문제
첫 호출에서 시간을 계산해 파일명을 결정한 후, state 파일에 캐시해야 후속 호출에서
동일 파일에 append 가능. glob fallback (`*-${HASH}.md`)으로 state 손실도 대응.

### Auto-commit 범위
`git add -- "$OUT_FILE"` (단일 파일) → `git ls-files --others --modified -- "$LOG_DIR/*.md"` (전체)로
확장해야 sub-agent 세션 로그도 포함됨.

## 프로세스 교훈

- 공식 문서 검증 먼저: tool 명세의 설명만으로 구현하면 `agentId ≠ session_id` 같은 불일치를 놓침
- 개밥먹기(dogfooding)로 실제 팀 config 구조를 확인한 것이 결정적이었음
