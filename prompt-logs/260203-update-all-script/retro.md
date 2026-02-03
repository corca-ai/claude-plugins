# Retro: update-all 스크립트 추가

> Session date: 2026-02-03

## 1. Context Worth Remembering

- 유저는 플러그인 업데이트를 자주 수행하며, 매번 수동으로 각 플러그인을 하나씩 설치하는 반복 작업을 불편하게 여김
- `~/.claude/settings.json`의 `enabledPlugins`에는 비활성화된 플러그인도 포함됨 (값이 `false`). 마켓플레이스에서 삭제된 플러그인(`url-export`)도 남아 있을 수 있음
- `((var++))` 는 bash의 `set -e` 환경에서 var=0일 때 exit code 1을 반환함 → `$((var + 1))` 패턴을 사용해야 안전

## 2. Collaboration Preferences

- 유저는 반복 작업을 발견하면 즉시 자동화를 요청하는 패턴을 보임
- "then retro, commit then push" 처럼 후속 작업을 한 문장으로 연달아 지시하는 스타일
- 코드 변경뿐 아니라 문서(README, CLAUDE.md) 반영까지 한 번에 요청하는 것이 일반적

### Suggested CLAUDE.md Updates

없음. 기존 워크플로우에 스크립트 참조가 이미 반영됨.

## 3. Prompting Habits

이번 세션에서 특별한 프롬프팅 개선점은 없음. "설치된 corca-plugin 모두 업데이트해주세요" → 반복 작업 인지 → "스크립트 만들고 문서에 넣어주세요" 흐름이 명확했음.

## 4. Learning Resources

- [Bash Pitfalls (Greg's Wiki)](https://mywiki.wooledge.org/BashPitfalls) — `((i++))` with `set -e` 등 bash 함정 모음. 이번 세션에서 겪은 이슈가 정리되어 있음
- [Claude Code Plugins Documentation](https://docs.anthropic.com/en/docs/claude-code/plugins) — 플러그인 마켓플레이스 CLI 명령어 공식 레퍼런스

## 5. Relevant Skills

이번 세션에서 스킬 갭은 식별되지 않음. `update-all.sh`는 독립 유틸리티 스크립트로 플러그인이 아닌 별도 도구로 존재하는 것이 적절함.
