# Review & Prevention: 260216 Refactoring Incident

> Date: 2026-02-17
> Scope: f7b1979..c6af491 (8 commits, 260216-04 full-repo-refactor session)
> Reviewer: Claude Opus 4.6 (post-incident, user-directed)

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
| D-1 | **P0 — Runtime breakage** | fc9919b | `gather/scripts/csv-to-toon.sh` | Deleted a script that `g-export.sh:111` calls at runtime. Google Sheets → TOON conversion pipeline broken. |
| D-2 | **P1 — Safety net removal** | fc9919b | `refactor/references/*.provenance.yaml` (×3) | Deleted provenance sidecars that feed pre-push drift detection for 3 criteria documents. |
| D-3 | P2 — Stale reference | 38b6ebe | `retro/SKILL.md:145` | Rationale text still mentions `expert-lens-guide.md` after agent prompts were migrated to `expert-advisor-guide.md`. |

### What was correct

The remaining changes (plugin-deploy Rules/References, plan Adaptive Sizing Gate, ship i18n, update generic path, skill-conventions enforced/aspirational split, review persistence, expert-advisor-guide retro mode, README Design Intent sections) are structurally sound and improve the system.

---

## 2. Root Cause: Why csv-to-toon.sh Was Deleted

### The signal chain

```
Deep review (structural)           → "csv-to-toon.sh unreferenced in SKILL.md"
Deep review (recommendation)       → "Add reference to SKILL.md Google Export section"
Analysis.md triage                 → "P3-16: Remove gather unreferenced csv-to-toon.sh"
Impl agent                         → `git rm csv-to-toon.sh`
Pre-push link check (README)       → Broken link detected → push blocked
User fixes broken link             → ← HERE: last signal eliminated
User notices csv-to-toon missing   → Runtime breakage discovered
```

### 5 Whys

1. **왜 삭제했나?** Analysis.md가 P3-16으로 "unreferenced csv-to-toon.sh 제거"를 분류했고, impl 에이전트가 이를 그대로 실행했다.
2. **왜 analysis가 "제거"로 분류했나?** Deep review의 구체적 권장사항("SKILL.md에 참조 추가")이 triage 단계에서 "unreferenced → 삭제"로 단순화되었다. 원본 리뷰 문서 대신 요약 테이블에서 작업을 수행했다.
3. **왜 triage에서 왜곡되었나?** 분석 요약이 "해결 방법"이 아닌 "문제 설명"만 전달했다. "unreferenced csv-to-toon.sh"라는 라벨은 "제거하라"로 읽히기 쉬우나 원래는 "참조를 추가하라"였다.
4. **왜 impl에서 삭제 전 런타임 의존성을 확인하지 않았나?** Impl 단계에 **"삭제 전 호출자 확인"** 게이트가 없었다. `git rm`은 reversal cost가 낮다고 판단했으나 실제로는 런타임 파이프라인을 파괴했다.
5. **왜 cwf:review가 이를 잡지 못했나?** 이 세션에서 cwf:review가 코드 변경에 대해 실행되지 않았다. cwf:run 파이프라인이 아닌 수동 순차 실행이었고, review(code) 단계가 생략되었다.

### Structural cause

