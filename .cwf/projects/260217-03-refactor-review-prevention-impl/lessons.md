# Lessons — refactor-review-prevention-impl

### Gather 단계에서의 범위 판단

- **Expected**: 태스크 문서가 상세해도 gather에서 추가 리서치가 필요할 것
- **Actual**: review-and-prevention.md에 pseudocode, BDD 기준, 파일 목록이 이미 충분히 있어 로컬 파일 탐색만으로 충분했음
- **Takeaway**: 이전 세션의 리뷰 산출물이 충분히 상세하면 gather를 로컬 탐색으로 한정 가능

When 태스크 문서에 BDD + pseudocode + 파일 목록이 이미 있으면 → gather는 `--local` 모드로 구현 대상 파일 구조만 확인

### 기존 worktree 재활용

- **Expected**: 새 worktree 생성이 필요할 것
- **Actual**: 이전 에이전트가 남긴 worktree가 marketplace-v3와 같은 커밋에 있어 브랜치만 새로 생성하여 재활용
- **Takeaway**: worktree가 같은 base 커밋이면 브랜치 전환으로 재활용 가능

### 외부 CLI 리뷰 timeout과 프롬프트 크기

- **Expected**: plan 리뷰에서 Codex/Gemini CLI가 120초 내에 응답할 것
- **Actual**: plan.md(239줄) + review-and-prevention.md(270줄) = ~500줄 프롬프트를 stdin으로 전달했더니 Codex/Gemini 모두 120초 timeout (exit 124). Gemini는 credential 로드 + hook 초기화까지만 완료, 실제 응답 생성 시작 안 됨.
- **Takeaway**: cwf:review의 외부 CLI timeout(120s)은 코드 diff 기준으로 설정됨. plan 리뷰는 spec 문서까지 포함되어 프롬프트가 2-3배 길 수 있음. timeout을 프롬프트 크기/복잡도에 맞춰 적응형으로 조절해야 함.

When 리뷰 프롬프트 > 300줄이면 → timeout을 180-240초로 확장

### 컴팩트 복구 시 사용자 의사결정 유실

- **Expected**: 컨텍스트 컴팩트 후 요약에서 사용자의 명시적 의사결정이 보존될 것
- **Actual**: 사용자가 "4개로 합성 진행" 선택했으나 컴팩트 요약에 이 결정이 명확히 전달되지 않아, 에이전트가 fallback 재시도를 3회 반복함
- **Takeaway**: 컴팩트 복구 메커니즘이 AskUserQuestion 응답과 주요 의사결정 포인트를 별도로 추적해야 함. decision_journal이 compaction summary에 포함되어야 에이전트가 같은 결정을 반복 질문하지 않음.

When 컴팩트 후 복구 시 → 사용자 결정은 session state나 decision journal에서 복구, 대화 컨텍스트에만 의존하지 않음

### Impl 단계: 부분 구현 복구

- **Expected**: 컴팩트 후 impl 단계가 처음부터 시작될 것
- **Actual**: 3개 Step이 이미 커밋 또는 부분 구현되어 있었음. git log + git diff + 파일 읽기로 각 Step의 완료 상태를 체계적으로 평가 가능했음
- **Takeaway**: 컴팩트 후 impl 재개 시 git log/diff로 기존 작업을 먼저 평가하면 중복 작업을 방지할 수 있음

When 컴팩트 후 impl 재개 시 → git log + git status + git diff로 각 Step 완료 상태 평가 후 잔여 작업만 수행

### SC2168: case 블록 내 local 키워드

- **Expected**: `case` 블록 내에서 `local` 변수 선언이 가능할 것
- **Actual**: ShellCheck SC2168 — `local`은 함수 내에서만 유효. case 블록은 함수가 아님
- **Takeaway**: bash에서 `local`은 함수 컨텍스트에서만 사용. case 블록 내 변수는 `local` 없이 선언

When case 블록 내 변수 선언 → `local` 제거, 스크립트 레벨 변수로 사용

### 이전 에이전트 작업물 위에 구축하기

- **Expected**: 이전 에이전트(S260217-02)의 미커밋 작업을 버리고 새로 구현할 것
- **Actual**: 이전 에이전트가 ~500줄의 셸 스크립트(check-deletion-safety.sh, workflow-gate.sh, cwf-live-state.sh 확장)를 남겨둠. 리뷰 결과를 반영하여 타겟 수정하는 것이 재작성보다 효율적이었음.
- **Takeaway**: worktree에 이전 에이전트의 의미 있는 작업이 있으면 "빌드 온탑" 전략 적용. 다만 반드시 plan의 요구사항과 대조하여 차이점을 식별해야 함.

When 이전 에이전트의 작업이 미커밋 상태로 존재하면 → git diff로 현재 상태 확인, plan 대비 갭 분석 후 수정 적용

### UserPromptSubmit hook의 blocking 메커니즘

- **Expected**: `json_decision("block", ...)` + `exit 0`으로 UserPromptSubmit 훅이 블로킹될 것
- **Actual**: Claude Code hooks는 exit code로 block/allow를 결정. exit 0 = allow, exit 1 = block. JSON 출력의 decision 필드만으로는 실제 블로킹이 안 됨. 이전 에이전트의 workflow-gate.sh는 exit 0만 사용해서 실제로는 아무것도 차단하지 못하는 상태였음.
- **Takeaway**: PreToolUse든 UserPromptSubmit이든 exit 1이 실제 차단 메커니즘. json_block/json_allow 패턴을 분리하여 exit code를 명확히 해야 함.

When hook에서 block 의도가 있으면 → 반드시 exit 1 사용, exit 0으로는 블로킹 불가
