# Review & Prevention: 260216 Refactoring Incident

> Date: 2026-02-17 (updated post-review)
> Scope: f7b1979..c6af491 (8 commits, 260216-04 full-repo-refactor session)
> Reviewer: Claude Opus 4.6 (post-incident, user-directed)
> Review: cwf:review --mode plan verdict **Revise** → this revision
> Next action: implement in next session via cwf:run

## 1. Review Findings

### Commit-by-commit assessment

| Commit | Description | Verdict |
|--------|-------------|---------|
| f7b1979 | Add refactoring analysis artifacts | OK — artifacts only |
| e9bddb9 | P0 fixes (frontmatter, marketplace.json, gather description) | OK |
| 38b6ebe | P1 expert advisor unification, review persistence, routing | OK — with 1 stale ref (see P2-a) |
| c236e8e | Extract expert roster update to shared guide | OK |
| fc9919b | P2 portability and convention fixes | **2 DEFECTS** (see below) |
| 9c3ca07 | Align README.md structure with README.ko.md SSOT | OK |
| 1e40ab1 | Prompt log | OK — session log |
| 1084c1d | Retro | OK — session artifact |

### Defects found

| ID | Severity | Commit | File | Description |
|----|----------|--------|------|-------------|
| D-1 | **P0 — Runtime breakage** | fc9919b | [gather/scripts/csv-to-toon.sh](../../plugins/cwf/skills/gather/scripts/csv-to-toon.sh) | Deleted a script that `g-export.sh:111` calls at runtime. Google Sheets → TOON conversion pipeline broken. |
| D-2 | **P1 — Safety net removal** | fc9919b | `refactor/references/*.provenance.yaml` (×3) | Deleted provenance sidecars that feed pre-push drift detection for 3 criteria documents. |
| D-3 | P2 — Stale reference | 38b6ebe | `retro/SKILL.md:145` | Rationale text still mentions `expert-lens-guide.md` after migration to `expert-advisor-guide.md`. |

### What was correct

The remaining changes (plugin-deploy Rules/References, plan Adaptive Sizing Gate, ship i18n, update generic path, skill-conventions enforced/aspirational split, review persistence, expert-advisor-guide retro mode, README Design Intent sections) are structurally sound and improve the system.

---

## 2. Root Cause: Why csv-to-toon.sh Was Deleted

### The signal chain

```text
Deep review (structural)           → "csv-to-toon.sh unreferenced in SKILL.md"
Deep review (recommendation)       → "Add reference to SKILL.md Google Export section"
Analysis.md triage                 → "P3-16: Remove gather unreferenced csv-to-toon.sh"
Impl agent                         → `git rm csv-to-toon.sh`
Pre-push link check (README)       → Broken link detected → push blocked
User fixes broken link             → ← HERE: last signal eliminated
User notices csv-to-toon missing   → Runtime breakage discovered
```

### 6 Whys (extended per Expert β review)

1. **왜 삭제했나?** Analysis.md가 P3-16으로 "unreferenced csv-to-toon.sh 제거"를 분류했고, impl 에이전트가 이를 그대로 실행했다.
2. **왜 analysis가 "제거"로 분류했나?** Deep review의 구체적 권장사항("SKILL.md에 참조 추가")이 triage 단계에서 "unreferenced → 삭제"로 단순화되었다.
3. **왜 triage에서 왜곡되었나?** 분석 요약이 "해결 방법"이 아닌 "문제 설명"만 전달했다. "unreferenced csv-to-toon.sh"라는 라벨은 "제거하라"로 읽히기 쉬우나 원래는 "참조를 추가하라"였다.
4. **왜 impl에서 삭제 전 런타임 의존성을 확인하지 않았나?** Impl 단계에 **"삭제 전 호출자 확인"** 게이트가 없었다.
5. **왜 cwf:review가 이를 잡지 못했나?** cwf:run 파이프라인이 아닌 수동 순차 실행이었고, review(code) 단계가 생략되었다.
6. **왜 triage 산출물의 구조가 삭제를 "당연한" 행동으로 유도했나?** (Expert β 추가) Triage 테이블이 action 열 없이 problem label만 가져, "unreferenced"는 recognition-primed decision으로 "삭제"와 자동 연결되었다. **Triage 산출물에 원본 recommendation을 함께 기록했다면** 이 연결이 차단되었을 것이다.

