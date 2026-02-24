## Review Synthesis

### Verdict: Revise
계획의 방향성(쉘 오케스트레이터 전환, 6스테이지 고정, max-3 commit 정책)은 일관적입니다. 다만 자동화 안전성/재시작 결정론/운영 가능성에 대한 핵심 계약이 빠져 있어 구현 시작 전 보완이 필요합니다.

### Behavioral Criteria Verification
- [ ] `Given a prepared repository ... When cwf run "<prompt>" ... Then issue 생성 + initial-req + 6 stages`
  - Security/Correctness: 부수효과(idempotency) 상태계약과 권한 경계가 없어 재시도 시 중복 생성/오동작 위험.
- [ ] `Given an existing issue URL ... Then duplicate issue 없이 동일 6-stage`
  - Correctness/Security: URL 신뢰/정규화 규칙, dedupe key, 재실행 경계가 미정.
- [x] `Given a stage is running ... Then no more than 3 commits and non-empty diff`
  - Correctness/Architecture: `Step 3` 및 `Commit Strategy`에 명시되어 있음.
- [x] `Given stage gate checks fail ... Then stop and do not advance`
  - Correctness/Architecture: 게이트 실패 시 중단 의도는 명확함.
- [ ] `Given cwf watch is enabled ... Then auto routing for issue/PR comment`
  - Security/Correctness/Expert: 분류 정책·권한 정책·비용 가드레일이 deferred 상태라 즉시 자동화 기준 미충족.
- [x] `Given run-skill migration complete ... Then other interactive skills still work`
  - Architecture/UX-DX: 회귀 검증 항목이 계획에 포함됨.

### Concerns (must address)
- **Security** [security]: `cwf watch` 자동 트리거에 대한 권한 경계(authz)와 신뢰 주체 정책이 없음.
  Reference: `Scope Summary`, `Step 5`, `Decision Log #5`.
- **Security** [security]: issue/comment 기반 입력의 prompt/command injection 방어 계약이 없음.
  Reference: `Step 2`, `Step 3`, `Step 4`, `Step 5`.
- **Security** [security]: GitHub 토큰 최소권한/secret 처리/로그 마스킹 규칙 누락.
  Reference: `Create (.github/workflows/cwf-watch.yml)`, `Step 4`, `Step 5`.
- **Correctness** [critical]: run-state(idempotency, resume, side-effect dedupe) SSOT 스키마가 없어 재시작 결정론 위반 위험.
  Reference: `Known Constraints`, `Step 2`, `Step 3`, `Step 4`.
- **Correctness** [critical]: branch/worktree 상태 전이표(더티 트리, detached HEAD, diverged branch 등)가 없어 오동작 가능.
  Reference: `Known Constraints`, `Step 2`, `Step 3`.
- **Correctness** [critical]: stage/substep별 결정론적 gate 매핑(스크립트/아티팩트/exit code/재시도)이 미정.
  Reference: `Migration Principle`, `Step 3`, `Step 6`.
- **UX/DX** [moderate]: 실패 출력 계약(exit code, stage/substep, 원인, 해결 힌트)이 없어 운영자 복구 UX 부족.
  Reference: `Step 0`, `Step 3`, `Success Criteria (Qualitative)`.
- **Architecture** [moderate]: run core와 GitHub side effect 경계가 약해 결합도 상승(transport 교체/테스트 어려움).
  Reference: `Target State #3/#4`, `Step 2`, `Step 4`.
- **Expert Alpha/Beta** [moderate]: watch 즉시 자동화 대비 위험모델/제어루프/교란 시나리오(STPA/variation)가 계획에 미반영.
  Reference: `Evidence Gap List`, `Deferred Actions`, `Step 5`, `Validation Plan`.

### Suggestions (optional improvements)
- `Threat Model & Trust Boundaries` 섹션 추가: actor, asset, trust boundary, abuse case 정의.
- run-state 계약 파일 추가: `run_id`, `stage/substep`, `issue/pr/comment ids`, `checkpoint sha`, `dedupe keys`.
- branch/worktree 결정표 추가: 상태별 action/exit code/manual override 기준.
- gate matrix 추가: stage별 required artifacts, checker script, strict mode, retry policy.
- watch readiness gate 분리: 분류 규칙 + 비용 가드레일 + 동시성/재시도 상한을 Step 5 선행조건으로 승격.
- 오류 UX 계약 추가: machine-readable error + human remediation hint 표준화.

### Considered-Not-Adopted
No considered-not-adopted items.

### Commit Boundary Guidance
- `tidy`: 문서 재구성, 파일 이동/명칭 정리, 비동작성 리팩토링
- `behavior-policy`: runner contract, gate policy, watch routing/authz, runtime state semantics
- 권장 순서:
  1. `tidy` commit
  2. `behavior-policy` commit

### Confidence Note
- 6개 슬롯 모두 완료되었고 각 파일에 `<!-- AGENT_COMPLETE -->` 확인.
- Reviewer 간 공통 수렴점: `watch 자동화 즉시 적용`은 가능하나, 권한/분류/비용/재시작 결정론 계약 선행이 필수.
- Expert selection provenance: α=Deming, β=Leveson (대조 프레임워크: process variation vs safety control-loop).
- 본 synthesis는 plan mode이며 holdout scenarios 미사용.

### Reviewer Provenance
| Reviewer | Source | Tool | Duration |
|----------|--------|------|----------|
| Security | REAL_EXECUTION | claude-task | — |
| UX/DX | REAL_EXECUTION | claude-task | — |
| Correctness | REAL_EXECUTION | claude-task | — |
| Architecture | REAL_EXECUTION | claude-task | — |
| Expert Alpha | REAL_EXECUTION | claude-task | — |
| Expert Beta | REAL_EXECUTION | claude-task | — |

<!-- AGENT_COMPLETE -->
