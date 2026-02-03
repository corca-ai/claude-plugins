# Lessons: smart-read Hook Plugin

### PreToolUse hook의 도구 입력 접근

- **Expected**: hook에서 tool_input을 직접 접근 가능
- **Actual**: stdin으로 JSON이 들어오고, `tool_input.file_path`, `tool_input.offset`, `tool_input.limit` 등을 jq로 파싱해야 함
- **Takeaway**: PreToolUse hook은 stdin JSON → jq 파싱이 표준 패턴

### Read 도구의 기본 2000줄 제한

- **Expected**: Read가 파일 전체를 읽을 수 있음
- **Actual**: Read 도구 자체가 기본 2000줄 제한이 있음 ("By default, it reads up to 2000 lines")
- **Takeaway**: deny 임계값 2000줄은 Read의 기본 제한과 일치 — 어차피 잘리는 내용을 컨텍스트에 넣는 것을 방지

### offset/limit을 우회 수단으로 활용

- **Expected**: deny된 파일에 접근하려면 별도 우회 메커니즘 필요
- **Actual**: offset 또는 limit이 설정되어 있으면 hook이 allow → Claude가 limit만 명시하면 의도적 읽기로 인정
- **Takeaway**: 기존 도구 파라미터를 "의도 표현" 수단으로 재활용하면 별도 설정 없이 자연스러운 우회 가능

When hook에 우회 메커니즘이 필요할 때 → 기존 도구 파라미터를 활용해 의도를 표현하게 하기

### 환경변수 간 일관성 검증 필요

- **Expected**: 사용자가 WARN_LINES와 DENY_LINES를 항상 올바른 관계(WARN ≤ DENY)로 설정
- **Actual**: DENY_LINES만 낮추면 WARN_LINES(기본 500)보다 작아져서 중간 범위가 사라지는 버그 발생
- **Takeaway**: 여러 임계값을 환경변수로 제공할 때는 스크립트 내에서 관계 검증(clamp)이 필요

When 여러 환경변수가 서로 의존적일 때 → 스크립트에서 일관성을 보정하는 guard 추가

### 로컬 플러그인 테스트 방법

- **Expected**: `claude plugin install`로 로컬 플러그인을 설치하려 했으나, marketplace에 push 전이라 실패
- **Actual**: `claude --plugin-dir ./plugins/<path>` 플래그로 로컬 플러그인 디렉토리를 직접 로드할 수 있음. `--dangerously-skip-permissions`와 `--resume`을 함께 사용.
- **Takeaway**: push 전 로컬 테스트는 `--plugin-dir`가 정답. `plugin install`은 marketplace에 이미 존재하는 플러그인용.

When 로컬 플러그인을 테스트할 때 → `claude --plugin-dir ./plugins/<name> --dangerously-skip-permissions --resume`
