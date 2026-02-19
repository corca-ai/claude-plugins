# Iteration 2 Improvement Plan

## 목표

1. main 머지 이후 설치 blocker 해소 여부를 실제 사용자 경로로 확정
2. non-interactive smoke의 false PASS를 추가로 제거
3. Iteration 3에서 바로 착수 가능한 잔여 결함 목록 고정

## 작업 항목

1. 설치/게이트 재검증
   - marketplace remove/add + install(project/local)
   - premerge/predeploy gate 재실행
2. 분류기 보강
   - `WAIT_INPUT` 패턴 확장
   - 빈 출력 성공 케이스(`exit 0`)를 `NO_OUTPUT`로 강등
   - fixture 확장 후 gate 재통과 확인
3. run/retro 단건 재검증
   - `cwf:run` (task 포함) timeout 확인
   - `cwf:retro --light` timeout 확인

## 성공 기준

- 설치 경로 재검증 PASS
- predeploy gate PASS + public marketplace `FOUND`
- smoke fixture PASS (신규 WAIT_INPUT/NO_OUTPUT 케이스 포함)
- 잔여 결함은 시나리오/리포트에 증거와 함께 고정
