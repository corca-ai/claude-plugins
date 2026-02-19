# Lessons — minimal-smoke-plan

### CWF 스킬 스모크 테스트 타임아웃 패턴

- **Expected**: 모든 CWF 스킬이 `--print` 모드에서 60초 이내에 완료될 것으로 예상
- **Actual**: 14개 중 9개가 타임아웃 — sub-agent를 스폰하는 스킬(plan, review, impl)은 본질적으로 60초를 초과
- **Takeaway**: 스모크 테스트는 "스킬이 로드되고 크래시 없이 실행되는가"만 검증해야 함. 전체 워크플로우 완료는 스모크 범위를 벗어남

sub-agent 스폰 스킬 발견 시 → 스모크 대상에서 제외하거나 Tier 2(타임아웃 허용)로 분류

### Tier 분류 기준

- **Expected**: PASS/FAIL 이진 분류로 충분할 것
- **Actual**: 스킬마다 실행 시간 편차가 크고(6초~60초+), 일부는 실행 자체는 정상이나 시간만 초과
- **Takeaway**: 2-tier 시스템(core must-pass + extended informational)이 신호 대 잡음 비율을 개선

게이트 설계 시 → max-failures와 max-timeouts를 분리하여 core 실패와 extended 타임아웃을 구별
