## Concerns (blocking)

- **[C1] Proposal E/G가 “알림” 중심이라 게이트 강제가 보장되지 않습니다 (`§6 Proposal E`, `§6 Proposal G`).**  
  `Notification/UserPromptSubmit hook`로 “Do NOT skip gates”를 주입하는 설계는 권고 신호이며, 실제 편집/커밋을 차단하는 fail-closed 경로가 없습니다. 이번 사고의 핵심인 “게이트 생략”을 구조적으로 막으려면, 최소 한 지점에서 **실행 차단**이 필요합니다(예: review-code 미완료 시 코드 변경/ship 차단).  
  Severity: **critical**

- **[C2] Deletion Safety Gate의 “no callers => safe to delete” 결론이 논리적으로 불완전합니다 (`§6 Proposal A`).**  
  제시된 검색 범위가 `*.sh/*.md/*.mjs` + 파일명 문자열 매치에 한정되어 있어, `yaml/json/python/manifest/hook config/동적 경로` 호출을 놓칠 수 있습니다. 그 상태에서 “안전 삭제”로 판정하면 동일한 런타임 파손이 재발할 수 있습니다.  
  Severity: **critical**

- **[C3] workflow 상태 모델에 동시성/오염 위험이 있습니다 (`§6 Proposal E`, `§6 Proposal G`).**  
  `cwf-state.yaml`에 `workflow/remaining_gates`를 기록하지만 session scope/락/CAS(버전 비교 갱신) 설계가 없습니다. 다중 에이전트/복구 시 stale state가 남아 잘못된 gate 안내(과차단 또는 미차단)를 유발할 수 있습니다.  
  Severity: **moderate**

- **[C4] Broken-link triage 매트릭스가 호출자 의미를 과단순화합니다 (`§6 Proposal B`).**  
  “deleted + has callers => restore file”는 호출자가 런타임 의존인지(문서/테스트/레거시 참조인지) 구분하지 않습니다. 잘못 복원하면 obsolete 파일이 재유입되고, 반대로 참조 제거가 필요한 경우를 놓칠 수 있습니다.  
  Severity: **moderate**

- **[C5] Session log cross-check의 오류 전파/일관성 정의가 없습니다 (`§6 Proposal F`).**  
  로그 누락/부분 기록/compaction 중간 상태에서 어떤 판정을 내릴지(실패-중단 vs 경고-계속) 미정입니다. 이 정책이 없으면 false positive/negative가 리뷰 신뢰도를 떨어뜨립니다.  
  Severity: **moderate**

## Suggestions (non-blocking)

- **[S1] Proposal E/G에 강제 게이트를 추가하세요.**  
  권고 훅 외에, `review-code` 미완료 시 `impl->ship` 전환을 차단하는 deterministic check(예: hook gate script exit 1)를 명시하세요.

- **[S2] Proposal A를 “다중 신호 + fail-closed”로 바꾸세요.**  
  텍스트 검색 + manifest 스캔 + script-call parser를 결합하고, 탐지 실패/파싱 에러 시 삭제 금지로 처리하세요.

- **[S3] 상태 갱신에 `session_id`, `state_version`, `updated_at`를 넣고 CAS 갱신 규칙을 정의하세요.**  
  stale write를 방지하고 복구 시에도 같은 세션의 gate만 소비하도록 만들 수 있습니다.

- **[S4] Proposal B의 매트릭스에 `caller type` 분류를 추가하세요.**  
  `runtime / build / test / docs / stale`로 분류한 뒤 액션을 결정하면 오판이 줄어듭니다.

- **[S5] Proposal D는 pre-push 전체 스캔 대신 변경 파일 중심 증분 검사로 시작하세요.**  
  성능 비용을 낮추고 도입 리스크를 줄일 수 있습니다.

## Provenance

```text
source: REAL_EXECUTION (user-provided review target + local skill prompt references)
tool: functions.exec_command (sed, rg)
reviewer: Correctness Reviewer
duration_ms: 205
command: sed -n '1,220p' plugins/cwf/skills/review/SKILL.md; sed -n '1,220p' AGENTS.md; rg -n "Correctness|plan" plugins/cwf/skills/review/references/prompts.md; sed -n '1,260p' plugins/cwf/skills/review/references/prompts.md
```
[cwf:codex post-run] live session-state check
[cwf:codex post-run] post-run checks passed (3 checks)

<\!-- AGENT_COMPLETE -->
