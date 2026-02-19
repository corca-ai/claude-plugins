# Retro: prompt-logger 버그 수정 및 gitignore 복구

> Session date: 2026-02-04

## 1. Context Worth Remembering

- **Claude Code hook 이벤트 중 인터럽트 전용 이벤트 없음**: `Stop`은 "user interrupt로 인한 중단 시에는 실행되지 않음"이 공식 문서에 명시됨. `PostToolUseFailure`의 `is_interrupt: true` 필드는 도구 실행 중단만 감지. 응답 생성 중 Escape 인터럽트는 어떤 hook도 트리거하지 않음.
- **async hook의 transcript flush race condition**: `"async": true` hook은 Stop 이벤트 발생 즉시 실행되지만, transcript JSONL의 마지막 라인이 아직 디스크에 flush되지 않은 상태일 수 있음. `sleep 0.3`으로 완화.
- **Claude 응답의 thinking 후 빈 text 블록**: Claude가 thinking block 이후 첫 번째 text content block으로 `"\n\n"`만 보내는 패턴이 존재. 이로 인해 assistant 텍스트가 빈 줄로 시작하여 truncation 예산이 낭비됨.
- **Rewind 감지의 한계**: offset 기반 추적(`TOTAL_LINES < LAST_OFFSET`)은 rewind 후 새 응답이 제거분보다 길면 감지 실패. 근본 해결은 라인 해시 기반 추적이나, 현재는 감지 가능한 범위에서만 마커를 남기는 것으로 충분.

## 2. Collaboration Preferences

- 유저가 이전 세션에서 에이전트가 독단적으로 추가한 변경(gitignore)을 이번 세션에서 발견하는 패턴. prompt-logger의 핵심 목적(repo에 세션 기록 남기기)과 정면으로 충돌하는 변경이 유저 동의 없이 들어감.
- "왜 그렇게 흘러갔을까요?" — 유저가 원인 분석까지 요청. 단순 수정이 아니라 커밋 이력과 세션 로그를 추적하여 근본 원인(에이전트의 독단적 판단)을 규명.
- 유저의 "rewind 전에는 뭐였고, rewind해서 뭐가 됐다" 요구 — 단순 마커가 아니라 학습 목적의 before/after 보존을 원함. 구현 의도를 충분히 이해하고 나서 코딩해야 함.
- "너무 복잡하게 안 가도 될 것 같습니다" — 완벽한 해결보다 실용적 범위에서의 해결을 선호. 에이전트가 과도하게 엔지니어링하려는 경향을 유저가 조율.

### Suggested CLAUDE.md Updates

- `Collaboration Style`에 추가: "커밋 시 유저가 명시적으로 요청하지 않은 파일 변경(.gitignore, 설정 파일 등)을 임의로 포함하지 말 것. 특히 프로젝트의 핵심 목적과 충돌할 수 있는 변경은 반드시 유저에게 확인."

## 3. Prompting Habits

- **"즉시 응답해주세요"**: 테스트 목적의 최소 응답 요청. prompt-logger의 동작을 확인하기 위한 효과적인 패턴.
- **"왜 그렇게 흘러갔을까요? 어떻게 생각하세요?"**: 에이전트에게 원인 분석과 의견을 동시에 요구. 단순 수정 지시가 아니라 이해를 확인하는 프롬프팅.
- **인터럽트를 의도적 테스트로 활용**: 인터럽트 후 "일부러 인터럽트했는데"로 맥락 제공. 디버깅과 테스트를 대화 흐름 안에서 자연스럽게 수행.
- **"이걸 고려하셨나요?"**: 구현 후 의도 확인 질문. 에이전트가 표면적 구현만 하고 핵심 요구사항을 놓쳤는지 검증.

## 4. Learning Resources

- [Claude Code async hooks: what they are and when to use them](https://jpcaparas.medium.com/claude-code-async-hooks-what-they-are-and-when-to-use-them-61b21cd71aad) — async hook의 sync 대비 trade-off와 race condition 회피 패턴
- [[FEATURE] User Interrupt Hook #9516](https://github.com/anthropics/claude-code/issues/9516) — 인터럽트 감지 hook 이벤트 feature request. 현재 지원되지 않음을 확인.
- [Detecting log file truncation on POSIX systems](https://stackoverflow.com/questions/462122/detecting-that-log-file-has-been-deleted-or-truncated-on-posix-systems) — inode 변경과 offset 기반 truncation 감지 패턴. rewind 감지 개선 시 참고.

## 5. Relevant Skills

- **prompt-logger 개선 완료**: 빈 줄 제거, race condition 완화, rewind 마커 기능 이번 세션에서 구현.
- **향후 고려**: interrupt hook이 Claude Code에 추가되면 prompt-logger에 `Interrupt` 이벤트 핸들러 추가 검토. 현재는 feature request 단계 (#9516).
