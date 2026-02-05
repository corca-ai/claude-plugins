# Lessons: gather-context v2 구현

## 구현

- **플랜 기반 구현의 위력**: 파일 단위 변경 목록 + 각 파일의 구체적 변경 설명이 있으면 구현이 linear하게 진행됨. 반복/시행착오 제로.
- **스크립트 복사 전략**: deprecated 예정 플러그인에서 자산을 가져올 때 심볼릭 링크 대신 물리 복사. `diff`로 동일성 검증까지.
- **Progressive Disclosure in SKILL.md**: 261줄로 3모드(URL/search/local) + 5개 URL 핸들러를 커버. query-intelligence.md와 search-api-reference.md로 세부 로직을 분리한 것이 핵심.

## 프로세스

- **lessons.md 누락**: 구현 세션에서도 prompt-logs 디렉토리와 lessons.md를 세션 시작 시 생성해야 함. 이전 세션에서 plan.md가 작성되었더라도 별개.
- **hooks.json 이미 존재**: gather-context 플러그인의 hooks/hooks.json은 이미 존재했음(git status에 `?? plugins/gather-context/hooks/` 표시). 세션 시작 전 상태를 더 세밀하게 확인할 것.
