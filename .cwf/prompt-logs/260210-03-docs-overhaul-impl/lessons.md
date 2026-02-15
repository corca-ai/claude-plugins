# Lessons — S32 Docs Overhaul

## L1: cwf:impl has no git awareness

**Context**: Implemented W1-W9 docs overhaul (93 files, -7479/+446 lines) in a single
cwf:impl run. All changes accumulated as unstaged modifications — zero commits until
the user explicitly requested post-hoc organization into 8 logical commits.

**Root cause**: cwf:impl SKILL.md has no git-related phases. It doesn't:
- Check/create a branch before starting
- Commit after completing each work item batch
- Verify clean working tree between batches

**Impact**: Without explicit user instruction ("브랜치 체크아웃해서 적절한 단위로 커밋"),
impl produces a monolithic uncommitted diff. This makes review harder, rollback
impossible at work-item granularity, and forces manual commit organization afterward.

**Relationship to cwf:ship**: `cwf:ship issue` creates branches, `cwf:ship pr` creates
PRs, but neither connects to cwf:impl. The expected flow is:
`/ship issue` → `cwf:impl` → `/ship pr`, but impl doesn't know it's operating on a
feature branch and doesn't produce commits for ship to PR.

**Proposed fix — two additions to cwf:impl**:
1. **Phase 0.5 (Branch Gate)**: Before execution, check git state. If on base branch
   (main/marketplace-v3), warn and offer to create a feature branch from the plan title.
   If already on a feature branch, proceed.
2. **Phase 3 post-batch (Commit Gate)**: After each work item batch completes in 3b
   (or after 3a direct execution), stage the modified files and create a commit with a
   message derived from the work item's step descriptions.

**Why not a separate cwf:commit skill**: Adding a separate skill between impl and ship
creates another coordination point that can be forgotten. The commit is a natural
completion marker for each work item — it belongs inside impl.

**Why not a hook**: PostToolUse hooks on Write/Edit could auto-commit, but commits at
individual file granularity are too fine. Work-item-batch granularity matches how
humans think about logical change units.

## L2: cwf:clarify sub-agent completion is not enforced

**Context**: During clarify phase (previous context session), 4 sub-agents were
spawned: codebase researcher, web researcher, Expert α (Parnas), Expert β (Klein).
The conversation ran out of context and was resumed. The impl phase completed all
W1-W9 work items. Only then did the 4 clarify sub-agents deliver their results.

**Root cause**: Two gaps:
1. cwf:clarify SKILL.md says "Wait for both to complete" but doesn't enforce it
   programmatically. If the orchestrator's context is compacted or the conversation
   is resumed, the wait is lost.
2. cwf:impl doesn't verify that the preceding clarify phase actually completed.
   It only checks for plan.md existence, not clarify completion status.

**Impact**: Clarify results (research + expert analysis) that should inform
implementation decisions arrived after implementation was done. The research was
wasted — no opportunity to use it.

**Proposed fix**:
- cwf:clarify Phase 2/2.5: After spawning sub-agents, write intermediate state to
  cwf-state.yaml (e.g., `clarify_agents: pending`). Update to `completed` when
  results are collected. If context is compacted and clarify resumes, it can check
  this state and re-collect or re-spawn.
- cwf:impl Phase 1: Add a pre-condition check — read cwf-state.yaml and verify
  clarify phase completed (if clarify was part of the workflow).

## L3: Post-hoc commit organization is viable but wasteful

**Observation**: The 8 logical commits created after implementation were well-structured
and each told a coherent story. But the process was wasteful — all the work-item
boundary knowledge existed during implementation and was discarded, only to be
reconstructed manually afterward.

**Takeaway**: Work item boundaries in cwf:impl Phase 2 are natural commit boundaries.
Capturing them at execution time (L1 proposal) eliminates the post-hoc reconstruction.

## L4: Plan-phase research reveals instruction specificity gap

- **Expected**: SKILL.md prose instructions ("check git state", "commit changes")
  would be sufficient for reliable agent execution
- **Actual**: Prior art research (Aider, Claude Code Git Safety Protocol) shows
  reliable git instructions require exact bash commands, prohibition rules with
  NEVER, pre/post-condition checks, error handling tables, and HEREDOC templates
- **Takeaway**: When adding git operations to SKILL.md, write exact bash commands
  rather than descriptive prose. Agents follow commands more reliably than intent.

When adding shell operations to SKILL.md → include exact bash commands with
error handling, not just descriptions of what to do.

## L5: L2 문제가 plan 단계에서도 재현됨

- **Expected**: cwf:plan Phase 2 research 에이전트 결과를 수집한 후 plan 작성,
  notification은 정보성으로만 도착
