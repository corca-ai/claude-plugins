### 클린 마이그레이션 패턴

- **Expected**: 스크립트 복사 시 모든 파일이 정상 복사될 것
- **Actual**: `cp *`이 `__pycache__/` 디렉토리를 만나 exit 1 반환 (디렉토리는 `-r` 없이 건너뜀). 실제 스크립트 파일은 모두 정상 복사됨.
- **Takeaway**: Python 스크립트가 있는 디렉토리 복사 시 `__pycache__` 존재 가능성 인지

When Python 스크립트 디렉토리 복사 → `cp` exit code를 검증하되, `__pycache__` 경고는 무시 가능

### notion-to-md.py 실행 권한

- **Expected**: `chmod +x *`로 모든 파일에 실행 권한 부여
- **Actual**: `.py` 파일은 원본에서도 실행 권한 없었음 → 수동으로 `chmod +x` 필요
- **Takeaway**: 원본 권한과 무관하게, 스크립트로 사용될 파일은 명시적으로 실행 권한 확인

### 예시 기반 작성 vs 템플릿 기반 작성

- **Expected**: next-session.md를 최신 컨벤션에 맞게 작성
- **Actual**: S6b의 next-session.md(cwf-state.yaml 도입 전 작성)를 복사해서 수동 상태 테이블 중복. 사용자가 지적할 때까지 발견 못함.
- **Takeaway**: 최근 예시 ≠ canonical 템플릿. 컨벤션이 변경된 후에는 이전 예시가 stale. 항상 master-plan.md의 템플릿 섹션을 먼저 확인.

When 핸드오프 작성 → master-plan.md § "Handoff Template" 먼저 읽기. 최근 예시는 참고용.

### 스텁 → 실제 구현 전환

- **Expected**: redirect-websearch.sh 스텁을 실제 deny JSON으로 교체
- **Actual**: 기존 gate 메커니즘(HOOK_GROUP + cwf-hook-gate.sh)을 유지하면서 stdin 소비 + deny JSON 출력 추가. 깔끔한 전환.
- **Takeaway**: CWF 스텁 패턴이 잘 설계되어 있어, 스텁 → 실제 전환이 최소 변경으로 가능
