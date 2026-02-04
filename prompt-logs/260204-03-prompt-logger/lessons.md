# Lessons: prompt-logger Plugin

## Implementation Lessons

1. **`date -j` stdout leak**: Using `if date -j ... 2>/dev/null; then` as a test condition prints the date to stdout even when used inside an if statement. The `if` tests the exit code, but stdout still goes through. Fix: always capture via `$(...)` command substitution with `||` fallback chain instead.

2. **State file cleanup between tests**: `/tmp/` state files persist between test runs. The offset file from a previous run causes the script to think everything is already logged. Always clean state dir before testing, or use unique session IDs.

3. **JSONL transcript structure**: Claude Code JSONL entries have these key types:
   - `type: "user"` with `message.content` as string (user text) or array (with text/image blocks)
   - `type: "assistant"` with `message.content` as array containing `text`, `tool_use`, and `thinking` blocks
   - `isMeta: true` for system-injected entries (should be skipped for turn grouping)
   - Snapshot entries (`isSnapshotUpdate`) exist but are filtered by the user/assistant type filter

4. **Token fields**: `message.usage.input_tokens` and `message.usage.output_tokens` are the key fields. Cache-related fields (`cache_creation_input_tokens`, `cache_read_input_tokens`) exist but aren't needed for basic turn logging.

5. **Stop + SessionEnd hooks both provide**: `session_id`, `transcript_path`, `cwd`, `permission_mode`, `hook_event_name`. SessionEnd also has `reason` field.

6. **update-all.sh는 push 후에 실행해야 함**: `claude plugin marketplace update`는 remote git repo에서 pull하므로, 로컬 커밋만 있는 상태에서는 새 플러그인이 반영되지 않음. CLAUDE.md의 "5. Commit and push → 6. run update-all.sh" 순서를 기계적으로 따르지 말고 *왜* 그 순서인지 이해할 것.

7. **Rewind(Esc+Esc) 시 offset 처리**: 트랜스크립트가 truncate되면 `TOTAL_LINES < LAST_OFFSET`이 됨. 이때 offset을 0으로 리셋하여 전체 재처리. 이전 턴이 중복 기록될 수 있으나, rewind 자체가 "유저가 불만족했다"는 시그널이므로 중복 기록이 오히려 유용한 컨텍스트.

8. **플러그인 간 방어적 연동**: 플러그인 A가 B의 출력을 참조할 때, B 미설치 환경에서도 A가 정상 동작해야 함. 디렉토리 존재 조건부 체크로 구현 (예: retro가 `prompt-logs/sessions/` 존재 여부로 prompt-logger 설치 여부 판단).

9. **SessionEnd 훅에서 모델 활용 불가**: 세션 종료 후 발동하므로 `type: "command"`(bash)만 실행 가능. 모델 기반 의사결정(제목 생성 등)이 필요하면 Stop 훅 또는 스킬(retro 등)에서 처리해야 함.