### Structural cause

**분석(what's wrong) → 처방(what to do)의 충실도 손실(fidelity loss)**. 깊은 분석의 구체적 권장사항이 요약/triage 단계를 거치며 반대 방향의 행동으로 변환되었다.

---

## 3. Retrospective: Would cwf:run Have Prevented This?

### 짧은 답: 높은 확률로 예, 단 조건부

cwf:run의 기본 체인은 `gather → clarify → plan → review(plan) → impl → review(code) → refactor → retro → ship`.

이 세션에서 실제로 실행된 순서는:

```text
(manual) refactor --holistic/--skill/--docs/--code → analysis.md → P0/P1/P2 manual impl → retro
```

**생략된 게이트들:**

| 생략된 단계 | 잡았을 가능성 | 근거 |
|------------|-------------|------|
| clarify | 중간 | "unreferenced 파일 처리 방법"에 대한 명시적 의사결정이 이루어졌을 수 있음 |
| plan | **높음** | Plan의 "Don't Touch" 섹션이나 BDD criteria가 "기존 런타임 파이프라인 파괴 금지"를 명시했을 가능성 |
| review(plan) | **높음** | 6명의 병렬 리뷰어가 "csv-to-toon.sh 삭제" 항목을 보고 g-export.sh 의존성을 지적했을 가능성 |
| review(code) | **매우 높음** | 코드 리뷰 시 `git rm csv-to-toon.sh` + `g-export.sh:111`의 호출 관계를 직접 감지 |

**결론**: cwf:run의 review(code) 단계 하나만으로도 이 문제는 거의 확실히 잡혔다. 하지만 cwf:run만으로는 불충분한 부분이 있다 — review는 **최종 diff를 검토**하지만, 근본 원인은 **분석→triage에서의 충실도 손실**이다. 이것은 cwf:impl의 "삭제 안전성 확인" 로직이 필요한 영역이다.

---

## 4. Retrospective: Why cwf:run Was Never Called (Session Log Analysis)

### 사실 관계

세션 로그에서 확인된 사실:

1. 사용자는 **두 번** "cwf:run 최대한 사용"이라고 말함 (Turn 1, Turn 3)
2. 에이전트는 Task #6을 **"Phase 3: Implement fixes via cwf:run"**으로 생성
3. Turn 4에서 Task #6을 `in_progress`로 변경한 직후, **cwf:run을 invoke하지 않고 직접 Edit 시작**
4. **cwf:run은 전체 세션에서 한 번도 호출되지 않음**
5. 따라서 cwf:run 체인의 review(code) 게이트가 **완전히 생략됨**

### 원인 분석

**컨텍스트 컴팩션 4회에 의한 의도 희석**: 매번 summary의 "Optional Next Step"이 구체적인 Edit 작업을 나열하여, 복구된 에이전트가 원래 사용자 지시("cwf:run 사용")를 잃어버림.

---

## 5. Retrospective: This Session's (260217) Signal Failure

Pre-push hook이 broken link를 보고했을 때, 에이전트는 **왜 파일이 없는지** 조사하지 않고 README에서 참조를 제거했다. 이것은 증상을 제거한 것이지 원인을 해결한 것이 아니다.

---

## 6. Prevention Proposals (post-review revision)

> 리뷰 반영: 6-reviewer cwf:review --mode plan (verdict: Revise)
> 주요 반영 사항: A를 hook으로 승격, E fail-closed 게이트 추가, C를 P1로 승격,
> `workflow` → `active_pipeline` 필드명 변경, remaining_gates를 YAML list로 저장,
> hook event를 UserPromptSubmit으로 확정, override 메커니즘 추가

### Proposal A: Deletion safety hook (P0 — co-primary with E+G)

**문제**: `git rm`이나 파일 삭제가 런타임 의존성을 깨뜨릴 수 있다.

**리뷰 반영**: 원래 prose rule이었으나, 5/6 리뷰어가 "prose는 deterministic gate가 아님 — 문서 자체 분석과 내부 모순"이라고 지적. Expert β: "유일하게 실제 결정 시점에 개입하는 메커니즘". **Hook script로 구현하여 compaction immunity 확보.**

**해결**: `hooks/scripts/check-deletion-safety.sh` — PostToolUse hook으로 `git rm`, `rm`, 파일 삭제 감지 시 호출자 검사를 실행.

```bash
#!/usr/bin/env bash
# PostToolUse hook: fires after Bash/Edit/Write tool calls
# 1. Parse tool output for file deletion patterns (git rm, rm, unlink)
# 2. For each deleted file: search codebase for callers
#    grep -r "filename" --include="*.sh" --include="*.md" --include="*.mjs" \
#                       --include="*.yaml" --include="*.json" --include="*.py"
# 3. If callers found: exit 1 with error message
#    "BLOCKED: {file} has runtime callers: {list}. Restore file or remove callers first."
# 4. If no callers: exit 0 (silent pass)
```

**검색 범위** (Correctness 리뷰 반영 — 원래 `*.sh/*.md/*.mjs`만이었으나 확장):
`*.sh`, `*.md`, `*.mjs`, `*.yaml`, `*.json`, `*.py`, `hooks.json`, `package.json`

**Fail-closed**: 검색 파싱 에러 시 삭제 금지 (`exit 1`). False positive가 false negative보다 안전하다.

**구현 위치**: `plugins/cwf/hooks/scripts/check-deletion-safety.sh`, `hooks.json`에 PostToolUse 등록

### Proposal B: Broken-link triage protocol (P0)

**문제**: Broken link를 발견했을 때 "참조 제거"가 기본 반응이 되면 근본 원인을 놓친다.

**해결**: `plugins/cwf/references/agent-patterns.md`에 프로토콜 추가:

```markdown
### Broken Link Triage

When a link check reports a missing target file:
1. Check git log: was the file recently deleted? If yes → investigate WHY
2. Check callers: classify by type (runtime / build / test / docs / stale)
3. Decision matrix:
   | File was deleted | Caller type | Action |
   |-----------------|-------------|--------|
   | Yes | runtime/build | RESTORE the file (deletion was wrong) |
   | Yes | test only | Evaluate — may need test update instead |
   | Yes | docs/stale only | Remove reference (deletion was correct) |
   | Never existed | — | Remove reference (link was always wrong) |
   | Renamed | — | Update reference to new path |
4. Record triage decision in `lessons.md` or `live.decision_journal`
```

**리뷰 반영**: Correctness의 "caller type 분류 추가", UX/DX의 "triage 결정 persistence" 반영.

**구현 위치**: `plugins/cwf/references/agent-patterns.md`, check-links-local.sh hook의 에러 메시지에 "Broken Link Triage protocol 참조" 힌트 추가

### Proposal C: Analysis-to-impl fidelity check (P1 — 승격)

**문제**: 분석 문서의 구체적 권장사항이 triage/impl을 거치며 왜곡된다.

**리뷰 반영**: Expert β가 "5 Whys가 한 단계 부족 — triage 산출물의 구조가 삭제를 당연시하게 만든 원인 미분석"으로 P1 승격 권고. **Triage 단계에서 결정 시점 왜곡을 방어하는 메커니즘.**

**해결**: cwf:impl SKILL.md Rules 섹션에 추가:

```markdown
### Recommendation Fidelity Check

For each triage item that references an analysis document:
1. Read the ORIGINAL analysis document's recommendation section
2. Compare with the triage item's action description
3. If the triage action contradicts or simplifies the original recommendation:
   follow the original, not the triage summary
4. For deletions: apply pre-mortem — "이 삭제가 실패하면 어떻게 될까?"를 먼저 시뮬레이션
```

**구현 위치**: `plugins/cwf/skills/impl/SKILL.md` Rules 섹션

### Proposal D: Script dependency graph in pre-push (P2)

**문제**: 스크립트 간 런타임 의존성이 정적 분석되지 않는다.

**해결**: `check-script-deps.sh`를 만들어 pre-push에 추가:

```bash
# For each .sh/.mjs/.py in plugins/cwf/:
#   1. Extract calls to other scripts ($SCRIPT_DIR/..., bash ..., source ...)
#   2. Verify target exists
#   3. Exit 1 if any broken runtime dependency
# Note (Architecture review): treat as "high-confidence caller" signal,
# not deterministic — variable interpolation limits static analysis.
# Note (Security review): enforce repository-boundary check to prevent
# path traversal in parsed paths.
```

**변경 점**: check-readme-structure.sh (next-session Proposal 2)와 같은 세션에서 구현하여 hook 인프라를 한 번에 확장. 증분 검사(변경 파일 중심)로 시작하여 성능 비용 최소화 (Correctness S5).

### Proposal E+G: Hook-based workflow enforcement with fail-closed gate (P0 — 핵심)

**문제**: "cwf:run을 써라"는 사용자 지시가 컴팩션을 거치며 희석. 문서는 컴팩션에 취약하지만, **hooks는 매 turn마다 새로 주입되므로 컴팩션을 살아남는다.**

**리뷰 반영 — 6개 핵심 수정**:

1. **Advisory → Fail-closed** (Correctness C1, Expert α C2): Hook이 알림만 하는 것이 아니라, `remaining_gates`에 `review-code`가 있는 상태에서 ship/commit을 시도하면 **exit 1로 차단**.

2. **Hook event 확정** (UX/DX C2): **`UserPromptSubmit`만 사용**. Notification은 에이전트가 이미 행동한 후이므로 safety gate로 부적합.

3. **필드명 변경** (UX/DX C4): `live.workflow` → `live.active_pipeline` (root-level `workflow:` 키와의 충돌 방지).

4. **remaining_gates를 YAML list로 저장** (UX/DX C1): comma-separated string 대신 기존 `key_files`, `decisions`와 동일한 YAML list 규약 사용. `cwf-live-state.sh`에 list upsert 함수 추가.

5. **user_directive 안전성** (Security C2, C3): `user_directive` 값을 YAML-safe하게 sanitize (`:`, `\n`, `[`, `]` 이스케이프). Gate name은 `cwf:run` stage manifest의 enum과 대조 검증.

6. **Override 메커니즘** (Architecture critical): `live.pipeline_override_reason` 필드 추가. 사용자 동의 하에 게이트를 건너뛸 수 있되, 반드시 사유를 기록하고 hook 출력에 경고 표시.

**구현 설계**:

```text
┌─────────────────────────────────────────────────────────┐
│  cwf-state.yaml (live section)                          │
│  active_pipeline: cwf:run                               │
│  phase: impl                                            │
│  remaining_gates:                                       │
│    - review-code                                        │
│    - refactor                                           │
│    - retro                                              │
│    - ship                                               │
│  user_directive: "cwf:run 최대한 사용"                    │
│  pipeline_override_reason: null                         │
│  state_version: 3                                       │
└───────────────────────┬─────────────────────────────────┘
                        │ read by UserPromptSubmit hook
                        ▼
┌─────────────────────────────────────────────────────────┐
│  workflow-gate.sh output (every turn)                   │
│  ⚠ Active pipeline: cwf:run (phase: impl)              │
│  Remaining gates: review-code → refactor → retro → ship│
│  Do NOT skip gates. Use Skill tool to invoke next stage.│
│  BLOCKED actions: ship, push (review-code pending)      │
└─────────────────────────────────────────────────────────┘
```

**구현 파일**:
- `plugins/cwf/hooks/scripts/workflow-gate.sh` — UserPromptSubmit hook
- `plugins/cwf/scripts/cwf-live-state.sh` — list upsert 함수 추가, gate name validation
- `plugins/cwf/skills/run/SKILL.md` — Phase 1에서 active_pipeline 등록, 각 stage에서 remaining_gates 업데이트, Phase 3에서 정리
- `plugins/cwf/hooks/hooks.json` — UserPromptSubmit hook 등록
- `cwf:setup` — hook group에 포함

**Fail-closed 동작**:
- `remaining_gates`에 `review-code`가 있으면: `cwf:ship`, `git push` 시도를 차단 (`exit 1`)
- 에이전트가 직접 Edit으로 구현하려 해도: 매 turn "review-code 게이트가 남아있다" 알림
- Override: 사용자가 명시적으로 `--skip-gate review-code`를 요청하면 `pipeline_override_reason`에 사유 기록 후 진행

**Recovery layer** (Expert α 반영): `remaining_gates` 상태가 corrupt되었을 경우의 복구 경로:
- `workflow-gate.sh`가 `active_pipeline`은 있는데 `remaining_gates`가 비어있으면 경고 출력
- `state_version` 필드로 stale write 감지 (CAS-style)
- 이전 세션의 `active_pipeline`이 남아있으면 정리 프롬프트 출력

### Proposal F: cwf:review에 세션 로그 리뷰 모드 추가 (P2)

**문제**: cwf:review가 코드 diff만 분석하고 세션 로그(의사결정 과정)를 보지 않아 "계획과 실행의 불일치"를 감지하지 못한다.

**해결**: `cwf:review --mode code`가 세션 디렉토리에 세션 로그가 있으면 자동으로 교차 검증:

```markdown
### Session Log Cross-Check (auto, when session log exists)

1. Read session log from `.cwf/projects/{session}/session-logs/`
2. Compare stated task plan (TaskCreate entries) with actual execution
3. Flag: planned gates that were never executed
   Example: "FLAG: Task #6 planned cwf:run invocation but execution trace shows 0 Skill tool calls"
4. Flag: user instructions that appear in messages but not in execution trace
5. Flag: analysis recommendations that were inverted during implementation
6. On missing/partial logs: WARN and continue (do not hard-fail)
```

**리뷰 반영**: UX/DX S3 (예시 추가), Correctness C5 (에러 정책: WARN + continue).

---

## 7. Priority Matrix (defense layer view)

Expert α (James Reason)의 권고를 반영하여 방어 레이어별로 재구성:

### Prevention layer (사고 발생 방지)

| Proposal | Defense type | Mechanism | Priority |
|----------|-------------|-----------|----------|
| A: Deletion safety hook | Direct — 결정 시점 개입 | PostToolUse hook (`exit 1`) | **P0** |
| B: Broken-link triage | Signal preservation | agent-patterns.md protocol + hook hint | **P0** |
| C: Fidelity check | Triage 왜곡 방지 | impl SKILL.md rule + pre-mortem | **P1** |
| E+G: Workflow enforcement | Gate 소실 방지 (compaction-immune) | UserPromptSubmit hook + cwf-state.yaml | **P0** |

### Detection layer (사고 감지)

| Proposal | Defense type | Mechanism | Priority |
|----------|-------------|-----------|----------|
| D: Script dep graph | Deterministic static check | pre-push hook (`exit 1`) | **P2** |
| H: README structure sync | Structural drift check | pre-push hook (`exit 1`) | **P2** |

### Recovery layer (사고 후 복구)

| Proposal | Defense type | Mechanism | Priority |
|----------|-------------|-----------|----------|
| F: Session log review | Plan-execution gap 감지 | cwf:review auto cross-check | **P2** |
| E recovery path | Stale state 복구 | state_version + cleanup prompt | **P0** (E에 포함) |

**구현 순서** (P0 내): A → B → E+G (ascending effort)

---

## 8. Next-Session Scope: Deferred Extraction & Validation Scripts

> Source: 260216-04 retro persist proposals #4, #5

### Proposal H: README Structure Sync Validation Script

**Finding**: README.ko.md (SSOT) and README.md had structural misalignment across all 13 skills.

**Action**: Create `check-readme-structure.sh` that:

1. Extracts section heading hierarchy from README.ko.md and README.md
2. Compares at the heading level (ignoring content)
3. Reports structural drift (missing/extra sections, order differences)
4. Exits non-zero on mismatch for CI/hook integration

**Integration point**: pre-push hook or `cwf:refactor --docs` deterministic tool pass.
**Pilot scope**: Compare only `##` and `###` level headings within skill sections.

### Proposal I: Shared Reference Extraction (Sub-Agent Output Persistence + Web Research Protocol)

**Finding**: Expert α (Fowler, 260216-04 retro) identified extraction priority = 변경 빈도 × 인스턴스 수.

| Priority | Pattern | Instances | Location after extraction |
|----------|---------|-----------|--------------------------|
| 1 | Sub-Agent Output Persistence Block | 25+ across 5 skills | `plugins/cwf/references/agent-patterns.md` (new section) |
| 2 | Web Research Protocol prompt fragment | 8+ across 4 skills | `plugins/cwf/references/agent-patterns.md` (existing, formalize) |

**Deliverable**: Extract patterns 1 and 2 to shared references. Update all composing skills to reference instead of inline. Apply Proposal A (deletion safety) during extraction — verify no runtime callers before removing inline blocks.

---

## 9. BDD Acceptance Checks

```gherkin
# Proposal A
Given an agent executing cwf:impl attempts to delete a file
When the file has runtime callers (grep across *.sh/*.md/*.mjs/*.yaml/*.json/*.py)
Then the PostToolUse hook exits 1 with "BLOCKED: {file} has runtime callers"
And the deletion is prevented

Given an agent attempts to delete a file with no callers
When check-deletion-safety.sh runs
Then the hook exits 0 silently

# Proposal B
Given a pre-push hook reports a broken link to a recently deleted file
When the agent responds
Then the agent checks git log for deletion history before removing any reference
And classifies callers by type (runtime/build/test/docs/stale)

# Proposal C
Given cwf:impl receives a triage item referencing an analysis document
When the triage action says "delete" but the original recommendation says "add reference"
Then the agent follows the original recommendation, not the triage summary

# Proposal E+G
Given cwf:run is active with remaining_gates including review-code
When the agent attempts to invoke cwf:ship
Then the UserPromptSubmit hook exits 1 with gate violation message
And the ship action is blocked

Given cwf:run completes the review-code stage
When remaining_gates is updated
Then review-code is removed from the YAML list in cwf-state.yaml
And state_version is incremented

Given a stale active_pipeline from a previous session exists
When a new session starts
Then workflow-gate.sh outputs a cleanup prompt

# Proposal H
Given README.ko.md has a heading structure
When check-readme-structure.sh compares against README.md
Then structural mismatches are reported with specific section names
And exit code is non-zero on mismatch

# Proposal I
Given the Sub-Agent Output Persistence Block exists inline in 5+ skills
When extraction is performed
Then all composing skills reference the shared block instead of inlining
And no runtime callers are broken by the extraction
```

---

## 10. Context Files

- Review synthesis: `.cwf/projects/260216-04-full-repo-refactor/review-synthesis-plan.md`
- Individual reviews: `.cwf/projects/260216-04-full-repo-refactor/review-{security,ux-dx,correctness,architecture,expert-alpha,expert-beta}-plan.md`
- Retro: `.cwf/projects/260216-04-full-repo-refactor/retro.md`
- Holistic convention analysis: `.cwf/projects/260216-04-full-repo-refactor/refactor-holistic-convention.md`
- Lessons: `.cwf/projects/260216-04-full-repo-refactor/lessons.md`
- Next-session (original): `.cwf/projects/260216-04-full-repo-refactor/next-session.md`
