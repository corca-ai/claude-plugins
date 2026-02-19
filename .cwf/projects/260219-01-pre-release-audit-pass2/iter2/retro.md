# Iteration 2 Retro

## 무엇이 개선되었나

1. main 머지 이후 설치 blocker가 실제로 해소됨
2. predeploy gate가 `FOUND`로 복구되어 공개 설치 경로 검증 가능 상태가 됨
3. smoke 분류에서 가짜 PASS가 줄고(질문형/무출력), 실패 원인 가시성이 높아짐

## 무엇이 여전히 막히나

1. `cwf:retro --light` 단건 timeout
2. task 포함 `cwf:run` 단건 timeout
3. setup 계열의 non-interactive 결과 변동성

## 교훈

- timeout 자체 감소보다 먼저 “무엇 때문에 멈췄는지”를 분류기와 로그로 확정하는 것이 반복 속도를 높인다.
- non-interactive 스모크는 `PASS` 기준을 엄격히(질문형/무출력 배제) 유지해야 회귀를 조기에 포착한다.

## Iteration 3 액션

1. run/retro stage provenance 강제 flush
2. setup 질문 분기의 fail-fast WAIT_INPUT 표준화
3. quick-scan warning 2건 정리
