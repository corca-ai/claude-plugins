# Next Session: S4.6 — SW Factory 분석 + CWF v3 설계 논의

이전 세션에서 이미 S4.6 핸드오프를 작성함. 전체 내용은:
`prompt-logs/260208-04-cwf-scaffold/next-session.md` → "S4.6" 섹션 참조

## S4.5에서 추가된 논의 사항

### 1. Post-implementation 자율 워크플로우

S4.5 retro에서 식별: 에이전트가 구현 완료 후 lessons → retro → commit → push를 유저 요청 없이 자율적으로 완료해야 함.

**CLAUDE.md 반영 완료**: step 3을 "Run `/retro` autonomously — do not wait for user to request it"으로 강화함.

**CWF 스킬 설계에 반영 필요**: S4.6 논의 시 아래 질문을 다룰 것:
- CWF의 워크플로우 훅이 post-implementation 단계를 자동 트리거할 수 있는가?
- `/ship` 또는 별도 `/wrap-up` 스킬로 통합하는 것이 맞는가, 아니면 CLAUDE.md 지시만으로 충분한가?
- "에이전트가 스스로 판단하여 실행하는 단계" vs "유저 확인 후 실행하는 단계"의 경계를 어떻게 설계할 것인가?

### 2. /ship 개선 검증

S4.6 세션 중 또는 이후에 개선된 `/ship`을 실사용하여 검증:
- `/ship issue` → 한글 + 배경/문제/목표 구조 확인
- `/ship pr` → 결정사항 테이블, 검증 방법, 인간 판단 필요 사항 확인
- `/ship merge` → autonomous merge 로직 테스트 (branch protection 없는 상태에서)

## Start Command

```text
@prompt-logs/260208-07-ship-improve/next-session.md S4.6 시작합니다
```
