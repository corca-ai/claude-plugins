# Retro: S19 Resolve Top Open Gaps

> Session date: 2026-02-11
> Mode: light

## 1. Context Worth Remembering
- S18의 `next-session.md`에 mention-only 실행 계약이 있으면 단순 파일 조회가 아니라 파이프라인 실행 지시로 해석해야 합니다.
- GAP 유형 중 "artifact flow" 문제는 writer/reader를 동시에 고치지 않으면 재발합니다.

## 2. Collaboration Preferences
- 사용자는 명시적 계약(DEC/DoD) 기반 진행을 선호하며, 근거 파일과 실제 실행 증거를 함께 요구합니다.

### Suggested Agent-Guide Updates
- 없음

## 3. Waste Reduction
- 초기에 `next-prompt-dir.sh`를 여러 번 호출해 시퀀스 번호 출력이 흔들릴 여지가 있었습니다.
- 구조적 원인: 세션 디렉터리 생성을 one-shot 변수 고정 없이 반복 호출했기 때문입니다.
- 개선: 세션 시작 시 출력 경로를 1회 캡처한 뒤 재사용하도록 습관화.

## 4. Critical Decision Analysis (CDM)
- 의사결정 1: BL-003를 문서 수정만으로 끝낼지, 로그 writer까지 같이 고칠지.
  - 선택: writer + reader 동시 수정.
  - 근거: DEC-005 DoD가 canonical output + legacy read를 동시에 요구.
- 의사결정 2: `--scenarios`를 fallback 허용할지 fail-fast로 고정할지.
  - 선택: fail-fast 명시.
  - 근거: DEC-001의 "실행 가능한 holdout 검증" 요구와 조용한 누락 방지.

## 5. Expert Lens
> Run `/retro --deep` for expert analysis.

## 6. Learning Resources
> Run `/retro --deep` for learning resources.

## 7. Relevant Skills
### Installed Skills
- `run`: mention-only contract 실행 시 stage 순서 강제에 유효.
- `review`: 시나리오 기반 holdout 검증 규약 강화 작업에 직접 연관.
- `handoff`: 다음 세션 전달 범위를 DEC/BL 기준으로 정리할 때 유효.

### Skill Gaps
- No additional skill gaps identified.
