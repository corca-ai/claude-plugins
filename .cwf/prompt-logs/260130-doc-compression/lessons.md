# Lessons: 문서 압축

## 핑퐁에서 배운 것

### README.md의 중복은 의도적이다

- **예상**: README.md의 스킬별 install/update 블록과 설명이 SKILL.md와 중복이므로 압축 대상
- **실제**: 유저가 "의도적 중복으로 사용성을 높인 것"이라고 판단. README는 사용자(human)가 읽는 진입점이므로, 각 스킬의 독립적 이해를 위해 중복이 필요
- **시사점**: 중복 제거 대상인지 판단할 때 "누가 읽는가"를 먼저 확인할 것. Agent가 읽는 문서(SKILL.md)는 DRY 원칙 적용, 사람이 읽는 문서(README)는 사용성 우선

중복 제거를 제안할 때 → 독자가 agent인지 human인지 먼저 구분

### CLAUDE.md 변경은 유저가 직접 결정한다

- **예상**: "The user expects protocols to be followed"과 "verify incrementally" bullet이 불필요하므로 제거 제안
- **실제**: 유저가 P4를 제외함. CLAUDE.md는 유저의 agent 설정이므로 유저가 직접 판단
- **시사점**: CLAUDE.md 개선은 제안하되, 유저의 명시적 선택 없이 진행하지 말 것

## 구현에서 배운 것

### Output Format template의 placeholder는 생각보다 많은 줄을 차지한다

- **예상**: retro SKILL.md P6 절감 ~15줄
- **실제**: 33줄 절감 (계획의 2배). Output Format의 `{content}` placeholder + 빈 줄이 예상보다 많았음
- **시사점**: template에서 section heading만 나열하면 충분. 각 section의 내용 설명은 위 workflow에서 이미 정의됨
