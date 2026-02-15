# Lessons — CWF v3 Master Plan

### Clarify 스킬 미발동

- **Expected**: 요구사항 정리 시 `/clarify` 스킬이 자동 발동
- **Actual**: 수동으로 질문을 던짐. 사용자가 지적 후 발동
- **Takeaway**: CLAUDE.md의 "custom skill 겹치면 custom skill 우선" 원칙 준수 필요

When 요구사항 정리가 필요할 때 → `/clarify` 스킬 먼저 발동

### `{plugin}:{skill}` 네이밍 발견

- **Expected**: `cwf:gather` 같은 콜론 네이밍은 플랫폼 수정이 필요할 것
- **Actual**: 단일 플러그인에 복수 스킬을 넣으면 자동으로 `{plugin}:{skill}` 트리거 생성됨. claude-dashboard가 이미 이 패턴 사용 중
- **Takeaway**: 기존 시스템 프롬프트의 스킬 목록을 주의 깊게 보면 플랫폼 기능을 발견할 수 있음

### 단일 vs 다중 플러그인 결정

- **Expected**: 기존 9개 플러그인 구조를 유지하면서 cwf 네이밍 적용
- **Actual**: 콜론 네이밍이 단일 플러그인을 요구함. compound-engineering, superpowers도 같은 패턴
- **Takeaway**: 네이밍 요구사항이 아키텍처를 결정할 수 있음. 트리거 형식 확인을 설계 초기에 해야 함

### 외부 플러그인 참조의 가치

- **Expected**: 자체 설계로 충분
- **Actual**: compound-engineering의 `workflows:` 네임스페이스, superpowers의 SessionStart 부트스트랩 등 검증된 패턴 발견
- **Takeaway**: 설계 전 2-3개 성숙한 레퍼런스를 항상 조사할 것

### Untracked 파일 삭제 주의

- **Expected**: 임시 파일이므로 옮기면 원본 삭제 가능
- **Actual**: 사용자가 원본 자체에 가치가 있다고 판단. 삭제 후 untracked라 git restore 불가
- **Takeaway**: 사용자 파일은 삭제 전 반드시 확인. 특히 untracked 파일은 복구 불가능

When 사용자 작성 파일을 정리할 때 → 삭제가 아닌 이동을 먼저 제안

### setup/update 분리 결정 과정

- **Expected**: cwf:setup 하나로 통합이 간단
- **Actual**: 사용자가 "이미 셋업한 사람에게는 번거롭다"는 UX 관점 제시
- **Takeaway**: 초기 설정과 반복 작업은 UX가 다르므로 분리 검토 필요

### 플랜 자체를 서브에이전트로 리뷰

- **Expected**: 플랜 작성 후 바로 구현으로 이동
- **Actual**: 사용자가 플랜 리뷰를 요청. 2개 서브에이전트(feasibility, philosophy)가 각각 핵심 이슈 발견 — 세션 의존성 역전(S8→S4), under-scoped 세션 3개, 누락된 install.sh 리라이트, per-session 리뷰/테스트/문서 미반영
- **Takeaway**: v3에서 만들 cwf:review를 이 세션에서 이미 프로토타이핑한 셈. "자기가 만들 도구를 만들기 전에 먼저 써본다"는 패턴이 유효함

When 큰 플랜을 작성했을 때 → 구현 전에 관점 기반 서브에이전트 리뷰 실행

### infra 스킬 → setup 서브커맨드로 축소

- **Expected**: cwf:attention, cwf:log 등 4개 독립 스킬
- **Actual**: 리뷰어가 "14 skills is too many, infra config viewers are low value" 지적. setup 서브커맨드로 대체
- **Takeaway**: 스킬 개수 자체가 오버헤드. 독립 트리거가 필요한 것만 스킬로 분리

### hook 성능: dual-file 패턴

- **Expected**: cwf-config.json을 모든 hook이 매번 읽음
- **Actual**: heartbeat가 모든 PreToolUse에서 실행 → JSON 파싱 오버헤드 우려. shell-sourceable 파일(`cwf-hooks-enabled.sh`)로 분리하면 source 비용 ≈ 0
- **Takeaway**: hot path의 config 읽기는 가장 가벼운 형식으로. JSON은 사람/스킬용, shell vars는 hook용

### 큰 결정 세션과 retro 토큰 압박

- **Expected**: 세션 끝에 retro를 자연스럽게 실행
- **Actual**: 큰 아키텍처 결정 세션은 이미 컨텍스트를 많이 소비하고, deep retro는 추가로 서브에이전트 + 웹서치를 사용. compact 해야 하나 고민.
- **Takeaway**: light retro가 이 상황에 맞는 선택. deep은 컨텍스트 여유 있을 때. cwf:handoff + cwf-state.yaml이 완성되면 compact 후에도 맥락 보존 가능.

### workflow-state.yaml: wf 스킬의 핵심 패턴

- **Expected**: 핸드오프 문서만으로 세션 간 연속성 확보
- **Actual**: 사용자가 wf의 workflow-state.yaml을 persistent memory로 쓰는 패턴을 상기시킴. 상태 파일이 있으면 cwf:handoff가 자동 생성 가능
- **Takeaway**: 세션 간 인수인계는 "문서"가 아니라 "상태"에서 시작해야 함. 상태 → 문서 생성이 맞는 방향
