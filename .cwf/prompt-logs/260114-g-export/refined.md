## Requirement Clarification Summary

### Before (Original)
"Google 슬라이드, 독스, 시트 다운로드 스킬 (public 공개된 문서에 한함)"

### After (Clarified)
**Goal**: 공개된 Google 문서(Slides, Docs, Sheets)를 로컬 파일로 다운로드하는 스킬 생성
**Reason**: 에이전트가 Google 문서 내용을 읽고 작업할 수 있도록 로컬 파일로 변환
**Scope**:
- 포함: Google Slides, Docs, Sheets 다운로드
- 제외: 비공개 문서, 이미지 export, 인증 필요 문서

**Constraints**:
- 공개 문서만 지원
- curl -L 로 다운로드
- 저장 위치: `./g-exports/`

**Success Criteria**: URL 제공 시 해당 문서를 지정된 포맷으로 다운로드

**Decisions Made**:
| Question | Decision |
|----------|----------|
| 트리거 방식 | URL 감지 자동 제안 + `/g-export` 명령 둘 다 지원 |
| 저장 위치 | `./g-exports/` 폴더 |
| 기본 포맷 | Slides→txt, Docs→md, Sheets→csv (상황에 따라 변경 가능) |
| 스킬 이름 | g-export |

---

> Source: 대화 기반 clarification (2026-01-14)