- **Actual**: Context compaction 발생 후 task completion notification이 뒤늦게 도착.
  "이미 반영되었습니다"라고 응답했지만, compaction 전 결과와 notification 결과가
  동일한지 검증할 수단이 없음. In-memory 의존의 취약점이 clarify뿐 아니라
  plan 등 sub-agent를 쓰는 모든 스킬에 존재
- **Takeaway**: L2의 file persistence 해결책은 clarify에만 적용할 게 아니라,
  sub-agent를 spawn하는 모든 CWF 스킬의 공통 패턴으로 검토 필요

When sub-agents are spawned → 결과를 파일에 즉시 persist해야 context loss에
resilient해짐. clarify 이외의 스킬(plan, impl, review 등)에도 동일 적용 고려.

## L6: Research agent 404/429는 URL 추측 전략의 증상

- **Expected**: Web researcher agent가 효율적으로 3-5개 소스를 찾아 결과 반환
- **Actual**: Agent가 학습 데이터에서 URL을 추측하여 직접 WebFetch → 404 (URL 변경됨)
  또는 동일 도메인 연속 요청 → 429 (rate limit). 50회 tool call, 342초 소요.
- **Root cause**: Agent prompt에 research 전략이 없음.
  "research best practices"는 무한 scope → agent가 끝없이 시도
- **Takeaway**: Sub-agent prompt에 research 전략 명시 필요:
  1. WebSearch first → WebFetch (URL 추측 금지)
  2. 소스 수 제한 (3-5개)
  3. 404/429 시 해당 도메인 skip
  4. max_turns 설정으로 runaway 방지 (증상 제한)

증상 제한(max_turns)과 원인 해결(prompt 전략)을 둘 다 적용해야 함.

## L7: log-turn.sh Turn 1 반복 버그

- **Expected**: Session log에 Turn 1, 2, 3... 순차적으로 기록
- **Actual**: Turn 1이 ~15회 반복, Turn 2 이후 기록 없음
- **Root cause**: 첫 invocation에서 meta/snapshot 엔트리가 필터링되면
  TURN_NUM_FILE이 갱신되지 않아 다음 invocation도 Turn 1부터 시작
- **Impact**: Session log에서 이전 논의 내용 복원 불가. Persistent memory 역할 실패.

## L8: Hooks/Skills의 session vs process 경계 오해

- **Expected**: Main session에서 WebSearch를 hook으로 차단하면 sub-agent에도 적용됨
- **Actual**: Hooks는 session-level snapshot. Sub-agent는 별도 process로 hook 미적용.
  따라서 sub-agent는 WebSearch를 자유롭게 사용 가능.
  반대로, sub-agent는 Skills도 접근 불가 (session-level resource이므로).
- **Root cause**: Plugin system의 scope가 session-level이라는 사실이
  hook 차단(security)과 skill 접근(capability) 양쪽에 동시 영향.
  Security hook이 sub-agent를 못 막는다는 것은 설계상 주의 필요.
- **Takeaway**: Sub-agent 관련 설계 시 항상 scope 확인 필요:
  - Hooks: main session only (sub-agent bypass)
  - Skills: main session only (sub-agent 접근 불가)
  - Tools: sub-agent에서 직접 사용 가능 (WebSearch, WebFetch 등)
- **출처**: architecture-patterns.md:16, plugin-dev-cheatsheet.md:115

## L9: cwf:review 외부 CLI 실패 시 에러 원인이 사용자에게 노출되지 않음

- **Expected**: Gemini CLI 실패 시 Confidence Note에 원인 요약 표시
- **Actual**: exit_code=1만 기록, "FAILED → fallback"으로 처리됨.
  실제 원인은 stderr.log에 있었음 (HTTP 429 MODEL_CAPACITY_EXHAUSTED,
  gemini-2.5-pro 서버 용량 부족, 3회 retry 후 포기)
- **Root cause**: review SKILL.md Phase 3.2 에러 처리가 exit code 기반
  분류만 수행. stderr.log를 읽어 핵심 에러 메시지를 추출하는 로직 미구현.
- **Impact**: 사용자가 "왜 실패했죠?"라고 물어봐야 원인 파악 가능.
  Graceful degradation은 동작하지만 observability가 부족.
- **Proposed fix**: Phase 3.2에서 외부 CLI 실패 시 stderr.log의 첫 번째
  에러 메시지 (JSON의 .error.message 또는 마지막 "Error" 줄)를 추출하여
  Confidence Note에 자동 포함. 예: "Gemini failed: No capacity available
  for model gemini-2.5-pro (429, 3 retries exhausted)"

에러의 원인이 사용자에게 자동 노출되어야 observability가 확보됨.
exit code만으로는 "왜?"에 답할 수 없음.