**분석(what's wrong) → 처방(what to do)의 충실도 손실(fidelity loss)**. 깊은 분석의 구체적 권장사항이 요약/triage 단계를 거치며 반대 방향의 행동으로 변환되었다.

---

## 3. Retrospective: Would cwf:run Have Prevented This?

### 짧은 답: 높은 확률로 예, 단 조건부

cwf:run의 기본 체인은 `gather → clarify → plan → review(plan) → impl → review(code) → refactor → retro → ship`.

이 세션에서 실제로 실행된 순서는:
```
(manual) refactor --holistic/--skill/--docs/--code → analysis.md → P0/P1/P2 manual impl → retro
```

**생략된 게이트들:**

| 생략된 단계 | 잡았을 가능성 | 근거 |
|------------|-------------|------|
| clarify | 중간 | "unreferenced 파일 처리 방법"에 대한 명시적 의사결정이 이루어졌을 수 있음 |
| plan | **높음** | Plan의 "Don't Touch" 섹션이나 BDD criteria가 "기존 런타임 파이프라인 파괴 금지"를 명시했을 가능성 |
| review(plan) | **높음** | 6명의 병렬 리뷰어가 "csv-to-toon.sh 삭제" 항목을 보고 g-export.sh 의존성을 지적했을 가능성 |
| review(code) | **매우 높음** | 코드 리뷰 시 `git rm csv-to-toon.sh` + `g-export.sh:111`의 호출 관계를 직접 감지 |

**결론**: cwf:run의 review(code) 단계 하나만으로도 이 문제는 거의 확실히 잡혔다. Plan 단계에서 잡힐 가능성도 높다. 이 세션이 수동 실행이었기 때문에 이 게이트들이 모두 누락되었다.

### 그러나 cwf:run만으로는 불충분한 부분

cwf:run의 review는 **최종 diff를 검토**한다. 하지만 이 사고의 근본 원인은 **분석→triage에서의 충실도 손실**이다. 이것은 cwf:review가 아닌 cwf:impl의 "삭제 안전성 확인" 로직이 필요한 영역이다.

---

## 4. Retrospective: Why cwf:run Was Never Called (Session Log Analysis)

### 사실 관계

세션 로그(`.cwf/sessions/260216-2049-1b5c4097.claude.md`)에서 확인된 사실:

1. 사용자는 **두 번** "cwf:run 최대한 사용"이라고 말함 (Turn 1, Turn 3)
2. 에이전트는 Task #6을 **"Phase 3: Implement fixes via cwf:run"**으로 생성 (Turn 3, tool #16)
3. Turn 4에서 Task #6을 `in_progress`로 변경한 직후, **cwf:run을 invoke하지 않고 직접 Edit 시작**
4. Turn 5~6에서 P0→P1→P2→P3의 17개 항목을 전부 수동 Edit으로 구현
5. **cwf:run은 전체 세션에서 한 번도 호출되지 않음**
6. 따라서 cwf:run 체인의 review(code) 게이트가 **완전히 생략됨**

### 원인 분석

**컨텍스트 컴팩션 4회에 의한 의도 희석**:
- 이 세션은 Turn 3→4, 4→5, 5→6, 6→7에서 각각 "out of context" 복구 발생
- 매번 summary의 "Optional Next Step"이 구체적인 Edit 작업을 나열 (e.g., "frontmatter 변환", "ship 수정")
- 복구된 에이전트는 summary에 적힌 다음 Edit를 즉시 실행 — **원래 사용자 지시("cwf:run 사용")가 점진적으로 사라짐**

**분석↔구현 경계의 모호성**:
- cwf:refactor(분석)를 수동 실행한 후 analysis.md가 생성됨
- 에이전트는 analysis.md가 cwf:run의 gather/clarify/plan을 대체한다고 판단
- 그러나 **핵심인 review(code) 게이트를 함께 건너뜀** — 이것이 csv-to-toon.sh 삭제를 잡을 수 있었던 유일한 자동 안전장치

**"cwf:run 최대한 사용"의 해석 차이**:
- 에이전트: "분석에 cwf 도구를 활용하라" → cwf:refactor를 사용함으로써 충족됐다고 판단
- 사용자: "구현도 cwf:run의 게이트를 거쳐라" → review(code) 포함

### cwf:review의 세션 로그 미활용

이번 세션에서 cwf:review를 실행했을 때, **코드 diff만 보고 세션 로그는 보지 않았다**. 세션 로그를 함께 봤다면:
- "Task #6이 cwf:run으로 구현한다고 적혀 있는데 실제로는 직접 Edit" → 프로세스 위반 감지
- "P3-16이 '삭제'로 기술되어 있는데 원본 deep review는 '참조 추가' 권장" → triage 왜곡 감지
- "review(code) 게이트가 한 번도 실행되지 않음" → 안전장치 부재 감지

이것은 cwf:review의 기능 확장 후보: **리뷰 대상에 세션 로그를 포함**하여 "계획과 실행의 불일치"를 검출하는 모드.

---

## 5. Retrospective: This Session's (260217) Signal Failure

### 사건 재구성

```
1. Pre-push hook: broken links 감지 (csv-to-toon.sh, provenance.yaml ×3)
2. 에이전트(나): "broken link를 수정합니다" → README에서 참조 제거
3. 사용자: "csv-to-toon이 없어졌나요?"
4. 에이전트(나): git history 확인 → 삭제 경위 파악
5. 사용자: "리팩토링이 동작을 깨뜨렸으니 큰 문제"
```

### 나(에이전트)의 판단 오류

**Pre-push hook이 broken link를 보고했을 때, 나는 "link를 고치는 것"이 목표라고 판단하고 README에서 참조를 제거했다.** 이것은 증상을 제거한 것이지 원인을 해결한 것이 아니다.

올바른 반응:
1. Broken link를 발견 → **왜 파일이 없는지** 먼저 조사
2. `csv-to-toon.sh`가 삭제되었다면 → **호출자가 있는지** 확인 (g-export.sh:111)
3. 런타임 의존성이 있다면 → **파일을 복원**하는 것이 올바른 수정

나는 2-3 단계를 건너뛰고 가장 표면적인 수정(참조 제거)을 선택했다. 사용자가 개입하지 않았다면, 런타임 파괴는 모든 표면적 신호가 제거된 채로 잔존했을 것이다.

### Provenance에 대해서도 동일한 패턴

Provenance.yaml 3개의 broken README link도 동일하게 처리했다. 파일이 왜 없는지 묻지 않고 참조를 제거했다. 사실 provenance-check.sh가 pre-push에서 실행되면서 drift 감지를 하는 인프라의 일부였다.

---

## 6. Prevention Proposals

### Proposal A: Impl-stage deletion safety gate (즉시 적용 가능)

**문제**: `git rm`이나 파일 삭제가 런타임 의존성을 깨뜨릴 수 있다.

**해결**: cwf:impl의 실행 규칙에 다음 게이트를 추가:

```markdown
### Deletion Safety Gate

Before deleting any file (git rm, rm, or omitting from write):
1. **Caller check**: Search the codebase for the filename in script calls,
   imports, source statements, and SKILL.md references
   (`grep -r "filename" --include="*.sh" --include="*.md" --include="*.mjs"`)
2. If callers exist: the file is a runtime dependency. Do NOT delete.
   Instead, address the original concern (e.g., add missing reference).
3. If no callers: safe to delete. Proceed.
```

**구현 위치**: `plugins/cwf/skills/impl/SKILL.md` Rules 섹션, `plugins/cwf/references/agent-patterns.md`

### Proposal B: Broken-link triage protocol (즉시 적용 가능)

**문제**: Broken link를 발견했을 때 "참조 제거"가 기본 반응이 되면 근본 원인을 놓친다.

**해결**: Pre-push/pre-commit hook의 broken link 처리 프로토콜:

```markdown
### Broken Link Triage

When a link check reports a missing target file:
1. Check git log: was the file recently deleted? If yes → investigate WHY
2. Check callers: does anything else reference or call this file at runtime?
3. Decision matrix:
   | File was deleted | Has callers | Action |
   |-----------------|-------------|--------|
   | Yes | Yes | RESTORE the file (deletion was wrong) |
   | Yes | No | Remove reference (deletion was correct, link is stale) |
   | Never existed | — | Remove reference (link was always wrong) |
   | Renamed | — | Update reference to new path |
```

**구현 위치**: `AGENTS.md` 또는 `plugins/cwf/references/agent-patterns.md`

### Proposal C: Analysis-to-impl fidelity check (중기)

**문제**: 분석 문서의 구체적 권장사항이 triage/impl을 거치며 왜곡된다.

**해결**: cwf:impl이 triage 항목을 실행하기 전, 원본 분석 문서의 recommendation을 반드시 확인하도록 강제:

```markdown
### Recommendation Fidelity Check

For each triage item that references an analysis document:
1. Read the ORIGINAL analysis document's recommendation section
2. Compare with the triage item's action description
3. If the triage action contradicts or simplifies the original recommendation:
   follow the original, not the triage summary
```

### Proposal D: Script dependency graph in pre-push (장기)

**문제**: 스크립트 간 런타임 의존성이 정적 분석되지 않는다.

**해결**: `check-script-deps.sh`를 만들어 pre-push에 추가:

```bash
# For each .sh/.mjs/.py in plugins/cwf/:
#   1. Extract calls to other scripts ($SCRIPT_DIR/..., bash ..., source ...)
#   2. Verify target exists
#   3. Exit 1 if any broken runtime dependency
```

이 스크립트가 있었다면 csv-to-toon.sh 삭제 시점(fc9919b push 시)에 즉시 차단했을 것이다. 현재의 link checker는 markdown link만 검사하고 스크립트 간 호출 관계는 검사하지 않는다.

### Proposal E: Hook-based workflow enforcement gate (P0 — 핵심 제안)

**문제**: "cwf:run을 써라"는 사용자 지시가 컴팩션 4회를 거치며 희석되어 review(code) 게이트가 완전히 생략되었다. AGENTS.md에 규칙을 추가해도 동일한 희석이 발생한다 — 문서는 컴팩션에 취약하지만, **hooks는 매 turn마다 새로 주입되므로 컴팩션을 살아남는다.**

**설계 원칙**: CWF의 핵심 가치는 "컴팩션을 거쳐도 워크플로가 유지되는 것"이다. 이것이 훼손되면 CWF의 존재 이유가 사라진다. 따라서 이 문제는 문서 수준이 아니라 **런타임 게이트 수준**에서 해결해야 한다.

**해결**: cwf-state.yaml의 `phase` + `workflow` 필드를 읽는 hook을 추가하여, 활성 워크플로가 있을 때 매 turn마다 에이전트에게 현재 상태를 주입:

```
┌─────────────────────────────────────────────────────────┐
│  cwf-state.yaml                                         │
│  workflow: cwf:run                                      │
│  phase: impl                                            │
│  remaining_gates: [review-code, refactor, retro, ship]  │
│  user_directive: "cwf:run 최대한 사용"                    │
└───────────────────────┬─────────────────────────────────┘
                        │ read by hook on every turn
                        ▼
┌─────────────────────────────────────────────────────────┐
│  UserPromptSubmit or Notification hook output            │
│  ⚠ Active workflow: cwf:run (phase: impl)               │
│  Remaining gates: review-code → refactor → retro → ship │
│  Do NOT skip gates. Use Skill tool to invoke next stage. │
└─────────────────────────────────────────────────────────┘
```

**구현 세부사항**:

1. **cwf-state.yaml 확장**: `cwf:run`이 시작할 때 `workflow`, `remaining_gates`, `user_directive` 필드를 기록. `cwf-live-state.sh set`으로 관리.

2. **Hook 추가**: `hooks/scripts/workflow-gate.sh` — `cwf-state.yaml`를 읽어 `workflow`가 활성이면 phase와 remaining gates를 출력. 기존 `attention.sh` (Notification hook)에 통합하거나 별도 UserPromptSubmit hook으로 추가.

3. **cwf:run SKILL.md 연동**: cwf:run의 Phase 1(Initialize)에서 workflow 필드를 등록하고, 각 stage 완료 시 remaining_gates를 업데이트. Phase 3(Completion)에서 workflow 필드를 정리.

4. **cwf:setup 연동**: `cwf:setup`이 이 hook을 hook group에 포함하여 설치. 기존 `attention` 그룹에 추가하거나 신규 `workflow-gate` 그룹으로 분리.

**효과**: 컴팩션이 100회 발생해도, 매 turn마다 hook이 cwf-state.yaml에서 현재 워크플로 상태를 읽어 주입한다. 에이전트가 "직접 Edit"을 시도하려 해도 "review-code 게이트가 남아있다"는 알림을 매번 받게 된다.

**왜 AGENTS.md가 아닌가**: AGENTS.md는 "CWF를 사용하세요" 수준의 안내에는 적합하지만, 특정 워크플로 단계를 강제하기에는 부적합하다. 사용자가 "CWF 사용해서"라고만 말해도 cwf:run이 잘 돌아가게 하는 것이 목표이므로, 강제 로직은 CWF 내부(hook + state)에 있어야 한다.

### Proposal F: cwf:review에 세션 로그 리뷰 모드 추가 (중기)

**문제**: cwf:review가 코드 diff만 분석하고 세션 로그(의사결정 과정)를 보지 않아 "계획과 실행의 불일치"를 감지하지 못한다.

**해결**: `cwf:review --mode code`가 세션 디렉토리에 세션 로그가 있으면 자동으로 교차 검증:

```markdown
### Session Log Cross-Check (auto, when session log exists)

1. Read session log from `.cwf/projects/{session}/session-logs/`
2. Compare stated task plan (TaskCreate entries) with actual execution
3. Flag: planned gates that were never executed
4. Flag: user instructions that appear in messages but not in execution trace
5. Flag: analysis recommendations that were inverted during implementation
```

### Proposal G: cwf:run의 gate 상태를 cwf-state.yaml에 영속화 (Proposal E의 전제 조건)

**문제**: 현재 cwf:run은 `phase`만 기록하고 remaining gates는 에이전트 메모리에만 존재. 컴팩션 시 사라짐.

**해결**: cwf:run이 매 stage 전환 시 `remaining_gates` 리스트를 cwf-state.yaml에 기록. cwf-live-state.sh 확장:

```bash
bash cwf-live-state.sh set . \
  phase="impl" \
  workflow="cwf:run" \
  remaining_gates="review-code,refactor,retro,ship" \
  user_directive="cwf:run 최대한 사용"
```

이 필드들이 있어야 Proposal E의 hook이 읽을 데이터가 생긴다. Proposal E와 G는 함께 구현해야 한다.

---

## 7. Priority and Effort Matrix

| Proposal | Prevention strength | Effort | Priority |
|----------|-------------------|--------|----------|
| A: Deletion safety gate | High (direct prevention) | Small (add rule text to impl) | **P0 — do now** |
| B: Broken-link triage | High (prevents signal elimination) | Small (add protocol to agent-patterns) | **P0 — do now** |
| E+G: Workflow enforcement hook + state | **Very high** (compaction-immune gate) | Medium (new hook + state fields + cwf:run update) | **P0 — do now** |
| C: Fidelity check | Medium (prevents triage distortion) | Medium (impl rule + examples) | P2 |
| F: Session log review mode | High (detects plan-execution gap) | Medium (review skill extension) | P2 |
| D: Script dep graph | Very high (deterministic gate) | Large (new script + hook) | P3 (next-session candidate) |

**Proposal E+G가 최우선**: 이번 사고의 근본 원인은 컴팩션에 의한 워크플로 게이트 소실이다. A/B는 특정 증상(삭제, broken link)에 대한 방어이고, E+G는 구조적 방어이다. CWF의 핵심 가치("컴팩션을 거쳐도 워크플로 유지")를 직접 보호한다.

---

## 8. Connection to Next-Session Proposals

Next-session.md의 Proposal 2 (check-readme-structure.sh)와 이 문서의 Proposal D (check-script-deps.sh)는 같은 설계 패턴을 공유한다: **인간의 기억이 아닌 자동화된 정적 검증으로 drift를 잡는다.** 두 스크립트를 같은 세션에서 구현하면 hook 인프라를 한 번에 확장할 수 있다.

또한 Proposal A/B (삭제 안전 게이트, broken-link triage)는 next-session의 Proposal 1 (공유 참조 추출) 작업에서 즉시 적용 가능하다 — 추출 과정에서 인라인 블록을 삭제하기 전, 런타임 의존성이 없는지 확인하는 연습이 된다.
