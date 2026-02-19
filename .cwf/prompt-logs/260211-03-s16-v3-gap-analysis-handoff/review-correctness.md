## Correctness & Performance Review

### Concerns (blocking)

- **[C1]** `Phase 0: Build Corpus Manifest`의 파일 수집 규칙이 `git diff --name-only 42d2cd9..HEAD -- 'prompt-logs/**'`로 고정되어 있어, `Hard Scope Anchor`에 명시된 `plugins/cwf/**`, `cwf-state.yaml`, `master-plan.md`, `docs/v3-migration-decisions.md` 변경 파일의 누락 검출이 구조적으로 불가능합니다. 이 상태면 “omission-resistant” 목표를 만족할 수 없습니다.  
  Severity: critical

- **[C2]** 범위를 `42d2cd9..HEAD`로 정의했지만, 어떤 `HEAD`를 기준으로 고정할지(초기 SHA 스냅샷) 절차가 없습니다. 분석 중 새 커밋이 들어오면 Phase별 입력 집합이 달라져 재현 불가/경계 오염이 발생할 수 있습니다. (`Hard Scope Anchor`, 전체 Phase 공통)  
  Severity: critical

- **[C3]** `Phase 1/2/3`의 상태 분류(`Implemented/Partial/...`, `reflected/unreflected/unknown`, `Resolved/...`)에 대한 판정 규칙이 정량화되어 있지 않아 리뷰어별 결과 편차가 큽니다. 특히 `Evidence Hierarchy`와 `Conflict rule`을 실제 row/item에 적용하는 tie-break 절차가 없어 잘못된 분류 가능성이 높습니다.  
  Severity: moderate

- **[C4]** `Phase 2`(user utterance index)와 `Phase 3`(gap mining) 사이 교차 매핑이 전수 탐색 방식으로 암시되지만, 성능 예산/복잡도 제한이 없습니다. 로그 수가 커질 때 O(U×A) 또는 O(N²) 탐색으로 지연이 커질 수 있습니다. (`Operating Intent: exhaustive`, `Phase 2`, `Phase 3`)  
  Severity: moderate

- **[C5]** 오류 전파 설계가 부족합니다. `Phase 0`에서 missing/unreadable을 “명시”만 요구하고, 이후 Phase에서 해당 결손이 결과 신뢰도/완료판정에 어떻게 반영되는지 정의가 없습니다. 이 경우 “완료”로 표시되지만 실제로는 부분 실패가 숨겨질 수 있습니다. (`Phase 0`, `Completion Criteria`)  
  Severity: moderate

### Suggestions (non-blocking)

- **[S1]** 시작 시 `BASE=42d2cd9`, `TIP=$(git rev-parse HEAD)`를 고정하고 모든 명령/문서에 `TIP`를 기록해 재현성을 확보하세요.
- **[S2]** 분류 규칙을 표준화하세요. 예: “Implemented=코드 경로+테스트/실행증거 2종 이상”, “Unknown=증거 부재 또는 상충 unresolved”.
- **[S3]** `Phase 2/3`에 키 정규화(세션ID, 날짜, artifact path)와 역인덱스를 먼저 만들면 교차 참조 성능과 정확도가 동시에 개선됩니다.
- **[S4]** unreadable/missing 항목이 있으면 `summary.md`와 `discussion-backlog.md`에 자동 승격(High risk unknown)하는 규칙을 추가하세요.

### Provenance

source: REAL_EXECUTION  
tool: codex  
reviewer: Correctness  
duration_ms: —  
command: —

<\!-- AGENT_COMPLETE -->
