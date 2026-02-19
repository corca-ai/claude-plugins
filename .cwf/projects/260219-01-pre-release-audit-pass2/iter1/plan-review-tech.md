# 기술 검토: Iteration 1 개선 계획

## 실행 가능성/가정

- Marketplace 엔트리 검증([scripts/check-marketplace-entry.sh](../../scripts/check-marketplace-entry.sh))에서 "원격/로컬 marketplace 소스"라는 범위가 명시적이지 않아, 어떤 인증·응답 구조를 기대하는지(예: HTTP API, ZIP 파일 풀기)를 먼저 정의하지 않으면 실제 gate 연결 시 네트워크 실패나 메타데이터 스키마 변경으로 false positive(네트워크 오류를 missing entry로 오판) 또는 false negative(필드명 차이로 미검출)가 생길 수 있습니다. 단순 이름 검색만으로는 대소문자, 별칭, URL 경로 차이로 오판 위험이 있어, release gate에서는 "엔트리 없음"과 "조회 실패"를 반드시 분리해야 합니다. 근거: [.cwf/projects/260219-01-pre-release-audit-pass2/iter1/improvement-plan.md](improvement-plan.md).
- [scripts/noninteractive-skill-smoke.sh](../../scripts/noninteractive-skill-smoke.sh)은 `claude --print --plugin-dir ...` 기반으로 스킬 트리거를 실행하지만, 실제 non-interactive deadlock이 CLI 단독 호출이 아닌 예약 워크플로우(추가 입력/네트워크 상태)에서 나타나는 경우가 있어 false negative 또는 false positive 위험이 있습니다. timeout 값과 스킬 목록을 iter1에서 명시하고, smoke 실행 환경이 실제 배포 환경 변수/플러그인 구성을 재현하는지 점검이 필요합니다. 근거: [.cwf/projects/260219-01-pre-release-audit-pass2/iter1/improvement-plan.md](improvement-plan.md).

## 검증/테스트 부족

- BDD 성공 기준은 exit code 확인 중심이라, CLI/marketplace 포맷 변화 시 silent fail(비어 있는 log + exit 0) 가능성이 남습니다. 엔트리 체크는 더미 데이터 기반 메시지/exit code 자동 검증, smoke는 실패 시 로그/exit pattern 검증 테스트가 필요합니다.
- 검증 계획이 수동 명령 나열 중심이라 반복 실행/CI 통합을 위한 결정적 입력/기대값이 부족합니다. marketplace 명세 변경 시 알림 대상, timeout(45초) 적정성 검증, 결과 승인 루틴을 자동화 흐름으로 명시해야 합니다.

## 위험 및 다음 단계 제안

1. [scripts/check-marketplace-entry.sh](../../scripts/check-marketplace-entry.sh)에서 네트워크 오류와 실제 missing entry를 분리 보고하고, `cwf` alias/case/permalink 인식 테스트를 추가하세요.
2. smoke 스크립트는 deadlock 재현 시나리오(mocking)와 timeout 과민 반응을 함께 검증하도록 로그 assert/성능 히스토리 수집을 보완하세요.
3. 두 스크립트를 실행하는 CI job을 만들고, fixture 기반 unit/integration 테스트를 [.cwf/projects/260219-01-pre-release-audit-pass2/iter1/implementation-review.md](implementation-review.md)와 연동해 반복 가능한 검증 루틴으로 고정하세요.
