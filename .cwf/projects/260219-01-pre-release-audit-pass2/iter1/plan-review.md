# Iteration 1 계획 리뷰 통합 결과

## 입력 문서

- [.cwf/projects/260219-01-pre-release-audit-pass2/iter1/improvement-plan.md](improvement-plan.md)
- [.cwf/projects/260219-01-pre-release-audit-pass2/iter1/plan-review-release.md](plan-review-release.md)
- [.cwf/projects/260219-01-pre-release-audit-pass2/iter1/plan-review-tech.md](plan-review-tech.md)

## 핵심 리뷰 포인트 반영

1. release gate 연결 지점 명시 필요
2. smoke/marketplace 체크 실패 기준 정량화 필요
3. 수동 검증만으로 끝내지 말고 반복 가능한 자동 검증 루틴 필요
4. marketplace 조회 실패(네트워크/권한)와 엔트리 누락을 구분 필요

## 최종 실행 범위 (현재 세션)

- 구현
  - [scripts/check-marketplace-entry.sh](../../../../scripts/check-marketplace-entry.sh) 신규 추가
  - [scripts/noninteractive-skill-smoke.sh](../../../../scripts/noninteractive-skill-smoke.sh) 신규 추가
- 테스트
  - fixture 기반 스크립트 테스트 추가
  - 실제 샌드박스에서 smoke 1회 실행
- 문서
  - [docs/plugin-dev-cheatsheet.md](../../../../docs/plugin-dev-cheatsheet.md)에 배포 전 점검 절차 추가
- 기록
  - [.cwf/projects/260219-01-pre-release-audit-pass2/iter1/implementation-review.md](implementation-review.md)
  - [.cwf/projects/260219-01-pre-release-audit-pass2/iter1/refactor.md](refactor.md)
  - [.cwf/projects/260219-01-pre-release-audit-pass2/iter1/retro.md](retro.md)

## 메인 머지 이후 이관 항목

- CI/CD release gate 강제 연결
  - pre-release job에서 marketplace/smoke 스크립트 실행
  - 실패 시 릴리스 차단 + 알림 채널 연동
- nightly 회귀 검증 파이프라인
  - timeout/fail 추세 저장 및 기준선 관리

## 정량 승인 기준

### Marketplace 엔트리 체크

- `FOUND`면 exit 0
- `MISSING_ENTRY`면 exit 4
- `LOOKUP_FAILED`(네트워크/파일 접근/HTTP 오류)면 exit 2
- `INVALID_MARKETPLACE`(JSON/스키마 오류)면 exit 3

### Non-interactive smoke 체크

- 케이스별 `PASS | FAIL | TIMEOUT` 결과를 요약 테이블로 출력
- 실행 아티팩트(케이스 로그 + summary.tsv) 생성
- 기본 gate 기준
  - `fail_count <= max_failures`
  - `timeout_count <= max_timeouts`
- 기준 초과 시 exit 1

## 의사결정

- 미배포 상태에서 가능한 범위까지 구현/검증/문서화를 완료한다.
- 원격 릴리스 파이프라인 강제 연결은 메인 머지 후 이관한다.
