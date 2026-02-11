# Retro: S20 Remaining Gap Closures

> Session date: 2026-02-11
> Mode: light

## 1. Context Worth Remembering
- 남은 open gap은 기능 추가보다 "증거 구조"와 "게이트 명시성" 문제였다.
- semantic quality는 기존 artifact 존재 체크와 별도 축으로 다뤄야 재발 방지가 가능하다.

## 2. Collaboration Preferences
- 사용자는 "나머지도 진행" 요청 시 실제 남은 open set을 끝까지 밀어붙이는 실행형 진행을 기대한다.

### Suggested Agent-Guide Updates
- 없음

## 3. Waste Reduction
- 대규모 이력 파일을 반복 조회하면 추적 비용이 커진다.
- 개선: trace 목적이면 먼저 대상 GAP/DEC를 좁히고 해당 증거 라인만 추출하는 방식이 효율적이다.

## 4. Critical Decision Analysis (CDM)
- 의사결정 1: semantic 체크를 기존 모드에 즉시 통합할지, 분리 플래그로 도입할지.
  - 선택: `--semantic-gap` 분리 도입.
  - 이유: backward compatibility 유지 + false-positive 관찰 가능.
- 의사결정 2: GAP-003을 구현 추가로 볼지 trace 문제로 볼지.
  - 선택: trace 우선.
  - 이유: S13.5-B3 구현 근거가 이미 존재해 추가 구현보다 분류 갱신이 핵심.

## 5. Expert Lens
> Run `/retro --deep` for expert analysis.

## 6. Learning Resources
> Run `/retro --deep` for learning resources.

## 7. Relevant Skills
### Installed Skills
- `review`: multi-perspective verdict format이 gap closure evidence 정리에 유효.
- `retro`: light/deep 분리가 세션 복잡도에 따라 회고 비용을 조절하는 데 유효.

### Skill Gaps
- No additional skill gaps identified.

### Post-Retro Findings
- 점검 질문: "스킬에서 Claude 강결합을 줄이기 위해 `~/.claude/.env` 의존성을 `~/.zshrc`/`~/.bashrc` 중심으로 옮기고, 하위호환을 보장했는가?"
- 판정: **부분 구현 상태 (fully migrated 아님)**.
- 구현된 부분:
  - `plugins/cwf/skills/gather/scripts/search.sh`는 `shell env -> ~/.claude/.env -> shell profiles` 순서로 로딩.
  - `plugins/cwf/hooks/scripts/log-turn.sh`는 동일한 3-tier 로딩을 적용.
  - `plugins/cwf/skills/gather/scripts/slack-api.mjs`도 env -> `.env` -> profiles 순서 지원.
- 미구현/잔존 결합:
  - `plugins/cwf/hooks/scripts/smart-read.sh`는 `~/.claude/.env`만 로딩.
  - `plugins/cwf/hooks/scripts/slack-send.sh`도 `~/.claude/.env` 중심 로딩.
  - `README.md`/`README.ko.md` 설정 문구가 여전히 `.env` 중심 안내라, 운영 관점에서 표준 위치 전환이 완료되지 않음.
- 결론: backward compatibility 자체는 일부 스크립트에서 확보됐지만, repository 전체 기준으로는 `.env` 결합이 남아 있어 "이전 완료"로 보기는 어렵다.
