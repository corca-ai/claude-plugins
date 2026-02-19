# Lessons

### web-search 삭제 시 hook 영향 확인

- **Expected**: web-search 삭제 시 WebSearch redirect hook이 사라질 수 있음
- **Actual**: gather-context v2가 이미 동일한 PreToolUse hook을 갖고 있어 영향 없음
- **Takeaway**: deprecated plugin 삭제 전에 hook 중복 여부 확인 필수

When deprecated plugin에 hook이 있을 때 → 대체 plugin에 동일 hook이 있는지 확인 후 삭제

### deprecated 디렉토리 삭제 시 active plugin 내 참조 정리

- **Expected**: 계획된 8개 파일만 수정하면 충분
- **Actual**: gather-context 스크립트 3개(extract.sh, code-search.sh, search.sh)의 주석과 에러메시지, plan-and-lessons/protocol.md에서도 web-search 참조 발견
- **Takeaway**: 디렉토리 삭제 후 반드시 `grep -r` 전수 검사 실행, 특히 스크립트 주석과 에러메시지 내 참조 확인

When deprecated plugin 삭제 시 → 계획된 파일 외에도 plugins/ 전체 grep으로 잔여 참조 확인

### retro의 deep-clarify 참조는 의도적 유지

- **Expected**: deep-clarify 삭제 시 모든 참조 제거 필요
- **Actual**: retro의 expert-lens 기능이 대화 히스토리에서 `/deep-clarify` 호출을 스캔하여 전문가 선택에 활용 — 디렉토리 참조가 아닌 대화 내용 스캔이므로 기능적으로 유효
- **Takeaway**: 참조의 성격(디렉토리 vs 대화 내용)을 구분하여 삭제 여부 판단
