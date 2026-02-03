### 문서 감사 시작

- **Expected**: prompt-logs 교훈이 대부분 문서에 반영되어 있을 것
- **Actual**: 핵심 교훈 3개가 cheatsheet에 빠져 있고, claude-marketplace.md가 공식 문서 전체 복사본이며, api-reference.md가 스크립트 위임 전환 후 죽은 문서가 됨
- **Takeaway**: 아키텍처 변경(스크립트 위임) 시 관련 참조 문서도 함께 슬림화해야 함

문서 변경 시 → 동일 정보가 다른 문서에도 있는지 확인하고 단일 출처 원칙 적용

### 외부 공식 문서 복사 금지

- **Expected**: claude-marketplace.md가 프로젝트 고유 정보를 담고 있을 것
- **Actual**: 510줄 전체가 Claude Code 공식 문서의 복사본 (walkthroughs, hosting, troubleshooting 포함)
- **Takeaway**: 공식 문서는 링크로 참조하고, 프로젝트 고유 정보만 문서화

외부 공식 문서 참조 시 → 복사 대신 링크 + 프로젝트 고유 내용만 추가

### Progressive Disclosure 체크리스트

감사 기준으로 유용했던 항목:
1. 단일 출처 원칙: 같은 정보가 2곳 이상에 있으면 하나만 남기고 나머지는 참조
2. 독자별 적정 수준: CLAUDE.md(포인터) → cheatsheet(빠른 참조) → deep docs(상세)
3. 죽은 문서 감지: 아키텍처 변경 후 기존 참조 문서가 실제 코드와 괴리가 있는지 확인
