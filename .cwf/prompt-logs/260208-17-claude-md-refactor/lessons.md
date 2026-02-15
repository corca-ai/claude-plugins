# Lessons — CLAUDE.md Refactoring + Automated Session Eval

### `set -e`와 `(( ))` 산술 연산의 함정

- **Expected**: `((pass_count++))` 가 정상적으로 카운터를 증가시킬 것
- **Actual**: `pass_count`가 0일 때 `((0++))` 평가 결과가 0(falsy)이므로 exit code 1을 반환, `set -e`에 의해 스크립트 종료
- **Takeaway**: `set -euo pipefail` 환경에서는 `((var++))` 대신 `var=$((var + 1))` 사용

When bash 스크립트에서 `set -e` + `(( ))` 조합 → `$((var + 1))` 대입 형식 사용

### CLAUDE.md 리팩토링 범위

- **Expected**: 플랜에서 65줄 → 45줄 목표
- **Actual**: 65줄 → 53줄 (더 보수적으로 정리)
- **Takeaway**: "CWF State" 섹션 전체 제거, 중복 항목 3개 제거, plugin-deploy/commit-push/update-all 워크플로우 3단계 제거, cwf:clarify/PreToolUse 구체적 도구 참조 2개 일반화. 단, Collaboration Style 항목들은 대부분 유지 — 도구 이름만 일반화하면 permanent 행동 가이드로 충분
