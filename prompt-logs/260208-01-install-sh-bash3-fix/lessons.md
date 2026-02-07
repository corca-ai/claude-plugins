# Lessons

## install.sh Bash 3 호환성

- `declare -A` (associative array)는 Bash 4+ 전용. macOS 기본 bash는 3.2.x
- cheatsheet에 "Empty array iteration under `set -u`" 가이드는 있지만, `declare -A` 호환성 경고는 없었음
- 수정: associative array → 일반 배열 + 선형 검색으로 교체
- 테스트: 모든 개별 플래그, 조합 플래그, 중복 방지, 에러 케이스 검증 완료
