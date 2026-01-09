# Claude Code Instructions

## Hooks 수정 시 주의사항

`hooks/` 디렉토리의 스크립트(예: `attention.sh`)를 수정할 때는 **반드시 두 곳을 함께 수정**해야 한다:

1. **이 repo의 파일**: `hooks/attention.sh`
2. **로컬 머신의 실제 hook**: `~/.claude/hooks/attention.sh`

repo 파일만 수정하면 실제 동작에 반영되지 않고, 로컬 파일만 수정하면 변경 이력이 남지 않는다.

## 문서 업데이트 필수

코드를 수정할 때는 **반드시 README.md를 읽고** 관련 내용이 있는지 확인해야 한다.

**작업 순서**:
1. 코드 수정
2. `README.md` 읽기 ← 이 단계를 건너뛰지 말 것
3. 수정한 코드와 관련된 문서 내용이 있으면 함께 갱신

문서를 읽지 않고 작업을 완료했다고 하면 안 된다.