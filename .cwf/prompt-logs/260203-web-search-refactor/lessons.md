# Lessons — web-search refactoring

### Plan already existed from previous session

- **Expected**: 플랜 모드에서 새로 플랜을 작성해야 함
- **Actual**: 이전 세션(260203-smart-read-hook)에서 이미 상세 플랜이 작성되어 있었음
- **Takeaway**: 이전 세션 플랜을 참조하되, 현재 세션의 prompt-logs에 별도 plan.md 생성

When 이전 세션에서 작성된 플랜을 구현할 때 → 새 디렉토리에 plan.md를 만들되 원본 경로를 참조

### Shell 스크립트에서 env var 로딩은 3단계 필요

- **Expected**: `~/.claude/.env` fallback만 있으면 충분
- **Actual**: Claude Code Bash tool은 bash 세션이라 `~/.zshrc`가 자동 로드되지 않음. 사용자가 `~/.zshrc`에 키를 설정한 경우 스크립트가 못 찾음
- **Takeaway**: env 로딩 3단계 체인: shell env → `~/.claude/.env` → grep으로 shell profiles 탐색

When 스크립트에서 API 키를 로딩할 때 → `grep -sh '^export VAR=' ~/.zshenv ~/.zshrc ~/.bashrc ~/.bash_profile ~/.profile` 패턴으로 쉘 프로파일도 탐색
