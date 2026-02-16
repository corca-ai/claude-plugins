# Lessons — refactor-review-prevention-run

- 삭제 안전성은 문서 규칙이 아니라 `PostToolUse` fail-closed 훅으로 강제해야 한다.
- `cwf-live-state`가 session 포인터를 이전 세션으로 유지할 수 있으므로, 새 세션 시작 시 `set → sync → set` 순서가 안전하다.
- `UserPromptSubmit`에서 `decision=allow/block`을 명시하면 compaction 이후에도 실행 게이트가 유지된다.
- 라이브 상태의 리스트 필드(`remaining_gates`)는 CSV scalar보다 YAML list가 복구/검증에 안정적이다.
- 훅 수 증가 시 provenance `hook_count`를 즉시 동기화하지 않으면 drift gate가 실패한다.
- Bash에서 `BASH_COMMAND`은 특수 변수이므로 일반 변수명으로 사용하면 파싱 로직이 오작동한다.

## Post-Retro Addendum

- `cwf:setup`의 책임 범위를 "도구 감지"에서 "필수 런타임 의존성 설치 시도 + 실패 시 상호작용 에스컬레이션"으로 확장해야 한다. 그렇지 않으면 결정론적 게이트가 환경 운에 의존하게 된다.
