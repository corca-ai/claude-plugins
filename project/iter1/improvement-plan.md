# Iteration 1 개선 계획 (cwf:plan 대체)

## 배경

- `cwf:plan` non-interactive 실행이 timeout/deadlock으로 종료되어 수동 계획 문서로 대체한다.
- 입력 근거: [project/iter1/master-scenarios.md](master-scenarios.md), [project/iter1/progress.md](progress.md), [project/overall-progress-report.md](../overall-progress-report.md)

## 목표

1. 퍼블릭 설치 blocker를 배포 전에 자동 감지한다.
2. non-interactive skill deadlock을 조기에 발견할 수 있는 smoke 도구를 제공한다.
3. Iteration 2에서 재실행 가능한 검증 루틴을 남긴다.

## 범위

- 포함
  - 신규 검증 스크립트 2개 추가
  - 사용 가이드 문서 업데이트
  - 스크립트 실행 검증
- 제외
  - marketplace 원격 배포 자체 수행
  - 모든 스킬의 interactive 로직 리디자인

## 작업 항목

1. [scripts/check-marketplace-entry.sh](../../scripts/check-marketplace-entry.sh) 추가
   - 원격/로컬 marketplace 소스에서 특정 plugin name 존재 여부를 검사
   - 실패 시 non-zero 반환으로 release gate에 연결 가능
2. [scripts/noninteractive-skill-smoke.sh](../../scripts/noninteractive-skill-smoke.sh) 추가
   - `claude --print --plugin-dir ...` 기반으로 주요 스킬 trigger를 timeout 포함 스모크 실행
   - 케이스별 exit/status 요약 리포트 출력
3. [docs/plugin-dev-cheatsheet.md](../../docs/plugin-dev-cheatsheet.md) 업데이트
   - 배포 전 필수 점검에 위 두 스크립트 추가

## BDD 성공 기준

### 시나리오 A: Marketplace 엔트리 누락 사전 감지

- Given marketplace 소스에 `cwf` 엔트리가 없다
- When `scripts/check-marketplace-entry.sh <source> cwf` 를 실행하면
- Then 명확한 실패 메시지와 함께 exit code != 0 을 반환한다

### 시나리오 B: Marketplace 엔트리 존재 확인

- Given marketplace 소스에 `cwf` 엔트리가 있다
- When 같은 명령을 실행하면
- Then 성공 메시지와 exit code 0 을 반환한다

### 시나리오 C: Non-interactive skill deadlock 조기 포착

- Given 스킬 trigger 목록과 timeout 설정이 있다
- When [scripts/noninteractive-skill-smoke.sh](../../scripts/noninteractive-skill-smoke.sh) 를 실행하면
- Then 케이스별 `PASS|FAIL|TIMEOUT` 결과와 로그 경로가 출력된다

## 검증 계획

1. `bash scripts/check-marketplace-entry.sh . cwf`
2. `bash scripts/noninteractive-skill-smoke.sh --plugin-dir plugins/cwf --workdir project/iter1/sandbox/user-repo-b --timeout 45`
3. 결과를 [project/iter1/implementation-review.md](implementation-review.md)에 기록
