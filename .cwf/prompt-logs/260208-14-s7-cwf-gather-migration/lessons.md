# S7 Lessons

### CWF 첫 번째 skill 마이그레이션

- **Expected**: CWF에 skills 디렉토리가 이미 존재할 것
- **Actual**: CWF는 hooks-only (13개 스크립트), skills/ 디렉토리 자체가 없음. S7이 첫 skill 추가 세션
- **Takeaway**: CWF skill 디렉토리 구조 패턴을 이 세션에서 확립해야 함

### redirect-websearch.sh stdin 처리 차이

- **Expected**: 기존 gather-context의 redirect-websearch.sh와 CWF 스텁이 동일한 패턴
- **Actual**: 기존 버전은 stdin 소비 없이 바로 JSON 출력. CWF 스텁은 `cat > /dev/null`로 stdin 소비 후 exit 0. CWF 패턴(stdin 소비 후 출력)을 따르기로 결정
- **Takeaway**: CWF hook 패턴은 항상 stdin을 먼저 소비 → 이는 broken pipe 방지를 위한 defensive pattern

### Adaptive team (Decision #9) 범위 결정

- **Expected**: 마스터 플랜에 "with adaptive team"으로 S7에 포함
- **Actual**: S7-prep 핸드오프는 마이그레이션만 언급, adaptive team은 별도 구현이 적절
- **Takeaway**: 마이그레이션과 기능 확장을 같은 세션에서 하면 리스크 증가. 마이그레이션 먼저, 확장은 다음 세션에서
