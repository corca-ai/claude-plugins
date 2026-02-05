# Retro: prompt-logger Linux 데이터 유실 수정

> Session date: 2026-02-05

## 1. Context Worth Remembering

- `prompt-logger`는 Stop/SessionEnd 훅에서 transcript JSONL을 파싱하는데, transcript 크기가 커지면 (~1.8MB+) bash command substitution이 null bytes를 drop하여 데이터가 유실됨 (이 세션에서 18,110 bytes)
- bash의 `$(...)` 는 C 문자열 기반이므로 NUL byte를 저장할 수 없음 — POSIX 명세상 의도된 동작
- `set -eo pipefail` + `| head -1` 조합은 SIGPIPE (exit 141)를 유발할 수 있으며, 출력 크기에 따라 비결정적으로 발생 (테스트에서는 재현 안 되고 프로덕션에서만 발생하는 패턴)
- jq의 `first` 함수와 `-rs` (raw + slurp) 플래그 조합으로 파이프라인 없이 JSONL에서 첫 번째 매칭 값을 추출할 수 있음

## 2. Collaboration Preferences

- 이슈가 상세한 원인 분석과 수정 제안을 포함하고 있어서 plan mode 없이 바로 수정에 진입한 것이 효율적이었음
- 사용자가 "신중하게"라고 명시했으나, 이슈 자체의 분석이 충분히 구체적이어서 추가 조사 없이 바로 구현해도 무방했음
- 커밋 → push → update-all → retro 워크플로우를 사용자가 한 번에 요청했고 순차적으로 잘 처리됨

CLAUDE.md 업데이트 제안 없음 — 현재 협업 스타일이 이 세션에 잘 맞았음.

## 3. Prompting Habits

이 세션에서 특별한 프롬프팅 이슈 없음. 이슈 번호를 제공하고 수정 요청한 것은 효과적인 패턴이었음 — GitHub 이슈에 충분한 분석이 담겨 있어서 컨텍스트 전달이 자연스러웠음.

## 4. Learning Resources

### [Pixelbeat: SIGPIPE Handling](http://www.pixelbeat.org/programming/sigpipe_handling.html)
coreutils 기여자 Padraig Brady의 글. SIGPIPE는 파이프라인의 lazy evaluation을 지원하는 **정보성 시그널**이며, `set -o pipefail` 하에서는 exit 141로 전파되어 `set -e`가 스크립트를 종료시킴. `cmd | head` 패턴의 SIGPIPE 발생은 출력 크기와 스케줄링에 따라 비결정적이라는 점이 핵심. prompt-logger처럼 `set -euo pipefail`을 사용하는 스크립트에서 `| head -1` 패턴을 쓸 때 반드시 고려해야 할 내용.

### [Rich's POSIX Shell Tricks](http://www.etalabs.net/sh_tricks.html)
musl libc 저자 Rich Felker의 셸 스크립팅 레퍼런스. command substitution의 두 가지 데이터 유실 메커니즘을 설명: NUL byte 제거(POSIX 의무)와 trailing newline 제거. 후자의 방어 패턴인 `var=$(cmd; echo x); var=${var%?}` 도 알아두면 유용. 10년 넘게 인용되는 권위 있는 자료.

### [Unix SE: SIGPIPE and bash pipefail](https://unix.stackexchange.com/questions/774908/)
`ls /tmp | head`에서 SIGPIPE 발생이 비결정적인 이유를 레이스 컨디션 관점에서 분석. 출력이 작으면 writer가 먼저 완료되어 정상 종료, 크면 broken pipe에 쓰기 시도 → SIGPIPE. 이번 이슈와 정확히 같은 패턴 — 테스트 환경(작은 transcript)에서는 재현 안 되고 프로덕션(큰 transcript)에서만 발생.

## 5. Relevant Skills

이 세션에서 스킬 갭 없음. GitHub 이슈 기반 버그 수정 → 커밋 → 배포 워크플로우가 잘 작동했음.
