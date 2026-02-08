### 클린 마이그레이션 패턴

- **Expected**: 스크립트 복사 시 모든 파일이 정상 복사될 것
- **Actual**: `cp *`이 `__pycache__/` 디렉토리를 만나 exit 1 반환 (디렉토리는 `-r` 없이 건너뜀). 실제 스크립트 파일은 모두 정상 복사됨.
- **Takeaway**: Python 스크립트가 있는 디렉토리 복사 시 `__pycache__` 존재 가능성 인지

When Python 스크립트 디렉토리 복사 → `cp` exit code를 검증하되, `__pycache__` 경고는 무시 가능

### notion-to-md.py 실행 권한

- **Expected**: `chmod +x *`로 모든 파일에 실행 권한 부여
- **Actual**: `.py` 파일은 원본에서도 실행 권한 없었음 → 수동으로 `chmod +x` 필요
- **Takeaway**: 원본 권한과 무관하게, 스크립트로 사용될 파일은 명시적으로 실행 권한 확인

### 스텁 → 실제 구현 전환

- **Expected**: redirect-websearch.sh 스텁을 실제 deny JSON으로 교체
- **Actual**: 기존 gate 메커니즘(HOOK_GROUP + cwf-hook-gate.sh)을 유지하면서 stdin 소비 + deny JSON 출력 추가. 깔끔한 전환.
- **Takeaway**: CWF 스텁 패턴이 잘 설계되어 있어, 스텁 → 실제 전환이 최소 변경으로 가능
