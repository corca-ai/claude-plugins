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

### Plan 단계에서 Prior Art 검색은 기본 동작

- **Expected**: 감사 작업이라 외부 프레임워크가 필요 없을 것
- **Actual**: retro에서 찾은 Diátaxis 프레임워크가 plan 단계에서 있었다면 더 구조적인 어휘와 기준을 제공했을 것
- **Takeaway**: "누군가 이미 고민한 적 있을 것이다" — 검색 비용은 낮고 잠재 가치는 비대칭적으로 높음. How to Measure Anything의 원칙: "It's been done before—don't reinvent the wheel."

plan 작성 시 → 관련 프레임워크/prior art를 먼저 검색하는 것을 기본 동작으로.
→ protocol.md에 "Prior Art Search" 섹션 추가 완료.

### 스킬 내부 문서 변경 시 버전 누락 주의

- **Expected**: api-reference.md 변경이 문서 감사의 일부라 버전 불필요할 것
- **Actual**: 플러그인 내부 파일이 변경되면 patch 버전이라도 올려야 함 (설치된 사본이 캐시되므로)
- **Takeaway**: 플러그인 디렉토리 안의 어떤 파일이든 바뀌면 버전 bump 필요

### 서브에이전트 "신선한 눈" 리뷰 패턴

- **Expected**: 자기 작업을 직접 검토하면 충분할 것
- **Actual**: 3개 독립 서브에이전트(content integrity, missed opportunities, progressive disclosure)에게 lessons/retro를 컨텍스트로 주고 최근 커밋의 diff를 리뷰시킨 결과, 4개 버그 + 7개 개선점 발견. 특히 404 링크, CHANGELOG 오류, marketplace.json 버전 누락 등 자기 작업에서 놓친 문제들.
- **Takeaway**: 대규모 변경 후 "리뷰 에이전트"를 병렬로 돌리는 패턴이 효과적. 각 에이전트에게 서로 다른 관점(정합성, 누락, 구조)을 부여하면 커버리지가 넓어짐.

커밋 전 품질 검증이 필요할 때 → 서브에이전트에게 lessons/retro 컨텍스트 + diff를 주고 관점별 병렬 리뷰

### README install 블록은 의도적 반복

- **Expected**: per-plugin install/update 블록이 중복이라 제거 가능할 것
- **Actual**: 유저가 특정 플러그인 섹션으로 바로 점프해서 복붙하는 UX를 위해 의도적으로 반복한 것
- **Takeaway**: "중복 제거"가 항상 옳진 않음. 독자의 실제 사용 패턴을 고려해야 함. 축약(한 줄 inline)이 중간안.

문서 중복 제거 시 → "누가 어떻게 이 문서를 읽는가?" 먼저 확인
